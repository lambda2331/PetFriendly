alter table private.notification_outbox add column claimed_until timestamptz;
create function public.claim_notifications() returns table(id uuid,user_id uuid,kind text,context_id uuid) language plpgsql security definer set search_path='' as $$
begin
 return query with jobs as (select o.id from private.notification_outbox o where o.delivered_at is null and o.next_attempt_at<=now() and (o.claimed_until is null or o.claimed_until<now()) order by o.next_attempt_at for update skip locked limit 25), claimed as (update private.notification_outbox o set claimed_until=now()+interval '2 minutes',attempts=attempts+1 from jobs where o.id=jobs.id returning o.id,o.notification_id) select c.id,n.user_id,n.kind,n.context_id from claimed c join public.notifications n on n.id=c.notification_id;
end $$;
create function public.finish_notification(job_in uuid, delivered boolean) returns void language plpgsql security definer set search_path='' as $$begin update private.notification_outbox set delivered_at=case when delivered then now()else null end,claimed_until=null,next_attempt_at=now()+least(3600,power(2,least(attempts,10))::integer*30)*interval '1 second' where id=job_in;end $$;
revoke all on function public.claim_notifications(),public.finish_notification(uuid,boolean) from public,anon,authenticated;
grant execute on function public.claim_notifications(),public.finish_notification(uuid,boolean) to service_role;
