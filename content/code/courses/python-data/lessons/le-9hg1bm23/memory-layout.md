---
title: How an array sits in memory
version: 1
---

**An array is one block of bytes plus a description of how to read it.** The block is flat: memory
has no rows and columns. The description, the shape, the dtype and the **strides**, is what turns
it into a table. Seeing that split explains why some operations cost nothing and others copy
everything.

Take the 4 × 6 table of hours from two sections ago:

```python
hours = np.arange(24).reshape(4, 6)
hours.strides, hours.flags["C_CONTIGUOUS"]
```

```
((48, 8), True)
```

`strides` says how many bytes to jump to move one step along each axis. Moving along a row, to the
next column, is 8 bytes: one `int64`. Moving down a column, to the next row, is 48 bytes: a whole
row of six. The block holds row 0, then row 1, then row 2, end to end, which NumPy calls **C
order**, after the language that lays out its arrays the same way.

@@figure:strides@@

## A transpose moves nothing

`hours.T` swaps rows and columns. It does that by swapping the strides, not the numbers:

```python
flipped = hours.T
flipped.shape, flipped.strides, flipped.flags["C_CONTIGUOUS"]
```

```
((6, 4), (8, 48), False)
```

Same 24 numbers in the same bytes, now read with 8 bytes to the next row and 48 to the next column.
It took no time and no memory, whatever the size of the array. What it gave up is contiguity: the
transposed array is not stored row after row any more, and an operation that needs its rows laid
end to end will make a copy first. `np.ascontiguousarray` makes that copy on purpose when you want
to pay for it once.

## Why it matters in practice

- **Reading along the last axis is fastest.** The numbers are next to each other, so the
  processor's cache brings in the following ones for free. Summing each row of a large C-order
  array is faster than summing each column, with the same result.
- **`reshape` of a contiguous array is free**, because a new shape is only new strides over the same
  block. The `-1` in `reshape(-1, 6)` asks NumPy to work out that axis from the size.
- **Some operations need a copy and make one without asking.** `ravel` returns the flat block when
  it can and a copy when the order does not allow it; `flatten` always copies. The next section is
  how to tell which you got, because it decides whether a change you make shows up elsewhere.
