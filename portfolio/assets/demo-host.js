// This host contains no product UI or scenario logic; Flutter owns every screen.
const params = new URLSearchParams(location.search);
const routes = {nearby:'/nearby',people:'/people',walk:'/walks',chats:'/chats',profile:'/profile'};
const frame = document.getElementById('flutter-demo');
if (params.get('embed') === '1') document.documentElement.classList.add('embed');
const route = routes[params.get('screen')] || '/nearby';
frame.src = `app/#${route}`;
document.getElementById('reset-demo').addEventListener('click', () => {
  // Reload the same route. Persistent preferences intentionally remain intact.
  frame.src = `app/?restart=${Date.now()}#${route}`;
});
