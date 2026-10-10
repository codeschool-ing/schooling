#!/usr/bin/env python3
"""Every diagram in the machine-learning course, drawn from the lab's own files.

A decision boundary drawn by hand is a claim about a model nobody fitted. These
are computed: every point, curve and count comes from the files make_data.py
writes, through the same libraries the lessons pin, so a figure cannot drift
from the transcript beside it.

    sudo bash lab.sh up                          # once: the data, and the libraries
    /home/ana/ml/.venv/bin/python figures.py     # rewrite every figure in the lessons
    /home/ana/ml/.venv/bin/python figures.py NAME ...   # only these
    /home/ana/ml/.venv/bin/python figures.py --list     # the names, and their lessons

It runs as root, with the lab's Python because that is where the libraries are,
and reads the data from ML_DATA, /home/ana/ml/data unless told otherwise.

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

Only palette tokens are used, so each drawing turns over with the theme like
the page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel. The drawing helpers are data-cleaning's,
which were the statistics course's, copied.
"""
import glob
import json
import math
import os
import re
import sys

import numpy as np
import pandas as pd

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.environ.get('ML_DATA', '/home/ana/ml/data')
SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def data(name, **kw):
    return pd.read_csv(os.path.join(DATA, name), **kw)


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


def apply(path, only=()):
    lang = 'pt' if path.endswith('.pt.md') else 'en'
    text = open(path, encoding='utf-8').read()

    def swap_fence(m):
        found = re.search(r'data-fig=\\"([a-z0-9-]+)\\"', m.group(1))
        if not found or found.group(1) not in FIGURES or (only and found.group(1) not in only):
            return m.group(0)
        return render(found.group(1), lang)

    new = FENCE.sub(swap_fence, text)
    new = PLACEHOLDER.sub(lambda m: render(m.group(1), lang), new)
    if new != text:
        open(path, 'w', encoding='utf-8').write(new)
        return True
    return False



def T(lang, en, pt):
    return en if lang == 'en' else pt


# ------------------------------------------------------------------ lesson 1

@figure('l01-four-outcomes', 1)
def l01_four_outcomes(lang):
    fig = Fig('l01-four-outcomes', 620, 285, T(lang,
        'A two by two grid. Columns: what the subscriber did, cancelled or stayed. Rows: what the '
        'model said, cancel or stay. The four cells are true positive, false positive, false '
        'negative and true negative, each with what it means for the R$ 40 credit.',
        'Uma grade dois por dois. Colunas: o que o assinante fez, cancelou ou ficou. Linhas: o que '
        'o modelo disse, cancela ou fica. As quatro células são verdadeiro positivo, falso positivo, '
        'falso negativo e verdadeiro negativo, cada uma com o que significa para o crédito de R$ 40.'))
    x0, y0, w, h = 190, 70, 200, 100
    fig.text(x0 + w, 22, T(lang, 'what the subscriber did', 'o que o assinante fez'), size=11,
             weight='600')
    fig.text(x0 + w / 2, 50, T(lang, 'cancelled', 'cancelou'), size=11)
    fig.text(x0 + 1.5 * w, 50, T(lang, 'stayed', 'ficou'), size=11)
    fig.text(20, 40, T(lang, 'what the model said', 'o que o modelo disse'), size=11,
             anchor='start', weight='600')
    fig.text(x0 - 14, y0 + h / 2, T(lang, 'cancel: credit sent', 'cancela: crédito enviado'),
             size=10.5, anchor='end')
    fig.text(x0 - 14, y0 + 1.5 * h, T(lang, 'stay: no credit', 'fica: sem crédito'),
             size=10.5, anchor='end')
    cells = [
        (0, 0, T(lang, 'true positive', 'verdadeiro positivo'),
         T(lang, 'some are kept: +R$ 104', 'alguns ficam: +R$ 104'), '--phosphor'),
        (1, 0, T(lang, 'false positive', 'falso positivo'),
         T(lang, 'credit wasted: −R$ 40', 'crédito perdido: −R$ 40'), '--amber'),
        (0, 1, T(lang, 'false negative', 'falso negativo'),
         T(lang, 'left, never asked', 'saiu sem ser chamado'), '--amber'),
        (1, 1, T(lang, 'true negative', 'verdadeiro negativo'),
         T(lang, 'nothing happens', 'nada acontece'), '--phosphor'),
    ]
    for c, r, title, sub, stroke in cells:
        x, y = x0 + c * w, y0 + r * h
        fig.rect(x + 4, y + 4, w - 8, h - 8, stroke=stroke, fill='--panel', width=1.6)
        fig.text(x + w / 2, y + h / 2 - 10, title, size=12, weight='600')
        fig.text(x + w / 2, y + h / 2 + 12, sub, size=10.5, fill='--paper-dim')
    cap = T(lang, 'Two ways to be right and two ways to be wrong, and the two wrong ones do not '
                  'cost the same.',
            'Dois jeitos de acertar e dois de errar, e os dois erros não custam o mesmo.')
    return fig, cap


CAT = ['city', 'payment', 'plan', 'box', 'channel']
NUM = ['age', 'app_user', 'tenure_months', 'price_month', 'orders_90d', 'skips_90d', 'late_90d',
       'complaints_90d', 'support_calls_90d', 'rating_90d', 'days_since_login']


