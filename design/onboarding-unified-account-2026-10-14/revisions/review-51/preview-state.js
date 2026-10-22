/* F01/F02: local design-preview infrastructure; not authentication or server authorization. */
(function(root){
 'use strict';
 const clone=v=>v===undefined?undefined:structuredClone(v);
 const types=new Set(['pets','places','requests','applications','agreements','conversations','messages','reviews','communities','events']);
 function createPreviewState({accountId='preview-A',seed=()=>({}),device={}}={}){
  const accounts=new Map(),listeners=new Set();let active=accountId,epoch=0,preferences={theme:'system',language:'device',...clone(device)};
  function account(){if(!accounts.has(active)){const initial=clone(seed(active))||{};accounts.set(active,{profile:initial.profile||{},favorites:new Set(initial.favoriteIds||[]),preferences:initial.preferences||{},records:new Map(),drafts:new Map(),contexts:new Map(),navigation:[],mode:'owner'})}return accounts.get(active)}
  function notify(){for(const fn of [...listeners])fn({accountId:active,epoch})}
  function connect(){const id=active,generation=epoch;const state=()=>{if(id!==active||generation!==epoch)throw Error('Stale preview connection');return account()};
   return Object.freeze({accountId:id,valid:()=>id===active&&generation===epoch,
    profile:()=>clone(state().profile),saveProfile:value=>{state().profile={...state().profile,...clone(value),id}},
    favorites:()=>[...state().favorites],setFavorite:(placeId,on)=>{if(typeof placeId!=='string'||!placeId)throw Error('Stable place ID required');if(on)state().favorites.add(placeId);else state().favorites.delete(placeId)},
    city:()=>clone(state().preferences.citySelection),selectCity:(city,mode='manual')=>{if(!city||typeof city.key!=='string'||!['manual','nearby'].includes(mode))throw Error('Canonical city key required');state().preferences.citySelection={mode,city:Object.fromEntries(['key','name','country','region','zone'].filter(k=>city[k]!==undefined).map(k=>[k,clone(city[k])]))}},
    preferences:()=>clone(state().preferences),savePreferences:value=>{state().preferences={...state().preferences,...clone(value)}},
    records:type=>{if(!types.has(type))throw Error('Unknown preview record type');return [...(state().records.get(type)||new Map()).values()].map(clone)},
    put:(type,value)=>{if(!types.has(type)||!value||typeof value.id!=='string'||!value.id)throw Error('Stable record ID required');const a=state();if(!a.records.has(type))a.records.set(type,new Map());a.records.get(type).set(value.id,clone(value));},
    remove:(type,id)=>{if(!types.has(type))throw Error('Unknown preview record type');state().records.get(type)?.delete(id)},
    draft:(form,record='')=>clone(state().drafts.get(JSON.stringify([form,record]))),
    saveDraft:(form,record,value)=>{if(!form)throw Error('Draft form key required');state().drafts.set(JSON.stringify([form,record||'']),clone(value))},
    clearDraft:(form,record='')=>state().drafts.delete(JSON.stringify([form,record])),
    context:key=>clone(state().contexts.get(key)),saveContext:(key,value)=>state().contexts.set(key,clone(value)),
    current:()=>clone(state().navigation.at(-1)),history:()=>clone(state().navigation),
    navigate:(route,{replace=false}={})=>{if(!route||!route.screen)throw Error('Screen key required');const stack=state().navigation;const next=clone(route);if(replace&&stack.length)stack[stack.length-1]=next;else if(JSON.stringify(stack.at(-1))!==JSON.stringify(next))stack.push(next);return clone(next)},
    back:()=>{const stack=state().navigation;if(stack.length<2)return null;stack.pop();return clone(stack.at(-1))},
    mode:()=>state().mode,setMode:mode=>{if(!['owner','helper'].includes(mode))throw Error('Invalid preview mode');state().mode=mode},
   });
  }
  account();return Object.freeze({connect,accountId:()=>active,switchAccount:id=>{if(typeof id!=='string'||!id)throw Error('Account ID required');active=id;epoch++;account();notify()},reset:()=>{accounts.delete(active);epoch++;account();notify()},subscribe:fn=>{listeners.add(fn);return()=>listeners.delete(fn)},device:()=>clone(preferences),setDevice:value=>{const next={...preferences,...clone(value)};if(!['system','light','dark'].includes(next.theme)||!['device','ru','en','be','pl'].includes(next.language))throw Error('Invalid device preference');preferences=next}});
 }
 root.PFPreviewState={create:createPreviewState};if(typeof module!=='undefined')module.exports={create:createPreviewState};
})(typeof window==='undefined'?globalThis:window);
