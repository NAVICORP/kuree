-- Push notifications: phones, what a save puts in the outbox, and who gets it.
-- Run after platform.sql and the migrations:
--   psql -v ON_ERROR_STOP=1 -f supabase/tests/push_test.sql
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
-- The sender: the database owner, no one signed in.
create or replace function pg_temp.as_server() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;
create or replace function pg_temp.ok(cond boolean, what text) returns void language plpgsql as $$
begin
  if not coalesce(cond, false) then raise exception 'FAILED: %', what; end if;
  raise notice 'ok: %', what;
end $$;
grant execute on function pg_temp.as_user(text, text, text), pg_temp.as_anon(), pg_temp.ok(boolean, text) to anon, authenticated;

create temp table t (k text primary key, v jsonb);
grant all on t to anon, authenticated;

-- A chit for three people, slot 2 shared by Farhan and Yasir.
create or replace function pg_temp.doc(paid jsonb, fines jsonb, winner int) returns jsonb language sql as $$
  select jsonb_build_object('name', '5K Chit', 'group', 'Riverside',
    'months', jsonb_build_array(jsonb_build_object('n', 1, 'paid', paid, 'fines', fines, 'winner', winner),
                                jsonb_build_object('n', 2, 'paid', '{}'::jsonb, 'fines', '{}'::jsonb)),
    'payers', '[{"id":"p1","slot":1,"person":"a"},{"id":"p2","slot":2,"person":"b"},{"id":"p3","slot":2,"person":"c"}]'::jsonb,
    'people', '[{"id":"a","name":"Nazil"},{"id":"b","name":"Farhan"},{"id":"c","name":"Yasir"}]'::jsonb);
$$;
grant execute on function pg_temp.doc(jsonb, jsonb, int) to authenticated;
create or replace function pg_temp.save(k text, data jsonb) returns void language sql as $$
  update t set v = public.save_kuri((select (v ->> 'id')::uuid from t where t.k = 'k1'), data, null) where t.k = 'k1';
$$;
grant execute on function pg_temp.save(text, jsonb) to authenticated;

-- The owner makes the chit and turns on notifications on their phone
select pg_temp.as_user('11111111-1111-1111-1111-111111111111', '919000000001', 'owner@example.com');
select public.set_my_name('Ishaque');
insert into t values ('k1', public.create_kuri(pg_temp.doc('{}', '{}', null)));
select public.register_push_device('owner-phone-token-0000000001', 'android', 'en');
select public.register_push_device('owner-phone-token-0000000001', 'android', 'en');
do $$ begin
  perform public.register_push_device('short', 'android', 'en');
  raise exception 'FAILED: a short token was taken';
exception when sqlstate '22023' then raise notice 'ok: a bad token is refused';
end $$;
do $$ begin
  perform public.register_push_device('owner-phone-token-0000000009', 'windows', 'en');
  raise exception 'FAILED: an unknown platform was taken';
exception when sqlstate '22023' then raise notice 'ok: an unknown platform is refused';
end $$;
do $$ begin
  perform count(*) from public.push_devices;
  raise exception 'FAILED: the phones table can be read';
exception when insufficient_privilege then raise notice 'ok: nobody reads the phones table directly';
end $$;

-- The owner adds a co-admin by email: one outbox line, for the person added
select public.add_kuri_admin((select (v ->> 'id')::uuid from t where k = 'k1'), null, 'co@example.com', 'Anees');
select pg_temp.as_server();
select pg_temp.ok((select count(*) from public.push_outbox where kind = 'admin_added') = 1, 'adding a co-admin leaves a line');
select pg_temp.ok((select args ->> 'chit' from public.push_outbox where kind = 'admin_added') = 'Riverside 5K Chit', 'with the chit''s name');
select pg_temp.ok((select args ->> 'by' from public.push_outbox where kind = 'admin_added') = 'Ishaque', 'and who added them');
select pg_temp.ok((select count(*) from public.push_recipients((select id from public.push_outbox where kind = 'admin_added'))) = 0,
  'nobody to tell before the co-admin has a phone registered');
select pg_temp.ok((select count(*) from public.push_outbox where kind = 'admin_added' and to_email = 'co@example.com') = 1, 'it is for the email added');

-- The co-admin signs in with that email and turns notifications on (Malayalam)
select pg_temp.as_user('22222222-2222-2222-2222-222222222222', null, 'co@example.com');
select public.register_push_device('coadmin-phone-token-000000001', 'ios', 'ml');
select pg_temp.as_server();
select pg_temp.ok((select string_agg(token || ':' || lang, ',') from public.push_recipients((select id from public.push_outbox where kind = 'admin_added')))
  = 'coadmin-phone-token-000000001:ml', 'now the added co-admin gets it, in their language');
