---
title: What a worker hides from your tools
version: 1
---

**A page controlled by a worker cannot see the network any more.** Every request it makes is answered by the
worker, and whether the worker answered from its cache or went to the server is the worker's business. Lesson
9's `revisit.ts`, run on a page the worker controls by its second visit, cannot tell what happened:

```
ana@dev:~/planner$ node tools/revisit.ts http://localhost:3000/courses/git
/courses/git                   undefined, downloaded again
/fonts/plex-400.woff2          undefined, downloaded again
/fonts/plex-700.woff2          undefined, downloaded again
/assets/index-DKDcq93q.js      undefined, downloaded again
/assets/planner-BNdUlffC.js    undefined, downloaded again
/covers/git-800.avif           undefined, downloaded again
```

**`undefined`, and the word *downloaded*, are the tool falling through to its last case.** It was written for
a page with no worker: no status crossed the page's part of the network, because the worker answered, and the
tool has no line for that. The worker's own requests are in a list of their own, the worker's, which the
developer tools show under the worker in the **Application** panel, along with its caches and their contents.

## Three consequences

- **Measure with the worker on purpose.** A lab measurement in a fresh browser, as every tool in this course
  makes, never has a worker installed, so it measures a first visit. A repeat visit with a worker needs a test
  that installs it first, as `offline.ts` does.
- **A bug can live in the worker for a long time.** A worker that serves a wrong copy keeps serving it, from
  every visitor's own cache, until a new version replaces it. Lesson 9's rule holds here too: `/sw.js` itself
  is sent with `no-cache`, so the browser's daily check sees a fix the day it is deployed.
- **There is a way out.** A server can answer any page with `Clear-Site-Data: "storage"` to have the browser
  drop a site's caches and service workers, and a page can call `unregister()` on its registration. A site that
  ships a worker should know which of the two it will use before it needs one.
