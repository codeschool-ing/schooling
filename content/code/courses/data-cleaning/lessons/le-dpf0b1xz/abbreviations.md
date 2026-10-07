---
title: Abbreviations, and the step that needs a list
version: 1
---

**After trimming, normalising, repairing, lower-casing and removing accents, the cities are down to
eleven spellings, and no further general rule helps.** The cascade:

```
ana@lab:~/clean$ python cascade.py
as exported         28 distinct
spaces trimmed      25 distinct
Unicode to NFC      23 distinct
mojibake repaired   21 distinct
lower case          12 distinct
accents removed     11 distinct
['b. horizonte', 'belo horizonte', 'bh', 'campinas', 'curitiba', 'curitiba - pr', 'rio', 'rio de janeiro', 'rj', 's. paulo', 'sao paulo']
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l06-cascade\" aria-label=\"A bar chart of how many distinct values the city column holds after each cleaning step: as exported 28, spaces trimmed 25, Unicode to NFC 23, mojibake repaired 21, lower case 12, accents removed 11, abbreviations mapped 5. The largest single drop is lower case.\"><text x=\"190.0\" y=\"42.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">as exported</text><rect x=\"200.0\" y=\"30.0\" width=\"420.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">28</text><text x=\"190.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">spaces trimmed</text><rect x=\"200.0\" y=\"70.0\" width=\"375.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"581.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">25</text><text x=\"190.0\" y=\"122.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Unicode to NFC</text><rect x=\"200.0\" y=\"110.0\" width=\"345.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"551.0\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">23</text><text x=\"190.0\" y=\"162.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mojibake repaired</text><rect x=\"200.0\" y=\"150.0\" width=\"315.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"521.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">21</text><text x=\"190.0\" y=\"202.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lower case</text><rect x=\"200.0\" y=\"190.0\" width=\"180.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"386.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"190.0\" y=\"242.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">accents removed</text><rect x=\"200.0\" y=\"230.0\" width=\"165.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"371.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11</text><text x=\"190.0\" y=\"282.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">abbreviations mapped</text><rect x=\"200.0\" y=\"270.0\" width=\"75.0\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"281.0\" y=\"282.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text></svg>", "caption": "Twenty-eight spellings, five cities. The steps are cheap and general; only the last one needs a list somebody wrote."}
```

What is left is knowledge, not mechanics. `bh` is Belo Horizonte because people in Brazil say so;
`rj` is the state of Rio de Janeiro used as if it were the city; `rio` is short; `curitiba - pr` has
its state glued on; `s. paulo` and `b. horizonte` are abbreviated by hand. **No function knows that
`bh` means Belo Horizonte.** Somebody has to write it down:

```
ana@lab:~/clean$ cat abbreviations.csv
spelling,city
s. paulo,São Paulo
sao paulo,São Paulo
campinas,Campinas
rio de janeiro,Rio de Janeiro
rio,Rio de Janeiro
rj,Rio de Janeiro
belo horizonte,Belo Horizonte
b. horizonte,Belo Horizonte
bh,Belo Horizonte
curitiba,Curitiba
curitiba - pr,Curitiba
```

A file of eleven lines: every spelling that reaches this stage, and the city it means. Applied to the
cleaned keys:

```
ana@lab:~/clean$ python -c "import pandas as pd; from cascade import values; m = pd.read_csv('abbreviations.csv'); out = values.map(dict(zip(m['spelling'], m['city']))); print(out.value_counts(dropna=False).to_string())"
city
São Paulo         935
Rio de Janeiro    487
Belo Horizonte    337
Curitiba          318
Campinas          299
```

Five cities, every customer accounted for: no spelling fell outside the list. **That last check is
what makes a mapping trustworthy**: a spelling that is not in the list should come out as a blank,
and counting the blanks shows whether the list is complete. Here there are none. Next month a
customer will type `Sampa`, and the count will say so.

The list also does something the earlier steps could not: it gives each city **its correct display
form**, `São Paulo` with its accent and capitals, written once by a person instead of reconstructed
by a rule. Lesson 8 generalises this into the mapping tables that standardise categories, and lesson
14 attaches each city to its official IBGE code, which is what a join to any outside data needs.
