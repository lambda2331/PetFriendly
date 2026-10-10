-- Keep the invocation credential outside the client API. Supabase's trusted
-- service role retains platform-owned Vault grants; no client uses that role.
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

revoke all on schema vault, net, cron from public, anon, authenticated, service_role;
revoke all on all tables in schema vault, net, cron from public, anon, authenticated, service_role;
-- Platform-owned grants may survive these revokes, especially pg_net PUBLIC
-- and Vault service_role grants. Keep vault/net/cron out of exposed API schemas
-- and grant database LOGIN only to trusted operators. See the deployment docs.

create function private.enqueue_push_dispatch() returns bigint
language plpgsql security definer set search_path = '' as $$
declare
  project_url text;
  invocation_key text;
begin
  -- Avoid requests and Google token exchanges when there is no work.
  if not exists (
    select 1 from private.notification_outbox o
    where o.delivered_at is null and o.next_attempt_at <= now()
      and (o.claimed_until is null or o.claimed_until < now())
  ) then return null; end if;

  select decrypted_secret into project_url from vault.decrypted_secrets
    where name = 'petfriendly_push_project_url';
  select decrypted_secret into invocation_key from vault.decrypted_secrets
    where name = 'petfriendly_push_service_role';
  if project_url is null or project_url !~ '^https://[a-z]{20}\.supabase\.co$'
      or invocation_key is null then
    raise exception 'Push scheduler is not configured';
  end if;

  return net.http_post(
    url := project_url || '/functions/v1/dispatch-notifications',
    headers := jsonb_build_object('Content-Type', 'application/json',
      'Authorization', 'Bearer ' || invocation_key),
    body := '{}'::jsonb,
    timeout_milliseconds := 20000
  );
end;
$$;
revoke all on function private.enqueue_push_dispatch() from public, anon, authenticated, service_role;
-- Activation is a separate staging step, after Secrets and Vault are configured.
