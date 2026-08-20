---
title: The round trip
---

Typing an address and watching the page appear hides a sequence worth knowing end to end, because it is the one the rest of the course takes apart:

- the browser finds the server's **address** from the name (that is DNS, lesson 08);
- opens a **connection** to it (lesson 02);
- sends a **request** saying what it wants (lesson 06);
- receives a **response** with the content and a status code;
- builds the page from what arrived, asking for the rest as it discovers it needs it (lesson 10).

Each step can fail in a different way, and each has a diagnostic tool of its own. That is why "the site will not open" is never one problem.