def churn_frame():
    churn = data('churn.csv', parse_dates=['snapshot'])
    for c in CAT:
        churn[c] = churn[c].astype('category')
    return churn


def first_model_scores():
    """Lesson 2's first_model.py, fitted again here so a figure needs no file it wrote."""
    from sklearn.ensemble import HistGradientBoostingClassifier
    churn = churn_frame()
    test = churn['snapshot'] >= '2025-07-01'
    model = HistGradientBoostingClassifier(categorical_features='from_dtype', random_state=0)
    model.fit(churn.loc[~test, NUM + CAT], churn.loc[~test, 'churned'])
    out = churn[test].copy()
    out['chance'] = model.predict_proba(out[NUM + CAT])[:, 1]
    return out.reset_index(drop=True)


# ------------------------------------------------------------------ lesson 2

def money(lang, v):
    s = f'{abs(v):,.0f}'
    if lang == 'pt':
        s = s.replace(',', '.')
    return ('−' if v < 0 else '') + 'R$ ' + s


@figure('l02-ceiling', 2)
def l02_ceiling(lang):
    test = data('churn.csv', parse_dates=['snapshot'])
    test = test[test['snapshot'] >= '2025-07-01']
    leavers = int(test['churned'].sum())
    ceiling = leavers * (0.3 * 480 - 40)
    model = 21672      # first_model.py, as captured beside this figure
    rule = -576        # rule.py
    bars = [(T(lang, 'send nobody', 'não mandar a ninguém'), 0),
            (T(lang, 'the best rule', 'a melhor regra'), rule),
            (T(lang, 'the first model', 'o primeiro modelo'), model),
            (T(lang, f'perfect: all {leavers:,} leavers', f'perfeito: os {leavers:,} que saíram'.replace(',', '.')), ceiling)]
    fig = Fig('l02-ceiling', 640, 200, T(lang,
        f'Horizontal bars of net value over the six test months: sending nobody R$ 0, the best rule '
        f'{money(lang, rule)}, the first model {money(lang, model)}, and a perfect model '
        f'{money(lang, ceiling)}.',
        f'Barras horizontais do valor líquido nos seis meses de teste: não mandar a ninguém R$ 0, a '
        f'melhor regra {money(lang, rule)}, o primeiro modelo {money(lang, model)} e um modelo '
        f'perfeito {money(lang, ceiling)}.'))
    x0, x1 = 230, 560
    sx = lambda v: x0 + (v / ceiling) * (x1 - x0)
    fig.line(sx(0), 22, sx(0), 182, stroke='--paper-dim', width=1)
    for i, (name, v) in enumerate(bars):
        y = 30 + 40 * i
        fig.text(x0 - 12, y + 11, name, size=11, anchor='end')
        a, b = sorted([sx(0), sx(v)])
        if b - a >= 1:
            fig.rect(a, y, b - a, 22, stroke='--phosphor' if v > 0 else '--amber',
                     fill='--phosphor-dim' if i == 2 else ('--scan' if v <= 0 else '--panel'), rx=2)
        fig.text(max(b, sx(0)) + 8, y + 11, money(lang, v), size=10.5, anchor='start', mono=True)
    cap = T(lang, f'The model is worth about {model / ceiling:.0%} of what a perfect one would be, '
                  'and far more than anything simpler.',
            f'O modelo vale cerca de {model / ceiling:.0%} do que valeria um perfeito, e muito mais '
            'do que qualquer coisa mais simples.'.replace('.0%', '%'))
    return fig, cap


@figure('l02-bootstrap', 2)
def l02_bootstrap(lang):
    test = first_model_scores()
    model = test['chance'] >= 40 / (0.3 * 480)
    rule = (test['skips_90d'] >= 3) & (test['complaints_90d'] >= 1)
    y = (test['churned'] == 1).to_numpy()
    m, r = model.to_numpy(), rule.to_numpy()
    def nv(idx, send):
        return 0.3 * 480 * (y[idx] & send[idx]).sum() - 40 * send[idx].sum()
    rng = np.random.default_rng(0)
    rows = test.groupby('customer_id').indices
    people = list(rows)
    gaps = []
    for _ in range(1000):
        drawn = rng.choice(len(people), len(people))
        idx = np.concatenate([rows[people[i]] for i in drawn])
        gaps.append(nv(idx, m) - nv(idx, r))
    gaps = np.array(gaps)
    low, high = np.percentile(gaps, [2.5, 97.5])
    fig = Fig('l02-bootstrap', 640, 250, T(lang,
        'A histogram of 1,000 bootstrap differences between the model and the rule, all of them '
        f'positive, centred near {money(lang, float(np.median(gaps)))}, with the zero line well to '
        'the left of every bar.',
        'Um histograma de 1.000 diferenças bootstrap entre o modelo e a regra, todas positivas, '
        f'centradas perto de {money(lang, float(np.median(gaps)))}, com a linha do zero bem à '
        'esquerda de todas as barras.'))
    edges = list(range(0, 32001, 1000))
    counts = histogram(gaps, edges)
    p = Plot(fig, 60, 30, 610, 200, 0, 32000, 0, max(counts) * 1.15)
    step = 50 if max(counts) > 120 else 25
    p.yaxis(list(range(0, int(max(counts) * 1.15) + 1, step)), label=T(lang, 'resamples', 'reamostras'))
    p.bars(edges, counts, highlight=lambda i: not (low <= edges[i] < high + 1000))
    p.xaxis([0, 8000, 16000, 24000, 32000], fmt=lambda v: money(lang, v),
            label=T(lang, 'model minus rule, in reais', 'modelo menos regra, em reais'))
    p.vline(0)
    fig.text(p.sx(0) + 8, 110, T(lang, 'no difference', 'sem diferença'), size=10, anchor='start',
             fill='--amber')
    cap = T(lang, 'A thousand resampled test sets. The gap moves by thousands of reais from one to '
                  'the next, and never reaches zero. The bars in the other colour are the 5% outside the '
                  'interval.',
            'Mil conjuntos de teste reamostrados. A diferença muda milhares de reais de um para '
            'outro, e nunca chega a zero. As barras da outra cor são os 5% fora do intervalo.')
    return fig, cap


