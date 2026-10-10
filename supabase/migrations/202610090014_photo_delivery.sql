-- Private bytes are served only by read-photo after a fresh user RLS check.
-- Direct authenticated Storage downloads can remain cached after access is
-- revoked; never use those URLs as the client-facing authorization boundary.
drop policy if exists photo_bytes_read on storage.objects;
