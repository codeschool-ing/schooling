---
title: Finding out which rule won
version: 1
---

Every capture in this lesson used `probe rules`, and it exists because **DevTools shows the same list**. When a style is not doing what you expect, this is the procedure that finds out why in a minute, instead of an afternoon of adding `!important`:

1. **Right-click the element and choose Inspect.** The Elements panel opens with the element selected.
2. **Look at the Styles pane.** It lists every rule that matched the element, most important first: `element.style` at the top, then your rules from the highest specificity down, then the browser's, labelled *user agent stylesheet*. Each rule names its file and line.
3. **Find the property.** A declaration that lost is **struck through**. The one that applies is the one that is not, and its rule is the winner.
4. **Read why it won.** Higher in the list means it won on specificity or order; the file and line tell you which. If your declaration is struck through, the rule above it with the same property is what beat it.
5. **If your rule is not listed at all, the selector does not match.** That is a different problem: read the selector from the right, as section 04 said, against the element's actual classes and parents in the tree.
6. **The Computed pane** shows the final value of every property, and expanding one shows every declaration that competed for it, which is the same as the `computed` line at the bottom of each `probe rules`.

## Three things it shows that you would not guess

**A declaration with a warning sign was not understood**: a misspelt property or an invalid value, skipped as section 02 said. **An inherited value appears under *Inherited from main*** further down, not among the element's own rules, as the note's colour would have. **A rule can match and set nothing you see**: a background on an element whose children cover it completely is applied and invisible, and the Computed pane is how you prove the value is there.

The panel also lets you edit any value and see the result at once, untick a declaration to switch it off, and add a new one. Nothing you change there is saved: it is a place to experiment, and when you find the fix you write it in the file.
