---
title: Why a div is not enough
---

Visually, `<div>` and `<main>` are identical: neither has any relevant styling of its own. The difference is that one of them **means** something.

Who reads that meaning: screen readers, which offer to skip straight to the main content; search engines, which tell an article from a menu; the browser's reading mode, which has to guess where the text starts; and the person who opens your code a year from now.

The cost of using the right element is zero — it is the same number of characters. The cost of not using it shows up later, and always on whoever has the least choice.
