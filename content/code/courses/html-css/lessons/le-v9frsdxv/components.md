---
title: Components without repeating yourself
version: 1
---

Twenty event cards with the same fifteen classes is the repetition from section 02. **The first answer is not CSS**: the site's templates should produce the card from one place, so the list is written once. A template in a server language, a component in a framework, an include in a static site generator: each one is a single file for "an event card", and the classes live there.

::: track frontend
In the framework you choose after `javascript`, a component is a file that takes data and returns markup, and that is where a Tailwind class list belongs: written once, used everywhere the component is. The repetition people complain about is mostly a sign that the component has not been extracted yet.
:::

::: track *
Server-rendered sites solve it the same way with templates: the HTML for an event card is written once and filled in for each event.
:::

When the markup cannot be controlled, a class added by a content management system or by a library, **`@apply`** copies utilities into a class of your own:

```css
@import "tailwindcss";

@layer components {
  .btn {
    @apply rounded-md bg-emerald-700 px-4 py-2 font-semibold text-white;
  }
}
```

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd components -i input.css -o out.css --silent
ana@laptop:~/site$ grep -A8 "^  \.btn {" components/out.css
  .btn {
    border-radius: var(--radius-md);
    background-color: var(--color-emerald-700);
    padding-inline: calc(var(--spacing) * 4);
    padding-block: calc(var(--spacing) * 2);
    --tw-font-weight: var(--font-weight-semibold);
    font-weight: var(--font-weight-semibold);
    color: var(--color-white);
  }
ana@laptop:~/site$ probe components/index.html style "#reserve,#wait" background-color
button#reserve  background-color: oklch(0.508 0.118 165.612)
button#wait  background-color: oklch(0.374 0.01 67.558)
```

`.btn` became an ordinary rule whose declarations are the utilities' declarations, reading the same tokens. It went into the **`components`** layer, and that decides what happens when a button also has a utility. The second button is `class="btn bg-stone-700"`: its background is stone, **`oklch(0.374 0.01 67.558)`**, not the emerald of `.btn`. `utilities` is the later layer, so a utility overrides a component, lesson 10 section 11, which is exactly what you want from a one-off change.

**Use `@apply` sparingly.** A stylesheet full of `@apply` is the stylesheet of lesson 10 written in a more limited language, and it brings back the naming and the leaking that utilities were for. For your own small utilities, `@utility name { … }` defines a new class that behaves like a built-in one, variants included.
