-- Run as postgres against an isolated backend or staging; no data changes.
begin;
do $$
declare actor text;
begin
  foreach actor in array array['anon','authenticated','service_role'] loop
    if has_function_privilege(actor, 'private.enqueue_push_dispatch()', 'execute') then
      raise exception '% can invoke the scheduler', actor;
    end if;
    -- Vault remains accessible to Supabase's trusted service role by platform
    -- design. Client roles must not read it. pg_net grants are platform-owned;
    -- verify that its schema is not API-exposed in the HTTP smoke check.
    if actor <> 'service_role' and (
        has_schema_privilege(actor, 'vault', 'usage')
        or has_table_privilege(actor, 'vault.decrypted_secrets', 'select')) then
      raise exception '% can read Vault', actor;
    end if;
    execute format('set local role %I', actor);
    begin
      perform private.enqueue_push_dispatch();
      raise exception '% invoked the private scheduler', actor;
    exception when insufficient_privilege then null;
    end;
    if actor <> 'service_role' then
      begin
        perform 1 from vault.decrypted_secrets limit 1;
        raise exception '% read Vault', actor;
      exception when insufficient_privilege then null;
      end;
    end if;
    execute 'reset role';
  end loop;
  if not has_table_privilege('service_role', 'public.device_tokens', 'select')
      or not has_table_privilege('service_role', 'public.device_tokens', 'delete') then
    raise exception 'Sender cannot maintain delivery tokens';
  end if;
end $$;
select 'PASS: clients cannot read Vault; anon/authenticated/service_role cannot invoke private scheduler; sender token access retained' as result;
rollback;
