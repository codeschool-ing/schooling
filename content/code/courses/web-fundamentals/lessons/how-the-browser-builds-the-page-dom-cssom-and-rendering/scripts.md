---
title: Where JavaScript comes in
---

An ordinary `<script>` **stops the DOM being built** while it downloads and executes, because it may alter the very tree under construction. A script at the top of the `<head>` is the classic recipe for a blank page.

Two attributes solve it: `defer` downloads in parallel and executes after the HTML is built, preserving the order between scripts; `async` downloads in parallel and executes as soon as it arrives, guaranteeing no order at all.

`defer` is the right default for the page's own code, and it is also the behaviour of a `<script type="module">` — which explains why this portal can call `document.querySelector` at the top of a module without waiting for any event.
