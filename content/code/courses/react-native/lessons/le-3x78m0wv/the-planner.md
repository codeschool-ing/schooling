---
title: The planner, as an Expo project
version: 1
---

**Every lesson from here on works on one app, the study planner.** You list your courses, open one,
add study sessions with a date and a length, mark them done, and see how many minutes this week
holds. It is the same planner the `frontend` track builds as a web page, with the same data and the
same rules, so its screens can be compared with the Android and iOS versions that `android-apps`
and `ios-apps` build. This lesson creates the project and gives it its rules and its data; lesson 4
gives it real screens.

## Creating it

From Expo's TypeScript template, at the versions this course was recorded with, as in lesson 1, and
without installing yet:

```
ana@dev:~$ npx create-expo-app@5.0.0 planner --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1
ana@dev:~$ cd planner
ana@dev:~/planner$ ls
AGENTS.md
App.tsx
LICENSE
app.json
assets
index.ts
package.json
tsconfig.json
```

## Every version written exactly

The template writes its versions with a `~`, which means *this version or a later patch*. A project
that installs differently next month is a project whose transcripts stop matching, so the first
command pins the four the template brought, and the next two add what this lesson needs, also
pinned:

```
ana@dev:~/planner$ npm install -E expo@58.0.21 expo-status-bar@58.0.4 react@19.3.0 react-native@0.88.1

added 460 packages, and audited 461 packages in 32s

8 vulnerabilities (5 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npm install -E react-dom@19.3.0 react-native-web@0.21.4 @expo/metro-runtime@58.0.15 expo-dev-client@58.0.17

added 32 packages, removed 2 packages, and audited 491 packages in 6s

8 vulnerabilities (5 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npm install -E -D jest@30.5.2 jest-expo@58.0.13 @testing-library/react-native@14.1.0 @types/jest@30.0.0 playwright@1.63.0 typescript@6.0.3 @types/react@19.3.0
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated whatwg-encoding@3.1.1: Use @exodus/bytes instead for a more spec-conformant and faster implementation
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@7.2.3: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

added 575 packages, and audited 1066 packages in 26s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

**`-E` writes exact versions**, and `package-lock.json`, which npm writes beside `package.json`,
records every package underneath them. Commit both; never commit `node_modules`. What each addition
is for:

| package | why |
|---|---|
| `react-dom`, `react-native-web`, `@expo/metro-runtime` | run the same app in a browser, with HTML standing in for the native views |
| `expo-dev-client` | turn the Android build at the end of this lesson into a development build |
| `jest`, `jest-expo`, `@testing-library/react-native`, `@types/jest` | render components and press their buttons in tests, with no phone |
| `playwright` | drive a real browser from a program, for the web build |

The versions of the Expo libraries are the ones `npx expo install` chooses for SDK 58. If you add a
library of your own later, ask `npx expo install` first, read the version it picks, and pin that one.

**Each install ends with a count of advisories**, fifteen by the last one, in packages that Expo's
command-line tools and Jest depend on, on the day this was recorded. `npm audit` names each one, and
says what its forced fix would do:

```
ana@dev:~/planner$ npm audit | grep "Will install" | sort -u
Will install expo@51.0.39, which is a breaking change
```

**That is why you do not run `npm audit fix --force` here.** To silence a warning in a build tool, it
would move `expo` back to SDK 51, and every version that belongs to it, which is a different project
from the one this course writes. The advisories are about tools that run on your computer while you
develop, not code that ships in the app. Read them, and let the next Expo release bring the fixes.

## The rules and the data

The planner keeps its rules apart from its screens, in `src/planner.ts`. It adds a session, marks one
done, and totals a week, and it touches no screen at all, which is what lets lesson 4 use it unchanged
and what lets a test check it without one. Save this as `src/planner.ts`:

```typescript
// src/planner.ts: the study planner's rules, with no screen in them.
export type Course = { id: string; name: string };
export type Session = { id: string; course: string; date: string; minutes: number; done: boolean };
export type Plan = { courses: Course[]; sessions: Session[] };

export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {
  if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
  if (!Number.isInteger(minutes) || minutes <= 0) throw new Error(`not a duration: ${minutes}`);
  const id = `s${plan.sessions.length + 1}`;
  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };
}

export function markDone(plan: Plan, id: string): Plan {
  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function mondayOf(date: string): string {
  const d = new Date(`${date}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d.toISOString().slice(0, 10);
}

// Minutes planned in the week that starts on `monday`, and how many are done.
export function weekTotal(plan: Plan, monday: string): { planned: number; done: number } {
  const end = new Date(`${monday}T12:00:00Z`);
  end.setUTCDate(end.getUTCDate() + 7);
  const last = end.toISOString().slice(0, 10);
  const week = plan.sessions.filter((s) => s.date >= monday && s.date < last);
  return {
    planned: week.reduce((n, s) => n + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((n, s) => n + s.minutes, 0),
  };
}
```

A course is joined to its sessions by its `id`, never by its name, so renaming *Spanish A2* loses
nothing. A function never changes the plan it was given: it returns a new one, which is exactly what
React wants of state, as lesson 9 explains. The data is a small JSON file. Save it as
`src/courses.json`:

```json
{
  "courses": [
    { "id": "spanish", "name": "Spanish A2" },
    { "id": "statistics", "name": "Statistics" },
    { "id": "guitar", "name": "Guitar" }
  ],
  "sessions": [
    { "id": "s1", "course": "spanish", "date": "2026-10-19", "minutes": 30, "done": true },
    { "id": "s2", "course": "statistics", "date": "2026-10-20", "minutes": 45, "done": true },
    { "id": "s3", "course": "guitar", "date": "2026-10-21", "minutes": 20, "done": false },
    { "id": "s4", "course": "spanish", "date": "2026-10-22", "minutes": 30, "done": false },
    { "id": "s5", "course": "statistics", "date": "2026-10-26", "minutes": 60, "done": false },
    { "id": "s6", "course": "guitar", "date": "2026-10-28", "minutes": 20, "done": false }
  ]
}
```

**This course's week is the week of Monday 19 October 2026**, so that every transcript shows the same
numbers whatever day you read it. The browser build reads the date from the address; everywhere
else, the real date counts. Save this as `src/today.ts`:

```typescript
// src/today.ts: the date the planner treats as today, as YYYY-MM-DD.
// In a browser, ?today= in the address overrides the clock, so a lesson can pin the week.
export function today(): string {
  const pinned = typeof location === "undefined" ? null : new URLSearchParams(location.search).get("today");
  return pinned ?? new Date().toISOString().slice(0, 10);
}
```

## A first screen

The template's `App.tsx` says *Open up App.tsx*. Replace it with a screen that uses the rules: a
heading, the week's total, and the course names. Lesson 4 explains every element in it; for now it is
here so there is something to run:

```tsx
// App.tsx: the planner's first screen, before lesson 4 gives it components of its own.
import { StatusBar } from "expo-status-bar";
import { Text, View } from "react-native";
import data from "./src/courses.json";
import { mondayOf, weekTotal, type Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  const total = weekTotal(plan, mondayOf(today()));
  return (
    <View style={{ flex: 1, padding: 24, paddingTop: 64 }}>
      <Text role="heading">Study planner</Text>
      <Text>
        This week: {total.done} of {total.planned} minutes done
      </Text>
      {plan.courses.map((c) => (
        <Text key={c.id}>{c.name}</Text>
      ))}
      <StatusBar style="auto" />
    </View>
  );
}
```

TypeScript checks the whole project without writing anything, and an empty answer is a pass:

```
ana@dev:~/planner$ npx tsc --noEmit
```
