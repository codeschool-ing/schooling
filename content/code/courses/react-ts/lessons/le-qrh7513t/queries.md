---
title: Queries, keys and the cache
version: 1
---

**A query is a key and a function that fetches.** The library calls the function, keeps what it
returns under the key, and gives every component that asks for that key the same data. Install it at
the version this course uses:

```
ana@dev:~/planner$ npm install @tanstack/react-query@5.104.5

added 2 packages, and audited 37 packages in 681ms

14 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

The cache is one object, a `QueryClient`, created once and handed down by a provider, which goes
outside the planner's own in `src/main.tsx`:

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { PlannerProvider } from './PlannerProvider'

const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <PlannerProvider>
        <App />
      </PlannerProvider>
    </QueryClientProvider>
  </StrictMode>,
)
```

Then `usePlanner` stops fetching and starts asking. This is the whole of it now:

```schooling-example
{"language": "typescript", "file": "src/usePlanner.ts", "parts": [{"code": "import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'\nimport type { Course, Session } from './types'\n", "note": "The library's three hooks. Nothing from React itself is needed any more: no `useState`, no `useEffect`."}, {"code": "export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>\ntype Planner = { courses: Course[]; sessions: Session[] }\ntype Status = 'loading' | 'ready' | 'failed'\n", "note": "The shape of a new session, as lesson 10 had it, and the shape of what the API answers."}, {"code": "async function request<T>(path: string, init?: RequestInit): Promise<T> {\n  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })\n  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)\n  return response.json()\n}\n", "note": "One small function for every request: it sends JSON, and turns any status that is not 2xx into an error, which is what tells the library a request failed."}, {"code": "export function usePlanner() {\n  const queryClient = useQueryClient()\n  const planner = useQuery({\n    queryKey: ['planner'],\n    queryFn: () => request<Planner>('/api/planner'),\n  })\n  const refresh = () => queryClient.invalidateQueries({ queryKey: ['planner'] })\n", "note": "**`useQuery` takes the key and the function.** The key is an array, and `['planner']` names this piece of data everywhere in the app. `refresh` tells the cache that whatever is under that key is out of date."}, {"code": "  const toggle = useMutation({\n    mutationFn: (id: string) => {\n      const current = queryClient.getQueryData<Planner>(['planner'])\n      const session = current?.sessions.find((s) => s.id === id)\n      return request(`/api/sessions/${id}`, {\n        method: 'PATCH',\n        body: JSON.stringify({ done: !session?.done }),\n      })\n    },\n    onSuccess: refresh,\n  })\n  const add = useMutation({\n    mutationFn: (session: NewSession) =>\n      request('/api/sessions', { method: 'POST', body: JSON.stringify(session) }),\n    onSuccess: refresh,\n  })\n", "note": "Two mutations, the library's word for a request that changes something. Each calls the API and, when it succeeds, `refresh`es the planner. The toggle reads the session's current `done` from the cache, so it needs nothing from the render."}, {"code": "  const status: Status = planner.isPending ? 'loading' : planner.isError ? 'failed' : 'ready'\n  return {\n    status,\n    courses: planner.data?.courses ?? [],\n    sessions: planner.data?.sessions ?? [],\n    toggleDone: toggle.mutate,\n    addSession: add.mutate,\n  }\n}", "note": "The same five things lesson 7's hook returned, so no caller changes. `isPending` is true until the first answer; `mutate` is a stable function, so the context's readers can rely on it."}]}
```

`App`, `CourseScreen` and the form did not change, and the type check and the linter agree. The page
asks for the planner once:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 88ms on 18 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network | grep -E 'api|courses'
net  GET /api/planner  200
```

**One `GET /api/planner`, even under strict mode.** Lesson 5's effect sent two, because strict mode
ran it twice and each run fetched. The query also ran twice, and the second time it found a request
for the same key already in flight and joined it. Any number of components asking for `['planner']`
at once produce one request.

The cache lives as long as the page. Open a course and come back, and the planner is drawn from the
cache at once; the library also refetches it in the background, because by default it treats every
answer as stale the moment it arrives. That default, `staleTime: 0`, is the safe one: it never shows
data older than the last mount or focus without checking. An app that knows its data changes rarely
sets a longer `staleTime` on the query and saves the requests.
