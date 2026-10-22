const nearbyMock=PFMock,nui=PFUI,na=nearbyMock.account();
const baseNearbyIcons=icons;
icons=function(){document.getElementById('phone').classList.toggle('dark',nearbyMock.prefs.theme==='dark');document.getElementById('phone').classList.toggle('large',nearbyMock.prefs.large);baseNearbyIcons();nui.translate()};
selectNearbyCity=function(n){const c=cityChoices[n];na.city={city:c[0],country:c[1],zone:nearbyMock.cityZone(c[0]),selection:'manual'};document.getElementById('city-name').textContent=c[0];citySelection='manual';dismiss();updateNearbyMeeting()};
saveNearbyManual=function(){const city=document.getElementById('manual-city').value.trim(),country=document.getElementById('manual-country').value.trim();if(!city||!country){document.getElementById('manual-error').textContent='Укажите населённый пункт и страну.';return}na.city={city,country,zone:nearbyMock.cityZone(city),selection:'manual'};document.getElementById('city-name').textContent=city+' · '+country;citySelection='manual';dismiss();updateNearbyMeeting()};
const baseDetectNearby=detectNearbyCity;
detectNearbyCity=function(){baseDetectNearby();updateNearbyMeeting()};
function updateNearbyMeeting(){const button=document.querySelector('.meeting-preview'),m=na.meeting;if(m.city!==na.city.city){button.disabled=true;button.innerHTML='<strong>Встреч пока нет</strong><span class="meta">Для выбранного города в макете нет встреч.</span>'}else{button.disabled=false;button.innerHTML=`<strong data-user-content>${nui.esc(m.name)}</strong><span class="meta" data-user-content>${nui.esc(PFUI.date(m)+' · '+m.venue)}</span><span class="link">Все встречи<i data-lucide="arrow-right" class="icon"></i></span>`}icons()}
const baseShowCity=showCity;
showCity=function(){baseShowCity();nui.translate()};
updateNearbyMeeting();
