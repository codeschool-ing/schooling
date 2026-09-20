---
title: Excel, where the trouble is never arithmetic
version: 1
---

Excel's model is two sentences. **A cell holds a value.** **A formula is a value computed from
other cells**, and it recomputes whenever one of them changes.

That is the whole engine, and it is not where the difficulty is. The difficulty is that **Excel
decides what kind of thing you typed at the moment you press Enter**, from the shape of the
characters, silently, and it is sometimes wrong.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four rows, each showing something typed into a cell, what the program decides it is, and what the cell then shows. Zero one two three four becomes a number and shows as one two three four. Three slash four becomes a date and shows as a date. One E five becomes a number and shows as one hundred thousand. Below a rule, the same first entry preceded by an apostrophe becomes text and shows exactly as it was typed.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">What the cell decides, the moment you press Enter</text><text x=\"60\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what you type</text><text x=\"290\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it decides it is</text><text x=\"520\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the cell then shows</text><rect x=\"48\" y=\"64\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"60\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">01234</text><path d=\"M206 80 L278 80 M270 75 L278 80 L270 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><text x=\"290\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a number</text><path d=\"M436 80 L508 80 M500 75 L508 80 L500 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><rect x=\"508\" y=\"64\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"520\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">1234</text><rect x=\"48\" y=\"108\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"60\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">3/4</text><path d=\"M206 124 L278 124 M270 119 L278 124 L270 129\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><text x=\"290\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a date</text><path d=\"M436 124 L508 124 M500 119 L508 124 L500 129\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><rect x=\"508\" y=\"108\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"520\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">3-Apr</text><rect x=\"48\" y=\"152\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"60\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1E5</text><path d=\"M206 168 L278 168 M270 163 L278 168 L270 173\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><text x=\"290\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a number</text><path d=\"M436 168 L508 168 M500 163 L508 168 L500 173\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><rect x=\"508\" y=\"152\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"520\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">100000</text><path d=\"M48 206 L672 206\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"48\" y=\"220\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"60\" y=\"236\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">'01234</text><path d=\"M206 236 L278 236 M270 231 L278 236 L270 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><text x=\"290\" y=\"236\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">text</text><path d=\"M436 236 L508 236 M500 231 L508 236 L500 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><rect x=\"508\" y=\"220\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"520\" y=\"236\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">01234</text><text x=\"24\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nothing warns you. The entry is accepted, the cell looks reasonable, and the value is not what you typed.</text></svg>", "caption": "The apostrophe is the whole fix, and it does not appear in the cell. Formatting the column as text beforehand does the same job for a whole column."}
```

## The four types, and how to tell them apart

| | what it is | how you can tell |
|---|---|---|
| **number** | a quantity | sits on the right of the cell by default |
| **text** | characters | sits on the left |
| **date and time** | a number of days since 1900, dressed up | right, and it does arithmetic you did not expect |
| **boolean** | `TRUE` or `FALSE` | centred |

**Alignment is the free diagnostic.** A column of numbers with one entry hugging the left edge is
a column with one piece of text in it, and every `SUM` down that column is quietly missing a row.

## The two that ruin real work

**Leading zeros disappear.** Postcodes, product codes, account numbers, anything where `007` and
`7` are different things. Excel sees a number and a number has no leading zeros.

**Things that look like dates become dates.** `3/4` is April. `1-2` is a date. A gene called
`SEP2` becomes September. A measurement written `2-3` becomes the third of February and cannot be
turned back, because **the original characters are gone** — the cell holds a day number now.

The second half of that sentence is the part that matters. Converting the column back to text
afterwards gives you `45016`, not `2-3`. **There is no undo once the file is saved**, which is why
this is a lesson about what to do beforehand.

## Doing it beforehand

- **Format the column as Text before typing anything into it.** The whole column, once, and every
  entry is kept as characters.
- **A leading apostrophe** — `'01234` — does the same for one cell. The apostrophe is not stored
  and not shown.
- **When importing a CSV, use the import dialogue rather than double-clicking the file.** It lets
  you mark each column's type, and double-clicking does not ask.

That last one is the one that saves whole afternoons. A CSV opened by double-click is a CSV
where every guess has already been made.

## And the thing that is genuinely a number and looks wrong

`0.1 + 0.2` does not give exactly `0.3` in any spreadsheet, because the machine stores fractions
in binary and a tenth is not exact in binary — the same reason a third is not exact in decimal.

Excel hides this by rounding the display, and it surfaces when a total that should be zero shows
as `-0.000000000000001`. It is not a bug and there is one fix: **`ROUND` the result** at the
point where a person reads it, rather than trusting the comparison.
