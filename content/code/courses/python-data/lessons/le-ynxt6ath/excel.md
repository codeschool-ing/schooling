---
title: Excel, sheets and all
version: 1
---

**An Excel workbook is a zip of XML files, and pandas reads and writes it through `openpyxl`, which
lesson 1 installed.** Unlike a CSV, it can hold several tables, one per sheet, and it stores numbers
as numbers. Everything else about a workbook, formatting, formulas, charts, is lost on the way into
pandas, because a DataFrame has nowhere to put it.

Write the weather and the stations as two sheets of one file:

```python
stations = pd.read_csv("stations.csv")
with pd.ExcelWriter("maré.xlsx") as book:
    weather.to_excel(book, sheet_name="weather", index=False)
    stations.to_excel(book, sheet_name="stations", index=False)
os.path.getsize("maré.xlsx")
```

```
12517
```

`ExcelWriter` keeps the file open while several DataFrames are written into it, and the `with` block
closes it. Reading it back, `sheet_name` chooses the sheet; `None` reads them all, as a dictionary
of DataFrames keyed by sheet name:

```python
sheets = pd.read_excel("maré.xlsx", sheet_name=None)
list(sheets), sheets["stations"].shape, sheets["weather"].dtypes
```

```
(['weather', 'stations'],
 (21, 4),
 date            str
 rain_mm     float64
 temp_max    float64
 dtype: object)
```

The numbers came back as numbers. The dates came back as text, because they went in as text; Excel
would have stored real dates if the column had been datetimes, and pandas would read them back as
datetimes.

## What a workbook from a person contains

A workbook made by hand is rarely one clean table from cell A1. The `read_excel` options that deal
with that are the same as `read_csv`'s, plus one:

- `skiprows=3` when the table starts below a title and some notes;
- `usecols="A:D"` to read some columns, in Excel's own letters;
- `header=None` when there is no row of names;
- `nrows` to stop before a total row at the bottom.

**Read a workbook somebody else made with `sheet_name=None` first**, and look at every sheet's
`shape` and `head`. The number you need is often on the sheet nobody mentioned.
