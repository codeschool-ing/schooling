#!/usr/bin/env python3
"""Every diagram in the statistics course, drawn from the numbers in sheet.py.

A histogram drawn by hand is a claim about data nobody can check. These are
computed: the bars, the curves and the points come from the same data the
prose quotes, so a figure cannot drift from the sentence beside it.

    python3 figures.py            # rewrite every figure in the lessons
    python3 figures.py --list     # the names, and the lesson each lives in

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

Only palette tokens are used — `--paper`, `--paper-dim`, `--wire`, `--phosphor`,
`--phosphor-dim`, `--amber`, `--panel`, `--scan` — so each drawing turns over
with the theme like the page around it. Text is never drawn in `--wire` or
`--phosphor-dim`, which do not reach AA on the light panel.

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


# ------------------------------------------------------------------ lesson 1

PAY = {'en': {'pix': 'pix', 'card': 'card', 'cash': 'cash'},
       'pt': {'pix': 'pix', 'card': 'cartão', 'cash': 'dinheiro'}}


@figure('l01-payment-bars', 1)
def l01_payment_bars(lang):
    pay = S.column('payment')
    counts = [(k, pay.count(k)) for k in ['pix', 'card', 'cash']]
    t = {'en': ('A bar chart of how the twelve orders were paid: pix 6, card 4, cash 2. The bars '
                'stand apart because the categories have no order and nothing lies between them.',
                'orders', 'how the order was paid',
                'Each bar is a count. The gaps say that nothing lies between two categories, and '
                'the order of the bars is a choice — here, largest first.'),
         'pt': ('Um gráfico de barras de como os doze pedidos foram pagos: pix 6, cartão 4, '
                'dinheiro 2. As barras ficam separadas porque as categorias não têm ordem e não '
                'há nada entre elas.',
                'pedidos', 'como o pedido foi pago',
                'Cada barra é uma contagem. Os espaços dizem que não há nada entre duas '
                'categorias, e a ordem das barras é uma escolha — aqui, da maior para a menor.')}[lang]
    f = Fig('l01-payment-bars', 520, 250, t[0])
    p = Plot(f, 90, 40, 480, 200, 0, 3, 0, 7)
    p.yaxis(range(0, 8), label=t[1])
    for i, (k, c) in enumerate(counts):
        x0, x1 = p.sx(i + 0.2), p.sx(i + 0.8)
        f.path(f'M{x0:.1f} {p.y1:.1f} L{x0:.1f} {p.sy(c):.1f} L{x1:.1f} {p.sy(c):.1f} '
               f'L{x1:.1f} {p.y1:.1f} Z', stroke='--phosphor', width=1, fill='--phosphor-dim')
        f.text((x0 + x1) / 2, p.sy(c) - 10, str(c), size=10, weight='600')
        f.text((x0 + x1) / 2, p.y1 + 14, PAY[lang][k], size=10)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    f.text((p.x0 + p.x1) / 2, p.y1 + 34, t[2], size=10, weight='600')
    return f, t[3]


@figure('l01-minutes-dots', 1)
def l01_minutes_dots(lang):
    xs = S.column('minutes')
    t = {'en': ('A dot plot of the twelve delivery times on one line from 25 to 65 minutes. Most '
                'sit between 27.5 and 44; two stand out to the right, at 52.5 and 61.',
                'delivery time, in minutes',
                'A numerical variable has a place on a line, so the distances mean something: 61 '
                'is as far from 52.5 as 36 is from 27.5.'),
         'pt': ('Um gráfico de pontos com os doze tempos de entrega numa reta de 25 a 65 minutos. '
                'A maioria fica entre 27,5 e 44; dois se destacam à direita, em 52,5 e 61.',
                'tempo de entrega, em minutos',
                'Uma variável numérica tem lugar numa reta, então as distâncias significam algo: '
                '61 está tão longe de 52,5 quanto 36 está de 27,5.')}[lang]
    f = Fig('l01-minutes-dots', 620, 150, t[0])
    p = Plot(f, 40, 30, 590, 95, 25, 65, 0, 1)
    p.xaxis(range(25, 66, 5), label=t[1])
    placed = []
    for x in sorted(xs):
        level = sum(1 for q in placed if abs(p.sx(q) - p.sx(x)) < 13)
        placed.append(x)
        f.circle(p.sx(x), p.y1 - 12 - 14 * level, 6, fill='--phosphor', stroke='--paper', width=0.8)
    return f, t[2]


# ------------------------------------------------------------------ lesson 2

@figure('l02-scales-ladder', 2)
def l02_scales_ladder(lang):
    t = {'en': dict(
        label='Four boxes stacked like a ladder. Nominal at the bottom allows equal or different. '
              'Ordinal adds greater or smaller. Interval adds differences. Ratio at the top adds '
              'ratios, because only it has a true zero. Each rung keeps everything below it.',
        rows=[('ratio', 'a true zero', '× ÷', 'weight, basket, minutes'),
              ('interval', 'equal steps', '+ −', '°C, calendar year'),
              ('ordinal', 'an order', '< >', 'rating 1 to 5, size S M L'),
              ('nominal', 'names only', '= ≠', 'payment, neighbourhood')],
        head=('scale', 'what it adds', 'allows', 'Horta’s example'),
        cap='Each rung keeps every operation of the rungs below it and adds one. A rating can be '
            'ordered but not subtracted; a temperature can be subtracted but not divided.'),
        'pt': dict(
        label='Quatro caixas empilhadas como uma escada. Nominal, embaixo, permite igual ou '
              'diferente. Ordinal acrescenta maior ou menor. Intervalar acrescenta diferenças. '
              'Razão, no topo, acrescenta razões, porque só ela tem um zero verdadeiro. Cada degrau '
              'mantém tudo o que está abaixo.',
        rows=[('razão', 'um zero verdadeiro', '× ÷', 'peso, cesta, minutos'),
              ('intervalar', 'passos iguais', '+ −', '°C, ano do calendário'),
              ('ordinal', 'uma ordem', '< >', 'nota de 1 a 5, tamanho P M G'),
              ('nominal', 'só nomes', '= ≠', 'pagamento, bairro')],
        head=('escala', 'o que acrescenta', 'permite', 'exemplo da Horta'),
        cap='Cada degrau mantém todas as operações dos degraus de baixo e acrescenta uma. Uma nota '
            'pode ser ordenada mas não subtraída; uma temperatura pode ser subtraída mas não '
            'dividida.')}[lang]
    f = Fig('l02-scales-ladder', 680, 260, t['label'])
    xs = [20, 150, 310, 400]
    for x, h in zip(xs, t['head']):
        f.text(x + 6, 22, h, size=10, anchor='start', weight='600', fill='--paper-dim')
    for i, (name, adds, ops, ex) in enumerate(t['rows']):
        y = 38 + i * 53
        indent = (3 - i) * 0
        f.rect(16, y, 648, 44, stroke='--phosphor' if i == 0 else '--wire', fill='--panel')
        f.text(xs[0] + 6, y + 22, name, size=12, anchor='start', weight='600')
        f.text(xs[1] + 6, y + 22, adds, size=10.5, anchor='start', fill='--paper-dim')
        f.text(xs[2] + 6, y + 22, ops, size=13, anchor='start', mono=True, fill='--phosphor')
        f.text(xs[3] + 6, y + 22, ex, size=10.5, anchor='start')
    return f, t['cap']


@figure('l02-temperature-scales', 2)
def l02_temperature_scales(lang):
    t = {'en': dict(
        label='Three number lines, one per temperature scale, each with its own zero. 13.5 and 27 '
              'degrees Celsius sit at the same physical temperatures on all three. On Celsius the '
              'second number is twice the first. On Fahrenheit, 56.3 and 80.6, it is 1.43 times. On '
              'Kelvin, 286.65 and 300.15, it is 1.05 times.',
        names=['Celsius', 'Fahrenheit', 'Kelvin'],
        ratio='ratio',
        cap='The same two afternoons on three scales. The difference keeps its meaning on each; '
            'the ratio depends on where somebody put the zero, and only kelvin’s zero is real.'),
        'pt': dict(
        label='Três retas numéricas, uma por escala de temperatura, cada uma com o seu zero. 13,5 e '
              '27 graus Celsius ficam nas mesmas temperaturas físicas nas três. Em Celsius o segundo '
              'número é o dobro do primeiro. Em Fahrenheit, 56,3 e 80,6, é 1,43 vez. Em Kelvin, '
              '286,65 e 300,15, é 1,05 vez.',
        names=['Celsius', 'Fahrenheit', 'Kelvin'],
        ratio='razão',
        cap='As mesmas duas tardes em três escalas. A diferença mantém o significado em todas; a '
            'razão depende de onde alguém pôs o zero, e só o zero do kelvin é real.')}[lang]
    f = Fig('l02-temperature-scales', 680, 250, t['label'])
    # all three drawn on one physical axis, in kelvin, from 0 K to 310 K
    p = Plot(f, 120, 0, 600, 1, 0, 310, 0, 1)
    rows = [(lambda k: k - 273.15, 'C'), (lambda k: (k - 273.15) * 9 / 5 + 32, 'F'),
            (lambda k: k, 'K')]
    a, b = 13.5 + 273.15, 27 + 273.15
    for i, (conv, unit) in enumerate(rows):
        y = 50 + i * 70
        f.text(20, y, t['names'][i], size=11, anchor='start', weight='600')
        f.line(p.sx(0), y, p.sx(310), y, stroke='--paper-dim')
        zero = {0: 273.15, 1: 273.15 - 32 * 5 / 9, 2: 0}[i]
        f.line(p.sx(zero), y - 7, p.sx(zero), y + 7, stroke='--paper', width=1.6)
        f.text(p.sx(zero), y + 18, '0', size=9.5, fill='--paper-dim')
        for k, col in ((a, '--phosphor'), (b, '--amber')):
            f.circle(p.sx(k), y, 5, fill=col)
        va, vb = conv(a), conv(b)
        d = 2 if i == 2 else 1
        f.text(p.sx(a) - 8, y - 14, num(lang, va, d), size=9.5, anchor='end', fill='--phosphor')
        f.text(p.sx(b) + 8, y - 14, num(lang, vb, d), size=9.5, anchor='start', fill='--amber')
        f.text(660, y, f'{t["ratio"]} {num(lang, vb / va, 2)}', size=10, anchor='end')
    return f, t['cap']


@figure('l02-ratings-bars', 2)
def l02_ratings_bars(lang):
    r = S.column('rating')
    counts = [r.count(k) for k in range(1, 6)]
    t = {'en': ('A bar chart of the twelve ratings, from 1 to 5 stars: one 1, one 2, two 3s, four 4s '
                'and four 5s. The median, 4, is a rating somebody gave. The mean, 3.75, sits between '
                'two bars.', 'orders', 'stars given',
                'median 4', 'mean 3.75',
                'The median is a value on the scale. The mean treats the step from 1 star to 2 as '
                'the same size as the step from 4 to 5, which nobody measured.'),
         'pt': ('Um gráfico de barras das doze notas, de 1 a 5 estrelas: um 1, um 2, dois 3, quatro '
                '4 e quatro 5. A mediana, 4, é uma nota que alguém deu. A média, 3,75, fica entre '
                'duas barras.', 'pedidos', 'estrelas dadas',
                'mediana 4', 'média 3,75',
                'A mediana é um valor da escala. A média trata o passo de 1 para 2 estrelas como do '
                'mesmo tamanho que o passo de 4 para 5, e ninguém mediu isso.')}[lang]
    f = Fig('l02-ratings-bars', 560, 260, t[0])
    p = Plot(f, 80, 50, 520, 205, 0.5, 5.5, 0, 5)
    p.yaxis(range(0, 6), label=t[1])
    for k, c in zip(range(1, 6), counts):
        x0, x1 = p.sx(k - 0.32), p.sx(k + 0.32)
        f.path(f'M{x0:.1f} {p.y1:.1f} L{x0:.1f} {p.sy(c):.1f} L{x1:.1f} {p.sy(c):.1f} '
               f'L{x1:.1f} {p.y1:.1f} Z', stroke='--phosphor', width=1,
               fill='--phosphor-dim')
        f.text((x0 + x1) / 2, p.y1 + 14, str(k), size=10)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    f.text((p.x0 + p.x1) / 2, p.y1 + 34, t[2], size=10, weight='600')
    p.vline(4, t[3], stroke='--paper', dash=None, top=36, anchor='start', dy=0)
    p.vline(S.mean(r), t[4], stroke='--amber', top=36, anchor='end')
    return f, t[5]


# ------------------------------------------------------------------ lesson 3

@figure('l03-balance', 3)
def l03_balance(lang):
    xs = S.column('minutes')
    m = S.mean(xs)
    left = sum(m - x for x in xs if x < m)
    right = sum(x - m for x in xs if x > m)
    t = {'en': dict(
        label=f'The twelve delivery times as dots on a line, resting on a fulcrum at the mean, '
              f'{num("en", m, 2)} minutes. The distances below the mean add up to '
              f'{num("en", left, 2)} and the distances above it add up to the same.',
        axis='delivery time, in minutes', mean=f'mean {num("en", m, 2)}',
        below=f'distances below: {num("en", left, 2)}', above=f'distances above: {num("en", right, 2)}',
        cap='The mean is the point where the line would balance. Two far values on the right are '
            'balanced by many near ones on the left.'),
        'pt': dict(
        label=f'Os doze tempos de entrega como pontos numa reta, apoiada num fulcro na média, '
              f'{num("pt", m, 2)} minutos. As distâncias abaixo da média somam '
              f'{num("pt", left, 2)} e as distâncias acima somam o mesmo.',
        axis='tempo de entrega, em minutos', mean=f'média {num("pt", m, 2)}',
        below=f'distâncias abaixo: {num("pt", left, 2)}', above=f'distâncias acima: {num("pt", right, 2)}',
        cap='A média é o ponto em que a reta se equilibraria. Dois valores distantes à direita são '
            'equilibrados por muitos próximos à esquerda.')}[lang]
    f = Fig('l03-balance', 640, 200, t['label'])
    p = Plot(f, 40, 30, 600, 120, 25, 65, 0, 1)
    p.xaxis(range(25, 66, 5), label=t['axis'])
    placed = []
    for x in sorted(xs):
        level = sum(1 for q in placed if abs(p.sx(q) - p.sx(x)) < 13)
        placed.append(x)
        f.circle(p.sx(x), p.y1 - 22 - 14 * level, 6, fill='--phosphor' if x < m else '--amber',
                 stroke='--paper', width=0.8)
    mx = p.sx(m)
    f.path(f'M{mx - 9:.1f} {p.y1:.1f} L{mx:.1f} {p.y1 - 13:.1f} L{mx + 9:.1f} {p.y1:.1f} Z',
           stroke='--paper', width=1, fill='--scan')
    f.text(mx, 22, t['mean'], size=10, weight='600')
    f.text(p.sx(26), 52, t['below'], size=9.5, anchor='start', fill='--phosphor')
    f.text(p.sx(64), 52, t['above'], size=9.5, anchor='end', fill='--amber')
    return f, t['cap']


@figure('l03-median', 3)
def l03_median(lang):
    xs = sorted(S.column('basket'))
    t = {'en': dict(
        label='The twelve baskets sorted from R$ 12.90 to R$ 212.60, as twelve boxes in a row. The '
              'sixth and seventh, R$ 62.30 and R$ 74.10, are highlighted; the median is halfway '
              'between them, R$ 68.20.',
        lo='six below', hi='six above', med='median = (62.30 + 74.10) ÷ 2 = 68.20',
        cap='With an even count there is no single middle value, so the median is halfway between '
            'the two in the middle.'),
        'pt': dict(
        label='As doze cestas ordenadas de R$ 12,90 a R$ 212,60, como doze caixas em fila. A sexta e '
              'a sétima, R$ 62,30 e R$ 74,10, estão destacadas; a mediana fica no meio delas, '
              'R$ 68,20.',
        lo='seis abaixo', hi='seis acima', med='mediana = (62,30 + 74,10) ÷ 2 = 68,20',
        cap='Com uma quantidade par não existe um único valor do meio, então a mediana fica no meio '
            'dos dois centrais.')}[lang]
    f = Fig('l03-median', 680, 150, t['label'])
    w = 52
    x0 = 340 - 6 * w
    for i, v in enumerate(xs):
        hot = i in (5, 6)
        f.rect(x0 + i * w + 2, 40, w - 4, 34, stroke='--amber' if hot else '--wire', fill='--panel')
        f.text(x0 + i * w + w / 2, 57, num(lang, v, 2), size=10, mono=True,
               fill='--amber' if hot else '--paper')
    f.line(340, 30, 340, 84, stroke='--amber', width=1.6, dash='4 3')
    f.text(x0 + 3 * w, 22, t['lo'], size=10, fill='--paper-dim')
    f.text(x0 + 9 * w, 22, t['hi'], size=10, fill='--paper-dim')
    f.text(340, 104, t['med'], size=11, weight='600')
    return f, t['cap']


@figure('l03-items-frequency', 3)
def l03_items_frequency(lang):
    freq = {1: 14, 2: 22, 3: 31, 4: 18, 5: 9, 6: 6}
    n = sum(freq.values())
    wm = sum(k * v for k, v in freq.items()) / n
    t = {'en': dict(
        label=f'A bar chart of 100 orders by number of items: 14 with one, 22 with two, 31 with '
              f'three, 18 with four, 9 with five and 6 with six. The weighted mean, '
              f'{num("en", wm, 2)}, sits just right of three. The plain average of the labels 1 to '
              f'6, 3.5, sits further right.',
        y='orders', x='items in the order', wm=f'weighted mean {num("en", wm, 2)}',
        naive='mean of the labels 3.5',
        cap='Each bar weighs as much as the orders in it. Averaging the labels 1 to 6 gives every '
            'bar the same weight, and lands at 3.5.'),
        'pt': dict(
        label=f'Um gráfico de barras de 100 pedidos por número de itens: 14 com um, 22 com dois, 31 '
              f'com três, 18 com quatro, 9 com cinco e 6 com seis. A média ponderada, '
              f'{num("pt", wm, 2)}, fica logo à direita do três. A média simples dos rótulos de 1 a '
              f'6, 3,5, fica mais à direita.',
        y='pedidos', x='itens no pedido', wm=f'média ponderada {num("pt", wm, 2)}',
        naive='média dos rótulos 3,5',
        cap='Cada barra pesa tanto quanto os pedidos que tem. Tirar a média dos rótulos de 1 a 6 dá o '
            'mesmo peso a toda barra, e cai em 3,5.')}[lang]
    f = Fig('l03-items-frequency', 600, 270, t['label'])
    p = Plot(f, 80, 60, 560, 215, 0.5, 6.5, 0, 35)
    p.yaxis(range(0, 36, 5), label=t['y'])
    for k, c in freq.items():
        x0, x1 = p.sx(k - 0.34), p.sx(k + 0.34)
        f.path(f'M{x0:.1f} {p.y1:.1f} L{x0:.1f} {p.sy(c):.1f} L{x1:.1f} {p.sy(c):.1f} '
               f'L{x1:.1f} {p.y1:.1f} Z', stroke='--phosphor', width=1, fill='--phosphor-dim')
        f.text((x0 + x1) / 2, p.y1 + 14, str(k), size=10)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    f.text((p.x0 + p.x1) / 2, p.y1 + 34, t['x'], size=10, weight='600')
    p.vline(wm, t['wm'], stroke='--amber', top=44, anchor='end')
    p.vline(3.5, t['naive'], stroke='--paper-dim', top=44, anchor='start', fill='--paper-dim')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 4

@figure('l04-salaries', 4)
def l04_salaries(lang):
    xs = S.SALARIES
    m, md = S.mean(xs), S.median(xs)
    t = {'en': dict(
        label='Horta’s nine monthly salaries on a line from R$ 0 to R$ 30,000. Eight are '
              'bunched between R$ 2,100 and R$ 3,400; the founder’s R$ 28,000 sits alone at the '
              'right. The median, R$ 2,400, is among the eight. The mean, R$ 5,338.89, is in the '
              'empty stretch where nobody is paid.',
        axis='monthly pay, in thousands of reais', med='median 2,400', mean='mean 5,338.89',
        founder='the founder', cap='Eight of the nine people earn less than the mean. The mean '
        'sits where nobody is, pulled out by one value.'),
        'pt': dict(
        label='Os nove salários mensais da Horta numa reta de R$ 0 a R$ 30.000. Oito se amontoam '
              'entre R$ 2.100 e R$ 3.400; os R$ 28.000 do fundador ficam sozinhos à direita. A '
              'mediana, R$ 2.400, está entre os oito. A média, R$ 5.338,89, está no trecho vazio '
              'onde ninguém recebe.',
        axis='salário mensal, em milhares de reais', med='mediana 2.400', mean='média 5.338,89',
        founder='o fundador', cap='Oito das nove pessoas ganham menos que a média. A média fica '
        'onde não há ninguém, puxada por um valor.')}[lang]
    f = Fig('l04-salaries', 660, 190, t['label'])
    p = Plot(f, 40, 50, 620, 130, 0, 30000, 0, 1)
    p.xaxis(range(0, 30001, 5000), fmt=lambda v: str(v // 1000), label=t['axis'])
    placed = []
    for x in sorted(xs):
        level = sum(1 for q in placed if abs(p.sx(q) - p.sx(x)) < 11)
        placed.append(x)
        f.circle(p.sx(x), p.y1 - 10 - 12 * level, 5, fill='--phosphor', stroke='--paper', width=0.8)
    p.vline(md, t['med'], stroke='--paper', dash=None, top=40, anchor='end', dy=-6)
    p.vline(m, t['mean'], stroke='--amber', top=40, anchor='start', dy=-6)
    f.text(p.sx(28000), p.y1 - 26, t['founder'], size=9.5, fill='--paper-dim')
    return f, t['cap']


@figure('l04-baskets-histogram', 4)
def l04_baskets_histogram(lang):
    xs = S.BASKETS
    m, md = S.mean(xs), S.median(xs)
    edges = list(range(0, 441, 20))
    counts = histogram(xs, edges)
    t = {'en': dict(
        label=f'A histogram of 400 baskets in bins of R$ 20, from R$ 0 to R$ 440. The tallest '
              f'bars are between R$ 40 and R$ 80, and a long thin tail runs right past R$ 400. '
              f'The median, R$ {num("en", md, 2)}, sits in the bulk; the mean, '
              f'R$ {num("en", m, 2)}, sits to its right.',
        y='orders', x='basket, in reais', med=f'median {num("en", md, 2)}',
        mean=f'mean {num("en", m, 2)}',
        cap='A long tail to the right pulls the mean towards it. The median stays with the bulk '
            'of the orders.'),
        'pt': dict(
        label=f'Um histograma de 400 cestas em faixas de R$ 20, de R$ 0 a R$ 440. As barras mais '
              f'altas ficam entre R$ 40 e R$ 80, e uma cauda longa e fina corre para a direita '
              f'além de R$ 400. A mediana, R$ {num("pt", md, 2)}, fica no grosso; a média, '
              f'R$ {num("pt", m, 2)}, fica à direita dela.',
        y='pedidos', x='cesta, em reais', med=f'mediana {num("pt", md, 2)}',
        mean=f'média {num("pt", m, 2)}',
        cap='Uma cauda longa à direita puxa a média para perto dela. A mediana fica com o grosso '
            'dos pedidos.')}[lang]
    f = Fig('l04-baskets-histogram', 660, 280, t['label'])
    top = (max(counts) // 10 + 1) * 10
    p = Plot(f, 70, 50, 630, 220, 0, 440, 0, top)
    p.yaxis(range(0, top + 1, 20), label=t['y'])
    p.bars(edges, counts)
    p.xaxis(range(0, 441, 40), label=t['x'])
    p.vline(md, t['med'], stroke='--paper', dash=None, top=40, anchor='end', dy=-4)
    p.vline(m, t['mean'], stroke='--amber', top=40, anchor='start', dy=-4)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 5

@figure('l05-two-couriers', 5)
def l05_two_couriers(lang):
    t = {'en': dict(
        label='Two rows of dots on the same scale, 20 to 50 minutes. Lia’s eight deliveries sit '
              'between 33 and 36. Davi’s eight are scattered from 22 to 44. A dashed line at 35 '
              'marks the mean, which is the same for both.',
        axis='delivery time, in minutes', mean='mean 35 for both',
        cap='The same mean, and two very different couriers to depend on. The mean alone cannot '
            'tell them apart.'),
        'pt': dict(
        label='Duas fileiras de pontos na mesma escala, de 20 a 50 minutos. As oito entregas da Lia '
              'ficam entre 33 e 36. As oito do Davi se espalham de 22 a 44. Uma linha tracejada em '
              '35 marca a média, que é a mesma para os dois.',
        axis='tempo de entrega, em minutos', mean='média 35 para os dois',
        cap='A mesma média, e dois entregadores bem diferentes para confiar. A média sozinha não '
            'consegue distingui-los.')}[lang]
    f = Fig('l05-two-couriers', 640, 210, t['label'])
    p = Plot(f, 90, 40, 610, 160, 20, 50, 0, 1)
    p.xaxis(range(20, 51, 5), label=t['axis'])
    for row, (name, xs) in enumerate((('Lia', S.LIA), ('Davi', S.DAVI))):
        y = 70 + row * 50
        f.text(20, y, name, size=11, anchor='start', weight='600')
        f.line(p.x0, y, p.x1, y, stroke='--wire', width=1)
        seen = {}
        for x in xs:
            k = seen.get(x, 0)
            seen[x] = k + 1
            f.circle(p.sx(x), y - 13 * k, 5.5, fill='--phosphor', stroke='--paper', width=0.8)
    p.vline(35, t['mean'], stroke='--amber', top=34)
    return f, t['cap']


@figure('l05-deviations', 5)
def l05_deviations(lang):
    xs = S.DAVI
    t = {'en': dict(
        label='Davi’s eight delivery times, each joined to the mean of 35 by a horizontal line. '
              'Below each line, its deviation and the square of it: minus 13 squared is 169, minus '
              '9 is 81, minus 4 is 16, 0 is 0, 3 is 9, 5 is 25, 9 is 81 and 9 is 81. The squares '
              'add up to 462.',
        axis='minutes', dev='deviation', sq='squared', total='sum of squares 462',
        cap='Each deviation is a distance from the mean. Squared, the negative ones stop '
            'cancelling the positive ones, and the far values weigh much more than the near ones.'),
        'pt': dict(
        label='Os oito tempos de entrega do Davi, cada um ligado à média de 35 por uma linha '
              'horizontal. Abaixo de cada linha, o desvio e o quadrado dele: menos 13 ao quadrado '
              'dá 169, menos 9 dá 81, menos 4 dá 16, 0 dá 0, 3 dá 9, 5 dá 25, 9 dá 81 e 9 dá 81. Os '
              'quadrados somam 462.',
        axis='minutos', dev='desvio', sq='ao quadrado', total='soma dos quadrados 462',
        cap='Cada desvio é uma distância até a média. Ao quadrado, os negativos param de anular os '
            'positivos, e os valores distantes pesam muito mais que os próximos.')}[lang]
    f = Fig('l05-deviations', 640, 330, t['label'])
    p = Plot(f, 130, 30, 610, 280, 20, 50, 0, 1)
    p.xaxis(range(20, 51, 5), label=t['axis'])
    f.line(p.sx(35), 24, p.sx(35), p.y1, stroke='--amber', width=1.4, dash='4 3')
    f.text(20, 18, t['dev'], size=9.5, anchor='start', fill='--paper-dim', weight='600')
    f.text(80, 18, t['sq'], size=9.5, anchor='start', fill='--paper-dim', weight='600')
    for i, x in enumerate(xs):
        y = 40 + i * 28
        d = x - 35
        col = '--phosphor' if d < 0 else '--amber'
        if d:
            f.line(p.sx(35), y, p.sx(x), y, stroke=col, width=2)
        f.circle(p.sx(x), y, 5, fill=col, stroke='--paper', width=0.8)
        f.text(40, y, f'{d:+d}'.replace('+0', '0').replace('-', '−'), size=10, anchor='end',
               mono=True, fill=col)
        f.text(115, y, str(d * d), size=10, anchor='end', mono=True)
    f.text(20, p.y1 + 31, t['total'], size=10, anchor='start', weight='600')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 6

def boxplot_h(f, p, xs, y, h=26, stroke='--phosphor', fill='--scan', dots=True):
    """A horizontal boxplot at height y on plot p, whiskers to 1.5 IQR, points beyond."""
    q1, md, q3 = S.quantile(xs, .25), S.median(xs), S.quantile(xs, .75)
    iqr = q3 - q1
    lo = min(x for x in xs if x >= q1 - 1.5 * iqr)
    hi = max(x for x in xs if x <= q3 + 1.5 * iqr)
    a, b = p.sx(q1), p.sx(q3)
    f.line(p.sx(lo), y, a, y, stroke='--paper-dim', width=1.4)
    f.line(b, y, p.sx(hi), y, stroke='--paper-dim', width=1.4)
    f.line(p.sx(lo), y - h / 3, p.sx(lo), y + h / 3, stroke='--paper-dim', width=1.4)
    f.line(p.sx(hi), y - h / 3, p.sx(hi), y + h / 3, stroke='--paper-dim', width=1.4)
    f.path(f'M{a:.1f} {y - h / 2:.1f} L{b:.1f} {y - h / 2:.1f} L{b:.1f} {y + h / 2:.1f} '
           f'L{a:.1f} {y + h / 2:.1f} Z', stroke=stroke, width=1.4, fill=fill)
    f.line(p.sx(md), y - h / 2, p.sx(md), y + h / 2, stroke='--amber', width=2.2)
    if dots:
        for x in xs:
            if x < lo or x > hi:
                f.circle(p.sx(x), y, 4.5, fill=None, stroke='--amber', width=1.6)
    return q1, md, q3, lo, hi


def boxplot_v(f, p, xs, x, w=40):
    q1, md, q3 = S.quantile(xs, .25), S.median(xs), S.quantile(xs, .75)
    iqr = q3 - q1
    lo = min(v for v in xs if v >= q1 - 1.5 * iqr)
    hi = max(v for v in xs if v <= q3 + 1.5 * iqr)
    a, b = p.sy(q1), p.sy(q3)
    f.line(x, p.sy(lo), x, a, stroke='--paper-dim', width=1.4)
    f.line(x, b, x, p.sy(hi), stroke='--paper-dim', width=1.4)
    f.line(x - w / 4, p.sy(lo), x + w / 4, p.sy(lo), stroke='--paper-dim', width=1.4)
    f.line(x - w / 4, p.sy(hi), x + w / 4, p.sy(hi), stroke='--paper-dim', width=1.4)
    f.path(f'M{x - w / 2:.1f} {a:.1f} L{x + w / 2:.1f} {a:.1f} L{x + w / 2:.1f} {b:.1f} '
           f'L{x - w / 2:.1f} {b:.1f} Z', stroke='--phosphor', width=1.4, fill='--scan')
    f.line(x - w / 2, p.sy(md), x + w / 2, p.sy(md), stroke='--amber', width=2.2)
    for v in xs:
        if v < lo or v > hi:
            f.circle(x, p.sy(v), 4.5, fill=None, stroke='--amber', width=1.6)


@figure('l06-boxplot-anatomy', 6)
def l06_boxplot_anatomy(lang):
    xs = S.column('minutes')
    t = {'en': dict(
        label='A boxplot of the twelve delivery times over the dots themselves. The box runs from '
              'the first quartile, 32.6, to the third, 41.8, with the median, 37.25, marked inside. '
              'The left whisker reaches the fastest delivery, 27.5. The right whisker stops at '
              '52.5; 61 lies beyond the upper fence at 55.4 and is drawn as a separate point.',
        axis='delivery time, in minutes', q1='Q1', q3='Q3', med='median', wl='whisker',
        wr='whisker', fence='upper fence', out='beyond the fence', box='the middle half',
        cap='The box holds the middle half of the deliveries. Each whisker runs to the most '
            'extreme value within 1.5 box-lengths of the box; anything further is drawn alone.'),
        'pt': dict(
        label='Um boxplot dos doze tempos de entrega sobre os próprios pontos. A caixa vai do '
              'primeiro quartil, 32,6, ao terceiro, 41,8, com a mediana, 37,25, marcada dentro. O '
              'bigode esquerdo chega à entrega mais rápida, 27,5. O bigode direito para em 52,5; '
              '61 fica além da cerca superior, em 55,4, e é desenhado como um ponto separado.',
        axis='tempo de entrega, em minutos', q1='Q1', q3='Q3', med='mediana', wl='bigode',
        wr='bigode', fence='cerca superior', out='além da cerca', box='a metade do meio',
        cap='A caixa contém a metade do meio das entregas. Cada bigode vai até o valor mais '
            'extremo a até 1,5 comprimento de caixa da caixa; o que passar disso é desenhado '
            'sozinho.')}[lang]
    f = Fig('l06-boxplot-anatomy', 660, 250, t['label'])
    p = Plot(f, 40, 30, 620, 195, 25, 65, 0, 1)
    p.xaxis(range(25, 66, 5), label=t['axis'])
    for x in xs:
        f.circle(p.sx(x), 168, 3.5, fill='--phosphor-dim', stroke='--phosphor', width=0.8)
    q1, md, q3, lo, hi = boxplot_h(f, p, xs, 110, h=34)
    q3v = S.quantile(xs, .75)
    fence = q3v + 1.5 * (q3v - S.quantile(xs, .25))
    f.line(p.sx(fence), 70, p.sx(fence), 150, stroke='--paper-dim', width=1.2, dash='3 3')
    f.text(p.sx(fence), 62, t['fence'], size=9.5, fill='--paper-dim')
    f.text(p.sx(q1), 82, t['q1'], size=10, weight='600')
    f.text(p.sx(q3), 82, t['q3'], size=10, weight='600')
    f.text(p.sx(md), 140, t['med'], size=10, fill='--amber')
    f.text((p.sx(q1) + p.sx(q3)) / 2, 50, t['box'], size=9.5, fill='--paper-dim')
    f.text((p.sx(lo) + p.sx(q1)) / 2, 100, t['wl'], size=9.5, fill='--paper-dim')
    f.text((p.sx(q3) + p.sx(hi)) / 2, 100, t['wr'], size=9.5, fill='--paper-dim')
    f.text(p.sx(61), 92, t['out'], size=9.5, fill='--amber', anchor='end')
    return f, t['cap']


@figure('l06-baskets-box', 6)
def l06_baskets_box(lang):
    xs = S.BASKETS
    edges = list(range(0, 441, 20))
    counts = histogram(xs, edges)
    t = {'en': dict(
        label='The histogram of the 400 baskets with a boxplot drawn under it on the same scale. '
              'The box runs from R$ 42.56 to R$ 106.38 with the median at R$ 66.73 closer to its '
              'left end. The right whisker is far longer than the left, and 17 baskets beyond '
              'R$ 202 are drawn as separate points.',
        y='orders', x='basket, in reais',
        cap='The same data twice. The box is off-centre and the right whisker is long: the '
            'boxplot shows the tail the histogram shows, in a strip a fifth of the height.'),
        'pt': dict(
        label='O histograma das 400 cestas com um boxplot desenhado embaixo, na mesma escala. A '
              'caixa vai de R$ 42,56 a R$ 106,38, com a mediana em R$ 66,73, mais perto da ponta '
              'esquerda. O bigode direito é muito mais longo que o esquerdo, e 17 cestas além de '
              'R$ 202 são desenhadas como pontos separados.',
        y='pedidos', x='cesta, em reais',
        cap='Os mesmos dados duas vezes. A caixa está fora do centro e o bigode direito é longo: o '
            'boxplot mostra a cauda que o histograma mostra, numa faixa com um quinto da altura.')}[lang]
    f = Fig('l06-baskets-box', 660, 320, t['label'])
    top = (max(counts) // 10 + 1) * 10
    p = Plot(f, 70, 40, 630, 200, 0, 440, 0, top)
    p.yaxis(range(0, top + 1, 20), label=t['y'])
    p.bars(edges, counts)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    boxplot_h(f, p, xs, 236, h=26)
    q = Plot(f, 70, 40, 630, 262, 0, 440, 0, 1)
    q.xaxis(range(0, 441, 40), label=t['x'])
    return f, t['cap']


@figure('l06-hoods', 6)
def l06_hoods(lang):
    t = {'en': dict(
        label='Four vertical boxplots of delivery time, one per neighbourhood, thirty deliveries '
              'each. Centro and Cambuí sit lowest, around 30 minutes, with Centro showing one point '
              'above its whisker at 45.5. Taquaral is higher, around 39. Barão Geraldo is highest, '
              'around 54, and its box is the tallest.',
        y='minutes', names={'Centro': 'Centro', 'Cambuí': 'Cambuí', 'Taquaral': 'Taquaral',
                            'Barão Geraldo': 'Barão Geraldo'},
        cap='Four groups on one scale. The medians climb with the distance from the warehouse, '
            'and Barão Geraldo, the farthest, also varies the most.'),
        'pt': dict(
        label='Quatro boxplots verticais do tempo de entrega, um por bairro, trinta entregas cada. '
              'Centro e Cambuí ficam mais baixo, perto de 30 minutos, com o Centro mostrando um '
              'ponto acima do bigode, em 45,5. Taquaral fica mais alto, perto de 39. Barão Geraldo '
              'é o mais alto, perto de 54, e a caixa dele é a mais alta.',
        y='minutos', names={'Centro': 'Centro', 'Cambuí': 'Cambuí', 'Taquaral': 'Taquaral',
                            'Barão Geraldo': 'Barão Geraldo'},
        cap='Quatro grupos numa escala só. As medianas sobem com a distância até o depósito, e '
            'Barão Geraldo, o mais distante, também é o que mais varia.')}[lang]
    f = Fig('l06-hoods', 600, 300, t['label'])
    p = Plot(f, 70, 40, 570, 250, 0.5, 4.5, 20, 70)
    p.yaxis(range(20, 71, 10), label=t['y'])
    for i, (hood, _, _) in enumerate(S.HOODS):
        xs = [r['minutes'] for r in S.DELIVERIES if r['hood'] == hood]
        boxplot_v(f, p, xs, p.sx(i + 1), w=56)
        f.text(p.sx(i + 1), p.y1 + 16, t['names'][hood], size=10)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 7

@figure('l07-bin-widths', 7)
def l07_bin_widths(lang):
    xs = S.BASKETS
    t = {'en': dict(
        label='The same 400 baskets drawn three times. With bins of R$ 5 the bars are a jagged '
              'comb. With bins of R$ 20 a single peak and a long right tail appear. With bins of '
              'R$ 80 almost everything falls in the first two bars and the shape is lost.',
        w='bins of R$ {}', x='basket, in reais',
        cap='Too narrow and the picture is noise; too wide and the shape disappears. The middle '
            'width shows the peak and the tail.'),
        'pt': dict(
        label='As mesmas 400 cestas desenhadas três vezes. Com faixas de R$ 5 as barras são um pente '
              'irregular. Com faixas de R$ 20 aparecem um pico só e uma cauda longa à direita. Com '
              'faixas de R$ 80 quase tudo cai nas duas primeiras barras e a forma se perde.',
        w='faixas de R$ {}', x='cesta, em reais',
        cap='Estreita demais e o desenho é ruído; larga demais e a forma some. A largura do meio '
            'mostra o pico e a cauda.')}[lang]
    f = Fig('l07-bin-widths', 660, 432, t['label'])
    for i, w in enumerate((5, 20, 80)):
        y0 = 30 + i * 118
        edges = list(range(0, 481, w))
        counts = histogram(xs, edges)
        top = max(counts)
        p = Plot(f, 60, y0 + 14, 630, y0 + 94, 0, 480, 0, top)
        p.bars(edges, counts)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
        f.text(60, y0, t['w'].format(w), size=10, anchor='start', weight='600')
        f.text(56, p.y0, str(top), size=9, anchor='end', fill='--paper-dim')
        f.text(56, p.y1, '0', size=9, anchor='end', fill='--paper-dim')
    q = Plot(f, 60, 0, 630, 386, 0, 480, 0, 1)
    q.xaxis(range(0, 481, 40), label=t['x'])
    return f, t['cap']


def small_hist(f, x0, y0, w, h, xs, edges, label, lang, unit=''):
    counts = histogram(xs, edges)
    p = Plot(f, x0, y0, x0 + w, y0 + h, edges[0], edges[-1], 0, max(counts) * 1.1)
    p.bars(edges, counts)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    m, md = S.mean(xs), S.median(xs)
    f.line(p.sx(md), p.y1, p.sx(md), y0 - 4, stroke='--paper', width=1.6)
    f.line(p.sx(m), p.y1, p.sx(m), y0 - 4, stroke='--amber', width=1.6, dash='4 3')
    f.text(x0 + w / 2, y0 - 20, label, size=10.5, weight='600')
    f.text(x0, p.y1 + 13, num(lang, edges[0], 0) + unit, size=9, anchor='start', fill='--paper-dim')
    f.text(x0 + w, p.y1 + 13, num(lang, edges[-1], 0) + unit, size=9, anchor='end', fill='--paper-dim')
    return p


@figure('l07-three-shapes', 7)
def l07_three_shapes(lang):
    t = {'en': dict(
        label='Three histograms side by side. On the left, 100 scores on an easy test, piled up '
              'near the top with a tail running left; the mean, 86.4, is left of the median, 89. In '
              'the middle, 200 bags of rice, symmetric, with mean and median together near 1003 g. '
              'On the right, 400 baskets with a tail running right; the mean, 82.78, is right of '
              'the median, 66.74.',
        titles=('left-skewed: test scores', 'symmetric: bags, in g', 'right-skewed: baskets'),
        key_m='mean', key_md='median',
        cap='The tail pulls the mean towards it. On the left it sits below the median, on the right '
            'above it; in the symmetric middle the two coincide.'),
        'pt': dict(
        label='Três histogramas lado a lado. À esquerda, 100 notas de uma prova fácil, amontoadas '
              'perto do topo com uma cauda para a esquerda; a média, 86,4, fica à esquerda da '
              'mediana, 89. No meio, 200 sacos de arroz, simétricos, com média e mediana juntas '
              'perto de 1003 g. À direita, 400 cestas com uma cauda para a direita; a média, 82,78, '
              'fica à direita da mediana, 66,74.',
        titles=('assimetria à esquerda: notas', 'simétrica: sacos, em g', 'assimetria à direita: cestas'),
        key_m='média', key_md='mediana',
        cap='A cauda puxa a média para perto dela. À esquerda ela fica abaixo da mediana, à direita '
            'acima; no meio simétrico as duas coincidem.')}[lang]
    f = Fig('l07-three-shapes', 690, 240, t['label'])
    small_hist(f, 20, 50, 200, 130, S.SCORES, list(range(50, 101, 5)), t['titles'][0], lang)
    small_hist(f, 245, 50, 200, 130, S.BAGS, list(range(984, 1024, 3)), t['titles'][1], lang)
    small_hist(f, 470, 50, 200, 130, S.BASKETS, list(range(0, 441, 20)), t['titles'][2], lang)
    f.line(250, 222, 270, 222, stroke='--paper', width=1.6)
    f.text(276, 222, t['key_md'], size=9.5, anchor='start')
    f.line(370, 222, 390, 222, stroke='--amber', width=1.6, dash='4 3')
    f.text(396, 222, t['key_m'], size=9.5, anchor='start', fill='--amber')
    return f, t['cap']


def t_pdf(x, df):
    c = math.exp(math.lgamma((df + 1) / 2) - math.lgamma(df / 2)) / math.sqrt(df * math.pi)
    return c * (1 + x * x / df) ** (-(df + 1) / 2)


@figure('l07-tails', 7)
def l07_tails(lang):
    # a t with 5 degrees of freedom, scaled to standard deviation 1, against the normal
    k = math.sqrt(5 / 3)
    heavy = lambda x: k * t_pdf(x * k, 5)
    t = {'en': dict(
        label='Two curves with the same mean, 0, and the same standard deviation, 1. The normal '
              'curve is drawn in blue. The heavy-tailed curve, in red, is taller and narrower in '
              'the middle. A second panel enlarges the right tail from 2 to 4.5 standard '
              'deviations: beyond about 2.5 the red curve stays above the blue one.',
        y='density', x='standard deviations from the mean', normal='normal: excess kurtosis 0',
        heavy='heavy tails: excess kurtosis 6', zoom='the right tail, enlarged',
        cap='Same centre, same standard deviation, different tails. Kurtosis measures how much of '
            'the spread comes from rare values far out.'),
        'pt': dict(
        label='Duas curvas com a mesma média, 0, e o mesmo desvio padrão, 1. A curva normal está '
              'em azul. A curva de caudas pesadas, em vermelho, é mais alta e estreita no meio. Um '
              'segundo painel amplia a cauda direita, de 2 a 4,5 desvios padrão: além de uns 2,5, a '
              'curva vermelha fica acima da azul.',
        y='densidade', x='desvios padrão a partir da média', normal='normal: curtose em excesso 0',
        heavy='caudas pesadas: curtose em excesso 6', zoom='a cauda direita, ampliada',
        cap='Mesmo centro, mesmo desvio padrão, caudas diferentes. A curtose mede quanto da '
            'dispersão vem de valores raros e distantes.')}[lang]
    f = Fig('l07-tails', 680, 320, t['label'])
    p = Plot(f, 60, 70, 400, 255, -4.5, 4.5, 0, 0.55)
    p.yaxis([0, 0.1, 0.2, 0.3, 0.4, 0.5], fmt=lambda v: num(lang, v, 1), label=t['y'])
    p.xaxis(range(-4, 5, 2), fmt=lambda v: str(v).replace('-', '−'), label=t['x'])
    p.curve(S.normal_pdf, -4.5, 4.5, stroke='--phosphor', width=2.2)
    p.curve(heavy, -4.5, 4.5, stroke='--amber', width=2.2, dash='6 3')
    z = Plot(f, 470, 70, 660, 255, 2, 4.5, 0, 0.06)
    z.yaxis([0, 0.02, 0.04, 0.06], fmt=lambda v: num(lang, v, 2), grid=True)
    z.xaxis([2, 3, 4], fmt=str)
    z.curve(S.normal_pdf, 2, 4.5, stroke='--phosphor', width=2.2)
    z.curve(heavy, 2, 4.5, stroke='--amber', width=2.2, dash='6 3')
    f.text(565, 46, t['zoom'], size=9.5, fill='--paper-dim')
    f.line(60, 18, 82, 18, stroke='--phosphor', width=2.2)
    f.text(88, 18, t['normal'], size=9.5, anchor='start', fill='--phosphor')
    f.line(330, 18, 352, 18, stroke='--amber', width=2.2, dash='6 3')
    f.text(358, 18, t['heavy'], size=9.5, anchor='start', fill='--amber')
    return f, t['cap']


@figure('l07-bimodal', 7)
def l07_bimodal(lang):
    xs = S.ORDER_HOURS
    edges = [h / 2 for h in range(14, 49)]
    counts = histogram(xs, edges)
    m = S.mean(xs)
    t = {'en': dict(
        label='A histogram of the time of day of 500 orders, in half-hour bins from 7:00 to 24:00, '
              'with a boxplot under it. There are two peaks, one around lunch at 12:00 and a larger '
              'one around dinner at 19:30, and almost nothing between 15:00 and 17:00. The mean, '
              'about 16:06, falls in that empty afternoon. The boxplot shows a box from about '
              '12:11 to 19:44 with the median near 17:57, and gives no hint of the two peaks.',
        y='orders', x='time of day', mean='mean 16:06',
        cap='Two peaks and an empty afternoon. The mean lands where almost nobody orders, and the '
            'boxplot underneath looks like any other.'),
        'pt': dict(
        label='Um histograma do horário de 500 pedidos, em faixas de meia hora das 7:00 às 24:00, com '
              'um boxplot embaixo. Há dois picos, um perto do almoço, às 12:00, e outro maior perto '
              'do jantar, às 19:30, e quase nada entre 15:00 e 17:00. A média, por volta das 16:06, '
              'cai nessa tarde vazia. O boxplot mostra uma caixa de cerca de 12:11 a 19:44, com a '
              'mediana perto das 17:57, e não dá nenhum sinal dos dois picos.',
        y='pedidos', x='horário do dia', mean='média 16:06',
        cap='Dois picos e uma tarde vazia. A média cai onde quase ninguém pede, e o boxplot embaixo '
            'parece igual a qualquer outro.')}[lang]
    f = Fig('l07-bimodal', 660, 320, t['label'])
    top = (max(counts) // 10 + 1) * 10
    p = Plot(f, 70, 40, 630, 200, 7, 24, 0, top)
    p.yaxis(range(0, top + 1, 10), label=t['y'])
    p.bars(edges, counts)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    p.vline(m, t['mean'], stroke='--amber', top=40, anchor='middle', dy=-2)
    boxplot_h(f, p, xs, 234, h=24)
    q = Plot(f, 70, 0, 630, 262, 7, 24, 0, 1)
    q.xaxis(range(8, 25, 2), fmt=lambda v: f'{v}:00', label=t['x'])
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
