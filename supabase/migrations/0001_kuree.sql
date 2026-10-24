-- Kuree: kuris run from the app by their admins, read by members through a
-- private link.
--
-- Each kuri is one JSON document (settings, the people, the slots and every
-- month), saved whole by an admin, with every earlier version kept so a
-- mistake can be undone. The shape of the document is decided by the app;
-- the database checks only what keeps it safe: who may change it, that two
-- admins saving at once cannot overwrite each other, and that phone numbers
-- never leave through the members' link.
--
-- Who may change a kuri is listed in kuri_admins, by account, WhatsApp
-- number or email, so an owner can add a co-admin before that person has
-- ever signed in.

-- ---------------------------------------------------------------- who is signed in

create or replace function public.me() returns text
language sql stable set search_path = '' as $$
  select nullif(lower(btrim(coalesce(auth.email(), ''))), '');
$$;

-- The signed-in WhatsApp number, digits only with the country code, or null.
create or replace function public.my_phone() returns text
language sql stable set search_path = '' as $$
  select nullif(regexp_replace(coalesce(auth.jwt() ->> 'phone', ''), '[^0-9]', '', 'g'), '');
$$;

-- A number as people type it, as digits with the country code. Ten digits on
-- their own are taken as Indian.
create or replace function public.phone_digits(p text) returns text
language sql immutable set search_path = '' as $$
  select case
    when d ~ '^[0-9]{10}$' then '91' || d
    when d ~ '^00[0-9]+$' then substr(d, 3)
    when d ~ '^0[0-9]{10}$' then '91' || substr(d, 2)
    else nullif(d, '')
  end
  from (select regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g') as d) x;
$$;

-- ---------------------------------------------------------------- tables

create table public.profiles (
  user_id    uuid primary key,
  name       text check (char_length(name) <= 60),
  updated_at timestamptz not null default now()
);

create table public.kuris (
  id          uuid primary key default gen_random_uuid(),
  data        jsonb not null check (jsonb_typeof(data) = 'object'),
  share_token text not null unique,
  created_by  uuid,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  updated_by  text
);

create table public.kuri_admins (
  id       bigserial primary key,
  kuri_id  uuid not null references public.kuris (id) on delete cascade,
  role     text not null check (role in ('owner', 'admin')),
  user_id  uuid,
  phone    text check (phone ~ '^[0-9]{8,15}$'),
  email    text check (email = lower(btrim(email)) and email like '%_@_%._%'),
  name     text check (char_length(name) <= 60),
  added_at timestamptz not null default now(),
  added_by text,
  check (user_id is not null or phone is not null or email is not null)
);
create unique index kuri_admins_user on public.kuri_admins (kuri_id, user_id) where user_id is not null;
create unique index kuri_admins_phone on public.kuri_admins (kuri_id, phone) where phone is not null;
create unique index kuri_admins_email on public.kuri_admins (kuri_id, email) where email is not null;
create index kuri_admins_by_phone on public.kuri_admins (phone) where phone is not null;
create index kuri_admins_by_email on public.kuri_admins (email) where email is not null;
create index kuri_admins_by_user on public.kuri_admins (user_id) where user_id is not null;

create table public.kuri_history (
  id       bigserial primary key,
  kuri_id  uuid not null references public.kuris (id) on delete cascade,
  data     jsonb not null,
  saved_at timestamptz not null default now(),
  saved_by text
);
create index kuri_history_kuri on public.kuri_history (kuri_id, saved_at desc);

-- Nothing is read or written directly: everything goes through the functions
-- below, which check who is asking.
alter table public.profiles enable row level security;
alter table public.kuris enable row level security;
alter table public.kuri_admins enable row level security;
alter table public.kuri_history enable row level security;
revoke all on public.profiles, public.kuris, public.kuri_admins, public.kuri_history from anon, authenticated;
revoke all on sequence public.kuri_admins_id_seq, public.kuri_history_id_seq from anon, authenticated;

-- ---------------------------------------------------------------- helpers

-- The signed-in person's role in a kuri: 'owner', 'admin' or null.
create or replace function public.kuri_role(k uuid) returns text
language sql stable security definer set search_path = '' as $$
  select a.role from public.kuri_admins a
  where a.kuri_id = k
    and ((auth.uid() is not null and a.user_id = auth.uid())
      or (public.my_phone() is not null and a.phone = public.my_phone())
      or (public.me() is not null and a.email = public.me()))
  order by case a.role when 'owner' then 1 else 2 end
  limit 1;
$$;

-- The name to show for the signed-in person, and to write next to a save.
create or replace function public.my_name() returns text
language sql stable security definer set search_path = '' as $$
  select coalesce(
    (select nullif(btrim(p.name), '') from public.profiles p where p.user_id = auth.uid()),
    (select nullif(btrim(a.name), '') from public.kuri_admins a
      where a.user_id = auth.uid() or a.phone = public.my_phone() or a.email = public.me()
      order by a.added_at limit 1),
    public.me(),
    case when public.my_phone() is not null then '+' || public.my_phone() end
  );
$$;

create or replace function public.new_token() returns text
language sql volatile set search_path = '' as $$
  select translate(encode(extensions.gen_random_bytes(18), 'base64'), '+/=', '-_');
$$;

-- What the app needs to know about a document before saving it.
create or replace function public.check_kuri(data jsonb) returns void
language plpgsql immutable set search_path = '' as $$
begin
  if data is null or jsonb_typeof(data) <> 'object' then
    raise exception 'Nothing to save.' using errcode = '22023';
  end if;
  if jsonb_typeof(data -> 'months') <> 'array' or jsonb_typeof(data -> 'payers') <> 'array'
     or jsonb_typeof(data -> 'people') <> 'array' then
    raise exception 'The kuri is missing its months, slots or people.' using errcode = '22023';
  end if;
  if coalesce(btrim(data ->> 'name'), '') = '' then
    raise exception 'Give the kuri a name.' using errcode = '22023';
  end if;
  if jsonb_array_length(data -> 'months') > 240 or jsonb_array_length(data -> 'payers') > 500
     or jsonb_array_length(data -> 'people') > 500 then
    raise exception 'That kuri is bigger than Kuree allows.' using errcode = '22023';
  end if;
  if pg_column_size(data) > 1000000 then
    raise exception 'That kuri is too big to save.' using errcode = '22023';
  end if;
end $$;

-- The kuri as the members' link shows it: no phone numbers.
create or replace function public.public_kuri(data jsonb) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_set(data, '{people}', coalesce(
    (select jsonb_agg(p - 'phone' - 'email') from jsonb_array_elements(data -> 'people') p), '[]'::jsonb));
$$;

-- One kuri as the app reads it.
create or replace function public.kuri_row(k public.kuris, role text) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object('id', k.id, 'data', k.data, 'role', role, 'share_token', k.share_token,
    'updated_at', k.updated_at, 'updated_by', k.updated_by, 'created_at', k.created_at);
$$;

-- ---------------------------------------------------------------- the signed-in person

create or replace function public.whoami() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', auth.uid(),
    'email', public.me(),
    'phone', public.my_phone(),
    'name', (select nullif(btrim(p.name), '') from public.profiles p where p.user_id = auth.uid()),
    'display', public.my_name()
  );
