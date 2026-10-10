import { send } from '../http.js';
import { store, reset, total } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/products',
    handle: ({ res }) => send(res, 200, store.products),
  },
  {
    method: 'GET', path: '/api/basket',
    handle: ({ res }) => send(res, 200, { lines: store.basket, total: total(store.basket) }),
  },
  {
    method: 'POST', path: '/api/basket',
    handle: ({ res, body }) => {
      if (!store.products.some((p) => p.id === body.id)) {
        return send(res, 400, { error: `no product called ${body.id}` });
      }
      const line = store.basket.find((l) => l.id === body.id);
      if (line) line.qty += 1;
      else store.basket.push({ id: body.id, qty: 1 });
      send(res, 200, { lines: store.basket, total: total(store.basket) });
    },
  },
  {
    method: 'POST', path: '/api/reset',
    handle: ({ res }) => {
      reset();
      send(res, 200, { reset: true });
    },
  },
];
