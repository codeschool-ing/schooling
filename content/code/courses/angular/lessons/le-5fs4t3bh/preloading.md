---
title: Preloading, lazy without the wait
version: 1
---

**A lazy chunk is fetched when it is needed, so the first click on a course waits for a download.**
On a fast network that is nothing; on a train it is the moment the application seems to hang.
**Preloading** fetches lazy chunks after the application has started, while the person is reading
the first page, so the first page is as quick as before and the click finds the code already there.

`withPreloading(PreloadAllModules)` preloads every lazy route:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import {
  PreloadAllModules,
  provideRouter,
  withComponentInputBinding,
  withPreloading,
  withRouterConfig,
} from '@angular/router';

import { routes } from './app.routes';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      withComponentInputBinding(),
      withRouterConfig({ paramsInheritanceStrategy: 'always' }),
      withPreloading(PreloadAllModules),
    ),
    provideHttpClient(withInterceptors([requestedBy])),
  ]
};
```

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text h2
[vite] connecting...
[vite] connected.
Angular is running in development mode.
scripts: /main.js /chunk-KGABQYFU.js /chunk-5ODBP7SE.js
This week
```

The week, and no click: the course area's chunk came anyway, after the page was drawn.

`PreloadAllModules` is the simplest strategy, and right for an application this size. An application
with fifty lazy areas would preload code most people never use, on their data plan; a strategy of its
own, a class with one method, can preload only the routes marked in their `data`, or only on a fast
connection. The default, with no `withPreloading`, is to preload nothing.
