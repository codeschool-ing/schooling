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
