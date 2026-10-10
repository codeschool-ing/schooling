#!/usr/bin/env python3
"""Every diagram in the bi-techniques course, drawn from Panela's data.

A chart drawn by hand is a claim about data nobody can check. These are
computed: the lines, the bars and the points come from the same CSV files the
lessons' programs read, so a figure cannot drift from the output beside it.

    sudo bash lab.sh ready                                # the data, once
    /home/ana/bi/.venv/bin/python figures.py              # rewrite every figure
    /home/ana/bi/.venv/bin/python figures.py --list       # the names, by lesson

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

Only palette tokens are used, so each drawing turns over with the theme like
the page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel. The helpers are the statistics course's.
"""
import glob
import json
import math
import os
import re
import sys

import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
BI = os.environ.get('BI', '/home/ana/bi')

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

    def path(self, d, stroke='--paper-dim', width=1.2, fill='none', dash=None, arrow=False,
             opacity=None, cap=None):
        extra = ''
        if dash:
            extra += f' stroke-dasharray="{dash}"'
        if arrow:
            mid = f'st-ah{stroke.replace("--", "-")}'
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

    def rect(self, x, y, w, h, stroke='--wire', fill='--panel', width=1.2, rx=4, dash=None):
        extra = f' stroke-dasharray="{dash}"' if dash else ''
        self.parts.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" '
            f'fill="var({fill})" stroke="var({stroke})" stroke-width="{width}"{extra}></rect>')

    def circle(self, x, y, r, fill='--phosphor', stroke=None, width=1.2):
        st = f' stroke="var({stroke})" stroke-width="{width}"' if stroke else ''
        fv = 'none' if fill is None else f'var({fill})'
        self.parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{fv}"{st}></circle>')

    def svg(self):
        defs = ''
        if self.markers:
            defs = '<defs>' + ''.join(
                f'<marker id="{m}" viewBox="0 0 10 8" refX="9" refY="4" markerWidth="8" '
                f'markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 4 L0 8 z" '
                f'fill="var({c})"></path></marker>' for m, c in sorted(self.markers)) + '</defs>'
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" data-fig="{self.name}" '
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

    def xaxis(self, ticks, fmt=str, label=None, size=9.5):
        f = self.f
        f.line(self.x0, self.y1, self.x1, self.y1, stroke='--paper-dim', width=1.2)
        for t in ticks:
            x = self.sx(t)
            f.line(x, self.y1, x, self.y1 + 4, stroke='--paper-dim', width=1)
            f.text(x, self.y1 + 13, fmt(t), size=size, fill='--paper-dim')
        if label:
            f.text((self.x0 + self.x1) / 2, self.y1 + 31, label, size=10, weight='600')

    def yaxis(self, ticks, fmt=str, label=None, grid=True, size=9.5):
        f = self.f
        f.line(self.x0, self.y0, self.x0, self.y1, stroke='--paper-dim', width=1.2)
        for t in ticks:
            y = self.sy(t)
            if grid and t != self.ymin:
                f.line(self.x0, y, self.x1, y, stroke='--wire', width=1)
            f.line(self.x0 - 4, y, self.x0, y, stroke='--paper-dim', width=1)
            f.text(self.x0 - 8, y, fmt(t), size=size, anchor='end', fill='--paper-dim')
        if label:
            f.text(self.x0, self.y0 - 14, label, size=10, anchor='start', weight='600')

    def bars(self, edges, counts, fill='--phosphor-dim', stroke='--phosphor', highlight=None):
        for i, c in enumerate(counts):
            if c <= 0:
                continue
            x0, x1 = self.sx(edges[i]), self.sx(edges[i + 1])
            y = self.sy(c)
            fl = fill
            if highlight and highlight(i):
                fl = '--amber'
            self.f.path(f'M{x0:.1f} {self.y1:.1f} L{x0:.1f} {y:.1f} L{x1:.1f} {y:.1f} '
                        f'L{x1:.1f} {self.y1:.1f} Z', stroke=stroke, width=1, fill=fl)

    def curve(self, fn, a, b, steps=160, stroke='--phosphor', width=2, dash=None, fill=None):
        pts = [(a + (b - a) * i / steps) for i in range(steps + 1)]
        d = 'M' + ' L'.join(f'{self.sx(x):.1f} {self.sy(fn(x)):.1f}' for x in pts)
        if fill:
            d += f' L{self.sx(b):.1f} {self.sy(0):.1f} L{self.sx(a):.1f} {self.sy(0):.1f} Z'
            self.f.path(d, stroke=None, width=0, fill=fill, opacity=0.55)
        else:
            self.f.path(d, stroke=stroke, width=width, dash=dash)

    def vline(self, v, label=None, stroke='--amber', dash='4 3', top=None, size=9.5, anchor='middle',
              fill=None, dy=0):
        x = self.sx(v)
        y = self.y0 if top is None else top
        self.f.line(x, self.y1, x, y, stroke=stroke, width=1.6, dash=dash)
        if label:
            self.f.text(x, y - 8 + dy, label, size=size, anchor=anchor, fill=fill or stroke)


