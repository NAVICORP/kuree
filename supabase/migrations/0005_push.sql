-- Push notifications: a message on the phones of a chit's other admins when
-- someone marks payments paid, not paid or late, runs the draw, or adds a
-- co-admin (to the person added).
--
-- The app registers each phone's Firebase address (register_push_device)
-- once its owner turns reminders on, and forgets it on sign-out
-- (forget_push_device). Saves and new admins leave a line in push_outbox;
-- server/push.mjs sends those through Firebase Cloud Messaging and marks them
-- sent. Without the Firebase service account it sends nothing.

-- ---------------------------------------------------------------- tables

-- One row per phone. The email and number are the account's, so a co-admin
-- added by number or email gets messages before their admin place is tied
-- to their account.
create table public.push_devices (
  token      text primary key check (char_length(token) between 20 and 4096),
  user_id    uuid not null,
  email      text,
  phone      text,
  platform   text not null check (platform in ('android', 'ios')),
  lang       text not null default 'en' check (lang in ('en', 'ar', 'ml', 'ta', 'kn', 'hi')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index push_devices_user on public.push_devices (user_id);
create index push_devices_email on public.push_devices (email) where email is not null;
create index push_devices_phone on public.push_devices (phone) where phone is not null;

-- What happened, waiting to be sent. The words are made by the sender, in
-- each phone's language, from kind and args.
create table public.push_outbox (
  id          bigserial primary key,
  kuri_id     uuid not null references public.kuris (id) on delete cascade,
  kind        text not null check (kind in ('paid', 'unpaid', 'late', 'draw', 'admin_added')),
  args        jsonb not null default '{}'::jsonb,
  -- who did it, so they are not told about their own change
  actor_user  uuid,
  actor_email text,
  actor_phone text,
  -- for admin_added: the person added
  to_email    text,
  to_phone    text,
  created_at  timestamptz not null default now(),
  sent_at     timestamptz
);
create index push_outbox_waiting on public.push_outbox (id) where sent_at is null;

-- Nothing is read or written directly: only through the functions below and
-- by the sender, which signs in to the database itself.
alter table public.push_devices enable row level security;
alter table public.push_outbox enable row level security;
revoke all on public.push_devices, public.push_outbox from anon, authenticated;
revoke all on sequence public.push_outbox_id_seq from anon, authenticated;

-- ---------------------------------------------------------------- the app's phone

-- This phone's Firebase address, for the signed-in account, with the app's
-- language. Called again when the address or the language changes; an
-- address that moved to another account moves with it.
create or replace function public.register_push_device(token text, platform text, lang text default 'en')
returns void language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare t text := btrim(coalesce(register_push_device.token, ''));
begin
  if auth.uid() is null then raise exception 'Sign in first.' using errcode = '42501'; end if;
  if char_length(t) < 20 or char_length(t) > 4096 then
    raise exception 'That push address does not look right.' using errcode = '22023';
  end if;
  if register_push_device.platform not in ('android', 'ios') then
    raise exception 'Unknown platform.' using errcode = '22023';
  end if;
  insert into public.push_devices (token, user_id, email, phone, platform, lang)
  values (t, auth.uid(), public.me(), public.my_phone(), register_push_device.platform,
          case when register_push_device.lang in ('en', 'ar', 'ml', 'ta', 'kn', 'hi') then register_push_device.lang else 'en' end)
  on conflict (token) do update
    set user_id = excluded.user_id, email = excluded.email, phone = excluded.phone,
        platform = excluded.platform, lang = excluded.lang, updated_at = now();
  -- Ten phones per account is plenty; the oldest go.
  delete from public.push_devices d
   where d.user_id = auth.uid()
     and d.token not in (select d2.token from public.push_devices d2 where d2.user_id = auth.uid()
                         order by d2.updated_at desc limit 10);
end $$;

-- Stops messages to this phone. Works signed out too (the app calls it after
-- signing out): knowing the address is enough, and all it can do is stop
-- messages to that one phone.
create or replace function public.forget_push_device(token text) returns void
language sql security definer set search_path = '' as $$
  delete from public.push_devices d where d.token = btrim(coalesce(forget_push_device.token, ''));
$$;

-- ---------------------------------------------------------------- what changed in a save

-- Every (month, payer) marked in one of a month's maps (paid or fines).
create or replace function public.push_flags(data jsonb, field text) returns table (n int, payer text)
language sql immutable set search_path = '' as $$
  select (m ->> 'n')::int, e.key
  from jsonb_array_elements(case when jsonb_typeof(data -> 'months') = 'array' then data -> 'months' else '[]'::jsonb end) m,
       jsonb_each(case when jsonb_typeof(m -> field) = 'object' then m -> field else '{}'::jsonb end) e
  where e.value = 'true'::jsonb and (m ->> 'n') ~ '^[0-9]{1,4}$';
$$;

-- The name of the person paying through a payer place, or null.
create or replace function public.push_payer_name(data jsonb, payer text) returns text
language sql immutable set search_path = '' as $$
  select nullif(btrim(pe ->> 'name'), '')
  from jsonb_array_elements(case when jsonb_typeof(data -> 'payers') = 'array' then data -> 'payers' else '[]'::jsonb end) pa
  join jsonb_array_elements(case when jsonb_typeof(data -> 'people') = 'array' then data -> 'people' else '[]'::jsonb end) pe
    on pe ->> 'id' = pa ->> 'person'
  where pa ->> 'id' = payer
  limit 1;
$$;

-- "Farhan / Yasir": everyone paying through a slot, as the app shows it.
create or replace function public.push_slot_name(data jsonb, slot int) returns text
language sql immutable set search_path = '' as $$
  select string_agg(public.push_payer_name(data, pa ->> 'id'), ' / ' order by o)
  from jsonb_array_elements(case when jsonb_typeof(data -> 'payers') = 'array' then data -> 'payers' else '[]'::jsonb end)
       with ordinality x(pa, o)
  where (pa ->> 'slot') = slot::text;
$$;

-- "Riverside 5K Chit": the group and the chit's name, as the app shows it.
create or replace function public.push_chit_name(data jsonb) returns text
language sql immutable set search_path = '' as $$
  select coalesce(nullif(btrim(coalesce(data ->> 'group', '') || ' ' || coalesce(data ->> 'name', '')), ''), 'Kuree');
$$;

-- One line in the outbox for each kind of change in a save: payments marked
-- paid, marked not paid, marked late (each counted, with the person's name
-- when it is one person), and each month whose draw was just made.
create or replace function public.push_kuri_saved() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  o jsonb := old.data;
  d jsonb := new.data;
  chit text := public.push_chit_name(new.data);
  who text := coalesce(public.my_name(), '');
  r record;
  kinds text[] := array['paid', 'unpaid', 'late'];
  kind text;
  payers text[];
  names text[];
begin
  -- Only changes made by someone signed in to the app.
  if auth.uid() is null then return null; end if;
  foreach kind in array kinds loop
    if kind = 'unpaid' then
      select array_agg(x.payer), array_agg(distinct public.push_payer_name(d, x.payer))
        into payers, names
        from (select * from public.push_flags(o, 'paid') except select * from public.push_flags(d, 'paid')) x
       -- months still in the chit (fewer slots is not "not paid")
       where x.n in (select (m ->> 'n')::int
                     from jsonb_array_elements(case when jsonb_typeof(d -> 'months') = 'array' then d -> 'months' else '[]'::jsonb end) m
                     where (m ->> 'n') ~ '^[0-9]{1,4}$');
    else
      select array_agg(x.payer), array_agg(distinct public.push_payer_name(d, x.payer))
        into payers, names
        from (select * from public.push_flags(d, case kind when 'paid' then 'paid' else 'fines' end)
              except select * from public.push_flags(o, case kind when 'paid' then 'paid' else 'fines' end)) x;
    end if;
    if coalesce(array_length(payers, 1), 0) > 0 then
      insert into public.push_outbox (kuri_id, kind, args, actor_user, actor_email, actor_phone)
      values (new.id, kind, jsonb_strip_nulls(jsonb_build_object(
                'chit', chit, 'by', who, 'n', array_length(payers, 1),
                'who', case when array_length(names, 1) = 1 then names[1] end)),
              auth.uid(), public.me(), public.my_phone());
    end if;
  end loop;
  -- The draw: a month that had no one taking the pot and now has.
  for r in
    select (nm ->> 'n')::int as n, (nm ->> 'winner')::int as slot
    from jsonb_array_elements(case when jsonb_typeof(d -> 'months') = 'array' then d -> 'months' else '[]'::jsonb end) nm
    where (nm ->> 'n') ~ '^[0-9]{1,4}$' and (nm ->> 'winner') ~ '^[0-9]{1,4}$' and (nm ->> 'winner')::int > 0
      and not exists (
        select 1 from jsonb_array_elements(case when jsonb_typeof(o -> 'months') = 'array' then o -> 'months' else '[]'::jsonb end) om
        where om ->> 'n' = nm ->> 'n' and (om ->> 'winner') ~ '^[0-9]{1,4}$' and (om ->> 'winner')::int > 0)
  loop
    insert into public.push_outbox (kuri_id, kind, args, actor_user, actor_email, actor_phone)
    values (new.id, 'draw', jsonb_strip_nulls(jsonb_build_object(
              'chit', chit, 'by', who, 'm', r.n, 'slot', r.slot, 'who', public.push_slot_name(d, r.slot))),
            auth.uid(), public.me(), public.my_phone());
  end loop;
  perform pg_notify('kuree_push', new.id::text);
  return null;
end $$;

drop trigger if exists kuris_push on public.kuris;
create trigger kuris_push after update of data on public.kuris
  for each row when (old.data is distinct from new.data)
  execute function public.push_kuri_saved();

-- A co-admin added by the owner hears about it.
create or replace function public.push_admin_added() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or new.role <> 'admin' then return null; end if;
  insert into public.push_outbox (kuri_id, kind, args, actor_user, actor_email, actor_phone, to_email, to_phone)
  select new.kuri_id, 'admin_added',
         jsonb_build_object('chit', public.push_chit_name(k.data), 'by', coalesce(public.my_name(), '')),
         auth.uid(), public.me(), public.my_phone(), new.email, new.phone
  from public.kuris k where k.id = new.kuri_id;
  perform pg_notify('kuree_push', new.kuri_id::text);
  return null;
end $$;

drop trigger if exists kuri_admins_push on public.kuri_admins;
create trigger kuri_admins_push after insert on public.kuri_admins
  for each row execute function public.push_admin_added();

-- ---------------------------------------------------------------- for the sender

-- The phones one outbox line goes to: the chit's admins (by account, number
-- or email), or for admin_added the person added; never the person who made
-- the change.
create or replace function public.push_recipients(outbox_id bigint)
returns table (token text, platform text, lang text)
language sql stable security definer set search_path = '' as $$
  select d.token, d.platform, d.lang
  from public.push_outbox o
  join public.push_devices d on
    case when o.kind = 'admin_added' then
      (o.to_email is not null and d.email = o.to_email) or (o.to_phone is not null and d.phone = o.to_phone)
    else exists (
      select 1 from public.kuri_admins a
      where a.kuri_id = o.kuri_id
        and (a.user_id = d.user_id or (a.email is not null and a.email = d.email) or (a.phone is not null and a.phone = d.phone)))
    end
  where o.id = outbox_id
    and not coalesce(d.user_id = o.actor_user or d.email = o.actor_email or d.phone = o.actor_phone, false);
$$;

-- When an account is deleted, its phones stop getting messages.
create or replace function public.forget_push_devices() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.push_devices d where d.user_id = old.id;
  return old;
end $$;
drop trigger if exists push_devices_forget on auth.users;
create trigger push_devices_forget after delete on auth.users
  for each row execute function public.forget_push_devices();

-- ---------------------------------------------------------------- who may call what

revoke execute on function
  public.register_push_device(text, text, text), public.forget_push_device(text),
  public.push_flags(jsonb, text), public.push_payer_name(jsonb, text), public.push_slot_name(jsonb, int),
  public.push_chit_name(jsonb), public.push_kuri_saved(), public.push_admin_added(),
  public.push_recipients(bigint), public.forget_push_devices()
  from public, anon, authenticated;
grant execute on function public.register_push_device(text, text, text) to authenticated;
grant execute on function public.forget_push_device(text) to anon, authenticated;
