---
title: DOM: the HTML becoming a tree
---

The browser reads the HTML and builds the **DOM** — a tree of objects in which every element is a node with a parent, children and properties. The HTML is the text; the DOM is what exists in memory after interpreting it.

The distinction matters because the DOM is not obliged to look like the file. It is corrected while being built (a badly closed tag gets patched) and altered afterwards by JavaScript. That is why "view source" and "inspect element" can show different things — the first is the text that arrived, the second is the tree as it is now.
