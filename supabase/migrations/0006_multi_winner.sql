-- Several takers a month. A chit can run fewer months than it has slots
-- (20 slots over 10 months: two take the pot each month). Each month keeps
-- "winner", the first taker, which older apps read, and "winners", the
-- full list, when there is more than one (see app/lib/core/kuri.dart).
--
-- The push trigger now counts a draw by the list: a month with more takers
-- than before is news, naming each new one ("Month 5: Farhan and Yasir take
-- the pot"). The outbox line keeps "slot" and "who" for the first, and adds
-- "slots" and "whos" when there are several (server/push_text.mjs).

-- A month's takers, in order: "winners" when it is a list, else "winner".
-- An older app may change or clear "winner" alone; it is believed, as the
-- app does.
create or replace function public.push_winners(m jsonb) returns int[]
language sql immutable set search_path = '' as $$
  with f as (
    select case when (m ->> 'winner') ~ '^[0-9]{1,4}$' and (m ->> 'winner')::int > 0 then (m ->> 'winner')::int end as first
  ), l as (
    select coalesce(array_agg(x order by i), '{}'::int[]) as xs
    from (select distinct on (v::int) v::int as x, i
          from jsonb_array_elements_text(case when jsonb_typeof(m -> 'winners') = 'array' then m -> 'winners' else '[]'::jsonb end)
               with ordinality e(v, i)
          where v ~ '^[0-9]{1,4}$' and v::int > 0
          order by v::int, i) d
  )
  select case
    when coalesce(jsonb_typeof(m -> 'winners'), '') <> 'array' then case when f.first is null then '{}'::int[] else array[f.first] end
    when coalesce(l.xs[1], -1) = coalesce(f.first, -1) then l.xs
    when f.first is null then '{}'::int[]
    else array[f.first] || array(select u.x from unnest(l.xs[2:]) with ordinality u(x, i) where u.x <> f.first order by u.i)
  end
  from f, l;
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
  -- The draw: a month with more takers than before, with the new ones
  -- (one line per month, naming everyone new in it). A month whose taker
  -- was only changed is not news.
  for r in
    select (nm ->> 'n')::int as n,
           array(select u.x from unnest(public.push_winners(nm)) with ordinality u(x, i)
                 where u.x <> all(public.push_winners(old_month.om)) order by u.i) as slots
    from jsonb_array_elements(case when jsonb_typeof(d -> 'months') = 'array' then d -> 'months' else '[]'::jsonb end) nm
    left join lateral (
      select x.om from jsonb_array_elements(case when jsonb_typeof(o -> 'months') = 'array' then o -> 'months' else '[]'::jsonb end) x(om)
      where x.om ->> 'n' = nm ->> 'n' limit 1) prev on true
    cross join lateral (select coalesce(prev.om, '{}'::jsonb) as om) old_month
    where (nm ->> 'n') ~ '^[0-9]{1,4}$'
      and cardinality(public.push_winners(nm)) > cardinality(public.push_winners(old_month.om))
  loop
    continue when cardinality(r.slots) = 0;
    insert into public.push_outbox (kuri_id, kind, args, actor_user, actor_email, actor_phone)
    values (new.id, 'draw', jsonb_strip_nulls(jsonb_build_object(
              'chit', chit, 'by', who, 'm', r.n, 'slot', r.slots[1], 'who', public.push_slot_name(d, r.slots[1]),
              'slots', case when cardinality(r.slots) > 1 then to_jsonb(r.slots) end,
              'whos', case when cardinality(r.slots) > 1 then
                (select jsonb_agg(coalesce(public.push_slot_name(d, s.x), s.x::text) order by s.i)
                 from unnest(r.slots) with ordinality s(x, i)) end)),
            auth.uid(), public.me(), public.my_phone());
  end loop;
  perform pg_notify('kuree_push', new.id::text);
  return null;
end $$;

revoke execute on function public.push_winners(jsonb) from public, anon, authenticated;
