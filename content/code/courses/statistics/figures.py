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


# ------------------------------------------------------------------ lesson 8

def pmf_bars(f, p, probs, highlight=None, width=0.6, labels=True, lang='en', d=3):
    for k, pr in probs:
        x0, x1 = p.sx(k - width / 2), p.sx(k + width / 2)
        hot = highlight and highlight(k)
        f.path(f'M{x0:.1f} {p.y1:.1f} L{x0:.1f} {p.sy(pr):.1f} L{x1:.1f} {p.sy(pr):.1f} '
               f'L{x1:.1f} {p.y1:.1f} Z', stroke='--amber' if hot else '--phosphor', width=1,
               fill='--amber' if hot else '--phosphor-dim')
        if labels and pr > 0.004:
            f.text((x0 + x1) / 2, p.sy(pr) - 9, num(lang, pr, d), size=9,
                   fill='--amber' if hot else '--paper-dim')
        f.text((x0 + x1) / 2, p.y1 + 13, str(k), size=10)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')


@figure('l08-uniform', 8)
def l08_uniform(lang):
    t = {'en': dict(
        label='A flat line at height one thirtieth from 0 to 30 minutes: the courier is equally '
              'likely to arrive at any moment in the half hour. The stretch from 20 to 30 minutes '
              'is shaded; it is a third of the rectangle, so the chance of waiting more than 20 '
              'minutes is one in three.',
        x='minutes after 18:00', shade='wait longer than 20 minutes: 1/3',
        cap='Every moment equally likely, so the probability of any stretch is its share of the '
            'width.'),
        'pt': dict(
        label='Uma linha reta na altura de um trinta avos, de 0 a 30 minutos: o entregador tem a '
              'mesma chance de chegar em qualquer momento da meia hora. O trecho de 20 a 30 minutos '
              'está sombreado; é um terço do retângulo, então a chance de esperar mais de 20 minutos '
              'é de uma em três.',
        x='minutos depois das 18:00', shade='esperar mais de 20 minutos: 1/3',
        cap='Todo momento com a mesma chance, então a probabilidade de qualquer trecho é a fração '
            'que ele ocupa da largura.')}[lang]
    f = Fig('l08-uniform', 560, 200, t['label'])
    p = Plot(f, 50, 40, 520, 150, -2, 32, 0, 1.4)
    p.xaxis(range(0, 31, 5), label=t['x'])
    f.path(f'M{p.sx(20):.1f} {p.sy(0):.1f} L{p.sx(20):.1f} {p.sy(1):.1f} L{p.sx(30):.1f} '
           f'{p.sy(1):.1f} L{p.sx(30):.1f} {p.sy(0):.1f} Z', stroke=None, width=0, fill='--amber',
           opacity=0.45)
    f.path(f'M{p.sx(0):.1f} {p.sy(0):.1f} L{p.sx(0):.1f} {p.sy(1):.1f} L{p.sx(30):.1f} '
           f'{p.sy(1):.1f} L{p.sx(30):.1f} {p.sy(0):.1f}', stroke='--phosphor', width=2.2)
    f.text(p.sx(25), p.sy(1) - 14, t['shade'], size=10, fill='--amber')
    return f, t['cap']


@figure('l08-binomial', 8)
def l08_binomial(lang):
    probs = [(k, S.binom_pmf(k, 10, 0.15)) for k in range(0, 11)]
    t = {'en': dict(
        label='A bar chart of the binomial distribution with 10 deliveries, each late with '
              'probability 0.15. The bars for 0 to 5 late deliveries are 0.197, 0.347, 0.276, '
              '0.130, 0.040 and 0.008; from 6 upwards they are too small to see. The bars for 3 or '
              'more are highlighted and add up to 0.180.',
        y='probability', x='late deliveries out of 10', hot='3 or more: 0.180',
        cap='One count, eleven possible values, and a probability for each. The highlighted bars '
            'are the evenings with three or more late deliveries.'),
        'pt': dict(
        label='Um gráfico de barras da distribuição binomial com 10 entregas, cada uma atrasando com '
              'probabilidade 0,15. As barras de 0 a 5 atrasos são 0,197, 0,347, 0,276, 0,130, 0,040 e '
              '0,008; de 6 para cima são pequenas demais para ver. As barras de 3 ou mais estão '
              'destacadas e somam 0,180.',
        y='probabilidade', x='entregas atrasadas em 10', hot='3 ou mais: 0,180',
        cap='Uma contagem, onze valores possíveis, e uma probabilidade para cada. As barras '
            'destacadas são as noites com três ou mais atrasos.')}[lang]
    f = Fig('l08-binomial', 600, 250, t['label'])
    p = Plot(f, 70, 40, 570, 200, -0.6, 10.6, 0, 0.4)
    p.yaxis([0, 0.1, 0.2, 0.3, 0.4], fmt=lambda v: num(lang, v, 1), label=t['y'])
    pmf_bars(f, p, probs, highlight=lambda k: k >= 3, lang=lang)
    f.text((p.x0 + p.x1) / 2, p.y1 + 33, t['x'], size=10, weight='600')
    f.text(p.sx(6.5), p.sy(0.2), t['hot'], size=10.5, fill='--amber', weight='600')
    return f, t['cap']


