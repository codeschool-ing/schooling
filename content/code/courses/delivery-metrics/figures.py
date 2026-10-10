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
    def swap_placeholder(m):
        if m.group(1) not in FIGURES:
            # Left in the file, where validate-content and the render walk both refuse
            # it; said here so the run does not look complete.
            print(f'{path}: no figure called {m.group(1)}, placeholder left', file=sys.stderr)
            return m.group(0)
        return render(m.group(1), lang)
    new = PLACEHOLDER.sub(swap_placeholder, new)
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


# ------------------------------------------------------------------ lesson 2

def cycle_days(items, first, last):
    """(merge date, cycle days, start date) for items merged in [first, last]."""
    return [(when(i['merged']), (when(i['merged']) - when(i['started'])).days, when(i['started']))
            for i in items if i['merged'] and first <= when(i['merged']) <= last]


def pctl(values, p):
    ordered = sorted(values)
    return ordered[-(-p * len(ordered) // 100) - 1]


@figure('l02-clocks', 2)
def l02_clocks(lang):
    f = Fig('l02-clocks', 680, 250, T(
        lang,
        'A timeline of one item with five moments: created, started, handed to review, merged '
        'and deployed. Cycle time runs from started to merged. Lead time runs from created to '
        'deployed and contains cycle time, the wait in the backlog before it and the wait for '
        'a deployment after it. A third bracket, lead time for changes, runs from the commit to '
        'the deployment.',
        'Uma linha do tempo de um item com cinco momentos: criado, começado, entregue para '
        'revisão, integrado e com deploy. O tempo de ciclo vai de começado a integrado. O lead '
        'time vai de criado ao deploy e contém o tempo de ciclo, a espera no backlog antes dele '
        'e a espera pelo deploy depois. Uma terceira chave, o lead time de mudanças, vai do '
        'commit ao deploy.'))
    xs = [60, 250, 400, 500, 610]
    names = T(lang, ['request written', 'work starts', 'handed to review', 'change merged',
                     'in production'],
              ['pedido registrado', 'trabalho começa', 'vai para revisão', 'mudança integrada',
               'em produção'])
    cols = ['created', 'started', 'review', 'merged', 'deployed']
    f.line(40, 110, 640, 110, stroke='--paper-dim', width=1.4)
    for x, n, c in zip(xs, names, cols):
        f.circle(x, 110, 5, fill='--phosphor')
        f.text(x, 92, n, size=10.5)
        f.text(x, 130, c, size=9, mono=True, fill='--paper-dim')
    segs = [(60, 250, T(lang, 'backlog', 'backlog')), (250, 400, T(lang, 'development', 'desenvolvimento')),
            (400, 500, T(lang, 'review', 'revisão')), (500, 610, T(lang, 'to deploy', 'até o deploy'))]
    for a, b, t in segs:
        f.text((a + b) / 2, 70, t, size=9.5, fill='--paper-dim', italic=True)

    def bracket(a, b, y, label, colour):
        f.line(a, y, b, y, stroke=colour, width=1.6)
        f.line(a, y - 6, a, y + 6, stroke=colour, width=1.6)
        f.line(b, y - 6, b, y + 6, stroke=colour, width=1.6)
        f.text((a + b) / 2, y + 16, label, size=10.5, fill=colour)
    bracket(250, 500, 158, T(lang, 'cycle time: the team\'s clock', 'tempo de ciclo: o relógio do time'),
            '--phosphor')
    bracket(60, 610, 196, T(lang, 'lead time: the requester\'s clock', 'lead time: o relógio de quem pediu'),
            '--amber')
    f.line(452, 30, 610, 30, stroke='--paper-dim', width=1.2, dash='4 3')
    f.line(452, 24, 452, 36, stroke='--paper-dim', width=1.2)
    f.line(610, 24, 610, 36, stroke='--paper-dim', width=1.2)
    f.text(531, 16, T(lang, 'lead time for changes (lesson 5)', 'lead time de mudanças (aula 5)'),
           size=9.5, fill='--paper-dim')
    return f, T(lang,
                'Two clocks on one item. Cycle time is inside lead time, and the two stretches '
                'outside it, the backlog and the wait for a deployment, are the team\'s too.',
                'Dois relógios num item. O tempo de ciclo está dentro do lead time, e os dois '
                'trechos de fora, o backlog e a espera pelo deploy, também são do time.')


@figure('l02-scatter', 2)
def l02_scatter(lang):
    items, _ = billing()
    pts = cycle_days(items, date(2026, 6, 1), date(2026, 9, 30))
    first = date(2026, 6, 1)
    before = [c for m, c, s in pts if m <= date(2026, 7, 31)]
    after = [c for m, c, s in pts if m >= date(2026, 9, 1)]
    f = Fig('l02-scatter', 680, 300, T(
        lang,
        f'A scatterplot of the {len(pts)} items the Billing team merged from June to September '
        '2026: each dot sits at the date the item merged and at its cycle time in days. In June '
        f'and July the dots spread from 1 to {max(before)} days, with the 85th percentile at '
        f'{pctl(before, 85)}. In August, items started before the change keep finishing with '
        'long cycle times while new ones finish within a week. In September the dots sit low, '
        f'with the 85th percentile at {pctl(after, 85)}.',
        f'Um gráfico de dispersão dos {len(pts)} itens que o time de Billing integrou de junho a '
        'setembro de 2026: cada ponto fica na data em que o item foi integrado e na altura do '
        f'seu tempo de ciclo em dias. Em junho e julho os pontos se espalham de 1 a {max(before)} '
        f'dias, com o percentil 85 em {pctl(before, 85)}. Em agosto, itens começados antes da '
        'mudança continuam terminando com ciclos longos enquanto os novos terminam em uma '
        f'semana. Em setembro os pontos ficam baixos, com o percentil 85 em {pctl(after, 85)}.'))
    p = Plot(f, 60, 36, 650, 240, 0, 121, 0, 60)
    p.yaxis([0, 10, 20, 30, 40, 50, 60])
    p.baseline()
    for d in (date(2026, 6, 1), date(2026, 7, 1), date(2026, 8, 1), date(2026, 9, 1)):
        f.text(p.sx((d - first).days), 256, day_label(lang, d), size=9.5, anchor='start',
               fill='--paper-dim')
    xa = p.sx((date(2026, 8, 3) - first).days)
    f.line(xa, 36, xa, 240, stroke='--paper-dim', width=1, dash='4 3')
    for m, c, s in pts:
        old = s < date(2026, 8, 3)
        f.circle(p.sx((m - first).days), p.sy(c), 3,
                 fill='--phosphor' if old else '--amber')
    for lo, hi, vals in ((date(2026, 6, 1), date(2026, 7, 31), before),
                         (date(2026, 9, 1), date(2026, 9, 30), after)):
        y = p.sy(pctl(vals, 85))
        f.line(p.sx((lo - first).days), y, p.sx((hi - first).days), y, stroke='--paper', width=1.2,
               dash='6 3')
        f.text(p.sx((hi - first).days), y - 8, T(lang, f'85th: {pctl(vals, 85)} days',
                                                 f'p85: {pctl(vals, 85)} dias'),
               size=9.5, anchor='end')
    f.text(60, 16, T(lang, 'cycle time in days, by the date each item merged',
                     'tempo de ciclo em dias, pela data em que cada item foi integrado'),
           size=10, anchor='start', fill='--paper-dim')
    f.circle(430, 16, 3, fill='--phosphor')
    f.text(438, 16, T(lang, 'started before 3 Aug', 'começado antes de 3 ago'), size=9.5,
           anchor='start', fill='--paper-dim')
    f.circle(560, 16, 3, fill='--amber')
    f.text(568, 16, T(lang, 'started after', 'começado depois'), size=9.5, anchor='start',
           fill='--paper-dim')
    return f, T(lang,
                'August holds two systems at once: the old one draining out in tall dots, and the '
                'new one finishing within a week.',
                'Agosto tem dois sistemas ao mesmo tempo: o antigo escoando em pontos altos, e o '
                'novo terminando em uma semana.')


def stage_days(first, last):
    """stages.py's four averages for items deployed in [first, last], rounded as it prints."""
    items, deploys = billing()
    shipped = {}
    for d in deploys:
        for i in d['items'].split():
            shipped[i] = datetime.fromisoformat(d['at'])
    cols = [[], [], [], []]
    for i in items:
        if i['id'] not in shipped or not first <= shipped[i['id']].date() <= last:
            continue
        merged = datetime.fromisoformat(i['merged'])
        cols[0].append((when(i['started']) - when(i['created'])).days)
        cols[1].append((when(i['review']) - when(i['started'])).days)
        cols[2].append((merged.date() - when(i['review'])).days)
        cols[3].append((shipped[i['id']] - merged).total_seconds() / 86400)
    return [round(sum(c) / len(c), 1) for c in cols]


@figure('l02-stages', 2)
def l02_stages(lang):
    a = stage_days(date(2026, 6, 1), date(2026, 7, 31))
    b = stage_days(date(2026, 9, 1), date(2026, 9, 30))
    rows = [(T(lang, 'June and July', 'junho e julho'), a), (T(lang, 'September', 'setembro'), b)]
    names = T(lang, ['backlog', 'development', 'review', 'to deploy'],
              ['backlog', 'desenvolvimento', 'revisão', 'até o deploy'])
    styles = [('--panel', '--paper-dim'), ('--scan', '--phosphor'), ('--panel', '--amber'),
              ('--scan', '--paper')]
    f = Fig('l02-stages', 680, 220, T(
        lang,
        f'Two stacked bars of average lead time in days. June and July: {num(lang, sum(a))} days, '
        f'of which {a[0]} in the backlog, {a[1]} in development, {a[2]} in review and {a[3]} '
        f'waiting to deploy. September: {num(lang, sum(b))} days, of which {b[0]} in the '
        f'backlog, {b[1]} in development, {b[2]} in review and {b[3]} waiting to deploy.',
        f'Duas barras empilhadas do lead time médio em dias. Junho e julho: {num(lang, sum(a))} '
        f'dias, sendo {num(lang, a[0])} no backlog, {num(lang, a[1])} em desenvolvimento, '
        f'{num(lang, a[2])} em revisão e {num(lang, a[3])} esperando o deploy. Setembro: '
        f'{num(lang, sum(b))} dias, sendo {num(lang, b[0])} no backlog, {num(lang, b[1])} em '
        f'desenvolvimento, {num(lang, b[2])} em revisão e {num(lang, b[3])} esperando o deploy.'))
    x0, scale = 130, 11.5
    for r, (label, vals) in enumerate(rows):
        y = 50 + r * 70
        f.text(x0 - 10, y + 16, label, size=10.5, anchor='end')
        x = x0
        for k, v in enumerate(vals):
            fill, stroke = styles[k]
            f.bar(x, y, v * scale, 32, fill=fill, stroke=stroke, width=1.2)
            if v * scale > 44:
                f.text(x + v * scale / 2, y + 16, num(lang, v), size=9.5)
            x += v * scale
        f.text(x + 8, y + 16, T(lang, f'{num(lang, sum(vals))} days', f'{num(lang, sum(vals))} dias'),
               size=10.5, anchor='start', weight='600')
    for k, n in enumerate(names):
        fill, stroke = styles[k]
        lx = 130 + k * 130
        f.bar(lx, 190, 14, 12, fill=fill, stroke=stroke, width=1.2)
        f.text(lx + 20, 196, n, size=9.5, anchor='start', fill='--paper-dim')
    f.text(130, 24, T(lang, 'average lead time of items deployed in the period, by column',
                      'lead time médio dos itens com deploy no período, por coluna'),
           size=10, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'Every queue inside the team shrank, and the requester waits only ten days less: '
                'the backlog grew to fill most of the gain.',
                'Toda fila dentro do time encolheu, e quem pediu espera só dez dias a menos: o '
                'backlog cresceu e ocupou quase todo o ganho.')


# ------------------------------------------------------------------ lesson 3

def cfd_counts(items, deploys, days):
    shipped = {}
    for d in deploys:
        for i in d['items'].split():
            shipped[i] = d['at'][:10]
    cols = ['created', 'started', 'review', 'merged']
    out = {c: [] for c in cols + ['deployed']}
    for day in days:
        iso = day.isoformat()
        for c in cols:
            out[c].append(sum(1 for i in items if i[c] and i[c][:10] <= iso))
        out['deployed'].append(sum(1 for v in shipped.values() if v <= iso))
    return out


@figure('l03-cfd', 3)
def l03_cfd(lang):
    items, deploys = billing()
    days = span(date(2026, 6, 1), date(2026, 9, 30))
    c = cfd_counts(items, deploys, days)
    f = Fig('l03-cfd', 680, 320, T(
        lang,
        'A cumulative flow diagram of the Billing team from June to September 2026: five rising '
        'lines, arrived, started, to review, merged and deployed, with the bands between them '
        'shaded. Through July the band between to review and merged widens, the review queue. '
        'From August the bands between started and deployed are thin, and the merged and '
        'deployed lines lie on top of each other.',
        'Um diagrama de fluxo cumulativo do time de Billing de junho a setembro de 2026: cinco '
        'linhas que sobem, chegou, começou, para revisão, integrado e com deploy, com as faixas '
        'entre elas sombreadas. Em julho a faixa entre para revisão e integrado alarga, a fila '
        'de revisão. A partir de agosto as faixas entre começou e deploy ficam finas, e as linhas '
        'de integrado e deploy ficam uma sobre a outra.'))
    p = Plot(f, 56, 30, 560, 270, 0, len(days) - 1, 0, 150)
    p.yaxis([0, 50, 100, 150])
    p.baseline()
    order = ['created', 'started', 'review', 'merged', 'deployed']
    fills = ['--panel', '--scan', '--panel', '--scan', None]
    strokes = ['--paper-dim', '--phosphor', '--amber', '--paper', '--paper-dim']
    xs = list(range(len(days)))
    for k in range(4):
        top, bot = c[order[k]], c[order[k + 1]]
        d = 'M' + ' L'.join(f'{p.sx(x):.1f} {p.sy(v):.1f}' for x, v in zip(xs, top))
        d += ' L' + ' L'.join(f'{p.sx(x):.1f} {p.sy(v):.1f}' for x, v in reversed(list(zip(xs, bot))))
        f.path(d + ' Z', stroke=None, fill=fills[k], width=0)
    for k, col in enumerate(order):
        p.polyline(xs, c[col], stroke=strokes[k], width=1.5, dash='3 2' if col == 'deployed' else None)
    names = T(lang, ['arrived', 'started', 'to review', 'merged', 'deployed'],
              ['chegou', 'começou', 'para revisão', 'integrado', 'com deploy'])
    ys, last = [], None
    for o in order:
        y = p.sy(c[o][-1])
        if last is not None and y < last + 13:
            y = last + 13
        ys.append(y)
        last = y
    for k, n in enumerate(names):
        f.text(566, ys[k], n, size=10, anchor='start', fill='--paper' if k != 4 else '--paper-dim')
    for d in (date(2026, 6, 1), date(2026, 7, 1), date(2026, 8, 1), date(2026, 9, 1)):
        f.text(p.sx((d - days[0]).days), 286, day_label(lang, d), size=9.5, anchor='start',
               fill='--paper-dim')
    xa = p.sx((date(2026, 8, 3) - days[0]).days)
    f.line(xa, 30, xa, 270, stroke='--paper-dim', width=1, dash='4 3')
    f.text(56, 14, T(lang, 'items that had reached each column, day by day',
                     'itens que tinham chegado a cada coluna, dia a dia'),
           size=10, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'The board\'s history in one picture: the thickness of each band is how many items '
                'were in that state, and the steepness of each line is how fast items crossed it.',
                'A história do quadro numa imagem: a espessura de cada faixa é quantos itens '
                'estavam naquele estado, e a inclinação de cada linha é a rapidez com que os itens '
                'a cruzaram.')


@figure('l03-patterns', 3)
def l03_patterns(lang):
    f = Fig('l03-patterns', 680, 220, T(
        lang,
        'Three small cumulative flow diagrams drawn as sketches. In the first, the band between '
        'two lines widens because the upper line rises faster than the lower one: a bottleneck. '
        'In the second, the lower line goes flat while the upper one keeps rising: nothing is '
        'finishing. In the third, the lower line rises in steps: work crosses that boundary in '
        'batches.',
        'Três pequenos diagramas de fluxo cumulativo desenhados como esboço. No primeiro, a '
        'faixa entre duas linhas alarga porque a de cima sobe mais rápido que a de baixo: um '
        'gargalo. No segundo, a linha de baixo fica plana enquanto as outras continuam subindo: '
        'nada está terminando. No terceiro, a linha de baixo sobe em degraus: o trabalho cruza '
        'essa fronteira em lotes.'))
    titles = T(lang, ['a band that widens', 'a line that goes flat', 'stairs instead of a slope'],
               ['uma faixa que alarga', 'uma linha que fica plana', 'degraus em vez de rampa'])
    notes = T(lang, ['a queue is growing', 'nothing is finishing', 'work moves in batches'],
              ['uma fila está crescendo', 'nada está terminando', 'o trabalho anda em lotes'])
    for k in range(3):
        x0 = 20 + k * 226
        f.rect(x0, 30, 200, 150, stroke='--wire', fill='--panel', width=1, rx=4)
        f.text(x0 + 100, 18, titles[k], size=10.5, weight='600')
        f.text(x0 + 100, 198, notes[k], size=10, fill='--paper-dim', italic=True)
        bx, by, w, h = x0 + 14, 166, 172, 120
        if k == 0:
            top = [(0, 30), (1, 70), (2, 110)]
            bot = [(0, 20), (1, 40), (2, 58)]
        elif k == 1:
            top = [(0, 30), (1, 70), (2, 108)]
            bot = [(0, 20), (1, 56), (1.2, 62), (2, 62)]
        else:
            top = [(0, 30), (1, 70), (2, 108)]
            bot = [(0, 18), (0.45, 18), (0.45, 42), (1.1, 42), (1.1, 68), (1.75, 68), (1.75, 92),
                   (2, 92)]

        def pts(seq):
            return ' L'.join(f'{bx + a / 2 * w:.1f} {by - v:.1f}' for a, v in seq)
        f.path('M' + pts(top), stroke='--phosphor', width=1.6)
        f.path('M' + pts(bot), stroke='--amber', width=1.6)
    return f, T(lang,
                'Three shapes worth knowing on sight. Each is visible days before the cycle times '
                'of finished items change.',
                'Três formas que vale reconhecer de relance. Cada uma aparece dias antes de os '
                'tempos de ciclo dos itens terminados mudarem.')


def ages_on(items, today):
    recent = [(when(i['merged']) - when(i['started'])).days for i in items
              if i['merged'] and today - timedelta(days=30) < when(i['merged']) <= today]
    bands = {p: pctl(recent, p) for p in (50, 70, 85, 95)}
    dots = []
    for i in items:
        s, r, m = when(i['started']), when(i['review']), when(i['merged'])
        if not s or s > today or (m and m <= today):
            continue
        dots.append(('review' if r and r <= today else 'development', (today - s).days))
    return bands, dots


@figure('l03-ageing', 3)
def l03_ageing(lang):
    items, _ = billing()
    panels = [(date(2026, 7, 15), T(lang, '15 July', '15 de julho')),
              (date(2026, 9, 30), T(lang, '30 September', '30 de setembro'))]
    data = [ages_on(items, d) for d, _ in panels]
    b1, d1 = data[0]
    b2, d2 = data[1]
    f = Fig('l03-ageing', 680, 320, T(
        lang,
        f'Two ageing charts of the Billing team\'s board. On 15 July, {len(d1)} items are open; '
        'the oldest are all in review, up to '
        f'{max(a for c, a in d1 if c == "review")} days, above the 85th-percentile band at '
        f'{b1[85]} days. On 30 September, {len(d2)} items are open; one item in development is '
        f'{max(a for c, a in d2)} days old, far above the 95th-percentile band at {b2[95]} days, '
        'and the rest are under a week.',
        f'Dois gráficos de envelhecimento do quadro do time de Billing. Em 15 de julho há '
        f'{len(d1)} itens abertos; os mais velhos estão todos em revisão, até '
        f'{max(a for c, a in d1 if c == "review")} dias, acima da faixa do percentil 85 em '
        f'{b1[85]} dias. Em 30 de setembro há {len(d2)} itens abertos; um item em desenvolvimento '
        f'tem {max(a for c, a in d2)} dias, bem acima da faixa do percentil 95 em {b2[95]} dias, '
        'e os outros têm menos de uma semana.'))
    cols = T(lang, ['development', 'review'], ['desenvolvimento', 'revisão'])
    for k, ((day, title), (bands, dots)) in enumerate(zip(panels, data)):
        x0 = 60 + k * 320
        p = Plot(f, x0, 40, x0 + 260, 270, 0, 2, 0, 45)
        if k == 0:
            p.yaxis([0, 15, 30, 45])
        else:
            p.yaxis([0, 15, 30, 45], fmt=lambda t: '')
        p.baseline()
        f.text(x0 + 130, 24, title, size=11, weight='600')
        prev = 0
        for q, fill in ((50, '--scan'), (70, '--panel'), (85, '--scan'), (95, '--panel')):
            v = bands[q]
            if v > prev:
                f.bar(x0, p.sy(v), 260, p.sy(prev) - p.sy(v), fill=fill, stroke=None, width=0)
            f.line(x0, p.sy(v), x0 + 260, p.sy(v), stroke='--paper-dim', width=0.8, dash='3 3')
            prev = v
        f.text(x0 + 258, p.sy(bands[85]) - 6, T(lang, f'85th: {bands[85]}', f'p85: {bands[85]}'),
               size=9, anchor='end', fill='--paper-dim')
        for j, col in enumerate(['development', 'review']):
            cx = p.sx(0.5 + j)
            f.text(cx, 286, cols[j], size=10)
            same = {}
            for c, a in dots:
                if c != col:
                    continue
                n = same.get(a, 0)
                same[a] = n + 1
                f.circle(cx - 30 + (n % 7) * 10, p.sy(a), 4,
                         fill='--amber' if a > bands[85] else '--phosphor')
    f.text(60, 304, T(lang, 'age in days; bands are the 50th, 70th, 85th and 95th percentiles of recent cycle times',
                      'idade em dias; as faixas são os percentis 50, 70, 85 e 95 dos tempos de ciclo recentes'),
           size=9.5, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'A queue and a stuck item look different. In July the old dots crowd one column; '
                'in September one dot stands alone far above everything else.',
                'Uma fila e um item travado têm cara diferente. Em julho os pontos velhos lotam uma '
                'coluna; em setembro um ponto fica sozinho, muito acima de todo o resto.')


# ------------------------------------------------------------------ lesson 4

@figure('l04-before-after', 4)
def l04_before_after(lang):
    items, _ = billing()
    a = [c for m, c, s in cycle_days(items, date(2026, 6, 1), date(2026, 7, 31))]
    b = [c for m, c, s in cycle_days(items, date(2026, 9, 1), date(2026, 9, 30))]
    f = Fig('l04-before-after', 680, 310, T(
        lang,
        f'Two dot histograms of cycle time in days, one dot per item. June and July, {len(a)} '
        f'items, spread from {min(a)} to {max(a)} days with the median at {pctl(a, 50)} and the '
        f'85th percentile at {pctl(a, 85)}. September, {len(b)} items, packed between {min(b)} '
        f'and {max(b)} days with the median at {pctl(b, 50)} and the 85th percentile at '
        f'{pctl(b, 85)}.',
        f'Dois histogramas de pontos do tempo de ciclo em dias, um ponto por item. Junho e julho, '
        f'{len(a)} itens, espalhados de {min(a)} a {max(a)} dias, com mediana em {pctl(a, 50)} e '
        f'percentil 85 em {pctl(a, 85)}. Setembro, {len(b)} itens, concentrados entre {min(b)} e '
        f'{max(b)} dias, com mediana em {pctl(b, 50)} e percentil 85 em {pctl(b, 85)}.'))
    x0, x1, top = 150, 650, 50
    sx = lambda d: x0 + d / 50 * (x1 - x0)
    rows = [(T(lang, 'June and July', 'junho e julho'), a, 110, '--phosphor'),
            (T(lang, 'September', 'setembro'), b, 262, '--amber')]
    for label, vals, base, colour in rows:
        f.line(x0, base, x1, base, stroke='--paper-dim', width=1)
        f.text(x0 - 12, base - 10, label, size=10.5, anchor='end')
        f.text(x0 - 12, base + 6, T(lang, f'{len(vals)} items', f'{len(vals)} itens'), size=9.5,
               anchor='end', fill='--paper-dim')
        seen = {}
        for v in sorted(vals):
            k = v // 2
            n = seen.get(k, 0)
            seen[k] = n + 1
            f.circle(sx(k * 2 + 1), base - 6 - n * 8, 3.2, fill=colour)
        for q in (50, 85):
            x = sx(pctl(vals, q))
            f.line(x, base + 2, x, base + 12, stroke='--paper', width=1.4)
            f.text(x, base + 22, T(lang, f'{"median" if q == 50 else "85th"} {pctl(vals, q)}',
                                   f'{"mediana" if q == 50 else "p85"} {pctl(vals, q)}'),
                   size=9, fill='--paper-dim')
    for t in range(0, 51, 10):
        f.text(sx(t), 300, str(t), size=9, fill='--paper-dim')
    f.text(x0, 20, T(lang, 'cycle time in days, one dot per item merged',
                     'tempo de ciclo em dias, um ponto por item integrado'),
           size=10, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'The same team before and after the limit: fewer items open, about the same '
                'number finished, and each one done in a quarter of the time.',
                'O mesmo time antes e depois do limite: menos itens abertos, mais ou menos o mesmo '
                'número terminado, e cada um pronto em um quarto do tempo.')


# ------------------------------------------------------------------ lesson 5

def dora_periods():
    """The four metrics for June-July and for August-September."""
    items, deploys = billing()
    merged = {i['id']: datetime.fromisoformat(i['merged']) for i in items if i['merged']}
    out = []
    for lo, hi, weeks in (('2026-06', '2026-07', 61 / 7), ('2026-08', '2026-09', 61 / 7)):
        ds = [d for d in deploys if lo <= d['at'][:7] <= hi]
        lead = sorted((datetime.fromisoformat(d['at']) - merged[i]).total_seconds() / 3600
                      for d in ds for i in d['items'].split())
        fails = [d for d in ds if d['failed'] == '1']
        rest = sorted((datetime.fromisoformat(d['restored']) - datetime.fromisoformat(d['at']))
                      .total_seconds() / 60 for d in fails)
        mid = lambda v: (v[len(v) // 2] if len(v) % 2 else (v[len(v) // 2 - 1] + v[len(v) // 2]) / 2)
        out.append({'freq': len(ds) / weeks, 'lead': mid(lead), 'cfr': len(fails) / len(ds),
                    'restore': mid(rest), 'n': len(ds), 'f': len(fails)})
    return out


@figure('l05-timeline', 5)
def l05_timeline(lang):
    f = Fig('l05-timeline', 680, 230, T(
        lang,
        'A timeline of one change: committed, merged, deployed, a failure noticed, service '
        'restored. Lead time for changes runs from the commit to the deployment. Time to restore '
        'runs from the failed deployment to the restore. Deployment frequency counts the '
        'deployments, and change failure rate is the share of them that fail.',
        'Uma linha do tempo de uma mudança: commit, integração, deploy, uma falha percebida, '
        'serviço restaurado. O lead time de mudanças vai do commit ao deploy. O tempo para '
        'restaurar vai do deploy com falha à restauração. A frequência de deploy conta os '
        'deploys, e a taxa de falha de mudanças é a fração deles que falha.'))
    xs = [60, 210, 360, 470, 620]
    names = T(lang, ['commit', 'merge', 'deploy', 'failure noticed', 'restored'],
              ['commit', 'integração', 'deploy', 'falha percebida', 'restaurado'])
    f.line(40, 100, 640, 100, stroke='--paper-dim', width=1.4)
    for k, (x, n) in enumerate(zip(xs, names)):
        f.circle(x, 100, 5, fill='--amber' if k >= 3 else '--phosphor')
        f.text(x, 80, n, size=10.5)

    def bracket(a, b, y, label, colour, dash=None):
        f.line(a, y, b, y, stroke=colour, width=1.6, dash=dash)
        f.line(a, y - 6, a, y + 6, stroke=colour, width=1.6)
        f.line(b, y - 6, b, y + 6, stroke=colour, width=1.6)
        f.text((a + b) / 2, y + 16, label, size=10.5, fill=colour)
    bracket(60, 360, 132, T(lang, 'lead time for changes', 'lead time de mudanças'), '--phosphor')
    bracket(210, 360, 30, T(lang, 'what this course measures, from the merge',
                            'o que este curso mede, a partir da integração'), '--paper-dim', dash='4 3')
    bracket(360, 620, 170, T(lang, 'time to restore', 'tempo para restaurar'), '--amber')
    f.text(360, 214, T(lang, 'deployment frequency counts these; change failure rate is the share that fail',
                       'a frequência de deploy conta estes; a taxa de falha é a fração que falha'),
           size=9.5, fill='--paper-dim')
    return f, T(lang,
                'Two of the metrics are durations on this line and two are counts of the deployments '
                'on it.',
                'Duas das métricas são durações nesta linha e duas são contagens dos deploys nela.')


@figure('l05-four', 5)
def l05_four(lang):
    a, b = dora_periods()
    f = Fig('l05-four', 680, 250, T(
        lang,
        'Four small bar charts, each comparing June and July with August and September. '
        f'Deployments per week: {num(lang, a["freq"])} then {num(lang, b["freq"])}. Median lead '
        f'time for changes in hours: {num(lang, a["lead"])} then {num(lang, b["lead"])}. Change '
        f'failure rate: {pct(lang, a["cfr"], 0)} then {pct(lang, b["cfr"], 0)}. Median time to '
        f'restore in minutes: {a["restore"]:.0f} then {b["restore"]:.0f}.',
        'Quatro pequenos gráficos de barras, cada um comparando junho e julho com agosto e '
        f'setembro. Deploys por semana: {num(lang, a["freq"])} e depois {num(lang, b["freq"])}. '
        f'Lead time de mudanças mediano em horas: {num(lang, a["lead"])} e depois '
        f'{num(lang, b["lead"])}. Taxa de falha de mudanças: {pct(lang, a["cfr"], 0)} e depois '
        f'{pct(lang, b["cfr"], 0)}. Tempo para restaurar mediano em minutos: '
        f'{a["restore"]:.0f} e depois {b["restore"]:.0f}.'))
    panels = [(T(lang, 'deploys per week', 'deploys por semana'), 'freq', lambda v: num(lang, v), T(lang, 'higher is better', 'maior é melhor')),
              (T(lang, 'lead time (hours)', 'lead time (horas)'), 'lead', lambda v: num(lang, v), T(lang, 'lower is better', 'menor é melhor')),
              (T(lang, 'change failure rate', 'taxa de falha'), 'cfr', lambda v: pct(lang, v, 0), T(lang, 'lower is better', 'menor é melhor')),
              (T(lang, 'time to restore (min)', 'tempo p/ restaurar (min)'), 'restore', lambda v: f'{v:.0f}', T(lang, 'lower is better', 'menor é melhor'))]
    for k, (title, key, fmt, note) in enumerate(panels):
        x0 = 20 + k * 166
        f.text(x0 + 70, 20, title, size=10.5, weight='600')
        f.text(x0 + 70, 36, note, size=9, fill='--paper-dim', italic=True)
        top = max(a[key], b[key])
        for j, (v, colour, lab) in enumerate(((a[key], '--phosphor', T(lang, 'Jun–Jul', 'jun–jul')),
                                              (b[key], '--amber', T(lang, 'Aug–Sep', 'ago–set')))):
            h = 140 * v / top
            bx = x0 + 22 + j * 64
            f.bar(bx, 200 - h, 44, h, fill='--scan', stroke=colour, width=1.4)
            f.text(bx + 22, 192 - h, fmt(v), size=10, weight='600')
            f.text(bx + 22, 214, lab, size=9.5, fill='--paper-dim')
        f.line(x0 + 10, 200, x0 + 140, 200, stroke='--paper-dim', width=1)
    f.text(340, 240, T(lang, f'{a["n"]} deployments ({a["f"]} failed) before, {b["n"]} ({b["f"]} failed) after',
                       f'{a["n"]} deploys ({a["f"]} com falha) antes, {b["n"]} ({b["f"]} com falha) depois'),
           size=9.5, fill='--paper-dim')
    return f, T(lang,
                'All four moved the right way at once: more deployments, faster, failing less and '
                'recovering sooner.',
                'As quatro andaram para o lado certo ao mesmo tempo: mais deploys, mais rápidos, '
                'falhando menos e voltando antes.')


# ------------------------------------------------------------------ lesson 6

@figure('l06-chain', 6)
def l06_chain(lang):
    f = Fig('l06-chain', 680, 260, T(
        lang,
        'Three columns joined by arrows. On the left, four families of capabilities: technical, '
        'architecture, process and flow, culture, marked "change these". In the middle, the four '
        'DORA metrics, marked "read these". On the right, what the organisation wants: users '
        'served, a business that works, people who stay. Habits move the metrics, and the '
        'metrics are associated with the outcomes.',
        'Três colunas ligadas por setas. À esquerda, quatro famílias de capacidades: técnicas, '
        'arquitetura, processo e fluxo, cultura, marcadas "mude estas". No meio, as quatro '
        'métricas DORA, marcadas "leia estas". À direita, o que a organização quer: usuários '
        'atendidos, um negócio que funciona, pessoas que ficam. Hábitos movem as métricas, e as '
        'métricas andam junto com os resultados.'))
    left = T(lang, ['technical', 'architecture', 'process and flow', 'culture'],
             ['técnicas', 'arquitetura', 'processo e fluxo', 'cultura'])
    mid = T(lang, ['deployment frequency', 'lead time for changes', 'change failure rate', 'time to restore'],
            ['frequência de deploy', 'lead time de mudanças', 'taxa de falha', 'tempo para restaurar'])
    right = T(lang, ['users served', 'a business that works', 'people who stay'],
              ['usuários atendidos', 'um negócio que funciona', 'pessoas que ficam'])
    f.text(100, 24, T(lang, 'capabilities: change these', 'capacidades: mude estas'), size=10.5, weight='600')
    f.text(340, 24, T(lang, 'the four metrics: read these', 'as quatro métricas: leia estas'), size=10.5, weight='600')
    f.text(580, 24, T(lang, 'what the company wants', 'o que a empresa quer'), size=10.5, weight='600')
    for k, t in enumerate(left):
        f.rect(20, 44 + k * 50, 160, 36, stroke='--phosphor', fill='--panel', width=1.2)
        f.text(100, 62 + k * 50, t, size=10.5)
    for k, t in enumerate(mid):
        f.rect(250, 44 + k * 50, 180, 36, stroke='--paper-dim', fill='--panel', width=1.2)
        f.text(340, 62 + k * 50, t, size=10.5)
    for k, t in enumerate(right):
        f.rect(500, 69 + k * 50, 160, 36, stroke='--amber', fill='--panel', width=1.2)
        f.text(580, 87 + k * 50, t, size=10.5)
    f.line(186, 137, 244, 137, stroke='--paper-dim', width=1.6, arrow=True)
    f.line(436, 137, 494, 137, stroke='--paper-dim', width=1.6, arrow=True)
    f.text(215, 124, T(lang, 'move', 'movem'), size=9.5, fill='--paper-dim', italic=True)
    f.text(465, 124, T(lang, 'go with', 'andam com'), size=9.5, fill='--paper-dim', italic=True)
    f.text(340, 250, T(lang, 'a target set on the middle column skips the left one',
                       'uma meta posta na coluna do meio pula a da esquerda'),
           size=10, fill='--paper-dim', italic=True)
    return f, T(lang,
                'The work happens in the left column. The middle one is where you look to see '
                'whether it worked.',
                'O trabalho acontece na coluna da esquerda. A do meio é onde você olha para ver se '
                'funcionou.')


# ------------------------------------------------------------------ lesson 7

@figure('l07-split', 7)
def l07_split(lang):
    f = Fig('l07-split', 680, 230, T(
        lang,
        'Two rows showing the same pipeline run at 17:20 carrying three changes, the first of which failed. In the top row '
        'it is counted as one deployment; in the bottom row as three deployments at the same '
        'minute. The changes, the time they reached users and the one failure are identical in '
        'both rows; only the count differs.',
        'Duas linhas mostrando a mesma rodada do pipeline às 17h20 levando três mudanças, a primeira com falha. Na de '
        'cima ela conta como um deploy; na de baixo como três deploys no mesmo minuto. As '
        'mudanças, a hora em que chegaram aos usuários e a única falha são idênticas nas duas '
        'linhas; só a contagem muda.'))
    rows = [(T(lang, 'as recorded', 'como registrado'), 1, 70), (T(lang, 'one per change', 'um por mudança'), 3, 160)]
    for label, n, y in rows:
        f.text(20, y, label, size=10.5, anchor='start', weight='600')
        f.line(160, y, 640, y, stroke='--paper-dim', width=1.2)
        f.circle(400, y, 5, fill='--phosphor')
        f.text(400, y + 22, '17:20', size=9.5, mono=True, fill='--paper-dim')
        for k in range(3):
            cx = 280 + k * 40
            bad = k == 0
            f.rect(cx - 16, y - 34, 32, 20, stroke='--amber' if bad else '--phosphor', fill='--scan', width=1.2, rx=3)
        boxes = [(256, y - 40, 128, 32)] if n == 1 else [(260 + k * 40, y - 38, 40, 28) for k in range(3)]
        for bx, by, bw, bh in boxes:
            f.path(f'M{bx} {by} L{bx + bw} {by} L{bx + bw} {by + bh} L{bx} {by + bh} Z',
                   stroke='--paper', width=1, dash='4 3')
        f.text(560, y - 10, T(lang, f'{n} deployment' + ('' if n == 1 else 's'), f'{n} deploy' + ('' if n == 1 else 's')),
               size=11, weight='600')
        f.text(560, y + 8, T(lang, f'failure rate {1 / n:.0%}', f'taxa de falha {1 / n:.0%}'.replace('%', '%')),
               size=10, fill='--paper-dim')
    f.text(340, 214, T(lang, 'the first change failed; all three reached users at the same minute in both rows',
                       'a primeira mudança falhou; as três chegaram aos usuários no mesmo minuto nas duas linhas'),
           size=9.5, fill='--paper-dim')
    return f, T(lang,
                'Splitting changes the count, not the event. Lead time and time to restore are '
                'measured on the changes and the failure, so they do not move.',
                'Dividir muda a contagem, não o evento. Lead time e tempo para restaurar são medidos '
                'nas mudanças e na falha, então não se mexem.')


# ------------------------------------------------------------------ lesson 9

@figure('l09-points', 9)
def l09_points(lang):
    items, _ = billing()
    def group(lo, hi):
        out = {}
        for i in items:
            if i['merged'] and lo <= i['started'] <= hi:
                out.setdefault(int(i['points']), []).append(
                    (when(i['merged']) - when(i['started'])).days)
        return out
    panels = [(T(lang, 'started in June and July', 'começados em junho e julho'), group('2026-06-01', '2026-07-31')),
              (T(lang, 'started from 3 August', 'começados a partir de 3 de agosto'), group('2026-08-03', '2026-09-30'))]
    f = Fig('l09-points', 680, 300, T(
        lang,
        'Two strip charts of cycle time in days against the story points each item was given, '
        'one dot per item. For items started in June and July, every points value spreads over '
        'weeks and the groups overlap almost completely. For items started from 3 August, all '
        'groups sit lower and rise slightly with points, and still overlap.',
        'Dois gráficos de faixa do tempo de ciclo em dias contra os story points de cada item, '
        'um ponto por item. Para itens começados em junho e julho, todo valor de pontos se '
        'espalha por semanas e os grupos se sobrepõem quase por completo. Para itens começados a '
        'partir de 3 de agosto, todos os grupos ficam mais baixos e sobem um pouco com os pontos, '
        'e ainda se sobrepõem.'))
    for k, (title, g) in enumerate(panels):
        x0 = 60 + k * 320
        p = Plot(f, x0, 40, x0 + 260, 250, 0, 5, 0, 60)
        p.yaxis([0, 20, 40, 60], fmt=(str if k == 0 else (lambda t: '')))
        p.baseline()
        f.text(x0 + 130, 24, title, size=10.5, weight='600')
        for j, pts in enumerate([1, 2, 3, 5, 8]):
            cx = p.sx(j + 0.5)
            f.text(cx, 266, str(pts), size=10, fill='--paper-dim')
            seen = {}
            for d in sorted(g.get(pts, [])):
                n = seen.get(d, 0)
                seen[d] = n + 1
                f.circle(cx - 8 + (n % 5) * 4, p.sy(d), 2.6,
                         fill='--phosphor' if k == 0 else '--amber')
    f.text(340, 290, T(lang, 'story points given to the item; cycle time in days up the side',
                       'story points dados ao item; tempo de ciclo em dias na vertical'),
           size=9.5, fill='--paper-dim')
    return f, T(lang,
                'Removing the waiting made every item faster and made the estimates matter a little '
                'more. It did not make a three reliably longer than a one.',
                'Tirar a espera deixou todo item mais rápido e fez as estimativas importarem um pouco '
                'mais. Não fez um três ser sempre mais longo que um um.')


# @@LESSONS@@

if __name__ == '__main__':
    main()
