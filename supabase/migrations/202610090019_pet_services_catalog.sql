-- Add pet services without changing publication, review or moderation permissions.
alter table public.place_submissions drop constraint place_submissions_category_check;
alter table public.place_submissions add constraint place_submissions_category_check
 check (category in ('Парк','Площадка','Кафе','Ресторан','Зоомагазин','Ветклиника'));
-- Existing city catalogs refresh through the same leased, rate-limited import.
-- Preserve all place IDs, community edits, ratings and pending submissions.
update private.city_catalog set updated_at=least(updated_at,now()-interval '8 days') where status='ready';