$$;

create or replace function public.set_my_name(name text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare n text := nullif(btrim(regexp_replace(coalesce(set_my_name.name, ''), '[<>]', '', 'g')), '');
begin
  if auth.uid() is null then raise exception 'Sign in first.' using errcode = '42501'; end if;
  if n is not null and char_length(n) > 60 then raise exception 'That name is too long.' using errcode = '22023'; end if;
  insert into public.profiles (user_id, name) values (auth.uid(), n)
  on conflict (user_id) do update set name = excluded.name, updated_at = now();
  return public.whoami();
end $$;

-- ---------------------------------------------------------------- kuris

-- Every kuri the signed-in person runs, newest first.
create or replace function public.my_kuris() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.kuri_row(k, r.role) order by k.created_at desc), '[]'::jsonb)
  from public.kuris k
  cross join lateral (select public.kuri_role(k.id) as role) r
  where r.role is not null;
$$;

create or replace function public.get_kuri(id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare k public.kuris%rowtype; r text := public.kuri_role(get_kuri.id);
begin
  if r is null then raise exception 'This kuri is not yours, or it was deleted.' using errcode = '42501'; end if;
  select * into k from public.kuris x where x.id = get_kuri.id;
  return public.kuri_row(k, r);
end $$;

create or replace function public.create_kuri(data jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare k public.kuris%rowtype;
begin
  if auth.uid() is null then raise exception 'Sign in first.' using errcode = '42501'; end if;
  perform public.check_kuri(data);
  if (select count(*) from public.kuri_admins a where a.user_id = auth.uid() and a.role = 'owner') >= 50 then
    raise exception 'You already run 50 kuris. Delete an old one first.' using errcode = '22023';
  end if;
  insert into public.kuris (data, share_token, created_by, updated_by)
  values (data, public.new_token(), auth.uid(), public.my_name())
  returning * into k;
  insert into public.kuri_admins (kuri_id, role, user_id, phone, email, name, added_by)
  values (k.id, 'owner', auth.uid(), public.my_phone(), public.me(), public.my_name(), public.my_name());
  return public.kuri_row(k, 'owner');
end $$;

-- Save the whole kuri. `expected` is the updated_at the admin started from:
-- when someone else saved in between, the save is refused instead of
-- silently overwriting their change.
create or replace function public.save_kuri(id uuid, data jsonb, expected timestamptz default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare k public.kuris%rowtype; r text := public.kuri_role(save_kuri.id); who text := public.my_name();
begin
  if r is null then raise exception 'Only this kuri''s admins can change it.' using errcode = '42501'; end if;
  perform public.check_kuri(data);
  select * into k from public.kuris x where x.id = save_kuri.id for update;
  if expected is not null and date_trunc('milliseconds', k.updated_at) <> date_trunc('milliseconds', expected) then
    raise exception 'Someone else saved this a moment ago. Reload to see their change, then try again.'
      using errcode = 'PT409';
  end if;
  if k.data = save_kuri.data then
    return public.kuri_row(k, r);
  end if;
  insert into public.kuri_history (kuri_id, data, saved_at, saved_by) values (k.id, k.data, k.updated_at, k.updated_by);
  update public.kuris x set data = save_kuri.data, updated_at = clock_timestamp(), updated_by = who
   where x.id = save_kuri.id returning * into k;
  -- The last 200 versions of each kuri are plenty.
  delete from public.kuri_history h
   where h.kuri_id = k.id
     and h.id not in (select h2.id from public.kuri_history h2 where h2.kuri_id = k.id order by h2.saved_at desc limit 200);
  return public.kuri_row(k, r);
end $$;

-- Earlier versions, newest first: when and by whom, and a little about each.
create or replace function public.kuri_versions(id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if public.kuri_role(kuri_versions.id) is null then
    raise exception 'Only this kuri''s admins can see its history.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', h.id, 'saved_at', h.saved_at, 'saved_by', h.saved_by, 'data', h.data)
                     order by h.saved_at desc)
    from public.kuri_history h where h.kuri_id = kuri_versions.id), '[]'::jsonb);