# ------------------------------------------------------------------ lesson 3

MONTHS_EN = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
MONTHS_PT = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']


@figure('l03-three-sets', 3)
def l03_three_sets(lang):
    churn = data('churn.csv', parse_dates=['snapshot'])
    counts = churn.groupby('snapshot').size()
    fig = Fig('l03-three-sets', 680, 190, T(lang,
        'Eighteen monthly snapshots from July 2024 to December 2025, drawn as bars as tall as the '
        'number of subscribers. The first nine are training, the next three validation, and the last '
        'six, from July 2025, the test.',
        'Dezoito retratos mensais de julho de 2024 a dezembro de 2025, desenhados como barras da '
        'altura do número de assinantes. Os nove primeiros são treino, os três seguintes validação, '
        'e os seis últimos, a partir de julho de 2025, o teste.'))
    M = MONTHS_EN if lang == 'en' else MONTHS_PT
    x0, w, base, top = 40, 33, 130, 40
    mx = counts.max()
    for i, (month, n) in enumerate(counts.items()):
        kind = 0 if i < 9 else (1 if i < 12 else 2)
        h = (base - top) * n / mx
        x = x0 + i * w
        fig.rect(x + 3, base - h, w - 6, h, stroke=['--phosphor', '--amber', '--paper-dim'][kind],
                 fill=['--phosphor-dim', '--scan', '--panel'][kind], rx=2)
        fig.text(x + w / 2, base + 12, M[month.month - 1], size=9.5, fill='--paper-dim')
    fig.text(x0 + 4.5 * w, base + 30, '2024 – 2025', size=9.5, mono=True)
    for a, b, label, col in [(0, 9, T(lang, 'training', 'treino'), '--phosphor'),
                             (9, 12, T(lang, 'validation', 'validação'), '--amber'),
                             (12, 18, T(lang, 'test: touched once', 'teste: tocado uma vez'), '--paper')]:
        fig.line(x0 + a * w + 3, 26, x0 + b * w - 3, 26, stroke=col, width=2)
        fig.text(x0 + (a + b) * w / 2, 16, label, size=11, weight='600', fill=col if col != '--paper' else '--paper')
    fig.text(x0 + 15 * w, base + 30, T(lang, 'by_time cuts on 1 July 2025', 'o by_time corta em 1º de julho de 2025'), size=9.5,
             fill='--paper-dim')
    cap = T(lang, 'Cut by date. The test months are later than everything the model may learn from.',
            'Corte por data. Os meses de teste vêm depois de tudo de que o modelo pode aprender.')
    return fig, cap


@figure('l03-folds', 3)
def l03_folds(lang):
    fig = Fig('l03-folds', 600, 230, T(lang,
        'Five rows, one per fit. Each row is the training data cut into five folds; in each row a '
        'different fold is scored and the other four are fitted on.',
        'Cinco linhas, uma por ajuste. Cada linha são os dados de treino cortados em cinco partes; em '
        'cada linha uma parte diferente é medida e as outras quatro servem para ajustar.'))
    x0, w, y0, h = 120, 80, 40, 30
    fig.text(x0 + 2.5 * w, 18, T(lang, 'the training rows, in five folds', 'as linhas de treino, em cinco partes'),
             size=11, weight='600')
    for r in range(5):
        y = y0 + r * (h + 8)
        fig.text(x0 - 14, y + h / 2, T(lang, f'fit {r + 1}', f'ajuste {r + 1}'), size=10.5, anchor='end')
        for c in range(5):
            scored = c == r
            fig.rect(x0 + c * w + 2, y, w - 4, h, stroke='--amber' if scored else '--phosphor',
                     fill='--scan' if scored else '--phosphor-dim', rx=3)
            if scored:
                fig.text(x0 + c * w + w / 2, y + h / 2, T(lang, 'scored', 'medida'), size=10, fill='--paper')
        fig.text(x0 + 5 * w + 14, y + h / 2, T(lang, f'score {r + 1}', f'nota {r + 1}'), size=10.5,
                 anchor='start', fill='--paper-dim')
    cap = T(lang, 'Every row is scored once and fitted on four times. Five scores come out, and their '
                  'spread is the luck of the cut.',
            'Toda linha é medida uma vez e usada no ajuste quatro vezes. Saem cinco notas, e a '
            'dispersão delas é a sorte do corte.')
    return fig, cap


