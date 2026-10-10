#!/usr/bin/env python3
"""Every diagram in the design-patterns course, drawn in both languages.

    python3 figures.py            # rewrite every figure in the lessons
    python3 figures.py --list     # the names, and the lesson each lives in
    python3 figures.py le-xxxx    # only that lesson's prose

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
The drawings are in figs/, one file per lesson. A placeholder line
`@@fig:<name>@@` is replaced the same way, which is how a figure enters a
section the first time.

The framework is threat-modeling's figures.py, with one notation added: the
class box of lesson 1, `Fig.klass`, a name over its fields over its methods,
the way every class diagram in this course is drawn. An arrow with a hollow
head is "is a" (inheritance or implementing a protocol); a plain arrow is
"uses" or "calls"; a line with a diamond at the owner's end is "has a".

Only palette tokens are used, so each drawing turns over with the theme like
the page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel. Standard library only.
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
            mid = f'dp-ah{stroke.replace("--", "-")}'
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

    # ---- the notation of lesson 1

    def klass(self, x, y, w, name, fields=(), methods=(), size=10, stroke='--phosphor',
              italic=False, stereo=None):
        """A class box with its top-left corner at x, y: the name, then fields, then methods.
        Fields and methods are code, so they are drawn in the mono face. Returns the height."""
        row = size * 1.45
        head = row * (2 if stereo else 1) + 8
        h = head + (len(fields) * row + 8 if fields else 0) + (len(methods) * row + 8 if methods else 0)
        self.rect(x, y, w, h, stroke=stroke, fill='--panel', width=1.4, rx=2)
        ty = y + 4 + row / 2
        if stereo:
            self.text(x + w / 2, ty, stereo, size=size - 1, fill='--paper-dim', mono=True)
            ty += row
        self.text(x + w / 2, ty, name, size=size + 0.5, weight='600', mono=True, italic=italic)
        cy = y + head
        for group in (fields, methods):
            if not group:
                continue
            self.line(x, cy, x + w, cy, stroke=stroke, width=1)
            for i, s in enumerate(group):
                self.text(x + 8, cy + 4 + row / 2 + i * row, s, size=size - 0.5, anchor='start', mono=True)
            cy += len(group) * row + 8
        return h

    def isa(self, pts, stroke='--paper-dim', width=1.3, dash=None):
        """Inheritance or implementation: a line ending in a hollow triangle at the parent."""
        self.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke=stroke, width=width, dash=dash)
        (x1, y1), (x2, y2) = pts[-2], pts[-1]
        import math
        a = math.atan2(y2 - y1, x2 - x1)
        L, W = 12, 7
        bx, by = x2 - L * math.cos(a), y2 - L * math.sin(a)
        px, py = -math.sin(a) * W, math.cos(a) * W
        self.parts.append(f'<path d="M{x2:.1f} {y2:.1f} L{bx + px:.1f} {by + py:.1f} L{bx - px:.1f} {by - py:.1f} Z" '
                          f'stroke="var({stroke})" stroke-width="{width}" fill="var(--panel)"></path>')

    def has(self, pts, stroke='--paper-dim', width=1.3, filled=True):
        """Composition: a line with a diamond at the owner's end, which is pts[0]."""
        self.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke=stroke, width=width)
        (x1, y1), (x2, y2) = pts[0], pts[1]
        import math
        a = math.atan2(y2 - y1, x2 - x1)
        L, W = 9, 5.5
        mx, my = x1 + L * math.cos(a), y1 + L * math.sin(a)
        ex, ey = x1 + 2 * L * math.cos(a), y1 + 2 * L * math.sin(a)
        px, py = -math.sin(a) * W, math.cos(a) * W
        fill = f'var({stroke})' if filled else 'var(--panel)'
        self.parts.append(f'<path d="M{x1:.1f} {y1:.1f} L{mx + px:.1f} {my + py:.1f} L{ex:.1f} {ey:.1f} L{mx - px:.1f} {my - py:.1f} Z" '
                          f'stroke="var({stroke})" stroke-width="{width}" fill="{fill}"></path>')

    def box(self, x, y, w, h, rows, size=10, stroke='--wire', fill='--panel', mono=False, rx=4,
            dash=None, fillt='--paper'):
        """A plain box centred on x, y with its rows of text."""
        self.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill=fill, rx=rx, dash=dash)
        if rows:
            self.lines(x, y, rows, size=size, mono=mono, fill=fillt)

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
    only = [a for a in sys.argv[1:] if a.startswith('le-')]
    for f in sorted(glob.glob(os.path.join(HERE, 'figs', 'l*.py'))):
        try:
            importlib.import_module('figs.' + os.path.basename(f)[:-3])
        except Exception as err:  # another lesson's drawing being written; say so, carry on
            if not only:
                raise
            print(f'skipped {os.path.basename(f)}: {err}')
    if '--list' in sys.argv:
        for name, (lesson, _) in sorted(FIGURES.items(), key=lambda kv: (kv[1][0], kv[0])):
            print(f'{lesson:2}  {name}')
        for name in sorted(PICTURES):
            print(f' -  images/{name}.svg')
        return
    changed = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        if only and os.path.basename(os.path.dirname(path)) not in only:
            continue
        changed += apply(path)
    if PICTURES:
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
