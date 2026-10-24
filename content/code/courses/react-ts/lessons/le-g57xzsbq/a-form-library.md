---
title: A form library, and an install that refuses
version: 1
---

**React Hook Form registers inputs, collects their values on submit and keeps the errors, without
re-rendering on every keystroke.** It is one of several form libraries, and the one this course
uses; with it come Zod, which describes what valid data is, and `@hookform/resolvers`, which connects
the two. Installing them is the first thing in this lesson that does not go to plan:

```
ana@dev:~/planner$ npm view react-hook-form dist-tags.latest
8.0.0-beta.5
ana@dev:~/planner$ npm install react-hook-form@7.91.0 zod@4.6.7 @hookform/resolvers@6.0.0 2>&1 | head -n 14
npm error code ERESOLVE
npm error ERESOLVE unable to resolve dependency tree
npm error
npm error While resolving: planner@0.0.0
npm error Found: effect@3.22.4
npm error node_modules/effect
npm error   peerOptional effect@"^3.6.5" from @typeschema/effect@0.14.0
npm error   node_modules/@typeschema/effect
npm error     peerOptional @typeschema/effect@"0.14.0" from @typeschema/main@0.14.1
npm error     node_modules/@typeschema/main
npm error       peerOptional @typeschema/main@">=0.13.7" from @hookform/resolvers@6.0.0
npm error       node_modules/@hookform/resolvers
npm error         @hookform/resolvers@"6.0.0" from the root project
npm error   peer effect@"^3.6.8" from @effect/schema@0.71.4
ana@dev:~/planner$ npm view @hookform/resolvers@6.0.0 peerDependenciesMeta.effect
{ optional: true }
ana@dev:~/planner$ npm install react-hook-form@7.91.0 zod@4.6.7 @hookform/resolvers@5.9.2

added 5 packages, and audited 35 packages in 2s

12 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm ls react-hook-form zod @hookform/resolvers
planner@0.0.0 /home/ana/planner
├─┬ @hookform/resolvers@5.9.2
│ ├── react-hook-form@7.91.0 deduped
│ └── zod@4.6.7 deduped
├── react-hook-form@7.91.0
└── zod@4.6.7
```

**npm's `latest` tag for React Hook Form points at a beta**, 8.0.0-beta.5, which is why the course
names 7.91.0, the newest stable release, and never `latest`. Then the first install failed. Read an
`ERESOLVE` from the bottom of its tree upward: `@hookform/resolvers` 6.0.0 declares optional peers for
many validation libraries, among them `effect` at version 4, while another optional peer it lists,
through `@typeschema/main`, wants `effect` at version 3. Both cannot be satisfied, and npm 10 refuses
rather than guess. `npm view` confirms the peer is optional: the conflict is in a package this project
does not even use.

Two ways out. `--legacy-peer-deps` tells npm to ignore peer dependencies, which installs and leaves you
to find out later whether anything is broken. **The other is a version that does not have the
conflict**, and 5.9.2, the newest release before 6, supports Zod 4 and React Hook Form 7 and installed
without complaint. Pinning it is a decision with a reason, and the reason is written here; when
version 6 is fixed, the move is one line.

```typescript
import { z } from 'zod'

export const sessionSchema = z.object({
  date: z.iso.date({ error: 'Choose the day of the session.' }),
  minutes: z
    .number({ error: 'Enter how many minutes.' })
    .int('Use whole minutes.')
    .min(5, 'A session is at least 5 minutes.')
    .max(240, 'A session is at most 240 minutes.'),
})

export type SessionInput = z.infer<typeof sessionSchema>
```

**The schema says what a valid session is, once.** `z.iso.date` accepts a `YYYY-MM-DD` string and
nothing else; the minutes must be a number, whole, from 5 to 240. Each rule carries the message to show
when it fails. `z.infer` derives the TypeScript type from the schema, so the form's values and the
rules cannot disagree.