@figure('l08-poisson', 8)
def l08_poisson(lang):
    c = S.COMPLAINTS
    obs = [c.count(k) for k in range(9)]
    exp_ = [60 * S.poisson_pmf(k, 2.4) for k in range(9)]
    t = {'en': dict(
        label='Bars show how many of 60 days had 0, 1, 2 and up to 8 complaints: 5, 17, 16, 8, 12, '
              '2, and none with 6 or more. Dots show what a Poisson distribution with mean 2.4 '
              'expects in 60 days: about 5.4, 13.1, 15.7, 12.5, 7.5, 3.6, 1.4, 0.5 and 0.2. The two '
              'follow the same shape, with the ups and downs sixty days produce.',
        y='days', x='complaints in a day', o='observed days', e='Poisson, mean 2.4',
        cap='Sixty real days against the model. No sample matches a model bar for bar; the '
            'question is whether the shape and the spread agree.'),
        'pt': dict(
        label='As barras mostram quantos de 60 dias tiveram 0, 1, 2 e até 8 reclamações: 5, 17, 16, 8, '
              '12, 2, e nenhum com 6 ou mais. Os pontos mostram o que uma distribuição de Poisson com '
              'média 2,4 espera em 60 dias: cerca de 5,4, 13,1, 15,7, 12,5, 7,5, 3,6, 1,4, 0,5 e 0,2. '
              'Os dois seguem a mesma forma, com os altos e baixos que sessenta dias produzem.',
        y='dias', x='reclamações num dia', o='dias observados', e='Poisson, média 2,4',
        cap='Sessenta dias reais contra o modelo. Nenhuma amostra bate com um modelo barra a barra; '
            'a pergunta é se a forma e a dispersão concordam.')}[lang]
    f = Fig('l08-poisson', 600, 260, t['label'])
    p = Plot(f, 70, 50, 570, 205, -0.6, 8.6, 0, 20)
    p.yaxis(range(0, 21, 5), label=t['y'])
    pmf_bars(f, p, list(enumerate(obs)), labels=False, lang=lang)
    for k, e in enumerate(exp_):
        f.circle(p.sx(k), p.sy(e), 4.5, fill='--amber', stroke='--paper', width=0.8)
    f.text((p.x0 + p.x1) / 2, p.y1 + 33, t['x'], size=10, weight='600')
    f.path(f'M390 30 L404 30 L404 42 L390 42 Z', stroke='--phosphor', width=1, fill='--phosphor-dim')
    f.text(410, 36, t['o'], size=9.5, anchor='start')
    f.circle(397, 56, 4.5, fill='--amber', stroke='--paper', width=0.8)
    f.text(410, 56, t['e'], size=9.5, anchor='start', fill='--amber')
    return f, t['cap']


@figure('l08-normal-rule', 8)
def l08_normal_rule(lang):
    t = {'en': dict(
        label='A normal curve for bag weights with mean 1003 g and standard deviation 6 g. Bands '
              'mark one, two and three standard deviations either side: 997 to 1009 g holds 68.3% '
              'of bags, 991 to 1015 g holds 95.4%, and 985 to 1021 g holds 99.7%.',
        x='weight of a bag, in grams',
        cap='The same proportions for every normal curve, whatever its mean and standard '
            'deviation: about 68%, 95% and 99.7%.'),
        'pt': dict(
        label='Uma curva normal para o peso dos sacos, com média 1003 g e desvio padrão 6 g. Faixas '
              'marcam um, dois e três desvios padrão para cada lado: de 997 a 1009 g ficam 68,3% dos '
              'sacos, de 991 a 1015 g ficam 95,4%, e de 985 a 1021 g ficam 99,7%.',
        x='peso de um saco, em gramas',
        cap='As mesmas proporções para toda curva normal, sejam quais forem a média e o desvio '
            'padrão: cerca de 68%, 95% e 99,7%.')}[lang]
    mu, sg = 1003, 6
    pdf = lambda x: S.normal_pdf((x - mu) / sg) / sg
    f = Fig('l08-normal-rule', 640, 300, t['label'])
    p = Plot(f, 40, 90, 610, 240, mu - 4 * sg, mu + 4 * sg, 0, pdf(mu) * 1.05)
    p.curve(pdf, mu - sg, mu + sg, fill='--phosphor-dim')
    p.curve(pdf, mu - 4 * sg, mu + 4 * sg, stroke='--phosphor', width=2.2)
    p.xaxis(range(mu - 3 * sg, mu + 3 * sg + 1, sg), label=t['x'])
    for k, share, y in ((1, '68,3%' if lang == 'pt' else '68.3%', 74),
                        (2, '95,4%' if lang == 'pt' else '95.4%', 50),
                        (3, '99,7%' if lang == 'pt' else '99.7%', 26)):
        a, b = p.sx(mu - k * sg), p.sx(mu + k * sg)
        f.line(a, y, b, y, stroke='--paper-dim', width=1.2)
        f.line(a, y - 5, a, y + 5, stroke='--paper-dim', width=1.2)
        f.line(b, y - 5, b, y + 5, stroke='--paper-dim', width=1.2)
        f.text((a + b) / 2, y - 9, share, size=10, weight='600')
        f.line(a, y + 5, a, p.y1, stroke='--wire', width=1, dash='2 3')
        f.line(b, y + 5, b, p.y1, stroke='--wire', width=1, dash='2 3')
    return f, t['cap']


