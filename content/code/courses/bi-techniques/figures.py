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
