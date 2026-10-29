---
title: A return before a hook
version: 1
---

**The commonest way to break rule one is not an `if` around a hook. It is a `return` above one.** It
reads naturally: deal with the special cases first, then get on with the real work. In `App` that
would mean answering "still loading" before setting up the title effect, so here are the two lines
that draw the loading and failure screens moved up, above the second and third effects:

```
ana@dev:~/planner$ sed -n 38,45p src/App.tsx
    }
  }, [])

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21
[error] React has detected a change in the order of Hooks called by %s. This will lead to bugs and errors if not fixed. For more information, read the Rules of Hooks: https://react.dev/link/rules-of-hooks

   Previous render            Next render
   ------------------------------------------------------
%s   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 App 1. useState                   useState
2. useState                   useState
3. useState                   useState
4. useState                   useState
5. useState                   useState
6. useEffect                  useEffect
7. undefined                  useEffect

Uncaught Error: Rendered more hooks than during the previous render.
[warn] %s

%s
 An error occurred in the <App> component. Consider adding an error boundary to your tree to customize error handling behavior.
Visit https://react.dev/link/error-boundaries to learn more about error boundaries.

ana@dev:~/planner$ npm run lint 2>&1 | grep -c rules-of-hooks
2
ana@dev:~/planner$ cp /tmp/App.tsx src/App.tsx
```

**The type check passed and the app does not appear at all.** On the first render `status` is
`'loading'`, so `App` returned after six hooks: five `useState` and the fetch effect. When the data
arrived, `App` rendered again with `status` set to `'ready'`, went past the `return`, and called two
more effects. React kept a list of six slots and was asked for eight.

The console says it twice. First, a table of the hooks `App` called on the previous render against
the ones it called on this one, where slot 7 was `undefined` and is now a `useEffect`. `look` prints
React's message before its `%s` placeholders are filled in with the component's name, which your
browser's console fills in for you. Then the error itself: **"Rendered more hooks than during the
previous render"**, and a warning that suggests an error boundary, the subject of lesson 12. An
uncaught error during rendering removes the whole tree, which is why the page is empty.

The linter counted two hooks after the `return`. The fix is the order `App` had: every hook first,
then every `return`.

```tsx
// all the hooks
const [monday, setMonday] = useState(…)
// …
useEffect(() => { … }, [])

// then the screens that depend on them
if (status === 'loading') return <p>Loading the planner…</p>
```

The last `cp` put the correct `App` back.
