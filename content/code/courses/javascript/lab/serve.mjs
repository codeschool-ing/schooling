// The lab's web server: ana's ~/js as static files, and a small API under
// /api/ that lesson 16 fetches from. Same origin for both, so no request in
// this course needs CORS (that is front-quality lesson 7).
//
//   node serve.mjs [ROOT] [PORT]      default ROOT=., PORT=8080
//
// Every response is deterministic except /api/slow, which waits for real.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const TYPES = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8", ".svg": "image/svg+xml",
  ".txt": "text/plain; charset=utf-8",
};

const BOOKS = [
  { id: 1, title: "Dom Casmurro", author: "Machado de Assis", year: 1899 },
  { id: 2, title: "Grande Sertão: Veredas", author: "João Guimarães Rosa", year: 1956 },
  { id: 3, title: "A Hora da Estrela", author: "Clarice Lispector", year: 1977 },
];

function json(res, status, body) {
  const text = JSON.stringify(body);
  res.writeHead(status, { "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(text) });
  res.end(text);
}

export function api(req, res, url, state) {
  const p = url.pathname;
  if (p === "/api/books" && req.method === "GET") return json(res, 200, BOOKS);
  if (p === "/api/books" && req.method === "POST") {
    let body = "";
    req.on("data", (c) => (body += c));
    req.on("end", () => {
      let book;
      try { book = JSON.parse(body); } catch { return json(res, 400, { error: "the body is not JSON" }); }
      if (!book.title) return json(res, 422, { error: "a book needs a title" });
      json(res, 201, { id: 4, ...book });
    });
    return;
  }
  const one = p.match(/^\/api\/books\/(\d+)$/);
  if (one) {
    const b = BOOKS.find((x) => x.id === Number(one[1]));
    return b ? json(res, 200, b) : json(res, 404, { error: `no book ${one[1]}` });
  }
  if (p === "/api/broken") return json(res, 500, { error: "the database is not answering" });
  if (p === "/api/html") {
    res.writeHead(502, { "content-type": "text/html; charset=utf-8" });
    return res.end("<html><body><h1>502 Bad Gateway</h1></body></html>\n");
  }
  if (p === "/api/slow") {
    const ms = Number(url.searchParams.get("ms") || 3000);
    const t = setTimeout(() => json(res, 200, { waited: ms }), ms);
    res.on("close", () => clearTimeout(t));
    return;
  }
  if (p === "/api/flaky") {
    // Fails the first N requests of this server's life, then answers.
    state.flaky = (state.flaky || 0) + 1;
    const fails = Number(url.searchParams.get("fails") || 2);
    return state.flaky <= fails
      ? json(res, 503, { error: "busy, try again", attempt: state.flaky })
      : json(res, 200, { ok: true, attempt: state.flaky });
  }
  json(res, 404, { error: "no such endpoint" });
}

export function createServer(root) {
  const state = {};
  return http.createServer((req, res) => {
    const url = new URL(req.url, "http://127.0.0.1");
    if (url.pathname.startsWith("/api/")) return api(req, res, url, state);
    const file = path.join(root, decodeURIComponent(url.pathname));
    if (!file.startsWith(path.resolve(root))) { res.writeHead(403); return res.end(); }
    fs.readFile(file, (err, data) => {
      if (err) { res.writeHead(404, { "content-type": "text/plain" }); return res.end("not found\n"); }
      res.writeHead(200, { "content-type": TYPES[path.extname(file)] || "application/octet-stream" });
      res.end(data);
    });
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const root = path.resolve(process.argv[2] || ".");
  const port = Number(process.argv[3] || 8080);
  createServer(root).listen(port, "127.0.0.1", () => console.log(`serving ${root} on http://127.0.0.1:${port}`));
}
