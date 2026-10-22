-- Separate directional reviews preserve the existing helper-review API/UI.
create table public.walk_owner_reviews (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.walk_requests on delete cascade,
  author_id uuid not null references public.profiles on delete cascade,
  owner_id uuid not null references public.profiles on delete cascade,
  rating integer not null check(rating between 1 and 5),
  body text not null default '' check(char_length(body)<=1000),
  published boolean not null default true,
  owner_reply text not null default '' check(char_length(owner_reply)<=1000),
  replied_at timestamptz,
  created_at timestamptz not null default now(),
  check(author_id<>owner_id)
);
create index owner_review_profile on public.walk_owner_reviews(owner_id,created_at,id);
alter table public.walk_owner_reviews enable row level security;
revoke all on public.walk_owner_reviews from public,anon,authenticated;
grant select on public.walk_owner_reviews to authenticated;
create policy owner_review_read on public.walk_owner_reviews for select using(
  private.actor() is not null and published and private.public_account(owner_id)
  and private.public_account(author_id) and not private.blocked(private.actor(),owner_id)
  and not private.blocked(private.actor(),author_id));

drop policy walk_review_read on public.walk_reviews;
create policy walk_review_read on public.walk_reviews for select using(
  private.actor() is not null and published and private.public_account(helper_id)
  and private.public_account(author_id) and not private.blocked(private.actor(),helper_id)
  and not private.blocked(private.actor(),author_id));

create or replace function public.reply_walk_review(review_in uuid,body_in text) returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); review public.walk_reviews;
begin
  if body_in is null or char_length(trim(body_in)) not between 1 and 1000 then
    raise exception 'Invalid reply' using errcode='22023'; end if;
  select * into review from public.walk_reviews where id=review_in for update;
  if review.id is null or review.helper_id<>actor or not review.published
    or not private.public_account(review.author_id) or private.blocked(actor,review.author_id)
    or not exists(select 1 from public.walk_requests w join public.walk_agreements a on a.request_id=w.id
      where w.id=review.request_id and w.status='completed' and a.helper_id=actor
        and w.owner_id=review.author_id and w.owner_id<>actor) then
    raise exception 'Reply not allowed' using errcode='42501'; end if;
  update public.walk_reviews set helper_reply=trim(body_in),replied_at=now() where id=review_in;
end $$;

create function public.review_walk_owner(request_in uuid,rating_in integer,body_in text default '') returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests; helper uuid;
begin
  select * into item from public.walk_requests where id=request_in for update;
  select helper_id into helper from public.walk_agreements where request_id=request_in;
  if item.id is null or helper is distinct from actor or item.owner_id=actor
    or item.status<>'completed' or not private.public_account(item.owner_id)
    or private.blocked(actor,item.owner_id) then
    raise exception 'Owner review not allowed' using errcode='42501'; end if;
  if rating_in is null or rating_in not between 1 and 5 or body_in is null
    or char_length(body_in)>1000 then raise exception 'Invalid review' using errcode='22023'; end if;
  insert into public.walk_owner_reviews(request_id,author_id,owner_id,rating,body)
    values(request_in,actor,item.owner_id,rating_in,trim(body_in));
end $$;

-- Keep old signature, strengthen eligibility and lock the same agreement.
create or replace function public.review_walk(request_in uuid,rating_in integer,body_in text default '') returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests; helper uuid;
begin
  select * into item from public.walk_requests where id=request_in for update;
  select helper_id into helper from public.walk_agreements where request_id=request_in;
  if item.id is null or item.owner_id<>actor or item.status<>'completed' or helper is null
    or helper=actor or not private.public_account(helper) or private.blocked(actor,helper) then
    raise exception 'Helper review not allowed' using errcode='42501'; end if;
  if rating_in is null or rating_in not between 1 and 5 or body_in is null
    or char_length(body_in)>1000 then raise exception 'Invalid review' using errcode='22023'; end if;
  insert into public.walk_reviews(request_id,author_id,helper_id,rating,body)
    values(request_in,actor,helper,rating_in,trim(body_in));
end $$;

create function public.reply_walk_owner_review(review_in uuid,body_in text) returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); review public.walk_owner_reviews;
begin
  if body_in is null or char_length(trim(body_in)) not between 1 and 1000 then
    raise exception 'Invalid reply' using errcode='22023'; end if;
  select * into review from public.walk_owner_reviews where id=review_in for update;
  if review.id is null or review.owner_id<>actor or not review.published
    or not private.public_account(review.author_id) or private.blocked(actor,review.author_id)
    or not exists(select 1 from public.walk_requests w join public.walk_agreements a on a.request_id=w.id
      where w.id=review.request_id and w.status='completed' and w.owner_id=actor
      and a.helper_id=review.author_id) then
    raise exception 'Reply not allowed' using errcode='42501'; end if;
  update public.walk_owner_reviews set owner_reply=trim(body_in),replied_at=now() where id=review_in;
