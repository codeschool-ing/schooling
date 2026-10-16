---
title: Reading the error
version: 1
---

**The broadcasting error names both shapes, and the shapes are the whole diagnosis.** It is the
error you will meet most in NumPy and the easiest to fix, once you read it as the rule failing
rather than as something mysterious.

Subtract each week's mean from its days, the natural way, without `keepdims`:

```python
weekly_flat = weeks.mean(axis=1)
weeks - weekly_flat
```

```
ValueError: operands could not be broadcast together with shapes (52,7) (52,) 
```

Line the shapes up from the right, as the rule says: `(52, 7)` against `(52,)`. The rightmost pair
is `7` and `52`: neither equal nor 1. **NumPy does not try the other alignment.** It never guesses
that you meant the 52 to go with the 52; it only ever aligns from the right, and that is why the
same subtraction works with `(52, 1)`.

The trailing space after `(52,)` in the message is NumPy's, by the way, not a typo in this course.

## Three questions that fix it

Every broadcasting error is answered by these, in this order:

1. **What are the two shapes?** The message says. If it does not, ask each array for `.shape`.
2. **Which axis is meant to match?** Here, the 52 weeks.
3. **Is that axis on the right of both?** Here, no: it is the left axis of `weeks` and the only
   axis of `weekly_flat`. Give `weekly_flat` a length-1 axis on its right, and the 52 moves left
   where it belongs. The next section is how.

The same error appears in pandas, from lesson 9 on, whenever a calculation drops to NumPy, and the
same three questions answer it there.

A related one, which is not broadcasting at all, is the shape mismatch of a matrix product:

```python
weeks @ by_position[:5]
```

```
ValueError: matmul: Input operand 1 has a mismatch in its core dimension 0, with gufunc signature (n?,k),(k,m?)->(n?,m?) (size 5 is different from 7)
```

`@` is matrix multiplication, which needs the inner lengths to agree, `7` and `5` here. Elementwise
operators broadcast; `@` does linear algebra. The message says `matmul` so that you can tell them
apart.
