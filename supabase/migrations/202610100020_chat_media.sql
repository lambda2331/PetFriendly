-- Immutable private attachments. No public URLs or client Storage access.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('petfriendly-chat','petfriendly-chat',false,20971520,array['image/jpeg','video/mp4','video/quicktime']);
create table public.chat_attachments (
 message_id uuid primary key references public.messages on delete cascade,
 kind text not null check(kind in ('image','video')),
 mime text not null check(mime in ('image/jpeg','video/mp4','video/quicktime')),
 byte_size integer not null check(byte_size between 1 and 20971520),
 duration double precision check(duration>0 and duration<=60),
 object_path text not null unique,
 check((kind='image' and mime='image/jpeg' and duration is null and byte_size<=8388608) or (kind='video' and mime in ('video/mp4','video/quicktime') and duration is not null))
);
alter table public.chat_attachments enable row level security;
revoke all on public.chat_attachments from public,anon,authenticated;
grant select on public.chat_attachments to authenticated;
create function private.chat_media_allowed(cid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.member(cid) and not exists (
 select 1 from public.conversations c join public.conversation_members m on m.conversation_id=c.id
 where c.id=cid and c.kind in('direct','walk') and m.user_id<>private.actor() and private.blocked(private.actor(),m.user_id));
$$;
create policy chat_attachment_read on public.chat_attachments for select using(exists(
 select 1 from public.messages m where m.id=message_id and private.chat_media_allowed(m.conversation_id) and not private.blocked(private.actor(),m.sender_id)));
create function public.authorize_chat_media(conversation_in uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor();begin
 if not private.chat_media_allowed(conversation_in) then raise exception 'Chat unavailable' using errcode='42501';end if;
 perform private.rate_limit(actor,'chat_media',10);return actor;
end $$;
revoke all on function public.authorize_chat_media(uuid) from public,anon;
grant execute on function public.authorize_chat_media(uuid) to authenticated;
create function public.publish_chat_media(claims_in jsonb, conversation_in uuid,client_id uuid,body_in text,path_in text,kind_in text,mime_in text,size_in integer,duration_in double precision)
returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid;mid uuid;member uuid;existing public.chat_attachments;begin
 -- Only the trusted Edge Function may pass claims, after getUser validates JWT.
 perform set_config('request.jwt.claims',claims_in::text,true);
 actor:=private.require_actor();
 if not private.chat_media_allowed(conversation_in) then raise exception 'Chat unavailable' using errcode='42501';end if;
 if path_in not like actor::text||'/%' or char_length(body_in)>1000 then raise exception 'Invalid attachment';end if;
 perform pg_advisory_xact_lock(hashtextextended(actor::text||client_id::text,0));
 select id into mid from public.messages where sender_id=actor and client_message_id=client_id;
 if mid is not null then
   select * into existing from public.chat_attachments where message_id=mid;
   if not exists(select 1 from public.messages where id=mid and conversation_id=conversation_in and body=coalesce(nullif(trim(body_in),''),case when kind_in='image' then 'Фото' else 'Видео' end)) or existing.kind is distinct from kind_in then raise exception 'Idempotency conflict';end if;
   return jsonb_build_object('id',mid,'created',false);
 end if;
 insert into public.messages(conversation_id,sender_id,client_message_id,body)
 values(conversation_in,actor,client_id,coalesce(nullif(trim(body_in),''),case when kind_in='image' then 'Фото' else 'Видео' end)) returning id into mid;
 insert into public.chat_attachments values(mid,kind_in,mime_in,size_in,duration_in,path_in);
 for member in select user_id from public.conversation_members where conversation_id=conversation_in and user_id<>actor loop
   perform private.notify(member,'message',conversation_in);
 end loop;
 return jsonb_build_object('id',mid,'created',true);
end $$;
revoke all on function public.publish_chat_media(jsonb,uuid,uuid,text,text,text,text,integer,double precision) from public,anon,authenticated;
grant execute on function public.publish_chat_media(jsonb,uuid,uuid,text,text,text,text,integer,double precision) to service_role;
-- Existing recent-auth export contract, including only one's own media references.
alter function public.export_my_data() rename to export_my_data_before_media;
alter function public.export_my_data_before_media() set schema private;
revoke all on function private.export_my_data_before_media() from public,anon,authenticated;
create function public.export_my_data() returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor();data jsonb;begin
 data:=private.export_my_data_before_media();
 return data||jsonb_build_object('chat_attachments',(select coalesce(jsonb_agg(a),'[]') from public.chat_attachments a join public.messages m on m.id=a.message_id where m.sender_id=actor));
end $$;
revoke all on function public.export_my_data() from public,anon;
grant execute on function public.export_my_data() to authenticated;

create function public.chat_media_capabilities() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin perform private.require_actor();return jsonb_build_object('image',true,'video',true,'video_max_bytes',20971520,'video_max_seconds',60);end $$;
revoke all on function public.chat_media_capabilities() from public,anon;
grant execute on function public.chat_media_capabilities() to authenticated;
