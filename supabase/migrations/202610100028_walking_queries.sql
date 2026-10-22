-- Whitelisted response shape: public venue area, never GPS/hand-over addresses.
create function private.walk_card(item public.walk_requests,actor uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare helper uuid; cid uuid; own boolean:=item.owner_id=actor; participating boolean;
  owner_profile jsonb; helper_profile jsonb; pet jsonb; result jsonb; allowed_actions text[]:='{}'::text[];
begin
  select helper_id into helper from public.walk_agreements where request_id=item.id;
  participating:=own or helper=actor;
  select jsonb_build_object('id',p.id,'name',p.name,'kind',p.kind,'age',p.age,'size',p.size,
    'temperament',p.temperament) into pet from public.pets p where p.id=item.pet_id;
  if private.public_account(item.owner_id) and not private.blocked(actor,item.owner_id) then
    select jsonb_build_object('id',p.id,'display_name',p.display_name,'district',p.district,
      'rating',(select avg(r.rating) from public.walk_owner_reviews r where r.owner_id=p.id and r.published),
      'review_count',(select count(*) from public.walk_owner_reviews r where r.owner_id=p.id and r.published))
      into owner_profile from public.profiles p where p.id=item.owner_id;
  end if;
  if participating and helper is not null and private.public_account(helper)
    and not private.blocked(actor,helper) then
    select jsonb_build_object('id',p.id,'display_name',p.display_name,'district',p.district)
      into helper_profile from public.profiles p where p.id=helper;
  end if;
  if participating then
    select c.id into cid from public.conversations c
      where c.kind='walk' and c.context_id=item.id and private.member(c.id);
  end if;
  if item.status='open' then
    if own then
      allowed_actions:=array['cancel'];
      if private.product_can(actor,'owner') then allowed_actions:=allowed_actions||'assign'::text; end if;
    elsif private.public_account(item.owner_id) and not private.blocked(actor,item.owner_id) then
      if exists(select 1 from public.walk_applications a where a.request_id=item.id and a.helper_id=actor) then
        allowed_actions:=array['withdraw'];
      elsif item.starts_at>now() and private.product_can(actor,'helper') then allowed_actions:=array['apply']; end if;
    end if;
  elsif helper=actor and item.status='assigned' then allowed_actions:=array['start'];
  elsif helper=actor and item.status='in_progress' then allowed_actions:=array['finish'];
  elsif own and item.status='awaiting_confirmation' then allowed_actions:=array['confirm'];
  elsif item.status='completed' and helper is not null and helper<>item.owner_id then
    if own and private.public_account(helper) and not private.blocked(actor,helper)
      and not exists(select 1 from public.walk_reviews r where r.request_id=item.id) then
      allowed_actions:=array['review_helper'];
    elsif helper=actor and owner_profile is not null
      and not exists(select 1 from public.walk_owner_reviews r where r.request_id=item.id) then
      allowed_actions:=array['review_owner']; end if;
  end if;
  result:=jsonb_build_object('id',item.id,'owner_id',item.owner_id,'pet_id',item.pet_id,
    'city',item.city,'district',item.district,'starts_at',item.starts_at,'duration',item.duration,
    'time_zone',item.time_zone,'description',item.description,'status',item.status,
    'pet',pet,'owner',owner_profile,'helper',helper_profile,
    'my_role',case when own then 'owner' when helper=actor then 'helper'
      when exists(select 1 from public.walk_applications a where a.request_id=item.id and a.helper_id=actor)
        then 'applicant' else 'viewer' end,
    'applied',exists(select 1 from public.walk_applications a where a.request_id=item.id and a.helper_id=actor),
    'conversation_id',cid,'allowed_actions',to_jsonb(allowed_actions),
    'helper_review_written',own and exists(select 1 from public.walk_reviews r where r.request_id=item.id),
    'owner_review_written',coalesce(helper=actor,false) and exists(select 1 from public.walk_owner_reviews r where r.request_id=item.id));
  return result;
end $$;
revoke all on function private.walk_card(public.walk_requests,uuid) from public,anon,authenticated;

create function private.walk_query_bounds(offset_in integer,limit_in integer) returns void
language plpgsql immutable set search_path='' as $$
begin
  if offset_in is null or offset_in not between 0 and 10000 or limit_in is null
    or limit_in not between 1 and 100 then raise exception 'Invalid page' using errcode='22023'; end if;
end $$;
revoke all on function private.walk_query_bounds(integer,integer) from public,anon,authenticated;

create function public.search_walk_requests(city_in text,district_in text default null,
  from_in timestamptz default null,until_in timestamptz default null,size_in text default null,
  offset_in integer default 0,limit_in integer default 40) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); result jsonb;
