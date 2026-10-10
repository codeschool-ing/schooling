---
title: Four roles, named by what they deliver
version: 1
---

From outside, everybody who works with data looks like one profession with four job titles, and the
titles look like a ladder: analyst at the bottom, data scientist at the top. **Both pictures are
wrong.** The four roles do different work, answer different questions and fail in different ways,
and a company that hires the wrong one for its problem waits a year to find out. The clearest way to
tell them apart is by what each one hands to somebody else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"A path from left to right. On the left, the company's records: the stores' tills, the online shop, the warehouse. An arrow to the data engineer, who delivers data that arrives correct and on time, into one database. From the database three arrows go to three roles stacked on the right: the BI analyst, who delivers the recurring answers and the definitions behind them; the data analyst, who delivers an answer to a new question; the data scientist, who delivers a model that predicts or decides. All three arrows end at the decisions.\" data-fig=\"l03-roles\"><rect x=\"16.0\" y=\"120.0\" width=\"120.0\" height=\"170.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76.0\" y=\"145.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">the records</text><text x=\"76.0\" y=\"180.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">store tills</text><text x=\"76.0\" y=\"206.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">online shop</text><text x=\"76.0\" y=\"232.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">warehouse</text><text x=\"76.0\" y=\"258.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">payroll</text><path d=\"M138.0 205.0 L166.0 205.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M166.0 205.0 L157.9 208.9 L157.9 201.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"168.0\" y=\"150.0\" width=\"160.0\" height=\"110.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"248.0\" y=\"178.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">data engineer</text><text x=\"248.0\" y=\"202.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">data that arrives</text><text x=\"248.0\" y=\"218.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">correct and on time</text><text x=\"248.0\" y=\"244.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Tiago</text><rect x=\"370.0\" y=\"40.0\" width=\"220.0\" height=\"100.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480.0\" y=\"67.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">BI analyst</text><text x=\"480.0\" y=\"91.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the same answer, every week,</text><text x=\"480.0\" y=\"107.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and its written definition</text><text x=\"480.0\" y=\"129.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Lívia</text><path d=\"M330.0 205.0 L368.0 90.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M368.0 90.0 L369.2 98.9 L361.7 96.5 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M592.0 90.0 L640.0 205.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M640.0 205.0 L633.3 199.0 L640.5 196.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"370.0\" y=\"160.0\" width=\"220.0\" height=\"100.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480.0\" y=\"187.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">data analyst</text><text x=\"480.0\" y=\"211.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">an answer to a new question,</text><text x=\"480.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">once, then perhaps again</text><text x=\"480.0\" y=\"249.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Lívia, again</text><path d=\"M330.0 205.0 L368.0 210.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M368.0 210.0 L359.5 212.8 L360.5 205.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M592.0 210.0 L640.0 205.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M640.0 205.0 L632.3 209.7 L631.5 201.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"370.0\" y=\"280.0\" width=\"220.0\" height=\"100.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480.0\" y=\"307.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">data scientist</text><text x=\"480.0\" y=\"331.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a model that predicts</text><text x=\"480.0\" y=\"347.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">or decides on its own</text><text x=\"480.0\" y=\"369.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">nobody, yet</text><path d=\"M330.0 205.0 L368.0 330.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M368.0 330.0 L361.9 323.4 L369.4 321.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M592.0 330.0 L640.0 205.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M640.0 205.0 L640.7 214.0 L633.4 211.2 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"642.0\" y=\"160.0\" width=\"70.0\" height=\"90.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"677.0\" y=\"200.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the</text><text x=\"677.0\" y=\"218.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">decisions</text><text x=\"360.0\" y=\"408.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the name in each box: who does that work at Varanda in 2026</text></svg>", "caption": "Four roles between the records and the decisions, each named by what it delivers. At Varanda one part-time engineer and one analyst cover three of them."}
```

## The data engineer: data that arrives, correct and on time

A company's records live in the systems that run it: the stores' tills, the online shop, the
warehouse, payroll. None of them was built for analysis, and none of them talks to the others. **The
data engineer builds and runs the pipelines that copy those records into one place where they can be
queried, every night or every hour, and notices when a copy fails.** At Varanda that is Tiago Ramos,
a part-time contractor, and the place is a database that holds yesterday's sales, stock and
deliveries by six in the morning.

The question an engineer answers is not about the business. It is "did the data arrive, is it
complete, and is it the same as the source?" When the answer is yes nobody notices, which is why the
role is easy to underrate. The `data-fundamentals` course is about this job.

## The BI analyst: the recurring answer, the same way every time

**The BI analyst answers the questions a company asks over and over — sales by store, delivery on
time, stock by category — and makes sure they are answered the same way each time.** What they
deliver is a report, a dashboard or an email, and behind it something less visible and more
important: the written definition of each number, so that two directors bring the same total to the
same meeting. Lívia was hired for this, and lesson 1 was about why Varanda needed it.

## The data analyst: the new question

Some questions are asked once. Why did October fall? Do customers who first buy garden furniture come
back more than those who first buy kitchenware? **The data analyst takes a question nobody has
answered before, explores the data, and delivers an answer with its evidence and its doubts.** The
work is less repeatable and more open: the analyst does not know at the start which tables or which
comparison will matter. When an answer turns out to be needed every month, it moves to the BI side
and gets a definition.

## The data scientist: a model that predicts or decides

**The data scientist builds models: something that takes data about a case it has not seen and
predicts an outcome, or makes a decision on its own.** Which customer will stop buying, how many
garden hoses the Contagem store will sell next week, which transactions look like fraud. The
deliverable is a model and the evidence that it beats a simple rule, and it needs more statistics and
more programming than the other three. Varanda has no data scientist, and in its first months of BI it
does not need one yet. Lesson 8 shows how far simple forecasting goes before a model is worth its
cost.

## Not a ladder

A data scientist is not a senior analyst. A good BI analyst with ten years' experience is senior in
BI, and may never build a model or need to. **The roles differ in kind, not in
rank.** What separates them is the question each one is for:

| role | the question it answers | what it delivers |
|---|---|---|
| data engineer | did the data arrive, complete and on time? | pipelines and a database that can be trusted |
| BI analyst | what happened, measured the same way as last time? | recurring reports and dashboards, and the definitions behind them |
| data analyst | what is going on with this new question? | an analysis, once, with its evidence and doubts |
| data scientist | what will happen in this case, or what should be done? | a model, and the proof it beats a simple rule |
