---
title: The store ranking, computed
version: 1
---

Helena's proposal rests on one ranking: Contagem sells the most, so it is the best store, so it
deserves more floor. **The ranking is right and the conclusion does not follow from it**, because a
store that sells the most may only be the store with the most space. The way to find out is to
divide, and it takes one column in the sheet you started in lesson 1.

## The table

Add a new sheet to your file. Type the nine stores with their 2025 sales, in thousands of reais, and
their sales floor in square metres. The online shop is left out this time: it has no floor to
enlarge.

| | A | B | C |
|---|---|---|---|
| 1 | Store | Sales | Floor |
| 2 | Savassi | 11880 | 1800 |
| 3 | Pampulha | 10560 | 2400 |
| 4 | Contagem | 12480 | 3200 |
| 5 | Betim | 8840 | 2600 |
| 6 | Nova Lima | 9450 | 1500 |
| 7 | Sete Lagoas | 6720 | 2100 |
| 8 | Divinópolis | 6460 | 1900 |
| 9 | Ipatinga | 7040 | 2200 |
| 10 | Juiz de Fora | 8960 | 2800 |

## Sales per square metre

In D1 type `Per m2`. Sales are in thousands, so multiply by 1,000 to get reais, divide by the floor,
and round to whole reais. In D2:

```localised
=ROUND(B2*1000/C2,0)      6600
```

Copy D2 down to D10. Savassi sells **R$ 6,600 a year for each square metre** of its floor. Your
column should read 6600, 4400, 3900, 3400, 6300, 3200, 3400, 3200, 3200.

Then a total row, so that each store has something to be compared with. In A11 type `Total`, and:

```localised
B11   =SUM(B2:B10)      82390
C11   =SUM(C2:C10)      20500
D11   =ROUND(B11*1000/C11,0)      4019
```

The nine stores sold R$ 82.39 million on 20,500 square metres, an average of **R$ 4,019 per square
metre**. Notice that D11 divides the two totals; it does not average the nine values above it.
Averaging them would give each store the same weight whatever its size, which is a different number
and the wrong one here.

## Two rankings of the same stores

