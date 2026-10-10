---
title: Filters, and what the reader does not see
version: 1
---

A filter turns one dashboard into many: the same page for each region, each segment, any range of
dates. It also creates the dashboard's quietest failure, which is a filter the reader does not know
is set.

## Defaults decide what most people see

Most readers never touch a filter. **Whatever the default is, is the dashboard** for them. Three
choices matter:

- **The default date range.** "This month" on the 2nd of the month is two days of data. "Last 12
  months, complete months only" gives a Monday reader a stable picture; the current month belongs in
  its own tile, compared with the same days of the last.
- **The default for every other filter is "all".** A page that opens filtered to one segment because
  that was what its author last looked at shows everybody the author's question.
- **Which cards a filter drives.** In Metabase, each filter is connected card by card. A region filter
  connected to the trend and not to the tiles shows a page whose top half is about the South and whose
  bottom half is about everybody, with nothing on it to say so.

## Say what is filtered

The reader should be able to tell, without opening anything, what the page is showing: the filters'
current values visible at the top, the period in each card's title — *Net revenue, May 2026* rather
than *Net revenue* — and a card that does not respond to a filter saying so in its title.

**And a filter must not silently drop rows.** A region filter built on `customers` excludes orders
whose customer is not in the table — for Lantern's layer, the test account, on purpose. A filter on a
column that is sometimes empty excludes the empty rows too, and a total that falls when "all" is
selected through the filter rather than without it is the symptom. Check one total with the filter
on "all" against the same total with no filter at all.
