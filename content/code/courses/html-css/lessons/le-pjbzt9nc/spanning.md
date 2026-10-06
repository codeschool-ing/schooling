---
title: Cells that span rows and columns
version: 1
---

A cell can cover more than one row or column. **`colspan`** makes a cell as wide as several columns and **`rowspan`** makes it as tall as several rows. The hours table used one: on Sunday, *Closed* is a single cell across the two columns, *Opens* and *Closes*.

The Saturday programme uses both. The book swap fills the front room from 10 to 11, so its cell spans two rows; at noon the whole shop closes, so that cell spans both rooms:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Saturday · Andorinha Books</title>
    <style>
      td, th { border: 1px solid; padding: 4px 8px; }
      table { border-collapse: collapse; }
    </style>
  </head>
  <body>
    <main>
      <h1>Saturday 10 October</h1>
      <table>
        <caption>What is on, room by room</caption>
        <thead>
          <tr>
            <th scope="col">Time</th>
            <th scope="col">Front room</th>
            <th scope="col">Back room</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">10 am</th>
            <td rowspan="2">Book swap</td>
            <td>Children's reading</td>
          </tr>
          <tr>
            <th scope="row">11 am</th>
            <td>Bookbinding class</td>
          </tr>
          <tr>
            <th scope="row">12 noon</th>
            <td colspan="2">Lunch: the shop is closed</td>
          </tr>
        </tbody>
      </table>
    </main>
  </body>
</html>
```

Measured, the cells come out like this:

```
ana@laptop:~/site$ probe spans.html box td box 'th[scope=row]'
td  x 79.3   y 125.38 width 95.95  height 54
td  x 175.25 y 125.38 width 135.67 height 27
td  x 175.25 y 152.38 width 135.67 height 27
td  x 79.3   y 179.38 width 231.63 height 27
th  x 8.5    y 125.38 width 70.8   height 27
th  x 8.5    y 152.38 width 70.8   height 27
th  x 8.5    y 179.38 width 70.8   height 27
```

*Book swap* is one cell **54 pixels tall**, exactly two rows of 27. *Lunch* is one cell **231.63 pixels wide**, the two room columns together, 95.95 and 135.67, plus the one pixel of border between them. Drawn from those boxes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The Saturday table drawn from its measured boxes. Header row: Time, Front room, Back room. Row headers: 10 am, 11 am, 12 noon. Book swap has rowspan 2 and fills the front room for 10 and 11 am, one cell 54 pixels tall. Lunch: the shop is closed has colspan 2 and fills both rooms at 12 noon, one cell 231.63 pixels wide.\"><rect x=\"20\" y=\"40\" width=\"99.12\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69.56\" y=\"58.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Time</text><rect x=\"119.12\" y=\"40\" width=\"134.33\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"186.28\" y=\"58.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Front room</text><rect x=\"253.45\" y=\"40\" width=\"189.94\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"348.42\" y=\"58.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Back room</text><rect x=\"20\" y=\"77.8\" width=\"99.12\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69.56\" y=\"96.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">10 am</text><rect x=\"20\" y=\"115.6\" width=\"99.12\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69.56\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">11 am</text><rect x=\"20\" y=\"153.4\" width=\"99.12\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69.56\" y=\"172.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12 noon</text><rect x=\"119.12\" y=\"77.8\" width=\"134.33\" height=\"75.6\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"186.28\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Book swap</text><rect x=\"253.45\" y=\"77.8\" width=\"189.94\" height=\"37.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"348.42\" y=\"96.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Children&#x27;s reading</text><rect x=\"253.45\" y=\"115.6\" width=\"189.94\" height=\"37.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"348.42\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Bookbinding class</text><rect x=\"119.12\" y=\"153.4\" width=\"324.28\" height=\"37.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"281.26\" y=\"172.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Lunch: the shop is closed</text><text x=\"467.39\" y=\"85.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">rowspan=&quot;2&quot;</text><text x=\"467.39\" y=\"103.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one cell, two rows tall:</text><text x=\"467.39\" y=\"119.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">54 pixels</text><text x=\"467.39\" y=\"157.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">colspan=&quot;2&quot;</text><text x=\"467.39\" y=\"175.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one cell, two columns wide:</text><text x=\"467.39\" y=\"191.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">231.63 pixels</text></svg>", "caption": "A spanned cell takes the place of the cells it covers, and the rows below it are written without them."}
```

## The rule that trips people up

**A row is written without the cells that a span from above already covers.** The 11 am row has a header and one cell, *Bookbinding class*, because the front room at 11 is still taken by *Book swap*. Write a second cell there and the row has one cell too many: the browser pushes it into a fourth column that has no header, and the table grows a ragged edge. Count each row as the cells you write plus the cells reaching down into it from above, and every row should come to the same number.

**Spans make tables harder to read for everybody.** A screen reader handles a simple span like these, and a table with spans inside spans becomes difficult to follow by ear and for the eye. If a table needs many of them, it is often two tables.
