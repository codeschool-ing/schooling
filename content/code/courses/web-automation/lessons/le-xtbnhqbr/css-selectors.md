---
title: CSS selectors, counted on the shop
version: 1
---

**A CSS selector is the language a stylesheet uses to say which elements a rule applies to**, and
the same language finds elements for a test. You have probably written some: `.card` in a
stylesheet means every element whose class list includes `card`. A test reads the same selector
the same way. The difference is what you want from it. A style rule is glad to match forty
elements; a test that wants to click one button needs a selector that matches **one**.

## The pieces

| selector | matches |
|---|---|
| `li` | every element with that tag |
| `.card` | every element whose `class` includes `card` |
| `#products` | the element whose `id` is `products` |
| `[data-testid]` | every element that has the attribute, whatever its value |
| `[data-testid="product-mango"]` | the attribute with exactly that value |
| `[data-testid^="product-"]` | a value that starts with `product-` (`$=` ends, `*=` contains) |
| `A B` | a `B` anywhere inside an `A`, at any depth: the **descendant** combinator |
| `A > B` | a `B` directly inside an `A`: the **child** combinator |
| `A:nth-child(2)` | an `A` that is the second child of its parent |
| `A:has(B)` | an `A` with a `B` somewhere inside it |

Pieces join without spaces to mean *all of these at once*: `li.card[data-testid]` is an `li` that
has the class and the attribute. A space between them means *inside*, which is the most common
slip in the whole language.

## Counting, on the real page

`count.mjs` takes any number of selectors. The tags and classes first:

```
ana@laptop:~/quitanda$ node count.mjs 'li' '.card' 'button' 'button:visible' '.card button' '.card small' '.card > small'
  8  li
  8  .card
  9  button
  8  button:visible
  8  .card button
  8  .card small
  0  .card > small
```

Three things in that list are worth a second look:

- **`button` finds 9 and the page shows eight buttons.** The ninth is the **Menu** button in the
  header, which the stylesheet hides on any window wider than 600 pixels. It is in the DOM
  anyway, and a selector does not care whether you can see what it matches. `:visible` is not
  CSS; it is one of a few additions Playwright's `page.locator` accepts on top of the standard,
  and it brings the count back to 8;
- **`.card small` finds 8 and `.card > small` finds 0.** The `small` is inside the `p`, so it is a
  grandchild of the card, never a child. The descendant combinator forgives a level of nesting and
  the child combinator does not;
- **`.card` and `.card button` find 8 each**, which is right if you meant all the cards and wrong
  if you meant the banana. A count is the cheapest test of a locator, and you can run it before
  writing the test at all.

Now attributes, positions and `:has`:

```
ana@laptop:~/quitanda$ node count.mjs '[data-testid]' '[data-testid^="product-"]' '[data-testid="product-mango"] h2' '.card:nth-child(2) h2' 'li:nth-child(9)' '.card:has(small)' '[role="status"]'
  9  [data-testid]
  8  [data-testid^="product-"]
  1  [data-testid="product-mango"] h2
       <h2>Mango</h2>
  1  .card:nth-child(2) h2
       <h2>Mango</h2>
  0  li:nth-child(9)
  8  .card:has(small)
  1  [role="status"]
       <p role="status" class="toast"></p>
```

`[data-testid]` finds 9 because the basket's counter in the header carries one as well;
`[data-testid^="product-"]` keeps only the eight cards. The two selectors that find Mango by
different routes print the same heading: one by the card's test id, the other by **position**,
the second child of the list. `li:nth-child(9)` finds nothing, since there are eight. The toast,
`[role="status"]`, is there and empty: it gets its text only after a click.

## What CSS cannot say

`.card:has(small)` finds all eight cards. `:has` lets a selector pick an element by what is inside
it, which is the nearest CSS comes to looking downwards and choosing the parent. It does not help
here, because every card has the same elements inside it. **What makes the Mango card the Mango
card is the word *Mango***, and a CSS selector cannot test text at all: there is no selector for
*the card whose heading says Mango*. A test that needs one has two ways out. XPath, in the next
section, can read text. Playwright's own locators can filter by it, two sections after that.

## Specific is not the same as stable

Stylesheets teach a habit that works against tests. When two CSS rules disagree, the one whose
selector carries more ids and classes wins, which is called **specificity**, and people who write
stylesheets learn to add pieces until their rule wins. A test selector gains nothing from that:

```
ana@laptop:~/quitanda$ node count.mjs 'main > ul#products > li.card:nth-child(2) > h2' '[data-testid="product-mango"] h2'
  1  main > ul#products > li.card:nth-child(2) > h2
       <h2>Mango</h2>
  1  [data-testid="product-mango"] h2
       <h2>Mango</h2>
```

Both find the same heading. The first also needs the list to be a `ul` directly inside `main`, to
keep its `id`, the card to keep its class and its place in the list, and every step to stay exactly
one level deep.
**Every piece of a selector is a promise the page has to keep**, and the shortest selector that
finds exactly one element is the one with the fewest promises.
