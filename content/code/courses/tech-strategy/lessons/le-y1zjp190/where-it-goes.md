---
title: Where the money goes
version: 1
---

Ask an engineer what engineering costs and the answer is usually the cloud bill. It is the one
invoice with the department's name on it, it arrives every month, and it has a number on it big
enough to worry about. **It is also a small part of the money.** The largest cost of an engineering
organisation never arrives as an invoice, so the people closest to it rarely see it as a cost at all.

This section puts Coreto's year on one sheet, so the rest of the lesson argues from the whole
budget rather than from the line that happens to be visible.

## Four lines

Otávio Lins, Coreto's CFO, keeps the engineering budget in four lines. Every amount below is for a
year.

| line | what is in it | amount | share |
|---|---|---|---|
| People | 52 engineers at the loaded cost from lesson 1 | R$ 13,728,000 | 79.0% |
| Cloud | the provider's bill, R$ 212,000 a month | R$ 2,544,000 | 14.6% |
| Licences and SaaS | subscriptions paid per seat or per use, R$ 61,000 a month | R$ 732,000 | 4.2% |
| Tooling | things bought outright: build machines, the test devices Mobile needs, the year's one-off purchases | R$ 380,000 | 2.2% |
| **total** | | **R$ 17,384,000** | |

The people line is arithmetic you already have. An engineer-hour costs R$ 150 loaded, an
engineer-year is 1,760 working hours, so one engineer costs **R$ 264,000 a year**, and 52 of them
cost R$ 13,728,000.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l11-budget\" aria-label=\"One horizontal bar for Coreto's engineering budget of R$ 17,384,000 a year. People take 79.0% of it, drawn as 52 blocks, one per engineer at R$ 264,000 each. Cloud takes 14.6%, licences and SaaS 4.2% and tooling 2.2%, the last two thin slivers at the right-hand end.\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Coreto's engineering budget for one year: R$ 17,384,000</text><rect x=\"20.0\" y=\"74.0\" width=\"537.2\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><path d=\"M30.3 75 L30.3 123 M40.7 75 L40.7 123 M51.0 75 L51.0 123 M61.3 75 L61.3 123 M71.7 75 L71.7 123 M82.0 75 L82.0 123 M92.3 75 L92.3 123 M102.6 75 L102.6 123 M113.0 75 L113.0 123 M123.3 75 L123.3 123 M133.6 75 L133.6 123 M144.0 75 L144.0 123 M154.3 75 L154.3 123 M164.6 75 L164.6 123 M175.0 75 L175.0 123 M185.3 75 L185.3 123 M195.6 75 L195.6 123 M206.0 75 L206.0 123 M216.3 75 L216.3 123 M226.6 75 L226.6 123 M236.9 75 L236.9 123 M247.3 75 L247.3 123 M257.6 75 L257.6 123 M267.9 75 L267.9 123 M278.3 75 L278.3 123 M288.6 75 L288.6 123 M298.9 75 L298.9 123 M309.3 75 L309.3 123 M319.6 75 L319.6 123 M329.9 75 L329.9 123 M340.3 75 L340.3 123 M350.6 75 L350.6 123 M360.9 75 L360.9 123 M371.2 75 L371.2 123 M381.6 75 L381.6 123 M391.9 75 L391.9 123 M402.2 75 L402.2 123 M412.6 75 L412.6 123 M422.9 75 L422.9 123 M433.2 75 L433.2 123 M443.6 75 L443.6 123 M453.9 75 L453.9 123 M464.2 75 L464.2 123 M474.6 75 L474.6 123 M484.9 75 L484.9 123 M495.2 75 L495.2 123 M505.5 75 L505.5 123 M515.9 75 L515.9 123 M526.2 75 L526.2 123 M536.5 75 L536.5 123 M546.9 75 L546.9 123\" fill=\"none\" stroke=\"var(--ink)\" stroke-width=\"1\"></path><rect x=\"557.2\" y=\"74.0\" width=\"99.3\" height=\"50.0\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"656.5\" y=\"74.0\" width=\"28.6\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"685.0\" y=\"74.0\" width=\"15.0\" height=\"50.0\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"20.0\" y=\"46.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">People · 79.0%</text><text x=\"20.0\" y=\"63.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">52 engineers × R$ 264,000 = R$ 13,728,000</text><text x=\"559.2\" y=\"46.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">Cloud · 14.6%</text><text x=\"559.2\" y=\"63.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 2,544,000</text><path d=\"M670.8 124 L670.8 146 L600 146\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M692.5 124 L692.5 170 L600 170\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"594.0\" y=\"150.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Licences and SaaS · 4.2% · R$ 732,000</text><text x=\"594.0\" y=\"174.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tooling · 2.2% · R$ 380,000</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">each block is one engineer</text></svg>", "caption": "The four lines of the budget at their true proportions. The invoice engineers see most, the cloud bill, is the second line; the first never arrives as an invoice at all."}
```

## The sheet

Add a sheet to your workbook, as set up in lesson 1, and type the four lines:

| | A | B | C |
|---|---|---|---|
| 1 | Line | Amount | Share |
| 2 | People | 13728000 | |
| 3 | Cloud | 2544000 | |
| 4 | Licences and SaaS | 732000 | |
| 5 | Tooling | 380000 | |

The total, in an empty cell:

```localised
=SUM(B2:B5)      17384000
```

And each line's share of it, in C2:

```localised
=ROUND(B2/SUM($B$2:$B$5)*100,1)      79
```

The dollar signs fix the range, so the formula can be copied down: C3, C4 and C5 then read 14.6,
4.2 and 2.2. **Without them the range slides one row with every copy**, and C5 would divide the
tooling line by a sum of three cells that includes two empty ones. C2 shows 79 rather than 79.0
because the cell drops a trailing zero; format the column to one decimal place and it reads the way
the table does.

## What the shares say

**Four fifths of the budget is people's time.** Any conversation about engineering money is,
underneath, a conversation about what 52 people spend their hours on. Two engineers for a quarter
is half an engineer-year, R$ 132,000 of time. A cloud saving that took them that long has to
save more than that before it has paid for itself, and nobody checks unless the hours are priced
the same way as the invoice.

**The lines are not independent.** A licence often replaces people's time: lesson 9 found that
operation was 76% of the self-hosted observability stack's total cost, and almost all of that was
hours. Cancel the subscription and the money moves from the licence line to the people line, where
nobody records it as a cost of the decision. The cloud does the same in reverse: a cheaper
architecture that needs a person to watch it is cheaper on one line only.

**And the lines move at different speeds.** The cloud bill moves every month, with traffic; lesson
12 is about reading it. Licences move with headcount, because most are priced per seat. People move
in steps of R$ 264,000, and slowly: a role takes months to fill and an engineer who leaves takes
what they know with them. Tooling is lumpy, a large purchase one year and almost nothing the next.

| line | what moves it | how fast it can change |
|---|---|---|
| People | hiring, leaving, reallocation | months, in steps of R$ 264,000 |
| Cloud | traffic, architecture, waste | weeks |
| Licences and SaaS | headcount, contract renewals | at renewal, usually yearly |
| Tooling | one-off purchases | when somebody buys something |

That last column decides what a lead can actually change in a quarter, and it is the first thing
to check when somebody asks for money back. The next section is that request.
