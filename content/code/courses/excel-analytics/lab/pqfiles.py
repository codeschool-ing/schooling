"""The small files of lessons 13 and 14, read back out of the lessons, and
what Power Query's steps do to them, done in plain Python.

NOTHING HERE IS POWER QUERY. Power Query has no engine outside Excel, and the
machine this course was written on has no Excel (lab.sh). What a lesson says a
step produces is what the function of the same name below produces on the same
text, and the lessons say so.

THE FILES ARE READ OUT OF THE LESSONS. Each one is a fence that follows a
sentence ending in its name in backticks and a colon, so the bytes computed
here are the bytes the student copies.
"""
import datetime
import glob
import os
import re

from engine import LESSONS, rows

L13 = "le-rsfr20hc"
L14 = "le-sapssdn5"
FILE = re.compile(r"`([\w.-]+\.csv)`:\n\n```\n(.*?)\n```", re.S)


def files():
    out = {}
    for lesson in (L13, L14):
        for path in sorted(glob.glob(os.path.join(LESSONS, lesson, "*.md"))):
            if path.endswith(".pt.md"):
                continue
            for name, body in FILE.findall(open(path, encoding="utf-8").read()):
                if name in out and out[name] != body:
                    raise SystemExit(f"{name} is printed twice, differently")
                out[name] = body
    return out


def split(name, delim):
    """Csv.Document followed by Table.PromoteHeaders: a list of dicts of text."""
    lines = files()[name].split("\n")
    head = lines[0].split(delim)
    out = []
    for line in lines[1:]:
        f = line.split(delim)
        if len(f) != len(head):
            raise SystemExit(f"{name}: {line!r} has {len(f)} fields")
        out.append(dict(zip(head, f)))
    return out


# --- reading text under a locale -------------------------------------------
class Error:
    """A cell holding an error, as Power Query shows one."""
    def __repr__(self):
        return "Error"


def number(text, locale):
    dec, grp = (".", ",") if locale == "en-US" else (",", ".")
    t = text.replace(grp, "")
    try:
        return float(t.replace(dec, "."))
    except ValueError:
        return Error()


def date(text, locale):
    if re.match(r"^\d{4}-\d{2}-\d{2}$", text):
        return datetime.date.fromisoformat(text)
    a, b, y = (int(x) for x in text.split("/"))
    m, d = (a, b) if locale == "en-US" else (b, a)
    try:
        return datetime.date(y, m, d)
    except ValueError:
        return Error()


# --- the queries -----------------------------------------------------------
WEB = ["web-2026-07.csv", "web-2026-08.csv", "web-2026-09.csv"]


def web_file(name, locale="en-US"):
    out = []
    for r in split(name, ","):
        r = dict(r)
        r["Date"] = date(r["Date"], locale)
        r["Qty"] = int(r["Qty"])
        r["Unit price"] = number(r["Unit price"], locale)
        out.append(r)
    return out


def web_orders(locale="en-US"):
    """From Folder, Combine: Source.Name first, then each file's rows."""
    out = []
    for name in WEB:
        for r in web_file(name, locale):
            out.append({"Source.Name": name, **r})
    return out


def freight(locale="pt-BR"):
    out = []
    for r in split("freight-2026-q3.csv", ";"):
        out.append({"Order": r["Order"], "Shipped": date(r["Shipped"], locale),
                    "Weight kg": number(r["Weight kg"], locale),
                    "Freight": number(r["Freight"], locale)})
    return out


def products():
    t = rows("Products")
    return [dict(zip(t[0], r)) for r in t[1:]]


def sales():
    """The Sales table of lesson 7, with lesson 2's Revenue column."""
    t = rows("Sales")
    out = []
    for r in t[1:]:
        d = dict(zip(t[0], r))
        d["Revenue"] = d["Bags"] * d["Price"]
        out.append(d)
    return out


# --- numbers as the lessons print them -------------------------------------
def en(x, dp=None):
    if dp is None:
        dp = 0 if float(x) == int(x) else 2
    return f"{x:,.{dp}f}"


def pt(x, dp=None):
    return en(x, dp).replace(",", "_").replace(".", ",").replace("_", ".")


def both(label, x, dp=None):
    print(f"{label}: {en(x, dp)}  |  pt {pt(x, dp)}")
