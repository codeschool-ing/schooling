---
title: What does not belong there
version: 1
---

**Three kinds of data end up in key-value storage and do not belong: lists that grow, secrets, and
anything large.** Each one works in development and fails in the field, which is why each one keeps
being shipped.

## A list that grows

The planner's sessions would fit in one preference: turn the array into a string, save it under
`sessions`, done. The program below does exactly that, adding a thousand sessions one at a time the
way a person would over a year or two. Save it as `grow.ts` in `~/planner/prefs`:

```typescript
// grow.ts: keep every session in one preference, add 1,000 one at a time, and count the bytes.
import { load, save } from "./kv.ts";

const path = "grow.json";
save(path, { sessions: "[]" });
let written = 0;
for (let n = 1; n <= 1000; n++) {
  const prefs = load(path); // the whole file is read...
  const sessions = JSON.parse(prefs.sessions as string);
  sessions.push({ id: `s${n}`, course: "statistics", date: "2026-10-20", minutes: 45, done: false });
  prefs.sessions = JSON.stringify(sessions);
  const size = save(path, prefs); // ...and the whole file is written, for one new session
  written += size;
  if ([1, 10, 100, 1000].includes(n)) {
    console.log(`${String(n).padStart(4)} sessions: file ${(size / 1024).toFixed(1)} KB, written so far ${(written / 1024 / 1024).toFixed(2)} MB`);
  }
}
```

```
ana@dev:~/planner/prefs$ node grow.ts
   1 sessions: file 0.1 KB, written so far 0.00 MB
  10 sessions: file 1.0 KB, written so far 0.01 MB
 100 sessions: file 9.5 KB, written so far 0.47 MB
1000 sessions: file 95.6 KB, written so far 46.70 MB
```

**The file holds 95.6 KB, and getting it there wrote 46.70 MB.** Each new session rewrote every
session before it, so the cost of one tap grows with the history, and the total grows with its
square. The thousandth tap also reads and parses the whole file at launch, before the first screen,
because a key-value store loads everything. A database writes one row for one session and reads
only the rows a screen asks for, which is lesson 3.

## A secret

A key-value file is a plain file in the sandbox. It is in the backup lesson 1 measured, it is
readable on a rooted or jailbroken phone, and on a development build anybody with the tools can
download it. An access token, a password or an encryption key does not go there. Android's
Keystore and iOS's Keychain exist for them, and lesson 19 uses both; `expo-secure-store` reaches
the same two from React Native.

## Something large

A cover picture encoded as a string, a cached API response, a draft with an attachment. MMKV and
`UserDefaults` both hold their whole contents in memory, and Apple's documentation for
`UserDefaults` says it is meant for small values. Large data goes in a file in the right folder of
the sandbox, with its name in the database, which is lesson 18.

## What remains

| belongs in key-value storage | goes elsewhere |
|---|---|
| theme, language, week start | sessions and courses: the database |
| whether onboarding was shown | tokens and keys: Keystore or Keychain |
| the last course opened | pictures and files: the sandbox, by folder |
| a feature flag the server sent | anything that grows with use |

A good test is the count: **if the number of keys depends on how much the person has used the app,
it is not a setting.**
