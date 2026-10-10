import { send, pause } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/search',
    handle: async ({ res, url }) => {
      const q = (url.searchParams.get('q') ?? '').toLowerCase();
      // A known flaw, on purpose: a short query takes longer to answer, so
      // the answer to "p" arrives after the answer to "papaya".
      await pause(Math.max(0, 900 - 150 * q.length));
      send(res, 200, store.products.filter((p) => p.name.toLowerCase().includes(q)));
    },
  },
];
