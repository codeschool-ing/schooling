---
title: Writing through an index, and the write that vanishes
version: 1
---

**Assigning to an index changes the array in place: `rain[rain < 0.5] = 0` sets every small reading
to zero in `rain` itself.** That is one of the most useful lines in NumPy. Its trap is one step to
the side: assigning to the result of an index, rather than through it, changes a copy that is
immediately thrown away.

Work on a copy of the rain, so the original stays as the file has it:

```python
r = rain.copy()
r[r < 0.5] = 0.0
(r == 0).sum(), (rain == 0).sum()
```

```
(np.int64(197), np.int64(192))
```

`r[r < 0.5] = 0.0` reads as "where `r` is under half a millimetre, set it to zero". Five readings
were above zero and under half a millimetre, so `r` has five more zeros than `rain`. The six `nan` are untouched, because
`nan < 0.5` is `False`.

The same mechanism fills the missing days, if you have decided what to fill them with:

```python
r[np.isnan(r)] = 0.0
np.isnan(r).sum(), r.sum().round(1)
```

```
(np.int64(0), np.float64(1711.5))
```

## Two indexes in a row

Now the trap. Set the heavy-rain days of the first quarter to a cap of 30 millimetres, written as
two selections, one after the other:

```python
r2 = rain.copy()
r2[:90][r2[:90] > 30] = 30.0
r2[:90].max()
```

```
np.float64(30.0)
```

That worked: `r2[:90]` is a **slice**, a view, so the assignment through the mask wrote into `r2`'s
own bytes. Now the same idea with the first selection made by a mask, the heavy days, followed by a
slice of them:

```python
r3 = rain.copy()
r3[r3 > 20][:3] = 0.0
np.nanmax(r3[:90]), (r3 > 20).sum()
```

```
(np.float64(45.9), np.int64(20))
```

**Nothing changed.** `r3[r3 > 20]` is a **copy**, as the last section said, and `[:3] = 0.0` wrote
into that copy, which nobody kept. No error, no warning: the code reads like an assignment and is
not one. The rule that avoids it is to **index once, with everything, on the left of `=`**: one set of
brackets on the array you mean to change.

pandas met exactly this problem and spent years warning about it as `SettingWithCopyWarning`;
pandas 3 changed the rules so that the second form never writes. Lesson 11 is that story.
