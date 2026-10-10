#!/usr/bin/env python3
"""Every diagram in the delivery-metrics course, drawn from the Billing team's data.

The charts in this course are the course: a cumulative flow diagram, an ageing
chart, a cycle-time scatter, a Monte Carlo histogram. Each one is drawn from
the files billing.py writes, and billing.py is read OUT OF LESSON 1'S PROSE and
run in a temporary folder, so a chart cannot drift from the program the
student saves or from the numbers the lessons quote.

    python3 figures.py            # rewrite every figure in the lessons
    python3 figures.py --list     # the names, and the lesson each lives in

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

Only palette tokens are used, so each drawing turns over with the theme like
the page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel. Bars are paths rather than rects, because
`figure-fit` reads every rect as a box that a gridline may not cross.

The drawing kit (Fig, Plot and the fence machinery) is data-storytelling's,
copied rather than imported: two courses sharing one file would make either
one's figures a reason to edit the other's.

Standard library only.
"""
import csv
import glob
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import date, datetime, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
LESSON1 = os.path.join(HERE, 'lessons', 'le-zz75x0ba')


import functools


@functools.lru_cache(maxsize=None)
def billing(*args):
    """Run lesson 1's billing.py in a fresh folder; return its items and deploys."""
    program = subprocess.run([sys.executable, os.path.join(HERE, 'lab', 'extract.py'), LESSON1,
                              'billing.py'], capture_output=True, text=True, check=True).stdout
    with tempfile.TemporaryDirectory() as d:
        open(os.path.join(d, 'billing.py'), 'w').write(program)
        subprocess.run([sys.executable, 'billing.py', *args], cwd=d, check=True,
                       capture_output=True)
        items = list(csv.DictReader(open(os.path.join(d, 'items.csv'))))
        deploys = list(csv.DictReader(open(os.path.join(d, 'deploys.csv'))))
    return items, deploys


def when(text):
    return date.fromisoformat(text[:10]) if text else None


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
            mid = f'dm-ah{stroke.replace("--", "-")}'
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




def main():
    if '--list' in sys.argv:
        for name, (lesson, _) in FIGURES.items():
            print(f'{lesson:>3}  {name}')
        return
    changed = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        changed += apply(path)
    print(f'{len(FIGURES)} figures drawn, {changed} file(s) rewritten')


# ------------------------------------------------------------------ helpers

