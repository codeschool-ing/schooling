---
title: An outlier is a position, not a verdict
version: 1
---

**An outlier is a value far from the others. An error is a value that does not match the world.**
The two overlap, and the overlap is smaller than it looks. `statistics` lesson 9 drew the line in
general; this lesson works it on Quitanda Verde's order totals, where all four possibilities occur:

| | far from the others | close to the others |
|---|---|---|
| **wrong** | a total typed with a zero too many | a typo that happened to land in the normal range |
| **right** | a clinic's Christmas order | almost every order |

The bottom-left cell is the reason outliers are not deleted on sight: the largest orders of the
year are among the most important rows in the file. The top-right cell is the reason a rule about
distance is not enough: an error that lands among ordinary values is invisible to any rule that
only measures how far a value is from the rest.

So the work of this lesson has two halves. **Flagging** is statistics: decide what counts as far,
and list what is far. **Deciding** is everything else: for each flagged value, find out what
happened — from the row's other columns, from another file, from the person who knows — and then
choose between correcting it, keeping it, setting it aside for some questions, or marking it.

Three questions settle most cases, and they come from outside the number:

- **is it consistent with the rest of its own record?** A total that disagrees with its order lines
  is wrong whatever its size;
- **is there an explanation in the context?** A customer called a clinic, a date in mid-December, a
  product that only sells in bulk;
- **is it one value, or one of a pattern?** Twenty-three refunds are each ordinary and together
  impossible.

The sections that follow take one kind each, and the last one turns the decisions into numbers.
