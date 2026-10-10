---
title: A database, described rather than run
version: 1
---

**A database connection asks for three things a file never does: where the server is, who you
are, and which table you want.** After that the query is like any other, with one difference that
makes databases worth the trouble: the server can do the work of your steps before a single row
reaches your computer.

**This section was not run, and it has no numbers.** The course gives you no database to connect
to, and the computer it was written on has no Excel. What follows describes the dialogs and what
each choice means, so that the first time you meet them, at work or in the `sql-databases` course
(position 5 of the BI track), you know what is being asked.

## The dialogs, in order

Databases are under **Data › Get Data › From Database**. Microsoft's own, **From SQL Server
Database**, is the commonest at work, and it is a fair model of the rest; others appear in the
same menu or under **From Other Sources**, depending on your version and what is installed.

1. **Server.** The name or address of the machine the database runs on, which whoever runs it
   gives you, such as `db.example.com` or `SERVER01\SALES`. Optionally the **Database** name, and
   under **Advanced options** a box for a SQL statement of your own.
2. **Credentials.** How you prove who you are. SQL Server offers your **Windows** login, a
   **Database** user name and password, or a **Microsoft account**. Excel remembers the answer for
   that server on your computer, not inside the workbook, so a colleague who opens your file has
   to give their own. **Data › Get Data › Data Source Settings** is where a saved credential is
   changed or cleared.
3. **The Navigator.** The same window as section 05 of this lesson, listing the tables and views
   your login may read. Tick one and choose **Transform Data**.

Some databases need their own driver installed on your computer before Excel can talk to them.
When one is missing, the connector says so, and the database's documentation names the driver to
install.

## The server does the work

Suppose Café Serra's web shop kept its orders in a database instead of sending monthly files, and
the orders table had grown to a million rows over the years. You connect, filter `Date` to 2026,
and remove four columns you do not need.

With a file, Power Query would read all million rows and then throw most of them away. With a
database it does something better: it translates your steps into one question in **SQL**, the
database's language, and the server answers it, sending back only 2026's rows and only the columns
you kept. This is called **query folding**, and it is why a query against a large table can be
fast. Right-click a step and choose **View Native Query** to see the SQL it was turned into; if
that item is greyed out, the step did not fold, and from there on Excel does the work itself.

Two habits keep a query folding:

- **Filter and remove columns early.** Steps that the database understands, such as filters,
  column choices, sorting and grouping, fold; a step that has no SQL equivalent stops the folding,
  and every step after it runs in Excel on whatever rows came back.
- **Prefer the Navigator to the SQL box.** A statement typed under **Advanced options** is sent as
  it is, and the steps you add after it are done in Excel rather than by the server. It is the
  right tool when you already have the exact query; it is the wrong place to start.

## What to ask before connecting

A database at work belongs to somebody, and three questions save an afternoon: which **server and
database** to use, which **login** you should have (a personal one, never a shared password in a
workbook), and whether there is a **read-only copy** meant for reports, so that your refresh does
not slow the system that takes orders.
