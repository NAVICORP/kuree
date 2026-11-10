-- An email to the Kuree team for every feature request sent in. The push
-- sender (server/feature_mail.mjs, run by server/push.mjs) mails the ones
-- not mailed yet and stamps them. Requests already in the inbox count as
-- mailed, so turning this on sends only new ones.
alter table public.feature_requests add column if not exists emailed_at timestamptz;
update public.feature_requests set emailed_at = now() where emailed_at is null;
create index if not exists feature_requests_to_mail on public.feature_requests (id) where emailed_at is null;
