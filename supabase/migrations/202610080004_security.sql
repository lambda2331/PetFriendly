drop view public.helper_ratings;
create function public.helper_stats() returns table(id uuid, rating numeric, review_count bigint, completed bigint) language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_actor();begin
return query select p.id,r.rating,coalesce(r.review_count,0),coalesce(a.completed,0) from public.profiles p left join(select helper_id,avg(w.rating)::numeric as rating,count(*) as review_count from public.walk_reviews w where published group by helper_id) r on r.helper_id=p.id left join(select a.helper_id,count(*) as completed from public.walk_agreements a join public.walk_requests w on w.id=a.request_id where w.status='completed' group by a.helper_id) a on a.helper_id=p.id where private.public_account(p.id) and not private.blocked(actor,p.id);
end $$;
revoke all on function public.helper_stats() from public,anon;grant execute on function public.helper_stats() to authenticated;
create table private.action_rates(user_id uuid references auth.users on delete cascade,kind text,bucket timestamptz,hits integer not null default 1,primary key(user_id,kind,bucket));
create function private.rate_limit(actor uuid, action text, max_hits integer) returns void language plpgsql security definer set search_path='' as $$ declare used integer;begin insert into private.action_rates values(actor,action,date_trunc('minute',now()),1) on conflict(user_id,kind,bucket) do update set hits=private.action_rates.hits+1 returning hits into used;if used>max_hits then raise exception 'Rate limit exceeded' using errcode='P0001';end if;end $$;
revoke all on function private.rate_limit(uuid,text,integer) from public,authenticated;
-- Deletion removes personal rows and anonymizes a helper's link in past agreements.
alter table public.walk_agreements drop constraint walk_agreements_helper_id_fkey;
alter table public.walk_agreements alter column helper_id drop not null;
alter table public.walk_agreements add constraint walk_agreements_helper_id_fkey foreign key(helper_id) references public.profiles on delete set null;
alter table public.walk_reviews drop constraint walk_reviews_helper_id_fkey;
alter table public.walk_reviews add constraint walk_reviews_helper_id_fkey foreign key(helper_id) references public.profiles on delete cascade;
create function public.deletion_authorized(user_in uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from private.accounts where id=user_in and deletion_requested_at is not null) $$;
revoke all on function public.deletion_authorized(uuid) from public,anon,authenticated;grant execute on function public.deletion_authorized(uuid) to service_role;