@figure('l03-gap', 3)
def l03_gap(lang):
    fig = Fig('l03-gap', 640, 260, T(lang,
        'Six snapshots, January to June, each followed by a three-month horizon bar. A vertical line '
        'marks 1 July, the moment of fitting. The horizons of January to April end by then; those of '
        'May and June run past it, so their labels are not yet known.',
        'Seis retratos, de janeiro a junho, cada um seguido de uma barra de horizonte de três meses. '
        'Uma linha vertical marca 1º de julho, o momento do ajuste. Os horizontes de janeiro a abril '
        'terminam até ali; os de maio e junho passam dela, então os rótulos deles ainda não existem.'))
    M = MONTHS_EN if lang == 'en' else MONTHS_PT
    x0, w, y0 = 90, 52, 50
    for m in range(10):
        fig.text(x0 + m * w + w / 2, 30, M[m], size=9.5, fill='--paper-dim')
        fig.line(x0 + m * w, 38, x0 + m * w, 44, stroke='--wire', width=1)
    for i in range(6):
        y = y0 + i * 28
        known = i < 4
        fig.text(x0 - 10, y + 9, T(lang, f'{M[i]} snapshot', f'retrato de {M[i]}'), size=10, anchor='end')
        fig.circle(x0 + i * w + 6, y + 9, 4, fill='--paper')
        fig.rect(x0 + i * w + 12, y + 2, 3 * w - 14, 14, stroke='--phosphor' if known else '--amber',
                 fill='--phosphor-dim' if known else '--scan', rx=2)
    xt = x0 + 6 * w
    for i in range(7):                       # the line, in the gaps between the bars
        top = 40 if i == 0 else y0 + (i - 1) * 28 + 18
        bottom = y0 + i * 28 if i < 6 else 222
        fig.line(xt, top, xt, bottom, stroke='--paper', width=2)
    fig.text(xt + 6, 236, T(lang, '1 July: fit the model', '1º de julho: ajustar o modelo'), size=10.5,
             anchor='start', weight='600')
    fig.text(x0 + 2 * w, 236, T(lang, 'answer known: may train', 'resposta conhecida: pode treinar'),
             size=10, fill='--phosphor')
    fig.text(x0 + 8.4 * w, 140, T(lang, 'answer still open:', 'resposta em aberto:'), size=10,
             fill='--amber', anchor='middle')
    fig.text(x0 + 8.4 * w, 156, T(lang, 'leave it out', 'deixe de fora'), size=10, fill='--amber',
             anchor='middle')
    cap = T(lang, 'With a three-month horizon, the last two snapshots before the fit have no answer yet. '
                  'The gap is what keeps them out of training.',
            'Com horizonte de três meses, os dois últimos retratos antes do ajuste ainda não têm '
            'resposta. A lacuna é o que os mantém fora do treino.')
    return fig, cap


# ------------------------------------------------------------------ lesson 4

@figure('l04-timeline', 4)
def l04_timeline(lang):
    fig = Fig('l04-timeline', 660, 210, T(lang,
        'A timeline for C00001, the first row of churn.csv. The snapshot and the credit decision are on '
        '1 July 2024; the cancellation comes on 14 July 2024; the export is on 1 January 2026. A '
        'bracket from the cancellation to the export is what days_since_last_order counted.',
        'Uma linha do tempo para o C00001, a primeira linha do churn.csv. O retrato e a decisão do crédito são '
        'em 1º de julho de 2024; o cancelamento vem em 14 de julho de 2024; a exportação é em 1º de '
        'janeiro de 2026. Um colchete do cancelamento à exportação é o que o days_since_last_order '
        'contou.'))
    y = 100
    xs, xc, xe = 90, 190, 590
    fig.line(40, y, 620, y, stroke='--paper-dim', width=1.5, arrow=True)
    for x, top, col in [(xs, T(lang, '1 Jul 2024', '1º jul 2024'), '--phosphor'),
                        (xc, T(lang, '14 Jul 2024', '14 jul 2024'), '--amber'),
                        (xe, T(lang, '1 Jan 2026', '1º jan 2026'), '--paper')]:
        fig.circle(x, y, 6, fill=col)
        fig.text(x, y - 22, top, size=10.5, mono=True)
    fig.text(xs - 14, y + 26, T(lang, 'snapshot: the credit is decided', 'retrato: o crédito é decidido'), size=10.5,
             anchor='start', fill='--phosphor')
    fig.text(xc + 30, y - 52, T(lang, 'cancels: cancel_reason is written', 'cancela: cancel_reason é escrito'),
             size=10.5, anchor='start', fill='--amber')
    fig.line(xc, y - 10, xc + 26, y - 46, stroke='--amber', width=1)
    fig.text(xe, y + 26, T(lang, 'the file is exported', 'o arquivo é exportado'), size=10.5)
    fig.path(f'M{xc} {y + 52} L{xc} {y + 60} L{xe} {y + 60} L{xe} {y + 52}', stroke='--amber', width=1.4)
    fig.text((xc + xe) / 2, y + 78, T(lang, 'what days_since_last_order counted: 536 days',
                                      'o que o days_since_last_order contou: 536 dias'), size=10.5,
             fill='--amber')
    cap = T(lang, 'Everything to the right of the snapshot was unknown on the day the credit was '
                  'decided, and both leaking columns live there.',
            'Tudo à direita do retrato era desconhecido no dia em que o crédito foi decidido, e as '
            'duas colunas que vazam moram ali.')
    return fig, cap


