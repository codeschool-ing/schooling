---
title: A web page or a web file, also described rather than run
version: 1
---

**From Web downloads whatever is at an address and reads the tables in it, and the address
belongs to somebody else, who can change the page tomorrow.** It is the most convenient source
in this lesson and the least dependable one.

**This section was not run either.** A query against a live page would give a different answer on
the day you read this, and the course's computer has no Excel to run it. What follows is what the
dialogs ask and how the result breaks.

## Two kinds of address

**An address that ends in a file**, a `.csv` or a `.xlsx` published on a site, behaves exactly
like section 03 of this lesson: Power Query downloads the file and the same delimiter, encoding and
locale choices apply. Government open-data portals, statistics offices and central banks publish
much of their data this way, and it is the dependable case, because a published file usually keeps
its columns from one release to the next.

**An address that is a page** is the other case. Power Query reads the page's HTML and looks for
tables in it, which is convenient and fragile in equal measure.

## The dialogs

**Data › Get Data › From Other Sources › From Web**, which also has a button of its own on the
**Data** tab on most versions. The dialog asks for the **URL**; **Advanced** lets you build it from
parts and add headers, which you need only when a site's documentation asks for them.

Next comes **access**: for a public page, **Anonymous**. A site that needs a login is rarely worth
reading this way, and a page behind somebody else's login is usually not yours to download.

Then the **Navigator**, which for a page lists every table it found, named `Table 1`, `Table 2` and
so on, plus `Document`, the page as a whole. **Web View** shows the page itself, which helps you
see which of the numbered tables is the one you want. If the data on the page is not a real table,
**Add Table Using Examples** lets you type the first values of the columns you want, and Power
Query looks for the pattern.

## How it breaks

A page is built for people to read, and its owner rearranges it whenever they like. Three things
happen, from least to most dangerous:

- **The page moves or disappears.** The refresh fails, and the error names the address. Annoying,
  and harmless: you see it at once.
- **A column is renamed.** The step that named the old column fails with an error saying the
  column was not found, which lesson 14 section 07 shows how to read and fix.
- **A table is added above yours.** `Table 2` is now a different table, the columns may still have
  plausible types, and the query **refreshes without an error**, on the wrong data. Nothing warns
  you; a total that changed overnight is the only symptom.

That last one is the reason to prefer a published file to a page, and when a page is all there
is, to check a known number after every refresh, the way lesson 1 section 05 checked the paste.

## Privacy levels

The first time a query combines a web source with one of your files, Excel may ask you to set a
**privacy level** for each source: **Public**, **Organizational** or **Private**. The question
exists because combining two sources can send values from one to the other: a filter built from a
column of your private file could end up inside the address of a request to a public site. Mark
your own files Private and a public site Public, and Excel keeps the two apart.
