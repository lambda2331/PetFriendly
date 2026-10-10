-- The server sender may read delivery tokens and remove invalid tokens.
-- No client privileges change; session/MFA RLS and token-owner writes stay enforced.
grant select, delete on public.device_tokens to service_role;
