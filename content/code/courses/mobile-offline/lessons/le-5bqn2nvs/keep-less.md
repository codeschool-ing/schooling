---
title: Keep less: the data the planner does not need
version: 1
---

**The cheapest data to protect is data that was never collected.** Every field the planner keeps,
sends or logs is one more thing to encrypt, to declare in the stores (the next section), to export
and erase when the person asks, and to explain after a breach. The question for each one is not
"could this be useful" but "what breaks without it".

Asked of the planner, it gives short answers:

| the planner keeps | needed? |
|---|---|
| courses, sessions, dates, minutes, done | yes: it is the app |
| an account id | yes: it is what the server joins on |
| the e-mail address | on the server, to sign in; on the device, not after sign-in |
| the person's location when they add a session | no: nothing in the planner uses it |
| the contacts, to suggest study partners | no, and it would be a feature with its own consent |
| a session's free-text notes in a crash report | no, and the next part of this section is that mistake |

## The log line that leaked an address

Logs are where data minimisation fails quietly, because nobody reviews a log line as data. A sync
fails, a developer wants to know whose, and writes the most identifying thing to hand. The line
goes to a crash reporter, a third-party service, with every report. Save this as `log.ts`:

```typescript
// log.ts: the line the planner writes when a sync fails, as a crash reporter would send it.
import { appendFileSync } from "node:fs";

const account = { id: "acc-0193", email: "ana@example.org", name: "Ana Lima" };
const session = { id: "s5", course: "statistics", notes: "ask about the exam on Friday" };

appendFileSync("app.log",
  `sync failed for ${account.email} (${account.name}): session ${JSON.stringify(session)}\n`);
```

Run it, then look for anything shaped like an address in the log:

```
ana@dev:~/planner/secrets$ node log.ts
ana@dev:~/planner/secrets$ grep -E -o '[a-z.]+@[a-z.]+' app.log
ana@example.org
ana@dev:~/planner/secrets$ cat app.log
sync failed for ana@example.org (Ana Lima): session {"id":"s5","course":"statistics","notes":"ask about the exam on Friday"}
```

**One sync failure, and the report carried a name, an e-mail address and a note about an exam.**
None of it helps fix a sync: the id of the account and of the session say which rows to look at,
and the person's data is already on the server for whoever is allowed to look. Here is the line
written that way, the same file with its last line changed:

```typescript
// log.ts: the line the planner writes when a sync fails, as a crash reporter would send it.
import { appendFileSync } from "node:fs";

const account = { id: "acc-0193", email: "ana@example.org", name: "Ana Lima" };
const session = { id: "s5", course: "statistics", notes: "ask about the exam on Friday" };

// An id says which row to look at. The address, the name and the notes are not needed to fix a sync.
appendFileSync("app.log", `sync failed for account ${account.id}: session ${session.id}\n`);
```

```
ana@dev:~/planner/secrets$ node log.ts
ana@dev:~/planner/secrets$ grep -E -c '[a-z.]+@[a-z.]+' app.log
0
ana@dev:~/planner/secrets$ cat app.log
sync failed for account acc-0193: session s5
```

**The same `grep`, run as a check before every release, catches the next one.** A pattern for an
address, a phone number or a token's shape is a few characters, and it runs over the logs a test
suite produced. It cannot prove a log is clean; it reliably finds the mistake this section made.
