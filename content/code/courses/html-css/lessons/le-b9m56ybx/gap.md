---
title: Space between items: gap
version: 1
---

Space between flex items used to be made with margins, and margins cause two problems: the last item has a margin after it that nobody wanted, so the row ends short, and with wrapping the items at the start of each line have a margin before them. **`gap`** puts space **between** items and nowhere else:

```css
.shelf {
  display: flex;
  gap: 16px;
}
```

That is 16 pixels between each pair of items, and none before the first or after the last. With wrapping, `gap` also sets the space between lines; two values, `gap: 24px 16px`, set the gap between lines first and between items second, the same row-then-column order as everywhere else in CSS. `row-gap` and `column-gap` set them one at a time.

The `align.html` shelves above used `gap: 8px`, which is why the items' x positions were 0, 58.69 and 165.16: each starts 8 pixels after the one before ends, 50.69 + 8 = 58.69.

## Gap and the free space

`gap` comes off the free space before anything else is distributed. A shelf 600 wide with three items 100 wide and `gap: 16px` has 600 − 300 − 32 = 268 pixels left for `justify-content` or `flex-grow` to work with. **Use `gap` for the space between items, and margins for space between the container and what is around it.** The same property works identically in Grid, lesson 9, which is one more reason to prefer it.
