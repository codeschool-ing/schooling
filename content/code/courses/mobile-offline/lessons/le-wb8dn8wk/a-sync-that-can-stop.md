---
title: A sync that can stop at any step
version: 1
---

**A background sync must be written to be interrupted: it does one step at a time, saves after
each, and reads on the next run where the last one stopped.** The three platform sections ended on
the same requirement in three spellings: a cancelled coroutine, an `expirationHandler`, a task the
system stops. None of them tells the sync in advance how long it has. So the program cannot plan
its work to fit; it can only make every point between two steps a safe place to stop.

This program is that sync, with the system played by two arguments. The first is how many steps
this run is granted; the second, if given, is a step during which the process is killed outright,
as an Android phone or iOS does to an app that overruns. Its outbox of six edits and its pull
cursor live in SQLite, in `background.db`, so they survive from one run to the next exactly as they
would survive from one background launch to the next. The server's side is played by a table in
the same file, `received`, which remembers the idempotency key of every operation it has taken, as
the server of lesson 10 does. Make the folder `~/planner/background` and save this there as
`bg.ts`:

```typescript
// bg.ts: a sync that does what it can in the steps it is given, and resumes where it stopped.
import Database from "better-sqlite3";

const db = new Database("background.db");
db.exec(`
  create table if not exists outbox (seq integer primary key, key text not null, op text not null, sent integer not null default 0);
  create table if not exists state (name text primary key, value integer not null);
  create table if not exists received (key text primary key); -- the server's side, played here
`);
// The first run finds the week's edits waiting, as lesson 8's outbox would hold them.
if (!db.prepare("select 1 from outbox").get()) {
  const add = db.prepare("insert into outbox (key, op) values (?, ?)");
  for (const [key, op] of [["k1", "add session s7"], ["k2", "mark s3 done"], ["k3", "set s5 to 50 minutes"],
    ["k4", "add session s8"], ["k5", "delete session s6"], ["k6", "mark s4 done"]]) add.run(key, op);
}
const serverChanges = ["c1", "c2", "c3", "c4", "c5"]; // what the server has for this device to pull

const steps = Number(process.argv[2] ?? 3); // what the system grants this run
const killAt = Number(process.argv[3] ?? 0); // a step during which the system kills the process
const cursor = () => (db.prepare("select value from state where name = 'cursor'").get() as { value: number } | undefined)?.value ?? 0;

console.log(`run with ${steps} steps` + (killAt ? `, killed during step ${killAt}` : ""));
for (let step = 1; step <= steps; step++) {
  const next = db.prepare("select seq, key, op from outbox where sent = 0 order by seq").get() as
    { seq: number; key: string; op: string } | undefined;
  if (next) {
    const fresh = db.prepare("insert or ignore into received (key) values (?)").run(next.key).changes === 1;
    if (step === killAt) {
      console.log(`  step ${step}: sent ${next.key}, killed before it was marked sent`);
      process.kill(process.pid, "SIGKILL"); // what the system does: no warning, no cleanup
    }
    db.prepare("update outbox set sent = 1 where seq = ?").run(next.seq); // the checkpoint
    console.log(`  step ${step}: sent ${next.key} ${next.op}` + (fresh ? "" : " (the server had it: ignored)"));
    continue;
  }
  const from = cursor();
  if (from >= serverChanges.length) {
    console.log(`  step ${step}: nothing left to do`);
    break;
  }
  const page = serverChanges.slice(from, from + 2);
  db.prepare("insert into state (name, value) values ('cursor', ?) on conflict (name) do update set value = excluded.value")
    .run(from + page.length); // the checkpoint for pulls
  console.log(`  step ${step}: pulled ${page.join(", ")}, cursor ${from} -> ${from + page.length}`);
}
const left = (db.prepare("select count(*) as n from outbox where sent = 0").get() as { n: number }).n;
console.log(`stopped: ${left} to send, pull cursor at ${cursor()}`);
```

There are two checkpoints, and both are marked in comments. After an operation is sent, its row
is marked sent; after a page is pulled, the cursor moves on. In an app the pulled rows and the new
cursor go in one transaction, as lesson 11 writes them, so the page and the cursor can never
disagree.

