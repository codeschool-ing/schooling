---
title: Order, !important and the style attribute
version: 1
---

When specificity ties, order decides. Here are three rules in `order.css`, two of them identical, all (0,1,1):

```css
.event h2 { color: #2f6f4e; }
.featured h2 { color: #7a5c00; }
.event h2 { color: #333333; }

.intro { color: #555555 !important; }
#events .intro { color: #8a1c1c; }
```

```
ana@laptop:~/site$ probe order.html rules '.featured h2' color
.event h2 (0,1,1)     color: #2f6f4e                  order.css
.featured h2 (0,1,1)  color: #7a5c00                  order.css
.event h2 (0,1,1)     color: #333333                  order.css
computed color: rgb(51, 51, 51)
```

All three match the featured event's heading. **The last one in the file wins**, so the heading is `#333333`, not the brown that `.featured h2` was written to give it. Somebody added a rule for `.featured`, the rule was right, and a forgotten duplicate further down the file overrode it. Reading the list from the bottom, as DevTools draws it, is how you find that.

## `!important`

`!important` after a value lifts the declaration above every normal declaration, whatever the specificity:

```
ana@laptop:~/site$ probe order.html rules .intro color
.intro (0,1,0)          color: #555555 !important       order.css
#events .intro (1,1,0)  color: #8a1c1c                  order.css
computed color: rgb(85, 85, 85)
```

`#events .intro` is (1,1,0) and should beat `.intro` at (0,1,0) easily. It does not, because `.intro` said `!important`. The only thing that beats an `!important` declaration is another `!important` declaration with the same or a stronger claim, and that is how stylesheets end up with `!important` everywhere: each one is answered with another.

**Use it for almost nothing in your own CSS.** It has two honest uses: a utility class that must win wherever it is put, such as one that hides an element, and overriding CSS you do not control, such as a third-party widget's. When you reach for it to fix a specificity problem, the problem is a selector somewhere that is more specific than it needed to be, and that is the thing to fix.

## The `style` attribute

A declaration in a `style` attribute belongs to the element itself and beats every selector in every stylesheet, whatever their specificity, because it is not matched by a selector at all. Only `!important` in a stylesheet beats it. That makes it the hardest thing on a page to override, which is the reason section 02 said to leave it to scripts. DevTools lists it at the top of the Styles panel as `element.style`.
