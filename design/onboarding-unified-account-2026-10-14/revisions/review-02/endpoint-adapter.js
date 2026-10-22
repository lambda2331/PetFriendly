// Only replace simplified shell-review fixtures with the approved prior pages.
// Frozen scripts and all source reference pages remain untouched.
const originalRender=render;
render=function(){originalRender();const v=views[0];if(['nearby','people'].includes(v.page)&&!v.modal&&!v.sheet){document.getElementById('phone-0').innerHTML=`<iframe title="Approved ${v.page} reference" src="${v.page}-reference.html" style="width:100%;height:100%;border:0"></iframe>`;}}
go(0,new URLSearchParams(location.search).get('screen')||'nearby');
const originalSheet=sheet,originalProfile=profile;
let profilePreview=null;
sheet=function(i){if(views[i].sheet==='editProfile')return '<iframe title="Existing profile editor" src="profile-edit-reference.html" style="position:absolute;inset:0;width:100%;height:100%;border:0;z-index:10"></iframe>';return originalSheet(i);}
profile=function(i){const html=originalProfile(i);return profilePreview?html.replace('Анна Ковалевская',escape(profilePreview.name)).replace('Минск · Центральный район',escape(profilePreview.city+' · '+profilePreview.district)):html;}
function updateProfilePreview(value){profilePreview={name:value.name,city:value.city,district:value.district};views[0].about=value.about;closeSheet(0);}
function profileDraftForEditor(){return profilePreview?{...profilePreview,about:views[0].about}:null;}
