---
title: When the phone has no network
version: 1
---

**A phone is offline often**: a lift, a train, a building with thick walls, airplane mode. TanStack
Query's default is to **pause** a query or a mutation while offline and run it when the connection comes
back, instead of failing at once. To do that it needs to know whether the phone is online, and that is the
one line in `src/planState.tsx` outside every hook:

```tsx
onlineManager.setEventListener((setOnline) => NetInfo.addEventListener((s) => setOnline(!!s.isConnected)));
```

In a browser, TanStack Query listens to the browser's own online and offline events. On a phone there are
none, so NetInfo, which asks the platform, tells it instead.

## What the third test showed

The last test of the previous section sets `onlineManager.setOnline(false)` before pressing:

- the total showed **95** at once, because `onMutate` ran and wrote the change into the cache;
- `sendDone` had **not** been called: the mutation was paused, waiting;
- after `setOnline(true)`, it was called exactly once.

So a person on a train marks a session done, sees it done, and the request goes out when the train leaves
the tunnel. **If the app is closed before that, the paused change is lost**, because it lives only in
memory. Keeping it across a restart means writing it to storage, which TanStack Query offers through its
persistence plugins and which the `mobile-offline` course builds properly, with a queue of its own and the
conflicts that come with one.

## Saying that the phone is offline

A change that silently waits is better than one that fails, and worse than one that says it is waiting.
`onlineManager.isOnline()`, or NetInfo's `useNetInfo()` hook, lets a screen show a line such as *Offline:
changes will be sent when you reconnect*, in a `status` so a screen reader hears it once. The planner does
not draw one yet; it is the kind of sentence that should exist the first time the app is used somewhere
real.
