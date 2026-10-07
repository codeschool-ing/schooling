#!/usr/bin/env python3
"""Every diagram in the visualization course, drawn from horta.py's numbers.

A chart drawn by hand is a claim about data nobody can check, and in a course
about charts that would be the one thing it must not do. These are computed:
the bars, the lines and the points come from the same data the student's own
scripts read, so a figure cannot drift from the sentence beside it.

    python3 figures.py            # rewrite every figure and every picture
    python3 figures.py --list     # the names, and the lesson each lives in

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

Inline figures use only palette tokens — `--paper`, `--paper-dim`, `--wire`,
`--phosphor`, `--phosphor-dim`, `--amber`, `--panel`, `--scan`, `--ink` — so
each one turns over with the theme like the page around it. Text is never drawn
in `--wire` or `--phosphor-dim`, which do not reach AA on the light panel.

THE COLOUR LESSONS ARE THE EXCEPTION, and on purpose. A palette is a set of
literal colours, and a lesson about viridis has to show viridis; those
figures carry hex values where the colour IS the subject, and keep their text
off them.

THE PICTURES IN `images/` ARE A DIFFERENT KIND OF FILE. A `labelling` question
shows its picture through `<img>`, which is a separate document: the page's
tokens do not reach it. So each one defines the tokens it uses in a `<style>`
of its own, at the light theme's values, and paints its own ground. They carry
no words, because a picture is shared by both languages and its labels are the
question's.

Standard library only.
"""
import glob
import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True
import horta as H  # noqa: E402

SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def esc(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            .replace('"', '&quot;'))


def num(lang, x, d=0):
    """A number as the reader writes it: 3.5 in English, 3,5 in Portuguese."""
    s = f'{x:,.{d}f}'
    if lang == 'pt':
        s = s.replace(',', '\0').replace('.', ',').replace('\0', '.')
    return s


# The palette in both themes, as ui/assets/base.css defines it, so a label drawn on a tint can be
# given the ink that reads on it in both. tools/figure-contrast measures the same thing.
THEMES = {
    'dark': {'--ink': '#0a0e14', '--panel': '#111721', '--scan': '#1b2431', '--phosphor': '#5b8cff',
             '--phosphor-dim': '#33549e', '--amber': '#ff4d5e', '--paper': '#e8e6df',
             '--paper-dim': '#9aa0a8', '--wire': '#233043'},
    'light': {'--ink': '#f2f4f9', '--panel': '#ffffff', '--scan': '#e7ebf4', '--phosphor': '#2b52c9',
              '--phosphor-dim': '#6c86c9', '--amber': '#d40f28', '--paper': '#20263c',
              '--paper-dim': '#5a6274', '--wire': '#ccd4e3'},
}


