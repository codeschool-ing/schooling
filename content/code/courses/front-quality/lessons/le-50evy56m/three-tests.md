---
title: Three tests the server fails
version: 1
---

**The server can be tested without a browser at all: start it on a free port inside the test, send it
requests with `fetch`, and read what comes back.** That is why `api.mjs` exports `createApi()` and only
listens on 3000 when it is run directly. Save this as `server/api.test.mjs`:

```javascript
// server/api.test.mjs
import { afterAll, beforeAll, expect, test, vi } from "vitest";
import { createApi } from "./api.mjs";

let server;
let base;

beforeAll(async () => {
  server = createApi();
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});

afterAll(() => {
  server.close();
});

async function signIn() {
  const response = await fetch(`${base}/api/login`, {
    method: "POST",
    body: JSON.stringify({ name: "ana", password: "correct horse battery staple" }),
  });
  return response.headers.get("set-cookie");
}

const cookieOf = (setCookie) => setCookie.split(";")[0];

test("the session cookie is kept from scripts, from plain HTTP and from other hosts", async () => {
  const setCookie = await signIn();
  expect(setCookie).toMatch(/^__Host-sid=/);
  for (const part of ["HttpOnly", "Secure", "SameSite=Lax", "Path=/", "Max-Age=28800"]) {
    expect(setCookie).toContain(part);
  }
});

test("signing out ends the login on the server, not only in the browser", async () => {
  const cookie = cookieOf(await signIn());
  await fetch(`${base}/api/logout`, { method: "POST", headers: { cookie } });
  const response = await fetch(`${base}/api/plan`, { headers: { cookie } });
  expect(response.status).toBe(401);
});

test("a login ends after eight hours, whatever the browser keeps", async () => {
  vi.useFakeTimers({ toFake: ["Date"] });
  try {
    const cookie = cookieOf(await signIn());
    vi.setSystemTime(Date.now() + 8 * 60 * 60 * 1000);
    const response = await fetch(`${base}/api/plan`, { headers: { cookie } });
    expect(response.status).toBe(401);
  } finally {
    vi.useRealTimers();
  }
});
```

`listen(0)` asks the operating system for any free port, so the test never collides with the server you
have running on 3000. The second test is the one that matters most, and its witness is the plainest
there is: **the cookie a person had before they signed out**, sent again. If the server still answers
with the plan, signing out only hid the cookie from the browser that clicked the button, and any copy
of it, in a proxy's log or another device's browser, still works. The third stops the clock with
`toFake: ["Date"]`, so only `Date` is replaced and the network keeps its real timers.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError|Error:|- Expected|\+ Received|- |\+ | Test Files|      Tests)"
 FAIL  server/api.test.mjs > the session cookie is kept from scripts, from plain HTTP and from other hosts
AssertionError: expected 'sid=M5auRETffnbVctH6wJEPVflGClyD1nnMu…' to match /^__Host-sid=/
- Expected:
+ Received:
 FAIL  server/api.test.mjs > signing out ends the login on the server, not only in the browser
AssertionError: expected 200 to be 401 // Object.is equality
- Expected
+ Received
- 401
+ 200
 FAIL  server/api.test.mjs > a login ends after eight hours, whatever the browser keeps
AssertionError: expected 200 to be 401 // Object.is equality
- Expected
+ Received
- 401
+ 200
 Test Files  1 failed (1)
      Tests  3 failed (3)
```

**All three fail, and each says what is wrong.** The cookie is called `sid` and carries neither
`Secure` nor a lifetime. The old cookie still fetched the plan after sign-out: 200 where the test wanted
401. And eight hours later the login was still alive, because the server never wrote down when it
started.
