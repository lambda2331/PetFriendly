import { createClient } from 'npm:@supabase/supabase-js@2';
import { Image } from 'https://deno.land/x/imagescript@1.3.0/mod.ts';
Deno.serve(async (request:Request)=>{
 if(request.method!=='POST')return new Response('Method not allowed',{status:405});
 const url=Deno.env.get('SUPABASE_URL')!;
 const client=createClient(url,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:request.headers.get('Authorization')??''}},auth:{persistSession:false}});
 const {data:{user},error}=await client.auth.getUser();
 if(error||!user)return Response.json({error:'Authentication required'},{status:401});
 const params=new URL(request.url).searchParams;const kind=params.get('kind'),target=params.get('target');
 if(!['profile','pet','group'].includes(kind??'')||!target||! /^[0-9a-f-]{36}$/i.test(target))return Response.json({error:'Invalid target'},{status:400});
 const {error:access}=await client.rpc('authorize_photo',{kind_in:kind,target_in:target});
 if(access)return Response.json({error:'Photo unavailable or upload too frequent'},{status:403});
 // Bound the streamed request before allocating a decoder; the Flutter picker outputs PNG.
 const reader=request.body?.getReader();if(!reader)return Response.json({error:'Image required'},{status:400});
 let total=0;const chunks:Uint8Array[]=[];
 while(true){const {done,value}=await reader.read();if(done)break;total+=value.length;if(total>8388608){await reader.cancel();return Response.json({error:'Image too large'},{status:413});}chunks.push(value);}
 const bytes=new Uint8Array(total);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
 const png=[137,80,78,71,13,10,26,10];
 if(total<33||png.some((b,i)=>bytes[i]!==b)||String.fromCharCode(...bytes.slice(12,16))!=='IHDR')return Response.json({error:'PNG required'},{status:400});
 const view=new DataView(bytes.buffer);const width=view.getUint32(16),height=view.getUint32(20);
 if(!width||!height||width>1200||height>1200)return Response.json({error:'Image dimensions exceed limit'},{status:400});
 let encoded:Uint8Array;
 try{const image=await Image.decode(bytes);encoded=await image.encodeJPEG(85);}catch{return Response.json({error:'Invalid image'},{status:400});}
 // New encoding never copies EXIF/text chunks. Untrusted original bytes are never stored.
 const admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}});
 const path=`${user.id}/${crypto.randomUUID()}.jpg`;const bucket=admin.storage.from('petfriendly-photos');
 const {error:uploadError}=await bucket.upload(path,encoded,{contentType:'image/jpeg',cacheControl:'0',upsert:false});
 if(uploadError)return Response.json({error:'Photo storage unavailable'},{status:503});
 const {data:oldPath,error:publishError}=await admin.rpc('publish_photo',{user_in:user.id,session_in:JSON.parse(atob((request.headers.get('Authorization')??'').replace(/^Bearer /i,'').split('.')[1].replace(/-/g,'+').replace(/_/g,'/'))).session_id,kind_in:kind,target_in:target,path_in:path});
 if(publishError){await bucket.remove([path]);return Response.json({error:'Photo unavailable'},{status:403});}
 if(oldPath)await bucket.remove([oldPath]);
 return Response.json({saved:true});
});
