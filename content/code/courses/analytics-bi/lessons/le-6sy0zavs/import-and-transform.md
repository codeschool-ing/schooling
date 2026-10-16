---
title: Bringing the layer in
version: 1
---

Power BI reads data through **Get data**, which offers connectors for hundreds of sources,
PostgreSQL among them. In a company the database would be on a server Power BI can reach, and you
would pick that connector, point it at the `semantic` schema with a read-only role like lesson 3's,
and choose between two **storage modes**:

| mode | what happens | trade-off |
|---|---|---|
| **Import** | Power BI copies the rows into the `.pbix` file and answers from its own compressed copy | fast, and as fresh as the last refresh |
| **DirectQuery** | Power BI sends a query to the database for every visual, every time | always current, and every click costs the database a query |

Your database is inside a virtual machine that, on purpose, lets nothing in on port 5432. Opening it
to the Windows computer is possible and not worth it for a course. **Files are the simpler bridge**:
export each view of the layer as CSV, copy the files across, and use Get data's **Text/CSV**
connector, which is Import mode with a different source.

In the machine, make a directory, save this as `export.sql` in it, and run it with `psql`:

```
\copy (SELECT * FROM semantic.orders) TO 'orders.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM semantic.order_lines) TO 'order_lines.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM semantic.customers) TO 'customers.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM semantic.products) TO 'products.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM semantic.calendar) TO 'calendar.csv' WITH (FORMAT csv, HEADER)
```

`\copy` is `psql`'s own command: it runs the query on the server and writes the result to a file on
the client, with a header row.

```
ana@vm:~$ cd powerbi
ana@vm:~/powerbi$ psql lantern -f export.sql
COPY 7098
COPY 11355
COPY 2649
COPY 12
COPY 546
```

```
ana@vm:~/powerbi$ wc -l *.csv
   547 calendar.csv
  2650 customers.csv
 11356 order_lines.csv
  7099 orders.csv
    13 products.csv
 21665 total
ana@vm:~/powerbi$ head -n 3 orders.csv
order_id,customer_id,order_date,status,gross,discount,net_revenue
2,660,2025-01-04,paid,32.90,0.00,32.90
3,325,2025-01-09,paid,77.70,0.00,77.70
```

Each file has one line more than its count, for the header. Copy the directory to your Windows
computer from a PowerShell window there, with the same SSH connection lesson 1 set up (this command
was not run for the course, because the course has no Windows computer at the other end):

```
scp -P 2222 -r ana@localhost:powerbi .
```

## Power Query, and the locale trap

Loading a file goes through **Power Query**, the editor between the source and the model. Every
transformation you make there — renaming a column, changing a type, removing rows — is recorded as
a step, and the steps are replayed on every refresh. It is the same idea as `lantern.sql`: the
recipe is kept, not the result.

One step needs your attention with these files. The CSV writes `32.90` with a point, and Power
Query reads a number using the **locale** of the file or of your Windows settings. On a computer
set to Portuguese (Brazil), where the decimal separator is a comma, `32.90` can be read as `3290`
— every amount a hundred times too large, and no error anywhere. Lesson 1 found three lines like
that in Lantern's data; this would make all of them like that. Set the locale to English when
loading (in the import dialog, or with *Change type → Using locale* on the money columns) and check
one known value: order 2 is R$ 32.90.

That check is lesson 1 again, in a new tool: **after any load, compare one number you already know.**
