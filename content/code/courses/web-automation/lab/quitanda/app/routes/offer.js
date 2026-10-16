import { send } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/offer',
    handle: ({ res }) => {
      const product = store.products.find((p) => p.id === store.offer.id);
      // A known flaw, on purpose: the browser may keep this answer for ten
      // minutes without asking again, so a new offer goes unseen.
      send(res, 200, { name: product.name, price: store.offer.price },
        { 'Cache-Control': 'max-age=600' });
    },
  },
  {
    method: 'POST', path: '/api/offer',
    handle: ({ res, body }) => {
      store.offer = { id: body.id, price: body.price };
      send(res, 200, store.offer);
    },
  },
];
