/* A174/A180/A186/A192: account-local shared conversation origins; no URLs or private state persistence. */
(function(root){
 const supported=new Set(['chat-direct-design','chat-group-design','meeting-chat','chat-walk-design','walk-assigned','walk-active','walk-awaiting-confirmation','walk-awaiting-owner','walk-completed','walk-completed-helper','walk-progress-controls','walk-confirm-controls','walk-start-controls','walk-review-controls','walk-helper-review-controls']);
 const aux=new Set(['chat-info-design','chat-members-design','chat-block-design','report-chat','report-chat-sent']);
 const keys=new Set(['event','member','community','candidate','place','record','request','agreement','conversation','pet','review']);
 const clean=(route,mode)=>({screen:route.screen,params:Object.fromEntries(Object.entries(route.params||{}).filter(([key,value])=>keys.has(key)&&typeof value==='string').sort(([a],[b])=>a.localeCompare(b))),mode:['owner','helper'].includes(route.mode)?route.mode:mode});
 const same=(a,b)=>!!a&&!!b&&JSON.stringify(clean(a,'owner'))===JSON.stringify(clean(b,'owner'));
 const originAllowed=(route,known)=>route&&known(route.screen)&&!supported.has(route.screen)&&route.screen!=='target-unavailable'&&route.screen!=='chat-notice'&&!route.screen.startsWith('chat-')&&!aux.has(route.screen);
 function enter(port,next,frames=[],known=()=>true){
  const current=port.current(),history=port.history();let inherited;
  if(supported.has(current?.screen)||aux.has(current?.screen)){
   inherited=[...history].reverse().find(r=>r.originKey&&r.params?.conversation===next.params?.conversation);
   if(!inherited&&supported.has(current?.screen))inherited=current;
  }
  if(inherited?.originKey){const saved=port.context(inherited.originKey);if(saved?.accountId===port.accountId&&originAllowed(saved.route,known))return {...next,originKey:inherited.originKey}}
  if(!originAllowed(current,known))return next;
  const originKey='conversation-origin:'+crypto.randomUUID();
  port.saveContext(originKey,{accountId:port.accountId,route:clean(current,port.mode()),index:history.length-1,frames:structuredClone(frames)});
  return {...next,originKey};
 }
 function back(port,known=()=>true){
  const current=port.current(),saved=current?.originKey?port.context(current.originKey):null;
  if(saved?.accountId===port.accountId&&originAllowed(saved.route,known)&&['owner','helper'].includes(saved.route.mode)){
   const history=port.history();
   if(Number.isInteger(saved.index)&&saved.index>=0&&same(history[saved.index],saved.route))while(port.history().length>saved.index+1)port.back();
   else {while(port.history().length>1)port.back();port.navigate(saved.route,{replace:true});}
   for(const frame of saved.frames||[]){
    if(typeof frame.key!=='string'||typeof frame.record!=='string')continue;
    if(frame.fields)port.saveDraft('fields:'+frame.key,frame.record,{...(port.draft('fields:'+frame.key,frame.record)||{}),...frame.fields});
    port.saveContext('filters:'+frame.key,frame.filters);port.saveContext('scroll:'+frame.key,frame.scroll||[]);
   }
   port.setMode(saved.route.mode);return port.current();
  }
  const fallback={screen:'chats',params:{},mode:port.mode()};port.navigate(fallback,{replace:true});return port.current();
 }
 root.PFPreviewDirectNavigation={enter,back};if(typeof module!=='undefined')module.exports=root.PFPreviewDirectNavigation;
})(typeof window==='undefined'?globalThis:window);
