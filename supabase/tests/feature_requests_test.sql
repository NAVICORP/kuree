-- Run against a scratch database after platform.sql and the migrations:
--   psql -v ON_ERROR_STOP=1 -f supabase/tests/feature_requests_test.sql
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

-- Signed out: nothing
select pg_temp.as_anon();
do $$ begin
  perform public.request_feature('A dark mode');
  raise exception 'FAILED: anon could ask for a feature';
exception when insufficient_privilege then raise notice 'ok: signed-out people cannot ask';
end $$;

-- An admin asks, and the text is cleaned
reset role;
insert into auth.users (id, email) values ('33333333-3333-3333-3333-333333333333', 'admin@example.com');
select pg_temp.as_user('33333333-3333-3333-3333-333333333333', '919000000003', 'admin@example.com');
select public.set_my_name('Riya');
insert into t values ('r1', public.request_feature('  Dark   <b>mode</b> ', E'Please add it.\r\n\n\n\n\nThanks', 'important', '1.0.0+21', 'android', 'ml'));
select pg_temp.ok((select v->>'title' from t where k='r1') = 'Dark b mode /b', 'the title is cleaned to one safe line');
select pg_temp.ok((select v->>'details' from t where k='r1') = E'Please add it.\n\nThanks', 'the details keep at most one empty line');
select pg_temp.ok((select v->>'status' from t where k='r1') = 'new', 'a new request starts as new');
select pg_temp.ok((select v ? 'email' from t where k='r1') = false, 'the sender does not get the owner fields back');
select pg_temp.ok(jsonb_array_length(public.my_feature_requests()) = 1, 'the admin sees their own request');
select pg_temp.ok(public.feature_owner() = false, 'an admin is not an owner');

-- Checks on what is sent
do $$ begin
  perform public.request_feature('ab');
  raise exception 'FAILED: a two letter title went through';
exception when sqlstate '22023' then raise notice 'ok: a title needs 3 letters';
end $$;
do $$ begin
  perform public.request_feature(repeat('x', 101));
  raise exception 'FAILED: a long title went through';
exception when sqlstate '22023' then raise notice 'ok: a title stays under 100';
end $$;
do $$ begin
  perform public.request_feature('Long details', repeat('y', 2001));
  raise exception 'FAILED: long details went through';
exception when sqlstate '22023' then raise notice 'ok: details stay under 2000';
end $$;
insert into t values ('r2', public.request_feature('Odd extras', '', 'urgent!!', '<script>', 'windows', 'not a lang'));
select pg_temp.ok((select v->'importance' from t where k='r2') = 'null'::jsonb, 'an unknown importance is dropped');

-- Up to 5 an hour
select public.request_feature('Idea three');
select public.request_feature('Idea four');
select public.request_feature('Idea five');
do $$ begin
  perform public.request_feature('Idea six');
  raise exception 'FAILED: a sixth request in an hour went through';
exception when sqlstate '54000' then raise notice 'ok: at most 5 requests an hour';
end $$;

-- The inbox is for owners only
do $$ begin
  perform public.all_feature_requests();
  raise exception 'FAILED: an admin read the inbox';
exception when insufficient_privilege then raise notice 'ok: admins cannot read every request';
end $$;
do $$ begin
  perform public.set_feature_request_status((select (v->>'id')::bigint from t where k='r1'), 'done');
  raise exception 'FAILED: an admin changed a status';
exception when insufficient_privilege then raise notice 'ok: admins cannot change a status';
end $$;

-- An owner reads them all and answers
select pg_temp.as_user('44444444-4444-4444-4444-444444444444', null, 'Contact@SkiFi.co');
select pg_temp.ok(public.feature_owner(), 'the Kuree team is an owner');
insert into t values ('all', public.all_feature_requests());
select pg_temp.ok((select (v #>> '{counts,new}')::int from t where k='all') = 5, 'the inbox counts the new requests');
select pg_temp.ok((select v #>> '{requests,0,title}' from t where k='all') = 'Idea five', 'newest first');
select pg_temp.ok((select v #>> '{requests,4,email}' from t where k='all') = 'admin@example.com', 'owners see who asked');
select pg_temp.ok((select v #>> '{requests,4,name}' from t where k='all') = 'Riya', 'owners see the name');
select public.set_feature_request_status((select (v->>'id')::bigint from t where k='r1'), 'planned', 'Coming in the next update.');
select pg_temp.ok(jsonb_array_length(public.all_feature_requests('planned') -> 'requests') = 1, 'the inbox filters by status');
do $$ begin
  perform public.set_feature_request_status((select (v->>'id')::bigint from t where k='r1'), 'maybe');
  raise exception 'FAILED: an unknown status went through';
exception when sqlstate '22023' then raise notice 'ok: only the four statuses';
end $$;

-- The admin sees the answer
select pg_temp.as_user('33333333-3333-3333-3333-333333333333', '919000000003', 'admin@example.com');
select pg_temp.ok((select x->>'owner_note' from jsonb_array_elements(public.my_feature_requests()) x where x->>'status' = 'planned') = 'Coming in the next update.', 'the admin reads the note');

-- Deleting the account keeps the idea but forgets the person
select public.delete_my_data();
reset role;
select pg_temp.ok((select count(*) from public.feature_requests where user_id is not null or email is not null) = 0, 'a deleted account leaves no name or email on its requests');
select pg_temp.ok((select count(*) from public.feature_requests) = 5, 'the ideas stay');

rollback;
