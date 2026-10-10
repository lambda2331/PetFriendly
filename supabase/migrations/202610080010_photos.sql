-- Private media: only the server can publish re-encoded bytes and object references.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('petfriendly-photos','petfriendly-photos',false,8388608,array['image/jpeg']) on conflict(id) do nothing;
create table public.entity_photos (
 kind text not null check(kind in ('profile','pet','group')), target_id uuid not null,
 owner_id uuid not null references public.profiles on delete cascade,
 object_path text not null unique, updated_at timestamptz not null default now(),
 primary key(kind,target_id), check(object_path like owner_id::text||'/%')
);
alter table public.entity_photos enable row level security;
revoke all on public.entity_photos from anon,authenticated;
grant select on public.entity_photos to authenticated;
create function private.photo_owner(kind_in text,target_in uuid) returns uuid language sql stable security definer set search_path='' as $$
 select case kind_in when 'profile' then (select id from public.profiles where id=target_in)
 when 'pet' then (select owner_id from public.pets where id=target_in)
 when 'group' then (select owner_id from public.groups where id=target_in) end
$$;
create function private.photo_visible(kind_in text,target_in uuid,owner_in uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.actor() is not null and private.photo_owner(kind_in,target_in)=owner_in and not private.blocked(private.actor(),owner_in)
 and exists(select 1 from private.accounts where id=owner_in and not blocked and deletion_requested_at is null)
$$;
create policy photo_metadata_read on public.entity_photos for select to authenticated using(private.photo_visible(kind,target_id,owner_id));
create policy photo_bytes_read on storage.objects for select to authenticated using(bucket_id='petfriendly-photos' and exists(select 1 from public.entity_photos p where p.object_path=name and private.photo_visible(p.kind,p.target_id,p.owner_id)));
create table private.photo_uploads(user_id uuid primary key references auth.users on delete cascade, requested_at timestamptz not null);
revoke all on private.photo_uploads from public,anon,authenticated;
create function public.authorize_photo(kind_in text,target_in uuid) returns uuid language plpgsql security definer set search_path='' as $$
 declare actor uuid:=private.require_actor();begin
 if private.photo_owner(kind_in,target_in) is distinct from actor then raise exception 'Photo ownership required' using errcode='42501';end if;
 insert into private.photo_uploads values(actor,now()) on conflict(user_id) do update set requested_at=excluded.requested_at where private.photo_uploads.requested_at<now()-interval '10 seconds';
 if not found then raise exception 'Try again later' using errcode='54000';end if;return actor;end $$;
revoke all on function public.authorize_photo(text,uuid) from public,anon;grant execute on function public.authorize_photo(text,uuid) to authenticated;
create function public.publish_photo(user_in uuid,session_in uuid,kind_in text,target_in uuid,path_in text) returns text language plpgsql security definer set search_path='' as $$
 declare old_path text;begin
 if not exists(select 1 from auth.sessions where id=session_in and user_id=user_in) or exists(select 1 from private.revoked_sessions where id=session_in) or private.photo_owner(kind_in,target_in) is distinct from user_in or path_in not like user_in::text||'/%' or not exists(select 1 from private.accounts where id=user_in and not blocked and deletion_requested_at is null) then raise exception 'Photo unavailable' using errcode='42501';end if;
 perform pg_advisory_xact_lock(hashtext(kind_in||target_in::text));
 select object_path into old_path from public.entity_photos where kind=kind_in and target_id=target_in;
 insert into public.entity_photos(kind,target_id,owner_id,object_path) values(kind_in,target_in,user_in,path_in) on conflict(kind,target_id) do update set owner_id=excluded.owner_id,object_path=excluded.object_path,updated_at=now();return old_path;end $$;
revoke all on function public.publish_photo(uuid,uuid,text,uuid,text) from public,anon,authenticated;grant execute on function public.publish_photo(uuid,uuid,text,uuid,text) to service_role;

create or replace function public.export_my_data() returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); data jsonb; begin
  perform private.recent_auth();
  select jsonb_build_object('profile',(select to_jsonb(p) from public.profiles p where id=actor),'pets',(select coalesce(jsonb_agg(p),'[]') from public.pets p where owner_id=actor),'walk_requests',(select coalesce(jsonb_agg(p),'[]') from public.walk_requests p where owner_id=actor),'messages',(select coalesce(jsonb_agg(m),'[]') from public.messages m where sender_id=actor),'reviews',(select coalesce(jsonb_agg(r),'[]') from public.walk_reviews r where author_id=actor),'place_submissions',(select coalesce(jsonb_agg(s),'[]') from public.place_submissions s where author_id=actor),'photos',(select coalesce(jsonb_agg(p),'[]') from public.entity_photos p where owner_id=actor),'place_reviews',(select coalesce(jsonb_agg(r),'[]') from public.place_reviews r where author_id=actor)) into data;
  return data;
end $$;