// The service worker that makes the app open with no network. It keeps a
// copy of the page, its script and its style, and answers from that copy
// before asking the server.
const SHELL = ['/spa/', '/spa/spa.js', '/style.css'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open('shell-v1').then((cache) => cache.addAll(SHELL)));
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.pathname.startsWith('/api/')) return;
  event.respondWith(caches.match(event.request).then((hit) => hit ?? fetch(event.request)));
});