def _lum(hx):
    c = [int(hx[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    c = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def _ratio(a, b):
    la, lb = sorted([_lum(a), _lum(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)


def tint(token, alpha, theme):
    a, b = THEMES[theme][token], THEMES[theme]['--panel']
    return '#' + ''.join(f'{round(int(a[i:i + 2], 16) * alpha + int(b[i:i + 2], 16) * (1 - alpha)):02x}'
                         for i in (1, 3, 5))


def ink_on(token, alpha):
    """The text token that reads at AA on `token` at `alpha` over the panel in both themes, or
    None when neither does."""
    for ink in ('--paper', '--ink'):
        if all(_ratio(THEMES[t][ink], tint(token, alpha, t)) >= 4.5 for t in THEMES):
            return ink
    return None


def col(v):
    """A palette token, or a literal colour as it is."""
    if v is None:
        return 'none'
    return f'var({v})' if v.startswith('--') else v


class Fig:
    def __init__(self, name, w, h, label):
        self.name, self.w, self.h, self.label = name, w, h, label
        self.parts = []
        self.markers = set()

    def text(self, x, y, s, size=10, anchor='middle', fill='--paper', weight=None, mono=False,
             italic=False, rotate=None):
        w = f' font-weight="{weight}"' if weight else ''
        it = ' font-style="italic"' if italic else ''
        rt = f' transform="rotate({rotate} {x:.1f} {y:.1f})"' if rotate is not None else ''
        self.parts.append(
            f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" dominant-baseline="middle" '
            f'font-family="{MONO if mono else SANS}" font-size="{size}"{w}{it}{rt} '
            f'fill="{col(fill)}">{esc(s)}</text>')

    def path(self, d, stroke='--paper-dim', width=1.2, fill='none', dash=None, arrow=False,
             opacity=None, cap=None, join=None):
        extra = ''
        if dash:
            extra += f' stroke-dasharray="{dash}"'
        if arrow:
            mid = f'vz-ah{stroke.replace("--", "-").replace("#", "-")}'
            self.markers.add((mid, stroke))
            extra += f' marker-end="url(#{mid})"'
        if opacity is not None:
            extra += f' fill-opacity="{opacity}"'
        if cap:
            extra += f' stroke-linecap="{cap}"'
        if join:
            extra += f' stroke-linejoin="{join}"'
        fv = 'none' if fill in (None, 'none') else col(fill)
        self.parts.append(f'<path d="{d}" stroke="{col(stroke)}" stroke-width="{width}" '
                          f'fill="{fv}"{extra}></path>')

    def line(self, x1, y1, x2, y2, **kw):
        self.path(f'M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}', **kw)

    def poly(self, pts, **kw):
        self.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), **kw)

    def rect(self, x, y, w, h, stroke='--wire', fill='--panel', width=1.2, rx=4, dash=None,
             opacity=None):
        extra = f' stroke-dasharray="{dash}"' if dash else ''
        if opacity is not None:
            extra += f' fill-opacity="{opacity}"'
        self.parts.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" '
            f'fill="{col(fill)}" stroke="{col(stroke)}" stroke-width="{width}"{extra}></rect>')

    def bar(self, x, y, w, h, stroke='--phosphor', fill='--phosphor-dim', width=1.2, rx=0,
            opacity=None):
        """A data bar, drawn as a path: a mark of the chart rather than a box to put things in,
        so a gridline behind it is not a line through a box."""
        op = f' fill-opacity="{opacity}"' if opacity is not None else ''
        self.parts.append(
            f'<path d="M{x:.1f} {y:.1f} h{w:.1f} v{h:.1f} h{-w:.1f} Z" fill="{col(fill)}" '
            f'stroke="{col(stroke)}" stroke-width="{width}"{op}></path>')

    def circle(self, x, y, r, fill='--phosphor', stroke=None, width=1.2, opacity=None):
        st = f' stroke="{col(stroke)}" stroke-width="{width}"' if stroke else ''
        op = f' fill-opacity="{opacity}"' if opacity is not None else ''
        self.parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" '
                          f'fill="{col(fill)}"{st}{op}></circle>')

    def badge(self, x, y, r, label, fill='--amber', size=10):
        """A numbered disc. Drawn as a rounded rect so the label's ground is a fill the contrast
        check can see, and labelled in --ink, which reads on both accents in both themes."""
        self.rect(x - r, y - r, 2 * r, 2 * r, stroke=fill, fill=fill, rx=r, width=1)
        self.text(x, y, label, size=size, weight='600', fill='--ink')

    def wedge(self, cx, cy, r, a0, a1, fill='--phosphor-dim', stroke='--panel', width=1.5):
        """A pie slice from angle a0 to a1, in degrees clockwise from twelve o'clock."""
        def pt(a):
            t = math.radians(a - 90)
            return cx + r * math.cos(t), cy + r * math.sin(t)
        (x0, y0), (x1, y1) = pt(a0), pt(a1)
        big = 1 if a1 - a0 > 180 else 0
        self.path(f'M{cx:.1f} {cy:.1f} L{x0:.1f} {y0:.1f} A{r:.1f} {r:.1f} 0 {big} 1 '
                  f'{x1:.1f} {y1:.1f} Z', stroke=stroke, width=width, fill=fill)

    def defs(self):
        if not self.markers:
            return ''
        return '<defs>' + ''.join(
            f'<marker id="{m}" viewBox="0 0 10 8" refX="9" refY="4" markerWidth="8" '
            f'markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 4 L0 8 z" '
            f'fill="{col(c)}"></path></marker>' for m, c in sorted(self.markers)) + '</defs>'

    def svg(self):
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" data-fig="{self.name}" '
                f'aria-label="{esc(self.label)}">{self.defs()}{"".join(self.parts)}</svg>')

    def standalone(self):
        """The picture as a file of its own, for `images/`."""
        style = ('<style>svg{--ink:#f2f4f9;--panel:#ffffff;--scan:#e7ebf4;--phosphor:#2b52c9;'
                 '--phosphor-dim:#6c86c9;--amber:#d40f28;--paper:#20263c;--paper-dim:#5a6274;'
                 '--wire:#ccd4e3}</style>')
        ground = f'<rect x="0" y="0" width="{self.w}" height="{self.h}" fill="var(--panel)"></rect>'
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" '
                f'role="img" aria-label="{esc(self.label)}">\n{style}{self.defs()}\n{ground}\n'
                + '\n'.join(self.parts) + '\n</svg>\n')


