---
title: What the server keeps, and for how long
version: 1
---

**For each key the server stores the answer it gave, a fingerprint of the request it answered, and
when; and it decides three cases from them.** The key alone is not enough, because the interesting
failures are the ones where a key comes back in a shape the server did not expect.

| the key arrives... | the server answers | why |
|---|---|---|
| for the first time | does the work, saves the answer | an ordinary request |
| again, same body | the saved answer, without doing the work | a retry |
| again, different body | 422, and does nothing | the client reused a key, which is a bug |
| again, while the first is still running | 409, and does nothing | two tries racing |
| from another user | as if new | keys are scoped to who sent them |
| after 24 hours | as if new | the server forgot it |

Those are the rules in `server.ts`, and in Stripe's API, and in the IETF draft. The fingerprint is
a SHA-256 of the body. The scope is the `x-user` header, which stands in for the signed-in account
that lesson 20 is about. The expiry is the constant `DAY`.

To send one purchase by hand, with a key and a user you choose, save this as `send.ts`:

```typescript
// send.ts: one purchase by hand: node send.ts <user> <key> <course> <cents>
const [user, key, course, cents] = process.argv.slice(2);
const res = await fetch("http://127.0.0.1:8010/purchases", {
  method: "POST",
  headers: { "content-type": "application/json", "x-user": user, "idempotency-key": key },
  body: JSON.stringify({ course, cents: Number(cents) }),
});
const replayed = res.headers.get("idempotent-replayed") ? " replayed" : "";
console.log(`${res.status}${replayed} ${JSON.stringify(await res.json())}`);
```

Start the server as `node server.ts ok ok ok ok slow`, so that the fifth purchase it receives takes a
second to answer. Send the same key and body twice, then the same key with another course, then the
same key from another user:

```
ana@dev:~/planner/idempotency$ node send.ts ana k-1 statistics 4900
201 {"id":"p1","user":"ana","course":"statistics","cents":4900}
ana@dev:~/planner/idempotency$ node send.ts ana k-1 statistics 4900
201 replayed {"id":"p1","user":"ana","course":"statistics","cents":4900}
ana@dev:~/planner/idempotency$ node send.ts ana k-1 guitar 3900
422 {"error":"this key was used with a different body"}
ana@dev:~/planner/idempotency$ node send.ts bia k-1 statistics 4900
201 {"id":"p2","user":"bia","course":"statistics","cents":4900}
```

The second call was a replay: the same `p1`, and nothing charged. The third reused `k-1` for a
guitar course and was refused, because answering it with the saved Statistics purchase would tell
the client a guitar course had been bought. The fourth came from `bia`, whose `k-1` is a different
key from `ana`'s, and charged her.

Now two tries of one operation at the same moment, which is a drain started twice:

```
ana@dev:~/planner/idempotency$ node send.ts ana k-2 guitar 3900 & node send.ts ana k-2 guitar 3900; wait
409 {"error":"a request with this key is still running"}
201 {"id":"p3","user":"ana","course":"guitar","cents":3900}
```

The second request arrived while the first was charging, found the key `in progress`, and got a 409
straight away; the first finished a second later with a 201. **The 409 is worth retrying**, unlike
lesson 9's other 4xx answers: a moment later, the key holds a finished answer and the retry receives
it.

## What the window costs

Twenty-four hours is the time a phone has to come back with its retry. A phone offline for two days
retrying a purchase arrives after the server has forgotten the key, and is charged again. Stripe
removes keys after at least 24 hours; a planner's server can keep them longer, because an entry is a
few hundred bytes, and **the window should be longer than the longest time an outbox may hold an
operation**. Lesson 12 is the other side of that sentence: what the device does when it has been
away longer than the server remembers.

`answers` in this server is a `Map` in memory, so a restart forgets every key. A real one keeps them
in the same database as the purchases, written in the same transaction as the charge, for the reason
lesson 8 wrote the outbox row with the change.
