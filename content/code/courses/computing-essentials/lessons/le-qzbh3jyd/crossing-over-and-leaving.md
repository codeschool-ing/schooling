---
title: Crossing over, and the question of what you own
version: 1
---

Most people work in both suites, usually because somebody else chose the other one. Three things
are worth knowing before a document crosses.

## Editing Office files without converting them

Drive will open a `.docx` and edit it **in place**, keeping it as a `.docx`. That is *Office
editing mode*, and it is the right answer whenever the file has to go back to somebody in Word.

The cost is that the Google-only features are unavailable, because there is nowhere in the
`.docx` format to put them. You get the collaboration and not the `@` menu.

The alternative — *File, Save as Google Docs* — converts it, unlocks everything, and produces a
document that is no longer the file somebody sent you. Both are correct; the mistake is not
knowing which one you did.

## What breaks in each direction

| | usually survives | usually moves |
|---|---|---|
| **Docs → Word** | text, headings, lists, tables, images, comments | precise spacing, some table borders, page breaks in long documents |
| **Word → Docs** | the same | section-dependent headers, fields, macros, SmartArt |
| **Sheets → Excel** | values, most formulas, formatting | `QUERY`, `IMPORTRANGE`, `ARRAYFORMULA`, anything from Apps Script |
| **Slides → PowerPoint** | layout, text, images | fonts, some transitions, linked charts |

**The row to plan around is the third one.** A sheet built on `QUERY` and `IMPORTRANGE` does not
become an Excel workbook; it becomes an Excel workbook full of `#NAME?`. If the spreadsheet will
ever have to leave, build it with functions both understand.

## Takeout, and what a backup of this looks like

`takeout.google.com` exports everything in the account — Drive, mail, photos, calendar — as a
set of archives. Documents come out as `.docx`, `.xlsx` and `.pptx`, or as PDFs, chosen at export
time.

Two things about it matter:

- **It is a snapshot, not a sync.** It has to be run again to be current, and it can be scheduled
  to run every two months, which is the closest thing to automatic available.
- **The export is a translation**, with everything from the table above. A `QUERY` does not
  survive; what comes out is the values it produced at the moment of export.

## And the argument from lesson eight, applied here

A Google Doc is **a copy you do not hold**. The account can be suspended, the service can change
its terms, and a document deleted by its owner disappears for everyone it was shared with. None
of those is likely and all of them have happened to somebody.

So the same three sentences apply, unchanged:

- **a plain format** — the export, as `.docx` or PDF, of anything that would hurt to lose;
- **a copy that does not change when the original does** — which the export is, by construction;
- **one of them somewhere else** — a folder on the machine you backed up in lesson eight.

Twice a year, for the dozen documents that matter, is enough. It is not a criticism of the
service; it is what *you have a copy* means when the thing is on somebody else's computer.