# ------------------------------------------------------------------ lesson 5

def deliveries_frame():
    d = data('deliveries.csv', parse_dates=['date'])
    d['rush'] = d['hour'].isin([11, 12, 17, 18, 19]).astype(int)
    return d


@figure('l05-line', 5)
def l05_line(lang):
    from sklearn.linear_model import LinearRegression
    d = deliveries_frame()
    train, test = d[d['date'] < '2025-10-01'], d[d['date'] >= '2025-10-01']
    feats = ['distance_km', 'items', 'rush', 'rain', 'driver_months']
    line = LinearRegression().fit(train[feats], train['minutes'])
    fixed = dict(items=17, rush=0, rain=0, driver_months=30)
    def at(km):
        return line.intercept_ + line.coef_[0] * km + sum(
            line.coef_[i] * fixed[f] for i, f in enumerate(feats) if f in fixed)
    fig = Fig('l05-line', 640, 300, T(lang,
        f'A scatter of the {len(test):,} test deliveries, minutes against kilometres, with the fitted '
        'line for a dry delivery of 17 items outside rush hour. Most points sit within a band around '
        'it; a few lie far above, the deliveries that went wrong.',
        f'Uma dispersão das {len(test):,} entregas de teste, minutos contra quilômetros, com a reta '
        'ajustada para uma entrega sem chuva, de 17 itens, fora do horário de pico. A maioria dos '
        'pontos fica numa faixa em volta dela; alguns ficam muito acima, as entregas que deram '
        'errado.'.replace(',', '.', 1)))
    p = Plot(fig, 60, 30, 610, 250, 0, 30, 0, 200)
    p.yaxis([0, 50, 100, 150, 200], label=T(lang, 'minutes', 'minutos'))
    p.xaxis([0, 5, 10, 15, 20, 25, 30], label=T(lang, 'distance, km', 'distância, km'))
    for km, mins in zip(test['distance_km'], test['minutes']):
        if km <= 30 and mins <= 200:
            fig.circle(p.sx(km), p.sy(mins), 1.6, fill='--paper-dim')
    p.curve(at, 0, 30, stroke='--amber', width=2.4)
    fig.text(p.sx(24), p.sy(at(24)) - 16, T(lang, 'the line', 'a reta'), size=11, fill='--amber',
             weight='600')
    cap = T(lang, 'Each kilometre adds about two and a half minutes to a fixed part of about 22 '
                  '(with 17 items and 30 months of driving). The points far above the line are the '
                  'deliveries nothing in the columns predicts.',
            'Cada quilômetro soma uns dois minutos e meio a uma parte fixa de uns 22 (com 17 itens e '
            '30 meses de direção). Os pontos muito acima da reta são as entregas que nada nas colunas '
            'prevê.')
    return fig, cap


@figure('l05-lasso-path', 5)
def l05_lasso_path(lang):
    from sklearn.linear_model import Lasso
    from sklearn.preprocessing import StandardScaler
    d = deliveries_frame()
    real = ['distance_km', 'items', 'rush', 'rain', 'driver_months']
    rng = np.random.default_rng(0)
    for i in range(40):
        d[f'noise_{i}'] = rng.normal(size=len(d))
    feats = real + [f'noise_{i}' for i in range(40)]
    train = d[d['date'] < '2025-10-01'].sample(80, random_state=0)
    X = StandardScaler().fit_transform(train[feats])
    alphas = np.logspace(-2, 1.2, 60)
    paths = np.array([Lasso(alpha=a, max_iter=50000).fit(X, train['minutes']).coef_ for a in alphas])
    fig = Fig('l05-lasso-path', 640, 320, T(lang,
        'Lasso weights against the penalty alpha, on a logarithmic axis. Forty noise weights, in a '
        'faint colour, start spread around zero and are flattened early; the weights of distance, '
        'rush, rain and items stay large much longer.',
        'Pesos do lasso contra a penalidade alpha, num eixo logarítmico. Quarenta pesos de ruído, numa '
        'cor apagada, começam espalhados em volta do zero e são achatados cedo; os pesos de '
        'distância, pico, chuva e itens continuam grandes por muito mais tempo.'))
    lo, hi = float(np.floor(paths.min())), float(np.ceil(paths.max()))
    p = Plot(fig, 60, 30, 520, 270, -2, 1.2, lo, hi)
    step = 5 if hi - lo > 20 else 2
    p.yaxis([t for t in range(int(lo) - int(lo) % step, int(hi) + 1, step) if t > lo], label=T(lang, 'weight, minutes', 'peso, minutos'))
    p.xaxis([-2, -1, 0, 1], fmt=lambda v: {-2: '0.01', -1: '0.1', 0: '1', 1: '10'}[v].replace('.', ',' if lang == 'pt' else '.'),
            label=T(lang, 'alpha, the strength of the penalty', 'alpha, a força da penalidade'))
    xs = np.log10(alphas)
    for j in range(len(feats) - 1, -1, -1):
        dd = 'M' + ' L'.join(f'{p.sx(x):.1f} {p.sy(v):.1f}' for x, v in zip(xs, paths[:, j]))
        fig.path(dd, stroke='--phosphor' if j < 5 else '--wire', width=2 if j < 5 else 1)
    names = {'distance_km': T(lang, 'distance', 'distância'), 'items': T(lang, 'items', 'itens'),
             'rush': T(lang, 'rush', 'pico'), 'rain': T(lang, 'rain', 'chuva'),
             'driver_months': T(lang, 'experience', 'experiência')}
    used = []
    for j, f in enumerate(real):
        y = p.sy(paths[0, j])
        while any(abs(y - u) < 13 for u in used):
            y += 13
        used.append(y)
        fig.text(p.x1 + 8, y, names[f], size=10, anchor='start', fill='--phosphor')
    cap = T(lang, 'Read from left to right: as the penalty grows, the noise weights hit zero first and '
                  'the real columns last.',
            'Leia da esquerda para a direita: à medida que a penalidade cresce, os pesos de ruído chegam '
            'a zero primeiro e as colunas reais por último.')
    return fig, cap


