create schema if not exists private;
create schema if not exists extensions;
create extension if not exists postgis with schema extensions;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table private.accounts (
  id uuid primary key references auth.users on delete cascade,
  blocked boolean not null default false,
  moderator boolean not null default false,
  deletion_requested_at timestamptz
);
create table private.revoked_sessions (id uuid primary key, user_id uuid not null references auth.users on delete cascade);
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text not null default 'Новый пользователь' check(char_length(display_name) between 1 and 80),
  district text not null default '', about text not null default '' check(char_length(about)<=1000),
  interests text not null default '' check(char_length(interests)<=300)
);
create table public.pets (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles on delete cascade,
  name text not null check(char_length(name) between 1 and 80), kind text not null default 'Собака',
  age integer not null default 0 check(age between 0 and 100), temperament text not null default '' check(char_length(temperament)<=1000)
);
create function private.new_user() returns trigger language plpgsql security definer set search_path='' as $$
begin
  insert into private.accounts(id) values(new.id);
  insert into public.profiles(id) values(new.id);
  return new;
end $$;
create trigger new_user after insert on auth.users for each row execute function private.new_user();

create function private.actor() returns uuid language plpgsql stable security definer set search_path='' as $$
declare uid uuid := auth.uid(); sid uuid;
begin
  if uid is null then return null; end if;
  sid := nullif(auth.jwt()->>'session_id','')::uuid;
  if sid is null or not exists(select 1 from auth.sessions where id=sid and user_id=uid)
     or exists(select 1 from private.revoked_sessions where id=sid)
     or not exists(select 1 from private.accounts where id=uid and not blocked and deletion_requested_at is null) then return null; end if;
  if (exists(select 1 from auth.mfa_factors where user_id=uid and status='verified')
      or exists(select 1 from private.accounts where id=uid and moderator))
     and coalesce(auth.jwt()->>'aal','aal1')<>'aal2' then return null; end if;
  return uid;
end $$;
create function private.require_actor() returns uuid language plpgsql stable security definer set search_path='' as $$
declare uid uuid := private.actor(); begin if uid is null then raise exception 'Authentication required' using errcode='42501'; end if; return uid; end $$;
create function private.recent_auth() returns void language plpgsql stable security definer set search_path='' as $$
declare last_login bigint;
begin
  perform private.require_actor();
  select max((entry->>'timestamp')::bigint) into last_login from jsonb_array_elements(coalesce(auth.jwt()->'amr','[]')) entry where entry->>'method' in ('password','oauth','otp','totp','passkey');
  if last_login is null or extract(epoch from now())-last_login>300 then raise exception 'Reauthentication required' using errcode='42501'; end if;
end $$;
create table public.blocks (user_id uuid references public.profiles on delete cascade, target_id uuid references public.profiles on delete cascade, primary key(user_id,target_id), check(user_id<>target_id));
create function private.blocked(a uuid,b uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.blocks where (user_id=a and target_id=b) or (user_id=b and target_id=a)) $$;

create table public.places (
  id uuid primary key default gen_random_uuid(), source text not null default 'osm', source_id text not null unique,
  name text not null, category text not null, city text not null default 'Минск',
  latitude double precision not null check(latitude between -90 and 90), longitude double precision not null check(longitude between -180 and 180),
  location extensions.geography(Point,4326) generated always as (extensions.st_setsrid(extensions.st_makepoint(longitude,latitude),4326)::extensions.geography) stored,
  pet_access text not null default 'unknown', source_tags jsonb not null default '{}',
  source_updated_at timestamptz, imported_at timestamptz not null default now(), published boolean not null default true
);
create index places_geo on public.places using gist(location);
create table public.place_reviews (id uuid primary key default gen_random_uuid(), place_id uuid not null references public.places on delete cascade, author_id uuid not null references public.profiles on delete cascade, rating integer not null check(rating between 1 and 5), body text not null default '' check(char_length(body)<=1000), created_at timestamptz not null default now(), unique(place_id,author_id));
create table public.place_corrections (id uuid primary key default gen_random_uuid(), place_id uuid not null references public.places on delete cascade, author_id uuid not null references public.profiles on delete cascade, body text not null check(char_length(body) between 1 and 1000), created_at timestamptz not null default now());
create table public.favorites (user_id uuid references public.profiles on delete cascade, place_id uuid references public.places on delete cascade, primary key(user_id,place_id));

