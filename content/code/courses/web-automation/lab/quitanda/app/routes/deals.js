import { send } from '../http.js';

// Adaptive: the server picks one of two pages from the User-Agent header.
// A narrow window on a desktop browser still gets the desktop page.
export const routes = [
  {
    method: 'GET', path: '/deals',
    handle: ({ req, res }) => {
      const phone = /Mobile/.test(req.headers['user-agent'] ?? '');
      const body = phone
        ? '<!doctype html><title>Deals</title><h1>Deals</h1><p>Tap a deal to call the shop.</p>'
        : '<!doctype html><title>Deals</title><h1>Deals</h1><p>Weekly deals, in a table.</p>';
      send(res, 200, body, { 'Content-Type': 'text/html; charset=utf-8', Vary: 'User-Agent' });
    },
  },
];
