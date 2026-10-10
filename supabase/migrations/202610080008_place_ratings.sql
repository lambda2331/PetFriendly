-- Aggregates are derived from all venue reviews, never a client's limited page.
create or replace function public.place_rating_stats() returns table(place_id uuid,average_rating numeric,review_count bigint)
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_actor();begin
  return query select r.place_id,avg(r.rating)::numeric,count(*)
    from public.place_reviews r join public.places p on p.id=r.place_id
    where p.published group by r.place_id;
end $$;
revoke all on function public.place_rating_stats() from public,anon;
grant execute on function public.place_rating_stats() to authenticated;

create or replace function public.export_my_data() returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); data jsonb; begin
  perform private.recent_auth();
  select jsonb_build_object('profile',(select to_jsonb(p) from public.profiles p where id=actor),'pets',(select coalesce(jsonb_agg(p),'[]') from public.pets p where owner_id=actor),'walk_requests',(select coalesce(jsonb_agg(p),'[]') from public.walk_requests p where owner_id=actor),'messages',(select coalesce(jsonb_agg(m),'[]') from public.messages m where sender_id=actor),'reviews',(select coalesce(jsonb_agg(r),'[]') from public.walk_reviews r where author_id=actor),'place_submissions',(select coalesce(jsonb_agg(s),'[]') from public.place_submissions s where author_id=actor),'place_reviews',(select coalesce(jsonb_agg(r),'[]') from public.place_reviews r where author_id=actor)) into data;
  return data;
end $$;
