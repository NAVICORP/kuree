-- Run against a scratch database after platform.sql and the migrations:
--   psql -v ON_ERROR_STOP=1 -f supabase/tests/kuree_test.sql
-- Every check raises if it fails. Nothing is left behind (rolled back).
begin;

create or replace function pg_temp.as_user(sub text, phone text, email text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', sub, 'role', 'authenticated', 'phone', phone, 'email', email)::text, true);
  execute 'set local role authenticated';
end $$;
create or replace function pg_temp.as_anon() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
end $$;
create or replace function pg_temp.ok(cond boolean, what text) returns void language plpgsql as $$
begin
  if not coalesce(cond, false) then raise exception 'FAILED: %', what; end if;
  raise notice 'ok: %', what;
end $$;
grant execute on function pg_temp.as_user(text, text, text), pg_temp.as_anon(), pg_temp.ok(boolean, text) to anon, authenticated;

create temp table t (k text primary key, v jsonb);
grant all on t to anon, authenticated;

-- An owner makes a kuri
select pg_temp.as_user('11111111-1111-1111-1111-111111111111', '919000000001', 'owner@example.com');
select public.set_my_name('Ishaque');
insert into t values ('k1', public.create_kuri('{"name":"5K Kuri","group":"Boystown","months":[{"n":1,"paid":{},"fines":{}}],"payers":[{"id":"p1","slot":1,"person":"a"}],"people":[{"id":"a","name":"Nazil","phone":"919111111111"}]}'));
select pg_temp.ok((select v->>'role' from t where k = 'k1') = 'owner', 'creator is the owner');
select pg_temp.ok(jsonb_array_length(public.my_kuris()) = 1, 'owner sees the kuri');
select pg_temp.ok((select v->>'updated_by' from t where k='k1') = 'Ishaque', 'saves carry the name');

-- Saving, and a stale save is refused
insert into t values ('s1', public.save_kuri((select (v->>'id')::uuid from t where k='k1'),
  '{"name":"5K Kuri","group":"Boystown","months":[{"n":1,"paid":{"p1":true},"fines":{}}],"payers":[{"id":"p1","slot":1,"person":"a"}],"people":[{"id":"a","name":"Nazil","phone":"919111111111"}]}',
  (select (v->>'updated_at')::timestamptz from t where k='k1')));
do $$ begin
  perform public.save_kuri((select (v->>'id')::uuid from t where k='k1'),
    '{"name":"Stale","months":[],"payers":[],"people":[]}', (select (v->>'updated_at')::timestamptz from t where k='k1'));
  raise exception 'FAILED: stale save went through';
exception when sqlstate 'PT409' then raise notice 'ok: a stale save is refused';
end $$;
select pg_temp.ok(jsonb_array_length(public.kuri_versions((select (v->>'id')::uuid from t where k='k1'))) = 1, 'the old version is kept');

-- The members' link has no phone numbers
select pg_temp.as_anon();
select pg_temp.ok(public.shared_kuri((select v->>'share_token' from t where k='k1')) #>> '{data,people,0,name}' = 'Nazil', 'link shows names');
select pg_temp.ok(public.shared_kuri((select v->>'share_token' from t where k='k1')) #> '{data,people,0}' ? 'phone' = false, 'link hides phones');
select pg_temp.ok(public.shared_kuri('not-a-real-token-at-all') is null, 'a wrong link shows nothing');
do $$ begin
  perform public.my_kuris();
  raise exception 'FAILED: anon could list kuris';
exception when insufficient_privilege then raise notice 'ok: signed-out people cannot call admin functions';
end $$;

-- A stranger cannot read or save it
select pg_temp.as_user('22222222-2222-2222-2222-222222222222', '919000000002', null);
select pg_temp.ok(jsonb_array_length(public.my_kuris()) = 0, 'stranger sees nothing');
do $$ begin
  perform public.get_kuri((select (v->>'id')::uuid from t where k='k1'));
  raise exception 'FAILED: stranger read the kuri';
exception when insufficient_privilege then raise notice 'ok: stranger cannot read it';
end $$;

-- The owner adds that number as a co-admin; now they see it and can save
select pg_temp.as_user('11111111-1111-1111-1111-111111111111', '919000000001', 'owner@example.com');
select public.add_kuri_admin((select (v->>'id')::uuid from t where k='k1'), '90000 00002', null, 'Anees');
select pg_temp.as_user('22222222-2222-2222-2222-222222222222', '919000000002', null);
select pg_temp.ok(public.my_kuris() -> 0 ->> 'role' = 'admin', 'co-admin sees the kuri by their number');
select public.save_kuri((select (v->>'id')::uuid from t where k='k1'),
  '{"name":"5K Kuri","group":"Boystown","months":[{"n":1,"paid":{"p1":true},"fines":{"p1":true}}],"payers":[{"id":"p1","slot":1,"person":"a"}],"people":[{"id":"a","name":"Nazil"}]}', null);
do $$ begin
  perform public.delete_kuri((select (v->>'id')::uuid from t where k='k1'));
  raise exception 'FAILED: an admin deleted the kuri';
exception when insufficient_privilege then raise notice 'ok: only the owner can delete';
end $$;

-- Resetting the link stops the old one
select pg_temp.as_user('11111111-1111-1111-1111-111111111111', '919000000001', 'owner@example.com');
insert into t values ('r1', public.reset_share_link((select (v->>'id')::uuid from t where k='k1')));
select pg_temp.as_anon();
select pg_temp.ok(public.shared_kuri((select v->>'share_token' from t where k='k1')) is null, 'old link stops working');
select pg_temp.ok(public.shared_kuri((select v->>'share_token' from t where k='r1')) is not null, 'new link works');

-- Restoring an older version
select pg_temp.as_user('11111111-1111-1111-1111-111111111111', '919000000001', 'owner@example.com');
select public.restore_kuri((select (x->>'id')::bigint from jsonb_array_elements(public.kuri_versions((select (v->>'id')::uuid from t where k='k1'))) x order by (x->>'saved_at') limit 1));
select pg_temp.ok(public.get_kuri((select (v->>'id')::uuid from t where k='k1')) #> '{data,months,0,paid}' = '{}'::jsonb, 'restore puts the first version back');

-- Deleting the owner's account hands the kuri to the co-admin
select public.delete_my_data();
select pg_temp.ok(jsonb_array_length(public.my_kuris()) = 0, 'deleted owner no longer sees it');
select pg_temp.as_user('22222222-2222-2222-2222-222222222222', '919000000002', null);
select pg_temp.ok(public.my_kuris() -> 0 ->> 'role' = 'owner', 'co-admin becomes the owner');
select public.delete_my_data();
reset role;
select pg_temp.ok((select count(*) from public.kuris) = 0, 'the last admin leaving deletes the kuri');

rollback;
