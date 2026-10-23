#!/usr/bin/env python3
"""Every diagram in the architecture-modeling course, drawn in both languages.

    python3 figures.py            # rewrite every figure in the lessons, and images/
    python3 figures.py --list     # the names, and the lesson each lives in

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
The drawings are in figs/, one file per lesson. A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time. The pictures a `labelling` question
names are written to images/ and carry no lettering at all, because the labels
are the answer.

The shape and the framework are threat-modeling's figures.py. Only
palette tokens are used, so each drawing turns over with the theme like the
page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which do
not reach AA on the light panel.

A LABELLING PICTURE IS THE SAME DRAWING WITH ITS LETTERING TAKEN OUT, because
this course's questions show the student a finished diagram and ask what is
wrong with it, or what each part is: the platform cannot receive a drawing,
and reading one critically is the half of the skill a grader can check.

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


def marker(fig, mid, colour, head):
    """The arrowheads UML tells apart: filled, open, hollow triangle, and the two diamonds."""
    c = f'var({colour})'
    shapes = {
        'fill': ('0 0 10 8', 9, 4, 8, 7, f'<path d="M0 0 L10 4 L0 8 z" fill="{c}"></path>'),
        'open': ('0 0 10 8', 9.5, 4, 9, 8, f'<path d="M0 0.5 L9.5 4 L0 7.5" fill="none" stroke="{c}" stroke-width="1.3"></path>'),
        'hollow': ('0 0 12 10', 11, 5, 11, 10, f'<path d="M1 1 L11 5 L1 9 z" fill="var(--ink)" stroke="{c}" stroke-width="1.1"></path>'),
        'diamond': ('0 0 18 10', 17, 5, 13, 8, f'<path d="M1 5 L9 1 L17 5 L9 9 z" fill="{c}" stroke="{c}" stroke-width="1"></path>'),
        'odiamond': ('0 0 18 10', 17, 5, 13, 8, f'<path d="M1 5 L9 1 L17 5 L9 9 z" fill="var(--ink)" stroke="{c}" stroke-width="1.1"></path>'),
    }
    vb, rx, ry, mw, mh, body = shapes[head]
    return (f'<marker id="{fig}-{mid}" viewBox="{vb}" refX="{rx}" refY="{ry}" markerWidth="{mw}" '
            f'markerHeight="{mh}" markerUnits="userSpaceOnUse" orient="auto-start-reverse">{body}</marker>')


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
             opacity=None, cap=None, start=False, head='fill'):
        extra = ''
        if dash:
            extra += f' stroke-dasharray="{dash}"'
        if arrow or start:
            mid = f'am-{head}{stroke.replace("--", "-")}'
            self.markers.add((mid, stroke, head))
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

    # ---- the shapes this course draws again and again

    def box(self, x, y, w, h, rows, size=10, stroke='--wire', fill='--panel', sub=None,
            rx=4, dash=None, weight='600', width=1.4):
        """An element centred on x, y: a name in bold and, under it, a type or a note."""
        self.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill=fill, rx=rx, dash=dash, width=width)
        rows = [rows] if isinstance(rows, str) else rows
        sub = [sub] if isinstance(sub, str) else (sub or [])
        n = len(rows) + len(sub)
        gap = size * 1.3
        top = y - gap * (n - 1) / 2
        for i, r in enumerate(rows):
            self.text(x, top + i * gap, r, size=size, weight=weight)
        for j, r in enumerate(sub):
            self.text(x, top + (len(rows) + j) * gap, r, size=size - 1.5, fill='--paper-dim')

    def person(self, x, y, rows, size=10, stroke='--phosphor'):
        """A person: a head over a box, C4's way and the use-case actor's cousin."""
        self.circle(x, y - 34, 12, fill='--panel', stroke=stroke, width=1.4)
        self.rect(x - 46, y - 20, 92, 44, stroke=stroke, fill='--panel', rx=12, width=1.4)
        rows = [rows] if isinstance(rows, str) else [r for r in (rows or []) if r]
        if rows:
            self.lines(x, y + 2, rows, size=size)

    def actor(self, x, y, label=None, size=10, stroke='--paper'):
        """A UML actor: the stick figure, with its name under it."""
        self.circle(x, y - 22, 7, fill=None, stroke=stroke, width=1.4)
        self.line(x, y - 15, x, y + 6, stroke=stroke, width=1.4)
        self.line(x - 11, y - 8, x + 11, y - 8, stroke=stroke, width=1.4)
        self.line(x, y + 6, x - 9, y + 20, stroke=stroke, width=1.4)
        self.line(x, y + 6, x + 9, y + 20, stroke=stroke, width=1.4)
        if label:
            self.text(x, y + 32, label, size=size)

    def ellipse(self, x, y, rx, ry, rows=None, size=10, stroke='--phosphor', fill='--panel', dash=None):
        st = f' stroke-dasharray="{dash}"' if dash else ''
        self.parts.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx}" ry="{ry}" fill="var({fill})" '
                          f'stroke="var({stroke})" stroke-width="1.4"{st}></ellipse>')
        if rows:
            self.lines(x, y, [rows] if isinstance(rows, str) else rows, size=size)

    def cls(self, x, y, w, name, attrs=(), ops=(), size=9.5, stroke='--paper-dim', stereo=None):
        """A UML class with its top-left corner at x, y: name, attributes, operations."""
        row = size * 1.45
        head = row * (2 if stereo else 1) + 8
        h = head + max(len(attrs), 0.4) * row + 8 + (max(len(ops), 0.4) * row + 8 if ops is not None else 0)
        self.rect(x, y, w, h, stroke=stroke, fill='--panel', rx=1, width=1.4)
        cy = y + 4 + row / 2
        if stereo:
            self.text(x + w / 2, cy, stereo, size=size - 1, fill='--paper-dim', mono=True)
            cy += row
        self.text(x + w / 2, cy, name, size=size, weight='600', mono=True)
        yy = y + head
        self.line(x, yy, x + w, yy, stroke=stroke, width=1)
        for i, a in enumerate(attrs):
            self.text(x + 6, yy + 4 + row / 2 + i * row, a, size=size - 0.5, anchor='start', mono=True)
        yy += max(len(attrs), 0.4) * row + 8
        if ops is not None:
            self.line(x, yy, x + w, yy, stroke=stroke, width=1)
            for i, o in enumerate(ops):
                self.text(x + 6, yy + 4 + row / 2 + i * row, o, size=size - 0.5, anchor='start', mono=True)
        return h

    def node(self, x, y, w, h, rows=None, size=10, stroke='--paper-dim', depth=10):
        """A UML deployment node: a box with depth, top-left corner at x, y."""
        d = depth
        self.path(f'M{x:.1f} {y:.1f} L{x + d:.1f} {y - d:.1f} L{x + w + d:.1f} {y - d:.1f} '
                  f'L{x + w + d:.1f} {y + h - d:.1f} L{x + w:.1f} {y + h:.1f}', stroke=stroke, width=1.3,
                  fill='--ink')
        self.line(x + w, y, x + w + d, y - d, stroke=stroke, width=1.3)
        self.rect(x, y, w, h, stroke=stroke, fill='--panel', rx=0, width=1.3)
        if rows:
            self.text(x + 8, y + 14, rows, size=size, anchor='start', weight='600')

    def state(self, x, y, w, h, rows, size=10, stroke='--phosphor', fill='--panel'):
        """A state: a box with rounded corners, centred on x, y."""
        self.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill=fill, rx=min(14, h / 2), width=1.5)
        if rows:
            self.lines(x, y, [rows] if isinstance(rows, str) else rows, size=size)

    def start(self, x, y):
        self.circle(x, y, 7, fill='--paper')

    def end(self, x, y):
        self.circle(x, y, 10, fill=None, stroke='--paper', width=1.4)
        self.circle(x, y, 5.5, fill='--paper')

    def diamond(self, x, y, s=12, stroke='--paper-dim', fill='--panel'):
        self.path(f'M{x:.1f} {y - s:.1f} L{x + s:.1f} {y:.1f} L{x:.1f} {y + s:.1f} L{x - s:.1f} {y:.1f} Z',
                  stroke=stroke, fill=fill, width=1.4)

    def tag(self, x, y, s, size=9.5, anchor='middle', fill='--paper', **kw):
        """A label for a line. It is placed BESIDE the line, never on it: figure-fit refuses a
        line through a label, and a patch painted behind the words would hide the line instead."""
        self.text(x, y, s, size=size, anchor=anchor, fill=fill, **kw)

    def badge(self, x, y, n, fill='--amber'):
        """A numbered marker, for a figure the text walks through by number."""
        self.circle(x, y, 9, fill='--ink', stroke=fill, width=1.4)
        self.text(x, y + 0.5, str(n), size=9.5, weight='600', fill=fill)

    def svg(self):
        defs = ''
        if self.markers:
            defs = '<defs>' + ''.join(marker(self.name, m, c, h) for m, c, h in sorted(self.markers)) + '</defs>'
        body = ''.join(self.parts)
        for m, _, _ in self.markers:
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
            print(f'WARNING {path}: no figure called {m.group(1)} yet; the placeholder stays', file=sys.stderr)
            return m.group(0)
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
