---
title: Tokens: short-lived, kept in the keystore, and wiped at sign-out
version: 1
---

**The one secret a phone must hold is the one that proves who the person is, and it is built to
be worth as little as possible if it leaks.** A password is not kept at all: it is typed once,
sent once, and exchanged for two tokens. Neither of them is the password, and each has a job.

| token | lives | kept | if it leaks |
|---|---|---|---|
| **access token** | minutes; fifteen is a common choice | in memory, or the keystore | it works until it expires, then it is worthless |
| **refresh token** | days or months | in the Android Keystore or the iOS Keychain, never in preferences or a file | the server can revoke it, and rotation shows it was copied |

The access token goes on every request. The refresh token goes to the server only to get a new
access token, and the server **rotates** it: each use returns a fresh refresh token and spends the
old one. A copied refresh token is then useful once at most, and the second use of it, by whoever
is left holding the spent one, is a signal the server can act on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-tokens\" aria-label=\"A timeline from sign-in to sign-out. The password is typed once, at sign-in, and exchanged for an access token and a refresh token. Each access token lives a short time; when one expires the next request is answered 401, and the client spends the refresh token for a new pair, so each refresh token is used once. At sign-out the server revokes the last refresh token and the device wipes the tokens, the database and the cache.\"><defs><marker id=\"l20-tokens-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60 40 L60 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"66\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sign-in</text><text x=\"66\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">password, typed once</text><text x=\"66\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">access token</text><text x=\"66\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">refresh token</text><rect x=\"66\" y=\"110\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"66\" y=\"176\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"236\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">401: expired</text><text x=\"166\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">spent, rotated</text><path d=\"M236 140 L264 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-tokens-ah-paper-dim)\"></path><rect x=\"266\" y=\"110\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"266\" y=\"176\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"436\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">401: expired</text><text x=\"366\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">spent, rotated</text><path d=\"M436 140 L464 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-tokens-ah-paper-dim)\"></path><rect x=\"466\" y=\"110\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"466\" y=\"176\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M40 228 L690 228\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-tokens-ah-paper-dim)\"></path><text x=\"690\" y=\"242\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text><path d=\"M670 60 L670 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"664\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sign-out: revoke, then wipe</text></svg>", "caption": "Neither token is the password. The one that lives long is used once at a time, and sign-out ends both, on the server and on the phone."}
```

## The planner's server, and its client

The server signs a person in, hands out tokens, and answers `/tip` only with a valid access token,
adding the tips service's key on its side. The key comes from the server's environment. Save it in
`~/planner/secrets` as `server.ts`:

```typescript
// server.ts: the planner's own server, on port 8020. It signs people in, hands out short-lived
// access tokens, and is the only place the tips service's key exists.
import { createServer } from "node:http";
import { randomBytes } from "node:crypto";

const TIPS_KEY = process.env.TIPS_API_KEY; // from the server's environment, never from the app
const TTL = Number(process.env.ACCESS_TTL ?? 900); // seconds an access token lives
const access = new Map<string, number>(); // token -> when it expires
const refresh = new Set<string>();
const token = () => randomBytes(24).toString("base64url");

// Stands in for the third-party service the key unlocks: it knows its own key.
const tipsService = (key: string | undefined, course: string) =>
  key === "tips_live_4f9c2a7e1b6d83a0" ? `${course}: review yesterday's mistakes first` : "refused: bad key";

function issue() {
  const a = token(), r = token();
  access.set(a, Date.now() + TTL * 1000);
  refresh.add(r);
  return { access: a, refresh: r, expiresIn: TTL };
}

createServer(async (req, res) => {
  let body = "";
  for await (const chunk of req) body += chunk;
  const url = new URL(req.url!, "http://localhost");
  const send = (status: number, value: unknown) => {
    console.log(`${req.method} ${url.pathname} -> ${status}`);
    res.writeHead(status, { "Content-Type": "application/json" }).end(JSON.stringify(value));
  };
  if (url.pathname === "/token") return send(200, issue()); // a real one checks the password
  if (url.pathname === "/refresh") {
    const old = JSON.parse(body).refresh;
    if (!refresh.delete(old)) return send(401, { error: "refresh token not valid" });
    return send(200, issue()); // rotated: the old refresh token is spent
  }
  if (url.pathname === "/revoke") {
    refresh.delete(JSON.parse(body).refresh);
    return send(200, { revoked: true });
  }
  if (url.pathname === "/tip") {
    const a = (req.headers.authorization ?? "").replace("Bearer ", "");
    if ((access.get(a) ?? 0) < Date.now()) return send(401, { error: "access token expired or unknown" });
    return send(200, { tip: tipsService(TIPS_KEY, url.searchParams.get("course") ?? "") });
  }
  send(404, { error: "no such route" });
}).listen(8020, "127.0.0.1");
```

The client keeps both tokens in `keystore/`, a folder standing in for the platform's Keystore or
Keychain, where the platform listings of lesson 19 would put them. When the server answers 401 it
refreshes once and asks again. Save it as `client.ts`:

```typescript
// client.ts: the planner's side of signing in, asking for a tip, and signing out.
// usage: node client.ts signin | node client.ts tip COURSE | node client.ts signout
import { mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } from "node:fs";