end $$;

-- Put an older version back. The current one goes into the history first, so
-- an undo can itself be undone.
create or replace function public.restore_kuri(version bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare old public.kuri_history%rowtype;
begin
  select * into old from public.kuri_history h where h.id = version;
  if not found then raise exception 'That version no longer exists.' using errcode = 'P0002'; end if;
  if public.kuri_role(old.kuri_id) is null then
    raise exception 'Only this kuri''s admins can restore a version.' using errcode = '42501';
  end if;
  return public.save_kuri(old.kuri_id, old.data, null);
end $$;

create or replace function public.delete_kuri(id uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if public.kuri_role(delete_kuri.id) is distinct from 'owner' then
    raise exception 'Only the owner can delete this kuri.' using errcode = '42501';
  end if;
  delete from public.kuris k where k.id = delete_kuri.id;
end $$;

-- ---------------------------------------------------------------- the members' link

-- A new private link. The old one stops working straight away.
create or replace function public.reset_share_link(id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare k public.kuris%rowtype; r text := public.kuri_role(reset_share_link.id);
begin
  if r is null then raise exception 'Only this kuri''s admins can change its link.' using errcode = '42501'; end if;
  update public.kuris x set share_token = public.new_token() where x.id = reset_share_link.id returning * into k;
  return public.kuri_row(k, r);
end $$;

-- What a member sees from the link: the kuri without anyone's number.
create or replace function public.shared_kuri(token text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('data', public.public_kuri(k.data), 'updated_at', k.updated_at)
  from public.kuris k
  where shared_kuri.token is not null and char_length(shared_kuri.token) between 16 and 64 and k.share_token = shared_kuri.token;
$$;

-- ---------------------------------------------------------------- admins

create or replace function public.kuri_admin_list(id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if public.kuri_role(kuri_admin_list.id) is null then
    raise exception 'Only this kuri''s admins can see who runs it.' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', a.id, 'role', a.role, 'name', coalesce(nullif(btrim(p.name), ''), a.name),
      'phone', a.phone, 'email', a.email, 'added_at', a.added_at, 'added_by', a.added_by,
      'me', (a.user_id = auth.uid() or a.phone = public.my_phone() or a.email = public.me()))
      order by case a.role when 'owner' then 1 else 2 end, a.added_at)
    from public.kuri_admins a
    left join public.profiles p on p.user_id = a.user_id
    where a.kuri_id = kuri_admin_list.id), '[]'::jsonb);
end $$;

-- The owner adds a co-admin by WhatsApp number or email. They see the kuri
-- the next time they sign in with that number or email.
create or replace function public.add_kuri_admin(id uuid, phone text default null, email text default null, name text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  ph text := public.phone_digits(add_kuri_admin.phone);
  em text := nullif(lower(btrim(coalesce(add_kuri_admin.email, ''))), '');
  nm text := nullif(btrim(regexp_replace(coalesce(add_kuri_admin.name, ''), '[<>]', '', 'g')), '');
begin
  if public.kuri_role(add_kuri_admin.id) is distinct from 'owner' then
    raise exception 'Only the owner can add admins.' using errcode = '42501';
  end if;
  if ph is null and em is null then
    raise exception 'Give a WhatsApp number or an email.' using errcode = '22023';
  end if;
  if ph is not null and ph !~ '^[0-9]{8,15}$' then
    raise exception 'That number does not look right. Add the country code.' using errcode = '22023';
  end if;
  if em is not null and em !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'That email does not look right.' using errcode = '22023';
  end if;
  if exists (select 1 from public.kuri_admins a where a.kuri_id = add_kuri_admin.id
             and ((ph is not null and a.phone = ph) or (em is not null and a.email = em))) then
    raise exception 'That person is already an admin of this kuri.' using errcode = '23505';
  end if;
  if (select count(*) from public.kuri_admins a where a.kuri_id = add_kuri_admin.id) >= 20 then
    raise exception 'A kuri can have up to 20 admins.' using errcode = '22023';
  end if;
  insert into public.kuri_admins (kuri_id, role, phone, email, name, added_by)
  values (add_kuri_admin.id, 'admin', ph, em, nm, public.my_name());
  return public.kuri_admin_list(add_kuri_admin.id);
end $$;

-- The owner removes an admin; an admin can also remove themselves (leave).
create or replace function public.remove_kuri_admin(admin_id bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare a public.kuri_admins%rowtype; mine boolean;
begin
  select * into a from public.kuri_admins x where x.id = admin_id;
  if not found then raise exception 'That admin was already removed.' using errcode = 'P0002'; end if;
  mine := (a.user_id = auth.uid() or a.phone = public.my_phone() or a.email = public.me());
  if a.role = 'owner' then
    raise exception 'The owner cannot be removed. Make someone else the owner first.' using errcode = '22023';
  end if;
  if not mine and public.kuri_role(a.kuri_id) is distinct from 'owner' then
    raise exception 'Only the owner can remove admins.' using errcode = '42501';
  end if;
  delete from public.kuri_admins x where x.id = admin_id;
  if mine and public.kuri_role(a.kuri_id) is null then return '[]'::jsonb; end if;
  return public.kuri_admin_list(a.kuri_id);
end $$;

-- The owner hands the kuri to one of its admins and stays on as an admin.
create or replace function public.make_kuri_owner(admin_id bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare a public.kuri_admins%rowtype;
begin
  select * into a from public.kuri_admins x where x.id = admin_id;
  if not found then raise exception 'That admin was removed.' using errcode = 'P0002'; end if;
  if public.kuri_role(a.kuri_id) is distinct from 'owner' then
    raise exception 'Only the owner can hand the kuri over.' using errcode = '42501';
  end if;
  update public.kuri_admins x set role = 'admin' where x.kuri_id = a.kuri_id and x.role = 'owner';
  update public.kuri_admins x set role = 'owner' where x.id = admin_id;
  return public.kuri_admin_list(a.kuri_id);
end $$;

-- ---------------------------------------------------------------- deleting an account

-- Before an account is deleted: every kuri it owns passes to its longest
-- serving admin, or is deleted when nobody else runs it; then its admin
-- places and its name go. The app then deletes the sign-in itself.
create or replace function public.delete_my_data() returns void
language plpgsql security definer set search_path = '' as $$
declare r record; heir bigint;
begin
  if auth.uid() is null then raise exception 'Sign in first.' using errcode = '42501'; end if;
  for r in
    select a.kuri_id from public.kuri_admins a
    where a.role = 'owner' and (a.user_id = auth.uid() or a.phone = public.my_phone() or a.email = public.me())
  loop
    select x.id into heir from public.kuri_admins x
     where x.kuri_id = r.kuri_id and x.role = 'admin'
       and not (x.user_id is not distinct from auth.uid() or x.phone is not distinct from public.my_phone()
                or x.email is not distinct from public.me())
     order by x.added_at limit 1;
    if heir is null then
      delete from public.kuris k where k.id = r.kuri_id;
    else
      update public.kuri_admins x set role = 'owner' where x.id = heir;
    end if;
  end loop;
  delete from public.kuri_admins a
   where a.user_id = auth.uid() or a.phone = public.my_phone() or a.email = public.me();
  delete from public.profiles p where p.user_id = auth.uid();
  -- This app's copy of the sign-in (the SkiFi login itself is kept by SkAuth).
  delete from auth.users u where u.id = auth.uid();
end $$;

-- ---------------------------------------------------------------- who may call what

revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.shared_kuri(text) to anon, authenticated;
grant execute on function
  public.whoami(), public.set_my_name(text), public.my_kuris(), public.get_kuri(uuid), public.create_kuri(jsonb),
  public.save_kuri(uuid, jsonb, timestamptz), public.kuri_versions(uuid), public.restore_kuri(bigint),
  public.delete_kuri(uuid), public.reset_share_link(uuid), public.kuri_admin_list(uuid),
  public.add_kuri_admin(uuid, text, text, text), public.remove_kuri_admin(bigint), public.make_kuri_owner(bigint),
  public.delete_my_data()
  to authenticated;
