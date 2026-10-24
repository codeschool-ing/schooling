---
title: What a boundary cannot catch
version: 1
---

**A boundary catches what goes wrong while React is drawing: rendering, and the effects that run after
it.** An error that happens outside that work does not pass through React on its way up, so no
boundary sees it:

| where the error is thrown | caught by a boundary? | why |
|---|---|---|
| a component's body, while it renders | yes | React called the function, and catches what it throws |
| a `useEffect` or `useLayoutEffect` | yes | React runs effects as part of committing a render |
| an event handler, such as `onClick` | no | the browser calls the handler, after the render is long finished |
| a `setTimeout` callback or a promise's `.then` | no | they run later, outside React's work |
| the boundary's own `render` | no, not by itself | the error goes to the next boundary above it |

An error in an event handler leaves the page as it was and reaches the browser as an uncaught error,
which in development shows in the console. The handler is ordinary JavaScript, so a `try`/`catch`
inside it, setting some state that the render shows, is the way to put such an error on the screen.

The last line of the table is why one boundary is not enough. **A boundary around each card protects
the page from a card; nothing yet protects the page from everything else.** An error in
`WeekSummary`, or in `App` itself, would still find no boundary above it, and the page would go white
as before. So one more goes around the whole application, in `src/main.tsx`:

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { ErrorBoundary } from './ErrorBoundary'
import { PlannerProvider } from './PlannerProvider'

const queryClient = new QueryClient()

const crashed = (
  <main>
    <h1>Study planner</h1>
    <p role="alert">Something went wrong, and the planner stopped. Reload the page to start again.</p>
  </main>
)

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary fallback={crashed}>
      <QueryClientProvider client={queryClient}>
        <PlannerProvider>
          <App />
        </PlannerProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  </StrictMode>,
)
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 56ms on 19 files with 116 rules using 4 threads.
no errors
```

Its fallback is deliberately plain. It is drawn when something unforeseen has failed, so it uses
nothing that could fail with it: no data, no context, no other component of the app. The heading is
the same as on every screen, so a user sees they are still in the planner, and `role="alert"` makes a
screen reader announce the paragraph as soon as it appears.

This boundary goes **outside** the providers on purpose. An error in `PlannerProvider` or in the
query client is then caught too, and the fallback does not need either of them.

The two layers answer two questions. The boundaries around the cards say which parts of the screen
**may fail on their own** and leave the rest working. The one at the root says what the user sees
**when anything else fails**, so that the answer is never a white page.
