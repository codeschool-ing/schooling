---
title: fixed and sticky
---

`fixed` pins the element to the window: it does not move when the page scrolls. It is what holds this portal's top bar in place.

`sticky` is the hybrid: the element scrolls normally until it reaches the declared limit, and sticks there.

[object Object]

Two gotchas with `sticky` explain almost every "it does not work" case: it **requires** a declared offset (`top`, `bottom`…), without which it does nothing; and it sticks inside its **parent**, not the window — if the parent has `overflow: hidden` or ends soon, the effect ends with it.