create table public.events (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles on delete cascade,
  title text not null check(char_length(title) between 1 and 120), city text not null, place_id uuid references public.places,
  starts_at timestamptz not null, capacity integer not null check(capacity between 2 and 100), description text not null default '' check(char_length(description)<=1000), cancelled boolean not null default false
);
create table public.event_members (event_id uuid references public.events on delete cascade, user_id uuid references public.profiles on delete cascade, primary key(event_id,user_id));
create table public.walk_requests (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles on delete cascade,
  pet_id uuid not null references public.pets, city text not null, starts_at timestamptz not null,
  duration integer not null check(duration between 15 and 240), description text not null default '' check(char_length(description)<=1000),
  status text not null default 'open' check(status in ('open','assigned','in_progress','awaiting_confirmation','completed','cancelled'))
);
create table public.walk_applications (request_id uuid references public.walk_requests on delete cascade, helper_id uuid references public.profiles on delete cascade, created_at timestamptz not null default now(), primary key(request_id,helper_id));
create table public.walk_agreements (id uuid primary key default gen_random_uuid(), request_id uuid not null unique references public.walk_requests on delete cascade, helper_id uuid not null references public.profiles, assigned_at timestamptz not null default now());
create table public.walk_details (request_id uuid primary key references public.walk_requests on delete cascade, instructions text not null default '' check(char_length(instructions)<=2000));
create table public.walk_reviews (id uuid primary key default gen_random_uuid(), request_id uuid not null unique references public.walk_requests on delete cascade, author_id uuid not null references public.profiles on delete cascade, helper_id uuid not null references public.profiles, rating integer not null check(rating between 1 and 5), body text not null default '' check(char_length(body)<=1000), published boolean not null default true, created_at timestamptz not null default now());
create table public.conversations (id uuid primary key default gen_random_uuid(), kind text not null check(kind in ('direct','event','walk')), context_id uuid, unique(kind,context_id));
create table public.conversation_members (conversation_id uuid references public.conversations on delete cascade, user_id uuid references public.profiles on delete cascade, primary key(conversation_id,user_id));
create table public.messages (id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations on delete cascade, sender_id uuid not null references public.profiles on delete cascade, client_message_id uuid not null, body text not null check(char_length(body) between 1 and 1000), created_at timestamptz not null default now(), unique(sender_id,client_message_id));
create index message_pagination on public.messages(conversation_id,created_at,id);
create function private.member(cid uuid) returns boolean language sql stable security definer set search_path='' as $$ select private.actor() is not null and exists(select 1 from public.conversation_members where conversation_id=cid and user_id=private.actor()) $$;
create table public.reports (id uuid primary key default gen_random_uuid(), author_id uuid not null references public.profiles on delete cascade, target_kind text not null check(target_kind in ('profile','place','message','walk','review')), target_id uuid not null, reason text not null check(char_length(reason) between 1 and 1000), created_at timestamptz not null default now());
create table public.notifications (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles on delete cascade, kind text not null, context_id uuid, created_at timestamptz not null default now(), read_at timestamptz);
create table private.notification_outbox (id uuid primary key default gen_random_uuid(), notification_id uuid not null unique references public.notifications on delete cascade, attempts integer not null default 0, delivered_at timestamptz, next_attempt_at timestamptz not null default now());
create table public.device_tokens (user_id uuid not null references public.profiles on delete cascade, token text primary key, platform text not null, updated_at timestamptz not null default now());
create function private.notify(uid uuid, kind text, context uuid) returns void language plpgsql security definer set search_path='' as $$ declare nid uuid; begin insert into public.notifications(user_id,kind,context_id) values(uid,kind,context) returning id into nid; insert into private.notification_outbox(notification_id) values(nid); end $$;

