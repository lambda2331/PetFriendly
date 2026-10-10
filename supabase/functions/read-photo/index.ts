import { createClient } from 'npm:@supabase/supabase-js@2';

const headers = {
  'Cache-Control': 'private, no-store, max-age=0',
  'Pragma': 'no-cache',
  'Vary': 'Authorization',
  'X-Content-Type-Options': 'nosniff',
};
const fail = (status: number) => Response.json({error: 'Photo unavailable'}, {status, headers});

// POST deliberately avoids a reusable CDN URL. Authorization is checked on
// every request through the user's RLS context before reading immutable bytes.
Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') return fail(405);
  const authorization = request.headers.get('Authorization') ?? '';
  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: {headers: {Authorization: authorization}}, auth: {persistSession: false},
  });
  const {data: {user}, error: authError} = await userClient.auth.getUser();
  if (authError || !user) return fail(401);
  const reader = request.body?.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  if (reader) {
    while (true) {
      const {value, done} = await reader.read();
      if (done) break;
      size += value.length;
      if (size > 1024) { await reader.cancel(); return fail(413); }
      chunks.push(value);
    }
  }
  const inputBytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) { inputBytes.set(chunk, offset); offset += chunk.length; }
  const input = new TextDecoder().decode(inputBytes);
  let kind: string, target: string;
  try {
    const body = JSON.parse(input);
    kind = body.kind; target = body.target;
  } catch (_) { return fail(400); }
  if (!['profile', 'pet', 'group'].includes(kind) || typeof target !== 'string' ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(target)) return fail(400);
  const {data: photo, error: photoError} = await userClient.from('entity_photos')
    .select('object_path').eq('kind', kind).eq('target_id', target).maybeSingle();
  // RLS validates MFA, session revocation, blocks and current entity ownership.
  if (photoError || !photo) return fail(404);
  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: {persistSession: false},
  });
  const {data: bytes, error: readError} = await admin.storage.from('petfriendly-photos').download(photo.object_path);
  if (readError || !bytes) return fail(404);
  return new Response(bytes, {headers: {...headers, 'Content-Type': 'application/octet-stream'}});
});