MONTHS = {'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
          'pt': ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']}


def day_label(lang, d):
    return f'{d.day} {MONTHS[lang][d.month - 1]}'


def span(first, last):
    return [first + timedelta(n) for n in range((last - first).days + 1)]


def open_on(items, d):
    return [i for i in items if i['started'] and when(i['started']) <= d
            and (not i['merged'] or when(i['merged']) > d)]


def card(f, x, y, w=34, h=22, stroke='--phosphor', fill='--scan'):
    f.rect(x, y, w, h, stroke=stroke, fill=fill, width=1.2, rx=3)


# ------------------------------------------------------------------ lesson 1

@figure('l01-box', 1)
def l01_box(lang):
    f = Fig('l01-box', 680, 250, T(
        lang,
        'A box standing for the team, with six cards inside it. Cards arrive from the left, '
        'and finished cards leave on the right. The number of cards inside is the work in '
        'progress, L; the rate at which they leave is the throughput, lambda; the time each '
        'card spends inside, from entering to leaving, is the cycle time, W.',
        'Uma caixa que representa o time, com seis cartões dentro. Cartões chegam pela '
        'esquerda, e os terminados saem pela direita. O número de cartões dentro é o trabalho '
        'em andamento, L; o ritmo em que saem é a vazão, lambda; o tempo que cada cartão passa '
        'dentro, de entrar a sair, é o tempo de ciclo, W.'))
    f.rect(190, 40, 300, 130, stroke='--phosphor', fill='--panel', width=1.6, rx=8)
    f.text(340, 58, T(lang, 'the team', 'o time'), size=11, weight='600')
    for k in range(6):
        card(f, 214 + (k % 3) * 92, 78 + (k // 3) * 42, w=70, h=28)
    for k in range(3):
        card(f, 24 + k * 44, 104, stroke='--wire', fill='--panel')
    f.line(160, 118, 186, 118, stroke='--paper-dim', width=1.4, arrow=True)
    f.line(494, 118, 520, 118, stroke='--paper-dim', width=1.4, arrow=True)
    for k in range(3):
        card(f, 530 + k * 44, 104, stroke='--amber', fill='--panel')
    f.text(90, 84, T(lang, 'requests arrive', 'pedidos chegam'), size=10, fill='--paper-dim')
    f.text(596, 84, T(lang, 'items finish', 'itens terminam'), size=10, fill='--paper-dim')
    f.line(190, 196, 490, 196, stroke='--amber', width=1.4, arrow=True)
    f.line(190, 188, 190, 204, stroke='--amber', width=1.4)
    f.text(340, 214, T(lang, 'W: the days each item spends inside (cycle time)',
                       'W: os dias que cada item passa dentro (tempo de ciclo)'), size=10.5)
    f.text(340, 20, T(lang, 'L: the items inside at any moment (work in progress)',
                      'L: os itens dentro a cada momento (trabalho em andamento)'), size=10.5)
    f.text(596, 150, T(lang, 'λ: items leaving per day', 'λ: itens que saem por dia'),
           size=10.5)
    f.text(596, 166, T(lang, '(throughput)', '(vazão)'), size=10.5, fill='--paper-dim')
    f.text(340, 238, 'L = λ × W', size=11, fill='--paper-dim')
    return f, T(lang,
                'Any system that work enters and leaves. Know two of the three numbers and the '
                'law gives the third.',
                'Qualquer sistema por onde o trabalho entra e sai. Conhecidos dois dos três '
                'números, a lei dá o terceiro.')


@figure('l01-wip-days', 1)
def l01_wip_days(lang):
    items, _ = billing()
    days = span(date(2026, 6, 1), date(2026, 9, 30))
    wip = [len(open_on(items, d)) for d in days]
    f = Fig('l01-wip-days', 680, 280, T(
        lang,
        'A line chart of the Billing team\'s work in progress at the end of each day, from '
        f'1 June to 30 September 2026. It sits between {min(wip[:60])} and {max(wip[:60])} '
        'items through June and July, falls through August after the rules change on 3 '
        f'August, and stays at {max(wip[-30:])} or fewer in September.',
        'Um gráfico de linha do trabalho em andamento do time de Billing no fim de cada dia, '
        f'de 1º de junho a 30 de setembro de 2026. Fica entre {min(wip[:60])} e '
        f'{max(wip[:60])} itens em junho e julho, cai ao longo de agosto depois que as regras '
        f'mudam em 3 de agosto, e fica em {max(wip[-30:])} ou menos em setembro.'))
    p = Plot(f, 60, 40, 650, 230, 0, len(days) - 1, 0, 30)
    p.yaxis([0, 10, 20, 30])
    p.baseline()
    for d in (date(2026, 6, 1), date(2026, 7, 1), date(2026, 8, 1), date(2026, 9, 1)):
        x = p.sx((d - days[0]).days)
        f.text(x, 246, day_label(lang, d), size=9.5, anchor='start', fill='--paper-dim')
    xa = p.sx((date(2026, 8, 3) - days[0]).days)
    f.line(xa, 40, xa, 230, stroke='--amber', width=1.2, dash='4 3')
    f.text(xa + 6, 34, T(lang, '3 Aug: one item each, review first',
                         '3 ago: um item cada, revisão primeiro'),
           size=10, anchor='start', fill='--amber')
    p.polyline(range(len(days)), wip, stroke='--phosphor', width=1.8)
    f.text(60, 16, T(lang, 'items open at the end of each day', 'itens abertos no fim de cada dia'),
           size=10, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'Two policies and the transition between them. Little\'s law holds in '
                'September and fails across August, where the board was emptying.',
                'Duas políticas e a transição entre elas. A lei de Little vale em setembro e '
                'falha em agosto, quando o quadro estava esvaziando.')


# @@LESSONS@@

if __name__ == '__main__':
    main()
