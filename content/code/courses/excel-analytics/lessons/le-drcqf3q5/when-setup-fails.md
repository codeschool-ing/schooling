---
title: When the setup fails
version: 1
---

**Most setup failures here are not broken installations.** They are an Excel older than the
course, a feature switched off, or a regional setting that changes how a formula is typed, and
each shows a symptom you can recognise. Find yours below.

## `XLOOKUP` answers `#NAME?`

`#NAME?` means Excel does not know a name in the formula. If you typed it correctly, your Excel is
older than the function: Excel 2019 and earlier do not have it. The fix is Microsoft 365, Excel
2021 or later, or one of the other paths in the previous section. If you cannot change it yet, you
can still follow lesson 4, which teaches `INDEX` and `MATCH` beside `XLOOKUP` precisely because
older copies of Excel are everywhere, and lessons 1 to 3 and 5 to 12 use nothing newer.

## Excel refuses a formula that is printed correctly

The message is *There's a problem with this formula*, and the formula has commas between its
arguments. Your Excel is set to a language or region that separates arguments with **semicolons**:
Portuguese, Spanish, French and German are among them. Type `;` where the course prints `,`. The
function names change with the language too, and the previous section and section 02 say where to
find both.

## Everything pasted into column A

The tab characters that split the values did not survive the copy. It happens when the text was
selected and copied by hand from the page rather than with the block's copy button, or when it
passed through a program that turns tabs into spaces. Copy again with the button. If the column is
already full, select column A and use **Data › Text to Columns**, choose **Delimited**, tick only
**Tab**, and finish.

## The dates sit on the left of their cells

They arrived as text, so `=COUNT(B:B)` in the `Sales` sheet answers 0 instead of 108. Excel reads
a value as `2025-01-02` in year-month-day order in every region, so this is rare, and it usually
means the paste went through another program first. Select column B, use **Data › Text to
Columns**, click **Next** twice, choose **Date** with the order **YMD**, and finish. Lesson 6 explains
what happened.

## There is no Power Pivot tab

On Excel for Windows, Power Pivot is an add-in that ships switched off. Go to **File › Options ›
Add-ins**, choose **COM Add-ins** in the **Manage** list at the bottom, click **Go**, tick
**Microsoft Power Pivot for Excel** and click **OK**. If it is not in the list, this edition of
Excel does not include it; on a Mac or in the browser it never does, and the previous section says
what to do instead.

## Excel opens files read-only, or says *Unlicensed Product*

Excel from Microsoft 365 checks the licence of the account it is signed in with. The banner means
it is signed in with an account that has none, often a personal account on a computer whose
licence belongs to a work or school account. Go to **File › Account**, sign out, and sign in with
the account that holds the subscription.

## The virtual machine is slow

Windows in a virtual machine wants at least two processors and 4 GB of memory, set in the virtual
machine's own settings while it is shut down, and it slows to a crawl below that. Close what you
do not need on your own computer while it runs, and keep the virtual machine's disk on an SSD
rather than an external hard drive.

## None of these

Write down three things before searching: the exact text of the message, where you were when it
appeared (which tab, which command) and the version from **File › Account**. A search for the
exact message in quotes, with the word Excel, finds Microsoft's own page for most of them. A
question asked with those three things in it gets an answer; "Excel doesn't work" does not.
