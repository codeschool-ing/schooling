"""Drawing helpers for the course's figures: inline SVG on the application's
palette, one drawing per language.

A figure is a function of `t`, which picks the English or the Portuguese of a
label: `t("total", "total")`. Text drawn with `sans()` is prose and is asked
about by check-figures; text drawn with `mono()` is a cell, a formula or a
header of the student's data, and is the same in both languages. A sans label
that comes out identical in both is listed in the Portuguese figure's `same`
automatically, because it was written once and decided once.
"""
from xml.sax.saxutils import escape

MONO = "'IBM Plex Mono', monospace"
SANS = "'IBM Plex Sans', sans-serif"


class Svg:
    def __init__(self, w, h, name, aria):
        self.w, self.h, self.name, self.aria = w, h, name, aria
        self.parts = []
        self.sans_labels = []

    def rect(self, x, y, w, h, fill="var(--panel)", stroke="var(--wire)", rx=0, sw=1, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" '
                          f'fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}></rect>')

    def line(self, x1, y1, x2, y2, stroke="var(--wire)", sw=1, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(f'<path d="M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}" stroke="{stroke}" '
                          f'stroke-width="{sw}" fill="none"{d}></path>')

    def path(self, d, stroke="var(--wire)", sw=1, fill="none"):
        self.parts.append(f'<path d="{d}" stroke="{stroke}" stroke-width="{sw}" fill="{fill}"></path>')

    def arrow(self, x1, y1, x2, y2, stroke="var(--amber)", sw=1.6):
        import math
        self.line(x1, y1, x2, y2, stroke, sw)
        a = math.atan2(y2 - y1, x2 - x1)
        p1 = (x2 - 8 * math.cos(a) + 4 * math.sin(a), y2 - 8 * math.sin(a) - 4 * math.cos(a))
        p2 = (x2 - 8 * math.cos(a) - 4 * math.sin(a), y2 - 8 * math.sin(a) + 4 * math.cos(a))
        self.parts.append(f'<path d="M{x2:.1f} {y2:.1f} L{p1[0]:.1f} {p1[1]:.1f} L{p2[0]:.1f} {p2[1]:.1f} Z" '
                          f'fill="{stroke}" stroke="none"></path>')

    def _text(self, x, y, s, family, size, fill, anchor, weight):
        w = f' font-weight="{weight}"' if weight else ""
        self.parts.append(f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" dominant-baseline="middle" '
                          f'font-family="{family}" font-size="{size}"{w} fill="{fill}">{escape(str(s))}</text>')

    def mono(self, x, y, s, size=11, fill="var(--paper)", anchor="start", weight=None):
        self._text(x, y, s, MONO, size, fill, anchor, weight)

    def sans(self, x, y, s, size=11.5, fill="var(--paper)", anchor="start", weight=None):
        self.sans_labels.append(str(s))
        self._text(x, y, s, SANS, size, fill, anchor, weight)

    def grid(self, x, y, widths, cells, rowh=22, header=True, fills=None, colours=None,
             letters=None, numbers=None, size=10.5, anchors=None):
        """A block of spreadsheet cells. `cells` is a list of rows of strings;
        `fills` and `colours` map (row, col) to a fill and a text colour;
        `letters` puts column letters above, `numbers` row numbers to the
        left (a list, or None)."""
        fills, colours, anchors = fills or {}, colours or {}, anchors or {}
        if letters:
            cx = x
            for i, w in enumerate(widths):
                self.mono(cx + w / 2, y - 9, letters[i], size=9.5, fill="var(--paper-dim)", anchor="middle")
                cx += w
        for r, row in enumerate(cells):
            cy = y + r * rowh
            if numbers:
                self.mono(x - 8, cy + rowh / 2, numbers[r], size=9.5, fill="var(--paper-dim)", anchor="end")
            cx = x
            for c, w in enumerate(widths):
                v = row[c] if c < len(row) else ""
                f = fills.get((r, c), "var(--scan)" if header and r == 0 else "var(--panel)")
                self.rect(cx, cy, w, rowh, fill=f, stroke="var(--wire)")
                if v != "" and v is not None:
                    a = anchors.get(c, "start")
                    tx = cx + 6 if a == "start" else (cx + w - 6 if a == "end" else cx + w / 2)
                    col = colours.get((r, c), "var(--paper)")
                    self.mono(tx, cy + rowh / 2 + 0.5, v, size=size, fill=col, anchor=a,
                              weight="600" if header and r == 0 else None)
                cx += w

    def svg(self):
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" data-fig="{self.name}" '
                f'aria-label="{escape(self.aria, {chr(34): "&quot;"})}">' + "".join(self.parts) + "</svg>")


def T(lang):
    return (lambda en, pt: en) if lang == "en" else (lambda en, pt: pt)
