---
title: Catching what escapes
version: 1
---

**Two events on `window` see what no `catch` did: `error`, for an exception that escaped, and
`unhandledrejection`, for a promise that was rejected with nothing waiting for the result.** A page that
listens to both, and reports from its own `catch`es as well, has seen every error it can.

The planner's monitor is one file:

```typescript
// src/monitor.ts
const url = import.meta.env.VITE_ERRORS_URL;
const release = import.meta.env.VITE_RELEASE ?? "dev";

export function report(error: unknown, source: string): void {
  const e = error instanceof Error ? error : new Error(String(error));
  console.error(source, e);
  if (!url) return;
  const body = { message: e.message, stack: e.stack, source, release, path: location.pathname };
  navigator.sendBeacon(url, JSON.stringify(body));
}

export function watchErrors(): void {
  window.addEventListener("error", (event) => report(event.error ?? event.message, "error"));
  window.addEventListener("unhandledrejection", (event) => report(event.reason, "unhandledrejection"));
}
```

- **`report`** takes anything that was thrown. JavaScript can throw a string or a number as easily as an
  `Error`, and only an `Error` has a stack, so anything else is wrapped in one. It still writes to the
  console, which is where a developer with the page open looks first.
- **`source`** says which part of the planner reported it: `saveDone`, `load`, `Planner`, or one of the two
  listeners.
- **`navigator.sendBeacon`** sends a small `POST` that the browser finishes even if the page is closing,
  which is exactly when some errors happen. It does not wait for an answer, and returns `false` if the
  browser refused to queue it; a report that cannot be sent is not reported again, because the alternative
  is a loop.
- **`event.error ?? event.message`**: an `error` event carries the thrown value in `error`. For a script
  from another origin loaded without `crossorigin`, the browser hides it and sends only the message
  *Script error.*, so third-party scripts that should be monitored are loaded with
  `<script crossorigin="anonymous">` and served with a CORS header.
- **No URL, no report.** The static build has no collector to send to, so it only writes to the console,
  as before.

## The two new variables

Lesson 2 said lesson 11 would add the name of a release. It adds the collector's address as well, and
both go in the types first:

```typescript
// src/vite-env.d.ts
interface ViteTypeOptions {
  strictImportMetaEnv: unknown;
}

interface ImportMetaEnv {
  readonly VITE_TITLE?: string;
  readonly VITE_GRAPHQL_URL?: string;
  readonly VITE_ERRORS_URL?: string;
  readonly VITE_RELEASE?: string;
}
```

## The planner, reporting

Four lines change in `main.ts`: the import, a call to `watchErrors()` before anything else runs, and the
two `console.error`s, which become reports. Three `sed`s make them, and `grep` shows the result:

```
ana@dev:~/planner$ sed -i 's#^import { saveDone, watch } from "./api";#&\nimport { report, watchErrors } from "./monitor";#' src/main.ts
ana@dev:~/planner$ sed -i 's#^const base = import.meta.env.BASE_URL;#watchErrors();\n\n&#' src/main.ts
ana@dev:~/planner$ sed -i 's#console.error("Could not save", error)#report(error, "saveDone")#; s#console.error("Could not load", error)#report(error, "load")#' src/main.ts
ana@dev:~/planner$ grep -n 'report\|watchErrors' src/main.ts
4:import { report, watchErrors } from "./monitor";
8:watchErrors();
37:        saveDone(id).catch((error) => report(error, "saveDone"));
56:}).catch((error) => report(error, "load"));
```

`apollo.ts` reports a failed query the same way, with the operation's name as the source, which is what
lesson 9 meant by an error report carrying the operation:

```
ana@dev:~/planner$ sed -i 's#^import type { Planner } from "./api";#&\nimport { report } from "./monitor";#' src/apollo.ts
ana@dev:~/planner$ sed -i 's#console.error("Could not load", result.error)#report(result.error, "Planner")#' src/apollo.ts
ana@dev:~/planner$ grep -n 'report' src/apollo.ts
4:import { report } from "./monitor";
28:    if (result.error) report(result.error, "Planner");
ana@dev:~/planner$ npx tsc && echo types ok
types ok
```

`watchErrors()` runs at the top of `main.ts` so that the listeners are in place before the first line that
could fail. An error thrown before it, in a module `main.ts` imports, is still missed; a page that must
see those too puts its listeners in a small inline `<script>` in `index.html`, ahead of everything else.
