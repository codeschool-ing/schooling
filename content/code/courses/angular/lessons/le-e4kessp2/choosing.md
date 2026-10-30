---
title: Choosing, and what goes with you
version: 1
---

**A framework is chosen for a team and an application, not for a card, and the card's differences
are the small ones.** What weighs in a real choice:

| Angular fits when | another fits when |
| --- | --- |
| the application is large, long-lived, and many people will work on it | a small team wants to choose each piece itself |
| one structure everywhere matters more than freedom: services, DI, the CLI's generators | the page is mostly content, read once, where every kilobyte counts |
| the team wants one upgrade path, `ng update`, for the whole stack | the team already knows React, Vue or Svelte, and its libraries |
| forms, routing and HTTP should be the same in every project the company has | a framework's own full-stack tool, Next, Nuxt or SvelteKit, is the product |

Angular's habit of deciding things is the reason it is common in companies with many teams and applications that live for years. A developer who moves from one Angular project to another finds the same folders, the same services, the same router and the same forms. React's habit of not deciding
is the reason it is everywhere else: each project assembles what it needs, and no two assemble it the
same way. Neither is a mistake. Knowing which one a team has made, and why, is the useful part.

## What goes with you

Most of what this course taught is not Angular's:

- **Components with inputs and outputs, and data that flows one way.** Every framework here works so,
  and lesson 8's `input()` and `output()` are `props` and an event in the others.
- **State that is read, and values derived from it, never stored twice.** Signals, refs, runes, or a
  `const` in a React function; the store pattern of lesson 22 is the same pattern in all four.
- **TypeScript, and a template the compiler checks.** All four check templates now, Angular most
  strictly.
- **What the server is for, and what it is not.** The API, the errors it sends, a failure undone and
  said out loud: lessons 12 and 13 hold in any of them.
- **Rendering on the server, and the browser taking over.** Hydration is the same idea in Next, Nuxt
  and SvelteKit.
- **Accessibility, tested on what the page says.** A label, a focus moved and returned, a live region:
  those are HTML's, and lesson 21's dialog works the same anywhere.
- **Tests at the cheapest level that can see the rule.** Vitest is the runner of all four.

What stays is Angular's: dependency injection as a system, decorators, `@for` and the other blocks,
RxJS where an application uses it, and the CLI. A student who takes one of the other courses after
this one starts from the second list, not from the beginning.