@figure('l08-z-area', 8)
def l08_z_area(lang):
    mu, sg = 1003, 6
    pdf = lambda x: S.normal_pdf((x - mu) / sg) / sg
    pr = S.normal_cdf((995 - mu) / sg)
    t = {'en': dict(
        label=f'The normal curve of bag weights, mean 1003 g and standard deviation 6 g, with the '
              f'area left of 995 g shaded. 995 g is 1.33 standard deviations below the mean, and '
              f'the shaded area is {num("en", pr, 4)}, about 9% of the bags.',
        x='weight of a bag, in grams', z='z = −1.33', area=f'area {num("en", pr, 4)}',
        cap='A probability under a continuous curve is an area. Turn the weight into a z-score, '
            'and one table, or one formula, gives the area for any normal curve.'),
        'pt': dict(
        label=f'A curva normal do peso dos sacos, média 1003 g e desvio padrão 6 g, com a área à '
              f'esquerda de 995 g sombreada. 995 g fica 1,33 desvio padrão abaixo da média, e a área '
              f'sombreada é {num("pt", pr, 4)}, cerca de 9% dos sacos.',
        x='peso de um saco, em gramas', z='z = −1,33', area=f'área {num("pt", pr, 4)}',
        cap='Uma probabilidade sob uma curva contínua é uma área. Transforme o peso num escore z, e '
            'uma tabela, ou uma fórmula, dá a área para qualquer curva normal.')}[lang]
    f = Fig('l08-z-area', 620, 250, t['label'])
    p = Plot(f, 40, 40, 590, 190, mu - 4 * sg, mu + 4 * sg, 0, pdf(mu) * 1.05)
    p.curve(pdf, mu - 4 * sg, 995, fill='--amber')
    p.curve(pdf, mu - 4 * sg, mu + 4 * sg, stroke='--phosphor', width=2.2)
    p.xaxis(range(mu - 3 * sg, mu + 3 * sg + 1, sg), label=t['x'])
    p.vline(995, t['z'], stroke='--amber', top=60, anchor='end')
    f.text(p.sx(986), p.sy(pdf(995) * 0.9), t['area'], size=10.5, fill='--amber', weight='600',
           anchor='end')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 9

@figure('l09-masking', 9)
def l09_masking(lang):
    twelve = S.column('basket')
    two = [2126.00 if x == 212.60 else 1547.50 if x == 154.75 else x for x in twelve]
    m, s_ = S.mean(two), S.sd(two)
    md, mad = S.median(two), S.mad(two)
    half = 3.5 * mad / 0.6745
    t = {'en': dict(
        label=f'The twelve baskets with two typing errors, R$ 1,547.50 and R$ 2,126.00, on a line '
              f'from R$ 0 to R$ 2,500, drawn twice. Above, the band of the z-score rule, the mean '
              f'plus or minus three standard deviations, reaches from below zero to about R$ 2,466 '
              f'and contains both errors, so neither is flagged. Below, the band of the robust rule, '
              f'built from the median and the MAD, reaches only to about R$ 247, and both errors lie '
              f'far outside it.',
        x='basket, in reais', zr='z-score rule: mean ± 3 sd', rr='robust rule: median ± 3.5 robust units',
        none='nothing flagged', both='both flagged',
        cap='The two errors inflate the standard deviation until the band they are judged by '
            'contains them. The median and the MAD barely notice them.'),
        'pt': dict(
        label=f'As doze cestas com dois erros de digitação, R$ 1.547,50 e R$ 2.126,00, numa reta de '
              f'R$ 0 a R$ 2.500, desenhadas duas vezes. Em cima, a faixa da regra do escore z, a média '
              f'mais ou menos três desvios padrão, vai de abaixo de zero até cerca de R$ 2.466 e '
              f'contém os dois erros, então nenhum é apontado. Embaixo, a faixa da regra robusta, '
              f'construída com a mediana e o MAD, vai só até cerca de R$ 247, e os dois erros ficam '
              f'bem fora dela.',
        x='cesta, em reais', zr='regra do escore z: média ± 3 dp', rr='regra robusta: mediana ± 3,5 unidades robustas',
        none='nada apontado', both='os dois apontados',
        cap='Os dois erros inflam o desvio padrão até que a faixa pela qual são julgados os contenha. A '
            'mediana e o MAD quase não os notam.')}[lang]
    f = Fig('l09-masking', 660, 250, t['label'])
    p = Plot(f, 30, 30, 640, 205, 0, 2500, 0, 1)
    p.xaxis(range(0, 2501, 500), fmt=lambda v: num(lang, v, 0), label=t['x'])
    for row, (lo, hi, lab, verdict, col) in enumerate((
            (m - 3 * s_, m + 3 * s_, t['zr'], t['none'], '--paper-dim'),
            (md - half, md + half, t['rr'], t['both'], '--amber'))):
        y = 70 + row * 80
        a, b = p.sx(max(lo, 0)), p.sx(min(hi, 2500))
        f.path(f'M{a:.1f} {y - 14:.1f} L{b:.1f} {y - 14:.1f} L{b:.1f} {y + 14:.1f} L{a:.1f} {y + 14:.1f} Z',
               stroke='--phosphor', width=1.2, fill='--scan')
        f.text(30, y - 26, lab, size=10, anchor='start', weight='600')
        f.text(640, y - 26, verdict, size=10, anchor='end', fill=col, weight='600')
        for x in two:
            out = x < lo or x > hi
            f.circle(p.sx(x), y, 4.5, fill='--amber' if out else '--phosphor', stroke='--paper',
                     width=0.8)
    return f, t['cap']


