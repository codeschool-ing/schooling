#!/usr/bin/env python3
"""Every diagram in the threat-modeling course, drawn in both languages.

    python3 figures.py            # rewrite every figure in the lessons, and images/
    python3 figures.py --list     # the names, and the lesson each lives in

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
The drawings are in figs/, one file per lesson. A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time. The pictures a `labelling` question
names are written to images/ and carry no lettering at all, because the labels
are the answer.

The shape and the framework are the statistics course's figures.py. Only
palette tokens are used, so each drawing turns over with the theme like the
page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which do
not reach AA on the light panel.

THE NOTATION IS THE ONE LESSON 2 TEACHES, AND EVERY FIGURE KEEPS IT: an
external entity is a rectangle, a process a circle (a rounded box when it has
to hold a long name), a data store two parallel lines, a data flow an arrow
with its label beside it, and a trust boundary a dashed amber line.

Standard library only.
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"
LANG = 'en'


def T(en, pt):
    """The label in the language being drawn."""
    return en if LANG == 'en' else pt


def esc(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            .replace('"', '&quot;'))


def width(s, size=10, weight=None):
    """A generous estimate of a label's width in IBM Plex Sans; figure-fit measures the truth."""
    k = 0.56 if weight else 0.53
    return len(s) * size * k


class Fig:
    def __init__(self, name, w, h, label):
        self.name, self.w, self.h, self.label = name, w, h, label
        self.parts = []
        self.markers = set()

    def text(self, x, y, s, size=10, anchor='middle', fill='--paper', weight=None, mono=False,
             italic=False):
        w = f' font-weight="{weight}"' if weight else ''
        it = ' font-style="italic"' if italic else ''
        self.parts.append(
            f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" dominant-baseline="middle" '
            f'font-family="{MONO if mono else SANS}" font-size="{size}"{w}{it} '
            f'fill="var({fill})">{esc(s)}</text>')

    def lines(self, x, y, rows, size=10, gap=None, **kw):
        """Several lines of text centred vertically on y."""
        gap = gap or size * 1.3
        top = y - gap * (len(rows) - 1) / 2
        for i, r in enumerate(rows):
            self.text(x, top + i * gap, r, size=size, **kw)

    def path(self, d, stroke='--paper-dim', width=1.2, fill='none', dash=None, arrow=False,
             opacity=None, cap=None, start=False):
        extra = ''
        if dash:
            extra += f' stroke-dasharray="{dash}"'
        if arrow or start:
            mid = f'tm-ah{stroke.replace("--", "-")}'
            self.markers.add((mid, stroke))
            if arrow:
                extra += f' marker-end="url(#{mid})"'
            if start:
                extra += f' marker-start="url(#{mid})"'
        if opacity is not None:
            extra += f' fill-opacity="{opacity}"'
        if cap:
            extra += f' stroke-linecap="{cap}"'
        sv = 'none' if stroke is None else f'var({stroke})'
        fv = fill if fill == 'none' else f'var({fill})'
        self.parts.append(f'<path d="{d}" stroke="{sv}" stroke-width="{width}" fill="{fv}"{extra}></path>')

    def line(self, x1, y1, x2, y2, **kw):
        self.path(f'M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}', **kw)

    def arrow(self, pts, **kw):
        kw.setdefault('arrow', True)
        self.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), **kw)

    def rect(self, x, y, w, h, stroke='--wire', fill='--panel', width=1.2, rx=4, dash=None):
        extra = f' stroke-dasharray="{dash}"' if dash else ''
        sv = 'none' if stroke is None else f'var({stroke})'
        self.parts.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" '
            f'fill="var({fill})" stroke="{sv}" stroke-width="{width}"{extra}></rect>')

    def circle(self, x, y, r, fill='--phosphor', stroke=None, width=1.2, dash=None):
        st = f' stroke="var({stroke})" stroke-width="{width}"' if stroke else ''
        if dash:
            st += f' stroke-dasharray="{dash}"'
        fv = 'none' if fill is None else f'var({fill})'
        self.parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{fv}"{st}></circle>')

    # ---- the notation of lesson 2

    def entity(self, x, y, w, h, rows, size=10, stroke='--paper-dim'):
        """An external entity: a rectangle, centred on x, y."""
        self.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill='--panel', width=1.4, rx=1)
        if rows:
            self.lines(x, y, rows, size=size)

    def process(self, x, y, r, rows, size=10, stroke='--phosphor'):
        """A process: a circle, centred on x, y. The label sits in a box the circle holds."""
        self.circle(x, y, r, fill='--panel', stroke=stroke, width=1.6)
        if rows:
            self.lines(x, y, rows, size=size)

    def pbox(self, x, y, w, h, rows, size=10, stroke='--phosphor'):
        """A process with a long name: a box with fully rounded ends."""
        self.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill='--panel', width=1.6, rx=h / 2)
        if rows:
            self.lines(x, y, rows, size=size)

    def store(self, x, y, w, rows, size=10, h=30, stroke='--amber'):
        """A data store: two parallel lines, open at the ends."""
        self.rect(x - w / 2, y - h / 2, w, h, stroke=None, fill='--panel', rx=0)
        self.line(x - w / 2, y - h / 2, x + w / 2, y - h / 2, stroke=stroke, width=1.6)
        self.line(x - w / 2, y + h / 2, x + w / 2, y + h / 2, stroke=stroke, width=1.6)
        if rows:
            self.lines(x, y, rows, size=size)

    def boundary(self, pts, label=None, at=None, anchor='start', size=9.5, close=False):
        """A trust boundary: a dashed amber line through pts."""
        d = 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + (' Z' if close else '')
        self.path(d, stroke='--amber', width=1.5, dash='6 4')
        if label and at:
            self.text(at[0], at[1], label, size=size, anchor=anchor, fill='--amber', italic=True)

    def zone(self, x, y, w, h, label=None, size=9.5, anchor='start'):
        """A trust boundary drawn round a region, as a dashed path rather than a box."""
        self.boundary([(x, y), (x + w, y), (x + w, y + h), (x, y + h)], close=True)
        if label:
            lx = x + 8 if anchor == 'start' else x + w - 8
            self.text(lx, y + 12, label, size=size, anchor=anchor, fill='--amber', italic=True)

    def svg(self):
        defs = ''
        if self.markers:
            defs = '<defs>' + ''.join(
                f'<marker id="{self.name}-{m}" viewBox="0 0 10 8" refX="9" refY="4" markerWidth="8" '
                f'markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 4 L0 8 z" '
                f'fill="var({c})"></path></marker>' for m, c in sorted(self.markers)) + '</defs>'
        body = ''.join(self.parts)
        for m, _ in self.markers:
            body = body.replace(f'url(#{m})', f'url(#{self.name}-{m})')
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" data-fig="{self.name}" '
                f'aria-label="{esc(self.label)}">{defs}{body}</svg>')

    def picture(self):
        """The same drawing as a standalone file for images/, which must carry no text."""
        assert not any(p.startswith('<text') for p in self.parts), f'{self.name} has lettering'
        s = self.svg().replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ', 1)
        return s.replace(f' data-fig="{self.name}"', '')


