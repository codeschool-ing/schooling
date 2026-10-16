// Quitanda: the shop every lesson of this course tests. No dependencies,
// only what Node itself ships.
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { send } from './http.js';

const port = Number(process.env.PORT ?? 3000);
const publicDir = path.join(import.meta.dirname, 'public');
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
};

// Every file in routes/ exports a list of routes. A later lesson adds a
// file there; this one never changes.
const routes = [];
const routeDir = path.join(import.meta.dirname, 'routes');
for (const file of (await fs.readdir(routeDir)).sort()) {
  routes.push(...(await import(path.join(routeDir, file))).routes);
}

async function serveFile(req, res, pathname) {
  if (pathname.endsWith('/')) pathname += 'index.html';
  const file = path.join(publicDir, path.normalize(pathname));
  if (!file.startsWith(publicDir)) return send(res, 404, 'not found');
  let body;
  try {
    body = await fs.readFile(file);
  } catch {
    return send(res, 404, 'not found');
  }
  // A static file may be kept, but must be checked with the server first.
  const etag = '"' + crypto.createHash('sha1').update(body).digest('hex').slice(0, 12) + '"';
  const headers = { 'Cache-Control': 'no-cache', ETag: etag };
  if (req.headers['if-none-match'] === etag) {
    res.writeHead(304, headers);
    return res.end();
  }
  headers['Content-Type'] = types[path.extname(file)] ?? 'application/octet-stream';
  res.writeHead(200, headers);
  res.end(body);
}

async function readJson(req) {
  let text = '';
  for await (const chunk of req) text += chunk;
  return text ? JSON.parse(text) : {};
}

http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  // QUITANDA_LOG=1 prints every request the server receives.
  if (process.env.QUITANDA_LOG) {
    res.on('finish', () => console.log(req.method, req.url, res.statusCode));
  }
  const route = routes.find((r) => r.method === req.method && r.path === url.pathname);
  try {
    if (route) return await route.handle({ req, res, url, body: await readJson(req) });
    if (req.method === 'GET') return await serveFile(req, res, url.pathname);
    send(res, 404, 'not found');
  } catch (err) {
    console.error(err);
    send(res, 500, { error: String(err.message) });
  }
}).listen(port, () => console.log(`quitanda is listening on http://localhost:${port}`));
