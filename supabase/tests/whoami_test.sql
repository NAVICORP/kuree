-- whoami, and that the old Boystown import is gone (0004).
-- Run against a scratch database after platform.sql and the migrations.
begin;
create or replace function pg_temp.as_user(sub text, phone text, email text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', sub, 'role', 'authenticated', 'phone', phone, 'email', email)::text, true);
  execute 'set local role authenticated';
end $$;
create or replace function pg_temp.ok(cond boolean, what text) returns void language plpgsql as $$
begin
  if not coalesce(cond, false) then raise exception 'FAILED: %', what; end if;
  raise notice 'ok: %', what;
end $$;
grant execute on function pg_temp.as_user(text, text, text), pg_temp.ok(boolean, text) to authenticated;

select pg_temp.ok(to_regprocedure('public.import_boystown(jsonb,jsonb)') is null, 'the Boystown import function is gone');
select pg_temp.ok(to_regprocedure('public.boystown_owner()') is null, 'the Boystown owner check is gone');
select pg_temp.ok(to_regclass('public.boystown_owner_phones') is null, 'the Boystown owner phone list is gone');

-- Ishaque, who used to be offered the import
select pg_temp.as_user('44444444-4444-4444-4444-444444444444', '919000000005', 'ishaque@skifi.co');
select pg_temp.ok(not (public.whoami() ? 'can_import_boystown'), 'nobody is offered the Boystown import');
select pg_temp.ok(public.whoami() ->> 'email' = 'ishaque@skifi.co', 'whoami still says who is signed in');
reset role;

rollback;
