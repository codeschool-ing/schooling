// server.mjs: the planner's server: the plan, a session marked done, and a session added.
// It keeps the plan in memory, so it starts from src/courses.json every time it starts.
import { readFileSync } from "node:fs";
import { createServer } from "node:http";

const plan = JSON.parse(readFileSync("src/courses.json", "utf8"));
const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": "*", // the web build is served from another port
  "access-control-allow-methods": "GET, POST",
  "access-control-allow-headers": "content-type",
};
const send = (res, status, body) => res.writeHead(status, headers).end(JSON.stringify(body));

// The server checks everything itself: a request may come from anything, not only from the app.
function invalid(s) {
  if (!plan.courses.some((c) => c.id === s.course)) return `no course ${s.course}`;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s.date ?? "")) return "date must be YYYY-MM-DD";
  if (!Number.isInteger(s.minutes) || s.minutes < 5 || s.minutes > 240) return "minutes must be 5 to 240";
  return null;
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  console.log(req.method, req.url, text);
  const done = req.url?.match(/^\/sessions\/([\w-]+)\/done$/);
  if (req.method === "OPTIONS") return res.writeHead(204, headers).end();
  if (req.method === "GET" && req.url === "/plan") return send(res, 200, plan);
  if (req.method === "POST" && done) {
    const session = plan.sessions.find((s) => s.id === done[1]);
    if (!session) return send(res, 404, { error: `no session ${done[1]}` });
    session.done = true;
    return send(res, 200, session);
  }
  if (req.method === "POST" && req.url === "/sessions") {
    const body = JSON.parse(text || "{}");
    const problem = invalid(body);
    if (problem) return send(res, 422, { error: problem });
    const session = { id: `s${plan.sessions.length + 1}`, course: body.course, date: body.date, minutes: body.minutes, done: false };
    plan.sessions.push(session);
    return send(res, 201, session);
  }
  send(res, 404, { error: "not found" });
}).listen(8008, () => console.log("listening on 8008"));
