---
title: The dot product, by hand
version: 1
---

Lesson 1 scored articles with `D @ q` and read the result as *higher is closer*. That operation is
the **dot product**, and it is small enough to do on paper. Take two vectors of three numbers:

| | first | second | third |
|---|---|---|---|
| a | 2 | 1 | 2 |
| b | 1 | 2 | 2 |
| a × b | 2 | 2 | 4 |

Multiply them coordinate by coordinate and add the products: 2 + 2 + 4 = **8**. That is the whole
definition. For two vectors from all-MiniLM-L6-v2 it is 384 multiplications and one long sum.

```schooling-example
{
  "language": "python",
  "file": "dot.py",
  "parts": [
    {
      "code": "import numpy as np\n\na = np.array([2, 1, 2])\nb = np.array([1, 2, 2])",
      "note": "The two vectors from the table, as NumPy arrays."
    },
    {
      "code": "print(a * b)\nprint((a * b).sum())\nprint(a @ b)",
      "note": "The products coordinate by coordinate, their sum, and the same sum written with `@`, which is how the rest of the course writes it."
    },
    {
      "code": "print((2 * a) @ b)",
      "note": "The same dot product with `a` doubled."
    }
  ]
}
```

```
ana@lab:~/emb$ python dot.py
[2 2 4]
8
8
16
```

The sum is large when both vectors have large values **in the same coordinates with the same
sign**. A coordinate where one vector is positive and the other negative subtracts from it. So the
dot product rewards two arrows that lean the same way, which is what a score of meaning needs.

## The trap: length counts too

The last line doubled `a` and nothing else. Its direction is unchanged, so it leans towards `b`
exactly as much as before, and the score went from 8 to **16**. Every coordinate doubled, so every
product doubled, so the sum did.

**The dot product mixes two things: how well two arrows line up, and how long they are.** A
document whose vector happens to be long beats a better-aligned document whose vector is short. For
all-MiniLM-L6-v2 the problem never shows, because every vector it returns has length 1 and the
dot product is left measuring the alignment alone. Not every model does that, and the section
*Vectors that are not normalised* finds one that does not, ranking the wrong article first. The
next section removes the length from the score.
