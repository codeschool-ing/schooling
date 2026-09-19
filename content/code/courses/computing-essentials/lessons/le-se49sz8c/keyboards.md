---
title: Keyboards, and the one that can type your own language
version: 1
---

A keyboard is a grid of switches and a table that says which switch means which character. Both
halves can be wrong independently, which is why "my keyboard types the wrong letters" is two
different problems with two different fixes.

## Layout is software, and the printing on the keys is not

The **physical layout** is the shape: how many keys, where the enter key is, whether there is a
numeric pad. The **logical layout** is the table the operating system uses to turn key number 41
into a character. They are set separately, and nothing forces them to agree.

So there are two distinct faults:

- **The printing and the output disagree.** You press `ç` and get `;`. The physical keyboard is
  Brazilian and the operating system has been told it is American. Fix it in the system settings,
  not by buying anything.
- **The character is not on the keyboard at all.** A US-layout keyboard has no `ç` key. No
  setting adds one; the layout gives you a way to compose it instead.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two rows of four keys each, drawn as squares, comparing the right-hand end of the home row. The upper row is labelled ABNT2 and its keys read L, C-cedilla, tilde and circumflex, and acute and grave. The lower row is labelled US and the same four positions read L, semicolon, apostrophe, and opening square bracket. Notes to the right say that ABNT2 has a C-cedilla key of its own and a dedicated key for the tilde and circumflex, and that US has no C-cedilla at all so you type apostrophe then c.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The right-hand end of the home row, where the two layouts part company</text><text x=\"24\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">ABNT2</text><rect x=\"120\" y=\"60\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"146\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">L</text><rect x=\"180\" y=\"60\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">Ç</text><rect x=\"240\" y=\"60\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"266\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">~ ^</text><rect x=\"300\" y=\"60\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"326\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">´ `</text><text x=\"24\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">US</text><rect x=\"120\" y=\"150\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"146\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">L</text><rect x=\"180\" y=\"150\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">;</text><rect x=\"240\" y=\"150\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"266\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">'</text><rect x=\"300\" y=\"150\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"326\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">[</text><text x=\"400\" y=\"72\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">One key for the cedilla,</text><text x=\"400\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one for the tilde and circumflex,</text><text x=\"400\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one for the acute and grave.</text><text x=\"400\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">No cedilla anywhere.</text><text x=\"400\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">On the international variant you</text><text x=\"400\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">compose it from two presses.</text><path d=\"M24 226 L696 226\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"24\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The keys are in the same places. What each one produces is a table, and the table is a setting.</text></svg>", "caption": "Four key positions, two tables. Everything that makes a Brazilian keyboard Brazilian is in this corner of it."}
```

## ABNT2, which is the one to buy here

`ABNT2` is the Brazilian standard, and what it gives you over a US layout is worth naming:

- a **`ç` key** of its own, where the American layout has `;`;
- **dead keys** for the acute, grave, tilde and circumflex — press the accent, then the vowel,
  and you get `á`, `à`, `ã`, `â`;
- **twelve keys** in the bottom row instead of eleven, the extra one sitting left of the right
  shift;
- **`R$`** printed and produced, and a `/` on the numeric pad where an American keyboard does not
  have one.

The US-International layout composes the same accents from the apostrophe and quote keys, which
works and is slower, and has one famous side effect: typing an apostrophe before a vowel
silently becomes an accented vowel, so `don't` needs a space after the apostrophe to come out
right.

## Membrane, mechanical, and what actually differs

- **Membrane** — a rubber sheet under the keys closes a circuit. Cheap, quiet, mushy, and what
  almost every keyboard sold is.
- **Mechanical** — one switch per key. Longer life, a definite point where the key registers,
  and louder unless the switches are chosen not to be.
- **Scissor** — the flat kind on laptops and on slim desktop keyboards. Short travel, stable,
  and not repairable when one key fails.

Mechanical is genuinely nicer to type on for hours and is genuinely not a productivity
improvement. Buy it because your hands like it.

## Two features that are not marketing

**N-key rollover** is how many keys can be held at once and still all register. A cheap keyboard
loses the third or fourth simultaneous press. It matters for games and for anybody who types
fast enough to overlap keys.

**Anti-ghosting** is the same problem stated the other way: pressing three keys producing a
fourth you never touched. If a keyboard claims one of these and not the other, it is claiming the
easy half.
