import { createClient } from 'npm:@supabase/supabase-js@2';
import { Image } from 'https://deno.land/x/imagescript@1.3.0/mod.ts';
const headers={'Cache-Control':'private, no-store, max-age=0','Pragma':'no-cache','Vary':'Authorization','X-Content-Type-Options':'nosniff'};
const fail=(status:number)=>Response.json({error:'Attachment unavailable'},{status,headers});
const uuid=(value:string|null)=>!!value&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
Deno.serve(async(request:Request)=>{
 if(request.method!=='POST')return fail(405);
 const authorization=request.headers.get('Authorization')??'',url=Deno.env.get('SUPABASE_URL')!;
 const client=createClient(url,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:authorization}},auth:{persistSession:false}});
 const {data:{user},error}=await client.auth.getUser();if(error||!user)return fail(401);
 const params=new URL(request.url).searchParams;
 const admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}}),bucket=admin.storage.from('petfriendly-chat');
 if(params.get('mode')==='read'){
   const message=params.get('message');if(!uuid(message))return fail(400);
   const {data:attachment,error:access}=await client.from('chat_attachments').select('object_path,mime').eq('message_id',message).maybeSingle();
   if(access||!attachment)return fail(404);
   const {data:bytes,error:download}=await bucket.download(attachment.object_path);
   if(download||!bytes)return fail(404);
   return new Response(bytes,{headers:{...headers,'Content-Type':'application/octet-stream'}});
 }
 const conversation=params.get('conversation'),nonce=params.get('client_id'),kind=params.get('kind');
 if(!uuid(conversation)||!uuid(nonce)||kind!=='image')return fail(400);
 const {error:access}=await client.rpc('authorize_chat_media',{conversation_in:conversation});if(access)return fail(403);
 const reader=request.body?.getReader();if(!reader)return fail(400);
 const limit=5*1024*1024;let total=0;const chunks:Uint8Array[]=[];
 while(true){const {done,value}=await reader.read();if(done)break;total+=value.length;if(total>limit+8196){await reader.cancel();return fail(413);}chunks.push(value);}
 const body=new Uint8Array(total);let offset=0;for(const chunk of chunks){body.set(chunk,offset);offset+=chunk.length;}
 if(total<4)return fail(400);
 const metadataSize=new DataView(body.buffer).getUint32(0);if(metadataSize>8192||metadataSize+4>total)return fail(400);
 let caption:string,inputMime:string;
 try{const metadata=JSON.parse(new TextDecoder().decode(body.slice(4,4+metadataSize)));caption=metadata.caption;inputMime=metadata.mime;if(typeof caption!=='string'||Array.from(caption).length>1000)return fail(400);}catch{return fail(400);}
 const raw=body.slice(4+metadataSize);total=raw.length;if(total>limit)return fail(413);
 let bytes:Uint8Array,mime:string,duration:number|null=null;
 try{
   if(inputMime!=='image/png')return fail(400);
   if(total<33||[137,80,78,71,13,10,26,10].some((b,i)=>raw[i]!==b))return fail(400);
   const view=new DataView(raw.buffer),width=view.getUint32(16),height=view.getUint32(20);
   if(!width||!height||width>1200||height>1200)return fail(400);
   const image=await Image.decode(raw);
   bytes=await image.encodeJPEG(85);mime='image/jpeg';
   for(const quality of [70,50,35]){if(bytes.length<=1024*1024)break;bytes=await image.encodeJPEG(quality);}
   if(bytes.length>1024*1024)return fail(413);
 }catch{return fail(400);}
 const path=`${user.id}/${crypto.randomUUID()}.${kind==='image'?'jpg':mime==='video/quicktime'?'mov':'mp4'}`;
 const {error:upload}=await bucket.upload(path,bytes,{contentType:mime,cacheControl:'0',upsert:false});if(upload)return fail(503);
 async function discardIfUnpublished(){
   // A lost RPC response may follow a successful commit: never delete a linked blob.
   const {data:linked,error:lookup}=await admin.from('chat_attachments').select('message_id').eq('object_path',path).maybeSingle();
   if(!lookup&&!linked)await bucket.remove([path]);
 }

 try{
   // getUser above validated this JWT; server RPC checks session/MFA again at commit.
   const payload=JSON.parse(atob(authorization.replace(/^Bearer /i,'').split('.')[1].replace(/-/g,'+').replace(/_/g,'/')));
   const claims={sub:user.id,session_id:payload.session_id,aal:payload.aal};
   const {data:result,error:publish}=await admin.rpc('publish_chat_media',{claims_in:claims,conversation_in:conversation,client_id:nonce,body_in:caption,path_in:path,kind_in:kind,mime_in:mime,size_in:bytes.length,duration_in:duration});
   if(publish){await discardIfUnpublished();return fail(403);}
   if(!result.created)await bucket.remove([path]);
   return Response.json({id:result.id},{headers});
 }catch{await discardIfUnpublished();return fail(503);}
});
