-- Kuree starts clean: nothing is carried over from boystown.skifi.co any more.
-- The one-time Boystown import (0002) is removed. whoami goes back to its first
-- shape, so no app build offers "Bring in your 5K chit" again, and the import
-- functions and the owner's phone list are dropped. Chits already in Kuree are
-- left as they are.

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

drop function if exists public.import_boystown(jsonb, jsonb);
drop function if exists public.note_boystown_owner_phone(text);
drop function if exists public.boystown_import_open();
drop function if exists public.boystown_owner();
drop table if exists public.boystown_owner_phones;