class Plot:
    """A pair of axes inside a figure, mapping data to the page."""

    def __init__(self, fig, x0, y0, x1, y1, xmin, xmax, ymin, ymax):
        self.f = fig
        self.x0, self.y0, self.x1, self.y1 = x0, y0, x1, y1  # y0 is the TOP
        self.xmin, self.xmax, self.ymin, self.ymax = xmin, xmax, ymin, ymax

    def sx(self, v):
        return self.x0 + (v - self.xmin) / (self.xmax - self.xmin) * (self.x1 - self.x0)

    def sy(self, v):
        return self.y1 - (v - self.ymin) / (self.ymax - self.ymin) * (self.y1 - self.y0)

    def xaxis(self, ticks, fmt=str, label=None, size=9.5, line=True):
        f = self.f
        if line:
            f.line(self.x0, self.y1, self.x1, self.y1, stroke='--paper-dim', width=1.2)
        for t in ticks:
            x = self.sx(t)
            f.line(x, self.y1, x, self.y1 + 4, stroke='--paper-dim', width=1)
            f.text(x, self.y1 + 13, fmt(t), size=size, fill='--paper-dim')
        if label:
            f.text((self.x0 + self.x1) / 2, self.y1 + 31, label, size=10, weight='600')

    def yaxis(self, ticks, fmt=str, label=None, grid=True, size=9.5, line=True):
        f = self.f
        if line:
            f.line(self.x0, self.y0, self.x0, self.y1, stroke='--paper-dim', width=1.2)
        for t in ticks:
            y = self.sy(t)
            if grid and t != self.ymin:
                f.line(self.x0, y, self.x1, y, stroke='--wire', width=1)
            f.line(self.x0 - 4, y, self.x0, y, stroke='--paper-dim', width=1)
            f.text(self.x0 - 8, y, fmt(t), size=size, anchor='end', fill='--paper-dim')
        if label:
            f.text(self.x0, self.y0 - 14, label, size=10, anchor='start', weight='600')

    def series(self, xs, ys, stroke='--phosphor', width=2, dash=None):
        self.f.poly([(self.sx(x), self.sy(y)) for x, y in zip(xs, ys)], stroke=stroke,
                    width=width, dash=dash, join='round')


# --------------------------------------------------------------- the machinery

FIGURES = {}
IMAGES = {}


def figure(name, lesson):
    def wrap(f):
        FIGURES[name] = (lesson, f)
        return f
    return wrap


def image(name, lesson):
    def wrap(f):
        IMAGES[name] = (lesson, f)
        return f
    return wrap


def fence(name, lang):
    _, f = FIGURES[name]
    fig, caption = f(lang)
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

    new = FENCE.sub(swap_fence, text)
    new = PLACEHOLDER.sub(lambda m: render(m.group(1), lang), new)
    if new != text:
        open(path, 'w', encoding='utf-8').write(new)
        return True
    return False


def write_images():
    os.makedirs(os.path.join(HERE, 'images'), exist_ok=True)
    for name, (_, f) in IMAGES.items():
        body = f().standalone()
        path = os.path.join(HERE, 'images', name)
        if not os.path.exists(path) or open(path, encoding='utf-8').read() != body:
            open(path, 'w', encoding='utf-8').write(body)


# Shared names, in the two languages a figure is drawn in.
REGION = {'en': {r: r for r in H.REGIONS},
          'pt': {'Southeast': 'Sudeste', 'South': 'Sul', 'Northeast': 'Nordeste',
                 'Centre-West': 'Centro-Oeste', 'North': 'Norte'}}
CATEGORY = {'en': {c: c for c in H.CATEGORIES},
            'pt': {'Vegetables': 'Verduras', 'Fruit': 'Frutas', 'Dairy': 'Laticínios',
                   'Bakery': 'Padaria', 'Drinks': 'Bebidas', 'Pantry': 'Mercearia'}}
MONTH_SHORT = {'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
                      'Nov', 'Dec'],
               'pt': ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out',
                      'nov', 'dez']}


def monthly_by_region():
    out = {r: [] for r in H.REGIONS}
    for row in H.monthly_orders():
        out[row['region']].append(row['orders'])
    return out


# The lessons' figures are in figs/, one file per lesson, so
# that a lesson's drawings can be read next to its prose.
for _path in sorted(glob.glob(os.path.join(HERE, 'figs', 'l*.py'))):
    _name = os.path.basename(_path)[:-3]
    _code = compile(open(_path, encoding='utf-8').read(), _path, 'exec')
    exec(_code, globals())


def main():
    if '--list' in sys.argv:
        for name, (lesson, _) in list(FIGURES.items()) + list(IMAGES.items()):
            print(f'{lesson:>3}  {name}')
        return
    changed = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        changed += apply(path)
    write_images()
    print(f'{len(FIGURES)} figures and {len(IMAGES)} pictures drawn, {changed} file(s) rewritten')


if __name__ == '__main__':
    main()
