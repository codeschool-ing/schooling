---
title: Media queries
version: 1
---

A **media query** is a condition about the device or the window, and a block of rules that only applies while the condition is true. The part in parentheses is a **media feature**:

```css
@media (width >= 40rem) { … }
```

`width` is the width of the viewport, the window the page is drawn in. Here it is being asked at three moments; the `width` step resizes the window while the page is open:

```
ana@laptop:~/site$ probe --width 600 first.html media "(width >= 40rem)" width 640 media "(width >= 40rem)" media "(min-width: 40rem)"
(width >= 40rem)  does not match
(width >= 40rem)  matches
(min-width: 40rem)  matches
```

At 600 the query does not match. At 640 it does, because 40rem is 640 pixels here. The rules inside start applying the moment the window crosses that width and stop when it goes back, with no reload. The third line is the same question in the older syntax, **`(min-width: 40rem)`**, which means "width is at least 40rem". You will read both everywhere. The **range syntax**, `width >= 40rem`, says the same thing with an operator, and it can say things `min-` and `max-` cannot say directly, such as `(40rem <= width < 64rem)`, a range between two widths. It works in every current browser.

## Combining and other features

Conditions combine with **`and`**, as in `(width >= 40rem) and (orientation: landscape)`; a comma between two queries means **or**; `not` negates a whole query. A query can start with a **media type**, `screen` or `print`: `@media print { nav { display: none; } }` takes the menu out of a printed page, which is the one media type you will still write. Section 08 covers the features that describe the reader rather than the window.

A stylesheet can also be conditional as a whole: `<link rel="stylesheet" href="print.css" media="print">` applies only when printing.

## rem in a query is not your rem

`rem` inside a media query does not use the font size you set on `html`. It uses the browser's **initial** font size, usually 16 pixels, because the query has to be answered before your stylesheet is applied. This page sets `html { font-size: 20px; }`:

```
ana@laptop:~/site$ probe --width 700 rem.html box .box media "(width >= 40rem)" media "(width >= 45rem)"
div.box  x 8      y 8      width 800    height 23
(width >= 40rem)  matches
(width >= 45rem)  does not match
```

A box of `40rem` is **800** wide, because in the page a rem is 20 pixels. And the window is 700 wide, yet `(width >= 40rem)` **matches**: in the query, 40rem is 640. `45rem`, 720, does not. So write breakpoints in `rem` or `em` and think of them as multiples of 16; and do not expect a change to the root font size to move them.

Why rem and not pixels? A reader who sets a larger default font size in their browser makes every rem bigger, **including the ones in queries**. A layout with its breakpoints in rem switches to the narrow layout sooner for that reader, which is exactly what their larger text needs. Breakpoints in pixels ignore that setting.
