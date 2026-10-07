---
title: Reading utilities as the CSS you know
version: 1
---

Every utility is a declaration this course has taught, and most names follow a pattern: an abbreviation of the property, a dash, and a value from a scale.

| Utility | What it generates | Lesson |
| --- | --- | --- |
| `p-4`, `px-4`, `mt-1` | `padding`, `padding-inline`, `margin-top`, 4 or 1 steps of `--spacing` | 6 |
| `max-w-3xl` | `max-width: var(--container-3xl)`, 48rem | 6 |
| `text-2xl` | `font-size: 1.5rem` and a matching `line-height` | 5 |
| `font-bold` | `font-weight: 700` | 5 |
| `flex`, `items-center`, `justify-between`, `gap-4` | `display: flex`, `align-items`, `justify-content`, `gap` | 8 |
| `grid`, `grid-cols-3`, `col-span-2` | `display: grid`, `grid-template-columns: repeat(3, minmax(0, 1fr))`, a span | 9 |
| `relative`, `absolute`, `top-0`, `z-10` | `position`, `top`, `z-index` | 7 |
| `sr-only` | the visually hidden technique | 7 |
| `rotate-6`, `scale-110`, `transition` | `rotate`, `scale`, `transition-property` and a duration | 12 |

## The scale is a set of custom properties

The numbers are not pixels. **One step is `--spacing`**, and the first build declared it, together with every colour the page used, on `:root`:

```
ana@laptop:~/site$ grep -n "@layer" first/out.css
2:@layer properties;
3:@layer theme, base, components, utilities;
4:@layer theme {
29:@layer base {
177:@layer utilities {
241:@layer properties {
ana@laptop:~/site$ grep -E -- "--(spacing|color-[a-z]+-[0-9]+):" first/out.css
    --color-emerald-700: oklch(50.8% 0.118 165.612);
    --color-stone-50: oklch(98.5% 0.001 106.423);
    --color-stone-600: oklch(44.4% 0.011 73.639);
    --color-stone-900: oklch(21.6% 0.006 56.043);
    --spacing: 0.25rem;
```

**`--spacing: 0.25rem`**, 4 pixels, so `p-4` is four steps, 16 pixels, and `mt-1` is 4. Those are lesson 10's design tokens, exactly: the palette and the scale are custom properties, and every utility reads one with `var()`. The first `grep` also shows how the stylesheet is organised, which is the next section's subject: in **cascade layers**.