@figure('l05-sigmoid', 5)
def l05_sigmoid(lang):
    fig = Fig('l05-sigmoid', 600, 260, T(lang,
        'The logistic curve: chance on the vertical axis from 0 to 1, the weighted sum on the '
        'horizontal axis from minus 6 to 6. It is flat near 0 on the left, rises steeply through 0.5 '
        'at a sum of zero, and flattens near 1 on the right.',
        'A curva logística: chance no eixo vertical de 0 a 1, a soma ponderada no eixo horizontal de '
        'menos 6 a 6. Ela é plana perto de 0 à esquerda, sobe rápido passando por 0,5 na soma zero, e '
        'se achata perto de 1 à direita.'))
    p = Plot(fig, 60, 30, 560, 210, -6, 6, 0, 1)
    dec = (lambda v: f'{v:.2f}'.replace('.', ',')) if lang == 'pt' else (lambda v: f'{v:.2f}')
    p.yaxis([0, 0.25, 0.5, 0.75, 1], fmt=dec, label=T(lang, 'chance of leaving', 'chance de sair'))
    p.xaxis([-6, -4, -2, 0, 2, 4, 6], fmt=lambda v: str(v).replace('-', '−'),
            label=T(lang, 'intercept + the weighted columns', 'intercepto + as colunas ponderadas'))
    p.curve(lambda x: 1 / (1 + math.exp(-x)), -6, 6, stroke='--phosphor', width=2.4)
    p.vline(0, stroke='--amber')
    fig.text(p.sx(0) + 8, p.sy(0.5) + 14, T(lang, 'sum 0: chance 0.5', 'soma 0: chance 0,5'), size=10,
             anchor='start', fill='--amber')
    cap = T(lang, 'The same weighted sum as a line, bent so that it never leaves the range a '
                  'probability lives in.',
            'A mesma soma ponderada de uma reta, dobrada para nunca sair da faixa em que uma '
            'probabilidade vive.')
    return fig, cap


# ------------------------------------------------------------------ lesson 6

def moons():
    from sklearn.datasets import make_moons
    from sklearn.model_selection import train_test_split
    X, y = make_moons(n_samples=600, noise=0.25, random_state=0)
    return train_test_split(X, y, random_state=0)


def contour_paths(score, level, xlim, ylim, p, n=160):
    """The level line of score(x, y) as SVG path data, through matplotlib's contour."""
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    xs, ys = np.linspace(*xlim, n), np.linspace(*ylim, n)
    gx, gy = np.meshgrid(xs, ys)
    z = score(np.c_[gx.ravel(), gy.ravel()]).reshape(gx.shape)
    fig = plt.figure()
    cs = plt.contour(gx, gy, z, levels=[level])
    out = []
    for path in cs.allsegs[0]:
        if len(path) > 2:
            out.append('M' + ' L'.join(f'{p.sx(a):.1f} {p.sy(b):.1f}' for a, b in path))
    plt.close(fig)
    return out


def moon_panel(fig, p, X, y, paths, label):
    fig.rect(p.x0, p.y0, p.x1 - p.x0, p.y1 - p.y0, stroke='--wire', fill='--panel', width=1, rx=0)
    for (a, b), c in zip(X, y):
        if p.xmin <= a <= p.xmax and p.ymin <= b <= p.ymax:
            fig.circle(p.sx(a), p.sy(b), 2, fill='--phosphor' if c else '--amber')
    for d in paths:
        fig.path(d, stroke='--paper', width=2)
    fig.text((p.x0 + p.x1) / 2, p.y0 - 10, label, size=11, weight='600')


