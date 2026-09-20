---
title: Three programs, and the one mistake that costs the most
version: 1
---

The suite is three programs that look alike and are not. Each is built around a different idea,
and the commonest waste of an afternoon is doing a job in the one that was not designed for it.

| | it is for | its unit |
|---|---|---|
| **Word** | text that is read in order | a paragraph |
| **Excel** | values that are calculated from other values | a cell |
| **PowerPoint** | things said out loud, with something on a screen | a slide |

## The wrong-program mistake, in both directions

**A table of numbers built in Word** looks fine and cannot be sorted, filtered, summed or checked.
Every total in it is a number somebody typed, which means every total in it is wrong the moment a
row changes.

**A document written in Excel** — and this is more common than it sounds, because the grid looks
tidy — has no page, no reflow, no styles, and prints across four sheets in an order nobody
predicted.

The test is one question: **is anything in this going to be calculated?** If yes, Excel, and paste
the result into Word afterwards. If no, Word.

## The file formats, and what the x means

`.docx`, `.xlsx` and `.pptx` replaced `.doc`, `.xls` and `.ppt` around 2007. The `x` is for XML:
the new ones are **zip archives full of text files**, which is why they are smaller, why they
recover better from damage, and why a `.docx` can be opened by programs Microsoft did not write.

Two practical consequences:

- **Anything that still says `.doc` is from before 2007** or was saved deliberately for
  compatibility. Save as `.docx` unless somebody has asked otherwise.
- **`.docm` and `.xlsm` hold macros**, which are programs. An unexpected `.xlsm` attachment is
  the spreadsheet version of the `.exe` from lesson seven.

## Desktop, web and mobile are three different products

They share a name and a file format and they do not share a feature list. The web versions are
genuinely capable and are missing things: mail merge, most of the advanced statistical functions,
pivot table refinements, macros.

**Work in the desktop version for anything complicated and use the web version for anything
collaborative**, and know that a document round-tripped through the web version can lose a
feature it did not support — quietly, and usually a field or a macro.

## What it costs, and the alternative that is free

Microsoft 365 is a subscription; there is still a one-off *Home and Student* licence that gets a
fixed version with no updates beyond security. The subscription includes the cloud storage and
the web versions.

**LibreOffice is free, opens and saves all of these formats, and is a genuinely complete suite.**
Its weakness is exactly the same as the web version's: a complex `.docx` round-tripped through it
can come back with its layout slightly moved. For your own documents that is nothing; for a
contract somebody else will open in Word, check it before sending.
