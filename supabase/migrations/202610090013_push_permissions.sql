-- Cloud projects with automatic table exposure disabled do not grant these
-- privileges by default. Only the server worker may read tokens or discard
-- an unregistered token; authenticated users retain their own RLS access.
grant select, delete on public.device_tokens to service_role;
