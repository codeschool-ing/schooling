---
title: WeakRef and FinalizationRegistry
version: 1
---

This lesson used `WeakRef` to look at the collector's decisions. It is also a tool programs can use,
together with **`FinalizationRegistry`**, which runs a callback some time after a registered object
has been collected:

```javascript
const registry = new FinalizationRegistry((label) => console.log("collected:", label));

(function () {
  const cover = { image: new Array(100_000).fill(0) };
  registry.register(cover, "the cover of Iracema");
})();

console.log("cover dropped");
setTimeout(() => globalThis.gc(), 0);
setTimeout(() => console.log("done"), 100);
```

```
ana@dev:~/js$ node --expose-gc finalization.js
cover dropped
collected: the cover of Iracema
done
```

The cover was only reachable inside the function, so once the function returned it was garbage, and
after the collection **the registry's callback ran with the label it was given**. It cannot receive
the object itself, since the object no longer exists.

## Why they come last

These two exist for rare jobs, such as cleaning up a resource held outside JavaScript when the object
that represents it is gone. **The specification itself warns against relying on them**, for reasons
the lab hid by calling `gc()` by hand:

- **when collection happens is the engine's choice**, and it may be much later or, for a program that
  ends first, never. A finalization callback is not guaranteed to run at all;
- code that behaves differently depending on whether an object has been collected yet behaves
  differently from run to run and from engine to engine, which is the hardest kind of bug to find.

So the order of preference is the order of this lesson: **let go of references at the right moment
(clear the timer, remove the listener, bound the cache)**; use a `WeakMap` or `WeakSet` (lesson 5)
when data should follow an object's lifetime; and reach for `WeakRef` and `FinalizationRegistry` only
when neither of those can express what you need.
