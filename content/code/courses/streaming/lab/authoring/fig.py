"""Figure kit: build an inline SVG figure for EN and PT from one drawing function.

A figure module defines NAME, W, H, draw(t) where t(en_text) returns the text in the
current language (from PT dict), LABEL (en, pt) and CAPTION (en, pt), optional SAME (pt labels
kept as-is). `figput.py MODULE MD...` puts it into the .md / .pt.md at @@fig:NAME@@ or
replaces the fence that already carries data-fig="NAME".
"""
from xml.sax.saxutils import escape as _e
SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"
import zlib
def _h(s): return zlib.crc32(s.encode()) % 9999
def esc(s): return _e(s, {'"': "&quot;"})
class S:
    def __init__(self, w, h, label, name):
        self.w, self.h, self.out = w, h, []
        self.label, self.name = label, name
        self.markers = set()
    def rect(self, x, y, w, h, fill="var(--panel)", stroke="var(--wire)", sw=1.2, rx=4, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}></rect>')
    def text(self, x, y, s, size=10, fill="var(--paper)", anchor="middle", weight=None, mono=False):
        wt = f' font-weight="{weight}"' if weight else ""
        fam = MONO if mono else SANS
        self.out.append(f'<text x="{x}" y="{y}" text-anchor="{anchor}" dominant-baseline="middle" font-family="{esc(fam)}" font-size="{size}"{wt} fill="{fill}">{esc(s)}</text>')
    def line(self, x1, y1, x2, y2, stroke="var(--paper-dim)", sw=1.2, arrow=False, dash=None):
        m = ""
        if arrow:
            self.markers.add(stroke); m = f' marker-end="url(#{self.name}-ah-{_h(stroke)})"'
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.out.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="{sw}"{d}{m}></line>')
    def path(self, d, stroke="var(--paper-dim)", sw=1.2, fill="none", arrow=False, dash=None):
        m = ""
        if arrow:
            self.markers.add(stroke); m = f' marker-end="url(#{self.name}-ah-{_h(stroke)})"'
        ds = f' stroke-dasharray="{dash}"' if dash else ""
        self.out.append(f'<path d="{d}" stroke="{stroke}" stroke-width="{sw}" fill="{fill}"{ds}{m}></path>')
    def circle(self, cx, cy, r, fill="var(--phosphor)", stroke="none", sw=1.2):
        self.out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"></circle>')
    def svg(self):
        defs = ""
        if self.markers:
            defs = "<defs>" + "".join(
                f'<marker id="{self.name}-ah-{_h(c)}" viewBox="0 0 10 8" refX="9" refY="4" markerWidth="8" markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 4 L0 8 z" fill="{c}"></path></marker>'
                for c in sorted(self.markers)) + "</defs>"
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" aria-label="{esc(self.label)}" data-fig="{self.name}">'
                + defs + "".join(self.out) + "</svg>")