@figure('l09-decide', 9)
def l09_decide(lang):
    t = {'en': dict(
        label='A decision chart. Start with a flagged value and go back to its source. If it is an '
              'error and the true value can be found, correct it; if it cannot, remove it and say '
              'so. If it belongs to a different population, analyse that group separately or '
              'exclude it by a rule written down beforehand. If it is a genuine extreme, keep it, '
              'and report the result with and without it when it changes the conclusion.',
        start='a flagged value', src='check the source', err='an error', other='another population',
        real='a genuine extreme', e1='correct it, or remove it', e2='and say so', o1='analyse it apart,',
        o2='or exclude it by a rule', r1='keep it, and report with', r2='and without it',
        cap='The rule that flags a value is only the start. What happens to it depends on where it '
            'came from, and every choice is written down.'),
        'pt': dict(
        label='Um diagrama de decisão. Comece com um valor apontado e volte à origem dele. Se for um '
              'erro e o valor verdadeiro puder ser achado, corrija-o; se não puder, remova-o e diga '
              'isso. Se ele pertencer a outra população, analise esse grupo separadamente ou exclua-o '
              'por uma regra escrita antes. Se for um extremo genuíno, mantenha-o, e informe o '
              'resultado com e sem ele quando isso mudar a conclusão.',
        start='um valor apontado', src='conferir a origem', err='um erro', other='outra população',
        real='um extremo genuíno', e1='corrigir, ou remover', e2='e dizer isso', o1='analisar à parte,',
        o2='ou excluir por uma regra', r1='manter, e informar com', r2='e sem ele',
        cap='A regra que aponta um valor é só o começo. O que acontece com ele depende de onde veio, e '
            'toda escolha fica registrada.')}[lang]
    f = Fig('l09-decide', 660, 290, t['label'])
    f.rect(250, 14, 160, 34, stroke='--amber')
    f.text(330, 31, t['start'], size=10.5, weight='600', fill='--amber')
    f.rect(250, 78, 160, 34, stroke='--phosphor')
    f.text(330, 95, t['src'], size=10.5, weight='600')
    f.line(330, 48, 330, 76, arrow=True)
    xs = [110, 330, 550]
    for x, lab, l1, l2 in zip(xs, (t['err'], t['other'], t['real']), (t['e1'], t['o1'], t['r1']),
                              (t['e2'], t['o2'], t['r2'])):
        f.rect(x - 90, 150, 180, 30, stroke='--wire')
        f.text(x, 165, lab, size=10.5, weight='600')
        f.rect(x - 95, 214, 190, 50, stroke='--wire', fill='--scan')
        f.text(x, 232, l1, size=10)
        f.text(x, 248, l2, size=10)
        f.line(x, 180, x, 212, arrow=True)
    f.path('M330 112 L330 130 L110 130 L110 148', stroke='--paper-dim', width=1.2, arrow=True)
    f.path('M330 112 L330 148', stroke='--paper-dim', width=1.2, arrow=True)
    f.path('M330 130 L550 130 L550 148', stroke='--paper-dim', width=1.2, arrow=True)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 10

