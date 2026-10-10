create function private.require_moderator() returns uuid language plpgsql stable security definer set search_path='' as $$ declare actor uuid:=private.require_actor();begin
 if coalesce(auth.jwt()->>'aal','')<>'aal2' or not exists(select 1 from private.accounts where id=actor and moderator) then raise exception 'Moderator MFA required' using errcode='42501';end if;return actor;end $$;
revoke all on function private.require_moderator() from public,anon,authenticated;
create function public.moderation_available() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from private.accounts a join auth.sessions s on s.user_id=a.id where a.id=auth.uid() and a.moderator and not a.blocked and a.deletion_requested_at is null and s.id=nullif(auth.jwt()->>'session_id','')::uuid and not exists(select 1 from private.revoked_sessions r where r.id=s.id))
$$;
revoke all on function public.moderation_available() from public,anon;grant execute on function public.moderation_available() to authenticated;
create table private.report_decisions(report_id uuid primary key references public.reports on delete cascade,moderator_id uuid references auth.users on delete set null,action text not null check(action in('dismiss','hide')),note text not null check(char_length(note) between 1 and 500),created_at timestamptz not null default now());
revoke all on private.report_decisions from public,anon,authenticated;
create function public.moderation_queue() returns jsonb language plpgsql stable security definer set search_path='' as $$ begin
 perform private.require_moderator();
 return jsonb_build_object('submissions',(select coalesce(jsonb_agg(p),'[]') from (select id,name,category,city,description from public.place_submissions where status='pending' order by created_at,id limit 50)p),
 'reports',(select coalesce(jsonb_agg(p),'[]') from (select r.id,r.target_kind,r.target_id,r.reason,r.created_at from public.reports r where not exists(select 1 from private.report_decisions d where d.report_id=r.id) order by r.created_at,r.id limit 50)p));end $$;
create function public.resolve_report(report_in uuid,action_in text,note_in text) returns void language plpgsql security definer set search_path='' as $$
 declare actor uuid:=private.require_moderator();r public.reports;begin
 select * into r from public.reports where id=report_in for update;
 if not found then raise exception 'Report unavailable';end if;
 if exists(select 1 from private.report_decisions where report_id=report_in) then return;end if;
 if action_in='hide' then
   if r.target_kind='place' then update public.places set published=false where id=r.target_id;
   elsif r.target_kind='review' then update public.walk_reviews set published=false where id=r.target_id;
   else raise exception 'This target requires a separate investigation';end if;
 end if;
 insert into private.report_decisions values(report_in,actor,action_in,trim(note_in),now());end $$;
revoke all on function public.moderation_queue(),public.resolve_report(uuid,text,text) from public,anon;grant execute on function public.moderation_queue(),public.resolve_report(uuid,text,text) to authenticated;
