import { createClient } from 'npm:@supabase/supabase-js@2';
Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', {status:405});
  const auth = request.headers.get('Authorization') ?? '';
  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {global:{headers:{Authorization:auth}}});
  const {data:{user},error} = await userClient.auth.getUser();
  if(error||!user)return Response.json({error:'Authentication required'},{status:401});
  const admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}});
  const {data:alreadyRequested}=await admin.rpc('deletion_authorized',{user_in:user.id});
  const {error:requestError}=alreadyRequested?{error:null}:await userClient.rpc('request_account_deletion');
  if(requestError)return Response.json({error:'Recent authentication required'},{status:403});
  const {data:allowed,error:checkError}=await admin.rpc('deletion_authorized',{user_in:user.id});
  if(checkError||!allowed)return Response.json({error:'Deletion is not authorized'},{status:403});
  // Remove all owned blobs, including an upload whose metadata publish failed.
  for (const name of ['petfriendly-photos','petfriendly-chat']) {
  const bucket=admin.storage.from(name);
  while(true){
    const {data:objects,error:listError}=await bucket.list(user.id,{limit:100});
    if(listError)return Response.json({error:'Account revoked; photo cleanup requires retry'},{status:503});
    if(!objects?.length)break;
    const {error:removeError}=await bucket.remove(objects.map(o=>`${user.id}/${o.name}`));
    if(removeError)return Response.json({error:'Account revoked; photo cleanup requires retry'},{status:503});
  }
  }
  const {error:deleteError}=await admin.auth.admin.deleteUser(user.id);
  if(deleteError)return Response.json({error:'Account access revoked; cleanup requires retry'},{status:503});
  return Response.json({deleted:true});
});
