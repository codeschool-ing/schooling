"""A small drawing kit for python-data's concept diagrams, in both languages at once.

THE STUDENT NEVER SEES THIS FILE. `../figures.py` runs every `figs/<lesson id>.py` and writes what
they draw into the lessons.

A figure is drawn once, with every label given in English and in Portuguese, and comes out as two
SVGs with the same geometry. Only palette tokens are used — `--paper`, `--paper-dim`, `--wire`,
`--phosphor`, `--phosphor-dim`, `--amber`, `--panel`, `--scan`, `--ink` — so each turns over with
the theme like the page around it, and text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel.

Code is drawn in IBM Plex Mono and prose in IBM Plex Sans, and that is not a style choice:
`check-figures` asks for the sans labels to be translated and leaves the mono ones alone. A sans
label that is the same word in both languages goes in the figure's `same` list, which this kit
fills from the labels themselves, so it can never name a label the figure does not draw.
"""
import html
import json

SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def esc(s):
    return html.escape(s, quote=True)


class Fig:
    def __init__(self, name, width, height, label, caption):
        self.name, self.w, self.h = name, width, height
        self.label, self.caption = label, caption  # each a pair (en, pt)
        self.parts = []  # functions of lang -> markup
        self.sans = []   # (en, pt) of every sans label
        self.arrowhead = False

    def _t(self, pair, lang):
        return pair[0] if lang == "en" or len(pair) == 1 else pair[1]

    def text(self, x, y, en, pt=None, mono=False, size=11, fill="paper", anchor="middle",
             weight=None):
        pair = (en, en if pt is None and mono else pt)
        if not mono:
            if pt is None:
                raise ValueError(f"{self.name}: the sans label {en!r} needs its Portuguese")
            self.sans.append(pair)
        family = MONO if mono else SANS
        w = f' font-weight="{weight}"' if weight else ""

        def draw(lang):
            return (f'<text x="{x}" y="{y}" text-anchor="{anchor}" dominant-baseline="middle" '
                    f'font-family="{family}" font-size="{size}" fill="var(--{fill})"{w}>'
                    f'{esc(self._t(pair, lang))}</text>')
        self.parts.append(draw)

    def rect(self, x, y, w, h, fill="panel", stroke="wire", dash=False, rx=4, width=1.5):
        d = ' stroke-dasharray="5 4"' if dash else ""
        f = "none" if fill is None else f"var(--{fill})"
        self.parts.append(lambda lang: (
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{f}" '
            f'stroke="var(--{stroke})" stroke-width="{width}"{d}></rect>'))

    def line(self, x1, y1, x2, y2, stroke="wire", width=1.5, arrow=False, dash=False):
        if arrow:
            self.arrowhead = True
        m = f' marker-end="url(#{self.name}-ah)"' if arrow else ""
        d = ' stroke-dasharray="5 4"' if dash else ""
        self.parts.append(lambda lang: (
            f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="var(--{stroke})" '
            f'stroke-width="{width}"{m}{d}></line>'))

    def path(self, d, stroke="wire", width=1.5, arrow=False, fill="none"):
        if arrow:
            self.arrowhead = True
        m = f' marker-end="url(#{self.name}-ah)"' if arrow else ""
        f = "none" if fill == "none" else f"var(--{fill})"
        self.parts.append(lambda lang: (
            f'<path d="{d}" fill="{f}" stroke="var(--{stroke})" stroke-width="{width}"{m}></path>'))

    def box(self, x, y, w, h, en, pt=None, mono=False, fill="panel", stroke="wire",
            ink="paper", size=12, weight="600", sub=None, sub_mono=False, dash=False):
        """A rectangle with a label in its middle, and an optional second line under it."""
        self.rect(x, y, w, h, fill=fill, stroke=stroke, dash=dash)
        cy = y + h / 2 - (8 if sub else 0)
        self.text(x + w / 2, cy, en, pt, mono=mono, size=size, fill=ink, weight=weight)
        if sub:
            self.text(x + w / 2, cy + 17, sub[0], sub[1] if len(sub) > 1 else None,
                      mono=sub_mono, size=10, fill="paper-dim")

    def svg(self, lang):
        defs = ""
        if self.arrowhead:
            defs = (f'<defs><marker id="{self.name}-ah" viewBox="0 0 10 8" refX="9" refY="4" '
                    f'markerWidth="8" markerHeight="7" orient="auto-start-reverse">'
                    f'<path d="M0 0 L10 4 L0 8 z" fill="var(--paper-dim)"></path></marker></defs>')
        label = self.label[0] if lang == "en" else self.label[1]
        body = "".join(p(lang) for p in self.parts)
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" aria-label="{esc(label)}" '
                f'data-fig="{self.name}">{defs}{body}</svg>')

    def fence(self, lang):
        block = {"svg": self.svg(lang),
                 "caption": self.caption[0] if lang == "en" else self.caption[1]}
        if lang == "pt":
            same = sorted({en for en, pt in self.sans if en == pt})
            if same:
                block["same"] = same
        return "```schooling-figure\n" + json.dumps(block, ensure_ascii=False) + "\n```\n"
