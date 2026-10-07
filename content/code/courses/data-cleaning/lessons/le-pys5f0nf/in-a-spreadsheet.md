---
title: In a spreadsheet
version: 1
---

**Nothing in this section was run.** The lab has no Excel, and this course does not show output it
did not capture. What follows describes how the same task goes in a spreadsheet and in Power Query,
Excel's tool for importing and shaping data, and the one behaviour that matters most for cleaning.

**A spreadsheet guesses the moment a file is opened.** Double-click a CSV and Excel decides each
cell's type on its own, with no step you can see or undo. pandas does the same when it is not told
otherwise, and that can be shown here:

```
ana@lab:~/clean$ python -c "import pandas as pd; text = pd.read_csv('raw/order_items.csv', dtype=str); guess = pd.read_csv('raw/order_items.csv'); five = text['product_code'].str.len() == 5; print(text.loc[five, 'product_code'].head(3).tolist(), guess.loc[five, 'product_code'].head(3).tolist(), guess['product_code'].dtype)"
['00833', '00126', '00713'] [833, 126, 713] int64
```

Read as text, the site's product codes are `00833`, `00126`, `00713`. Read with the default guess,
they are the numbers 833, 126 and 713, the same loss the app's export suffered in lesson 7. Opening
the file directly in a spreadsheet invites the same guess on every column at once: codes lose their
zeros, CEPs lose theirs, and day-first and month-first dates are read according to the computer's
regional settings rather than the file's. On a computer set up for Brazil, where the list separator
is the semicolon, a comma-separated file can also open with everything in a single column.

Power Query is the answer to most of that, because it turns the clicks into recorded steps:

- **Import through Power Query, not by opening the file**, and set each column's type yourself, as
  text where it is a code. "Using locale" is the option that reads `dd/mm/yyyy` dates and decimal
  commas as Brazil writes them.
- **Each step is kept** in the query's list of applied steps, can be reviewed and is replayed when
  the file is refreshed. That is a recipe, which a sheet edited by hand is not.
- **Remove Duplicates, Filter, Replace Values and Group By** cover this task, and **Unpivot Other
  Columns** is lesson 13's melt.

The time zone is the hard clause. Power Query has a type for a date and time with a zone, and the
`Z` has to be read into it on purpose; a plain spreadsheet cell has no zone at all, and there the
site's three hours must be subtracted by somebody who knows they are needed.

::: track bi
`excel-analytics` lessons 13 and 14 built exactly this kind of query, and for a team that lives in
Excel it is often the right home for a cleaning step: the people who read the result can open the
steps. The rule from this course still applies: keep the raw file untouched, do every change in the
query, and never type over a value in the sheet that the query produced.
:::

::: track data-science
For a model's training data, a spreadsheet is a place to look, not a place to clean: whatever was
done to the data has to be repeatable on next month's file without a person clicking, and that
means code.
:::

::: track *
Whichever tool cleans the data, the spreadsheet is still where many results are read. Exporting
from pandas or SQL with codes kept as text, and telling readers to import rather than open, saves
the next person from the guesses described above.
:::
