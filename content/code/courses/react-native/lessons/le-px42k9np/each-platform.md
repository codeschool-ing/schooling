---
title: One test, four platforms
version: 1
---

**A difference you wrote is a difference you should check, on each platform.** `jest-expo` makes that
cheap: besides the preset the planner uses, which runs every test as iOS, it has one per platform, and a
`universal` preset that runs every test once as each of them, iOS, Android, web and Node.js.

## A test that says where it ran

Save this as `__tests__/platform.test.ts`. It imports the card style and the sentence, and prints what
each platform got:

```typescript
// __tests__/platform.test.ts: one test, run once for each platform jest-expo knows.
import { Platform } from "react-native";
import { card } from "../src/card";
import { savedWhere } from "../src/savedWhere";

test("each platform gets its own file and its own shadow", () => {
  const shadow = Object.keys(card).filter((k) => /shadow|elevation/i.test(k));
  console.log(Platform.OS, "|", savedWhere, "|", shadow.join(" "));
  expect(shadow.length).toBeGreaterThan(0);
});
```

The `console.log` is there to show the result on the page; a test of your own would `expect` the values
instead, and this one also checks that every platform got a shadow of some kind.

## Running it four times

`--config` accepts the configuration as JSON on the command line, which runs the universal preset for one
command without changing `package.json`; `platform` picks the file:

```
ana@dev:~/planner$ npx jest --config '{"preset":"jest-expo/universal"}' platform
PASS Android __tests__/platform.test.ts
  ● Console

    console.log
      android | Saved on this Android device | elevation

      at Object.log (__tests__/platform.test.ts:8:11)

PASS iOS __tests__/platform.test.ts
  ● Console

    console.log
      ios | Saved on this iPhone | shadowColor shadowOpacity shadowRadius shadowOffset

      at Object.log (__tests__/platform.test.ts:8:11)

PASS Node __tests__/platform.test.ts
  ● Console

    console.log
      web | Saved in this browser | boxShadow

      at Object.log (__tests__/platform.test.ts:8:11)

PASS Web __tests__/platform.test.ts
  ● Console

    console.log
      web | Saved in this browser | boxShadow

      at Object.log (__tests__/platform.test.ts:8:11)


Test Suites: 4 passed, 4 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        1.008 s
Ran all test suites matching platform in 4 projects.
```

**Four runs of one file**, each with its own `Platform.OS`, its own resolution of `./savedWhere`, and its
own branch of `Platform.select`. Android got `elevation`, iOS the four shadow properties, and the web and
Node.js the `default`, `boxShadow`. That is the same choice Metro made in the bundles two sections ago,
made here by Jest's resolver configured the same way, which is what makes the test worth trusting.

## And the whole suite, as usual

The ordinary run is still the iOS preset, with the setup file now in front of every test:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npm test

> planner@1.0.0 test
> jest

PASS __tests__/App.test.tsx
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/WeekBar.test.tsx
PASS __tests__/platform.test.ts
  ● Console

    console.log
      ios | Saved on this iPhone | shadowColor shadowOpacity shadowRadius shadowOffset

      at Object.log (__tests__/platform.test.ts:8:11)

PASS __tests__/planner.test.ts

Test Suites: 5 passed, 5 total
Tests:       9 passed, 9 total
Snapshots:   0 total
Time:        1.213 s
Ran all test suites.
```

The platform test prints its line here too, as iOS. **The App test is the one the setup file rescued**:
without the stand-in, the real provider renders nothing in Jest while it waits for a measurement that
never comes, and the test finds no heading at all. Remove the line from `package.json` and run `npm
test` to see it fail that way; then put it back.

## What this does not replace

Jest runs your JavaScript with each platform's resolution and constants. It does not run UIKit or
Android's views, so a shadow that is set correctly and still looks wrong is found on a device. *Checking
the card's shadow on a phone and an emulator was not done for this course.* What the four runs prove is
that the code chose what you meant it to choose, on every platform, every time the tests run.
