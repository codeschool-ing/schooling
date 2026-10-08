---
title: In dplyr
version: 1
---

dplyr is R's grammar of data manipulation: each step is a verb, `filter`, `mutate`, `group_by`,
`summarise`, and the pipe `|>` passes the table from one to the next. It reads close to the
specification:

```schooling-example
{
  "language": "r",
  "file": "task.R",
  "parts": [
    {
      "code": "suppressPackageStartupMessages(library(dplyr))\nlibrary(readr)\n\n",
      "note": "dplyr for the verbs, readr for reading."
    },
    {
      "code": "orders <- read_csv(\"raw/orders.csv\", col_types = cols(.default = col_character())) |>\n  distinct()\n\n",
      "note": "**Every column as text**, and exact repeated rows removed with `distinct()`."
    },
    {
      "code": "result <- orders |>\n  filter(status == \"delivered\") |>\n",
      "note": "Delivered orders only."
    },
    {
      "code": "  mutate(\n"
    },
    {
      "code": "    total = pmax(as.numeric(total), 0),\n",
      "note": "**A negative total becomes zero**, row by row."
    },
    {
      "code": "    placed = if_else(\n      channel == \"site\",\n      format(as.POSIXct(ordered_at, format = \"%Y-%m-%dT%H:%M:%SZ\", tz = \"UTC\"),\n             tz = \"America/Sao_Paulo\", format = \"%Y-%m-%d %H:%M:%S\"),\n      ordered_at)\n  ) |>\n",
      "note": "**The two clocks**: the site's UTC time formatted in São Paulo's zone; the app's time kept as it is."
    },
    {
      "code": "  group_by(channel) |>\n  summarise(orders = n(), revenue = sum(total),\n            december = sum(total[placed >= \"2025-12-01\"]))\n\n",
      "note": "Per channel: how many orders, how much revenue, and December's. The times are compared as text, which works because they are written year first."
    },
    {
      "code": "print(as.data.frame(result), digits = 10)\n",
      "note": "All the digits, so the comparison with the other tools is exact."
    }
  ]
}
```

```
ana@lab:~/clean$ Rscript task.R
  channel orders    revenue  december
1     app  11851 1065555.60 132925.45
2    site  14659 1436387.75 281616.15
```

The third tool, the same three numbers per channel. `col_types = cols(.default = col_character())`
is readr's way of saying what `dtype=str` says in pandas: read everything as text and guess nothing.
`distinct()` is `SELECT DISTINCT *`, `pmax(..., 0)` is `greatest`, and the time zone is converted by
formatting the UTC time in São Paulo's zone, with base R and no extra package.

One line deserves a second look. `if_else` evaluates **both** branches for every row, so the site's
format is applied to the app's times too, where it fails and gives `NA`; the condition then picks the
other branch, and nothing is lost. That is safe here because a failed parse gives `NA` silently, and
it is exactly the kind of behaviour worth knowing before trusting a vectorised `if`.

**Three tools, each written from the same paragraph, agree on every number.** That is the same
check as the typed table in lesson 10 and the survivor map in lesson 11, at a larger scale: when
two implementations of one specification disagree, one of them has a rule the other does not, and
the specification says which is wrong.
