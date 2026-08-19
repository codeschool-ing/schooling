---
title: Native validation, and where it stops
---

The browser validates on its own from attributes, with no line of JavaScript:

[object Object]

And you can style the state with `:valid`, `:invalid` and — most useful of all — `:user-invalid`, which only turns red **after** the person has interacted with the field. Without it, a form is born entirely red before anyone types anything.

**Validation in the browser is convenience, never security.** Anybody removes a `required` through the inspector in two seconds. The server validates everything again, always — the client-side one exists to avoid the trip to the server, not to protect it.
