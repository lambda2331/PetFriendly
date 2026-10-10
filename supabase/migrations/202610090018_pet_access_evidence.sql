-- Separately verified public venue rules. OSM imports never write this table.
-- No proposer/reviewer identity or private pet-care instructions are exposed.
create table public.place_pet_access_evidence (
  place_id uuid primary key references public.places on delete cascade,
  confirmation text not null check (confirmation in ('community','venue')),
  policy text not null check (policy in ('allowed','on_leash','forbidden')),
  observed_at timestamptz not null,
  verified_at timestamptz not null default now(),
  basis text not null check (char_length(trim(basis)) between 1 and 1000),
  conditions text not null default '' check (char_length(conditions) <= 1000),
  reference_url text check (reference_url is null or
    (char_length(reference_url) <= 2000 and reference_url ~ '^https://[^/[:space:]]+')),
  check (observed_at <= verified_at),
  check (confirmation <> 'venue' or reference_url is not null)
);
alter table public.place_pet_access_evidence enable row level security;
revoke all on public.place_pet_access_evidence from anon, authenticated;
grant select on public.place_pet_access_evidence to anon, authenticated;
create function public.pet_access_evidence_visible(place_in uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.places p where p.id = place_in and p.published)
    and (auth.uid() is null or private.actor() is not null)
$$;
revoke all on function public.pet_access_evidence_visible(uuid) from public;
grant execute on function public.pet_access_evidence_visible(uuid) to anon, authenticated;
create policy published_pet_rules on public.place_pet_access_evidence for select
  using (public.pet_access_evidence_visible(place_id));

create function public.publish_place_pet_access(place_in uuid, confirmation_in text,
  policy_in text, observed_in timestamptz, basis_in text,
  conditions_in text default '', reference_in text default '')
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_moderator();
  if not exists (select 1 from public.places where id = place_in and published) then
    raise exception 'Published venue required';
  end if;
  if observed_in is null or not isfinite(observed_in) or observed_in > now() then
    raise exception 'A real observation date is required';
  end if;
  insert into public.place_pet_access_evidence(place_id, confirmation, policy,
    observed_at, verified_at, basis, conditions, reference_url)
  values (place_in, confirmation_in, policy_in, observed_in, now(), trim(basis_in),
    trim(coalesce(conditions_in,'')), nullif(trim(reference_in),''))
  on conflict (place_id) do update set confirmation = excluded.confirmation,
    policy = excluded.policy, observed_at = excluded.observed_at,
    verified_at = excluded.verified_at, basis = excluded.basis,
    conditions = excluded.conditions, reference_url = excluded.reference_url;
end $$;
create function public.withdraw_place_pet_access(place_in uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_moderator();
  delete from public.place_pet_access_evidence where place_id = place_in;
end $$;
revoke all on function public.publish_place_pet_access(uuid,text,text,timestamptz,text,text,text),
  public.withdraw_place_pet_access(uuid) from public, anon;
grant execute on function public.publish_place_pet_access(uuid,text,text,timestamptz,text,text,text),
  public.withdraw_place_pet_access(uuid) to authenticated;

-- Include moderated evidence with each bounded catalog page and keep unknown
-- confirmation separate from OSM hints (a tag alone is still unconfirmed).
create or replace function public.search_places(city_in text, query_in text default '',
  category_in text default 'Все', access_in text default 'all',
  favorites_in uuid[] default null, offset_in integer default 0) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); result jsonb;
begin
  if char_length(city_in)>120 or char_length(query_in)>120 or offset_in<0
    or offset_in>100000 or coalesce(array_length(favorites_in,1),0)>2000 then
    raise exception 'Invalid search';
  end if;
  with matches as (
    select p.*, to_jsonb(e) as pet_access_evidence from public.places p
    left join public.place_pet_access_evidence e on e.place_id = p.id
    where p.published and
      (lower(trim(p.city))=lower(trim(city_in)) or exists
        (select 1 from public.city_catalog_places c where c.place_id=p.id
          and c.city_key=lower(trim(city_in))))
    and (category_in='Все' or p.category=category_in)
    and position(replace(lower(trim(query_in)),'ё','е') in
      replace(lower(p.name||' '||p.category),'ё','е'))>0
    and (favorites_in is null or p.id=any(favorites_in))
    and (access_in='all'
      or (access_in='taggedAllowed' and p.pet_access in ('yes','leashed')
        and coalesce(e.policy,'')<>'forbidden')
      or (access_in='unknown' and e.place_id is null)
      or (access_in='forbidden' and p.pet_access='no' and e.place_id is null))
  ), page as (select * from matches order by name collate "C",id offset offset_in limit 40)
  select jsonb_build_object('total',(select count(*) from matches),'items',
    (select coalesce(jsonb_agg(row_to_json(p)),'[]') from page p)) into result;
  return result;
end $$;

-- Match the selected/detected catalog scope, including shared city links.
create function public.city_place_pet_access(city_in text)
returns setof public.place_pet_access_evidence
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_actor();
  if city_in is null or char_length(trim(city_in)) not between 1 and 120 then
    raise exception 'Invalid city';
  end if;
  return query select e.* from public.place_pet_access_evidence e
    join public.places p on p.id = e.place_id
    where p.published and
      (lower(trim(p.city)) = lower(trim(city_in)) or exists
        (select 1 from public.city_catalog_places c where c.place_id = p.id
          and c.city_key = lower(trim(city_in))))
    order by e.place_id limit 1000;
end $$;
revoke all on function public.city_place_pet_access(text) from public, anon;
grant execute on function public.city_place_pet_access(text) to authenticated;
