---
title: The correlation matrix
version: 1
---

Lesson 6 measured how tightly two quantities move together with the **correlation**, *r*, between −1
and +1. With five quantities there are ten pairs, and a **correlation matrix** shows all of them at
once: one row and one column per variable, and in each cell the correlation of that pair.

```schooling-example
{"language": "python", "file": "corr.py", "parts": [{"code": "import csv\nimport numpy as np\n"}, {"code": "columns = [\"km\", \"items\", \"rain\", \"basket\", \"minutes\"]\nwith open(\"deliveries.csv\") as f:\n    rows = list(csv.DictReader(f))\ndata = np.array([[float(r[c]) for c in columns] for r in rows])\n", "note": "Read the five numeric columns of every delivery into one table of 400 rows and 5 columns."}, {"code": "matrix = np.corrcoef(data, rowvar=False)\nprint(\" \" * 8 + \"\".join(f\"{c:>8}\" for c in columns))\nfor name, values in zip(columns, matrix):\n    print(f\"{name:8}\" + \"\".join(f\"{v:8.2f}\" for v in values))\n", "note": "`corrcoef` with `rowvar=False` treats each column as a variable and returns the 5 by 5 matrix of correlations, printed here as a table."}]}
```

```
ana@vm:~/viz$ .venv/bin/python corr.py
              km   items    rain  basket minutes
km          1.00    0.05    0.03    0.04    0.88
items       0.05    1.00    0.06    0.95    0.23
rain        0.03    0.06    1.00    0.08    0.26
basket      0.04    0.95    0.08    1.00    0.21
minutes     0.88    0.23    0.26    0.21    1.00
```

Three features of every correlation matrix are visible here.

- **The diagonal is all 1.00.** Every variable correlates perfectly with itself, and those cells carry
  no information.
- **It is symmetric.** The correlation of km with minutes, 0.88, appears twice, above and below the
  diagonal. Half the matrix is a mirror of the other half.
- **Most of it is small.** Of the ten distinct pairs, two are strong: **items with basket, 0.95**,
  because more items cost more, and km with minutes, 0.88, from lesson 6. Rain and items each
  add a little to minutes, 0.26 and 0.23. Everything else is close to zero.

## Reading it with care

A correlation measures **a straight-line relationship** only. Two variables can be strongly related
along a curve and still show a correlation near zero, so a surprising cell is a reason to draw the
scatterplot of that pair, not a conclusion.

And the warning from lesson 6 applies cell by cell: **a strong correlation is not a cause**. With
many variables, some pairs will correlate by coincidence, and a matrix of fifty variables has 1,225
pairs to find coincidences in.