Sort the table by column B, largest first, and then by column D. In LibreOffice and Excel select
A1:D10 and use **Data → Sort**; in Google Sheets, **Data → Sort range**. The two orders:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 430\" role=\"img\" aria-label=\"Two ranked lists of the nine stores joined by lines. Left, by 2025 sales: Contagem first, then Savassi, Pampulha, Nova Lima, Juiz de Fora, Betim, Ipatinga, Sete Lagoas, Divinópolis. Right, by sales per square metre: Savassi 6,600, Nova Lima 6,300, Pampulha 4,400, Contagem 3,900, Betim and Divinópolis 3,400, Juiz de Fora, Ipatinga and Sete Lagoas 3,200. The line from Contagem falls from first to fourth; the line from Nova Lima rises from fourth to second.\" data-fig=\"l02-ranking\"><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">by sales, R$ thousand</text><text x=\"440.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">by sales per m², R$</text><path d=\"M282.0 92.0 L438.0 200.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M282.0 128.0 L438.0 92.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 164.0 L438.0 164.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 200.0 L438.0 128.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M282.0 236.0 L438.0 308.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 272.0 L438.0 236.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 308.0 L438.0 344.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 344.0 L438.0 380.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 380.0 L438.0 272.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"40.0\" y=\"78.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"97.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1</text><text x=\"74.0\" y=\"97.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Contagem</text><text x=\"270.0\" y=\"97.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">12,480</text><rect x=\"40.0\" y=\"114.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"133.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2</text><text x=\"74.0\" y=\"133.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Savassi</text><text x=\"270.0\" y=\"133.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">11,880</text><rect x=\"40.0\" y=\"150.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"169.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3</text><text x=\"74.0\" y=\"169.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Pampulha</text><text x=\"270.0\" y=\"169.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">10,560</text><rect x=\"40.0\" y=\"186.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"205.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4</text><text x=\"74.0\" y=\"205.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Nova Lima</text><text x=\"270.0\" y=\"205.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">9,450</text><rect x=\"40.0\" y=\"222.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"241.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">5</text><text x=\"74.0\" y=\"241.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Juiz de Fora</text><text x=\"270.0\" y=\"241.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8,960</text><rect x=\"40.0\" y=\"258.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"277.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6</text><text x=\"74.0\" y=\"277.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Betim</text><text x=\"270.0\" y=\"277.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8,840</text><rect x=\"40.0\" y=\"294.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"313.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">7</text><text x=\"74.0\" y=\"313.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Ipatinga</text><text x=\"270.0\" y=\"313.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">7,040</text><rect x=\"40.0\" y=\"330.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"349.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8</text><text x=\"74.0\" y=\"349.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Sete Lagoas</text><text x=\"270.0\" y=\"349.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6,720</text><rect x=\"40.0\" y=\"366.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"385.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">9</text><text x=\"74.0\" y=\"385.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Divinópolis</text><text x=\"270.0\" y=\"385.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6,460</text><rect x=\"440.0\" y=\"78.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"97.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1</text><text x=\"474.0\" y=\"97.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Savassi</text><text x=\"670.0\" y=\"97.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6,600</text><rect x=\"440.0\" y=\"114.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"133.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2</text><text x=\"474.0\" y=\"133.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Nova Lima</text><text x=\"670.0\" y=\"133.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6,300</text><rect x=\"440.0\" y=\"150.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"169.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3</text><text x=\"474.0\" y=\"169.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Pampulha</text><text x=\"670.0\" y=\"169.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4,400</text><rect x=\"440.0\" y=\"186.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"205.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4</text><text x=\"474.0\" y=\"205.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Contagem</text><text x=\"670.0\" y=\"205.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3,900</text><rect x=\"440.0\" y=\"222.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"241.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">5</text><text x=\"474.0\" y=\"241.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Betim</text><text x=\"670.0\" y=\"241.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3,400</text><rect x=\"440.0\" y=\"258.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"277.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6</text><text x=\"474.0\" y=\"277.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Divinópolis</text><text x=\"670.0\" y=\"277.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3,400</text><rect x=\"440.0\" y=\"294.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"313.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">7</text><text x=\"474.0\" y=\"313.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Juiz de Fora</text><text x=\"670.0\" y=\"313.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3,200</text><rect x=\"440.0\" y=\"330.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"349.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8</text><text x=\"474.0\" y=\"349.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Ipatinga</text><text x=\"670.0\" y=\"349.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3,200</text><rect x=\"440.0\" y=\"366.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"385.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">9</text><text x=\"474.0\" y=\"385.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Sete Lagoas</text><text x=\"670.0\" y=\"385.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3,200</text><text x=\"360.0\" y=\"418.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">same stores, same year: the question decides the order</text></svg>", "caption": "The nine stores ranked twice. Contagem sells the most because it is the largest; per square metre it is fourth, selling 59% of what Savassi sells on each metre."}
```

**Contagem drops from first to fourth.** It has 1.8 times Savassi's floor and sells 1.05 times as
much, so each of its square metres sells 59% of what one of Savassi's does:

```localised
=ROUND(D4/D2*100,0)      59
```

Nova Lima, the smallest store, rises from fourth to second. Three stores tie at the bottom on R$ 3,200
and two above them on R$ 3,400; the sort puts them in whatever order it found them, and a report
should say they are level rather than rank one above the other.

Against the chain's R$ 4,019, Contagem's R$ 3,900 sits just under the average. It is the largest
store, with 15.6% of the chain's floor and 15.1% of the stores' sales, which is almost exactly what
its size alone would predict.

## What the ranking says to Helena

It does not say Contagem is a bad store. It says **"Contagem sells the most" is mostly a statement
about its size**, and that if Varanda wants each new square metre to sell as much as possible, the
stores that already sell the most per metre are the stronger candidates. That is what Lívia sent:
the table, the two orders and three sentences, with the caveat the next section explains — that
sales per square metre is an average, and the next metre built is not an average one.

Helena asked for Savassi and Nova Lima to be costed next to Contagem. That is the cycle of lesson 1
doing its work: the answer did not make the decision, it changed which options were on the table.
