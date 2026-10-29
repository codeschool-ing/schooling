---
title: Hosted services
version: 1
---

**A hosted service is the same chain, run by somebody else: an SDK in the page instead of `monitor.ts`, a
collector that groups, alerts and keeps history, and a place to upload source maps.** **Sentry** is the
most widely used, and is also open source and can be run on your own servers. **Bugsnag**, **Rollbar**,
**Honeybadger** and **GlitchTip**, a smaller open-source service compatible with Sentry's SDK, do the same
job. Datadog and New Relic include it in larger monitoring products.

**Nothing in this section was run for this course**: each service needs an account, and its plans and
screens change on its own schedule. What follows is the shape Sentry's documentation gave in October 2026
for a plain browser app built with Vite.

## The SDK

```typescript
// src/monitor.ts, with Sentry instead of the planner's own report
import * as Sentry from "@sentry/browser";

Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,
  release: import.meta.env.VITE_RELEASE,
  sendDefaultPii: false,
  beforeSend(event) {
    if (event.request?.url) event.request.url = event.request.url.split("?")[0];
    return event;
  },
});

export function report(error: unknown, source: string): void {
  Sentry.captureException(error, { tags: { source } });
}
```

- **The DSN** is the address the SDK sends to. It is not a secret: it is in every copy of the page, and
  anybody can send reports to it, which is why services rate-limit and filter on their side.
- **`release`** is this lesson's release, and it has to match the name the source maps are uploaded
  under.
- **`sendDefaultPii: false`** keeps the SDK from attaching IP addresses, cookies and request headers on
  its own. It is the default, and writing it down says that somebody decided.
- **`beforeSend`** sees every event before it leaves the page and may change or drop it. Here it removes
  the query string from the address, the same rule as the planner's `pathname`.
- The SDK installs its own `error` and `unhandledrejection` listeners, so `watchErrors` is not needed.

## The maps

Sentry's Vite plugin uploads the maps at the end of each build and deletes them from `dist/`, so they
cannot be deployed by mistake:

```typescript
// vite.config.ts, with the upload added
import { sentryVitePlugin } from "@sentry/vite-plugin";

export default defineConfig({
  build: { sourcemap: "hidden" },
  plugins: [
    sentryVitePlugin({
      org: "the-team",
      project: "planner",
      authToken: process.env.SENTRY_AUTH_TOKEN,
      sourcemaps: { filesToDeleteAfterUpload: ["./dist/**/*.map"] },
    }),
  ],
});
```

**The auth token is a secret**, unlike the DSN: it can upload, and on some plans delete, a project's data.
It goes where lesson 2 put secrets, in the pipeline's settings, and never in a file in the repository or a
`VITE_` variable, which would put it in every copy of the page.

## Choosing

The same questions as for a host in lesson 1, and one more. Where are the reports stored, and can the
region be chosen? Can the service be run on your own servers, if the reports must not leave them? What
does it scrub on its own, and what does it need to be told? And for a team in Brazil: does it offer the
terms the LGPD needs for an international transfer?
