---
title: A field with no label is a broken field
---

Every field needs a `<label>` tied to it. The tie is the `for` pointing at the `id`:

[object Object]

The tie does three things at once: the screen reader announces the label when the field takes focus, clicking the text focuses the field, and the touch target on a phone grows — which matters more than it looks on checkboxes.

A `placeholder` does **not** replace a label. It disappears as soon as the person starts typing, and then nobody knows what that field was any more. It is a complement, not a substitute.
