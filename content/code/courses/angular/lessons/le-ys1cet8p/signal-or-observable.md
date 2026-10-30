---
title: When a signal is enough
version: 1
---

**Use a signal for what something is, and an Observable for what happens to it over time.** Most of
an Angular application is the first kind: the data, the selected course, whether a panel is open,
the totals worked out from all three. For those, a `signal`, a `computed` and a resource say
everything that needs saying, with no subscription to forget. RxJS earns its place where time is
part of the question.

| the code needs | reach for |
|---|---|
| a value, and to change it | `signal` |
| a value worked out from others | `computed` |
| data from the server, read | `httpResource`, or `resource` |
| to send a write, and know how it went | `HttpClient`, subscribed once |
| to wait for a pause, or drop repeats | `debounceTime`, `distinctUntilChanged` |
| only the newest of several overlapping requests | `switchMap` |
| to try again, or to fall back | `retry`, `catchError` |
| to combine events from several sources over time | `combineLatest`, `merge` |

The planner lands exactly there. Its state is signals. Its one write goes through `HttpClient`
with a `retry`, because "try again in two seconds" is a statement about time. And its search box,
if it had one, would be `toObservable`, `debounceTime` and `switchMap`, ending in `toSignal` so the
template went on reading a signal.

**Code written before signals uses RxJS for everything**, and you will read a great deal of it: a
`BehaviorSubject` where a signal would do, `combineLatest` where a `computed` would, and `| async`
in every template. It works, and nothing obliges anybody to rewrite it. When you change such code,
`toSignal` and `toObservable` let the two kinds meet at the edge of what you touched.

## Putting the planner back

The bench goes, and `App` goes back to what git has:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M src/app/planner-store.ts
```

One change stays, the retry in the store:

```
ana@dev:~/planner$ git add -A && git commit -q -m "RxJS: retry a save that may work the second time"
```
