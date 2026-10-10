-- Preserve existing videos; disallow new video uploads in every write path.
create or replace function public.publish_chat_media(claims_in jsonb, conversation_in uuid,client_id uuid,body_in text,path_in text,kind_in text,mime_in text,size_in integer,duration_in double precision)
returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid;mid uuid;member uuid;existing public.chat_attachments;begin
 -- Only the trusted Edge Function may pass claims, after getUser validates JWT.
 perform set_config('request.jwt.claims',claims_in::text,true);
 actor:=private.require_actor();
 if kind_in is distinct from 'image' or mime_in is distinct from 'image/jpeg' or size_in is null or size_in not between 1 and 1048576 or duration_in is not null then raise exception 'Only photos up to 1 MiB are allowed' using errcode='22023';end if;
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

alter table public.chat_attachments add constraint new_chat_photos_only check(kind='image' and mime='image/jpeg' and byte_size between 1 and 1048576 and duration is null) not valid;
update storage.buckets set file_size_limit=1048576,allowed_mime_types=array['image/jpeg'] where id='petfriendly-chat';
create or replace function public.chat_media_capabilities() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin perform private.require_actor();return jsonb_build_object('image',true,'video',false,'image_max_input_bytes',5242880,'image_max_stored_bytes',1048576);end $$;
