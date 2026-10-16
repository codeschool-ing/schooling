import { send } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'POST', path: '/api/users',
    handle: ({ res, body }) => {
      const name = String(body.name ?? '').trim();
      if (!name) return send(res, 400, { error: 'a name is required' });
      if (store.users.has(name)) return send(res, 409, { error: `${name} already exists` });
      store.users.add(name);
      send(res, 201, { name });
    },
  },
  {
    method: 'DELETE', path: '/api/users',
    handle: ({ res, url }) => {
      store.users.delete(url.searchParams.get('name'));
      res.writeHead(204);
      res.end();
    },
  },
];
