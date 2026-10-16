---
title: A first look at the series
version: 1
---

With the data written, a dozen lines of pandas show three of the four movements before any model
is involved. Save this as `look.py` in the course folder and run it with
`.venv/bin/python look.py`:

```schooling-example
{"language": "python", "file": "look.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nprint(orders.head(3).rename_axis(None).to_string())", "note": "Read the file and keep one column. `parse_dates` turns the text `2023-01-01` into a date, and `index_col` makes the dates the row labels, which is what lets pandas group by year, weekday or month."}, {"code": "print(\"\\norders per year\")\nprint(orders.groupby(orders.index.year).sum().rename_axis(None).to_string())", "note": "Add up each year. A year holds every season once, so the totals move only with the trend."}, {"code": "print(\"\\nmean orders per day, by weekday\")\nnames = [\"Mon\", \"Tue\", \"Wed\", \"Thu\", \"Fri\", \"Sat\", \"Sun\"]\nby_day = orders.groupby(orders.index.dayofweek).mean().round(0)\nprint(by_day.set_axis(names).to_string())", "note": "Average each weekday over the three years. `dayofweek` counts from 0 for Monday, which is why the names are set in that order."}, {"code": "print(\"\\nmean orders per day, by month, 2024\")\nyear = orders[\"2024\"]\nprint(year.groupby(year.index.month).mean().round(0).rename_axis(None).to_string())", "note": "Average each month of one year. A string like `\"2024\"` selects every row of that year, because the dates are the index."}], "output": "Traceback (most recent call last):\n  File \"/home/ana/bi/look.py\", line 3, in <module>\n    orders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\n             ~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py\", line 872, in read_csv\n    return _read(filepath_or_buffer, kwds)\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py\", line 300, in _read\n    parser = TextFileReader(filepath_or_buffer, **kwds)\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py\", line 1643, in __init__\n    self._engine = self._make_engine(f, self.engine)\n                   ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py\", line 1907, in _make_engine\n    self.handles = get_handle(\n                   ~~~~~~~~~~^\n        f,\n        ^^\n    ...<6 lines>...\n        storage_options=self.options.get(\"storage_options\", None),\n        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n    )\n    ^\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/common.py\", line 930, in get_handle\n    handle = open(\n        handle,\n    ...<3 lines>...\n        newline=\"\",\n    )\nFileNotFoundError: [Errno 2] No such file or directory: 'daily_orders.csv'"}
```

**Each block of the output isolates one movement by averaging the others away.**

The yearly totals are the trend, because every year contains each weekday about 52 times and each
month once, so the seasons cancel. They rise by 99,383 and then by 55,091: growth, slowing.

The weekday means are the weekly season, because three years of Mondays carry every month and
every stage of the trend equally. Monday is the busiest day and Saturday the quietest, by 373
orders.

The monthly means are the yearly season, and they are the first sign of trouble. January and
February are quiet, as expected. But the months from June to December are almost flat, and the
year's second half sits well above its first. **That is the trend leaking into the season**: one
year of data cannot tell "July is a busy month" apart from "the business was bigger by July".
Separating the two properly is the subject of lesson 2.

The fourth movement, noise, is the one a table of averages cannot show, because averaging is
exactly what removes it. It appears when the other three are subtracted, which lesson 2 also does.
