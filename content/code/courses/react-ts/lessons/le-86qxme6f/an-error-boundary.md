---
title: An error boundary
version: 1
---

**An error boundary is a component that catches errors thrown while rendering anything inside it,
and draws something else in their place.** React has no hook for this: a boundary is written as a
class, the one place in modern React where a class component is still the only way. The whole of it
is `src/ErrorBoundary.tsx`:

```schooling-example
{"language": "tsx", "file": "src/ErrorBoundary.tsx", "parts": [{"code": "import { Component, type ErrorInfo, type ReactNode } from 'react'\n", "note": "`Component` is the base class every class component extends, and `ErrorInfo` is the type of what React tells the boundary about an error."}, {"code": "type ErrorBoundaryProps = {\n  fallback: ReactNode\n  children: ReactNode\n}\n", "note": "Two props: what to draw when something failed, and the children to draw when nothing has."}, {"code": "type ErrorBoundaryState = { failed: boolean }\n", "note": "A class keeps its state in one object, `this.state`. This one needs one fact: whether a child has failed."}, {"code": "export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {\n  state: ErrorBoundaryState = { failed: false }\n", "note": "**The state starts as not failed.** `Component<Props, State>` tells TypeScript the shapes of both, so `this.props.fallback` is checked like any prop."}, {"code": "  static getDerivedStateFromError(): ErrorBoundaryState {\n    return { failed: true }\n  }\n", "note": "**React calls this when a child throws during rendering**, and renders the boundary again with the state it returns. It runs in the middle of a render, so it must only compute: no logging here."}, {"code": "  componentDidCatch(error: Error, info: ErrorInfo) {\n    console.error(`ErrorBoundary: ${error.message}${info.componentStack}`)\n  }\n", "note": "**Called after the fallback is on the page**, with the error and `info.componentStack`, the components the error came up through. The place for side effects, such as a report."}, {"code": "  render() {\n    return this.state.failed ? this.props.fallback : this.props.children\n  }\n}", "note": "Draws the fallback once a child has failed and the children until then. `this.props` and `this.state` are a class's versions of a function component's props and `useState`."}]}
```

Wrap each card in one, in `src/CourseList.tsx`. The `key` moves from the card to the boundary, since
the boundary is now the outermost element the list renders for each course:

```tsx
import { Card } from './Card'
import { CourseCard } from './CourseCard'
import { ErrorBoundary } from './ErrorBoundary'
import type { Course, Session } from './types'

type CourseListProps = {
  courses: Course[]
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseList({ courses, sessions, onOpen }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <ErrorBoundary
          key={course.id}
          fallback={
            <Card title={course.name}>
              <p>This course could not be shown.</p>
            </Card>
          }
        >
          <CourseCard
            course={course}
            sessions={sessions.filter((s) => s.course === course.id)}
            onOpen={onOpen}
          />
        </ErrorBoundary>
      ))}
    </section>
  )
}
```

The fallback is a `Card` with the course's name and one sentence, so a card that fails still occupies
its place in the list and says which course it was. Do the same thing as before, ticking the last
statistics session:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 84ms on 19 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses'
-- click button Statistics
-- click checkbox Wed 21 Oct · 40 min
-- click button Back to courses
[error] %o

%s

