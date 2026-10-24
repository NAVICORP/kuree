-- Bringing the Boystown 5K Kuri over from boystown.skifi.co, once.
--
-- The import-boystown function reads the live kuri and Members list from the
-- Boystown site, turns them into a Kuree kuri and hands it to
-- import_boystown below as the signed-in person. Only Ishaque may run it,
-- and only while there is no Boystown kuri here yet. He becomes the owner;
-- the Boystown admins named by the function become admins.

-- Ishaque's WhatsApp number(s), filled in by the function from the Boystown
-- Members list the first time he runs it signed in by email, so a later
-- sign-in by WhatsApp also counts.
create table public.boystown_owner_phones (phone text primary key check (phone ~ '^[0-9]{8,15}$'));
alter table public.boystown_owner_phones enable row level security;
revoke all on public.boystown_owner_phones from anon, authenticated;

create or replace function public.boystown_owner() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(public.me() in ('ishaquenv@gmail.com', 'ishaque@skifi.co'), false)
      or coalesce(public.my_phone() in (select phone from public.boystown_owner_phones), false);
$$;

create or replace function public.boystown_import_open() returns boolean
language sql stable security definer set search_path = '' as $$
  select public.boystown_owner()
     and not exists (select 1 from public.kuris k where k.data ->> 'source' = 'boystown-5k');
$$;

create or replace function public.whoami() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', auth.uid(),
    'email', public.me(),
    'phone', public.my_phone(),
    'name', (select nullif(btrim(p.name), '') from public.profiles p where p.user_id = auth.uid()),
    'display', public.my_name(),
    'can_import_boystown', public.boystown_import_open()
  );
$$;

-- admins: [{ "phone": "9198...", "name": "Anees Muhammed" }]
create or replace function public.import_boystown(data jsonb, admins jsonb default '[]'::jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare k jsonb; kid uuid; a jsonb; ph text;
begin
  if not public.boystown_owner() then
    raise exception 'Only the Boystown owner can bring this kuri in.' using errcode = '42501';
  end if;
  if not public.boystown_import_open() then
    raise exception 'The Boystown 5K Kuri is already in Kuree.' using errcode = '23505';
  end if;
  if data ->> 'source' is distinct from 'boystown-5k' then
    raise exception 'That is not the Boystown 5K Kuri.' using errcode = '22023';
  end if;
  if public.my_name() is null or public.my_name() like '+%' or public.my_name() like '%@%' then
    perform public.set_my_name('Ishaque');
  end if;
  k := public.create_kuri(data);
  kid := (k ->> 'id')::uuid;
  for a in select * from jsonb_array_elements(coalesce(admins, '[]'::jsonb)) loop
    ph := public.phone_digits(a ->> 'phone');
    if ph is null or ph !~ '^[0-9]{8,15}$' or ph = public.my_phone() then continue; end if;
    insert into public.kuri_admins (kuri_id, role, phone, name, added_by)
    values (kid, 'admin', ph, nullif(btrim(a ->> 'name'), ''), public.my_name())
    on conflict do nothing;
  end loop;
  return k;
end $$;

-- The function records Ishaque's number from the Members list.
create or replace function public.note_boystown_owner_phone(phone text) returns void
language plpgsql security definer set search_path = '' as $$
declare ph text := public.phone_digits(note_boystown_owner_phone.phone);
begin
  if not public.boystown_owner() then return; end if;
  if ph is null or ph !~ '^[0-9]{8,15}$' then return; end if;
  insert into public.boystown_owner_phones (phone) values (ph) on conflict do nothing;
end $$;

revoke execute on function public.boystown_owner(), public.boystown_import_open(), public.import_boystown(jsonb, jsonb),
  public.note_boystown_owner_phone(text) from public, anon;
grant execute on function public.import_boystown(jsonb, jsonb), public.note_boystown_owner_phone(text) to authenticated;
grant execute on function public.whoami() to authenticated;