-- RLS is mandatory even when the client hides an action.
do $$ declare t text; begin foreach t in array array['profiles','pets','blocks','places','place_reviews','place_corrections','favorites','events','event_members','walk_requests','walk_applications','walk_agreements','walk_details','walk_reviews','conversations','conversation_members','messages','reports','notifications','device_tokens'] loop execute format('alter table public.%I enable row level security',t); execute format('revoke all on public.%I from anon, authenticated',t); end loop; end $$;
grant select on public.places to anon,authenticated;
create policy places_read on public.places for select using(published);
grant select on public.profiles,public.pets,public.place_reviews,public.events,public.event_members,public.walk_requests,public.walk_agreements,public.walk_reviews to authenticated;
create policy profile_read on public.profiles for select using(private.actor() is not null and not private.blocked(private.actor(),id) and exists(select 1 from private.accounts where id=profiles.id and not blocked and deletion_requested_at is null));
create policy pets_read on public.pets for select using(private.actor() is not null and not private.blocked(private.actor(),owner_id));
create policy place_review_read on public.place_reviews for select using(private.actor() is not null);
create policy event_read on public.events for select using(private.actor() is not null and not private.blocked(private.actor(),owner_id));
create policy event_member_read on public.event_members for select using(private.actor() is not null);
create policy walk_read on public.walk_requests for select using(private.actor() is not null and not private.blocked(private.actor(),owner_id));
create policy agreement_read on public.walk_agreements for select using(private.actor()=helper_id or exists(select 1 from public.walk_requests where id=request_id and owner_id=private.actor()));
create policy walk_review_read on public.walk_reviews for select using(private.actor() is not null and published);
-- Private account predicates must be security-definer; no direct access to private tables.
create function private.public_account(uid uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from private.accounts where id=uid and not blocked and deletion_requested_at is null) $$;
drop policy profile_read on public.profiles;
create policy profile_read on public.profiles for select using(private.actor() is not null and not private.blocked(private.actor(),id) and private.public_account(id));
grant update(display_name,district,about,interests) on public.profiles to authenticated;
create policy profile_edit on public.profiles for update using(id=private.actor()) with check(id=private.actor());
grant insert,update,delete on public.pets to authenticated;
create policy pet_write on public.pets for all using(owner_id=private.actor()) with check(owner_id=private.actor());
grant select,insert,delete on public.blocks to authenticated;
create policy block_own on public.blocks for all using(user_id=private.actor()) with check(user_id=private.actor());
grant select,insert,delete on public.favorites to authenticated;
create policy favorite_own on public.favorites for all using(user_id=private.actor()) with check(user_id=private.actor());
grant select on public.walk_details,public.walk_applications,public.conversations,public.conversation_members,public.messages,public.reports,public.notifications,public.device_tokens,public.place_corrections to authenticated;
create policy details_read on public.walk_details for select using(exists(select 1 from public.walk_requests where id=request_id and owner_id=private.actor()) or exists(select 1 from public.walk_agreements where request_id=walk_details.request_id and helper_id=private.actor()));
create policy application_read on public.walk_applications for select using(helper_id=private.actor() or exists(select 1 from public.walk_requests where id=request_id and owner_id=private.actor()));
create policy conversation_read on public.conversations for select using(private.member(id));
create policy members_read on public.conversation_members for select using(private.member(conversation_id));
create policy messages_read on public.messages for select using(private.member(conversation_id));
create policy reports_own on public.reports for select using(author_id=private.actor());
create policy notifications_own on public.notifications for select using(user_id=private.actor());
grant update(read_at) on public.notifications to authenticated;
create policy notifications_update on public.notifications for update using(user_id=private.actor()) with check(user_id=private.actor());
grant insert on public.reports,public.place_reviews,public.place_corrections to authenticated;
create policy report_insert on public.reports for insert with check(author_id=private.actor());
create policy place_review_insert on public.place_reviews for insert with check(author_id=private.actor());
create policy correction_insert on public.place_corrections for insert with check(author_id=private.actor());
create policy correction_own on public.place_corrections for select using(author_id=private.actor());
grant insert,update,delete on public.device_tokens to authenticated;
create policy token_own on public.device_tokens for all using(user_id=private.actor()) with check(user_id=private.actor());
