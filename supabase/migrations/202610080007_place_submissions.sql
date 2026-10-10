-- Precise coordinates here describe a venue chosen explicitly, not a user's location.
create table public.place_submissions (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles on delete cascade,
  client_id uuid not null,
  name text not null check(char_length(name) between 1 and 120),
  category text not null check(category in ('Парк','Кафе','Ресторан','Площадка')),
  city text not null check(char_length(city) between 1 and 120),
  description text not null default '' check(char_length(description)<=1000),
  latitude double precision not null check(latitude between -90 and 90),
  longitude double precision not null check(longitude between -180 and 180),
  status text not null default 'pending' check(status in ('pending','approved','rejected')),
  published_id uuid references public.places on delete set null,
  created_at timestamptz not null default now(), unique(author_id,client_id)
);
alter table public.place_submissions enable row level security;
revoke all on public.place_submissions from anon,authenticated;
grant select on public.place_submissions to authenticated;
create policy submission_own_read on public.place_submissions for select using(author_id=private.actor());
create function public.submit_place(client_id uuid,name_in text,category_in text,city_in text,latitude_in double precision,longitude_in double precision,description_in text default '') returns uuid
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); result uuid;
begin
  perform 1 from private.accounts where id=actor for update;
  select id into result from public.place_submissions where author_id=actor and place_submissions.client_id=submit_place.client_id;
  if result is not null then return result;end if;
  if (select count(*) from public.place_submissions where author_id=actor and status='pending')>=20 then raise exception 'Pending limit reached';end if;
  insert into public.place_submissions(author_id,client_id,name,category,city,latitude,longitude,description)
    values(actor,client_id,trim(name_in),category_in,trim(city_in),latitude_in,longitude_in,trim(description_in)) returning id into result;
  return result;
end $$;
create function public.review_place_submission(submission_in uuid,approve_in boolean) returns uuid
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.place_submissions; result uuid;
begin
  if not exists(select 1 from private.accounts where id=actor and moderator) or coalesce(auth.jwt()->>'aal','')<>'aal2' then raise exception 'Moderator MFA required' using errcode='42501';end if;
  select * into item from public.place_submissions where id=submission_in for update;
  if not found then raise exception 'Submission unavailable';end if;
  if item.status<>'pending' then return item.published_id;end if;
  if approve_in then
    insert into public.places(source,source_id,name,category,city,latitude,longitude,pet_access,source_tags)
    values('community','submission:'||item.id,item.name,item.category,item.city,item.latitude,item.longitude,'unknown',jsonb_build_object('description',item.description)) returning id into result;
  end if;
  update public.place_submissions set status=case when approve_in then 'approved' else 'rejected' end,published_id=result where id=item.id;
  return result;
end $$;
revoke all on function public.submit_place(uuid,text,text,text,double precision,double precision,text),public.review_place_submission(uuid,boolean) from public,anon;
grant execute on function public.submit_place(uuid,text,text,text,double precision,double precision,text),public.review_place_submission(uuid,boolean) to authenticated;

create or replace function public.export_my_data() returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); data jsonb; begin
  perform private.recent_auth();
  select jsonb_build_object('profile',(select to_jsonb(p) from public.profiles p where id=actor),'pets',(select coalesce(jsonb_agg(p),'[]') from public.pets p where owner_id=actor),'walk_requests',(select coalesce(jsonb_agg(p),'[]') from public.walk_requests p where owner_id=actor),'messages',(select coalesce(jsonb_agg(m),'[]') from public.messages m where sender_id=actor),'reviews',(select coalesce(jsonb_agg(r),'[]') from public.walk_reviews r where author_id=actor),'place_submissions',(select coalesce(jsonb_agg(s),'[]') from public.place_submissions s where author_id=actor)) into data;
  return data;
end $$;
