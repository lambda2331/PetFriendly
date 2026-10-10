-- Server filtering and bounded pages. No user coordinates are sent or stored.
create function public.search_places(city_in text,query_in text default '',category_in text default 'Все',access_in text default 'all',favorites_in uuid[] default null,offset_in integer default 0) returns jsonb language plpgsql stable security definer set search_path='' as $$
 declare actor uuid:=private.require_actor();result jsonb;begin
 if char_length(city_in)>120 or char_length(query_in)>120 or offset_in<0 or offset_in>100000 or coalesce(array_length(favorites_in,1),0)>2000 then raise exception 'Invalid search';end if;
 with matches as (
 select p.* from public.places p where p.published
 and (lower(trim(p.city))=lower(trim(city_in)) or exists(select 1 from public.city_catalog_places c where c.place_id=p.id and c.city_key=lower(trim(city_in))))
 and (category_in='Все' or p.category=category_in)
 and position(replace(lower(trim(query_in)),'ё','е') in replace(lower(p.name||' '||p.category),'ё','е'))>0
 and (favorites_in is null or p.id=any(favorites_in))
 and (access_in='all' or (access_in='taggedAllowed' and p.pet_access in('yes','leashed')) or (access_in='unknown' and p.pet_access='unknown') or (access_in='forbidden' and p.pet_access='no'))
 ), page as (select * from matches order by name collate "C",id offset offset_in limit 40)
 select jsonb_build_object('total',(select count(*) from matches),'items',(select coalesce(jsonb_agg(row_to_json(p)),'[]') from page p)) into result;return result;
 end $$;
revoke all on function public.search_places(text,text,text,text,uuid[],integer) from public,anon;grant execute on function public.search_places(text,text,text,text,uuid[],integer) to authenticated;