const SERVER = "http://127.0.0.1:8020";
// keystore/ stands in for the Android Keystore or the iOS Keychain.
const keep = (name: string, value: string) => {
  mkdirSync("keystore", { recursive: true });
  writeFileSync(`keystore/${name}`, value);
};
const read = (name: string) => (existsSync(`keystore/${name}`) ? readFileSync(`keystore/${name}`, "utf8") : "");
const post = async (path: string, body: object) =>
  (await fetch(`${SERVER}${path}`, { method: "POST", body: JSON.stringify(body) })).json();
const ask = (course: string) =>
  fetch(`${SERVER}/tip?course=${course}`, { headers: { Authorization: `Bearer ${read("access")}` } });

const [cmd, arg] = process.argv.slice(2);
if (cmd === "signin") {
  const t = await post("/token", { email: "ana@example.org", password: "what the person typed" });
  keep("access", t.access);
  keep("refresh", t.refresh);
  console.log(`signed in: an access token for ${t.expiresIn} s, and a refresh token in the keystore`);
} else if (cmd === "tip") {
  let res = await ask(arg);
  if (res.status === 401 && read("refresh")) {
    console.log("401: the access token has expired, refreshing it");
    const t = await post("/refresh", { refresh: read("refresh") });
    keep("access", t.access);
    keep("refresh", t.refresh);
    res = await ask(arg);
  }
  console.log(`${res.status} ${JSON.stringify(await res.json())}`);
} else if (cmd === "signout") {
  await post("/revoke", { refresh: read("refresh") });
  for (const path of ["keystore", "planner.db", "cache"]) {
    if (existsSync(path)) {
      rmSync(path, { recursive: true });
      console.log(`removed ${path}`);
    }
  }
}
```

For the capture the server is started with an access token that lives **one second**, so that
expiry can be seen without waiting fifteen minutes:
`TIPS_API_KEY=tips_live_4f9c2a7e1b6d83a0 ACCESS_TTL=1 node server.ts`, in a terminal of its own.
Then sign in, ask, wait two seconds, ask again, and sign out:

```
ana@dev:~/planner/secrets$ node client.ts signin
signed in: an access token for 1 s, and a refresh token in the keystore
ana@dev:~/planner/secrets$ node client.ts tip statistics
200 {"tip":"statistics: review yesterday's mistakes first"}
ana@dev:~/planner/secrets$ sleep 2
ana@dev:~/planner/secrets$ node client.ts tip guitar
401: the access token has expired, refreshing it
200 {"tip":"guitar: review yesterday's mistakes first"}
ana@dev:~/planner/secrets$ node client.ts signout
removed keystore
removed planner.db
removed cache
ana@dev:~/planner/secrets$ node client.ts tip statistics
401 {"error":"access token expired or unknown"}
```

And what the server saw:

```
ana@dev:~/planner/secrets$ TIPS_API_KEY=tips_live_4f9c2a7e1b6d83a0 ACCESS_TTL=1 node server.ts
POST /token -> 200
GET /tip -> 200
GET /tip -> 401
POST /refresh -> 200
GET /tip -> 200
POST /revoke -> 200
GET /tip -> 401
```

**The 401 after the pause was the access token expiring, and the client recovered without the
person noticing**: one refresh, one retry, a new pair of tokens. After sign-out the same request was
refused, because the client had nothing left to send and the server had revoked the refresh token.

## Sign-out wipes the device

Signing out is the moment the person hands the phone to somebody else, or sells it. So it removes
**everything the account put there**: the tokens, the database, the cache, the downloaded files of
lesson 18. The client above removes three of them, and printed each. Two rules make it reliable:

- **Revoke on the server first**, so a token copied earlier stops working even if the wipe is
  interrupted.
- **Wipe even when the server cannot be reached.** A person who signs out in a tunnel expects to be
  signed out. The revoke can go in the outbox of lesson 8; the wipe cannot wait for it.

One thing is the person's to decide: sessions still waiting in the outbox. Wiping them loses work;
keeping them leaves one person's data for the next. The planner asks, saying how many there are,
before the wipe.
