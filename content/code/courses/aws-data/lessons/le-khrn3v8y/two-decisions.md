---
title: The two decisions, priced together
version: 1
---

**Format and partitioning multiply, and the bill is their product.** The format decides what share of
each file a question reads; the partitioning decides how many files it opens and how large they are.
Every measurement of this lesson and of lesson 15 is one cell of that product, and laid side by side
they make the choice for Quitanda's lake plain.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 212\" role=\"img\" aria-label=\"A bar chart of bytes read from S3 for one question in seven layouts. CSV 40,641,097 bytes. CSV with gzip 8,421,323. Parquet with no codec 6,481,669. Parquet with Snappy 5,102,048. Parquet with zstd 4,280,951. ORC with zstd 2,820,788. Parquet in 96 files a day 27,000,299. The plain CSV and the small files are the two long bars.\" data-fig=\"l19-bytes\"><text x=\"180\" y=\"29\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CSV</text><rect x=\"190\" y=\"20\" width=\"400.0\" height=\"18\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"598.0\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40,641,097 bytes</text><text x=\"180\" y=\"55\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CSV, gzip</text><rect x=\"190\" y=\"46\" width=\"82.88480008302926\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"280.8848000830293\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8,421,323 bytes</text><text x=\"180\" y=\"81\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parquet, no codec</text><rect x=\"190\" y=\"72\" width=\"63.79423271965321\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"261.7942327196532\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6,481,669 bytes</text><text x=\"180\" y=\"107\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parquet, Snappy</text><rect x=\"190\" y=\"98\" width=\"50.215652397375\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"248.215652397375\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5,102,048 bytes</text><text x=\"180\" y=\"133\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parquet, zstd</text><rect x=\"190\" y=\"124\" width=\"42.134207154890525\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"240.13420715489053\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,280,951 bytes</text><text x=\"180\" y=\"159\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ORC, zstd</text><rect x=\"190\" y=\"150\" width=\"27.76291200997847\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"225.76291200997846\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,820,788 bytes</text><text x=\"180\" y=\"185\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parquet, 96 files a day</text><rect x=\"190\" y=\"176\" width=\"265.7438011577296\" height=\"18\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"463.7438011577296\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">27,000,299 bytes</text><line x1=\"190\" y1=\"16\" x2=\"190\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"></line></svg>", "caption": "The same question, October's sales by payment, asked of seven layouts of the same orders: the bytes each read from S3, measured by ask.py, on one linear scale."}
```

## The month question, at a thousand times the size

At this lake's size every layout but two pays Athena's 10 MB minimum, so the bill hides the
difference, as it did in lesson 15. Multiplied by a thousand, the read of each layout for the question
about October's sales becomes this, priced at the Athena line of the sheet and asked 4,464 times a
month by the dashboard:

| layout | read here | a query at ×1,000 | MB billed | USD a query | USD a month |
|---|---:|---:|---:|---:|---:|
| CSV | 40,641,097 | 40.6 GB | 38,759 | 0.333 | 1,485.04 |
| CSV, gzip | 8,421,323 | 8.4 GB | 8,032 | 0.069 | 307.74 |
| Parquet, no codec | 6,481,669 | 6.5 GB | 6,182 | 0.053 | 236.86 |
| Parquet, Snappy | 5,102,048 | 5.1 GB | 4,866 | 0.042 | 186.44 |
| Parquet, zstd | 4,280,951 | 4.3 GB | 4,083 | 0.035 | 156.44 |
| ORC, zstd | 2,820,788 | 2.8 GB | 2,691 | 0.023 | 103.11 |
| Parquet, 96 files a day | 27,000,299 | 27.0 GB | 25,750 | 0.221 | 986.61 |

**The worst columnar layout costs two thirds of the CSV, and the best a fourteenth.** The small files
threw away most of what Parquet had won, and they pay their GET requests on top, 14.88 dollars a
month at this size, which a thousand times larger would be far more. The arithmetic multiplies the
measured read by a thousand, which is fair for the column data and generous to the small files,
whose footers would multiply with their number; it is a size of bill and not an invoice.

## What Quitanda's lake should be

The measurements give one answer, and none of it is exotic:

- **Parquet, with zstd or with Snappy**, in the curated layer. The difference between them is 30
  dollars a month here, and the difference between either and CSV is nearly 1,300.
- **partitioned by `dt`**, the column almost every question names, coarse enough that a day is a
  file worth opening;
- **one file per day, or as few as the volume allows**, kept that way by the job that writes it, so
  that the small-files line never appears;
- **sorted by `hour` inside each file**, the next most common filter, for the row-group statistics.

**Both decisions are made when the data is written and paid for every time it is read**, which is
why they are worth getting right before the lake is large. Changing either afterwards means
rewriting every file under the table, a CTAS or a job that reads the whole history once. At a month that is one run of a small job; at three years it is the largest bill the lake will ever run.
