---
title: Building a page that reflows
version: 1
---

A chart saved as a picture cannot reflow: it is one shape at one size. A **web page** can, because the
browser lays it out again for every screen. Three pieces of HTML and CSS do the work, and this program
writes all three, with two versions of the trend chart, one wide and one narrow:

```schooling-example
{"language": "python", "file": "responsive.py", "parts": [{"code": "import csv\nimport os\nimport matplotlib.pyplot as plt\n"}, {"code": "total = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        total[row[\"month\"]] = total.get(row[\"month\"], 0) + int(row[\"orders\"])\nmonths = sorted(total)\nvalues = [total[m] for m in months]\ny24, y25 = sum(values[:12]), sum(values[12:])\n", "note": "Add up the orders per month across the regions, and the two yearly totals for the cards."}, {"code": "def trend(name, size, ticks):\n    fig, ax = plt.subplots(figsize=size)\n    ax.plot(range(len(months)), values, color=\"#2b52c9\", linewidth=2)\n    ax.set_xticks(ticks, [months[i] for i in ticks])\n    ax.set_title(\"Orders per month\", loc=\"left\")\n    ax.spines[[\"top\", \"right\"]].set_visible(False)\n    fig.savefig(name, bbox_inches=\"tight\")\n    plt.close(fig)\n", "note": "One function draws the trend at a given size with a given set of labelled months, so the wide and the narrow chart differ only in those two things."}, {"code": "trend(\"trend-wide.svg\", (9, 3.5), [0, 6, 12, 18, 23])\ntrend(\"trend-narrow.svg\", (3.6, 3.2), [0, 23])\n", "note": "The wide chart labels five months; the narrow one, smaller and nearly square, labels only the first and the last."}, {"code": "page = f\"\"\"<!doctype html>\n<html lang=\"en\">\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n<title>Horta</title>\n<style>\n  body {{ font-family: sans-serif; margin: 16px; max-width: 960px; }}\n  .cards {{ display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }}\n  .card {{ border: 1px solid #ccd4e3; border-radius: 6px; padding: 12px; }}\n  .card b {{ display: block; font-size: 2rem; }}\n  img {{ width: 100%; height: auto; margin-top: 16px; }}\n  @media (max-width: 600px) {{\n    .cards {{ grid-template-columns: 1fr; }}\n  }}\n</style>\n<div class=\"cards\">\n  <div class=\"card\">orders in 2025 <b>{y25:,}</b> {y25 / y24 - 1:+.1%} on 2024</div>\n  <div class=\"card\">orders in December <b>{values[-1]:,}</b> {values[-1] / values[11] - 1:+.1%} on Dec 2024</div>\n</div>\n<picture>\n  <source media=\"(max-width: 600px)\" srcset=\"trend-narrow.svg\">\n  <img src=\"trend-wide.svg\" alt=\"Orders per month, January 2024 to December 2025, rising from {values[0]:,} to {values[-1]:,} with a spike every December.\">\n</picture>\n\"\"\"\nwith open(\"dashboard.html\", \"w\") as f:\n    f.write(page)\n", "note": "The page. The viewport line makes a phone lay it out at its own width; the grid puts the cards in two columns; the media rule turns them into one at 600 pixels or less; and the picture element hands the browser both charts with the rule for choosing. The doubled braces are how an f-string writes a literal brace. Then write it to dashboard.html."}, {"code": "for name in (\"dashboard.html\", \"trend-wide.svg\", \"trend-narrow.svg\"):\n    print(f\"{name:16} {os.path.getsize(name):7,} bytes\")\n", "note": "Print the size of each file written, as a check that all three exist."}]}
```

```
ana@vm:~/viz$ .venv/bin/python responsive.py
dashboard.html       965 bytes
trend-wide.svg    20,517 bytes
trend-narrow.svg  17,846 bytes
```

## The three pieces

- **The viewport line**, `<meta name="viewport" content="width=device-width, initial-scale=1">`.
  Without it, a phone's browser pretends to be about 980 pixels wide and shrinks the page to fit,
  which is the left-hand phone in the first figure of this lesson. With it, the page is laid out at
  the phone's real width.
- **A grid that changes at a width.** The cards sit in a CSS grid of two columns. The `@media
  (max-width: 600px)` rule changes it to one column when the screen is 600 pixels wide or less. The
  number is a **breakpoint**, and it belongs where the layout stops working, not at a particular
  phone's width.
- **A chart per shape.** The `<picture>` element offers the browser two files and a rule for choosing:
  the narrow SVG, with two date labels and a taller shape, at 600 pixels or less; the wide one
  otherwise. Both carry the same `alt` text, which says what the chart shows (lesson 14).

## Looking at it

Opening `dashboard.html` straight from the folder works for a first look. Serving it is closer to how
a real dashboard is reached, and it is the only way a phone can open it. Python comes with a small
web server:

```
ana@vm:~/viz$ timeout 3 python3 -u -m http.server 8000 --bind 127.0.0.1
Serving HTTP on 127.0.0.1 port 8000 (http://127.0.0.1:8000/) ...
```

Open `http://127.0.0.1:8000/dashboard.html` in a browser on the same computer, then switch on its
**device mode**: Ctrl+Shift+M in Chrome's developer tools or in Firefox (Cmd+Opt+M on a Mac). It
shows the page at a chosen phone's width, and dragging the edge shows the breakpoint at work.

`--bind 127.0.0.1` keeps the server visible to this computer only. To try the page on a real phone,
both have to be on the same network and the server has to listen on it, with `--bind 0.0.0.0`, which
shows the folder to **everyone on that network**. Do that only on a network you trust, serve a folder
that holds nothing else, and stop the server with Ctrl+C when you are done.

## What device mode does not show

A desktop browser pretending to be narrow gets the layout right and the hand wrong: it does not show
how small a target feels under a thumb, or how a screen reads in sunlight. The last check is the real
phone, held the way the director holds it.
