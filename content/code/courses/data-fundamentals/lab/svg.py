"""A small drawing kit for the figures of data-fundamentals. THE AUTHOR'S.

A figure is described once, with every label in both languages, and drawn
twice. Only palette tokens are used, so a drawing turns over with the theme:
`--ink` is the ground, `--paper` what is written on it, `--panel` a box,
`--wire` a line, `--phosphor` and `--amber` the two accents. Text is never
drawn in `--wire` or `--phosphor-dim`, which do not reach AA on the light panel.

Prose is set in IBM Plex Sans and code in IBM Plex Mono, which is how
check-figures tells a label to translate from a symbol. A sans label that reads
the same in both languages goes into the translated figure's `same` list by
itself, because it was written once and meant once.

    from svg import Fig
    f = Fig('name', 720, 200, caption=('…', '…'), label=('…', '…'))
    f.box(20, 20, 160, 60, ('the app', 'o aplicativo'), stroke='phosphor')
    f.arrow(180, 50, 260, 50)
    FIGURES = [f]
"""
import json
import re

SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def _esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def _pair(t):
    if t is None:
        return ('', '')
    if isinstance(t, str):
        return (t, t)
    return t


class Fig:
    def __init__(self, name, w, h, caption, label):
        self.name, self.w, self.h = name, w, h
        self.caption, self.label = _pair(caption), _pair(label)
        self.items = []
        self.sans = []      # (en, pt) of every label drawn in the prose face

    # ---- primitives -------------------------------------------------------
    def rect(self, x, y, w, h, fill='panel', stroke='wire', sw=1.5, dash=None, rx=3):
        d = f' stroke-dasharray="{dash}"' if dash else ''
        self.items.append(lambda lang: (
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" '
            f'fill="var(--{fill})" stroke="var(--{stroke})" stroke-width="{sw}"{d}></rect>'))

    def text(self, x, y, t, size=11, anchor='middle', color='paper', weight=None, mono=False):
        en, pt = _pair(t)
        if not mono and re.search(r'[^\W\d_]', en):
            self.sans.append((en, pt))
        fam = MONO if mono else SANS
        wt = f' font-weight="{weight}"' if weight else ''

        def draw(lang):
            s = en if lang == 'en' else pt
            return (f'<text x="{x}" y="{y}" text-anchor="{anchor}" dominant-baseline="middle" '
                    f'font-family="{fam}" font-size="{size}" fill="var(--{color})"{wt}>'
                    f'{_esc(s)}</text>')
        self.items.append(draw)

    def line(self, x1, y1, x2, y2, color='paper-dim', sw=1.5, dash=None, head=False):
        d = f' stroke-dasharray="{dash}"' if dash else ''
        m = f' marker-end="url(#{self.name}-ah)"' if head else ''
        self.items.append(lambda lang: (
            f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="var(--{color})" '
            f'stroke-width="{sw}"{d}{m}></line>'))

    def arrow(self, x1, y1, x2, y2, color='paper-dim', dash=None):
        self.line(x1, y1, x2, y2, color=color, dash=dash, head=True)

    def circle(self, cx, cy, r, fill='panel', stroke='wire', sw=1.5):
        self.items.append(lambda lang: (
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="var(--{fill})" '
            f'stroke="var(--{stroke})" stroke-width="{sw}"></circle>'))

    def poly(self, points, fill='none', stroke='wire', sw=1.5, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ''
        pts = ' '.join(f'{x},{y}' for x, y in points)
        self.items.append(lambda lang: (
            f'<polygon points="{pts}" fill="{fill if fill == "none" else "var(--" + fill + ")"}" '
            f'stroke="var(--{stroke})" stroke-width="{sw}"{d}></polygon>'))

    # ---- composites -------------------------------------------------------
    def box(self, x, y, w, h, lines, stroke='wire', fill='panel', size=11, color='paper',
            weight=None, mono=False, title=None, dash=None):
        """A rectangle with centred lines of text. `lines` is one label or a
        list of them, each a str or an (en, pt) pair. `title` is a bold first
        line in the sans face."""
        self.rect(x, y, w, h, fill=fill, stroke=stroke, dash=dash)
        rows = []
        if title is not None:
            rows.append((title, True, False))
        if lines is not None:
            ls = lines if isinstance(lines, list) else [lines]
            rows += [(l, False, mono) for l in ls]
        step = size + 5
        top = y + h / 2 - step * (len(rows) - 1) / 2
        for i, (t, bold, mn) in enumerate(rows):
            self.text(x + w / 2, round(top + i * step, 1), t, size=size + (0.5 if bold else 0),
                      color=color, weight='600' if bold else weight, mono=mn)

    # ---- output -----------------------------------------------------------
    def svg(self, lang):
        label = self.label[0] if lang == 'en' else self.label[1]
        head = (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" aria-label="{_esc(label)}" '
                f'data-fig="{self.name}"><defs><marker id="{self.name}-ah" viewBox="0 0 10 8" '
                f'refX="9" refY="4" markerWidth="8" markerHeight="7" orient="auto-start-reverse">'
                f'<path d="M0 0 L10 4 L0 8 z" fill="var(--paper-dim)"></path></marker></defs>')
        return head + ''.join(i(lang) for i in self.items) + '</svg>'

    def fence(self, lang):
        block = {'svg': self.svg(lang), 'caption': self.caption[0 if lang == 'en' else 1]}
        if lang != 'en':
            same = sorted({en for en, pt in self.sans if en == pt})
            if same:
                block['same'] = same
        return '```schooling-figure\n' + json.dumps(block, ensure_ascii=False) + '\n```'
