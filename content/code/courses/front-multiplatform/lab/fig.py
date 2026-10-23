"""fig.py: the few shapes the figures of front-multiplatform are drawn with.

Every figure is written by a short program in lab/figures/, once per language
from the same coordinates, so the Portuguese drawing cannot drift from the
English one. `blocks.py` pastes them into the lessons.

    f = Fig("l01-births", 720, 260, aria="...")
    f.box(40, 30, 160, 44, ["requirement"], stroke="phosphor")
    f.arrow([(200, 52), (280, 52)])
    f.text(360, 240, "a note", italic=True, fill="paper-dim")
    f.json(caption="...")      # the body of a schooling-figure fence
"""
import json
from xml.sax.saxutils import escape

SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def _a(s):
    return escape(s, {'"': "&quot;"})


class Fig:
    def __init__(self, name, w, h, aria):
        self.name, self.w, self.h, self.aria = name, w, h, aria
        self.out, self.markers = [], set()

    def text(self, x, y, s, anchor="middle", mono=False, size=10, fill="paper",
             bold=False, italic=False):
        extra = (' font-weight="600"' if bold else "") + (' font-style="italic"' if italic else "")
        self.out.append(
            f'<text x="{x}" y="{y}" text-anchor="{anchor}" dominant-baseline="middle" '
            f'font-family="{MONO if mono else SANS}" font-size="{size}"{extra} '
            f'fill="var(--{fill})">{escape(s)}</text>')

    def rect(self, x, y, w, h, stroke="wire", fill="panel", width=1.4, dashed=False, rx=4):
        d = ' stroke-dasharray="5 4"' if dashed else ""
        self.out.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="var(--{fill})" '
            f'stroke="var(--{stroke})" stroke-width="{width}"{d}></rect>')

    def box(self, x, y, w, h, lines, stroke="wire", mono=False, size=10, bold=False,
            fill="paper", dashed=False, anchor="middle", ground="panel"):
        self.rect(x, y, w, h, stroke=stroke, dashed=dashed, fill=ground)
        step = size + 3
        top = y + h / 2 - step * (len(lines) - 1) / 2
        tx = x + w / 2 if anchor == "middle" else x + 10
        for i, s in enumerate(lines):
            self.text(tx, round(top + i * step, 1), s, anchor=anchor, mono=mono, size=size,
                      bold=bold, fill=fill)

    def arrow(self, pts, color="paper-dim", head=True, dashed=False, width=1.2, both=False):
        mid = f"{self.name}-ah-{color}"
        if head:
            self.markers.add((mid, color))
        d = "M" + " L".join(f"{x} {y}" for x, y in pts)
        da = ' stroke-dasharray="5 4"' if dashed else ""
        m = f' marker-end="url(#{mid})"' if head else ""
        if both:
            m += f' marker-start="url(#{mid})"'
        self.out.append(f'<path d="{d}" stroke="var(--{color})" stroke-width="{width}" '
                        f'fill="none"{da}{m}></path>')

    def svg(self):
        defs = "".join(
            f'<marker id="{mid}" viewBox="0 0 10 8" refX="9" refY="4" markerWidth="8" '
            f'markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 4 L0 8 z" '
            f'fill="var(--{c})"></path></marker>' for mid, c in sorted(self.markers))
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" data-fig="{self.name}" '
                f'aria-label="{_a(self.aria)}">' + (f"<defs>{defs}</defs>" if defs else "")
                + "".join(self.out) + "</svg>")

    def json(self, caption, same=None):
        d = {"svg": self.svg(), "caption": caption}
        if same:
            d["same"] = same
        return json.dumps(d, ensure_ascii=False)