%s
 TypeError: Cannot read properties of undefined (reading 'date')
    at CourseCard (http://localhost:5173/src/CourseCard.tsx:30:80)
    at Object.react_stack_bottom_frame (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:14140:12)
    at renderWithHooks (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:4398:19)
    at updateFunctionComponent (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:5773:16)
    at beginWork (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:6389:20)
    at runWithFiberInDEV (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:942:66)
    at performUnitOfWork (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:9146:92)
    at workLoopSync (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:9042:37)
    at renderRootSync (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:9026:6)
    at performWorkOnRoot (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:8713:27) The above error occurred in the <CourseCard> component. React will try to recreate this component tree from scratch using the error boundary you provided, ErrorBoundary.
[error] ErrorBoundary: Cannot read properties of undefined (reading 'date')
    at CourseCard (http://localhost:5173/src/CourseCard.tsx:5:30)
    at ErrorBoundary (http://localhost:5173/src/ErrorBoundary.tsx:2:8)
    at section (<anonymous>)
    at CourseList (http://localhost:5173/src/CourseList.tsx:6:30)
    at main (<anonymous>)
    at App (http://localhost:5173/src/App.tsx:14:30)
    at PlannerProvider (http://localhost:5173/src/PlannerProvider.tsx:6:35)
    at QueryClientProvider (http://localhost:5173/node_modules/.vite/deps/@tanstack_react-query.js?v=f3762bc1:43:30)
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 120 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: This course could not be shown.
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

**The page stayed.** The heading, the week buttons, the summary with its 120 minutes, the Spanish and
chemistry cards are all there; only the statistics card has become *This course could not be shown.*
The error went up the tree from `CourseCard` and stopped at the nearest boundary above it, and the
boundaries around the other two cards never saw it.

```schooling-figure
{"svg": "<svg data-fig=\"caught\" viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The planner's tree with error boundaries. The root holds App, which holds WeekNav, WeekSummary and CourseList. CourseList holds three ErrorBoundary components, one per course, each around a CourseCard. The statistics CourseCard throws; the error travels up to the boundary directly above it, which draws the fallback card. The other two boundaries and everything above them are untouched.\"><rect x=\"290\" y=\"10\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"40\" y=\"70\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekNav</text><line x1=\"360\" y1=\"40\" x2=\"115\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"210\" y=\"70\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><line x1=\"360\" y1=\"40\" x2=\"285\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"470\" y=\"70\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseList</text><line x1=\"360\" y1=\"40\" x2=\"545\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"545\" y1=\"100\" x2=\"360\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"300\" y=\"130\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ErrorBoundary</text><line x1=\"360\" y1=\"160\" x2=\"360\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"300\" y=\"190\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">CourseCard</text><text x=\"360.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">statistics</text><line x1=\"545\" y1=\"100\" x2=\"500\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"440\" y=\"130\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ErrorBoundary</text><line x1=\"500\" y1=\"160\" x2=\"500\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"440\" y=\"190\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">CourseCard</text><text x=\"500.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">spanish</text><line x1=\"545\" y1=\"100\" x2=\"640\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"580\" y=\"130\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ErrorBoundary</text><line x1=\"640\" y1=\"160\" x2=\"640\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"580\" y=\"190\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">CourseCard</text><text x=\"640.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">chemistry</text><path d=\"M 296 214 C 270 200 270 160 296 148\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><polygon points=\"296.0,148.0 291.2,154.6 287.9,149.1\" fill=\"var(--amber)\"></polygon><text x=\"260\" y=\"182\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">throws</text><text x=\"360\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the fallback card</text><text x=\"570\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">drawn as before</text><text x=\"40\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">untouched:</text><text x=\"40\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the week, the summary</text></svg>", "caption": "An error goes up to the nearest boundary and no further."}
```

The console has two errors now, both in red, and they are the two halves of the boundary at work:

- **React's own report**, the long one with `%o` and `%s` in it, which in development names the
  boundary that took over: *React will try to recreate this component tree from scratch using the
  error boundary you provided, ErrorBoundary.* Its stack is a JavaScript stack, mostly React's own
  functions, with line numbers of the file as Vite served it after compiling the JSX, which is why
  `CourseCard.tsx:30` does not match the source.
- **The line from `componentDidCatch`**, which starts `ErrorBoundary:`. Its stack is different: the
  *component* stack, the chain of components from the one that failed up to the root. That is the
  stack a person debugging this wants, and it is what you would send to an error reporting service.

React gives a boundary two methods for two moments, and they are not interchangeable:

| method | when React calls it | what it may do |
|---|---|---|
| `static getDerivedStateFromError(error)` | during the render, as soon as a child has thrown | return the new state, and nothing else: it is a pure function |
| `componentDidCatch(error, info)` | after the fallback has been put on the page | side effects: log, send a report |
