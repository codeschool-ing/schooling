---
title: A listener you cannot remove
version: 1
---

One use of `bind` survives everywhere, in classes that handle events, and it comes with a bug of its
own. Lesson 12 is about events; this section needs only two facts. `addEventListener("click", fn)`
runs `fn` on every click, and **`removeEventListener("click", fn)` stops it only if `fn` is the same
function**, compared with `===`.

```html
<!doctype html>
<button id="ring">Ring</button>
<script>
  "use strict";

  class Bell {
    constructor(name) {
      this.name = name;
      this.boundRing = this.ring.bind(this);
    }
    ring() {
      console.log(`${this.name} rang`);
    }
  }

  const bell = new Bell("front door");
  const button = document.querySelector("#ring");

  button.addEventListener("click", bell.ring.bind(bell));
  button.addEventListener("click", bell.boundRing);

  button.addEventListener("click", () => {
    button.removeEventListener("click", bell.ring.bind(bell));
    button.removeEventListener("click", bell.boundRing);
    console.log("removed both, supposedly");
  });
</script>
```

```
ana@dev:~/js$ page listeners.html --do 'click #ring' --do 'click #ring'
-- click #ring
front door rang
front door rang
removed both, supposedly
-- click #ring
front door rang
removed both, supposedly
```

Three listeners were added. The first click ran all three, and the third tried to remove the first
two. The second click shows how that went: **the bell still rang once, so one of the two removals did
nothing.** It was the first one.

`bell.ring.bind(bell)` makes **a new function every time it runs**. The listener added was one bound
function; the one passed to `removeEventListener` was a second, made a moment later, and the two are
not `===`. The browser looked for the second, found nothing, and kept the first. `bell.boundRing` was
bound once, in the constructor, and the same function was used to add and to remove, so that removal
worked.

The third listener ran again on the second click too, because nothing removed it. Lesson 19 comes
back to listeners nobody removes, from the side of memory.

## The rule

**Bind once, keep the result, and use that one value to add and to remove.** The constructor is
the usual place. Lesson 8 shows the shorter form classes have for this, an arrow-function field,
which gives the same guarantee: one function per object, made once, with `this` fixed.
