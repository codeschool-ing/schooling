#!/usr/bin/env python3
"""Every diagram in the data-storytelling course, drawn from the numbers in sheet.py.

A course about presenting evidence is taught by showing two versions of the
same slide, so most of these are slides: the one that was shown and the one
that would have worked. The bars, the lines and the numbers on them come from
the same counts the prose quotes, so a figure cannot drift from the sentence
beside it.

    python3 figures.py            # rewrite every figure in the lessons, and the pictures
    python3 figures.py --list     # the names, and the lesson each lives in

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

THE PICTURES IN `images/` ARE DRAWN HERE TOO, and they are different on
purpose. A `labelling` question names one file for every language, so those
carry no words at all: a title is a bar the width of a title, a paragraph is
three thinner bars, and a number is a number. What the question asks the
student to find is the SHAPE of the mistake, which reads the same in both.

Only palette tokens are used, so each drawing turns over with the theme like
the page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel. Bars are paths rather than rects, because
`figure-fit` reads every rect as a box that a gridline may not cross.

Standard library only.
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True
import sheet as S  # noqa: E402

SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def esc(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            .replace('"', '&quot;'))


def num(lang, x, d=1):
    """A number as the reader writes it: 3.5 in English, 3,5 in Portuguese."""
    s = f'{x:,.{d}f}'
    if lang == 'pt':
        s = s.replace(',', '\0').replace('.', ',').replace('\0', '.')
    return s


def pct(lang, x, d=1):
    return num(lang, 100 * x, d) + '%'


def brl(lang, cents, d=0):
    return 'R$ ' + num(lang, cents / 100, d)


def T(lang, en, pt):
    return pt if lang == 'pt' else en


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
        """Several lines of text, one under the other, starting at y."""
        gap = gap or size * 1.35
        for i, r in enumerate(rows):
            self.text(x, y + i * gap, r, size=size, **kw)

    def path(self, d, stroke='--paper-dim', width=1.2, fill='none', dash=None, arrow=False,
             opacity=None, cap=None):
        extra = ''
        if dash:
            extra += f' stroke-dasharray="{dash}"'
        if arrow:
            mid = f'ds-ah{stroke.replace("--", "-")}'
            self.markers.add((mid, stroke))
            extra += f' marker-end="url(#{mid})"'
        if opacity is not None:
            extra += f' fill-opacity="{opacity}"'
        if cap:
            extra += f' stroke-linecap="{cap}"'
        sv = 'none' if stroke is None else f'var({stroke})'
        fv = fill if fill == 'none' else f'var({fill})'
        self.parts.append(f'<path d="{d}" stroke="{sv}" stroke-width="{width}" fill="{fv}"{extra}></path>')

    def line(self, x1, y1, x2, y2, **kw):
        self.path(f'M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}', **kw)

    def bar(self, x, y, w, h, fill='--phosphor-dim', stroke='--phosphor', width=1):
        """A filled block drawn as a path, so it is not a box to figure-fit."""
        self.path(f'M{x:.1f} {y:.1f} L{x + w:.1f} {y:.1f} L{x + w:.1f} {y + h:.1f} '
                  f'L{x:.1f} {y + h:.1f} Z', stroke=stroke, width=width, fill=fill)

    def rect(self, x, y, w, h, stroke='--wire', fill='--panel', width=1.2, rx=4, dash=None):
        extra = f' stroke-dasharray="{dash}"' if dash else ''
        self.parts.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" '
            f'fill="var({fill})" stroke="var({stroke})" stroke-width="{width}"{extra}></rect>')

    def circle(self, x, y, r, fill='--phosphor', stroke=None, width=1.2):
        st = f' stroke="var({stroke})" stroke-width="{width}"' if stroke else ''
        fv = 'none' if fill is None else f'var({fill})'
        self.parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{fv}"{st}></circle>')

    def svg(self, standalone=False):
        defs = ''
        if self.markers:
            defs = '<defs>' + ''.join(
                f'<marker id="{m}" viewBox="0 0 10 8" refX="9" refY="4" markerWidth="8" '
                f'markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 4 L0 8 z" '
                f'fill="var({c})"></path></marker>' for m, c in sorted(self.markers)) + '</defs>'
        ns = ' xmlns="http://www.w3.org/2000/svg"' if standalone else ''
        fig = '' if standalone else f' data-fig="{self.name}"'
        return (f'<svg{ns} viewBox="0 0 {self.w} {self.h}" role="img"{fig} '
                f'aria-label="{esc(self.label)}">{defs}{"".join(self.parts)}</svg>')


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

    def yaxis(self, ticks, fmt=str, grid=True, size=9, axis=True):
        f = self.f
        if axis:
            f.line(self.x0, self.y0, self.x0, self.y1, stroke='--paper-dim', width=1)
        for t in ticks:
            y = self.sy(t)
            if grid and t != self.ymin:
                f.line(self.x0, y, self.x1, y, stroke='--wire', width=1)
            f.text(self.x0 - 6, y, fmt(t), size=size, anchor='end', fill='--paper-dim')

    def baseline(self):
        self.f.line(self.x0, self.y1, self.x1, self.y1, stroke='--paper-dim', width=1.2)

    def polyline(self, xs, ys, stroke='--phosphor', width=2, dash=None):
        d = 'M' + ' L'.join(f'{self.sx(x):.1f} {self.sy(y):.1f}' for x, y in zip(xs, ys))
        self.f.path(d, stroke=stroke, width=width, dash=dash)


# --------------------------------------------------------------- slide kit

def slide(f, x, y, w, h, title, sub=None, title_size=12, stroke='--wire', fill='--ink'):
    """A slide: a frame and its title, top left. Returns the content area."""
    f.rect(x, y, w, h, stroke=stroke, fill=fill, width=1.2, rx=3)
    if title:
        f.text(x + 14, y + 20, title, size=title_size, anchor='start', weight='600')
    top = y + 34
    if sub:
        f.text(x + 14, y + 38, sub, size=9.5, anchor='start', fill='--paper-dim')
        top = y + 50
    return x + 14, top, x + w - 14, y + h - 12


def hbars(f, x0, y0, x1, rows, lang, maxv=None, bar_h=18, gap=10, label_w=120, fmt=None,
          colours=None, size=10):
    """Horizontal bars with the label on the left and the value at the bar's end."""
    maxv = maxv or max(v for _, v in rows)
    fmt = fmt or (lambda v: pct(lang, v))
    span = x1 - x0 - label_w - 48
    for i, (label, v) in enumerate(rows):
        y = y0 + i * (bar_h + gap)
        f.text(x0 + label_w - 8, y + bar_h / 2, label, size=size, anchor='end')
        w = span * v / maxv
        fill, stroke = (colours[i] if colours else ('--phosphor-dim', '--phosphor'))
        f.bar(x0 + label_w, y, w, bar_h, fill=fill, stroke=stroke)
        f.text(x0 + label_w + w + 6, y + bar_h / 2, fmt(v), size=size, anchor='start',
               fill='--paper')