@figure('l06-svm', 6)
def l06_svm(lang):
    from sklearn.svm import SVC
    X_train, X_test, y_train, y_test = moons()
    svm = SVC(kernel='rbf', C=1).fit(X_train, y_train)
    fig = Fig('l06-svm', 600, 330, T(lang,
        'Two interlocking crescents of training points in two colours, with the rbf support vector '
        'machine boundary curving between them and the support vectors circled; they all sit near '
        'the boundary.',
        'Duas meias-luas encaixadas de pontos de treino em duas cores, com a fronteira da máquina de '
        'vetores de suporte rbf curvando entre elas e os vetores de suporte circulados; todos ficam '
        'perto da fronteira.'))
    xl, yl = (-1.6, 2.6), (-1.1, 1.6)
    p = Plot(fig, 40, 30, 560, 290, *xl, *yl)
    fig.rect(p.x0, p.y0, p.x1 - p.x0, p.y1 - p.y0, stroke='--wire', fill='--panel', width=1, rx=0)
    for (a, b), c in zip(X_train, y_train):
        fig.circle(p.sx(a), p.sy(b), 2.2, fill='--phosphor' if c else '--amber')
    for i in svm.support_:
        a, b = X_train[i]
        if xl[0] <= a <= xl[1] and yl[0] <= b <= yl[1]:
            fig.circle(p.sx(a), p.sy(b), 5, fill=None, stroke='--paper', width=1)
    for d in contour_paths(svm.decision_function, 0, xl, yl, p):
        fig.path(d, stroke='--paper', width=2.2)
    fig.text(p.x0, 16, T(lang, f'{len(svm.support_)} support vectors circled; every other point could be removed',
                         f'{len(svm.support_)} vetores de suporte circulados; qualquer outro ponto poderia sair'),
             size=10.5, anchor='start', fill='--paper-dim')
    cap = T(lang, 'The boundary is decided by the circled points alone, the ones on the edge of the '
                  'margin or past it.',
            'A fronteira é decidida só pelos pontos circulados, os que estão na borda da margem ou '
            'além dela.')
    return fig, cap


@figure('l06-boundaries', 6)
def l06_boundaries(lang):
    from sklearn.linear_model import LogisticRegression
    from sklearn.naive_bayes import GaussianNB
    from sklearn.neighbors import KNeighborsClassifier
    from sklearn.svm import SVC
    X_train, X_test, y_train, y_test = moons()
    models = [(T(lang, 'logistic regression', 'regressão logística'), LogisticRegression()),
              (T(lang, '15 nearest neighbours', '15 vizinhos mais próximos'), KNeighborsClassifier(15)),
              (T(lang, 'Gaussian naive Bayes', 'naive Bayes gaussiano'), GaussianNB()),
              (T(lang, 'rbf support vector machine', 'máquina de vetores de suporte rbf'), SVC(kernel='rbf'))]
    fig = Fig('l06-boundaries', 660, 470, T(lang,
        'Four small panels of the same crescents, each with one model\'s boundary: a straight line for '
        'logistic regression, a wiggly curve for nearest neighbours, a nearly straight line for '
        'Gaussian naive Bayes, and a smooth curve following the crescents for the support vector '
        'machine.',
        'Quatro painéis pequenos das mesmas meias-luas, cada um com a fronteira de um modelo: uma reta '
        'na regressão logística, uma curva ondulada nos vizinhos mais próximos, uma linha quase reta '
        'no naive Bayes gaussiano, e uma curva suave que segue as meias-luas na máquina de vetores de '
        'suporte.'))
    xl, yl = (-1.6, 2.6), (-1.1, 1.6)
    for i, (name, m) in enumerate(models):
        m.fit(X_train, y_train)
        acc = m.score(X_test, y_test)
        col, row = i % 2, i // 2
        x0, y0 = 20 + col * 325, 30 + row * 225
        p = Plot(fig, x0, y0, x0 + 300, y0 + 180, *xl, *yl)
        score = m.decision_function if hasattr(m, 'decision_function') else (lambda Z, m=m: m.predict_proba(Z)[:, 1] - 0.5)
        moon_panel(fig, p, X_train, y_train, contour_paths(score, 0, xl, yl, p),
                   f'{name}: {acc:.1%}'.replace('.', ',') if lang == 'pt' else f'{name}: {acc:.1%}')
    cap = T(lang, 'The same training points, four shapes of boundary. The percentages are right answers '
                  'on the test points.',
            'Os mesmos pontos de treino, quatro formas de fronteira. As porcentagens são acertos nos '
            'pontos de teste.')
    return fig, cap


# ------------------------------------------------------------------ lesson 7

@figure('l07-depth', 7)
def l07_depth(lang):
    from sklearn.tree import DecisionTreeClassifier
    churn = churn_frame()
    tr, te = churn[churn['snapshot'] < '2025-07-01'], churn[churn['snapshot'] >= '2025-07-01']
    cut = 40 / (0.3 * 480)
    def nv(rows, chance):
        send = chance >= cut
        return 0.3 * 480 * ((rows['churned'] == 1).to_numpy() & send).sum() - 40 * send.sum()
    depths = list(range(1, 21))
    a, b = [], []
    for d in depths:
        t = DecisionTreeClassifier(max_depth=d, random_state=0).fit(tr[NUM], tr['churned'])
        a.append(nv(tr, t.predict_proba(tr[NUM])[:, 1]) / 1000)
        b.append(nv(te, t.predict_proba(te[NUM])[:, 1]) / 1000)
    fig = Fig('l07-depth', 640, 300, T(lang,
        'Net value in thousands of reais against tree depth from 1 to 20. The training curve climbs '
        'steadily; the test curve rises to a peak at depth 7 and then falls below zero.',
        'Valor líquido em milhares de reais contra a profundidade da árvore, de 1 a 20. A curva de '
        'treino sobe sem parar; a de teste sobe até um pico na profundidade 7 e depois cai abaixo de '
        'zero.'))
    lo = min(min(b), 0)
    hi = max(a)
    p = Plot(fig, 70, 30, 560, 250, 1, 20, -40, 200)
    p.yaxis([-40, 0, 40, 80, 120, 160, 200], label=T(lang, 'net value, thousands of reais', 'valor líquido, milhares de reais'))
    p.xaxis([1, 5, 10, 15, 20], label=T(lang, 'max_depth', 'max_depth'))
    for vals, col, name in [(a, '--paper-dim', T(lang, 'training months', 'meses de treino')),
                            (b, '--phosphor', T(lang, 'test months', 'meses de teste'))]:
        d = 'M' + ' L'.join(f'{p.sx(x):.1f} {p.sy(max(min(v, 200), -40)):.1f}' for x, v in zip(depths, vals))
        fig.path(d, stroke=col, width=2.2)
        fig.text(p.x1 + 6, p.sy(max(min(vals[-1], 200), -40)), name, size=10, anchor='start', fill=col)
    best = int(np.argmax(b))
    fig.circle(p.sx(depths[best]), p.sy(b[best]), 4, fill='--amber')
    fig.text(p.sx(depths[best]), p.sy(b[best]) - 14, T(lang, f'peak: depth {depths[best]}', f'pico: profundidade {depths[best]}'),
             size=10, fill='--amber')
    cap = T(lang, 'Past depth 7 every extra level helps the training months and hurts the test months.',
            'Depois da profundidade 7, cada nível a mais ajuda os meses de treino e prejudica os de teste.')
    return fig, cap


