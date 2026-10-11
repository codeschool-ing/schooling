---
title: Two Series line up by label, not by position
version: 1
---

**When two Series meet in arithmetic, pandas matches their elements by label first and computes
second.** NumPy matched by position, and lesson 6 showed what happens when the positions mean
different things. pandas cannot make that mistake. It makes a different one, which this section is
about.

Two small Series, the docks at three stations each, in different orders and not quite the same
stations:

```python
docks = pd.Series({"S01": 14, "S02": 20, "S03": 12})
added = pd.Series({"S03": 4, "S01": 2, "S04": 6})
docks + added
```

```
S01    16.0
S02     NaN
S03    16.0
S04     NaN
dtype: float64
```

`S01` got its 2 and `S03` its 4, although they were in different positions, because the labels
matched. **`S02` and `S04` became `NaN`**: each label is present in only one Series, so there is
nothing to add it to, and pandas says "not known" rather than guessing. The result's index is the
union of the two, sorted. And the dtype became `float64`, because `NaN` is a float, the same reason
lesson 4 gave for NumPy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Left: docks with labels S01 14, S02 20, S03 12. Middle: added with labels S03 4, S01 2, S04 6, in another order. Right: docks + added, matched by label: S01 16, S02 NaN, S03 16, S04 NaN. Lines join equal labels across the two inputs; S02 and S04 have no partner.\" data-fig=\"align\"><text x=\"80\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">docks</text><rect x=\"20\" y=\"40\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S01</text><rect x=\"80\" y=\"40\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">14</text><rect x=\"20\" y=\"80\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S02</text><rect x=\"80\" y=\"80\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">20</text><rect x=\"20\" y=\"120\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S03</text><rect x=\"80\" y=\"120\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"320\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">added</text><rect x=\"260\" y=\"40\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S03</text><rect x=\"320\" y=\"40\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"260\" y=\"80\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S01</text><rect x=\"320\" y=\"80\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"260\" y=\"120\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S04</text><rect x=\"320\" y=\"120\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"620\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">docks + added</text><rect x=\"560\" y=\"40\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S01</text><rect x=\"620\" y=\"40\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"650\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">16.0</text><rect x=\"560\" y=\"80\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S02</text><rect x=\"620\" y=\"80\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"650\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">NaN</text><rect x=\"560\" y=\"120\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S03</text><rect x=\"620\" y=\"120\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"650\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">16.0</text><rect x=\"560\" y=\"160\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S04</text><rect x=\"620\" y=\"160\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"650\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">NaN</text><line x1=\"144\" y1=\"55\" x2=\"256\" y2=\"95\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"144\" y1=\"135\" x2=\"256\" y2=\"55\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"200\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">S02: no partner</text><text x=\"320\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">S04: no partner</text></svg>", "caption": "pandas matches labels before it adds. A label on one side only gives NaN."}
```

When a missing label should count as zero, say so:

```python
docks.add(added, fill_value=0)
```

```
S01    16.0
S02    20.0
S03    16.0
S04     6.0
dtype: float64
```

`add` is the method behind `+`, and its `fill_value` is the value a missing side takes. `sub`,
`mul` and `div` have the same argument.

## The trap is the opposite of NumPy's

The alignment is so reliable that people stop thinking about it, and then step outside it by
accident. `.to_numpy()` and `.values` throw the index away. Arithmetic on what they return is
NumPy's, by position:

```python
docks.to_numpy() + added.to_numpy()
```

```
array([18, 22, 18])
```

Three numbers, all wrong: `S01`'s 14 plus `S03`'s 4, and so on. No `NaN`, nothing to warn you.
**Inside pandas, labels decide; the moment you take `.to_numpy()`, positions decide.** Take it when
you need it, at the end, and not in the middle of arithmetic.
