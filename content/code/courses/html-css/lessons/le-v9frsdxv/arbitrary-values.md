---
title: Values off the scale
version: 1
---

Sometimes a value is not on the scale: a width from a design, a brand colour used once. Square brackets take any value, an **arbitrary value**: `w-[37rem]`, `text-[#2f6f4e]`, `grid-cols-[12rem_1fr]`, with an underscore where CSS has a space. They work, and they are the `margin: 13px` of lesson 10 section 08: each is a value that bypasses the design's tokens.

The CLI has a command that rewrites class lists into their **canonical** form, which is what a linter in an editor does as you type:

```
ana@laptop:~/site$ npx @tailwindcss/cli canonicalize "p-[16px] mt-[4px] w-[37rem] text-[#2f6f4e]"
mt-[4px] w-148 p-[16px] text-[#2f6f4e]
```

It put the classes in Tailwind's order, margins before widths before padding. And **`w-[37rem]` became `w-148`**: 37rem is 148 steps of 0.25rem, so the value is on the scale after all, and the arbitrary form only hid it. `p-[16px]` and `mt-[4px]` stayed as they were, because the scale is in rem and a pixel value is a different value, even when it renders the same today: if a reader's default font size is larger, `p-4` grows with it and `p-[16px]` does not. `text-[#2f6f4e]` stayed, because that colour is not in the palette. **The fix for a colour used twice is a token in `@theme`**, section 07, which gives it a name and a utility.

## Where Tailwind stops

Everything in this course is still available: an input stylesheet can hold any CSS, and a few lines of ordinary CSS are often clearer than a long list of arbitrary values. The test from section 02 applies. If you cannot say what CSS a class list generates, the class list is the wrong tool for that piece, and the lesson that explains the property is the place to look.