@figure('l07-steps', 7)
def l07_steps(lang):
    from sklearn.linear_model import LinearRegression
    from sklearn.tree import DecisionTreeRegressor
    d = deliveries_frame()
    train = d[d['date'] < '2025-10-01']
    f_tree = ['distance_km', 'items', 'hour', 'rain', 'driver_months']
    f_line = ['distance_km', 'items', 'rush', 'rain', 'driver_months']
    tree = DecisionTreeRegressor(min_samples_leaf=100, random_state=0).fit(train[f_tree], train['minutes'])
    line = LinearRegression().fit(train[f_line], train['minutes'])
    km = np.linspace(0, 60, 241)
    base = pd.DataFrame({'distance_km': km, 'items': 17, 'hour': 15, 'rush': 0, 'rain': 0, 'driver_months': 30})
    yt, yl = tree.predict(base[f_tree]), line.predict(base[f_line])
    fig = Fig('l07-steps', 640, 300, T(lang,
        'Predicted minutes against distance from 0 to 60 km, for a dry delivery of 17 items at 3 pm. '
        'The line rises steadily the whole way. The tree is a staircase that goes flat at about 16 km, '
        'where deliveries become rare, and stays flat past 29 km, the longest training delivery.',
        'Minutos previstos contra a distância de 0 a 60 km, para uma entrega sem chuva de 17 itens às '
        '15h. A reta sobe sem parar o caminho todo. A árvore é uma escada que fica plana perto dos 16 km, '
        'onde as entregas ficam raras, e continua plana além dos 29 km, a entrega de treino mais longa.'))
    p = Plot(fig, 60, 30, 560, 250, 0, 60, 0, 180)
    p.yaxis([0, 30, 60, 90, 120, 150, 180], label=T(lang, 'predicted minutes', 'minutos previstos'))
    p.xaxis([0, 10, 20, 30, 40, 50, 60], label=T(lang, 'distance, km', 'distância, km'))
    edge = train['distance_km'].max()
    x, w = p.sx(edge), p.sx(60) - p.sx(edge)
    fig.path(f'M{x:.1f} {p.y0:.1f} L{x + w:.1f} {p.y0:.1f} L{x + w:.1f} {p.y1:.1f} L{x:.1f} {p.y1:.1f} Z',
             stroke=None, fill='--scan', width=0)
    fig.line(x, p.y0, x, p.y1, stroke='--paper-dim', width=1, dash='4 3')
    fig.text((p.sx(edge) + p.sx(60)) / 2, p.y0 + 14, T(lang, 'beyond any training delivery', 'além de toda entrega de treino'),
             size=10, fill='--paper-dim')
    for ys, col in [(yl, '--paper'), (yt, '--phosphor')]:
        fig.path('M' + ' L'.join(f'{p.sx(x):.1f} {p.sy(y):.1f}' for x, y in zip(km, ys)), stroke=col, width=2.2)
    fig.text(p.x1 + 6, p.sy(yl[-1]), T(lang, 'the line', 'a reta'), size=10.5, anchor='start', fill='--paper')
    fig.text(p.x1 + 6, p.sy(yt[-1]), T(lang, 'the tree', 'a árvore'), size=10.5, anchor='start', fill='--phosphor')
    cap = T(lang, 'Inside the data the two roughly agree. Outside it, the tree stops learning anything '
                  'and repeats its last step.',
            'Dentro dos dados os dois quase concordam. Fora deles, a árvore para de aprender e repete o '
            'último degrau.')
    return fig, cap


def main():
    if '--list' in sys.argv:
        for name, (lesson, _) in FIGURES.items():
            print(f'{lesson:>3}  {name}')
        return
    only = [a for a in sys.argv[1:] if not a.startswith('-')]
    changed = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        changed += apply(path, only)
    print(f'{len(FIGURES)} figures known, {changed} file(s) rewritten')


if __name__ == '__main__':
    main()
