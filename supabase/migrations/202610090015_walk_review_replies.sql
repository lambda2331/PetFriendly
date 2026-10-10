-- Helpers may reply only to their own published eligible review.
alter table public.walk_reviews
  add column helper_reply text not null default '' check (char_length(helper_reply) <= 1000),
  add column replied_at timestamptz;

create function public.reply_walk_review(review_in uuid, body_in text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  review public.walk_reviews;
begin
  if body_in is null or char_length(btrim(body_in)) not between 1 and 1000 then
    raise exception 'Reply must contain between 1 and 1000 characters' using errcode = '22023';
  end if;
  select * into review from public.walk_reviews where id = review_in for update;
  if review.id is null or review.helper_id <> actor or not review.published then
    raise exception 'Reply not allowed' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.walk_requests w join public.walk_agreements a on a.request_id = w.id
    where w.id = review.request_id and w.status = 'completed'
      and a.helper_id = actor and w.owner_id = review.author_id and w.owner_id <> actor
  ) then
    raise exception 'Review is not eligible' using errcode = '42501';
  end if;
  update public.walk_reviews set helper_reply = btrim(body_in), replied_at = now() where id = review_in;
end $$;
revoke all on function public.reply_walk_review(uuid, text) from public, anon;
grant execute on function public.reply_walk_review(uuid, text) to authenticated;
-- Table UPDATE stays revoked: clients cannot change reviews or reputation totals.
