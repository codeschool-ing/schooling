---
title: Feature flags, rollout and the kill switch
version: 1
---

**A feature flag is a remote configuration value that decides whether a feature is shown, for which
installations.** It separates two moments that a release ties together: **shipping** the code, which
is lesson 8's staged rollout and takes days, and **turning it on**, which a flag does in minutes and
can undo in minutes.

## A share of installs, chosen stably

The planner's new statistics screen is on for 20% of installs. Which 20% is decided by the same idea
as lesson 8's buckets: a hash of the flag's name and the installation's identifier, taken modulo 100,
compared with the rollout. Hashing the flag's name too means that the 20% who see statistics are not
always the same 20% who see every other new feature.

`flagOn` in `client.ts` is exactly that. Here it is asked about 1000 installations, then about two in
particular, then the kill switch is set in `config.json` and the same installation is asked again.
This small program uses it; save it as `rollout-share.ts`:

```typescript
// rollout-share.ts: how many of 1000 installs the statistics flag reaches, by the client's own rule
import { readFileSync } from "node:fs";
import { flagOn } from "./client.ts";

const config = JSON.parse(readFileSync("config.json", "utf8"));
const on = Array.from({ length: 1000 }, (_, i) => `i${i}`).filter((id) => flagOn(config, "statistics", id)).length;
console.log(`statistics on for ${on} of 1000 installs`);
```

```
ana@dev:~/planner$ node rollout-share.ts
statistics on for 199 of 1000 installs
ana@dev:~/planner$ node client.ts 1.6.0 i009; node client.ts 1.6.0 i042
1.6.0 (config from server): up to date; statistics on for i009
1.6.0 (config from server): up to date; statistics off for i042
ana@dev:~/planner$ sed -i 's/"killed": false/"killed": true/' config.json && node client.ts 1.6.0 i009
1.6.0 (config from server): up to date; statistics off for i009
```

## Reading it

**199 of 1000 is the 20% asked for**, give or take the luck of the hash. Installation `i009` falls in
it and `i042` does not, and that will be true on every launch, which is what keeps a person from seeing
a screen appear and vanish. **The kill switch turned `i009` off with a one-word edit on the server**,
and the next launch of every installation reads it: that is the instant undo lesson 8 said did not
exist, available only for what was behind a flag before it shipped.

## Flags and the stores

Lesson 6 warned about a feature switched off for the reviewer and on for everybody else. A flag
rolling out a **reviewed** feature is ordinary; a flag hiding a feature from review, or changing what
the app is after approval, breaks both stores' rules. **The build sent for review should be able to
show every feature its flags can turn on**, with the review notes saying how.