# --------------------------------------------------------------- the machinery

FIGURES = {}


def figure(name, lesson):
    def wrap(f):
        FIGURES[name] = (lesson, f)
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


PICTURES = {}


def picture(name):
    def wrap(f):
        PICTURES[name] = f
        return f
    return wrap


def write_pictures():
    d = os.path.join(HERE, 'images')
    os.makedirs(d, exist_ok=True)
    for name, f in PICTURES.items():
        fig, _ = f()
        with open(os.path.join(d, name + '.svg'), 'w', encoding='utf-8') as out:
            out.write(fig.svg(standalone=True) + '\n')


def spots(name):
    """The label coordinates of a picture, as fractions of its frame."""
    fig, marks = PICTURES[name]()
    return [(round(x / fig.w, 4), round(y / fig.h, 4)) for x, y in marks]


# ------------------------------------------------------------------ lesson 1

@figure('l01-two-slides', 1)
def l01_two_slides(lang):
    f = Fig('l01-two-slides', 680, 300, T(
        lang,
        'Two slides from the same analysis. The left one, as shown in the meeting, is a table of '
        'twelve rows of counts under the title First-delivery analysis, first half of 2025. The '
        'right one has a sentence for a title, late first deliveries more than double early '
        'cancellations, and two bars: 41.5% of late customers cancelled within ninety days '
        'against 17.4% of on-time ones.',
        'Dois slides da mesma análise. O da esquerda, mostrado na reunião, é uma tabela de doze '
        'linhas de contagens sob o título Análise da primeira entrega, primeiro semestre de 2025. '
        'O da direita tem uma frase como título, entrega inicial atrasada mais que dobra o '
        'cancelamento precoce, e duas barras: 41,5% dos clientes com atraso cancelaram em noventa '
        'dias, contra 17,4% dos que receberam no prazo.'))
    f.text(170, 14, T(lang, 'what was shown', 'o que foi mostrado'), size=10, fill='--paper-dim')
    f.text(510, 14, T(lang, 'what would have worked', 'o que teria funcionado'), size=10,
           fill='--paper-dim')
    x0, y0, x1, y1 = slide(f, 10, 28, 320, 262, T(lang, 'First-delivery analysis, H1 2025',
                                                    'Análise da primeira entrega, 1º sem. 2025'),
                           title_size=11)
    heads = ['cohort', 'region', 'first', 'subs', 'canc.']
    cols = [x0, x0 + 60, x0 + 120, x0 + 190, x0 + 240]
    for c, h in zip(cols, heads):
        f.text(c, y0 + 6, h, size=8.5, anchor='start', mono=True, fill='--paper-dim')
    for i, r in enumerate(S.ROWS[:12]):
        y = y0 + 22 + i * 16
        vals = [r['cohort'], r['region'], r['first_delivery'], str(r['subscribers']),
                str(r['cancelled_90d'])]
        for c, v in zip(cols, vals):
            f.text(c, y, v, size=8.5, anchor='start', mono=True)
    x0, y0, x1, y1 = slide(f, 350, 28, 320, 262, '', stroke='--phosphor')
    f.lines(x0, y0 - 8, T(lang, ['Late first deliveries more than', 'double early cancellations'],
                         ['Entrega inicial atrasada mais', 'que dobra o cancelamento precoce']),
            size=12, anchor='start', weight='600', gap=16)
    p = Plot(f, x0 + 30, y0 + 40, x1 - 30, y1 - 30, 0, 2, 0, 0.5)
    vals = [(T(lang, 'late', 'atrasada'), S.RATE_LATE, '--amber'),
            (T(lang, 'on time', 'no prazo'), S.RATE_ON, '--phosphor')]
    for i, (lab, v, col) in enumerate(vals):
        xa, xb = p.sx(i + 0.2), p.sx(i + 0.8)
        f.bar(xa, p.sy(v), xb - xa, p.sy(0) - p.sy(v), fill='--scan', stroke=col, width=1.6)
        f.text((xa + xb) / 2, p.sy(v) - 10, pct(lang, v), size=12, weight='600', fill=col)
        f.text((xa + xb) / 2, p.y1 + 14, lab, size=10)
    p.baseline()
    f.text(x0, y1 - 2, T(lang, 'cancelled within 90 days, by first delivery',
                         'cancelaram em 90 dias, pela primeira entrega'),
           size=9, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'The same data twice. The table asks the room to do the analysis during the '
                'meeting; the right-hand slide has already done it and says what it found.',
                'Os mesmos dados duas vezes. A tabela pede que a sala faça a análise durante a '
                'reunião; o slide da direita já fez e diz o que achou.')


