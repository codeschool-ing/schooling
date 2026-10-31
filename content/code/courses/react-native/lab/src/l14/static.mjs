// static.mjs: serve dist/ with the two headers SQLite on the web needs, falling back to index.html.
import { createReadStream, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join } from "node:path";

const [dir, port] = process.argv.slice(2);
const types = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".css": "text/css", ".png": "image/png", ".json": "application/json", ".ico": "image/x-icon", ".ttf": "font/ttf" };
createServer((req, res) => {
  let file = join(dir, decodeURIComponent(new URL(req.url, "http://x").pathname));
  if (!existsSync(file) || statSync(file).isDirectory()) file = join(dir, "index.html");
  res.writeHead(200, {
    "content-type": types[extname(file)] ?? "application/octet-stream",
    "cross-origin-opener-policy": "same-origin",
    "cross-origin-embedder-policy": "require-corp",
  });
  createReadStream(file).pipe(res);
}).listen(Number(port), () => console.log(`serving ${dir} on ${port}`));
