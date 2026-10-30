---
title: The interface, and the web's half
version: 1
---

**Write the interface first, because it is the contract the other three keep.** It is what the
planner's code is typed against, what the generated documentation describes, and what the Kotlin and
Swift sides have to answer. Three methods, each returning a `Promise`, since every call across the
bridge is asynchronous:

```typescript
// src/definitions.ts: what the plugin promises, the same on every platform.
export interface KeepAwakePlugin {
  /** Keep the screen on, until allowSleep() or until the app leaves the screen. */
  keepAwake(): Promise<void>;
  /** Let the screen turn off again on the system's usual timer. */
  allowSleep(): Promise<void>;
  /** Whether this platform can keep the screen on at all. */
  isSupported(): Promise<{ supported: boolean }>;
}
```

**`isSupported` is there because not every platform can do it**, and the app should be able to ask
before it offers a button that will fail. The comments are not decoration: the generator's build step
turns them into the plugin's README, as the end of this section shows.

## The web implementation

In the browser, keeping the screen on is the Screen Wake Lock API. `navigator.wakeLock.request
("screen")` returns a sentinel, an object that holds the lock until it is released:

```typescript
// src/web.ts: the browser's half, on the Screen Wake Lock API.
import { WebPlugin } from '@capacitor/core';

import type { KeepAwakePlugin } from './definitions';

export class KeepAwakeWeb extends WebPlugin implements KeepAwakePlugin {
  private lock: WakeLockSentinel | null = null;

  async keepAwake(): Promise<void> {
    if (!('wakeLock' in navigator)) {
      throw this.unavailable('This browser cannot keep the screen on.');
    }
    this.lock = await navigator.wakeLock.request('screen');
  }

  async allowSleep(): Promise<void> {
    await this.lock?.release();
    this.lock = null;
  }

  async isSupported(): Promise<{ supported: boolean }> {
    return { supported: 'wakeLock' in navigator };
  }
}
```

- **`WebPlugin`** is Capacitor's base class for the web side. `this.unavailable(…)` makes the error
  Capacitor uses for "this platform cannot", with the code `UNAVAILABLE`, which the planner can tell
  apart from a refusal.
- **The browser may refuse.** `request()` rejects when the page is not visible, or when the browser
  does not allow it, and that rejection reaches the planner as an error, like a refused permission in
  lesson 4.
- **The lock ends on its own when the page is hidden**, so leaving the tab gives the screen back to the
  system. The native sides behave the same way when the app leaves the screen, which is why the
  interface's comment says so.

Build it. `npm run build` is the plugin's own: it cleans `dist/`, generates the documentation, checks
the types and bundles the result with Rollup. Its report goes to `/dev/null` here for the same reason
as the generator's, Rollup's line comes through, and `ls` shows what it wrote:

```
ana@dev:~/keep-awake$ npm run build > /dev/null

dist/esm/index.js → dist/plugin.js, dist/plugin.cjs.js...
created dist/plugin.js, dist/plugin.cjs.js in 58ms
ana@dev:~/keep-awake$ ls dist dist/esm
dist:
docs.json
esm
plugin.cjs.js
plugin.cjs.js.map
plugin.js
plugin.js.map

dist/esm:
definitions.d.ts
definitions.js
definitions.js.map
index.d.ts
index.js
index.js.map
web.d.ts
web.js
web.js.map
```

The documentation it generated, from the comments in `definitions.ts`:

```
ana@dev:~/keep-awake$ grep -E '^### |^(Keep|Let|Whether) ' README.md
Keep the screen on while a study session runs
### keepAwake()
Keep the screen on, until allowSleep() or until the app leaves the screen.
### allowSleep()
Let the screen turn off again on the system's usual timer.
### isSupported()
Whether this platform can keep the screen on at all.
```

Commit the plugin, so the planner installs a version of it that git can name:

```
ana@dev:~/keep-awake$ git add -A
ana@dev:~/keep-awake$ git commit -q -m "Keep the screen on, on three platforms"
ana@dev:~/keep-awake$ git log --oneline
9d831d6 Keep the screen on, on three platforms
4bfe8c8 Initial commit
```