@figure('l01-what-so-what', 1)
def l01_what_so_what(lang):
    f = Fig('l01-what-so-what', 680, 210, T(
        lang,
        'Three boxes joined by arrows. What: 17.3% of new subscribers got their first box late. '
        'So what: they cancel within ninety days at 41.5%, against 17.4%. Now what: fix the first '
        'delivery before anything else, starting with a pilot.',
        'Três caixas ligadas por setas. O quê: 17,3% dos novos assinantes receberam a primeira '
        'caixa com atraso. E daí: eles cancelam em noventa dias em 41,5%, contra 17,4%. E agora: '
        'consertar a primeira entrega antes de tudo, começando por um piloto.'))
    boxes = [
        (T(lang, 'What?', 'O quê?'),
         T(lang, ['17.3% of new subscribers', 'got their first box late'],
           ['17,3% dos novos assinantes', 'receberam a 1ª caixa atrasada']),
         T(lang, 'information', 'informação')),
        (T(lang, 'So what?', 'E daí?'),
         T(lang, ['they cancel in 90 days', 'at 41.5% against 17.4%'],
           ['cancelam em 90 dias', 'em 41,5% contra 17,4%']),
         T(lang, 'insight', 'insight')),
        (T(lang, 'Now what?', 'E agora?'),
         T(lang, ['fix the first delivery,', 'starting with a pilot'],
           ['consertar a 1ª entrega,', 'começando por um piloto']),
         T(lang, 'decision', 'decisão')),
    ]
    for i, (head, body, kind) in enumerate(boxes):
        x = 14 + i * 226
        stroke = '--amber' if i == 2 else '--phosphor' if i == 1 else '--wire'
        f.rect(x, 40, 200, 120, stroke=stroke, fill='--panel', width=1.4)
        f.text(x + 100, 64, head, size=14, weight='600')
        f.lines(x + 100, 98, body, size=10.5, gap=17)
        f.text(x + 100, 180, kind, size=10, fill='--paper-dim', italic=True)
        if i < 2:
            f.line(x + 202, 100, x + 224, 100, stroke='--paper-dim', width=1.4, arrow=True)
    f.text(340, 18, T(lang, 'each box answers the question the one before it raises',
                      'cada caixa responde à pergunta que a anterior levanta'),
           size=10, fill='--paper-dim')
    return f, T(lang,
                'A finding is the middle box. The report most analysts write stops at the first '
                'one, and the room has to supply the other two on the spot.',
                'Um achado é a caixa do meio. O relatório que a maioria dos analistas escreve para '
                'na primeira, e a sala tem de completar as outras duas na hora.')


def main():
    if '--list' in sys.argv:
        for name, (lesson, _) in FIGURES.items():
            print(f'{lesson:>3}  {name}')
        for name in PICTURES:
            print(f'img  {name}')
        return
    if '--spots' in sys.argv:
        for name in PICTURES:
            print(name, spots(name))
        return
    write_pictures()
    changed = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        changed += apply(path)
    print(f'{len(FIGURES)} figures and {len(PICTURES)} pictures drawn, '
          f'{changed} file(s) rewritten')


if __name__ == '__main__':
    main()
