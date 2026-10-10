-- Run only on petfriendly-staging after migrations 023–024 and Vault setup.
-- Leave inactive until FIREBASE_SERVICE_ACCOUNT_JSON has passed a credential test.
begin;
do $$begin
  if (select decrypted_secret from vault.decrypted_secrets
      where name = 'petfriendly_push_project_url')
      is distinct from 'https://cbkmxtplhcdomyeyrwyi.supabase.co' then
    raise exception 'Wrong staging project';
  end if;
  if not exists (select 1 from vault.secrets where name = 'petfriendly_push_service_role') then
    raise exception 'Missing invocation credential';
  end if;
end $$;
select cron.schedule('petfriendly-dispatch-notifications', '* * * * *',
  'select private.enqueue_push_dispatch();');
select cron.alter_job(jobid, active := false)
  from cron.job where jobname = 'petfriendly-dispatch-notifications';
commit;
select jobname, schedule, active from cron.job
  where jobname = 'petfriendly-dispatch-notifications';
