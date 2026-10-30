---
title: The dependency array says when to run again
version: 1
---

**React runs an effect again after any render in which a value in its dependency array changed.**
The array is a list of every value from the component that the effect reads. Get it right and the
effect stays in step; leave one out and it runs with an old value, silently.

The second effect keeps the tab's title in step with the week:

```tsx
useEffect(() => {
  document.title = `Week of ${formatWeek(monday)} · Study planner`
}, [monday])
```

`look --html title` prints the page's `<title>` element at the end:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --html title
<title>Week of 19 Oct 2026 · Study planner</title>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week' --html title
-- click button Next week
<title>Week of 26 Oct 2026 · Study planner</title>
```

After "Next week" the title says 26 October. `monday` changed, the effect's array named `monday`, so
React ran it again after the commit.

## Three ways to write the array

| you write | the effect runs | the planner's example |
|---|---|---|
| `useEffect(fn)`, no array | after every render | none: almost never what you want |
| `useEffect(fn, [])` | once, after the component first appears | fetching the data; the keyboard listener |
| `useEffect(fn, [monday])` | after the first render, and after any render where `monday` changed | the title |

React compares each value with the previous render's using `Object.is`, the comparison lesson 4 met.
For strings and numbers that compares values. For an object or a function created during the render
it is never equal, so an effect that lists one runs after every render; lesson 7 deals with that.

## Leaving one out

Change the title effect's array to `[]` and the title stops following the week:

```
ana@dev:~/planner$ sed -i 's|^  }, \[monday\])$|  }, [])|' src/App.tsx
ana@dev:~/planner$ grep -n "}, \[" src/App.tsx
39:  }, [])
43:  }, [])
53:  }, [])
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week' --html title
-- click button Next week
<title>Week of 19 Oct 2026 · Study planner</title>
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint


  ! react-hooks(exhaustive-deps): React Hook useEffect has a missing dependency: 'monday'
    ,-[src/App.tsx:43:6]
 41 |   useEffect(() => {
 42 |     document.title = `Week of ${formatWeek(monday)} · Study planner`
    :                                            ^^^|^^
    :                                               `-- useEffect uses `monday` here
 43 |   }, [])
    :      ^^
 44 | 
    `----
  help: Either include it or remove the dependency array.

Found 1 warning and 0 errors.
Finished in 107ms on 11 files with 116 rules using 4 threads.
ana@dev:~/planner$ sed -i '0,/^  }, \[\])$/!{0,/^  }, \[\])$/s//  }, [monday])/}' src/App.tsx
ana@dev:~/planner$ grep -n "}, \[" src/App.tsx
39:  }, [])
43:  }, [monday])
53:  }, [])
```

The title still says 19 October after "Next week". The effect ran once with the first render's
`monday` and was never asked to run again. **Nothing failed, and nothing on the page said so.** But
the template's linter noticed. `npm run lint` runs Oxlint, which ships a rule called
`exhaustive-deps`: it reads the effect, sees `monday`, and points at the array that does not mention
it. The last `sed` puts `[monday]` back.

**The array is not a choice of when you would like the effect to run. It is a statement of what the
effect reads**, and the linter can check a statement. If an effect runs too often with the correct
array, the fix is to change what the effect reads, never to lie in the array. Lesson 6 is about the
rules this linter enforces, and lesson 23 about linters in general.
