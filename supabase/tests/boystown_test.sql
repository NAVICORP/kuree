-- The one-time Boystown import: only the owner, only once.
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

-- Someone else
select pg_temp.as_user('33333333-3333-3333-3333-333333333333', '919000000009', 'someone@example.com');
select pg_temp.ok(public.whoami() ->> 'can_import_boystown' = 'false', 'others are not offered the import');
do $$ begin
  perform public.import_boystown('{"source":"boystown-5k","name":"5K Kuri","months":[],"payers":[],"people":[]}');
  raise exception 'FAILED: a stranger imported';
exception when insufficient_privilege then raise notice 'ok: a stranger cannot import';
end $$;
select public.note_boystown_owner_phone('919000000009');

-- Ishaque by email
select pg_temp.as_user('44444444-4444-4444-4444-444444444444', null, 'ishaque@skifi.co');
select pg_temp.ok(public.whoami() ->> 'can_import_boystown' = 'true', 'Ishaque is offered the import');
select public.note_boystown_owner_phone('+91 90000 00005');
select public.import_boystown('{"source":"boystown-5k","name":"5K Kuri","group":"Boystown","months":[{"n":1,"winner":4,"paid":{"p1":true},"fines":{}}],"payers":[{"id":"p1","slot":1,"person":"m1","amt":5000}],"people":[{"id":"m1","name":"Nazil"}]}',
  '[{"name":"Anees Muhammed","phone":"+91 90000 00004"}]');
select pg_temp.ok(public.whoami() ->> 'can_import_boystown' = 'false', 'the import is offered only once');
select pg_temp.ok(public.my_kuris() -> 0 ->> 'role' = 'owner', 'Ishaque owns it');

-- Ishaque by WhatsApp later, and Anees as admin
select pg_temp.as_user('55555555-5555-5555-5555-555555555555', '919000000005', null);
select pg_temp.ok(jsonb_array_length(public.my_kuris()) = 0, 'a different account with his number is not the owner of the kuri');
select pg_temp.as_user('66666666-6666-6666-6666-666666666666', '919000000004', null);
select pg_temp.ok(public.my_kuris() -> 0 ->> 'role' = 'admin', 'Anees is an admin');
select pg_temp.as_user('33333333-3333-3333-3333-333333333333', '919000000009', 'someone@example.com');
select pg_temp.ok(not exists (select 1 from jsonb_array_elements(public.my_kuris())), 'the stranger''s noted number did nothing');
rollback;
