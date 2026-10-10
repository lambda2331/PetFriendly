import { createClient } from 'npm:@supabase/supabase-js@2';
import { parsePlaces } from './osm.ts';
import { cityGeocodingQuery } from './geocoding.ts';
Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', {status:405});
  const url=Deno.env.get('SUPABASE_URL')!;
  const userClient=createClient(url,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:request.headers.get('Authorization')??''}},auth:{persistSession:false}});
  const {data:{user},error}=await userClient.auth.getUser();
  if(error||!user)return Response.json({error:'Authentication required'},{status:401});
  // require_actor inside this RPC rejects revoked sessions and enforces staff MFA.
  const {error:actorError}=await userClient.rpc('catalog_actor');
  if(actorError)return Response.json({error:'Session unavailable'},{status:403});
  let body;
  try {body=await request.json();} catch {return Response.json({error:'Invalid city'},{status:400});}
  const {city}=body;
  if(typeof city!=='string'||!city.trim()||city.length>120)
    return Response.json({error:'Invalid city'},{status:400});
  const admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}});
  const {data:claim,error:claimError}=await admin.rpc('claim_city_catalog',{user_in:user.id,city_in:city});
  if(claimError)return Response.json({error:'Catalog unavailable'},{status:503});
  if(claim.status==='ready')return Response.json({status:'ready'});
  if(claim.status!=='fetch')return Response.json({status:'busy'},{status:202});
  try {
    // Resolve the public city on the server; never trust a client location as catalog authority.
    const geocodeUrl=new URL(Deno.env.get('OSM_GEOCODER_URL')??'https://nominatim.openstreetmap.org/search');
    geocodeUrl.search=new URLSearchParams({q:cityGeocodingQuery(city),format:'jsonv2',limit:'1'}).toString();
    const geocode=await fetch(geocodeUrl,{headers:{'User-Agent':'PetFriendly/0.3 (pet places catalog)'},signal:AbortSignal.timeout(10000)});
    if(!geocode.ok)throw new Error('City lookup unavailable');
    const [match]=await geocode.json();
    if(!match||!['city','town','village','municipality'].includes(match.addresstype))throw new Error('City not found');
    const latitude=Number(match.lat),longitude=Number(match.lon);
    if(!Number.isFinite(latitude)||!Number.isFinite(longitude)||Math.abs(latitude)>90||Math.abs(longitude)>180)throw new Error('Invalid city');
    const query=`[out:json][timeout:25];(nwr["leisure"~"^(park|dog_park)$"](around:15000,${latitude},${longitude});nwr["shop"="pet"](around:15000,${latitude},${longitude});nwr["amenity"="veterinary"](around:15000,${latitude},${longitude}););out center meta;`;
    const response=await fetch(Deno.env.get('OSM_OVERPASS_URL')??'https://overpass-api.de/api/interpreter',{
      method:'POST',headers:{'User-Agent':'PetFriendly/0.3 (pet places catalog)','Content-Type':'application/x-www-form-urlencoded'},
      body:new URLSearchParams({data:query}),signal:AbortSignal.timeout(35000),
    });
    if(!response.ok)throw new Error('OSM unavailable');
    if(!response.body)throw new Error('Empty response');
    const reader=response.body.getReader();let size=0;const chunks:Uint8Array[]=[];
    while(true){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>8000000){await reader.cancel();throw new Error('Response too large');}chunks.push(value);}
    const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
    const records=parsePlaces(JSON.parse(new TextDecoder().decode(bytes)),claim.city);
    // Refresh source fields atomically while retaining IDs, moderation and edits.
    for(let i=0;i<records.length;i+=200){
      const {error}=await admin.rpc('import_city_catalog',{
        city_in:claim.city,lease_in:claim.lease,records_in:records.slice(i,i+200),
      });
      if(error)throw error;
    }
    const {error:finishError}=await admin.rpc('finish_city_catalog',{city_in:city,lease_in:claim.lease,success_in:true});
    if(finishError)throw finishError;
    return Response.json({status:'ready',imported:records.length});
  } catch {
    await admin.rpc('finish_city_catalog',{city_in:city,lease_in:claim.lease,success_in:false});
    return Response.json({error:'Catalog temporarily unavailable'},{status:503});
  }
});
