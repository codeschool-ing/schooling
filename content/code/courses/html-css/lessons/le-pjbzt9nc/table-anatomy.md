---
title: The parts of a table
version: 1
---

Here is the bookshop's hours table, written with every part a table can have:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Opening hours · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Opening hours</h1>
      <table>
        <caption>Opening hours, from October 2026</caption>
        <thead>
          <tr>
            <th scope="col">Day</th>
            <th scope="col">Opens</th>
            <th scope="col">Closes</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Monday to Friday</th>
            <td>10 am</td>
            <td>7 pm</td>
          </tr>
          <tr>
            <th scope="row">Saturday</th>
            <td>10 am</td>
            <td>4 pm</td>
          </tr>
          <tr>
            <th scope="row">Sunday</th>
            <td colspan="2">Closed</td>
          </tr>
        </tbody>
      </table>
    </main>
  </body>
</html>
```

From the outside in:

- **`<table>`** holds everything.
- **`<caption>`** is the table's title, and it must be the first thing inside it. It names the table, and the tree uses it as the table's accessible name.
- **`<thead>`** and **`<tbody>`** split the header rows from the data. A table can also have a **`<tfoot>`** for totals. They change nothing visible by default, and they give CSS and screen readers the structure.
- **`<tr>`** is a row. A table is written row by row; there is no element for a column.
- **`<th>`** is a header cell and **`<td>`** is a data cell.
- **`scope`** on a `<th>` says whether it heads a **column** (`col`) or a **row** (`row`).

And the tree:

```
ana@laptop:~/site$ probe hours.html tree
- main:
  - heading "Opening hours" [level=1]
  - table "Opening hours, from October 2026":
    - caption: Opening hours, from October 2026
    - rowgroup:
      - row "Day Opens Closes":
        - columnheader "Day"
        - columnheader "Opens"
        - columnheader "Closes"
    - rowgroup:
      - row "Monday to Friday 10 am 7 pm":
        - rowheader "Monday to Friday"
        - cell "10 am"
        - cell "7 pm"
      - row "Saturday 10 am 4 pm":
        - rowheader "Saturday"
        - cell "10 am"
        - cell "4 pm"
      - row "Sunday Closed":
        - rowheader "Sunday"
        - cell "Closed"
```

The table is named by its caption. Every `<th scope="col">` became a **columnheader** and every `<th scope="row">` a **rowheader**, and each row is named by its whole content. That structure is what lets a screen reader announce *Saturday, Closes, 4 pm* at a cell, instead of *4 pm* and nothing else.

## Two habits worth having

**Make the first cell of each row a `<th scope="row">` when it names the row.** It is the most common thing left out: people mark up the top row as headers and forget that *Saturday* heads its row in exactly the same way.

**Write the caption.** A heading above the table does not name it; `<caption>` does. If the design has no room for a visible caption, the caption can be hidden visually with CSS and stay in the tree, a technique lesson 7 shows; the habit starts here.