delete from public.push_outbox;

-- The co-admin marks Nazil paid: the owner hears, the co-admin does not
select pg_temp.as_user('22222222-2222-2222-2222-222222222222', null, 'co@example.com');
select pg_temp.save('k1', pg_temp.doc('{"p1":true}', '{}', null));
select pg_temp.as_server();
select pg_temp.ok((select count(*) from public.push_outbox) = 1, 'one save, one line');
select pg_temp.ok((select kind = 'paid' and (args ->> 'n')::int = 1 and args ->> 'who' = 'Nazil' from public.push_outbox), 'Nazil marked paid');
select pg_temp.ok((select args ->> 'by' from public.push_outbox) = 'Anees', 'by the co-admin, by the name the owner gave');
select pg_temp.ok((select string_agg(token, ',') from public.push_recipients((select id from public.push_outbox)))
  = 'owner-phone-token-0000000001', 'the owner hears, the one who did it does not');
delete from public.push_outbox;

-- The owner marks Farhan and Yasir paid, Nazil not paid, Nazil late, and draws slot 2
select pg_temp.as_user('11111111-1111-1111-1111-111111111111', '919000000001', 'owner@example.com');
select pg_temp.save('k1', pg_temp.doc('{"p2":true,"p3":true}', '{"p1":true}', 2));
select pg_temp.as_server();
select pg_temp.ok((select count(*) from public.push_outbox) = 4, 'four kinds of change, four lines');
select pg_temp.ok((select (args ->> 'n')::int = 2 and not args ? 'who' from public.push_outbox where kind = 'paid'), 'two paid, two people: a count');
select pg_temp.ok((select (args ->> 'n')::int = 1 and args ->> 'who' = 'Nazil' from public.push_outbox where kind = 'unpaid'), 'Nazil not paid');
select pg_temp.ok((select args ->> 'who' = 'Nazil' from public.push_outbox where kind = 'late'), 'Nazil late');
select pg_temp.ok((select (args ->> 'm')::int = 1 and (args ->> 'slot')::int = 2 and args ->> 'who' = 'Farhan / Yasir'
  from public.push_outbox where kind = 'draw'), 'the draw: month 1, Farhan / Yasir');
select pg_temp.ok((select bool_and((select string_agg(token, ',') from public.push_recipients(o.id)) = 'coadmin-phone-token-000000001')
  from public.push_outbox o), 'all to the co-admin only');
delete from public.push_outbox;

-- The same document again changes nothing and says nothing; a draw already made is not news
select pg_temp.as_user('11111111-1111-1111-1111-111111111111', '919000000001', 'owner@example.com');
select pg_temp.save('k1', pg_temp.doc('{"p2":true,"p3":true}', '{"p1":true}', 2));
select pg_temp.save('k1', pg_temp.doc('{"p2":true,"p3":true,"p1":true}', '{"p1":true}', 2));
select pg_temp.as_server();
select pg_temp.ok((select string_agg(kind, ',') from public.push_outbox) = 'paid', 'only the new payment');
delete from public.push_outbox;

-- A change made on the server itself (no one signed in) tells nobody
update public.kuris set data = pg_temp.doc('{}', '{}', null);
select pg_temp.ok((select count(*) from public.push_outbox) = 0, 'server-side changes are quiet');

-- Signed out, the app forgets its phone; a stranger cannot register for someone else
select pg_temp.as_anon();
do $$ begin
  perform public.register_push_device('anon-phone-token-000000000001', 'android', 'en');
  raise exception 'FAILED: signed out registration went through';
exception when insufficient_privilege then raise notice 'ok: signing in is needed to register';
end $$;
select public.forget_push_device('coadmin-phone-token-000000001');
select pg_temp.as_server();
select pg_temp.ok(not exists (select 1 from public.push_devices where token = 'coadmin-phone-token-000000001'), 'a forgotten phone is gone');

-- A phone that changes hands moves to the new account
select pg_temp.as_user('33333333-3333-3333-3333-333333333333', '919000000003', null);
select public.register_push_device('owner-phone-token-0000000001', 'android', 'hi');
select pg_temp.as_server();
select pg_temp.ok((select user_id = '33333333-3333-3333-3333-333333333333' and lang = 'hi' and email is null
  from public.push_devices where token = 'owner-phone-token-0000000001'), 'the phone moved to the new account');

-- Deleting an account deletes its phones
insert into auth.users (id) values ('33333333-3333-3333-3333-333333333333') on conflict do nothing;
delete from auth.users where id = '33333333-3333-3333-3333-333333333333';
select pg_temp.ok(not exists (select 1 from public.push_devices where user_id = '33333333-3333-3333-3333-333333333333'), 'a deleted account''s phones are gone');

rollback;
