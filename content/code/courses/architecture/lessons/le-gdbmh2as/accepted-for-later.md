---
title: Accepted now, answered later
version: 1
---

Some requests take too long to answer while the caller waits: a monthly sales report, a video to
transcode, a large export. Holding an HTTP connection open for minutes invites every timeout between
the client and the server to cut it. The **asynchronous request-reply** pattern splits the request
into two conversations, each of them short.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A sequence between a client and the reports service. The client sends POST /reports and gets 202 Accepted at once, with a Location header. The service works in the background for about three seconds. Meanwhile the client sends GET /reports/1 and gets status running; later another GET returns status done with the result.\"><defs><marker id=\"l5-accepted-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l5-accepted-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"70\" y=\"24\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><rect x=\"500\" y=\"24\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">reports</text><path d=\"M140 56 L140 270\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M570 56 L570 270\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"576\" y=\"84\" width=\"104\" height=\"152\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"628\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">building</text><text x=\"628\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3 s</text><path d=\"M142 76 L566 76\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-accepted-ah-amber)\"></path><text x=\"354\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /reports</text><path d=\"M566 98 L142 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-accepted-ah-phosphor)\"></path><text x=\"354\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">202 Accepted, Location: /reports/1</text><path d=\"M142 150 L566 150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-accepted-ah-amber)\"></path><text x=\"354\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /reports/1</text><path d=\"M566 172 L142 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-accepted-ah-phosphor)\"></path><text x=\"354\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200 {\"status\": \"running\"}</text><path d=\"M142 228 L566 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-accepted-ah-amber)\"></path><text x=\"354\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /reports/1</text><path d=\"M566 250 L142 250\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-accepted-ah-phosphor)\"></path><text x=\"354\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200 {\"status\": \"done\", …}</text></svg>", "caption": "Asynchronous request-reply: accepted at once, worked on in the background, collected later at an address the first answer gave."}
```

1. The client asks for the work. The server accepts it, starts it in the background, and answers at
   once with **`202 Accepted`**, which HTTP defines for exactly this: the request was received and will
   be processed, and it has not been yet. A `Location` header says where the result will be.
2. The client asks that address, now or later, as often as it likes. Each answer says how far the work
   has got, and the last one carries the result.

`report.py` from the start of the lesson is this pattern, and it is already running as the `reports`
service on port 8001. Ask for a report, and then ask for its result twice, once at once and once after
the three seconds the work takes:

```
ana@vm:~/lab/chain$ curl -s -i -X POST localhost:8001/reports
HTTP/1.0 202 Accepted
Server: BaseHTTP/0.6 Python/3.12.15
Date: Sat, 10 Oct 2026 04:59:24 GMT
Location: /reports/1
Content-Length: 13

{"job": "1"}
ana@vm:~/lab/chain$ curl -s localhost:8001/reports/1
{"status": "running"}
ana@vm:~/lab/chain$ sleep 4; curl -s localhost:8001/reports/1
{"status": "done", "orders": 412, "revenue_cents": 1893450}
```

The `POST` came back in no time with `202` and `Location: /reports/1`. The first `GET` found the job
still running; the second, after `sleep 4`, found it done, with the month's 412 orders and their
revenue.

## Polling, and the alternatives to it

Asking again and again is **polling**, and it is simple and works through any proxy. Its costs are a
request every few seconds while nothing has changed, and a result noticed only at the next poll. A
server can help by sending a `Retry-After` header saying how long to wait before asking again. When
polling costs too much, the server can push the result instead: a **callback** to an address the client
gave when it asked, or a message on a queue the client listens to, or a connection held open for
updates, which is lesson 18.

**The job has to outlive the process that started it.** `report.py` keeps its jobs in a dictionary,
which lesson 4 already explained is the wrong place: restart the container and every running job and
every result is gone, and the client polls an address that answers `404`. A real service keeps jobs in
a database, so that any copy can answer the `GET` and a restart loses nothing.

Stop the lesson's services when you are done:

```sh
docker compose down
```