## Four runs

The first run gets four steps, the second three but is killed during its second step, and the
last two get as many as they want:

```
ana@dev:~/planner/background$ node bg.ts 4
run with 4 steps
  step 1: sent k1 add session s7
  step 2: sent k2 mark s3 done
  step 3: sent k3 set s5 to 50 minutes
  step 4: sent k4 add session s8
stopped: 2 to send, pull cursor at 0
ana@dev:~/planner/background$ node bg.ts 3 2; echo "exit status $?"
run with 3 steps, killed during step 2
  step 1: sent k5 delete session s6
  step 2: sent k6, killed before it was marked sent
bash: line 1: 30438 Killed                  node bg.ts 3 2
exit status 137
ana@dev:~/planner/background$ node bg.ts 10
run with 10 steps
  step 1: sent k6 mark s4 done (the server had it: ignored)
  step 2: pulled c1, c2, cursor 0 -> 2
  step 3: pulled c3, c4, cursor 2 -> 4
  step 4: pulled c5, cursor 4 -> 5
  step 5: nothing left to do
stopped: 0 to send, pull cursor at 5
ana@dev:~/planner/background$ node bg.ts 10
run with 10 steps
  step 1: nothing left to do
stopped: 0 to send, pull cursor at 5
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l16-runs\" aria-label=\"Four runs of the sync, one row each, every box a step. Run 1, four steps: send k1, k2, k3, k4, then time is up. Run 2, three steps: send k5; during the second step k6 reaches the server and the process is killed before the outbox marks it sent. Run 3: send k6 again, which the server ignores, then pull c1 and c2, c3 and c4, c5, and find nothing left. Run 4: nothing left to do, in one step. A checkpoint follows every completed step.\"><text x=\"20\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">run 1</text><rect x=\"110\" y=\"20\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"158.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k1</text><rect x=\"220\" y=\"20\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"268.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k2</text><rect x=\"330\" y=\"20\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"378.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k3</text><rect x=\"440\" y=\"20\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"488.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k4</text><text x=\"554\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">time is up</text><text x=\"20\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">run 2</text><rect x=\"110\" y=\"64\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"158.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k5</text><rect x=\"220\" y=\"64\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"268.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k6</text><text x=\"334\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">killed</text><text x=\"20\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">run 3</text><rect x=\"110\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"158.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">k6, ignored</text><rect x=\"220\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"268.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">c1, c2</text><rect x=\"330\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"378.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">c3, c4</text><rect x=\"440\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"488.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">c5</text><rect x=\"550\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"598.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nothing left</text><text x=\"20\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">run 4</text><rect x=\"110\" y=\"152\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"158.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nothing left</text><text x=\"110\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">every completed step is saved before the next begins</text></svg>", "caption": "Being stopped costs at most one step: the one in flight when the kill came, sent again and ignored by the server's idempotency key."}
```

Read the second and third runs together. **The kill came after `k6` had reached the server and
before the outbox knew**, which is the worst moment there is: the work was done and the record of
it was not. The next run therefore sent `k6` again, and the server, finding the key already
received, ignored it. Without the key, the planner would now hold `s4` marked done twice, or, for
an operation that adds a session, two sessions. The program played the system by sending itself `SIGKILL`, the signal neither Android nor iOS lets an app catch. `137` is the status a shell reports for a process that died of it, under the shell's own `Killed` line with the process ID, which will differ
on your machine. Nothing in the program got a chance to clean up, and nothing needed to.

The pull side never had to be redone at all: each page moved the cursor, and the next run started
from it. And the fourth run found nothing to do and said so in one step, which is the case a
background run meets most often and should spend least on.

## What the program leaves to the platform

- **When to run.** The step budget here is an argument. On a phone it is WorkManager's ten minutes,
  iOS's thirty seconds, or whatever the system allows before it cancels.
- **The network.** Every step here succeeds. A real step fails, and lesson 9's retry and backoff
  decide what happens next, inside the budget.

What it does not leave to anybody is the shape: small steps, a checkpoint after each, idempotent
sends. **With that shape, being stopped costs one repeated step; without it, being stopped costs
the run.**
