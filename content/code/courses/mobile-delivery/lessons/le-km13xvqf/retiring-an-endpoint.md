---
title: Retiring an endpoint on purpose
version: 1
---

**An old version is retired by announcing a date, telling the app on every response, raising the
minimum version, and only then removing what it calls.** Skipping a step works for every user except
the ones on that version, and they find out from a screen that no longer loads.

## The order

1. **Decide the date from the count.** The table of the first section says how many installations
   still call the endpoint. Pick a date far enough out that most of them will have updated, and
   write it down.
2. **Say it in every response.** The `Sunset` header, from RFC 8594, carries the date after which the
   endpoint may stop answering, and a `Link` with the relation `sunset` points at a page that
   explains. An app that reads them can warn its user; a developer reading logs sees them without
   being told.
3. **Raise the minimum version before the date.** Lesson 19's minimum is what turns "this will stop
   working" into "update to continue", on a screen the app draws itself. Raising it on the day after
   the sunset is too late for anybody who opens the app on the day.
4. **After the date, answer with something an old app understands.** Not a 404 and not a server
   error. `410 Gone`, with a body saying which version to install, lets even the oldest version that
   checks the status show a sentence instead of a blank list.

Steps 3 and 4 only work for versions that already knew how to read them. **The minimum-version check
and the handling of `410` are the two parts of the contract that can never be removed,** because they
are how every other part is retired. They belong in 1.0.0.

*The `Sunset` header is described from RFC 8594, which the recording machine could not reach; the
server below is real and was run.*

## A server that announces its sunset

Save this in `~/planner` as `sunset-server.ts`. It takes the day as its argument, so you can run it
before and after the date without waiting:

```typescript
// sunset-server.ts: /v1/sessions announces its end, then answers 410 with what to install
import { createServer } from "node:http";

const SUNSET = "2027-03-31";
const today = process.argv[2];
const week = [{ id: "s-101", course: "statistics", minutes: 25, day: "2026-10-12", status: "done" }];

createServer((req, res) => {
  if (req.url !== "/v1/sessions") return res.writeHead(404).end();
  if (today > SUNSET) {
    return res.writeHead(410, { "content-type": "application/json" })
      .end(JSON.stringify({ error: "update required", minimumVersion: "1.5.1" }));
  }
  res.writeHead(200, {
    "content-type": "application/json",
    sunset: new Date(`${SUNSET}T23:59:59Z`).toUTCString(),
    link: '<https://planner.example/v1-sunset>; rel="sunset"',
  }).end(JSON.stringify(week));
}).listen(4320, "127.0.0.1");
```

Start it in a second terminal for a day in October 2026, `node sunset-server.ts 2026-10-30`, and look
at the status line and the two headers. Then stop it, start it again for a day after the sunset,
`node sunset-server.ts 2027-04-01`, and ask again:

```
ana@dev:~/planner$ curl -si http://127.0.0.1:4320/v1/sessions | grep -iE '^(HTTP|sunset|link)'
HTTP/1.1 200 OK
sunset: Wed, 31 Mar 2027 23:59:59 GMT
link: <https://planner.example/v1-sunset>; rel="sunset"
ana@dev:~/planner$ curl -si http://127.0.0.1:4320/v1/sessions | grep -iE '^HTTP'; curl -s http://127.0.0.1:4320/v1/sessions; echo
HTTP/1.1 410 Gone
{"error":"update required","minimumVersion":"1.5.1"}
```

**Before the date, the old endpoint still answers 200 and says when it ends; after it, the answer is
410 with the version to install.** The headers cost nothing to send for months, and they are the one
warning that reaches the people integrating with your API as well as your own app. The body after the
date is what 1.3.1 would show, if 1.3.1 had been written to show it.

## What the stores add

Neither store retires a version for you, and neither lets you stop an installed version from
opening. What they offer is what lessons 9 and 19 used: Google Play's In-App Updates, to ask for an
update in a sheet the app opens, and on both stores a page to link to. Raising the app's minimum OS
stops new installs on old phones, and leaves the installed copies exactly as they are, calling your
API.
