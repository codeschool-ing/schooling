---
title: Naming components so nobody has to guess
version: 1
---

Classes are where most of a stylesheet's selectors live, and a class name is read far more often than it is written. Without a convention, the same site ends up with `.card`, `.event-box`, `.eventCard` and `.tile` for four versions of one thing, and a selector like `.card .title` that also catches the title of a card inside another card. A naming convention prevents both. The one most teams know is **BEM**, for *block, element, modifier*:

```css
.event-card { padding: calc(var(--space) * 2); border-left: 4px solid var(--color-accent); }
.event-card__title { margin: 0; font-size: 1.1rem; }
.event-card--cancelled { --color-accent: #8a1c1c; }
```

- **The block** is the component: `.event-card`. One name, one component, one file.
- **An element** is a part that only exists inside it, written with two underscores: `.event-card__title`. It is a class of its own, so the rule is `.event-card__title`, not `.event-card .title`. That is one class, specificity (0,1,0), and it cannot catch the title of anything else.
- **A modifier** is a variant, written with two hyphens: `.event-card--cancelled`. It goes on the block beside the block's own class, and here it does the least it can: it redefines `--color-accent`, section 03's pattern, and everything inside the card follows.

```
ana@laptop:~/site$ probe site.html style .event-card border-left-color,padding-top style .event-card__title font-size
article.event-card.event-card--cancelled  border-left-color: rgb(138, 28, 28)
article.event-card.event-card--cancelled  padding-top: 16px
h2.event-card__title  font-size: 17.6px
```

The cancelled card's border is red and its padding 16px, from the shared tokens; its title is 17.6px, from the component file. The HTML says which component each element belongs to, and the CSS for that component is in one file named after it.

## Why the convention is worth its look

The names are long and the double underscores are not pretty. What they buy: **every selector is one class**, so specificity is flat and order decides, which is lesson 5's advice made automatic; **a component's styles cannot leak** into another's, because nothing selects by descendant; and **a class name says where its rule is**. You do not have to use BEM. You do have to use something, consistently, and the framework courses each bring their own way of scoping a component's styles, which solve the same problem in code.