begin
  perform private.walk_query_bounds(offset_in,limit_in);
  if not private.product_can(actor,'helper') then
    raise exception 'Helper role required' using errcode='42501'; end if;
  if city_in is null or char_length(trim(city_in)) not between 1 and 120
    or char_length(district_in)>100 or (size_in is not null and size_in not in ('small','medium','large'))
    or (from_in is not null and not isfinite(from_in)) or (until_in is not null and not isfinite(until_in))
    or (from_in is not null and until_in is not null and from_in>=until_in) then
    raise exception 'Invalid filters' using errcode='22023'; end if;
  with eligible as materialized (
    select w.* from public.walk_requests w join public.pets p on p.id=w.pet_id
    where w.status='open' and w.starts_at>now() and w.city=trim(city_in) and w.owner_id<>actor
      and private.public_account(w.owner_id) and not private.blocked(actor,w.owner_id)
      and (district_in is null or w.district=trim(district_in))
      and (from_in is null or w.starts_at>=from_in) and (until_in is null or w.starts_at<until_in)
      and (size_in is null or p.size=size_in)
  ), page as (select * from eligible order by starts_at,id offset offset_in limit limit_in)
  select jsonb_build_object('items',(select coalesce(jsonb_agg(
      private.walk_card(p::public.walk_requests,actor) order by p.starts_at,p.id),'[]') from page p),
    'total',(select count(*) from eligible),'offset',offset_in,'limit',limit_in) into result;
  return result;
end $$;

create function public.my_walks(role_in text default null,view_in text default 'active',
  offset_in integer default 0,limit_in integer default 40) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); selected_role text; result jsonb;
begin
  perform private.walk_query_bounds(offset_in,limit_in);
  select coalesce(role_in,active_mode) into selected_role from private.product_roles where user_id=actor;
  if selected_role is null or selected_role not in ('owner','helper','all')
    or view_in is null or view_in not in ('active','history','applications') then
    raise exception 'Invalid walking view' using errcode='22023'; end if;
  with related as materialized (
    select w.*,a.helper_id selected_helper,
      exists(select 1 from public.walk_applications x where x.request_id=w.id and x.helper_id=actor) applied
    from public.walk_requests w left join public.walk_agreements a on a.request_id=w.id
    where w.owner_id=actor or a.helper_id=actor
      or exists(select 1 from public.walk_applications x where x.request_id=w.id and x.helper_id=actor)
  ), eligible as materialized (
    select w.* from related w where
      ((selected_role in ('owner','all') and w.owner_id=actor)
        or (selected_role in ('helper','all') and (w.selected_helper=actor
          or (w.status='open' and w.applied) or (view_in='applications' and w.applied))))
      and case view_in when 'active' then w.status in ('open','assigned','in_progress','awaiting_confirmation')
        when 'history' then w.status in ('completed','cancelled') else w.applied end
  ), page as (select * from eligible order by starts_at desc,id offset offset_in limit limit_in)
  select jsonb_build_object('items',(select coalesce(jsonb_agg(
      private.walk_card(w,actor) order by p.starts_at desc,p.id),'[]')
      from page p join public.walk_requests w on w.id=p.id),
    'total',(select count(*) from eligible),'offset',offset_in,'limit',limit_in) into result;
  return result;
end $$;

create function public.walk_private_details(request_in uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests; helper uuid;
begin
  select * into item from public.walk_requests where id=request_in;
  select helper_id into helper from public.walk_agreements where request_id=request_in;
  if item.id is null or (item.owner_id<>actor and (helper is distinct from actor
    or not private.public_account(item.owner_id) or private.blocked(actor,item.owner_id))) then
    raise exception 'Private details unavailable' using errcode='42501'; end if;
  return jsonb_build_object('request_id',request_in,'instructions',
    (select d.instructions from public.walk_details d where d.request_id=request_in));
end $$;

drop policy details_read on public.walk_details;
create policy details_read on public.walk_details for select using(
  private.actor() is not null and (
    exists(select 1 from public.walk_requests w where w.id=request_id and w.owner_id=private.actor())
    or exists(select 1 from public.walk_requests w join public.walk_agreements a on a.request_id=w.id
      where w.id=walk_details.request_id and a.helper_id=private.actor()
        and private.public_account(w.owner_id) and not private.blocked(private.actor(),w.owner_id))));

revoke all on function public.search_walk_requests(text,text,timestamptz,timestamptz,text,integer,integer),
  public.my_walks(text,text,integer,integer),public.walk_private_details(uuid) from public,anon;
grant execute on function public.search_walk_requests(text,text,timestamptz,timestamptz,text,integer,integer),
  public.my_walks(text,text,integer,integer),public.walk_private_details(uuid) to authenticated;
