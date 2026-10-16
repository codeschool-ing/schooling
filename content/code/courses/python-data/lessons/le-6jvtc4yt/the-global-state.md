---
title: The old way, and the global state it shares
version: 1
---

**Most code online seeds NumPy with `np.random.seed(42)` and draws with `np.random.rand()`.** That is
the interface NumPy had before 2019, and it still works. Its problem is that there is one hidden
generator for the whole program, and anything that draws from it moves it, including code you did
not write.

```python
np.random.seed(42)
np.random.randint(1, 7, size=5)
```

```
array([4, 5, 3, 5, 5])
```

Same seed, same five numbers, as with a Generator. Now the same two lines with a helper in between,
the kind of function a colleague might have written, which happens to shuffle something:

```python
def tidy(values):
    values = list(values)
    np.random.shuffle(values)
    return sorted(values)

np.random.seed(42)
tidy([3, 1, 2])
np.random.randint(1, 7, size=5)
```

```
array([5, 3, 5, 5, 2])
```

**Different numbers, from the same seed**, because `tidy` drew from the global generator before your
line did. Its own result was sorted, so its shuffle changed nothing you could see, except every
random number after it. Add a call, remove one, upgrade a library that draws internally, and every
"seeded" result downstream changes. Nothing reports it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Top: one global sequence from seed 42. Without the helper, your line takes the first five values. With the helper, the helper&#x27;s shuffle takes the first values and your line gets the next five, different ones. Bottom: your own generator from seed 42 is a separate sequence the helper never touches, so your line always takes its first five.\" data-fig=\"shared\"><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">np.random.seed(42): one sequence for the whole program</text><rect x=\"20\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"39\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"62\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"81\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v2</text><rect x=\"104\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"123\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v3</text><rect x=\"146\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"165\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v4</text><rect x=\"188\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"207\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v5</text><rect x=\"230\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"249\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v6</text><rect x=\"272\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"291\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v7</text><rect x=\"314\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"333\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v8</text><rect x=\"356\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"375\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v9</text><rect x=\"398\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"417\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v10</text><rect x=\"440\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"459\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v11</text><rect x=\"482\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"501\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v12</text><rect x=\"524\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"543\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v13</text><rect x=\"566\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v14</text><rect x=\"608\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"627\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v15</text><rect x=\"650\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"669\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v16</text><rect x=\"20\" y=\"76\" width=\"122\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"81.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tidy()</text><rect x=\"146\" y=\"76\" width=\"206\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"249.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">your five</text><text x=\"362\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">shifted by whatever drew first</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">rng = np.random.default_rng(42): yours alone</text><rect x=\"20\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"39\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w1</text><rect x=\"62\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"81\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w2</text><rect x=\"104\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"123\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w3</text><rect x=\"146\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"165\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w4</text><rect x=\"188\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"207\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w5</text><rect x=\"230\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"249\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w6</text><rect x=\"272\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"291\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w7</text><rect x=\"314\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"333\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w8</text><rect x=\"356\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"375\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w9</text><rect x=\"398\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"417\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w10</text><rect x=\"440\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"459\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w11</text><rect x=\"482\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"501\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w12</text><rect x=\"524\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"543\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w13</text><rect x=\"566\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w14</text><rect x=\"608\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"627\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w15</text><rect x=\"650\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"669\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w16</text><rect x=\"20\" y=\"188\" width=\"206\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"123.0\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">your five</text><text x=\"236\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same with or without tidy()</text></svg>", "caption": "Whoever draws first from a shared generator moves everybody's numbers."}
```

A Generator is immune, because nobody else holds it:

```python
rng = np.random.default_rng(42)
tidy([3, 1, 2])
rng.integers(1, 7, size=5), np.random.default_rng(42).integers(1, 7, size=5)
```

```
(array([1, 5, 4, 3, 3]), array([1, 5, 4, 3, 3]))
```

`tidy` still drew from the global generator; `rng` is a separate object, and its sequence is
untouched: its five numbers are the ones a fresh generator from the same seed draws, `tidy` or no
`tidy`. **Pass your generator to the functions that need randomness**, as an argument, instead of
letting them reach for a global one.

| old, global | new, a Generator |
|---|---|
| `np.random.seed(42)` | `rng = np.random.default_rng(42)` |
| `np.random.rand(3)` | `rng.random(3)` |
| `np.random.randint(1, 7, 5)` | `rng.integers(1, 7, 5)` |
| `np.random.normal(0, 1, 5)` | `rng.normal(0, 1, 5)` |
| `np.random.choice(a, 3)` | `rng.choice(a, 3)` |

The two give **different numbers for the same seed**: they use different algorithms underneath. Code
moved from one column to the other keeps its behaviour and changes its results, once, which is worth
saying in the commit that does it.