# --------------------------------------------------------------- the machinery

FIGURES = {}
PICTURES = {}


def figure(name, lesson):
    def wrap(f):
        FIGURES[name] = (lesson, f)
        return f
    return wrap


def picture(name):
    def wrap(f):
        PICTURES[name] = f
        return f
    return wrap


def fence(name, lang):
    global LANG
    LANG = lang
    _, f = FIGURES[name]
    fig, caption = f()
    LANG = 'en'
    return {'svg': fig.svg(), 'caption': caption}


def prose_labels(svg):
    out = []
    for m in re.finditer(r'<text [^>]*font-family="([^"]*)"[^>]*>(.*?)</text>', svg):
        if 'Plex Sans' not in m.group(1):
            continue
        t = re.sub(r'<[^>]+>', '', m.group(2))
        t = (t.replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '"')
             .replace('&amp;', '&'))
        t = ' '.join(t.split())
        if t and re.search(r'[^\W\d_]', t):
            out.append(t)
    return out


def render(name, lang):
    block = fence(name, lang)
    if lang != 'en':
        en = prose_labels(fence(name, 'en')['svg'])
        mine = prose_labels(block['svg'])
        if len(en) != len(mine):
            raise SystemExit(f'{name}: {len(en)} English labels and {len(mine)} in {lang}')
        same = sorted({a for a, b in zip(en, mine) if a == b})
        if same:
            block['same'] = same
    return '```schooling-figure\n' + json.dumps(block, ensure_ascii=False) + '\n```'


FENCE = re.compile(r'```schooling-figure\n(\{.*?\})\n```', re.S)
PLACEHOLDER = re.compile(r'^@@fig:([a-z0-9-]+)@@$', re.M)


def apply(path):
    lang = 'pt' if path.endswith('.pt.md') else 'en'
    text = open(path, encoding='utf-8').read()

    def swap_fence(m):
        found = re.search(r'data-fig=\\"([a-z0-9-]+)\\"', m.group(1))
        if not found or found.group(1) not in FIGURES:
            return m.group(0)
        return render(found.group(1), lang)

    def swap_placeholder(m):
        if m.group(1) not in FIGURES:
            raise SystemExit(f'{path}: no figure called {m.group(1)}')
        return render(m.group(1), lang)

    new = FENCE.sub(swap_fence, text)
    new = PLACEHOLDER.sub(swap_placeholder, new)
    if new != text:
        open(path, 'w', encoding='utf-8').write(new)
        return True
    return False


def main():
    import importlib
    for f in sorted(glob.glob(os.path.join(HERE, 'figs', 'l*.py'))):
        importlib.import_module('figs.' + os.path.basename(f)[:-3])
    if '--list' in sys.argv:
        for name, (lesson, _) in sorted(FIGURES.items(), key=lambda kv: (kv[1][0], kv[0])):
            print(f'{lesson:2}  {name}')
        for name in sorted(PICTURES):
            print(f' -  images/{name}.svg')
        return
    changed = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        changed += apply(path)
    os.makedirs(os.path.join(HERE, 'images'), exist_ok=True)
    for name, f in PICTURES.items():
        out = os.path.join(HERE, 'images', name + '.svg')
        svg = f().picture() + '\n'
        if not os.path.exists(out) or open(out).read() != svg:
            open(out, 'w').write(svg)
            changed += 1
    print(f'{len(FIGURES)} figures, {len(PICTURES)} pictures, {changed} files rewritten')


sys.modules.setdefault('figures', sys.modules[__name__])
sys.dont_write_bytecode = True
sys.path.insert(0, HERE)

if __name__ == '__main__':
    main()
