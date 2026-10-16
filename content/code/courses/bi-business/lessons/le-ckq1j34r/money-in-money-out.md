---
title: Money in, money out
version: 1
---

An organisation chart shows a company as boxes of people: finance, marketing, operations, human
resources. **It is more useful to an analyst as flows: money coming in from customers, going out to
suppliers, staff and everything else, and what is left over.** Every number a BI analyst reports
measures one of those flows, or something that drives one, and knowing which tells you who cares
about it and why.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 440\" role=\"img\" aria-label=\"Varanda as flows of money and goods. In the centre, the company. Customers pay money in at the top, R$ 98.0 million of sales in 2025. Money flows out to suppliers for the goods, R$ 55.4 million, to people for their work, R$ 18.8 million, and to rent, marketing, the warehouse and other costs, R$ 21.0 million. What is left is the operating profit, R$ 2.9 million. Around the company, the four functions and what each decides: marketing brings customers in, operations buys, stores and delivers the goods, people hires and keeps the staff, finance counts all of it and decides where money goes.\" data-fig=\"l05-flows\"><rect x=\"250.0\" y=\"160.0\" width=\"220.0\" height=\"110.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Varanda</text><text x=\"360.0\" y=\"220.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">operating profit</text><text x=\"360.0\" y=\"242.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">R$ 2.9 million</text><rect x=\"250.0\" y=\"20.0\" width=\"220.0\" height=\"60.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"46.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">customers</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pay R$ 98.0 million</text><path d=\"M360.0 82.0 L360.0 158.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><path d=\"M360.0 158.0 L356.1 149.9 L363.9 149.9 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"30.0\" y=\"350.0\" width=\"200.0\" height=\"60.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"376.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">suppliers</text><text x=\"130.0\" y=\"396.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">goods: R$ 55.4 million</text><path d=\"M279.5 272.0 L130.0 348.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M130.0 348.0 L135.5 340.8 L139.0 347.8 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"260.0\" y=\"350.0\" width=\"200.0\" height=\"60.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"376.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">staff</text><text x=\"360.0\" y=\"396.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pay: R$ 18.8 million</text><path d=\"M360.0 272.0 L360.0 348.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M360.0 348.0 L356.1 339.9 L363.9 339.9 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"490.0\" y=\"350.0\" width=\"200.0\" height=\"60.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"376.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">everything else</text><text x=\"590.0\" y=\"396.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">R$ 21.0 million</text><path d=\"M440.5 272.0 L590.0 348.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M590.0 348.0 L581.0 347.8 L584.5 340.8 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"16.0\" y=\"120.0\" width=\"210.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"121.0\" y=\"146.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">marketing</text><text x=\"121.0\" y=\"166.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">brings customers in</text><rect x=\"16.0\" y=\"220.0\" width=\"210.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"121.0\" y=\"246.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">operations</text><text x=\"121.0\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">buys, stores, delivers</text><rect x=\"494.0\" y=\"120.0\" width=\"210.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"599.0\" y=\"146.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">finance</text><text x=\"599.0\" y=\"166.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">counts, decides spend</text><rect x=\"494.0\" y=\"220.0\" width=\"210.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"599.0\" y=\"246.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">people</text><text x=\"599.0\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">hires and keeps staff</text><text x=\"360.0\" y=\"434.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">money comes in at the top and goes out at the bottom</text></svg>", "caption": "Varanda's 2025 as money in and money out. Of every R$ 100 customers paid, R$ 2.92 was left as operating profit; the four functions decide how the rest is spent."}
```

## The flows at Varanda, 2025

**Customers paid R$ 98.0 million**, the year's sales from lesson 1. Most of it went straight back out.
R$ 55.4 million paid the suppliers for the furniture, plants and kitchenware that were sold. R$ 18.8
million paid the 410 people who work there. R$ 21.0 million went on everything else: rent and running
the nine stores, marketing, the warehouse in Contagem and its trucks, and the smaller costs every
company has. **What was left was R$ 2.9 million of operating profit, or R$ 2.92 of every R$ 100 a
customer paid.**

That small number is the first thing a new analyst should absorb about retail. A 5% rise in the
cost of goods, with prices unchanged, would cost R$ 2.77 million, nearly all of the R$ 2.86 million
of profit. **In a business with thin margins, small changes in large flows decide the year**, which is why
so many of the questions an analyst receives are about costs that look minor next to sales.

## Four functions, four kinds of decision

Each function exists to manage some of the flows, and each makes a different kind of decision:

| function | the flows it manages | the decisions it makes | who leads it at Varanda |
|---|---|---|---|
| finance | all of them, as numbers | where money goes, what is approved, when bills are paid | Otávio Lins |
| marketing and sales | customers coming in | which customers to reach, how, and at what price | Renata Sá |
| operations | goods coming in and going out | what to buy, how much stock to hold, how to deliver | Caio Barreto |
| people | the staff, the largest single cost after the goods | whom to hire, how to pay, how to keep them | Sônia Freitas |

The CEO, Helena, decides across all four, and so does the board above her. The remaining sections
take one function each: what it measures, what its numbers mean, and what usually goes wrong with
them.

## Why an analyst needs this map

**The same number means different things to different functions.** A rise in stock is a risk to
finance (money tied up), a relief to operations (fewer empty shelves) and a promise to marketing
(something to promote). An analyst who reports "stock rose 12%" without knowing who is reading has
answered nobody's question. The map also says where to look when a number moves: profit fell, so did
less money come in, or did more go out, and through which flow?

Lesson 6 starts the analysis itself with the simplest of those questions, what happened, and this
lesson's numbers are the vocabulary it uses.
