---
title: What a Web Component is
version: 1
---

**A Web Component is an element you define, used in a page like any built-in one, and made from three
browser standards that need no library at all.** Each standard is useful alone; together they give a
design system something its function components cannot: a component that every framework can use, because
it is just an element.

| standard | gives you | the planner's use |
|---|---|---|
| **custom elements** | your own tag, `<planner-session>`, with a class that runs when one appears | a session row any page can write in HTML |
| **shadow DOM** | a private tree of elements inside your tag, with styles that do not leak in or out | a button the page's CSS cannot repaint |
| **templates and slots** | inert markup to clone, and holes where the page's own content goes | the row's structure, with the course name passed in |

The common picture is that Web Components are a rival framework, to be chosen instead of React or Vue.
They are lower than that: **a framework renders elements, and a Web Component is an element**. React,
Angular, Vue and Svelte all render `<planner-session>` the way they render `<button>`, which is why the
last section of this lesson can show the same tag in each of them.

## Why a design system reaches for them

The library from lesson 7 exports functions that return DOM. A plain TypeScript app calls them happily. A
Vue app would need a wrapper component around each, so would a React one, and each wrapper is code to
keep in step with the library. A company with apps in three frameworks either writes three wrappers per
component or writes the component once as an element.

The cost is real, and this lesson shows it as it goes: attributes are strings, the shadow boundary
complicates forms and labels, and server rendering of shadow DOM needs extra care. Many design systems use
Web Components for their leaf components, buttons and badges and rows, and framework components for the
layouts around them.

## What the lesson builds

`<planner-session>`, in the library, beside the function components, with a demo page that Vite serves
and Playwright tests that drive it. **No library is used to write it**, so every line is a browser API;
**Lit**, a small library from Google's web platform team, is what many teams use to write the same thing
with less code, and it produces exactly the kind of element this lesson writes by hand.
