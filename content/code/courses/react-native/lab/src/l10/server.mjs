// server.mjs: the planner's server: the plan, and one way to change it.
// It keeps the plan in memory, so it starts from src/courses.json every time it starts.
import { readFileSync } from "node:fs";
import { createServer } from "node:http";

const plan = JSON.parse(readFileSync("src/courses.json", "utf8"));
const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": "*", // the web build is served from another port
  "access-control-allow-methods": "GET, POST",
};

createServer((req, res) => {
  console.log(req.method, req.url);
  const done = req.url?.match(/^\/sessions\/([\w-]+)\/done$/);
  if (req.method === "OPTIONS") return res.writeHead(204, headers).end();
  if (req.method === "GET" && req.url === "/plan") return res.writeHead(200, headers).end(JSON.stringify(plan));
  if (req.method === "POST" && done) {
    const session = plan.sessions.find((s) => s.id === done[1]);
    if (!session) return res.writeHead(404, headers).end(JSON.stringify({ error: `no session ${done[1]}` }));
    session.done = true;
    return res.writeHead(200, headers).end(JSON.stringify(session));
  }
  res.writeHead(404, headers).end(JSON.stringify({ error: "not found" }));
}).listen(8008, () => console.log("listening on 8008"));