@figure('l10-methods', 10)
def l10_methods(lang):
    t = {'en': dict(
        label='Three copies of the same population of 120 deliveries, drawn as four blocks of 30 '
              'dots, one block per neighbourhood: Centro, Cambuí, Taquaral and Barão Geraldo. In '
              'the first copy, a simple random sample of 20 is highlighted, scattered unevenly '
              'across the blocks. In the second, a stratified sample takes 5 from each block. In '
              'the third, a convenience sample takes 20 from the two blocks nearest the warehouse '
              'and none from the others.',
        titles=('simple random: any 20', 'stratified: 5 from each', 'convenience: the nearest 20'),
        hoods=('Centro', 'Cambuí', 'Taquaral', 'Barão G.'),
        cap='The same 20 deliveries chosen three ways. Only the convenience sample leaves whole '
            'neighbourhoods out, and no amount of extra data from the near ones fixes that.'),
        'pt': dict(
        label='Três cópias da mesma população de 120 entregas, desenhadas como quatro blocos de 30 '
              'pontos, um bloco por bairro: Centro, Cambuí, Taquaral e Barão Geraldo. Na primeira '
              'cópia, uma amostra aleatória simples de 20 está destacada, espalhada de forma desigual '
              'pelos blocos. Na segunda, uma amostra estratificada pega 5 de cada bloco. Na '
              'terceira, uma amostra por conveniência pega 20 dos dois blocos mais perto do depósito '
              'e nenhuma dos outros.',
        titles=('aleatória simples: 20 quaisquer', 'estratificada: 5 de cada', 'conveniência: as 20 mais perto'),
        hoods=('Centro', 'Cambuí', 'Taquaral', 'Barão G.'),
        cap='As mesmas 20 entregas escolhidas de três jeitos. Só a amostra por conveniência deixa '
            'bairros inteiros de fora, e nenhuma quantidade de dados a mais dos bairros perto conserta '
            'isso.')}[lang]
    f = Fig('l10-methods', 690, 270, t['label'])
    d = S.Draw(7)
    srs = set(d.sample(range(120), 20))
    strat = set()
    for g in range(4):
        strat |= set(d.sample(range(g * 30, g * 30 + 30), 5))
    conv = set(range(0, 10)) | set(range(30, 40))
    for panel, (title, chosen) in enumerate(zip(t['titles'], (srs, strat, conv))):
        x0 = 14 + panel * 228
        f.text(x0 + 103, 20, title, size=10.5, weight='600')
        for g in range(4):
            gx = x0 + (g % 2) * 106
            gy = 40 + (g // 2) * 112
            f.rect(gx, gy, 100, 102, stroke='--wire', fill='--panel')
            f.text(gx + 50, gy + 92, t['hoods'][g], size=9, fill='--paper-dim')
            for i in range(30):
                k = g * 30 + i
                cx = gx + 14 + (i % 6) * 14.4
                cy = gy + 14 + (i // 6) * 14
                if k in chosen:
                    f.circle(cx, cy, 4.6, fill='--amber')
                else:
                    f.circle(cx, cy, 3.2, fill='--phosphor-dim')
    return f, t['cap']


@figure('l10-strata', 10)
def l10_strata(lang):
    groups = {h: [r['minutes'] for r in S.DELIVERIES if r['hood'] == h] for h, _, _ in S.HOODS}
    allm = [r['minutes'] for r in S.DELIVERIES]
    d2 = S.Draw(1011)
    srs = [S.mean(d2.sample(allm, 20)) for _ in range(1000)]
    strat = []
    for _ in range(1000):
        pick = []
        for h in groups:
            pick += d2.sample(groups[h], 5)
        strat.append(S.mean(pick))
    near = groups['Centro'] + groups['Cambuí']
    t = {'en': dict(
        label='Two histograms of 1000 sample means each, on one scale from 28 to 48 minutes. The '
              'means of simple random samples of 20 spread from about 31 to 46. The means of '
              'stratified samples, 5 per neighbourhood, crowd between about 36 and 42. Both centre '
              'on the population mean, 38.65. A third line marks 31.28, where samples taken only '
              'from Centro and Cambuí centre, far from the truth.',
        r1='simple random samples of 20', r2='stratified, 5 per neighbourhood', truth='true mean 38.65',
        conv='near-only samples 31.28', x='mean of the sample, in minutes',
        cap='Both honest methods centre on the truth, and stratifying halves the wobble. The '
            'convenience samples are steady too, and steadily wrong.'),
        'pt': dict(
        label='Dois histogramas de 1000 médias amostrais cada, numa escala de 28 a 48 minutos. As '
              'médias de amostras aleatórias simples de 20 se espalham de uns 31 a 46. As médias de '
              'amostras estratificadas, 5 por bairro, se concentram entre uns 36 e 42. As duas se '
              'centram na média da população, 38,65. Uma terceira linha marca 31,28, onde se centram '
              'as amostras tiradas só do Centro e do Cambuí, longe da verdade.',
        r1='amostras aleatórias simples de 20', r2='estratificadas, 5 por bairro', truth='média verdadeira 38,65',
        conv='só bairros perto 31,28', x='média da amostra, em minutos',
        cap='Os dois métodos honestos se centram na verdade, e estratificar corta a oscilação pela '
            'metade. As amostras por conveniência também são estáveis, e estavelmente erradas.')}[lang]
    f = Fig('l10-strata', 660, 330, t['label'])
    edges = [28 + i * 0.5 for i in range(41)]
    for row, (xs, lab) in enumerate(((srs, t['r1']), (strat, t['r2']))):
        y0 = 50 + row * 120
        counts = histogram(xs, edges)
        p = Plot(f, 40, y0, 630, y0 + 90, 28, 48, 0, 220)
        p.bars(edges, counts)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
        f.text(630, y0 + 6, lab, size=10, anchor='end', weight='600')
    q = Plot(f, 40, 30, 630, 270, 28, 48, 0, 1)
    q.xaxis(range(28, 49, 2), label=t['x'])
    tm = S.mean(allm)
    f.line(q.sx(tm), 34, q.sx(tm), 270, stroke='--paper', width=1.6)
    f.text(q.sx(tm) + 6, 26, t['truth'], size=9.5, anchor='start')
    f.line(q.sx(S.mean(near)), 34, q.sx(S.mean(near)), 270, stroke='--amber', width=1.6, dash='4 3')
    f.text(q.sx(S.mean(near)) - 6, 26, t['conv'], size=9.5, anchor='end', fill='--amber')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 11

@figure('l11-clt', 11)
def l11_clt(lang):
    b = S.BASKETS
    mu, sig = S.mean(b), S.sd(b, False)
    ns = (1, 5, 30, 100)
    t = {'en': dict(
        label='Four histograms on the same scale, from R$ 0 to R$ 440, each of 2,000 sample means '
              'drawn from Horta’s 400 baskets. With samples of 1, the histogram is the baskets '
              'themselves: a peak on the left and a long right tail. With samples of 5 the means '
              'are less skewed and narrower. With samples of 30 they form a nearly symmetric bell, '
              'and with samples of 100 a narrow bell centred on R$ 82.78. From 5 upwards a normal '
              'curve is drawn over each histogram.',
        row='means of samples of {}', x='mean basket of the sample, in reais',
        cap='The population never changes shape. The means of samples drawn from it do: larger '
            'samples give means that are more symmetric and more tightly gathered around R$ 82.78.'),
        'pt': dict(
        label='Quatro histogramas na mesma escala, de R$ 0 a R$ 440, cada um com 2.000 médias '
              'amostrais tiradas das 400 cestas da Horta. Com amostras de 1, o histograma são as '
              'próprias cestas: um pico à esquerda e uma cauda longa à direita. Com amostras de 5, as '
              'médias são menos assimétricas e mais estreitas. Com amostras de 30, formam um sino '
              'quase simétrico, e com amostras de 100, um sino estreito centrado em R$ 82,78. De 5 '
              'para cima, uma curva normal está desenhada sobre cada histograma.',
        row='médias de amostras de {}', x='cesta média da amostra, em reais',
        cap='A população nunca muda de forma. As médias das amostras tiradas dela mudam: amostras '
            'maiores dão médias mais simétricas e mais juntas em torno de R$ 82,78.')}[lang]
    f = Fig('l11-clt', 660, 460, t['label'])
    edges = [i * 5 for i in range(89)]
    for row, n in enumerate(ns):
        ms = S.sample_means(b, n, 2000, 1100 + n)
        counts = histogram(ms, edges)
        y0 = 30 + row * 100
        top = max(counts) * 1.08
        p = Plot(f, 40, y0 + 12, 630, y0 + 82, 0, 440, 0, top)
        p.bars(edges, counts)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
        if n >= 5:
            se = sig / math.sqrt(n)
            dens = lambda x, se=se: 2000 * 5 * S.normal_pdf((x - mu) / se) / se
            lo, hi = max(0, mu - 4 * se), min(440, mu + 4 * se)
            p.curve(dens, lo, hi, stroke='--amber', width=1.8)
        f.text(630, y0 + 16, t['row'].format(n), size=10, anchor='end', weight='600')
    q = Plot(f, 40, 0, 630, 420, 0, 440, 0, 1)
    q.xaxis(range(0, 441, 40), label=t['x'])
    return f, t['cap']


@figure('l11-shrink', 11)
def l11_shrink(lang):
    b = S.BASKETS
    sig = S.sd(b, False)
    pts = [(n, S.sd(S.sample_means(b, n, 2000, 1100 + n))) for n in S.CLT_N]
    t = {'en': dict(
        label='The standard deviation of 2,000 sample means plotted against the sample size, from 1 '
              'to 100. The simulated points, 58.07, 41.75, 26.56, 19.22, 10.67 and 5.78, sit on the '
              'curve sigma over the square root of n, which starts at 58.82 and falls steeply, then '
              'more and more slowly.',
        y='spread of the sample means, R$', x='sample size n', curve='σ ÷ √n', sim='2,000 simulated samples',
        cap='Four times the sample, half the spread. The first few extra baskets buy a lot of '
            'precision; after that each one buys less.'),
        'pt': dict(
        label='O desvio padrão de 2.000 médias amostrais em função do tamanho da amostra, de 1 a 100. '
              'Os pontos simulados, 58,07, 41,75, 26,56, 19,22, 10,67 e 5,78, ficam sobre a curva sigma '
              'sobre a raiz de n, que começa em 58,82 e cai depressa, depois cada vez mais devagar.',
        y='dispersão das médias amostrais, R$', x='tamanho da amostra n', curve='σ ÷ √n', sim='2.000 amostras simuladas',
        cap='Quatro vezes a amostra, metade da dispersão. As primeiras cestas a mais compram muita '
            'precisão; depois disso cada uma compra menos.')}[lang]
    f = Fig('l11-shrink', 620, 280, t['label'])
    p = Plot(f, 70, 40, 590, 220, 0, 100, 0, 60)
    p.yaxis(range(0, 61, 10), label=t['y'])
    p.xaxis(range(0, 101, 10), label=t['x'])
    p.curve(lambda n: sig / math.sqrt(n), 1, 100, stroke='--phosphor', width=2)
    for n, v in pts:
        f.circle(p.sx(n), p.sy(v), 5, fill='--amber', stroke='--paper', width=0.8)
    f.line(400, 60, 422, 60, stroke='--phosphor', width=2)
    f.text(428, 60, t['curve'], size=10, anchor='start', fill='--phosphor')
    f.circle(411, 80, 5, fill='--amber', stroke='--paper', width=0.8)
    f.text(428, 80, t['sim'], size=10, anchor='start', fill='--amber')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 12

@figure('l12-twenty', 12)
def l12_twenty(lang):
    d = S.Draw(1201)
    ivs = [S.t_interval(d.sample(S.BASKETS, 40)) for _ in range(20)]
    mu = S.mean(S.BASKETS)
    miss = sum(1 for a, b in ivs if not a <= mu <= b)
    t = {'en': dict(
        label=f'Twenty 95% confidence intervals for the mean basket, one per random sample of 40, '
              f'drawn as horizontal bars, with a vertical line at the true mean, R$ 82.78. '
              f'{20 - miss} of the bars cross the line; {miss} misses it, lying wholly to one side.',
        x='mean basket, in reais', truth='true mean 82.78', miss='misses',
        cap='Each sample gives a different interval. The method catches the true mean about 95% of '
            'the time; any one interval either contains it or does not.'),
        'pt': dict(
        label=f'Vinte intervalos de confiança de 95% para a cesta média, um por amostra aleatória de '
              f'40, desenhados como barras horizontais, com uma linha vertical na média verdadeira, '
              f'R$ 82,78. {20 - miss} das barras cruzam a linha; {miss} erra, ficando inteira de um lado.',
        x='cesta média, em reais', truth='média verdadeira 82,78', miss='erra',
        cap='Cada amostra dá um intervalo diferente. O método pega a média verdadeira em cerca de 95% '
            'das vezes; um intervalo qualquer a contém ou não.')}[lang]
    f = Fig('l12-twenty', 620, 380, t['label'])
    p = Plot(f, 40, 40, 590, 330, 30, 150, 0, 1)
    p.xaxis(range(30, 151, 20), label=t['x'])
    f.line(p.sx(mu), 30, p.sx(mu), p.y1, stroke='--paper', width=1.4)
    f.text(p.sx(mu), 22, t['truth'], size=9.5)
    for i, (a, b) in enumerate(ivs):
        y = 50 + i * 13.5
        hit = a <= mu <= b
        col = '--phosphor' if hit else '--amber'
        f.line(p.sx(a), y, p.sx(b), y, stroke=col, width=3, cap='round')
        f.circle(p.sx((a + b) / 2), y, 2.6, fill='--paper')
        if not hit:
            f.text(p.sx(b) + 8, y, t['miss'], size=9.5, anchor='start', fill='--amber')
    return f, t['cap']


@figure('l12-t', 12)
def l12_t(lang):
    t = {'en': dict(
        label='Three curves centred on zero. The normal curve is the tallest in the middle. The t '
              'distribution with 7 degrees of freedom is a little lower in the middle with thicker '
              'tails. With 2 degrees of freedom it is lower still, with much thicker tails. Marks '
              'show where the middle 95% ends for each: 1.96 for the normal, 2.36 for 7 degrees of '
              'freedom and 4.30 for 2.',
        normal='normal: 1.96', t7='t, 7 degrees of freedom: 2.36', t2='t, 2 degrees of freedom: 4.30',
        x='distance from the centre, in standard errors',
        cap='With few observations, the standard deviation itself is uncertain, and the t '
            'distribution widens the interval to pay for it. With many, it becomes the normal curve.'),
        'pt': dict(
        label='Três curvas centradas em zero. A curva normal é a mais alta no meio. A distribuição t '
              'com 7 graus de liberdade é um pouco mais baixa no meio, com caudas mais grossas. Com 2 '
              'graus de liberdade ela é ainda mais baixa, com caudas bem mais grossas. Marcas mostram '
              'onde terminam os 95% centrais de cada uma: 1,96 para a normal, 2,36 para 7 graus de '
              'liberdade e 4,30 para 2.',
        normal='normal: 1,96', t7='t, 7 graus de liberdade: 2,36', t2='t, 2 graus de liberdade: 4,30',
        x='distância do centro, em erros padrão',
        cap='Com poucas observações, o próprio desvio padrão é incerto, e a distribuição t alarga o '
            'intervalo para pagar por isso. Com muitas, ela vira a curva normal.')}[lang]
    f = Fig('l12-t', 640, 290, t['label'])
    p = Plot(f, 40, 40, 610, 230, -5, 5, 0, 0.42)
    p.xaxis(range(-5, 6), fmt=lambda v: str(v).replace('-', '−'), label=t['x'])
    p.curve(S.normal_pdf, -5, 5, stroke='--phosphor', width=2.2)
    p.curve(lambda x: t_pdf(x, 7), -5, 5, stroke='--paper', width=1.8, dash='6 3')
    p.curve(lambda x: t_pdf(x, 2), -5, 5, stroke='--amber', width=1.8, dash='2 3')
    for v, col in ((1.96, '--phosphor'), (S.t_inv(0.975, 7), '--paper'), (S.t_inv(0.975, 2), '--amber')):
        f.line(p.sx(v), p.y1, p.sx(v), p.y1 - 18, stroke=col, width=2)
        f.line(p.sx(-v), p.y1, p.sx(-v), p.y1 - 18, stroke=col, width=2)
    for i, (lab, col, dash) in enumerate(((t['normal'], '--phosphor', None), (t['t7'], '--paper', '6 3'),
                                          (t['t2'], '--amber', '2 3'))):
        y = 26 + i * 18
        f.line(410, y, 432, y, stroke=col, width=2, dash=dash)
        f.text(438, y, lab, size=9.5, anchor='start', fill=col if col != '--paper' else '--paper')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 13

def null_curve(f, p, df, regions, observed, lang, obs_label, region_label):
    """A t curve under the null with shaded rejection regions and the observed statistic."""
    pdf = lambda x: t_pdf(x, df)
    for lo, hi in regions:
        p.curve(pdf, max(lo, p.xmin), min(hi, p.xmax), fill='--amber')
    p.curve(pdf, p.xmin, p.xmax, stroke='--phosphor', width=2.2)
    f.line(p.sx(observed), p.y1, p.sx(observed), p.y0 + 10, stroke='--paper', width=2)
    f.text(p.sx(observed), p.y0, obs_label, size=10, weight='600')


@figure('l13-one-sided', 13)
def l13_one_sided(lang):
    x = S.ROUTING
    tt = (S.mean(x) - 40) / (S.sd(x) / math.sqrt(len(x)))
    crit = S.t_inv(0.05, 24)
    t = {'en': dict(
        label=f'The t distribution with 24 degrees of freedom, the shape the test statistic would '
              f'have if the new routing changed nothing. The left tail beyond −1.71 is shaded: the '
              f'5% of results that would count as evidence of faster deliveries. The observed '
              f'statistic, −1.00, is marked well inside the unshaded part.',
        obs='observed t = −1.00', reg='reject: the lowest 5%', x='t statistic', crit='−1.71',
        cap='The test asks where the observed statistic falls on the curve the null hypothesis '
            'predicts. Here it is in the ordinary middle, so the null is not rejected.'),
        'pt': dict(
        label=f'A distribuição t com 24 graus de liberdade, a forma que a estatística de teste teria '
              f'se o novo sistema de rotas não mudasse nada. A cauda esquerda além de −1,71 está '
              f'sombreada: os 5% de resultados que contariam como evidência de entregas mais '
              f'rápidas. A estatística observada, −1,00, está marcada bem dentro da parte sem sombra.',
        obs='t observado = −1,00', reg='rejeitar: os 5% mais baixos', x='estatística t', crit='−1,71',
        cap='O teste pergunta onde a estatística observada cai na curva que a hipótese nula prevê. '
            'Aqui ela fica no meio comum, então a nula não é rejeitada.')}[lang]
    f = Fig('l13-one-sided', 640, 280, t['label'])
    p = Plot(f, 40, 50, 610, 220, -4, 4, 0, 0.42)
    null_curve(f, p, 24, [(-4, crit)], tt, lang, t['obs'], t['reg'])
    p.xaxis(range(-4, 5), fmt=lambda v: str(v).replace('-', '−'), label=t['x'])
    f.text(p.sx(crit) - 6, p.sy(0.13), t['reg'], size=10, anchor='end', fill='--amber', weight='600')
    f.text(p.sx(crit), p.y1 - 10, t['crit'], size=9.5, anchor='start', fill='--amber')
    return f, t['cap']


@figure('l13-two-sided', 13)
def l13_two_sided(lang):
    b15 = S.BAGS[:15]
    tt = (S.mean(b15) - 1000) / (S.sd(b15) / math.sqrt(15))
    crit = S.t_inv(0.975, 14)
    t = {'en': dict(
        label='The t distribution with 14 degrees of freedom, for a machine exactly on its 1000 g '
              'target. Both tails beyond 2.14 standard errors are shaded, 2.5% each. The observed '
              'statistic for 15 bags, 4.21, lies far out in the right tail.',
        obs='observed t = 4.21', l='2.5%', r='2.5%', x='t statistic',
        cap='A two-sided test splits the 5% between both tails, because a machine overfilling and '
            'one underfilling are both off target.'),
        'pt': dict(
        label='A distribuição t com 14 graus de liberdade, para uma máquina exatamente no alvo de '
              '1000 g. As duas caudas além de 2,14 erros padrão estão sombreadas, 2,5% cada. A '
              'estatística observada para 15 sacos, 4,21, fica bem longe na cauda direita.',
        obs='t observado = 4,21', l='2,5%', r='2,5%', x='estatística t',
        cap='Um teste bilateral divide os 5% entre as duas caudas, porque uma máquina enchendo demais '
            'e uma enchendo de menos estão as duas fora do alvo.')}[lang]
    f = Fig('l13-two-sided', 640, 280, t['label'])
    p = Plot(f, 40, 50, 610, 220, -5, 5, 0, 0.42)
    null_curve(f, p, 14, [(-5, -crit), (crit, 5)], tt, lang, t['obs'], '')
    p.xaxis(range(-5, 6), fmt=lambda v: str(v).replace('-', '−'), label=t['x'])
    f.text(p.sx(-crit) - 8, p.sy(0.08), t['l'], size=10, anchor='end', fill='--amber', weight='600')
    f.text(p.sx(crit) + 8, p.sy(0.08), t['r'], size=10, anchor='start', fill='--amber', weight='600')
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
