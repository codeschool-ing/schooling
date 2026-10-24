---
title: What can cross the boundary
version: 1
---

**A Server Component can render a Client Component, and the props it passes have to travel to the
browser as data.** `monday` is a string, which travels as it is. A function is the case that cannot,
for the same reason as the `onClick`, with a sharper message when it is not called `on…`:

```
ana@dev:~/planner-next$ sed -i 's|<WeekKeys monday={monday} />|<WeekKeys monday={monday} toWeek={(m: string) => console.log(m)} />|' app/Planner.tsx
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 | grep -A 3 'Functions cannot' | head -n 4
Uncaught Error: Functions cannot be passed directly to Client Components unless you explicitly expose it by marking it with "use server". Or maybe you meant to call this function rather than return it.
  <... monday=... toWeek={function toWeek}>
                         ^^^^^^^^^^^^^^^^^
- img
ana@dev:~/planner-next$ sed -i 's|<WeekKeys monday={monday} toWeek={(m: string) => console.log(m)} />|<WeekKeys monday={monday} />|' app/Planner.tsx && grep -c toWeek app/Planner.tsx
0
```

*Functions cannot be passed directly to Client Components unless you explicitly expose it by marking
it with "use server".* That exception is lesson 16's subject: a **Server Function**, which the browser
calls over the network. Anything else that is code stays on the side it was written.

What a Server Component can pass to a Client Component, from React's own list:

| crosses | does not cross |
|---|---|
| strings, numbers, booleans, `null`, `undefined` | functions, unless they are Server Functions |
| arrays and plain objects of those | instances of your own classes |
| `Date`, `Map`, `Set` | symbols that are not registered with `Symbol.for` |
| JSX, including Server Components as `children` | |
| promises, which a Client Component can read with `use` | |

Two consequences shape how such an app is built:

- **Keep the boundary low.** `'use client'` makes a whole file, and everything it imports, client code.
  Putting it on `Planner` would have sent the date arithmetic, the course list and the fetch to the
  browser, and the fetch would then have needed the proxy back. `WeekKeys` is twenty lines, and only
  those, with what they import from `lib/week.ts`, became browser code.
- **Children cross as finished results.** A Client Component can receive Server Components as
  `children`, already rendered on the server, and place them; it never runs them. That is how a
  client-side layout, a tab bar say, wraps content that was fetched on the server.