end $$;

create function public.owner_stats() returns table(id uuid,rating numeric,review_count bigint,completed bigint)
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_actor();
begin
  return query select p.id,r.rating,coalesce(r.review_count,0),coalesce(w.completed,0)
  from public.profiles p left join (
    select v.owner_id,avg(v.rating)::numeric rating,count(*) review_count
    from public.walk_owner_reviews v join public.walk_requests wr on wr.id=v.request_id
      join public.walk_agreements a on a.request_id=wr.id
    where v.published and wr.status='completed' and wr.owner_id=v.owner_id
      and a.helper_id=v.author_id and v.owner_id<>v.author_id
    group by v.owner_id
  ) r on r.owner_id=p.id left join (
    select wr.owner_id,count(*) completed from public.walk_requests wr
      join public.walk_agreements a on a.request_id=wr.id where wr.status='completed'
    group by wr.owner_id
  ) w on w.owner_id=p.id
  where private.public_account(p.id) and not private.blocked(actor,p.id);
end $$;

create or replace function public.helper_stats() returns table(id uuid,rating numeric,review_count bigint,completed bigint)
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_actor();
begin
  return query select p.id,r.rating,coalesce(r.review_count,0),coalesce(w.completed,0)
  from public.profiles p left join (
    select v.helper_id,avg(v.rating)::numeric rating,count(*) review_count
    from public.walk_reviews v join public.walk_requests wr on wr.id=v.request_id
      join public.walk_agreements a on a.request_id=wr.id
    where v.published and wr.status='completed' and wr.owner_id=v.author_id
      and a.helper_id=v.helper_id and v.helper_id<>v.author_id
    group by v.helper_id
  ) r on r.helper_id=p.id left join (
    select a.helper_id,count(*) completed from public.walk_requests wr
      join public.walk_agreements a on a.request_id=wr.id where wr.status='completed'
    group by a.helper_id
  ) w on w.helper_id=p.id
  where private.public_account(p.id) and not private.blocked(actor,p.id);
end $$;

-- Reporting keeps the existing 'review' target kind for both directions.
create or replace function public.resolve_report(report_in uuid,action_in text,note_in text) returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_moderator(); r public.reports;
begin
  select * into r from public.reports where id=report_in for update;
  if not found then raise exception 'Report unavailable'; end if;
  if exists(select 1 from private.report_decisions where report_id=report_in) then return; end if;
  if action_in='hide' then
    if r.target_kind='place' then update public.places set published=false where id=r.target_id;
    elsif r.target_kind='review' then
      update public.walk_reviews set published=false where id=r.target_id;
      update public.walk_owner_reviews set published=false where id=r.target_id;
    else raise exception 'This target requires a separate investigation'; end if;
  end if;
  insert into private.report_decisions values(report_in,actor,action_in,trim(note_in),now());
end $$;

-- Extend export without losing existing exports (including event/media additions).
alter function public.export_my_data() rename to export_my_data_before_walking_roles;
alter function public.export_my_data_before_walking_roles() set schema private;
revoke all on function private.export_my_data_before_walking_roles() from public,anon,authenticated;
create function public.export_my_data() returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); result jsonb;
begin
  perform private.recent_auth();
  result:=private.export_my_data_before_walking_roles();
  return result||jsonb_build_object(
    'product_role',(select to_jsonb(r)-'user_id' from private.product_roles r where r.user_id=actor),
    'walking_helper_profile',(select to_jsonb(p) from public.walking_helper_profiles p where p.user_id=actor),
    'owner_reviews_written',(select coalesce(jsonb_agg(v),'[]') from public.walk_owner_reviews v where v.author_id=actor),
    'owner_reviews_received',(select coalesce(jsonb_agg(v),'[]') from public.walk_owner_reviews v where v.owner_id=actor),
    'walking_applications',(select coalesce(jsonb_agg(a),'[]') from public.walk_applications a where a.helper_id=actor),
    'walking_agreements',(select coalesce(jsonb_agg(a),'[]') from public.walk_agreements a where a.helper_id=actor));
end $$;

revoke all on function public.review_walk_owner(uuid,integer,text),public.reply_walk_owner_review(uuid,text),
  public.owner_stats(),public.export_my_data() from public,anon;
grant execute on function public.review_walk_owner(uuid,integer,text),public.reply_walk_owner_review(uuid,text),
  public.owner_stats(),public.export_my_data() to authenticated;
