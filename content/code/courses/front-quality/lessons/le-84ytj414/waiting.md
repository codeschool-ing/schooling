---
title: What arrives later
version: 1
---

**A page that fetches its data draws nothing until the data arrives, so a test of it has to wait,
and `findBy…` is how it waits.** The planner's fetching lives in `main.ts`, at the top level of the
module, where no test can reach it: importing the file would run it. The first step is to move it
into a function a test can call.

Save this as `src/app.ts`:

```typescript
// src/app.ts
import { today, type Plan } from "./planner";
import { render } from "./view";

export async function start(root: HTMLElement, load = () => fetch("/courses.json")): Promise<void> {
  const response = await load();
  if (!response.ok) {
    root.textContent = "Could not load your courses.";
    return;
  }
  let plan: Plan = await response.json();
  const draw = (): void =>
    render(root, plan, today(), location.hash, (next) => {
      plan = next;
      draw();
    });
  window.addEventListener("hashchange", draw);
  draw();
}
```

And `src/main.ts` shrinks to what only a browser does, which is to start it:

```typescript
// src/main.ts
import "./style.css";
import { start } from "./app";

await start(document.querySelector<HTMLElement>("#app")!);
```

**`load` is a parameter with the real `fetch` as its default.** The page passes nothing and fetches
`/courses.json` as before; a test passes a function that answers whatever the test needs, and no
global is replaced. Save this as `src/app.test.ts`:

```typescript
// src/app.test.ts
// @vitest-environment jsdom
import { expect, test } from "vitest";
import { screen } from "@testing-library/dom";
import "@testing-library/jest-dom/vitest";
import { start } from "./app";
import data from "../public/courses.json";

function root(): HTMLElement {
  document.body.innerHTML = '<div id="app"></div>';
  return document.querySelector<HTMLElement>("#app")!;
}

test("the courses appear once the data has arrived", async () => {
  const started = start(root(), async () => Response.json(data));
  expect(screen.queryByRole("heading")).not.toBeInTheDocument();
  expect(await screen.findByRole("heading", { name: "Study planner" })).toBeInTheDocument();
  await started;
});

test("a failed load says so", async () => {
  await start(root(), async () => new Response("", { status: 500 }));
  expect(screen.getByText("Could not load your courses.")).toBeInTheDocument();
});
```

The first test checks the page twice. Straight after `start` is called the data has not arrived,
and `queryByRole` confirms that there is no heading yet; then `findByRole` waits, retrying, until
the heading appears. `Response.json(data)` builds the response a server would send, with the planner's
own data in it. The second test answers with a 500, and the page says so.

```
ana@dev:~/planner$ npx vitest run src/app.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  19:53:26
   Duration  983ms (environment 70%, tests 14%, import 9%, transform 7%, worker 1%)

ana@dev:~/planner$ npx tsc --noEmit
```

`npx tsc --noEmit` printed nothing, so the change type-checks too. The app behaves exactly as
before, and the dev server serves it the same way; what changed is that the one part of it lesson 2's
coverage could not reach is now reachable.

The whole suite, and the commit:

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner


 Test Files  4 passed (4)
      Tests  27 passed (27)
   Start at  19:53:30
   Duration  1.25s (environment 67%, tests 20%, import 9%, transform 4%, worker 1%)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Start the app from a function a test can call"
```

## Waiting, and not sleeping

A test that waits with a fixed pause, half a second and then look, is a test that fails on a slow
machine and wastes time on a fast one. `findBy…` polls the page and returns as soon as the element is
there, and gives up after a second with the same report a `getBy…` gives. **Wait for the thing, never
for the clock.** Lesson 4 meets the same rule in a real browser, where it matters more.