def histogram(xs, edges):
    counts = [0] * (len(edges) - 1)
    for x in xs:
        for i in range(len(edges) - 1):
            last = i == len(edges) - 2
            if edges[i] <= x < edges[i + 1] or (last and x == edges[-1]):
                counts[i] += 1
                break
    return counts


# --------------------------------------------------------------- the figures

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




def csv(name, **kw):
    return pd.read_csv(os.path.join(BI, name), **kw)


def daily():
    return csv('daily_orders.csv', parse_dates=['date'], index_col='date')['orders']


MONTHS = {'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
          'pt': ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']}


def series(p, xs, ys, stroke='--phosphor', width=1.4, dash=None):
    d = 'M' + ' L'.join(f'{p.sx(x):.1f} {p.sy(y):.1f}' for x, y in zip(xs, ys))
    p.f.path(d, stroke=stroke, width=width, dash=dash)


def years_axis(p, first, last, lang):
    """Ticks at each 1 January, for a plot whose x is days since `first`."""
    f = p.f
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for y in range(first.year, last.year + 2):
        x = (pd.Timestamp(y, 1, 1) - first).days
        if 0 <= x <= (last - first).days + 1:
            f.line(p.sx(x), p.y1, p.sx(x), p.y1 + 4, stroke='--paper-dim', width=1)
        mid = (pd.Timestamp(y, 7, 1) - first).days
        if 0 <= mid <= (last - first).days:
            f.text(p.sx(mid), p.y1 + 14, str(y), size=10, fill='--paper-dim', mono=True)


# ------------------------------------------------------------------ lesson 1

@figure('l01-daily', 1)
def l01_daily(lang):
    s = daily()
    first, last = s.index[0], s.index[-1]
    x = [(d - first).days for d in s.index]
    t = {'en': dict(
        label='Panela\'s orders for every day from January 2023 to December 2025. The line rises '
              'from about 900 a day to about 1,500, thickened by a weekly rhythm, dips each '
              'January, shoots up on each Black Friday, falls on Christmas Day and New Year\'s '
              'Day, and steps down in September 2025.',
        y='orders per day', bf='Black Friday', xmas='25 Dec, 1 Jan', carn='Carnival',
        rise='prices rise',
        cap='Three years of one number, and at least four movements in it: growth, a weekly '
            'rhythm that makes the line thick, a yearly swing, and holidays that the other '
            'three do not explain.'),
        'pt': dict(
        label='Os pedidos da Panela em cada dia de janeiro de 2023 a dezembro de 2025. A linha '
              'sobe de cerca de 900 por dia para cerca de 1.500, engrossada por um ritmo semanal, '
              'cai a cada janeiro, dispara em cada Black Friday, despenca no Natal e no Ano-Novo '
              'e desce um degrau em setembro de 2025.',
        y='pedidos por dia', bf='Black Friday', xmas='25 dez, 1 jan', carn='Carnaval',
        rise='preços sobem',
        cap='Três anos de um único número, e pelo menos quatro movimentos dentro dele: '
            'crescimento, um ritmo semanal que engrossa a linha, uma oscilação anual e feriados '
            'que os outros três não explicam.')}[lang]
    f = Fig('l01-daily', 640, 300, t['label'])
    p = Plot(f, 60, 40, 620, 250, 0, len(s), 0, 2400)
    p.yaxis(range(0, 2401, 600), fmt=lambda v: num(lang, v, 0), label=t['y'])
    series(p, x, s.values, width=0.9)
    years_axis(p, first, last, lang)
    bf = pd.Timestamp('2024-11-29')
    f.text(p.sx((bf - first).days), p.sy(s[bf]) - 10, t['bf'], size=10, fill='--amber', weight='600')
    xm = pd.Timestamp('2024-12-25')
    f.text(p.sx((xm - first).days) - 6, p.sy(s[xm]) + 4, t['xmas'], size=10, anchor='end',
           fill='--amber', weight='600')
    cv = pd.Timestamp('2023-02-19')
    f.text(p.sx((cv - first).days) + 8, p.sy(s[cv]) + 12, t['carn'], size=10, anchor='start',
           fill='--amber', weight='600')
    pr = (pd.Timestamp('2025-09-01') - first).days
    f.line(p.sx(pr), p.y0 + 4, p.sx(pr), p.y1, stroke='--amber', width=1.2, dash='4 3')
    f.text(p.sx(pr) - 4, p.y0 + 6, t['rise'], size=10, anchor='end', fill='--amber', weight='600')
    return f, t['cap']


@figure('l01-components', 1)
def l01_components(lang):
    t = {'en': dict(
        label='Five rows drawn over six years. Trend: a line rising slowly. Season: a wave that '
              'repeats every year, always the same length. Cycle: a slow wave whose rises and '
              'falls last different lengths of time. Noise: a jagged line with no pattern. Sum: '
              'all four added together. A band marks three years of data, and inside it the '
              'cycle only rises, like a trend.',
        rows=['trend', 'season', 'cycle', 'noise', 'their sum'],
        notes=['the long direction', 'same length every year', 'no fixed length',
               'what nothing explains', 'what is measured'],
        win='three years of data', yr='year',
        cap='A season repeats on the calendar and a cycle does not. Inside a window of three '
            'years, the cycle only climbs, and nothing in the data separates it from the trend.'),
        'pt': dict(
        label='Cinco linhas desenhadas ao longo de seis anos. Tendência: uma linha que sobe '
              'devagar. Sazonalidade: uma onda que se repete todo ano, sempre com o mesmo '
              'comprimento. Ciclo: uma onda lenta cujas subidas e descidas duram tempos '
              'diferentes. Ruído: uma linha serrilhada sem padrão. Soma: os quatro somados. Uma '
              'faixa marca três anos de dados, e dentro dela o ciclo só sobe, como uma tendência.',
        rows=['tendência', 'sazonalidade', 'ciclo', 'ruído', 'a soma'],
        notes=['a direção longa', 'mesmo comprimento todo ano', 'sem comprimento fixo',
               'o que nada explica', 'o que se mede'],
        win='três anos de dados', yr='ano',
        cap='A sazonalidade se repete no calendário e o ciclo não. Numa janela de três anos, o '
            'ciclo só sobe, e nada nos dados o separa da tendência.')}[lang]
    rng = np.random.default_rng(7)
    xs = np.linspace(0, 6, 361)
    trend = 0.5 * xs
    season = 0.55 * np.sin(2 * np.pi * xs)
    # a wave that falls for a year, rises for three and a half, then falls again
    knots = [0, 1.0, 4.4, 5.4, 6.0]
    vals = [0.3, -0.8, 0.9, 0.2, 0.45]
    cycle = np.interp(xs, knots, vals)
    cycle = np.convolve(np.pad(cycle, 12, mode='edge'), np.ones(25) / 25, mode='valid')
    noise = rng.normal(0, 0.22, len(xs))
    rows = [trend - trend.mean(), season, cycle, noise, trend + season + cycle + noise]
    f = Fig('l01-components', 640, 400, t['label'])
    top, h, gap = 26, 52, 14
    x0, x1 = 120, 470
    w0 = x0 + (x1 - x0) * 1.2 / 6
    w1 = x0 + (x1 - x0) * 4.2 / 6
    hh = 5 * (h + gap) - gap + 10
    f.path(f'M{w0:.1f} {top - 8:.1f} L{w1:.1f} {top - 8:.1f} L{w1:.1f} {top - 8 + hh:.1f} '
           f'L{w0:.1f} {top - 8 + hh:.1f} Z', stroke='--wire', width=1, fill='--scan')
    f.text((w0 + w1) / 2, top + 5 * (h + gap) + 6, t['win'], size=10, fill='--paper-dim')
    for i, (name, ys) in enumerate(zip(t['rows'], rows)):
        y0 = top + i * (h + gap)
        lo, hi = ys.min(), ys.max()
        pad = (hi - lo) * 0.08 + 1e-9
        p = Plot(f, x0, y0, x1, y0 + h, 0, 6, lo - pad, hi + pad)
        series(p, xs, ys, stroke='--amber' if i == 4 else '--phosphor', width=1.5)
        f.text(x0 - 12, y0 + h / 2, name, size=11, anchor='end', weight='600')
        f.text(x1 + 12, y0 + h / 2, t['notes'][i], size=10, anchor='start', fill='--paper-dim')
    yb = top + 5 * (h + gap) + 24
    f.line(x0, yb - 10, x1, yb - 10, stroke='--paper-dim', width=1)
    for k in range(7):
        xx = x0 + (x1 - x0) * k / 6
        f.line(xx, yb - 10, xx, yb - 6, stroke='--paper-dim', width=1)
        if k < 6:
            f.text(xx + (x1 - x0) / 12, yb + 2, f"{t['yr']} {k + 1}", size=9.5, fill='--paper-dim')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 2

@figure('l02-moving', 2)
def l02_moving(lang):
    s = daily()
    tr = s.rolling(7).mean()
    ce = s.rolling(7, center=True).mean()
    a, b = pd.Timestamp('2024-11-10'), pd.Timestamp('2024-12-20')
    days = pd.date_range(a, b)
    x = [(d - a).days for d in days]
    t = {'en': dict(
        label='Daily orders from 10 November to 20 December 2024 as dots, with two seven-day '
              'averages drawn through them. The Black Friday spike of 29 November lifts the '
              'trailing average from that day to 5 December, and lifts the centred average from '
              '26 November to 2 December, three days either side of it.',
        y='orders per day', tr='trailing: the day and six before', ce='centred: three either side',
        bf='Black Friday',
        cap='The same seven days averaged in two places. The trailing line can be drawn the '
            'moment a day closes, and it runs three days behind; the centred line sits on the '
            'day, and cannot be drawn for the last three.'),
        'pt': dict(
        label='Pedidos diários de 10 de novembro a 20 de dezembro de 2024 como pontos, com duas '
              'médias de sete dias passando por eles. O pico da Black Friday de 29 de novembro '
              'levanta a média móvel para trás desse dia até 5 de dezembro, e levanta a média '
              'centrada de 26 de novembro a 2 de dezembro, três dias de cada lado.',
        y='pedidos por dia', tr='para trás: o dia e os seis anteriores',
        ce='centrada: três de cada lado', bf='Black Friday',
        cap='Os mesmos sete dias com a média em dois lugares. A linha para trás pode ser '
            'desenhada assim que o dia fecha, e anda três dias atrasada; a centrada fica em cima '
            'do dia, e não pode ser desenhada nos três últimos.')}[lang]
    f = Fig('l02-moving', 640, 300, t['label'])
    p = Plot(f, 60, 40, 620, 240, -1, len(days), 900, 2100)
    p.yaxis(range(900, 2101, 300), fmt=lambda v: num(lang, v, 0), label=t['y'])
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for i, d in enumerate(days):
        f.circle(p.sx(i), p.sy(s[d]), 3, fill='--paper-dim')
        if d.day in (1, 10, 20):
            f.line(p.sx(i), p.y1, p.sx(i), p.y1 + 4, stroke='--paper-dim', width=1)
            f.text(p.sx(i), p.y1 + 14, f"{d.day} {MONTHS[lang][d.month - 1]}", size=9.5,
                   fill='--paper-dim')
    series(p, x, tr[days].values, stroke='--amber', width=2)
    series(p, x, ce[days].values, stroke='--phosphor', width=2, dash='5 3')
    bfx = (pd.Timestamp('2024-11-29') - a).days
    f.text(p.sx(bfx) + 8, p.sy(2009), t['bf'], size=10, anchor='start', weight='600')
    f.line(80, 282, 104, 282, stroke='--amber', width=2)
    f.text(110, 282, t['tr'], size=10, anchor='start')
    f.line(350, 282, 374, 282, stroke='--phosphor', width=2, dash='5 3')
    f.text(380, 282, t['ce'], size=10, anchor='start')
    return f, t['cap']


@figure('l02-decomposition', 2)
def l02_decomposition(lang):
    from statsmodels.tsa.seasonal import seasonal_decompose
    w = daily().resample('W-SUN').sum()['2023-01-08':'2025-12-28']
    parts = seasonal_decompose(w, model='multiplicative', period=52)
    first = w.index[0]
    t = {'en': dict(
        label='Four panels for the weekly orders of 2023 to 2025. Observed: the weekly totals, '
              'rising with a dip each January. Trend: a smooth rise from about 6,800 to 9,700 '
              'orders a week, missing the first and last 26 weeks. Season: the same yearly shape '
              'three times, from 0.80 in the New Year weeks to 1.10 before Christmas. Residual: '
              'values close to 1, furthest in the Carnival weeks and one Black Friday.',
        rows=['observed', 'trend', 'season', 'residual'],
        miss='no trend here', cap='The classical decomposition of three years of weeks. The '
            'trend cannot see the first and last half-year, and the residual is quiet except '
            'where a holiday moved.'),
        'pt': dict(
        label='Quatro painéis para os pedidos semanais de 2023 a 2025. Observado: os totais '
              'semanais, subindo com uma queda a cada janeiro. Tendência: uma subida suave de '
              'cerca de 6.800 para 9.700 pedidos por semana, sem as primeiras e as últimas 26 '
              'semanas. Sazonalidade: o mesmo desenho anual três vezes, de 0,80 nas semanas de '
              'Ano-Novo a 1,10 antes do Natal. Resíduo: valores perto de 1, mais longe nas '
              'semanas de Carnaval e numa Black Friday.',
        rows=['observado', 'tendência', 'sazonalidade', 'resíduo'],
        miss='sem tendência aqui', cap='A decomposição clássica de três anos de semanas. A '
            'tendência não enxerga o primeiro nem o último semestre, e o resíduo fica quieto '
            'exceto onde um feriado mudou de lugar.')}[lang]
    f = Fig('l02-decomposition', 640, 420, t['label'])
    rows = [(w, 5500, 12000, [6000, 9000]),
            (parts.trend, 5500, 12000, [6000, 9000]),
            (parts.seasonal, 0.75, 1.15, [0.8, 1.0, 1.1]),
            (parts.resid, 0.9, 1.1, [0.9, 1.0, 1.1])]
    top, h, gap = 22, 70, 22
    for i, (ser, lo, hi, ticks) in enumerate(rows):
        y0 = top + i * (h + gap)
        p = Plot(f, 120, y0, 620, y0 + h, 0, len(w) * 7, lo, hi)
        for tk in ticks:
            f.line(p.x0, p.sy(tk), p.x1, p.sy(tk), stroke='--wire', width=1)
            f.text(p.x0 - 6, p.sy(tk), num(lang, tk, 0 if tk > 100 else 1), size=9,
                   anchor='end', fill='--paper-dim')
        f.text(14, y0 + h / 2, t['rows'][i], size=11, anchor='start', weight='600')
        ok = ser.dropna()
        xs = [(d - first).days for d in ok.index]
        series(p, xs, ok.values, stroke='--amber' if i == 3 else '--phosphor', width=1.5)
        if i == 1:
            f.text(p.sx(13 * 7), y0 + h / 2, t['miss'], size=9.5, fill='--paper-dim')
            f.text(p.sx((len(w) - 13) * 7), y0 + h / 2, t['miss'], size=9.5, fill='--paper-dim')
    yb = top + 4 * (h + gap) - gap + 4
    p = Plot(f, 120, top, 620, yb, 0, len(w) * 7, 0, 1)
    years_axis(p, first, w.index[-1], lang)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 3

@figure('l03-weights', 3)
def l03_weights(lang):
    t = {'en': dict(
        label='Bars showing the weight each of the last ten weeks gets in simple exponential '
              'smoothing, for three values of alpha. With alpha 0.9 the latest week takes 0.9 and '
              'the rest almost nothing. With 0.5 the weights halve each week. With 0.1 they start '
              'at 0.1 and fall slowly, so old weeks still count.',
        x='weeks ago', y='weight', cap='The same rule with three memories. Every past week '
            'counts, and each counts a fixed fraction less than the week after it; alpha is how '
            'big that fraction is.'),
        'pt': dict(
        label='Barras com o peso que cada uma das dez últimas semanas recebe na suavização '
              'exponencial simples, para três valores de alpha. Com alpha 0,9 a última semana '
              'leva 0,9 e o resto quase nada. Com 0,5 os pesos caem pela metade a cada semana. Com '
              '0,1 eles começam em 0,1 e caem devagar, então semanas antigas ainda contam.',
        x='semanas atrás', y='peso', cap='A mesma regra com três memórias. Toda semana passada '
            'conta, e cada uma conta uma fração fixa a menos que a semana seguinte; alpha é o '
            'tamanho dessa fração.')}[lang]
    f = Fig('l03-weights', 640, 250, t['label'])
    alphas = [0.9, 0.5, 0.1]
    for k, a in enumerate(alphas):
        x0 = 50 + k * 200
        p = Plot(f, x0, 50, x0 + 170, 190, -0.5, 9.5, 0, 1)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
        for i in range(10):
            wgt = a * (1 - a) ** i
            xa, xb = p.sx(i - 0.35), p.sx(i + 0.35)
            f.path(f'M{xa:.1f} {p.y1:.1f} L{xa:.1f} {p.sy(wgt):.1f} L{xb:.1f} {p.sy(wgt):.1f} '
                   f'L{xb:.1f} {p.y1:.1f} Z', stroke='--phosphor', width=1, fill='--phosphor-dim')
        for i in (0, 9):
            f.text(p.sx(i), p.y1 + 13, str(i + 1), size=9.5, fill='--paper-dim')
        f.text((p.x0 + p.x1) / 2, 30, 'alpha = ' + num(lang, a, 1), size=11, weight='600')
        if k == 0:
            for v in (0, 0.5, 1):
                f.text(p.x0 - 6, p.sy(v), num(lang, v, 1), size=9, anchor='end', fill='--paper-dim')
            f.text(p.x0 - 30, p.y0 - 20, t['y'], size=10, anchor='start', weight='600')
        f.text((p.x0 + p.x1) / 2, p.y1 + 32, t['x'], size=10, fill='--paper-dim')
    return f, t['cap']


@figure('l03-forecasts', 3)
def l03_forecasts(lang):
    from statsmodels.tsa.holtwinters import ExponentialSmoothing
    from statsmodels.tsa.statespace.sarimax import SARIMAX
    w = daily().resample('W-SUN').sum()['2023-01-08':'2025-12-28']
    train, test = w[:'2024-12-29'], w['2025-01-05':'2025-06-29']
    hw = ExponentialSmoothing(train, trend='add', seasonal='mul', seasonal_periods=52).fit()
    ar = SARIMAX(train, order=(1, 0, 1), seasonal_order=(0, 1, 0, 52), trend='c').fit(disp=False)
    h = len(test)
    first = pd.Timestamp('2024-07-07')
    show = w[first:'2025-06-29']
    t = {'en': dict(
        label='Weekly orders from July 2024 to June 2025 as a line, with two forecasts made at the '
              'end of 2024 drawn over the first 26 weeks of 2025: Holt-Winters and seasonal ARIMA. '
              'Both follow the actual weeks closely and both dip in mid-February, where Carnival had '
              'been in 2024, while the actual dip came in March.',
        y='orders per week', act='actual', hw='Holt-Winters', ar='seasonal ARIMA',
        cut='forecast made here', carn='both expect Carnival here',
        cap='Two families, one set of training weeks, and forecasts that track 2025 closely and '
            'make the same mistake in February: both learnt last year\'s Carnival.'),
        'pt': dict(
        label='Pedidos semanais de julho de 2024 a junho de 2025 como uma linha, com duas previsões '
              'feitas no fim de 2024 desenhadas sobre as 26 primeiras semanas de 2025: Holt-Winters '
              'e ARIMA sazonal. As duas seguem bem as semanas reais e as duas caem em meados de '
              'fevereiro, onde o Carnaval tinha ficado em 2024, enquanto a queda real veio em março.',
        y='pedidos por semana', act='real', hw='Holt-Winters', ar='ARIMA sazonal',
        cut='previsão feita aqui', carn='as duas esperam o Carnaval aqui',
        cap='Duas famílias, um mesmo conjunto de semanas de treino, e previsões que acompanham bem '
            '2025 e erram igual em fevereiro: as duas aprenderam o Carnaval do ano passado.')}[lang]
    f = Fig('l03-forecasts', 640, 310, t['label'])
    p = Plot(f, 70, 40, 620, 240, 0, (show.index[-1] - first).days, 6000, 12000)
    p.yaxis(range(6000, 12001, 2000), fmt=lambda v: num(lang, v, 0), label=t['y'])
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for d in pd.date_range(first, show.index[-1], freq='MS'):
        if d.month in (7, 10, 1, 4):
            x = p.sx((d - first).days)
            f.line(x, p.y1, x, p.y1 + 4, stroke='--paper-dim', width=1)
            f.text(x, p.y1 + 14, f"{MONTHS[lang][d.month - 1]} {d.year}", size=9.5, fill='--paper-dim')
    xs = lambda idx: [(d - first).days for d in idx]
    series(p, xs(show.index), show.values, stroke='--paper', width=1.6)
    series(p, xs(test.index), hw.forecast(h).values, stroke='--phosphor', width=1.8, dash='5 3')
    series(p, xs(test.index), ar.forecast(h).values, stroke='--amber', width=1.8, dash='2 3')
    cx = p.sx((pd.Timestamp('2024-12-29') - first).days)
    f.line(cx, p.y0, cx, p.y1, stroke='--wire', width=1.2, dash='3 3')
    f.text(cx - 4, p.y0 + 4, t['cut'], size=9.5, anchor='end', fill='--paper-dim')
    fx = p.sx((pd.Timestamp('2025-02-16') - first).days)
    f.text(fx, p.sy(6900), t['carn'], size=9.5, fill='--paper-dim')
    for i, (lab, col, dash) in enumerate([(t['act'], '--paper', None), (t['hw'], '--phosphor', '5 3'),
                                          (t['ar'], '--amber', '2 3')]):
        x0 = 90 + i * 170
        f.line(x0, 288, x0 + 24, 288, stroke=col, width=1.8, dash=dash)
        f.text(x0 + 30, 288, lab, size=10, anchor='start')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 4

def month_ticks(p, first, last, lang, months=(1, 4, 7, 10)):
    f = p.f
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for d in pd.date_range(first, last, freq='MS'):
        if d.month in months:
            x = p.sx((d - first).days)
            f.line(x, p.y1, x, p.y1 + 4, stroke='--paper-dim', width=1)
            f.text(x, p.y1 + 14, f"{MONTHS[lang][d.month - 1]} {d.year}", size=9.5, fill='--paper-dim')


@figure('l04-horizon', 4)
def l04_horizon(lang):
    from statsmodels.tsa.holtwinters import ExponentialSmoothing
    w = daily().resample('W-SUN').sum()['2023-01-08':'2025-12-28']
    train, test = w[:'2024-12-29'], w['2025-01-05':]
    straight = ExponentialSmoothing(train, trend='add', seasonal='mul', seasonal_periods=52).fit()
    damped = ExponentialSmoothing(train, trend='add', damped_trend=True, seasonal='mul',
                                  seasonal_periods=52).fit()
    first = pd.Timestamp('2024-10-06')
    show = w[first:]
    t = {'en': dict(
        label='Weekly orders from October 2024 to December 2025, with two forecasts made at the end '
              'of 2024 for all of 2025: one with a straight trend and one with a damped trend. Both '
              'follow the actual weeks until August. After the price rise of September the actual '
              'weeks drop and both forecasts stay high, the straight one furthest away.',
        y='orders per week', act='actual', st='straight trend', dm='damped trend',
        rise='prices rise',
        cap='The same model, a week ahead and a year ahead. For six months the forecast is close; '
            'then the business changes, and the further the horizon reaches, the more of the '
            'change it misses.'),
        'pt': dict(
        label='Pedidos semanais de outubro de 2024 a dezembro de 2025, com duas previsões feitas no '
              'fim de 2024 para todo 2025: uma com tendência reta e outra com tendência amortecida. '
              'As duas seguem as semanas reais até agosto. Depois do aumento de preço de setembro as '
              'semanas reais caem e as duas previsões ficam altas, a reta mais longe.',
        y='pedidos por semana', act='real', st='tendência reta', dm='tendência amortecida',
        rise='preços sobem',
        cap='O mesmo modelo, uma semana à frente e um ano à frente. Por seis meses a previsão fica '
            'perto; depois o negócio muda, e quanto mais longe o horizonte chega, mais da mudança '
            'ele perde.')}[lang]
    f = Fig('l04-horizon', 640, 310, t['label'])
    p = Plot(f, 70, 40, 620, 240, 0, (show.index[-1] - first).days, 6000, 14000)
    p.yaxis(range(6000, 14001, 2000), fmt=lambda v: num(lang, v, 0), label=t['y'])
    month_ticks(p, first, show.index[-1], lang)
    xs = lambda idx: [(d - first).days for d in idx]
    series(p, xs(show.index), show.values, stroke='--paper', width=1.6)
    series(p, xs(test.index), straight.forecast(len(test)).values, stroke='--phosphor', width=1.8, dash='5 3')
    series(p, xs(test.index), damped.forecast(len(test)).values, stroke='--amber', width=1.8, dash='2 3')
    rx = p.sx((pd.Timestamp('2025-09-01') - first).days)
    f.line(rx, p.y0, rx, p.y1, stroke='--wire', width=1.2, dash='3 3')
    f.text(rx - 4, p.y0 + 4, t['rise'], size=9.5, anchor='end', fill='--paper-dim')
    for i, (lab, col, dash) in enumerate([(t['act'], '--paper', None), (t['st'], '--phosphor', '5 3'),
                                          (t['dm'], '--amber', '2 3')]):
        x0 = 90 + i * 170
        f.line(x0, 288, x0 + 24, 288, stroke=col, width=1.8, dash=dash)
        f.text(x0 + 30, 288, lab, size=10, anchor='start')
    return f, t['cap']


@figure('l04-band', 4)
def l04_band(lang):
    from statsmodels.tsa.statespace.sarimax import SARIMAX
    w = daily().resample('W-SUN').sum()['2023-01-08':'2025-12-28']
    train, test = w[:'2024-12-29'], w['2025-01-05':'2025-06-29']
    fc = SARIMAX(train, order=(1, 0, 1), seasonal_order=(0, 1, 0, 52), trend='c').fit(disp=False) \
        .get_forecast(len(test))
    lo, hi = fc.conf_int(alpha=0.2).T.values
    first = test.index[0]
    out = int(((test.values < lo) | (test.values > hi)).sum())
    t = {'en': dict(
        label=f'The 26 weeks from January to June 2025: a shaded 80% prediction interval around the '
              f'seasonal ARIMA forecast, and the actual weeks as dots. {out} of the 26 dots fall '
              f'outside the band, most of them below it, between January and April.',
        y='orders per week', inside='inside the 80% interval', outside='outside it',
        cap='An 80% interval should miss about one week in five. This one missed '
            f'{out} of 26: the model\'s claim about its own uncertainty was too modest.'),
        'pt': dict(
        label=f'As 26 semanas de janeiro a junho de 2025: um intervalo de previsão de 80% sombreado '
              f'em volta da previsão do ARIMA sazonal, e as semanas reais como pontos. {out} dos 26 '
              f'pontos caem fora da faixa, a maioria abaixo dela, entre janeiro e abril.',
        y='pedidos por semana', inside='dentro do intervalo de 80%', outside='fora dele',
        cap='Um intervalo de 80% deveria errar cerca de uma semana em cinco. Este errou '
            f'{out} de 26: o que o modelo dizia da própria incerteza era modesto demais.')}[lang]
    f = Fig('l04-band', 640, 300, t['label'])
    p = Plot(f, 70, 40, 620, 230, -3, (test.index[-1] - first).days + 3, 7000, 12000)
    p.yaxis(range(7000, 12001, 1000), fmt=lambda v: num(lang, v, 0), label=t['y'])
    month_ticks(p, first, test.index[-1], lang, months=range(1, 13))
    xs = [(d - first).days for d in test.index]
    d = 'M' + ' L'.join(f'{p.sx(x):.1f} {p.sy(v):.1f}' for x, v in zip(xs, hi))
    d += ' L' + ' L'.join(f'{p.sx(x):.1f} {p.sy(v):.1f}' for x, v in zip(reversed(xs), reversed(lo))) + ' Z'
    f.path(d, stroke=None, width=0, fill='--scan')
    series(p, xs, fc.predicted_mean.values, stroke='--phosphor', width=1.6)
    for x, v, a, b in zip(xs, test.values, lo, hi):
        if a <= v <= b:
            f.circle(p.sx(x), p.sy(v), 3.5, fill='--paper-dim')
        else:
            f.circle(p.sx(x), p.sy(v), 4, fill='--amber')
    f.circle(90, 278, 3.5, fill='--paper-dim')
    f.text(100, 278, t['inside'], size=10, anchor='start')
    f.circle(330, 278, 4, fill='--amber')
    f.text(340, 278, t['outside'], size=10, anchor='start')
    return f, t['cap']


def main():
    if '--list' in sys.argv:
        for name, (lesson, _) in FIGURES.items():
            print(f'{lesson:>3}  {name}')
        return
    changed = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        changed += apply(path)
    print(f'{len(FIGURES)} figures drawn, {changed} file(s) rewritten')


if __name__ == '__main__':
    main()
