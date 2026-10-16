"""Two differences between Calc and Excel that lessons 2 to 4 meet, closed so
that a formula printed in Excel's spelling means in Calc what it means in Excel.

1. A reference to another sheet. Excel writes `Products!$A$2:$A$7`; the API
   grammar `engine.Book.set` speaks writes `$Products.$A$2:$A$7`. `calc()`
   rewrites the first into the second, outside quoted text, and leaves every
   other character alone. A sheet name with a space would need quotes in both
   spellings; this course's sheets have none.

2. Comparing text. Excel compares text ignoring case: `="Wholesale"="wholesale"`
   is TRUE, and so is a lookup of `cer1k` against `CER1K`. A Calc document is
   case-sensitive unless told otherwise, so `excelish()` tells it.

Where Calc and Excel still differ, the lesson's number comes from `engine.xl`
instead, and the script that computes it says so: a logical value is a number
in Calc, so `SUM` over a range of TRUE adds them up, where Excel skips them.
"""
import re

REF = re.compile(r'"[^"]*"|([A-Za-z_][A-Za-z0-9_]*)!')


def calc(formula):
    return REF.sub(lambda m: m.group(0) if m.group(1) is None else "$" + m.group(1) + ".", formula)


def excelish(book):
    book.doc.IgnoreCase = True
    return book


def name(book, label, content, sheet="Sales"):
    """A workbook-level defined name. `content` in Excel's spelling, as the
    Name Manager's Refers to box shows it, without the leading `=`."""
    import uno
    addr = uno.createUnoStruct("com.sun.star.table.CellAddress")
    addr.Sheet = 0
    book.doc.NamedRanges.addNewByName(label, calc(content), addr, 0)
