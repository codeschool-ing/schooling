---
title: When not to use it
---

Repeating the same sequence of ten classes in fifteen places is a sign there was a component there. The right way out is the component of whatever framework you already use — a `<Button>` in React, a partial in the template — not a new class regrouping utilities.

And Tailwind does **not** excuse you from knowing CSS. Every class is a property: whoever does not understand specificity, the box model and flexbox does not understand `flex-1`, `min-w-0` or why the shadow disappeared. The twelve previous lessons are still the prerequisite.

The honest ruler: Tailwind pays off in a product with many components and a team sharing the scale. On a five-screen company site, hand-written CSS is smaller, more readable and brings no tooling along with it.
