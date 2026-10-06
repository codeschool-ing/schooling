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


# ------------------------------------------------------------------ lesson 14

@figure('l14-pvalue', 14)
def l14_pvalue(lang):
    x = S.ROUTING
    tt = (S.mean(x) - 40) / (S.sd(x) / math.sqrt(len(x)))
    p1 = S.t_cdf(tt, 24)
    t = {'en': dict(
        label=f'The t distribution with 24 degrees of freedom, as the null hypothesis predicts it. '
              f'The area to the left of the observed statistic, −1.00, is shaded. It is '
              f'{num("en", p1, 3)}: if the routing changed nothing, about one sample in six would '
              f'look at least this favourable to the supplier.',
        obs='observed t = −1.00', area=f'p = {num("en", p1, 3)}', x='t statistic',
        cap='The p-value is the area beyond what was observed, in the direction the alternative '
            'points. Here it is large: results like this are common when nothing has changed.'),
        'pt': dict(
        label=f'A distribuição t com 24 graus de liberdade, como a hipótese nula a prevê. A área à '
              f'esquerda da estatística observada, −1,00, está sombreada. Ela vale '
              f'{num("pt", p1, 3)}: se o sistema de rotas não mudasse nada, cerca de uma amostra em '
              f'seis pareceria pelo menos tão favorável ao fornecedor.',
        obs='t observado = −1,00', area=f'p = {num("pt", p1, 3)}', x='estatística t',
        cap='O p-valor é a área além do que se observou, na direção para onde a alternativa aponta. '
            'Aqui ele é grande: resultados assim são comuns quando nada mudou.')}[lang]
    f = Fig('l14-pvalue', 640, 280, t['label'])
    p = Plot(f, 40, 50, 610, 220, -4, 4, 0, 0.42)
    null_curve(f, p, 24, [(-4, tt)], tt, lang, t['obs'], '')
    p.xaxis(range(-4, 5), fmt=lambda v: str(v).replace('-', '−'), label=t['x'])
    f.text(p.sx(-2.1), p.sy(0.16), t['area'], size=11, anchor='end', fill='--amber', weight='600')
    return f, t['cap']


@figure('l14-batches', 14)
def l14_batches(lang):
    counts = S.null_batches()
    obs = [counts.count(k) for k in range(4)] + [sum(1 for c in counts if c >= 4)]
    exp_ = [1000 * S.binom_pmf(k, 20, 0.05) for k in range(4)]
    exp_.append(1000 - sum(exp_))
    t = {'en': dict(
        label='A bar chart of 1,000 batches of 20 tests, every test comparing two groups that '
              'differ by nothing but chance. 372 batches had no significant result, 394 had one, '
              '174 had two, 47 had three and 13 had four or more. Dots show what the binomial '
              'distribution predicts, and they sit close to the bars.',
        y='batches', x='tests in the batch with p below 0.05', four='4+', o='simulated batches',
        e='binomial, 20 tests at 5%',
        cap='Run twenty tests on nothing, and most of the time at least one comes out '
            '"significant". In 628 of the 1,000 batches, somebody would have had a finding.'),
        'pt': dict(
        label='Um gráfico de barras de 1.000 lotes de 20 testes, cada teste comparando dois grupos que '
              'só diferem por acaso. 372 lotes não tiveram nenhum resultado significativo, 394 tiveram '
              'um, 174 tiveram dois, 47 tiveram três e 13 tiveram quatro ou mais. Pontos mostram o que '
              'a distribuição binomial prevê, e ficam perto das barras.',
        y='lotes', x='testes do lote com p abaixo de 0,05', four='4+', o='lotes simulados',
        e='binomial, 20 testes a 5%',
        cap='Rode vinte testes sobre nada, e na maior parte das vezes pelo menos um sai '
            '"significativo". Em 628 dos 1.000 lotes, alguém teria tido uma descoberta.')}[lang]
    f = Fig('l14-batches', 600, 270, t['label'])
    p = Plot(f, 70, 50, 570, 210, -0.6, 4.6, 0, 450)
    p.yaxis(range(0, 451, 100), label=t['y'])
    for k, c in enumerate(obs):
        x0, x1 = p.sx(k - 0.3), p.sx(k + 0.3)
        f.path(f'M{x0:.1f} {p.y1:.1f} L{x0:.1f} {p.sy(c):.1f} L{x1:.1f} {p.sy(c):.1f} '
               f'L{x1:.1f} {p.y1:.1f} Z', stroke='--phosphor', width=1, fill='--phosphor-dim')
        f.text((x0 + x1) / 2, p.y1 + 13, t['four'] if k == 4 else str(k), size=10)
        f.circle(p.sx(k), p.sy(exp_[k]), 4.5, fill='--amber', stroke='--paper', width=0.8)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    f.text((p.x0 + p.x1) / 2, p.y1 + 33, t['x'], size=10, weight='600')
    f.path('M380 30 L394 30 L394 42 L380 42 Z', stroke='--phosphor', width=1, fill='--phosphor-dim')
    f.text(400, 36, t['o'], size=9.5, anchor='start')
    f.circle(387, 56, 4.5, fill='--amber', stroke='--paper', width=0.8)
    f.text(400, 56, t['e'], size=9.5, anchor='start', fill='--amber')
    return f, t['cap']


@figure('l14-duality', 14)
def l14_duality(lang):
    x = S.ROUTING
    m, se = S.mean(x), S.sd(x) / math.sqrt(len(x))
    c = S.t_inv(0.975, 24)
    b = S.BAGS[:15]
    mb, seb = S.mean(b), S.sd(b) / math.sqrt(15)
    cb = S.t_inv(0.975, 14)
    t = {'en': dict(
        label='Two rows, each a 95% confidence interval with the null value marked. Above, the '
              'routing deliveries: an interval from 36.62 to 41.18 minutes contains the null value '
              '40, and the two-sided p-value is 0.33. Below, the bags: an interval from 1002.26 to '
              '1006.94 g lies wholly above the null value 1000, and the two-sided p-value is '
              '0.0009.',
        r1='routing: p = 0.33', r2='bags: p = 0.0009', n1='null 40', n2='null 1000',
        u1='minutes', u2='grams',
        cap='An interval that contains the null value goes with p above 0.05; one that excludes '
            'it goes with p below. They are two views of the same calculation.'),
        'pt': dict(
        label='Duas linhas, cada uma um intervalo de confiança de 95% com o valor da nula marcado. Em '
              'cima, as entregas do sistema de rotas: um intervalo de 36,62 a 41,18 minutos contém o '
              'valor da nula, 40, e o p-valor bilateral é 0,33. Embaixo, os sacos: um intervalo de '
              '1002,26 a 1006,94 g fica inteiro acima do valor da nula, 1000, e o p-valor bilateral é '
              '0,0009.',
        r1='rotas: p = 0,33', r2='sacos: p = 0,0009', n1='nula 40', n2='nula 1000',
        u1='minutos', u2='gramas',
        cap='Um intervalo que contém o valor da nula anda junto com p acima de 0,05; um que o exclui, '
            'com p abaixo. São duas vistas da mesma conta.')}[lang]
    f = Fig('l14-duality', 640, 250, t['label'])
    rows = ((m - c * se, m + c * se, m, 40, 34, 46, t['r1'], t['n1'], t['u1'], 70),
            (mb - cb * seb, mb + cb * seb, mb, 1000, 998, 1010, t['r2'], t['n2'], t['u2'], 175))
    for lo, hi, mid, null, a, b_, lab, nlab, unit, y in rows:
        p = Plot(f, 160, y - 20, 610, y + 20, a, b_, 0, 1)
        f.line(p.x0, y + 22, p.x1, y + 22, stroke='--paper-dim')
        for v in range(int(a), int(b_) + 1, 2):
            f.line(p.sx(v), y + 22, p.sx(v), y + 26, stroke='--paper-dim', width=1)
            f.text(p.sx(v), y + 36, num(lang, v, 0) if v < 1000 else str(v), size=9, fill='--paper-dim')
        f.line(p.sx(lo), y, p.sx(hi), y, stroke='--phosphor', width=4, cap='round')
        f.circle(p.sx(mid), y, 3.5, fill='--paper')
        f.line(p.sx(null), y - 18, p.sx(null), y + 22, stroke='--amber', width=1.6, dash='4 3')
        f.text(p.sx(null), y - 26, nlab, size=9.5, fill='--amber')
        f.text(20, y, lab, size=10.5, anchor='start', weight='600')
        f.text(p.x1, y + 50, unit, size=9.5, anchor='end', fill='--paper-dim')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 15

@figure('l15-errors', 15)
def l15_errors(lang):
    t = {'en': dict(
        label='A two-by-two table. Columns: the test rejects the null, or does not. Rows: in truth '
              'there is no effect, or there is one. No effect and rejected: a type I error, a false '
              'alarm, with probability alpha. No effect and not rejected: correct. A real effect '
              'and rejected: correct, with probability equal to the power. A real effect and not '
              'rejected: a type II error, a missed effect, with probability beta.',
        cols=('the test rejects the null', 'the test keeps the null'),
        rows=('in truth, no effect', 'in truth, a real effect'),
        cells=(('type I error', 'a false alarm: α'), ('correct', 'probability 1 − α'),
               ('correct', 'the power: 1 − β'), ('type II error', 'a missed effect: β')),
        cap='Two ways to be right and two ways to be wrong. α is chosen; β depends on how big the '
            'effect is and how much data there is.'),
        'pt': dict(
        label='Uma tabela dois por dois. Colunas: o teste rejeita a nula, ou não. Linhas: na verdade '
              'não há efeito, ou há. Sem efeito e rejeitada: um erro tipo I, um alarme falso, com '
              'probabilidade alfa. Sem efeito e não rejeitada: correto. Efeito real e rejeitada: '
              'correto, com probabilidade igual ao poder. Efeito real e não rejeitada: um erro tipo '
              'II, um efeito perdido, com probabilidade beta.',
        cols=('o teste rejeita a nula', 'o teste mantém a nula'),
        rows=('na verdade, sem efeito', 'na verdade, efeito real'),
        cells=(('erro tipo I', 'um alarme falso: α'), ('correto', 'probabilidade 1 − α'),
               ('correto', 'o poder: 1 − β'), ('erro tipo II', 'um efeito perdido: β')),
        cap='Dois jeitos de acertar e dois de errar. α se escolhe; β depende do tamanho do efeito e '
            'de quantos dados existem.')}[lang]
    f = Fig('l15-errors', 640, 230, t['label'])
    x0, w, h = 190, 215, 70
    for j, c in enumerate(t['cols']):
        f.text(x0 + w * j + w / 2, 22, c, size=10.5, weight='600')
    for i, r in enumerate(t['rows']):
        y = 40 + i * (h + 10)
        f.text(20, y + h / 2, r, size=10.5, anchor='start', weight='600')
        for j in range(2):
            name, sub = t['cells'][i * 2 + j]
            bad = (i, j) in ((0, 0), (1, 1))
            f.rect(x0 + w * j + 4, y, w - 8, h, stroke='--amber' if bad else '--phosphor',
                   fill='--panel')
            f.text(x0 + w * j + w / 2, y + 26, name, size=11.5, weight='600',
                   fill='--amber' if bad else '--paper')
            f.text(x0 + w * j + w / 2, y + 46, sub, size=10, fill='--paper-dim')
    return f, t['cap']


@figure('l15-overlap', 15)
def l15_overlap(lang):
    se = 6 / 5
    crit = 40 + S.t_inv(0.05, 24) * se
    pdf0 = lambda x: S.normal_pdf((x - 40) / se) / se
    pdf1 = lambda x: S.normal_pdf((x - 38) / se) / se
    power = S.normal_cdf((crit - 38) / se)
    t = {'en': dict(
        label=f'Two bell curves of the sample mean of 25 deliveries, each with a standard error of '
              f'1.2 minutes. The right one, centred on 40, is what the null hypothesis predicts. The '
              f'left one, centred on 38, is what a real two-minute improvement would produce. A line '
              f'at {num("en", crit, 2)} minutes marks the critical value. Under the null, the area '
              f'left of it is 5%: alpha. Under the improvement, the area left of it is about '
              f'{100 * power:.0f}%: the power. The rest of the left curve, to the right of the line, '
              f'is beta.',
        h0='if nothing changed', h1='if 2 minutes faster', crit=f'reject below {num("en", crit, 2)}',
        x='mean of 25 deliveries, in minutes', a='α', pw=f'power ≈ {100 * power:.0f}%', b='β',
        cap='The same line cuts both curves. Moving it left lowers α and raises β; only more data, '
            'which narrows both curves, lowers both at once.'),
        'pt': dict(
        label=f'Duas curvas em sino da média amostral de 25 entregas, cada uma com erro padrão de 1,2 '
              f'minuto. A da direita, centrada em 40, é o que a hipótese nula prevê. A da esquerda, '
              f'centrada em 38, é o que uma melhora real de dois minutos produziria. Uma linha em '
              f'{num("pt", crit, 2)} minutos marca o valor crítico. Sob a nula, a área à esquerda dela '
              f'é 5%: alfa. Sob a melhora, a área à esquerda dela é cerca de {100 * power:.0f}%: o '
              f'poder. O resto da curva da esquerda, à direita da linha, é beta.',
        h0='se nada mudou', h1='se 2 minutos mais rápido', crit=f'rejeitar abaixo de {num("pt", crit, 2)}',
        x='média de 25 entregas, em minutos', a='α', pw=f'poder ≈ {100 * power:.0f}%', b='β',
        cap='A mesma linha corta as duas curvas. Movê-la para a esquerda baixa α e sobe β; só mais '
            'dados, que estreitam as duas curvas, baixam os dois de uma vez.')}[lang]
    f = Fig('l15-overlap', 660, 300, t['label'])
    p = Plot(f, 30, 60, 640, 240, 33, 45, 0, pdf0(40) * 1.1)
    p.curve(pdf1, 33, crit, fill='--phosphor-dim')
    p.curve(pdf0, 33, crit, fill='--amber')
    p.curve(pdf0, 33, 45, stroke='--paper', width=2)
    p.curve(pdf1, 33, 45, stroke='--phosphor', width=2, dash='6 3')
    p.xaxis(range(33, 46), label=t['x'])
    f.line(p.sx(crit), p.y1, p.sx(crit), 46, stroke='--amber', width=1.6, dash='4 3')
    f.text(p.sx(crit), 38, t['crit'], size=10, fill='--amber', weight='600')
    f.text(p.sx(41.6), p.sy(pdf0(41.6)) - 12, t['h0'], size=10, anchor='start')
    f.text(p.sx(36.3), p.sy(pdf1(36.3)) - 12, t['h1'], size=10, anchor='end', fill='--phosphor')
    f.text(p.sx(36.8), p.sy(0.06), t['pw'], size=10.5, anchor='end', fill='--phosphor', weight='600')
    f.text(p.sx(38.6), p.sy(0.035), t['b'], size=12, anchor='start', fill='--phosphor', weight='600')
    return f, t['cap']


@figure('l15-power-curve', 15)
def l15_power_curve(lang):
    t = {'en': dict(
        label='Three curves of power against the number of deliveries, from 5 to 300, for true '
              'improvements of 1, 2 and 3 minutes, with a standard deviation of 6 minutes and a '
              'one-sided test at 5%. A dashed line marks 80% power. The 3-minute curve crosses it at '
              'about 25 deliveries, the 2-minute curve at about 56, and the 1-minute curve at about '
              '223.',
        y='power', x='deliveries in the trial', g='{} min faster', eighty='80%',
        cap='The smaller the effect, the more data it takes to see it. Halving the effect '
            'quadruples the sample needed.'),
        'pt': dict(
        label='Três curvas de poder em função do número de entregas, de 5 a 300, para melhoras '
              'verdadeiras de 1, 2 e 3 minutos, com desvio padrão de 6 minutos e um teste unilateral a '
              '5%. Uma linha tracejada marca 80% de poder. A curva de 3 minutos a cruza em cerca de 25 '
              'entregas, a de 2 minutos em cerca de 56 e a de 1 minuto em cerca de 223.',
        y='poder', x='entregas no teste', g='{} min mais rápido', eighty='80%',
        cap='Quanto menor o efeito, mais dados para enxergá-lo. Cortar o efeito pela metade '
            'quadruplica a amostra necessária.')}[lang]
    f = Fig('l15-power-curve', 620, 290, t['label'])
    p = Plot(f, 70, 40, 590, 230, 0, 300, 0, 1)
    p.yaxis([0, 0.2, 0.4, 0.6, 0.8, 1.0], fmt=lambda v: f'{int(round(v * 100))}%', label=t['y'])
    p.xaxis(range(0, 301, 50), label=t['x'])
    f.line(p.x0, p.sy(0.8), p.x1, p.sy(0.8), stroke='--paper-dim', width=1.2, dash='4 3')
    styles = {1: ('--amber', '2 3'), 2: ('--phosphor', None), 3: ('--paper', '6 3')}
    for g in (1, 2, 3):
        col, dash = styles[g]
        p.curve(lambda n, g=g: S.normal_power(g, n), 5, 300, stroke=col, width=2.2, dash=dash)
    for i, g in enumerate((3, 2, 1)):
        col, dash = styles[g]
        y = p.sy(0.32) + i * 18
        f.line(p.sx(205), y, p.sx(225), y, stroke=col, width=2.2, dash=dash)
        f.text(p.sx(230), y, t['g'].format(g), size=10, anchor='start',
               fill='--paper' if col == '--paper' else col)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 16

@figure('l16-choose', 16)
def l16_choose(lang):
    t = {'en': dict(
        label='A decision tree for choosing a test. First question: is the outcome numerical or '
              'categorical? For a categorical outcome, use the chi-square test. For a numerical one, '
              'ask how many groups. One group against a fixed value: the one-sample t test. Two '
              'groups: if the same units are measured twice, the paired t test, with the Wilcoxon '
              'signed-rank test as the rank-based alternative; if the groups are separate, Welch’s '
              't test, with the Mann-Whitney test as the alternative. Three or more groups: ANOVA, '
              'with the Kruskal-Wallis test as the alternative.',
        q='what is the outcome?', num='numerical', cat='categorical: counts in a table',
        chi='chi-square test', one='one group vs a value', two_p='two groups, same units twice',
        two_i='two separate groups', many='three or more groups', t1='one-sample t',
        tp='paired t', ti='Welch’s t', an='ANOVA', np_='if ranks are safer:',
        wp='Wilcoxon signed-rank', mw='Mann-Whitney', kw='Kruskal-Wallis',
        cap='Two questions pick most tests: what kind of outcome, and how many groups. A rank-based '
            'alternative sits under each test of means, for small or awkward samples.'),
        'pt': dict(
        label='Uma árvore de decisão para escolher um teste. Primeira pergunta: o resultado é numérico '
              'ou categórico? Para um resultado categórico, use o teste qui-quadrado. Para um numérico, '
              'pergunte quantos grupos. Um grupo contra um valor fixo: o teste t de uma amostra. Dois '
              'grupos: se as mesmas unidades são medidas duas vezes, o teste t pareado, com o teste de '
              'postos sinalizados de Wilcoxon como alternativa baseada em postos; se os grupos são '
              'separados, o teste t de Welch, com o teste de Mann-Whitney como alternativa. Três ou '
              'mais grupos: ANOVA, com o teste de Kruskal-Wallis como alternativa.',
        q='qual é o resultado?', num='numérico', cat='categórico: contagens numa tabela',
        chi='teste qui-quadrado', one='um grupo vs um valor', two_p='dois grupos, mesmas unidades',
        two_i='dois grupos separados', many='três ou mais grupos', t1='t de uma amostra',
        tp='t pareado', ti='t de Welch', an='ANOVA', np_='se postos forem mais seguros:',
        wp='postos sinalizados de Wilcoxon', mw='Mann-Whitney', kw='Kruskal-Wallis',
        cap='Duas perguntas escolhem a maioria dos testes: que tipo de resultado, e quantos grupos. '
            'Uma alternativa baseada em postos fica sob cada teste de médias, para amostras pequenas '
            'ou difíceis.')}[lang]
    f = Fig('l16-choose', 690, 330, t['label'])
    f.rect(260, 10, 170, 32, stroke='--amber')
    f.text(345, 26, t['q'], size=10.5, weight='600', fill='--amber')
    f.rect(40, 70, 230, 32, stroke='--phosphor')
    f.text(155, 86, t['num'], size=10.5, weight='600')
    f.rect(440, 70, 230, 32, stroke='--phosphor')
    f.text(555, 86, t['cat'], size=10, weight='600')
    f.rect(470, 132, 170, 32, stroke='--wire', fill='--scan')
    f.text(555, 148, t['chi'], size=10.5, weight='600')
    f.path('M345 42 L345 56 L155 56 L155 68', arrow=True)
    f.path('M345 56 L555 56 L555 68', arrow=True)
    f.line(555, 102, 555, 130, arrow=True)
    cols = [(85, t['one'], t['t1'], None), (250, t['two_p'], t['tp'], t['wp']),
            (415, t['two_i'], t['ti'], t['mw']), (580, t['many'], t['an'], t['kw'])]
    for x, lab, test, alt in cols:
        f.rect(x - 80, 190, 160, 32, stroke='--wire')
        f.text(x, 206, lab, size=9.5)
        f.rect(x - 80, 238, 160, 30, stroke='--wire', fill='--scan')
        f.text(x, 253, test, size=10.5, weight='600')
        f.line(x, 222, x, 236, arrow=True)
        if alt:
            f.text(x, 292, t['np_'], size=8.5, fill='--paper-dim')
            f.text(x, 308, alt, size=9.5, fill='--phosphor')
    f.path('M155 102 L155 176 L85 176 L85 188', arrow=True)
    f.path('M155 176 L250 176 L250 188', arrow=True)
    f.path('M250 176 L415 176 L415 188', arrow=True)
    f.path('M415 176 L580 176 L580 188', arrow=True)
    return f, t['cap']


@figure('l16-paired', 16)
def l16_paired(lang):
    b, a = S.TRAIN_BEFORE, S.TRAIN_AFTER
    down = sum(1 for x, y in zip(b, a) if y < x)
    t = {'en': dict(
        label=f'Ten couriers, each drawn as a line from their mean delivery time in the month before '
              f'the training, on the left, to the month after, on the right. The couriers differ '
              f'from one another by several minutes, from about 33 to 42. {down} of the 10 lines slope '
              f'down; the average change is a fall of 1.21 minutes.',
        before='before', after='after', y='minutes',
        cap='The couriers differ from each other far more than each one changes. Pairing compares '
            'each courier with themselves, and removes that difference from the noise.'),
        'pt': dict(
        label=f'Dez entregadores, cada um desenhado como uma linha do tempo médio de entrega no mês '
              f'antes do treinamento, à esquerda, até o mês depois, à direita. Os entregadores diferem '
              f'entre si em vários minutos, de uns 33 a 42. {down} das 10 linhas descem; a mudança '
              f'média é uma queda de 1,21 minuto.',
        before='antes', after='depois', y='minutos',
        cap='Os entregadores diferem entre si muito mais do que cada um muda. Parear compara cada '
            'entregador consigo mesmo, e tira essa diferença do ruído.')}[lang]
    f = Fig('l16-paired', 460, 300, t['label'])
    p = Plot(f, 80, 40, 400, 260, 0, 1, 31, 44)
    p.yaxis(range(32, 45, 2), label=t['y'])
    for x, y in zip(b, a):
        col = '--phosphor' if y < x else '--amber'
        f.line(p.sx(0.1), p.sy(x), p.sx(0.9), p.sy(y), stroke=col, width=1.8)
        f.circle(p.sx(0.1), p.sy(x), 4, fill=col)
        f.circle(p.sx(0.9), p.sy(y), 4, fill=col)
    f.text(p.sx(0.1), p.y1 + 18, t['before'], size=10.5, weight='600')
    f.text(p.sx(0.9), p.y1 + 18, t['after'], size=10.5, weight='600')
    return f, t['cap']


@figure('l16-anova', 16)
def l16_anova(lang):
    g = [(h, [r['minutes'] for r in S.DELIVERIES if r['hood'] == h]) for h, _, _ in S.HOODS]
    grand = S.mean([x for _, xs in g for x in xs])
    t = {'en': dict(
        label=f'The 120 deliveries as four columns of dots, one per neighbourhood, with a short bar '
              f'at each neighbourhood’s mean and a dashed line across at the overall mean, '
              f'{num("en", grand, 2)} minutes. The neighbourhood means sit far apart compared with '
              f'how much the dots spread within each column.',
        y='minutes', grand=f'overall mean {num("en", grand, 2)}',
        cap='ANOVA compares two spreads: how far the group means sit from the overall mean, and how '
            'far the values sit from their own group mean. Here the first dwarfs the second.'),
        'pt': dict(
        label=f'As 120 entregas como quatro colunas de pontos, uma por bairro, com uma barra curta na '
              f'média de cada bairro e uma linha tracejada atravessando na média geral, '
              f'{num("pt", grand, 2)} minutos. As médias dos bairros ficam muito separadas comparadas '
              f'com quanto os pontos se espalham dentro de cada coluna.',
        y='minutos', grand=f'média geral {num("pt", grand, 2)}',
        cap='A ANOVA compara duas dispersões: quão longe as médias dos grupos ficam da média geral, e '
            'quão longe os valores ficam da média do próprio grupo. Aqui a primeira é muito maior que '
            'a segunda.')}[lang]
    f = Fig('l16-anova', 600, 300, t['label'])
    p = Plot(f, 70, 40, 580, 250, 0.4, 4.6, 20, 70)
    p.yaxis(range(20, 71, 10), label=t['y'])
    d = S.Draw(16)
    for i, (h, xs) in enumerate(g):
        cx = i + 1
        for x in xs:
            f.circle(p.sx(cx + d.uniform(-0.18, 0.18)), p.sy(x), 2.8, fill='--phosphor-dim', stroke='--phosphor', width=0.6)
        m = S.mean(xs)
        f.line(p.sx(cx - 0.3), p.sy(m), p.sx(cx + 0.3), p.sy(m), stroke='--amber', width=3)
        f.text(p.sx(cx), p.y1 + 16, h, size=10)
    f.line(p.x0, p.sy(grand), p.x1, p.sy(grand), stroke='--paper', width=1.2, dash='5 4')
    f.text(p.x1, p.sy(grand) - 8, t['grand'], size=9.5, anchor='end')
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    return f, t['cap']


# ----------------------------------------------------------------- lesson 17

def dots(f, p, xs, ys, r=2.8, fill='--phosphor-dim', stroke='--phosphor'):
    for x, y in zip(xs, ys):
        f.circle(p.sx(x), p.sy(y), r, fill=fill, stroke=stroke, width=0.7)


@figure('l17-scatter', 17)
def l17_scatter(lang):
    km = [r['km'] for r in S.DELIVERIES]
    mn = [r['minutes'] for r in S.DELIVERIES]
    t = {'en': dict(
        label='A scatter plot of the 120 deliveries, distance in kilometres across and minutes up. '
              'The points form a band rising from about 25 minutes at 1 km to about 60 minutes at '
              '13 km, with a few minutes of scatter around it at every distance.',
        x='distance (km)', y='minutes',
        cap='Each point is one delivery. The cloud rises from left to right, and it is narrow: '
            'distance says a lot about how long a delivery takes.'),
        'pt': dict(
        label='Um gráfico de dispersão das 120 entregas, distância em quilômetros na horizontal e '
              'minutos na vertical. Os pontos formam uma faixa que sobe de uns 25 minutos a 1 km até '
              'uns 60 minutos a 13 km, com alguns minutos de espalhamento em cada distância.',
        x='distância (km)', y='minutos',
        cap='Cada ponto é uma entrega. A nuvem sobe da esquerda para a direita, e é estreita: a '
            'distância diz muito sobre quanto uma entrega demora.')}[lang]
    f = Fig('l17-scatter', 600, 320, t['label'])
    p = Plot(f, 70, 36, 580, 260, 0, 14, 20, 75)
    p.yaxis(range(20, 76, 10), label=t['y'])
    p.xaxis(range(0, 15, 2), label=t['x'])
    dots(f, p, km, mn)
    return f, t['cap']


@figure('l17-quadrants', 17)
def l17_quadrants(lang):
    it, bk = S.column('items'), S.column('basket')
    mi, mb = S.mean(it), S.mean(bk)
    t = {'en': dict(
        label=f'The twelve orders, items across and basket up, with a dashed line at the mean of '
              f'each: {num("en", mi, 2)} items and R$ {num("en", mb, 2)}. Every point sits in the '
              f'top-right or bottom-left quarter, where the two deviations have the same sign.',
        x='items', y='basket (R$)', tr='both above: product +', bl='both below: product +',
        tl='product −', br='product −',
        mi=f'mean {num("en", mi, 2)}', mb=f'mean {num("en", mb, 2)}',
        cap='Correlation multiplies each point’s two deviations from the means. In the shaded '
            'quarters the product is positive; in the other two it is negative. Here every order '
            'lands in a positive quarter.'),
        'pt': dict(
        label=f'Os doze pedidos, itens na horizontal e cesta na vertical, com uma linha tracejada '
              f'na média de cada um: {num("pt", mi, 2)} itens e R$ {num("pt", mb, 2)}. Todo ponto '
              f'fica no quarto de cima à direita ou no de baixo à esquerda, onde os dois desvios '
              f'têm o mesmo sinal.',
        x='itens', y='cesta (R$)', tr='os dois acima: produto +', bl='os dois abaixo: produto +',
        tl='produto −', br='produto −',
        mi=f'média {num("pt", mi, 2)}', mb=f'média {num("pt", mb, 2)}',
        cap='A correlação multiplica os dois desvios de cada ponto em relação às médias. Nos '
            'quartos sombreados o produto é positivo; nos outros dois, negativo. Aqui todo pedido '
            'cai num quarto positivo.')}[lang]
    f = Fig('l17-quadrants', 600, 340, t['label'])
    p = Plot(f, 80, 40, 570, 270, 0, 16, 0, 240)
    xm, ym = p.sx(mi), p.sy(mb)
    f.path(f'M{xm:.1f} {p.y0:.1f} L{p.x1:.1f} {p.y0:.1f} L{p.x1:.1f} {ym:.1f} L{xm:.1f} {ym:.1f} Z',
           stroke=None, width=0, fill='--scan')
    f.path(f'M{p.x0:.1f} {ym:.1f} L{xm:.1f} {ym:.1f} L{xm:.1f} {p.y1:.1f} L{p.x0:.1f} {p.y1:.1f} Z',
           stroke=None, width=0, fill='--scan')
    p.yaxis(range(0, 241, 40), label=t['y'], grid=False)
    p.xaxis(range(0, 17, 2), label=t['x'])
    f.line(xm, p.y0, xm, p.y1, stroke='--amber', width=1.4, dash='5 4')
    f.line(p.x0, ym, p.x1, ym, stroke='--amber', width=1.4, dash='5 4')
    f.text(xm + 6, p.y0 + 8, t['mi'], size=9.5, anchor='start', fill='--amber')
    f.text(p.x1 - 4, ym - 9, t['mb'], size=9.5, anchor='end', fill='--amber')
    f.text(xm + 8, p.y0 + 30, t['tr'], size=10, anchor='start')
    f.text(p.x0 + 8, p.sy(68), t['bl'], size=10, anchor='start')
    f.text(p.x0 + 8, p.y0 + 30, t['tl'], size=10, anchor='start', fill='--paper-dim')
    f.text(p.x1 - 6, p.y1 - 12, t['br'], size=10, anchor='end', fill='--paper-dim')
    dots(f, p, it, bk, r=4)
    return f, t['cap']


@figure('l17-gallery', 17)
def l17_gallery(lang):
    t = {'en': dict(
        label='Six small scatter plots of sixty points each, with correlations of −0.90, −0.50, '
              '0, 0.30, 0.70 and 0.95. The strong negative cloud is a narrow band falling to the '
              'right, the zero cloud is a round blob, and the 0.95 cloud is a narrow band rising.',
        cap='Six clouds and their correlation. The sign is the direction; the size is how tightly '
            'the points hug a straight line. Note how little a correlation of 0.30 looks like '
            'anything.'),
        'pt': dict(
        label='Seis gráficos de dispersão pequenos de sessenta pontos cada, com correlações de '
              '−0,90, −0,50, 0, 0,30, 0,70 e 0,95. A nuvem negativa forte é uma faixa estreita '
              'descendo para a direita, a nuvem zero é uma bolha redonda, e a de 0,95 é uma faixa '
              'estreita subindo.',
        cap='Seis nuvens e sua correlação. O sinal é a direção; o tamanho é quão justos os pontos '
            'ficam em torno de uma reta. Repare como uma correlação de 0,30 quase não parece '
            'nada.')}[lang]
    f = Fig('l17-gallery', 600, 380, t['label'])
    for i, rho in enumerate(S.GALLERY_R):
        col, row = i % 3, i // 3
        x0, y0 = 20 + col * 195, 14 + row * 182
        f.rect(x0, y0, 180, 168, stroke='--wire', fill='--panel', rx=4)
        p = Plot(f, x0 + 10, y0 + 30, x0 + 170, y0 + 160, -3.2, 3.2, -3.2, 3.2)
        xs, ys = S.gallery(rho)
        dots(f, p, xs, ys, r=2.2)
        sign = '−' if rho < 0 else ''
        f.text(x0 + 90, y0 + 16, f'r = {sign}{num(lang, abs(rho), 2)}', size=11, weight='600')
    return f, t['cap']


@figure('l17-anscombe', 17)
def l17_anscombe(lang):
    t = {'en': dict(
        label='Anscombe’s four data sets, each drawn with the same fitted line. I is a loose '
              'straight-line cloud. II is a smooth curve that rises and bends back down. III is a '
              'perfect straight line with one point far above it. IV has ten points stacked at '
              'x = 8 and one point far to the right at x = 19.',
        cap='Four data sets with the same means, the same standard deviations, the same '
            'correlation, 0.816, and the same line. Only one of them is described well by that '
            'number.'),
        'pt': dict(
        label='Os quatro conjuntos de Anscombe, cada um desenhado com a mesma reta ajustada. I é '
              'uma nuvem solta em linha reta. II é uma curva suave que sobe e volta a descer. III '
              'é uma reta perfeita com um ponto muito acima dela. IV tem dez pontos empilhados em '
              'x = 8 e um ponto muito à direita em x = 19.',
        cap='Quatro conjuntos com as mesmas médias, os mesmos desvios padrão, a mesma correlação, '
            '0,816, e a mesma reta. Só um deles é bem descrito por esse número.')}[lang]
    f = Fig('l17-anscombe', 600, 420, t['label'])
    for i, (xs, ys) in enumerate(S.ANSCOMBE):
        col, row = i % 2, i // 2
        x0, y0 = 50 + col * 290, 20 + row * 200
        p = Plot(f, x0, y0 + 20, x0 + 240, y0 + 160, 2, 20, 2, 14)
        p.yaxis(range(4, 15, 4), grid=False, size=9)
        p.xaxis(range(4, 21, 4), size=9)
        a, b = S.line(xs, ys)
        f.line(p.sx(3), p.sy(a + b * 3), p.sx(19.5), p.sy(a + b * 19.5), stroke='--amber', width=1.6)
        dots(f, p, xs, ys, r=3.4)
        f.text(x0 + 4, y0 + 10, ['I', 'II', 'III', 'IV'][i], size=12, weight='600', anchor='start')
    return f, t['cap']


@figure('l17-monotone', 17)
def l17_monotone(lang):
    xs, ys = S.DISCOUNT, S.DISCOUNT_ORDERS
    r, rho = S.pearson(xs, ys), S.spearman(xs, ys)
    t = {'en': dict(
        label=f'Orders in a week against the discount offered, from 0% to 20%. Orders climb '
              f'quickly at first and then flatten near 660. Every step up in discount gives more '
              f'orders, but less each time. Pearson’s r is {num("en", r, 2)}; Spearman’s is '
              f'{num("en", rho, 2)}.',
        x='discount (%)', y='orders in the week',
        pr=f'Pearson {num("en", r, 2)}', sr=f'Spearman {num("en", rho, 2)}',
        cap='Every increase in discount brings more orders, so the ranks agree perfectly and '
            'Spearman’s coefficient is exactly 1. The points do not lie on a straight line, so '
            'Pearson’s is lower.'),
        'pt': dict(
        label=f'Pedidos numa semana contra o desconto oferecido, de 0% a 20%. Os pedidos sobem '
              f'rápido no começo e depois se achatam perto de 660. Cada degrau de desconto traz '
              f'mais pedidos, mas menos a cada vez. O r de Pearson é {num("pt", r, 2)}; o de '
              f'Spearman é {num("pt", rho, 2)}.',
        x='desconto (%)', y='pedidos na semana',
        pr=f'Pearson {num("pt", r, 2)}', sr=f'Spearman {num("pt", rho, 2)}',
        cap='Todo aumento de desconto traz mais pedidos, então os postos concordam perfeitamente '
            'e o coeficiente de Spearman é exatamente 1. Os pontos não ficam numa reta, então o '
            'de Pearson é menor.')}[lang]
    f = Fig('l17-monotone', 600, 320, t['label'])
    p = Plot(f, 80, 36, 580, 260, 0, 20, 380, 680)
    p.yaxis(range(400, 681, 50), label=t['y'])
    p.xaxis(range(0, 21, 4), label=t['x'])
    a, b = S.line(xs, ys)
    f.line(p.sx(0), p.sy(a), p.sx(20), p.sy(a + 20 * b), stroke='--paper-dim', width=1.2, dash='5 4')
    f.path('M' + ' L'.join(f'{p.sx(x):.1f} {p.sy(y):.1f}' for x, y in zip(xs, ys)),
           stroke='--phosphor', width=1.4)
    dots(f, p, xs, ys, r=4)
    f.text(p.x1 - 6, p.sy(470), t['pr'], size=11, anchor='end', weight='600')
    f.text(p.x1 - 6, p.sy(440), t['sr'], size=11, anchor='end', weight='600', fill='--amber')
    return f, t['cap']


@figure('l17-range', 17)
def l17_range(lang):
    near = [r for r in S.DELIVERIES if r['hood'] in ('Centro', 'Cambuí')]
    far = [r for r in S.DELIVERIES if r['hood'] not in ('Centro', 'Cambuí')]
    ra = S.pearson([r['km'] for r in S.DELIVERIES], [r['minutes'] for r in S.DELIVERIES])
    rn = S.pearson([r['km'] for r in near], [r['minutes'] for r in near])
    t = {'en': dict(
        label=f'The 120 deliveries again, with the 60 to Centro and Cambuí, all under 4.5 km, '
              f'drawn solid inside a shaded band and the rest drawn hollow. Across all 120 the '
              f'correlation is {num("en", ra, 2)}; inside the band it is {num("en", rn, 2)}.',
        x='distance (km)', y='minutes',
        all=f'all 120: r = {num("en", ra, 2)}', near=f'Centro and Cambuí: r = {num("en", rn, 2)}',
        cap='The same relationship, seen through a narrow window. Within a few kilometres, the '
            'noise of traffic and order size is as large as the effect of distance, and the '
            'correlation falls.'),
        'pt': dict(
        label=f'As 120 entregas de novo, com as 60 para Centro e Cambuí, todas abaixo de 4,5 km, '
              f'desenhadas cheias dentro de uma faixa sombreada e o resto desenhado vazado. Nas '
              f'120 a correlação é {num("pt", ra, 2)}; dentro da faixa é {num("pt", rn, 2)}.',
        x='distância (km)', y='minutos',
        all=f'todas as 120: r = {num("pt", ra, 2)}', near=f'Centro e Cambuí: r = {num("pt", rn, 2)}',
        cap='A mesma relação, vista por uma janela estreita. Em poucos quilômetros, o ruído do '
            'trânsito e do tamanho do pedido é tão grande quanto o efeito da distância, e a '
            'correlação cai.')}[lang]
    f = Fig('l17-range', 600, 320, t['label'])
    p = Plot(f, 70, 36, 580, 260, 0, 14, 20, 75)
    f.path(f'M{p.sx(0.8):.1f} {p.y0:.1f} L{p.sx(4.5):.1f} {p.y0:.1f} L{p.sx(4.5):.1f} {p.y1:.1f} '
           f'L{p.sx(0.8):.1f} {p.y1:.1f} Z', stroke=None, width=0, fill='--scan')
    p.yaxis(range(20, 76, 10), label=t['y'])
    p.xaxis(range(0, 15, 2), label=t['x'])
    for r in far:
        f.circle(p.sx(r['km']), p.sy(r['minutes']), 2.8, fill=None, stroke='--paper-dim', width=1)
    dots(f, p, [r['km'] for r in near], [r['minutes'] for r in near])
    f.text(p.x1 - 6, p.y1 - 40, t['all'], size=11, anchor='end', weight='600')
    f.text(p.x1 - 6, p.y1 - 20, t['near'], size=11, anchor='end', weight='600', fill='--amber')
    return f, t['cap']


@figure('l17-lever', 17)
def l17_lever(lang):
    d = S.Draw(1717)
    lx = [round(d.uniform(1, 3), 1) for _ in range(10)]
    ly = [round(d.uniform(30, 36), 1) for _ in range(10)]
    r0 = S.pearson(lx, ly)
    r1 = S.pearson(lx + [12], ly + [60])

    def signed(lang_, v):
        return ('−' if v < 0 else '') + num(lang_, abs(v), 2)
    t = {'en': dict(
        label=f'Ten points clustered between 1 and 3 on the horizontal axis and 30 and 36 on the '
              f'vertical, with no pattern among them, and one point far away at 12 and 60. A line '
              f'drawn through all eleven runs from the cluster to the lone point. Without that '
              f'point the correlation is {signed("en", r0)}; with it, {num("en", r1, 2)}.',
        without=f'the ten alone: r = {signed("en", r0)}', with_=f'all eleven: r = {num("en", r1, 2)}',
        lone='one point',
        cap='One point far from the rest can manufacture a correlation out of nothing. Spearman’s '
            'coefficient for the eleven is 0.14, because to ranks the lone point is just the top '
            'rank on each axis.'),
        'pt': dict(
        label=f'Dez pontos agrupados entre 1 e 3 no eixo horizontal e 30 e 36 no vertical, sem '
              f'padrão entre eles, e um ponto muito longe, em 12 e 60. Uma reta passando pelos onze '
              f'vai do grupo até o ponto isolado. Sem esse ponto a correlação é {signed("pt", r0)}; '
              f'com ele, {num("pt", r1, 2)}.',
        without=f'só os dez: r = {signed("pt", r0)}', with_=f'os onze: r = {num("pt", r1, 2)}',
        lone='um ponto',
        cap='Um ponto longe dos outros pode fabricar uma correlação do nada. O coeficiente de '
            'Spearman dos onze é 0,14, porque, em postos, o ponto isolado é só o posto mais alto '
            'em cada eixo.')}[lang]
    f = Fig('l17-lever', 600, 300, t['label'])
    p = Plot(f, 60, 30, 580, 250, 0, 14, 25, 65)
    p.yaxis(range(25, 66, 10))
    p.xaxis(range(0, 15, 2))
    a, b = S.line(lx + [12], ly + [60])
    f.line(p.sx(0.5), p.sy(a + 0.5 * b), p.sx(13), p.sy(a + 13 * b), stroke='--amber', width=1.6)
    dots(f, p, lx, ly, r=3.6)
    f.circle(p.sx(12), p.sy(60), 4.5, fill='--amber', stroke='--amber')
    f.text(p.sx(12) - 10, p.sy(60), t['lone'], size=10, anchor='end')
    f.text(p.sx(5), p.sy(41), t['without'], size=11, anchor='start', weight='600')
    f.text(p.sx(5), p.sy(37), t['with_'], size=11, anchor='start', weight='600', fill='--amber')
    return f, t['cap']


# ----------------------------------------------------------------- lesson 18

def node(f, cx, cy, w, label, h=34, stroke='--phosphor', weight='600'):
    f.rect(cx - w / 2, cy - h / 2, w, h, stroke=stroke, fill='--panel', rx=6)
    f.text(cx, cy, label, size=11, weight=weight)


@figure('l18-confounder', 18)
def l18_confounder(lang):
    r = S.pearson(S.COUPONS, [d['minutes'] for d in S.DELIVERIES])
    t = {'en': dict(
        label=f'A diagram of three boxes. Distance sits at the top, with an arrow down to coupon on '
              f'the left, labelled coupons are sent to far neighbourhoods, and an arrow down to '
              f'minutes on the right, labelled far takes longer. Between coupon and minutes there '
              f'is a dashed line with no arrowhead, labelled correlation {num("en", r, 2)}, no '
              f'cause.',
        dist='distance', coupon='coupon', mins='minutes',
        a='sent to far neighbourhoods', b='far takes longer',
        c=f'r = {num("en", r, 2)}, no arrow',
        cap='Distance is a common cause of both. It makes a coupon more likely and a delivery '
            'longer, so coupons and long deliveries go together without either causing the '
            'other.'),
        'pt': dict(
        label=f'Um diagrama de três caixas. Distância fica no alto, com uma seta descendo para cupom '
              f'à esquerda, rotulada cupons vão para bairros distantes, e uma seta descendo para '
              f'minutos à direita, rotulada longe demora mais. Entre cupom e minutos há uma linha '
              f'tracejada sem ponta de seta, rotulada correlação {num("pt", r, 2)}, sem causa.',
        dist='distância', coupon='cupom', mins='minutos',
        a='vão para bairros distantes', b='longe demora mais',
        c=f'r = {num("pt", r, 2)}, sem seta',
        cap='A distância é causa comum dos dois. Ela torna um cupom mais provável e uma entrega '
            'mais longa, então cupons e entregas longas andam juntos sem que um cause o outro.')}[lang]
    f = Fig('l18-confounder', 600, 250, t['label'])
    node(f, 300, 40, 140, t['dist'])
    node(f, 110, 190, 130, t['coupon'])
    node(f, 490, 190, 130, t['mins'])
    f.line(260, 57, 140, 171, stroke='--paper', width=1.6, arrow=True)
    f.line(340, 57, 460, 171, stroke='--paper', width=1.6, arrow=True)
    f.text(186, 104, t['a'], size=10, anchor='end')
    f.text(414, 104, t['b'], size=10, anchor='start')
    f.line(178, 190, 422, 190, stroke='--amber', width=1.6, dash='6 4')
    f.text(300, 178, t['c'], size=10, fill='--amber')
    return f, t['cap']


@figure('l18-coupon', 18)
def l18_coupon(lang):
    mins = [r['minutes'] for r in S.DELIVERIES]
    rows = [('all', [(m, c) for m, c in zip(mins, S.COUPONS)])]
    for h, _, _ in S.HOODS:
        rows.append((h, [(r['minutes'], c) for r, c in zip(S.DELIVERIES, S.COUPONS) if r['hood'] == h]))
    t = {'en': dict(
        label='Mean delivery minutes with and without a coupon, for all 120 deliveries and then for '
              'each neighbourhood. Overall, deliveries with a coupon average about 46 minutes and '
              'those without about 36, ten minutes apart. Within each neighbourhood the two means '
              'sit within about two minutes of each other.',
        all='all 120', x='mean minutes', w='with coupon', wo='without',
        cap='Overall, a coupon goes with deliveries ten minutes longer. Within each neighbourhood '
            'the gap all but disappears: the ten minutes were distance, not the coupon.'),
        'pt': dict(
        label='Média de minutos de entrega com e sem cupom, para as 120 entregas e depois para cada '
              'bairro. No geral, entregas com cupom têm média de uns 46 minutos e as sem, uns 36, '
              'dez minutos de distância. Dentro de cada bairro as duas médias ficam a uns dois '
              'minutos uma da outra.',
        all='todas as 120', x='média de minutos', w='com cupom', wo='sem',
        cap='No geral, um cupom anda com entregas dez minutos mais longas. Dentro de cada bairro a '
            'diferença quase some: os dez minutos eram a distância, não o cupom.')}[lang]
    f = Fig('l18-coupon', 600, 300, t['label'])
    p = Plot(f, 150, 40, 580, 240, 25, 60, 0, 5)
    p.xaxis(range(25, 61, 5), label=t['x'])
    for i, (name, data) in enumerate(rows):
        y = 58 + i * 40 + (8 if i else 0)
        a = S.mean([m for m, c in data if c])
        b = S.mean([m for m, c in data if not c])
        f.line(p.x0, y, p.x1, y, stroke='--wire', width=1)
        f.line(p.sx(min(a, b)), y, p.sx(max(a, b)), y, stroke='--paper-dim', width=2)
        f.circle(p.sx(b), y, 5, fill='--panel', stroke='--paper', width=1.6)
        f.circle(p.sx(a), y, 5, fill='--amber', stroke='--amber')
        f.text(p.x0 - 10, y, t['all'] if name == 'all' else name, size=10.5, anchor='end',
               weight='600' if name == 'all' else None)
    f.circle(160, 20, 5, fill='--amber', stroke='--amber')
    f.text(171, 20, t['w'], size=10, anchor='start')
    f.circle(280, 20, 5, fill='--panel', stroke='--paper', width=1.6)
    f.text(291, 20, t['wo'], size=10, anchor='start')
    return f, t['cap']


@figure('l18-simpson', 18)
def l18_simpson(lang):
    V = ('motorbike', 'bicycle')
    rate = {}
    for v in V:
        for b in ('near', 'far'):
            on, n = S.SIMPSON[(v, b)]
            rate[(v, b)] = on / n
        on = sum(S.SIMPSON[(v, b)][0] for b in ('near', 'far'))
        n = sum(S.SIMPSON[(v, b)][1] for b in ('near', 'far'))
        rate[(v, 'all')] = on / n
    t = {'en': dict(
        label=f'On-time rates for motorbikes and bicycles. Near: motorbike '
              f'{num("en", 100 * rate[("motorbike", "near")], 1)}%, bicycle '
              f'{num("en", 100 * rate[("bicycle", "near")], 1)}%. Far: motorbike '
              f'{num("en", 100 * rate[("motorbike", "far")], 1)}%, bicycle '
              f'{num("en", 100 * rate[("bicycle", "far")], 1)}%. All deliveries: motorbike '
              f'{num("en", 100 * rate[("motorbike", "all")], 1)}%, bicycle '
              f'{num("en", 100 * rate[("bicycle", "all")], 1)}%.',
        groups={'near': 'near', 'far': 'far', 'all': 'all deliveries'},
        v={'motorbike': 'motorbike', 'bicycle': 'bicycle'}, y='on time (%)',
        cap='Motorbikes are on time more often near and more often far, and less often overall. '
            'They do most of the far deliveries, where everybody is late more often.'),
        'pt': dict(
        label=f'Taxas de pontualidade de motos e bicicletas. Perto: moto '
              f'{num("pt", 100 * rate[("motorbike", "near")], 1)}%, bicicleta '
              f'{num("pt", 100 * rate[("bicycle", "near")], 1)}%. Longe: moto '
              f'{num("pt", 100 * rate[("motorbike", "far")], 1)}%, bicicleta '
              f'{num("pt", 100 * rate[("bicycle", "far")], 1)}%. Todas as entregas: moto '
              f'{num("pt", 100 * rate[("motorbike", "all")], 1)}%, bicicleta '
              f'{num("pt", 100 * rate[("bicycle", "all")], 1)}%.',
        groups={'near': 'perto', 'far': 'longe', 'all': 'todas as entregas'},
        v={'motorbike': 'moto', 'bicycle': 'bicicleta'}, y='no prazo (%)',
        cap='As motos chegam no prazo mais vezes perto e mais vezes longe, e menos vezes no total. '
            'Elas fazem a maior parte das entregas longas, onde todo mundo atrasa mais.')}[lang]
    f = Fig('l18-simpson', 600, 300, t['label'])
    p = Plot(f, 70, 50, 580, 250, 0, 3, 50, 100)
    p.yaxis(range(50, 101, 10), label=t['y'])
    for gi, g in enumerate(('near', 'far', 'all')):
        for vi, v in enumerate(V):
            x0 = gi + 0.18 + vi * 0.32
            x1 = x0 + 0.28
            val = 100 * rate[(v, g)]
            fill = '--phosphor-dim' if v == 'motorbike' else '--scan'
            stroke = '--phosphor' if v == 'motorbike' else '--paper-dim'
            f.path(f'M{p.sx(x0):.1f} {p.y1:.1f} L{p.sx(x0):.1f} {p.sy(val):.1f} L{p.sx(x1):.1f} '
                   f'{p.sy(val):.1f} L{p.sx(x1):.1f} {p.y1:.1f} Z', stroke=stroke, width=1.2, fill=fill)
            f.text(p.sx((x0 + x1) / 2), p.sy(val) - 9, num(lang, val, 1), size=9.5)
        f.text(p.sx(gi + 0.5), p.y1 + 16, t['groups'][g], size=10.5, weight='600')
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    f.rect(330, 12, 12, 12, stroke='--phosphor', fill='--phosphor-dim', rx=1)
    f.text(348, 18, t['v']['motorbike'], size=10, anchor='start')
    f.rect(440, 12, 12, 12, stroke='--paper-dim', fill='--scan', rx=1)
    f.text(458, 18, t['v']['bicycle'], size=10, anchor='start')
    return f, t['cap']


@figure('l18-walks', 18)
def l18_walks(lang):
    d = S.Draw(1803)
    a, b = S.walk(d), S.walk(d)
    r = S.pearson(a, b)
    lo, hi = min(a + b), max(a + b)
    t = {'en': dict(
        label=f'Two lines over 36 months, each built by adding a random step every month, '
              f'independently of the other. One drifts upwards and the other downwards, and their '
              f'correlation is {"−" if r < 0 else ""}{num("en", abs(r), 2)}.',
        x='month', a='series A', b='series B',
        cap='Two series with nothing in common. Each wanders on its own, and because both drift, '
            'they correlate strongly. Their month-to-month changes have a correlation of 0.07.'),
        'pt': dict(
        label=f'Duas linhas ao longo de 36 meses, cada uma construída somando um passo aleatório '
              f'por mês, independente da outra. Uma deriva para cima e a outra para baixo, e a '
              f'correlação entre elas é {"−" if r < 0 else ""}{num("pt", abs(r), 2)}.',
        x='mês', a='série A', b='série B',
        cap='Duas séries sem nada em comum. Cada uma vagueia por conta própria, e, como as duas '
            'derivam, elas se correlacionam forte. As variações de um mês para o outro têm '
            'correlação de 0,07.')}[lang]
    f = Fig('l18-walks', 600, 280, t['label'])
    p = Plot(f, 50, 30, 510, 230, 1, 36, math.floor(lo) - 1, math.ceil(hi) + 1)
    p.xaxis([1, 6, 12, 18, 24, 30, 36], label=t['x'])
    f.line(p.x0, p.y0, p.x0, p.y1, stroke='--paper-dim')
    f.path('M' + ' L'.join(f'{p.sx(i + 1):.1f} {p.sy(v):.1f}' for i, v in enumerate(a)),
           stroke='--phosphor', width=2)
    f.path('M' + ' L'.join(f'{p.sx(i + 1):.1f} {p.sy(v):.1f}' for i, v in enumerate(b)),
           stroke='--amber', width=2, dash='6 3')
    f.text(p.sx(36) + 8, p.sy(a[-1]), t['a'], size=10, anchor='start', fill='--paper')
    f.text(p.sx(36) + 8, p.sy(b[-1]), t['b'], size=10, anchor='start', fill='--amber')
    return f, t['cap']


@figure('l18-randomise', 18)
def l18_randomise(lang):
    t = {'en': dict(
        label='The same three boxes as before, plus a coin. The coin has an arrow to coupon. The '
              'arrow from distance to coupon is crossed out. Distance still has an arrow to '
              'minutes. Any arrow left from coupon to minutes would now be the coupon\'s own '
              'effect.',
        dist='distance', coupon='coupon', mins='minutes', coin='coin toss',
        q='its own effect, if any',
        cap='When a coin decides who gets a coupon, distance can no longer decide it. Far and near '
            'customers get coupons equally often, so any difference left in minutes is the '
            'coupon\'s.'),
        'pt': dict(
        label='As mesmas três caixas de antes, mais uma moeda. A moeda tem uma seta para cupom. A '
              'seta de distância para cupom está riscada. A distância ainda tem uma seta para '
              'minutos. Uma seta que sobre de cupom para minutos seria agora o efeito do próprio '
              'cupom.',
        dist='distância', coupon='cupom', mins='minutos', coin='sorteio',
        q='o efeito dele, se houver',
        cap='Quando uma moeda decide quem recebe cupom, a distância não pode mais decidir. '
            'Clientes longe e perto recebem cupons com a mesma frequência, então qualquer '
            'diferença que sobre nos minutos é do cupom.')}[lang]
    f = Fig('l18-randomise', 600, 250, t['label'])
    node(f, 300, 40, 140, t['dist'])
    node(f, 110, 190, 130, t['coupon'])
    node(f, 490, 190, 130, t['mins'])
    node(f, 80, 40, 120, t['coin'], stroke='--amber')
    f.line(90, 57, 105, 171, stroke='--amber', width=1.6, arrow=True)
    f.line(260, 57, 140, 171, stroke='--paper-dim', width=1.2, dash='3 3')
    f.line(188, 104, 212, 124, stroke='--amber', width=2.2)
    f.line(212, 104, 188, 124, stroke='--amber', width=2.2)
    f.line(340, 57, 460, 171, stroke='--paper', width=1.6, arrow=True)
    f.line(178, 190, 422, 190, stroke='--paper', width=1.6, dash='6 4', arrow=True)
    f.text(300, 178, t['q'], size=10)
    return f, t['cap']


# ----------------------------------------------------------------- lesson 19

def _kmfit():
    km = [r['km'] for r in S.DELIVERIES]
    mn = [r['minutes'] for r in S.DELIVERIES]
    a, b = S.line(km, mn)
    return km, mn, a, b


@figure('l19-residuals', 19)
def l19_residuals(lang):
    km, mn, a, b = _kmfit()
    pick = [i for i in range(120) if i % 6 == 0]
    t = {'en': dict(
        label=f'Twenty of the deliveries, distance across and minutes up, with the least-squares '
              f'line through all 120, minutes = {num("en", a, 2)} + {num("en", b, 2)} × km. A short '
              f'vertical segment joins each point to the line: its residual. Points above the line '
              f'took longer than predicted, points below were quicker.',
        x='distance (km)', y='minutes', res='residual',
        cap='The least-squares line is the one that makes the sum of the squared residuals, the '
            'vertical gaps, as small as it can be.'),
        'pt': dict(
        label=f'Vinte das entregas, distância na horizontal e minutos na vertical, com a reta de '
              f'mínimos quadrados pelas 120, minutos = {num("pt", a, 2)} + {num("pt", b, 2)} × km. Um '
              f'segmento vertical curto liga cada ponto à reta: o resíduo dele. Pontos acima da reta '
              f'demoraram mais que o previsto, pontos abaixo foram mais rápidos.',
        x='distância (km)', y='minutos', res='resíduo',
        cap='A reta de mínimos quadrados é a que deixa a soma dos resíduos ao quadrado, as '
            'distâncias verticais, a menor possível.')}[lang]
    f = Fig('l19-residuals', 600, 320, t['label'])
    p = Plot(f, 70, 36, 580, 260, 0, 14, 20, 70)
    p.yaxis(range(20, 71, 10), label=t['y'])
    p.xaxis(range(0, 15, 2), label=t['x'])
    f.line(p.sx(0.5), p.sy(a + 0.5 * b), p.sx(14), p.sy(a + 14 * b), stroke='--amber', width=2)
    for i in pick:
        f.line(p.sx(km[i]), p.sy(mn[i]), p.sx(km[i]), p.sy(a + b * km[i]), stroke='--paper', width=1.2)
    dots(f, p, [km[i] for i in pick], [mn[i] for i in pick], r=3.6)
    # label the largest residual among those drawn
    j = max(pick, key=lambda i: mn[i] - a - b * km[i])
    f.text(p.sx(km[j]) - 8, p.sy((mn[j] + a + b * km[j]) / 2), t['res'], size=10, anchor='end')
    return f, t['cap']


@figure('l19-slope', 19)
def l19_slope(lang):
    km, mn, a, b = _kmfit()
    t = {'en': dict(
        label=f'All 120 deliveries as faint points, with the fitted line. A right-angled triangle '
              f'under the line runs from 4 km to 8 km, 4 km across, and rises '
              f'{num("en", 4 * b, 2)} minutes. The line meets the vertical axis at '
              f'{num("en", a, 2)} minutes.',
        x='distance (km)', y='minutes', run='+4 km', rise=f'+{num("en", 4 * b, 1)} min',
        icpt=f'intercept {num("en", a, 1)}',
        cap=f'The slope is the rise per kilometre: {num("en", b, 2)} minutes. The intercept is '
            f'where the line meets zero kilometres, {num("en", a, 1)} minutes: roughly the time '
            f'spent before and after the ride.'),
        'pt': dict(
        label=f'As 120 entregas como pontos claros, com a reta ajustada. Um triângulo retângulo sob '
              f'a reta vai de 4 km a 8 km, 4 km de base, e sobe {num("pt", 4 * b, 2)} minutos. A '
              f'reta encontra o eixo vertical em {num("pt", a, 2)} minutos.',
        x='distância (km)', y='minutos', run='+4 km', rise=f'+{num("pt", 4 * b, 1)} min',
        icpt=f'intercepto {num("pt", a, 1)}',
        cap=f'A inclinação é a subida por quilômetro: {num("pt", b, 2)} minutos. O intercepto é '
            f'onde a reta encontra zero quilômetro, {num("pt", a, 1)} minutos: mais ou menos o '
            f'tempo gasto antes e depois do trajeto.')}[lang]
    f = Fig('l19-slope', 600, 320, t['label'])
    p = Plot(f, 70, 36, 580, 260, 0, 14, 20, 70)
    p.yaxis(range(20, 71, 10), label=t['y'])
    p.xaxis(range(0, 15, 2), label=t['x'])
    for x, y in zip(km, mn):
        f.circle(p.sx(x), p.sy(y), 2.4, fill=None, stroke='--paper-dim', width=0.8)
    f.line(p.sx(0), p.sy(a), p.sx(14), p.sy(a + 14 * b), stroke='--amber', width=2)
    x1, x2 = 4, 8
    f.line(p.sx(x1), p.sy(a + b * x1), p.sx(x2), p.sy(a + b * x1), stroke='--paper', width=1.6)
    f.line(p.sx(x2), p.sy(a + b * x1), p.sx(x2), p.sy(a + b * x2), stroke='--paper', width=1.6)
    f.text(p.sx(6), p.sy(a + b * x1) + 13, t['run'], size=10, weight='600')
    f.text(p.sx(x2) + 8, p.sy(a + b * 6), t['rise'], size=10, weight='600', anchor='start')
    f.circle(p.sx(0), p.sy(a), 4.5, fill='--amber', stroke='--amber')
    f.line(p.sx(0.15), p.sy(a) - 6, p.sx(0.5), p.sy(52) + 8, stroke='--amber', width=1)
    f.text(p.sx(0.3), p.sy(52), t['icpt'], size=10, anchor='start', fill='--amber')
    return f, t['cap']


@figure('l19-extrapolate', 19)
def l19_extrapolate(lang):
    km, mn, a, b = _kmfit()
    top = max(km)
    t = {'en': dict(
        label=f'The 120 deliveries cover 1 to {num("en", top, 1)} km. The fitted line is drawn '
              f'solid over that range and dashed beyond it, out to 30 km, where it predicts '
              f'{num("en", a + 30 * b, 1)} minutes. The region beyond the data is shaded and '
              f'labelled no data here.',
        x='distance (km)', y='minutes', none='no data here', q=f'{num("en", a + 30 * b, 1)}?',
        cap='Inside the range of the data the line is a summary of what happened. Outside it, the '
            'line is a guess that the same pattern continues, and nothing in the data can say '
            'whether it does.'),
        'pt': dict(
        label=f'As 120 entregas cobrem de 1 a {num("pt", top, 1)} km. A reta ajustada está cheia '
              f'nessa faixa e tracejada além dela, até 30 km, onde prevê '
              f'{num("pt", a + 30 * b, 1)} minutos. A região além dos dados está sombreada e '
              f'rotulada sem dados aqui.',
        x='distância (km)', y='minutos', none='sem dados aqui', q=f'{num("pt", a + 30 * b, 1)}?',
        cap='Dentro da faixa dos dados a reta resume o que aconteceu. Fora dela, a reta é um '
            'palpite de que o mesmo padrão continua, e nada nos dados consegue dizer se continua.')}[lang]
    f = Fig('l19-extrapolate', 600, 300, t['label'])
    p = Plot(f, 70, 36, 580, 240, 0, 32, 20, 110)
    f.path(f'M{p.sx(top):.1f} {p.y0:.1f} L{p.x1:.1f} {p.y0:.1f} L{p.x1:.1f} {p.y1:.1f} '
           f'L{p.sx(top):.1f} {p.y1:.1f} Z', stroke=None, width=0, fill='--scan')
    p.yaxis(range(20, 111, 20), label=t['y'])
    p.xaxis(range(0, 33, 4), label=t['x'])
    dots(f, p, km, mn, r=2.2)
    f.line(p.sx(1), p.sy(a + b), p.sx(top), p.sy(a + b * top), stroke='--amber', width=2)
    f.line(p.sx(top), p.sy(a + b * top), p.sx(30), p.sy(a + 30 * b), stroke='--amber', width=2, dash='6 4')
    f.circle(p.sx(30), p.sy(a + 30 * b), 4.5, fill='--panel', stroke='--amber', width=2)
    f.text(p.sx(30) - 10, p.sy(a + 30 * b) - 2, t['q'], size=10.5, anchor='end', weight='600', fill='--amber')
    f.text(p.sx(23), p.y1 - 18, t['none'], size=11, weight='600')
    return f, t['cap']


@figure('l19-rain-lines', 19)
def l19_rain_lines(lang):
    D = S.DELIVERIES
    m = S.ols_full([(r['km'], r['items'], r['rain']) for r in D], [r['minutes'] for r in D])
    b0, bk, bi, br = m['beta']
    t = {'en': dict(
        label=f'The 120 deliveries, distance across and minutes up, with dry deliveries as hollow '
              f'points and rainy ones as solid points. Two parallel lines show the model\'s '
              f'prediction for an 8-item order: the lower for dry weather, the upper for rain, '
              f'{num("en", br, 1)} minutes higher at every distance.',
        x='distance (km)', y='minutes', dry='dry', wet='rain', gap=f'+{num("en", br, 1)} min',
        cap='With distance, items and rain in one model, each coefficient is the change in '
            'minutes for that variable alone, with the others held fixed. Rain shifts the whole '
            'line up.'),
        'pt': dict(
        label=f'As 120 entregas, distância na horizontal e minutos na vertical, com as entregas sem '
              f'chuva como pontos vazados e as com chuva como pontos cheios. Duas retas paralelas '
              f'mostram a previsão do modelo para um pedido de 8 itens: a de baixo para tempo seco, a '
              f'de cima para chuva, {num("pt", br, 1)} minutos acima em qualquer distância.',
        x='distância (km)', y='minutos', dry='seco', wet='chuva', gap=f'+{num("pt", br, 1)} min',
        cap='Com distância, itens e chuva num só modelo, cada coeficiente é a mudança em minutos '
            'por aquela variável sozinha, com as outras fixas. A chuva desloca a reta inteira para '
            'cima.')}[lang]
    f = Fig('l19-rain-lines', 600, 320, t['label'])
    p = Plot(f, 70, 36, 580, 260, 0, 14, 20, 75)
    p.yaxis(range(20, 76, 10), label=t['y'])
    p.xaxis(range(0, 15, 2), label=t['x'])
    for r in D:
        if r['rain']:
            f.circle(p.sx(r['km']), p.sy(r['minutes']), 3, fill='--amber', stroke='--amber', width=0.8)
        else:
            f.circle(p.sx(r['km']), p.sy(r['minutes']), 2.6, fill=None, stroke='--paper-dim', width=1)
    base = b0 + 8 * bi
    f.line(p.sx(0.5), p.sy(base + 0.5 * bk), p.sx(14), p.sy(base + 14 * bk), stroke='--phosphor', width=2)
    f.line(p.sx(0.5), p.sy(base + br + 0.5 * bk), p.sx(14), p.sy(base + br + 14 * bk), stroke='--amber', width=2)
    f.text(p.sx(8.6), p.sy(base + 8.6 * bk) + 16, t['dry'], size=10.5, weight='600', fill='--phosphor')
    f.text(p.sx(8.6), p.sy(base + br + 8.6 * bk) - 16, t['wet'], size=10.5, weight='600', fill='--amber')
    xg = 7.6
    f.line(p.sx(xg), p.sy(base + xg * bk), p.sx(xg), p.sy(base + br + xg * bk), stroke='--paper', width=1.4, arrow=True)
    f.text(p.sx(xg) + 8, p.sy(base + br * 0.4 + xg * bk), t['gap'], size=10, anchor='start', weight='600')
    return f, t['cap']


@figure('l19-overfit', 19)
def l19_overfit(lang):
    D = S.DELIVERIES
    mins = [r['minutes'] for r in D]
    base = [(r['km'], r['items'], r['rain']) for r in D]
    noise = S.noise_columns(120, 30)
    train = [i for i in range(120) if i % 30 < 15]
    test = [i for i in range(120) if i % 30 >= 15]
    out = []
    for k in (0, 30):
        X = [tuple(base[i]) + tuple(noise[j][i] for j in range(k)) for i in range(120)]
        f_ = S.ols_full([X[i] for i in train], [mins[i] for i in train])
        pred = [f_['beta'][0] + sum(bb * v for bb, v in zip(f_['beta'][1:], X[i])) for i in test]
        te = math.sqrt(S.mean([(mins[i] - p_) ** 2 for i, p_ in zip(test, pred)]))
        tr = math.sqrt(f_['sse'] / len(train))
        out.append((tr, te))
    t = {'en': dict(
        label=f'Typical prediction error, in minutes, for two models fitted to 60 deliveries and '
              f'then tried on the other 60. With distance, items and rain: '
              f'{num("en", out[0][0], 2)} on the deliveries it was fitted to and '
              f'{num("en", out[0][1], 2)} on new ones. With 30 columns of random noise added: '
              f'{num("en", out[1][0], 2)} on its own deliveries and {num("en", out[1][1], 2)} on '
              f'new ones.',
        g=['3 real predictors', '+ 30 of noise'], fit='fitted deliveries', new='new deliveries',
        y='typical error (minutes)',
        cap='The model stuffed with noise fits its own data better and predicts new data far '
            'worse. It has learnt the accidents of 60 particular deliveries.'),
        'pt': dict(
        label=f'Erro típico de previsão, em minutos, de dois modelos ajustados a 60 entregas e '
              f'depois testados nas outras 60. Com distância, itens e chuva: '
              f'{num("pt", out[0][0], 2)} nas entregas em que foi ajustado e '
              f'{num("pt", out[0][1], 2)} em entregas novas. Com 30 colunas de ruído aleatório '
              f'acrescentadas: {num("pt", out[1][0], 2)} nas próprias entregas e '
              f'{num("pt", out[1][1], 2)} nas novas.',
        g=['3 preditores reais', '+ 30 de ruído'], fit='entregas do ajuste', new='entregas novas',
        y='erro típico (minutos)',
        cap='O modelo recheado de ruído se ajusta melhor aos próprios dados e prevê dados novos '
            'muito pior. Ele aprendeu os acidentes de 60 entregas em particular.')}[lang]
    f = Fig('l19-overfit', 600, 300, t['label'])
    p = Plot(f, 70, 50, 580, 250, 0, 2, 0, 7)
    p.yaxis(range(0, 8), label=t['y'])
    for gi in range(2):
        for k, (val, fill, stroke) in enumerate(((out[gi][0], '--phosphor-dim', '--phosphor'),
                                                 (out[gi][1], '--amber', '--amber'))):
            x0 = gi + 0.22 + k * 0.3
            x1 = x0 + 0.26
            f.path(f'M{p.sx(x0):.1f} {p.y1:.1f} L{p.sx(x0):.1f} {p.sy(val):.1f} L{p.sx(x1):.1f} '
                   f'{p.sy(val):.1f} L{p.sx(x1):.1f} {p.y1:.1f} Z', stroke=stroke, width=1.2, fill=fill)
            f.text(p.sx((x0 + x1) / 2), p.sy(val) - 9, num(lang, val, 2), size=10)
        f.text(p.sx(gi + 0.5), p.y1 + 16, t['g'][gi], size=10.5, weight='600')
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim')
    f.rect(330, 12, 12, 12, stroke='--phosphor', fill='--phosphor-dim', rx=1)
    f.text(348, 18, t['fit'], size=10, anchor='start')
    f.rect(470, 12, 12, 12, stroke='--amber', fill='--amber', rx=1)
    f.text(488, 18, t['new'], size=10, anchor='start')
    return f, t['cap']


# ----------------------------------------------------------------- lesson 20

def zero_line(f, p):
    f.line(p.x0, p.sy(0), p.x1, p.sy(0), stroke='--amber', width=1.4, dash='5 4')


def panel_title(f, x, y, s):
    f.text(x, y, s, size=10.5, weight='600', anchor='start')


@figure('l20-good', 20)
def l20_good(lang):
    D = S.DELIVERIES
    fit = S.ols_full([(r['km'], r['items'], r['rain']) for r in D], [r['minutes'] for r in D])
    res = [r['minutes'] - f_ for r, f_ in zip(D, fit['fitted'])]
    t = {'en': dict(
        label='Residuals of Horta\'s three-predictor model plotted against its predicted minutes, '
              'from about 25 to 65. The points form an even horizontal band around zero, roughly '
              'from −7 to +10, with no curve, no funnel and no stray point.',
        x='predicted minutes', y='residual (minutes)',
        cap='What a healthy residual plot looks like: a shapeless band of even width around zero. '
            'Whatever pattern there was in the data, the model has taken it.'),
        'pt': dict(
        label='Resíduos do modelo de três preditores da Horta contra os minutos previstos, de uns '
              '25 a 65. Os pontos formam uma faixa horizontal regular em torno de zero, mais ou '
              'menos de −7 a +10, sem curva, sem funil e sem ponto desgarrado.',
        x='minutos previstos', y='resíduo (minutos)',
        cap='Assim é um gráfico de resíduos saudável: uma faixa sem forma, de largura regular, em '
            'torno de zero. Qualquer padrão que havia nos dados, o modelo levou.')}[lang]
    f = Fig('l20-good', 600, 300, t['label'])
    p = Plot(f, 70, 36, 580, 240, 20, 70, -12, 12)
    p.yaxis(range(-12, 13, 4), fmt=lambda v: str(v).replace('-', '−'), label=t['y'], grid=False)
    p.xaxis(range(20, 71, 10), label=t['x'])
    zero_line(f, p)
    dots(f, p, fit['fitted'], res, r=2.8)
    return f, t['cap']


@figure('l20-curve', 20)
def l20_curve(lang):
    xs, ys = S.DISCOUNT, S.DISCOUNT_ORDERS
    a, b = S.line(xs, ys)
    r1 = [y - a - b * x for x, y in zip(xs, ys)]
    lx = [math.log(1 + x) for x in xs]
    a2, b2 = S.line(lx, ys)
    r2 = [y - a2 - b2 * x for x, y in zip(lx, ys)]
    t = {'en': dict(
        label='Two residual plots for the discount data, residual up and discount across. Left, '
              'for a straight line: the residuals run from −95 at no discount up to about +46 in '
              'the middle and down to −47 at 20%, an arch. Right, for a line in the logarithm of '
              'one plus the discount: the same arch, much flatter, between about −23 and +18.',
        x='discount (%)', y='residual (orders)', a='straight line', b='line in ln(1 + discount)',
        cap='A curve in the residuals means a curve the model missed. The logarithm takes most of '
            'it out, but not all: what is left still arches.'),
        'pt': dict(
        label='Dois gráficos de resíduos para os dados de desconto, resíduo na vertical e desconto '
              'na horizontal. À esquerda, para uma reta: os resíduos vão de −95 sem desconto até '
              'uns +46 no meio e descem a −47 em 20%, um arco. À direita, para uma reta no '
              'logaritmo de um mais o desconto: o mesmo arco, bem mais achatado, entre uns −23 e '
              '+18.',
        x='desconto (%)', y='resíduo (pedidos)', a='reta', b='reta em ln(1 + desconto)',
        cap='Uma curva nos resíduos quer dizer uma curva que o modelo perdeu. O logaritmo tira a '
            'maior parte dela, mas não toda: o que sobra ainda faz arco.')}[lang]
    f = Fig('l20-curve', 600, 300, t['label'])
    for k, (rs, title) in enumerate(((r1, t['a']), (r2, t['b']))):
        x0 = 70 + k * 280
        p = Plot(f, x0, 46, x0 + 230, 240, 0, 20, -100, 60)
        p.yaxis(range(-100, 61, 40), fmt=lambda v: str(v).replace('-', '−'), label=t['y'] if k == 0 else None, grid=False, size=9)
        p.xaxis(range(0, 21, 5), label=t['x'], size=9)
        zero_line(f, p)
        f.path('M' + ' L'.join(f'{p.sx(x):.1f} {p.sy(e):.1f}' for x, e in zip(xs, rs)),
               stroke='--phosphor', width=1.2)
        dots(f, p, xs, rs, r=3.6)
        panel_title(f, x0 + 10, 62, title)
    return f, t['cap']


@figure('l20-fan', 20)
def l20_fan(lang):
    it = [o[0] for o in S.BIG_ORDERS]
    bk = [o[1] for o in S.BIG_ORDERS]
    a, b = S.line(it, bk)
    r1 = [y - a - b * x for x, y in zip(it, bk)]
    la, lb = S.line([math.log(v) for v in it], [math.log(y) for y in bk])
    r2 = [math.log(y) - la - lb * math.log(x) for x, y in zip(it, bk)]
    t = {'en': dict(
        label='Two residual plots for 200 orders against the number of items. Left, basket in '
              'reais on items: the residuals spread from a few reais either way at one item to '
              'well over a hundred at twenty, a funnel opening to the right. Right, the logarithm '
              'of the basket on the logarithm of items: a band of even width.',
        x='items', a='basket on items (R$)', b='ln basket on ln items',
        cap='A funnel means the spread grows with the prediction. Here each customer shops at '
            'their own price level, so the spread grows in proportion, and logarithms turn that '
            'into an even band.'),
        'pt': dict(
        label='Dois gráficos de resíduos para 200 pedidos contra o número de itens. À esquerda, a '
              'cesta em reais pelos itens: os resíduos se espalham de poucos reais para cada lado '
              'com um item até bem mais de cem com vinte, um funil abrindo para a direita. À '
              'direita, o logaritmo da cesta pelo logaritmo dos itens: uma faixa de largura '
              'regular.',
        x='itens', a='cesta por itens (R$)', b='ln cesta por ln itens',
        cap='Um funil quer dizer que a dispersão cresce com a previsão. Aqui cada cliente compra '
            'num nível de preço próprio, então a dispersão cresce em proporção, e os logaritmos '
            'transformam isso numa faixa regular.')}[lang]
    f = Fig('l20-fan', 600, 300, t['label'])
    lim1 = max(abs(v) for v in r1) * 1.05
    for k, (rs, title, lo, hi, ticks) in enumerate(((r1, t['a'], -150, 300, range(-150, 301, 75)),
                                                    (r2, t['b'], -1.0, 1.0, [-1, -0.5, 0, 0.5, 1]))):
        x0 = 70 + k * 280
        p = Plot(f, x0, 46, x0 + 230, 240, 0, 21, lo, hi)
        fmt = (lambda v: str(v).replace('-', '−')) if k == 0 else (lambda v: num(lang, v, 1).replace('-', '−'))
        p.yaxis(ticks, fmt=fmt, grid=False, size=9)
        p.xaxis(range(0, 21, 5), label=t['x'], size=9)
        zero_line(f, p)
        dots(f, p, it, rs, r=2.2)
        panel_title(f, x0 + 10, 30, title)
    assert lim1 < 300
    return f, t['cap']


def qq(f, p, xs):
    n = len(xs)
    zs = sorted((v - S.mean(xs)) / S.sd(xs) for v in xs)
    th = [S.normal_inv((i + 0.5) / n) for i in range(n)]
    f.line(p.sx(-3), p.sy(-3), p.sx(3), p.sy(3), stroke='--amber', width=1.4, dash='5 4')
    dots(f, p, th, zs, r=2.2)


@figure('l20-qq', 20)
def l20_qq(lang):
    D = S.DELIVERIES
    fit = S.ols_full([(r['km'], r['items'], r['rain']) for r in D], [r['minutes'] for r in D])
    res = [r['minutes'] - f_ for r, f_ in zip(D, fit['fitted'])]
    t = {'en': dict(
        label='Two normal quantile plots. Left, the 120 residuals of Horta\'s delivery model, '
              'standardised: the points lie close to the dashed diagonal all the way along. '
              'Right, the 400 baskets, standardised: the points bend away from the diagonal, '
              'above it at both ends, the shape of a long right tail.',
        x='normal quantile', y='data quantile', a='120 residuals', b='400 baskets',
        cap='If the data were normal, the points would follow the diagonal. The residuals do; the '
            'baskets curve upwards, the mark of a long right tail.'),
        'pt': dict(
        label='Dois gráficos de quantis normais. À esquerda, os 120 resíduos do modelo de entregas '
              'da Horta, padronizados: os pontos ficam perto da diagonal tracejada o caminho todo. '
              'À direita, as 400 cestas, padronizadas: os pontos se curvam para longe da diagonal, '
              'acima dela nas duas pontas, a forma de uma cauda longa à direita.',
        x='quantil normal', y='quantil dos dados', a='120 resíduos', b='400 cestas',
        cap='Se os dados fossem normais, os pontos seguiriam a diagonal. Os resíduos seguem; as '
            'cestas se curvam para cima, a marca de uma cauda longa à direita.')}[lang]
    f = Fig('l20-qq', 600, 300, t['label'])
    for k, (xs, title) in enumerate(((res, t['a']), (S.BASKETS, t['b']))):
        x0 = 70 + k * 280
        p = Plot(f, x0, 46, x0 + 230, 240, -3.2, 3.2, -3.2, 6)
        fmt = lambda v: str(v).replace('-', '−')
        p.yaxis([-2, 0, 2, 4, 6], fmt=fmt, label=t['y'] if k == 0 else None, grid=False, size=9)
        p.xaxis([-3, -2, -1, 0, 1, 2, 3], fmt=fmt, label=t['x'], size=9)
        qq(f, p, xs)
        panel_title(f, x0 + 10, 62, title)
    return f, t['cap']


@figure('l20-time', 20)
def l20_time(lang):
    dk = [r['km'] for r in S.DAY]
    dm = [r['minutes'] for r in S.DAY]
    hr = [r['hour'] for r in S.DAY]
    a, b = S.line(dk, dm)
    res = [y - a - b * x for x, y in zip(dk, dm)]
    t = {'en': dict(
        label='Residuals of a distance-only model for one day\'s 60 deliveries, in the order they '
              'left, from 10:00 to 20:00. Two shaded bands mark lunch and the evening rush. The '
              'residuals rise above zero together inside each band and sit below zero together '
              'between them, so neighbouring deliveries have similar residuals.',
        x='time of departure', y='residual (minutes)', lunch='lunch', eve='evening',
        cap='Residuals that come in runs are not independent. Something that changes through the '
            'day, here the traffic, is in the residuals because it is not in the model.'),
        'pt': dict(
        label='Resíduos de um modelo só com a distância para as 60 entregas de um dia, na ordem em '
              'que saíram, das 10:00 às 20:00. Duas faixas sombreadas marcam o almoço e o pico da '
              'noite. Os resíduos sobem acima de zero juntos dentro de cada faixa e ficam abaixo '
              'de zero juntos entre elas, então entregas vizinhas têm resíduos parecidos.',
        x='hora de saída', y='resíduo (minutos)', lunch='almoço', eve='noite',
        cap='Resíduos que vêm em sequências não são independentes. Algo que muda ao longo do dia, '
            'aqui o trânsito, está nos resíduos porque não está no modelo.')}[lang]
    f = Fig('l20-time', 600, 300, t['label'])
    p = Plot(f, 70, 36, 580, 240, 10, 20, -8, 12)
    for lo, hi, lab in ((11.5, 13.5, t['lunch']), (17.5, 19.5, t['eve'])):
        f.path(f'M{p.sx(lo):.1f} {p.y0:.1f} L{p.sx(hi):.1f} {p.y0:.1f} L{p.sx(hi):.1f} {p.y1:.1f} '
               f'L{p.sx(lo):.1f} {p.y1:.1f} Z', stroke=None, width=0, fill='--scan')
        f.text(p.sx((lo + hi) / 2), p.y0 + 10, lab, size=10, weight='600')
    p.yaxis(range(-8, 13, 4), fmt=lambda v: str(v).replace('-', '−'), label=t['y'], grid=False)
    p.xaxis(range(10, 21, 2), fmt=lambda v: f'{v}:00', label=t['x'])
    zero_line(f, p)
    f.path('M' + ' L'.join(f'{p.sx(h):.1f} {p.sy(e):.1f}' for h, e in zip(hr, res)),
           stroke='--phosphor', width=1)
    dots(f, p, hr, res, r=2.8)
    return f, t['cap']


@figure('l20-influence', 20)
def l20_influence(lang):
    d = S.Draw(1717)
    lx = [round(d.uniform(1, 3), 1) for _ in range(10)]
    ly = [round(d.uniform(30, 36), 1) for _ in range(10)]
    a1, b1 = S.line(lx + [12], ly + [60])
    a0, b0 = S.line(lx, ly)

    def sgn(v):
        return ('−' if v < 0 else '+') + num(lang, abs(v), 2)
    t = {'en': dict(
        label=f'The ten patternless points and the lone point at 12 and 60 again. A solid line '
              f'fitted to all eleven rises steeply, slope {sgn(b1)}, towards the lone point. A '
              f'dashed line fitted to the ten alone is nearly flat, slope {sgn(b0)}. The lone point '
              f'is far out on the horizontal axis, which gives it the leverage to pull the line.',
        w=f'with it: slope {sgn(b1)}', wo=f'without it: slope {sgn(b0)}',
        cap='A point far out along the horizontal axis has leverage: the line pivots towards it. '
            'Here one point decides the sign of the slope, and Cook\'s distance flags it at 92, '
            'against at most 0.2 for the others.'),
        'pt': dict(
        label=f'Os dez pontos sem padrão e o ponto isolado em 12 e 60 de novo. Uma reta cheia '
              f'ajustada aos onze sobe forte, inclinação {sgn(b1)}, em direção ao ponto isolado. '
              f'Uma reta tracejada ajustada só aos dez é quase plana, inclinação {sgn(b0)}. O ponto '
              f'isolado fica longe no eixo horizontal, o que lhe dá a alavanca para puxar a reta.',
        w=f'com ele: inclinação {sgn(b1)}', wo=f'sem ele: inclinação {sgn(b0)}',
        cap='Um ponto longe no eixo horizontal tem alavanca: a reta gira em direção a ele. Aqui um '
            'ponto decide o sinal da inclinação, e a distância de Cook o aponta com 92, contra no '
            'máximo 0,2 para os outros.')}[lang]
    f = Fig('l20-influence', 600, 300, t['label'])
    p = Plot(f, 60, 30, 580, 250, 0, 14, 25, 65)
    p.yaxis(range(25, 66, 10))
    p.xaxis(range(0, 15, 2))
    f.line(p.sx(0.5), p.sy(a1 + 0.5 * b1), p.sx(13), p.sy(a1 + 13 * b1), stroke='--amber', width=1.8)
    f.line(p.sx(0.5), p.sy(a0 + 0.5 * b0), p.sx(13), p.sy(a0 + 13 * b0), stroke='--paper', width=1.6, dash='6 4')
    dots(f, p, lx, ly, r=3.6)
    f.circle(p.sx(12), p.sy(60), 4.5, fill='--amber', stroke='--amber')
    f.text(p.sx(6), p.sy(50), t['w'], size=11, weight='600', fill='--amber', anchor='end')
    f.text(p.sx(5.5), p.sy(33.5), t['wo'], size=11, weight='600', anchor='start')
    return f, t['cap']


# ----------------------------------------------------------------- lesson 21

def _logit_fit(with_first=True):
    O = S.COMPLAINT_ORDERS
    ys = [o['complained'] for o in O]
    rows = [(o['minutes'], o['first']) if with_first else (o['minutes'],) for o in O]
    return O, ys, S.logistic(rows, ys)


@figure('l21-line-vs-curve', 21)
def l21_line_vs_curve(lang):
    O, ys, m = _logit_fit(False)
    mins = [o['minutes'] for o in O]
    a, b = S.line(mins, ys)
    b0, b1 = m['beta']
    t = {'en': dict(
        label=f'The 400 orders as two rows of ticks, complaints at 1 and no complaint at 0, against '
              f'delivery minutes from 20 to 70. A straight line fitted to the zeros and ones runs from '
              f'{num("en", a + 20 * b, 2)} at 20 minutes, below zero, to {num("en", a + 70 * b, 2)} at '
              f'70. An S-shaped logistic curve stays between 0 and 1, flat near zero for quick '
              f'deliveries and climbing steeply after 45 minutes.',
        x='delivery minutes', y='probability of a complaint', line='straight line', curve='logistic curve',
        below='below zero',
        cap='A straight line through zeros and ones predicts impossible probabilities at the ends. '
            'The logistic curve bends to stay between 0 and 1.'),
        'pt': dict(
        label=f'Os 400 pedidos como duas fileiras de marcas, reclamações em 1 e sem reclamação em 0, '
              f'contra os minutos de entrega de 20 a 70. Uma reta ajustada aos zeros e uns vai de '
              f'{num("pt", a + 20 * b, 2)} em 20 minutos, abaixo de zero, até {num("pt", a + 70 * b, 2)} '
              f'em 70. Uma curva logística em S fica entre 0 e 1, plana perto de zero para entregas '
              f'rápidas e subindo forte depois de 45 minutos.',
        x='minutos de entrega', y='probabilidade de reclamação', line='reta', curve='curva logística',
        below='abaixo de zero',
        cap='Uma reta pelos zeros e uns prevê probabilidades impossíveis nas pontas. A curva '
            'logística se dobra para ficar entre 0 e 1.')}[lang]
    f = Fig('l21-line-vs-curve', 600, 320, t['label'])
    p = Plot(f, 80, 36, 580, 260, 18, 72, -0.3, 1.1)
    p.yaxis([0, 0.25, 0.5, 0.75, 1], fmt=lambda v: num(lang, v, 2), label=t['y'])
    p.xaxis(range(20, 71, 10), label=t['x'])
    f.line(p.x0, p.sy(0), p.x1, p.sy(0), stroke='--paper-dim', width=1, dash='2 3')
    d = S.Draw(2101)
    for o in O:
        y = o['complained']
        jy = (d.uniform(-0.03, 0.03))
        f.line(p.sx(o['minutes']), p.sy(y + jy) - 3, p.sx(o['minutes']), p.sy(y + jy) + 3, stroke='--paper-dim', width=0.8)
    f.line(p.sx(20), p.sy(a + 20 * b), p.sx(70), p.sy(a + 70 * b), stroke='--paper', width=1.8, dash='6 4')
    p.curve(lambda x: 1 / (1 + math.exp(-(b0 + b1 * x))), 20, 70, stroke='--amber', width=2.4)
    f.text(p.sx(25), p.sy(-0.19), t['below'], size=10, anchor='start')
    f.text(p.sx(44), p.sy(0.5), t['line'], size=10.5, weight='600', anchor='end')
    f.text(p.sx(62), p.sy(0.8), t['curve'], size=10.5, weight='600', anchor='end', fill='--amber')
    return f, t['cap']


@figure('l21-two-curves', 21)
def l21_two_curves(lang):
    O, ys, m = _logit_fit(True)
    c0, c1, c2 = m['beta']
    t = {'en': dict(
        label=f'The fitted probability of a complaint against delivery minutes, as two S-shaped '
              f'curves: one for returning customers and one, to its left, for first orders. At 45 '
              f'minutes the curves give {num("en", 100 / (1 + math.exp(-(c0 + c1 * 45))), 0)}% and '
              f'{num("en", 100 / (1 + math.exp(-(c0 + c1 * 45 + c2))), 0)}%.',
        x='delivery minutes', y='probability of a complaint', a='first order', b='returning customer',
        cap='On the log-odds scale a first order adds the same amount at every delivery time. On the '
            'probability scale that becomes a sideways shift: the gap is widest in the middle.'),
        'pt': dict(
        label=f'A probabilidade ajustada de reclamação contra os minutos de entrega, como duas '
              f'curvas em S: uma para clientes que voltam e outra, à esquerda dela, para primeiros '
              f'pedidos. Em 45 minutos as curvas dão {num("pt", 100 / (1 + math.exp(-(c0 + c1 * 45))), 0)}% '
              f'e {num("pt", 100 / (1 + math.exp(-(c0 + c1 * 45 + c2))), 0)}%.',
        x='minutos de entrega', y='probabilidade de reclamação', a='primeiro pedido', b='cliente que volta',
        cap='Na escala de log-chances um primeiro pedido soma o mesmo em qualquer tempo de entrega. '
            'Na escala de probabilidade isso vira um deslocamento para o lado: a diferença é maior no '
            'meio.')}[lang]
    f = Fig('l21-two-curves', 600, 320, t['label'])
    p = Plot(f, 80, 36, 580, 260, 20, 80, 0, 1)
    p.yaxis([0, 0.25, 0.5, 0.75, 1], fmt=lambda v: num(lang, v, 2), label=t['y'])
    p.xaxis(range(20, 81, 10), label=t['x'])
    p.curve(lambda x: 1 / (1 + math.exp(-(c0 + c1 * x))), 20, 80, stroke='--phosphor', width=2.2)
    p.curve(lambda x: 1 / (1 + math.exp(-(c0 + c1 * x + c2))), 20, 80, stroke='--amber', width=2.2)
    p.vline(45, stroke='--paper-dim', dash='3 3', top=p.y0 + 10)
    f.text(p.sx(52), p.sy(0.62), t['a'], size=10.5, weight='600', anchor='end', fill='--amber')
    f.text(p.sx(64), p.sy(0.42), t['b'], size=10.5, weight='600', anchor='start', fill='--phosphor')
    return f, t['cap']


@figure('l21-threshold', 21)
def l21_threshold(lang):
    O, ys, m = _logit_fit(True)
    ps = m['p']
    edges = [i / 20 for i in range(21)]
    yes = histogram([q for q, y in zip(ps, ys) if y], edges)
    no = histogram([q for q, y in zip(ps, ys) if not y], edges)
    t = {'en': dict(
        label='Two histograms of the model\'s predicted probability of a complaint, from 0 to 1. '
              'Orders with no complaint pile up near zero; orders that did bring a complaint spread '
              'across the whole range, most of them above 0.5. Each histogram has its own vertical '
              'scale. Two vertical lines mark cut-offs at 0.2 and 0.5.',
        x='predicted probability of a complaint', y='orders', no='no complaint', yes='complained',
        cap='Wherever the cut-off goes, some orders land on the wrong side. Moving it left catches '
            'more complaints and raises more false alarms.'),
        'pt': dict(
        label='Dois histogramas da probabilidade prevista de reclamação, de 0 a 1. Pedidos sem '
              'reclamação se acumulam perto de zero; pedidos que trouxeram reclamação se espalham '
              'pela faixa toda, a maioria acima de 0,5. Cada histograma tem a própria escala '
              'vertical. Duas linhas verticais marcam cortes em 0,2 e 0,5.',
        x='probabilidade prevista de reclamação', y='pedidos', no='sem reclamação', yes='reclamou',
        cap='Onde quer que o corte fique, alguns pedidos caem do lado errado. Movê-lo para a '
            'esquerda pega mais reclamações e dá mais alarmes falsos.')}[lang]
    f = Fig('l21-threshold', 600, 340, t['label'])
    top1 = 20 * math.ceil(max(no) / 20)
    top2 = 5 * math.ceil(max(yes) / 5)
    p1 = Plot(f, 70, 40, 580, 150, 0, 1, 0, top1)
    p2 = Plot(f, 70, 175, 580, 280, 0, 1, 0, top2)
    p1.bars(edges, no, fill='--scan', stroke='--paper-dim')
    p2.bars(edges, yes, fill='--amber', stroke='--amber')
    p1.yaxis([0, top1 // 2, top1], grid=False, size=9)
    p2.yaxis([0, top2 // 2, top2], grid=False, size=9)
    for p_ in (p1, p2):
        f.line(p_.x0, p_.y1, p_.x1, p_.y1, stroke='--paper-dim')
    p2.xaxis([0, 0.2, 0.5, 0.8, 1], fmt=lambda v: num(lang, v, 1), label=t['x'])
    for cut in (0.2, 0.5):
        x = p1.sx(cut)
        f.line(x, p1.y0 - 6, x, p2.y1, stroke='--paper', width=1.4, dash='4 3')
    f.text(p1.x1 - 4, p1.y0 + 4, t['no'], size=10.5, weight='600', anchor='end')
    f.text(p2.x1 - 4, p2.y0 + 4, t['yes'], size=10.5, weight='600', anchor='end', fill='--amber')
    f.text(p1.x0, p1.y0 - 18, t['y'], size=10, weight='600', anchor='start')
    return f, t['cap']


@figure('l21-confusion', 21)
def l21_confusion(lang):
    O, ys, m = _logit_fit(True)
    t = {'en': dict(
        cut='cut-off', pred='predicted', act='actual', c='complaint', n='none',
        label=None,
        cap='Each cut-off sorts the 400 orders into four boxes. The lower cut-off finds more of the '
            'real complaints and wrongly flags more of the quiet orders.'),
        'pt': dict(
        cut='corte', pred='previsto', act='real', c='reclamação', n='nenhuma',
        label=None,
        cap='Cada corte separa os 400 pedidos em quatro caixas. O corte mais baixo acha mais das '
            'reclamações reais e marca errado mais pedidos tranquilos.')}[lang]
    cells = {}
    for cut in (0.5, 0.2):
        cells[cut] = S.confusion(ys, m['p'], cut)
    if lang == 'en':
        lab = ('Two confusion tables for 400 orders. With a cut-off of 0.5: {0} complaints predicted '
               'and real, {1} real complaints missed, {2} false alarms, {3} quiet orders correctly '
               'left alone. With a cut-off of 0.2: {4} caught, {5} missed, {6} false alarms, {7} '
               'correctly left alone.')
    else:
        lab = ('Duas tabelas de confusão para 400 pedidos. Com corte de 0,5: {0} reclamações previstas '
               'e reais, {1} reclamações reais perdidas, {2} alarmes falsos, {3} pedidos tranquilos '
               'corretamente deixados de lado. Com corte de 0,2: {4} pegas, {5} perdidas, {6} alarmes '
               'falsos, {7} corretamente deixados de lado.')
    f = Fig('l21-confusion', 600, 250, lab.format(*cells[0.5], *cells[0.2]))
    for k, cut in enumerate((0.5, 0.2)):
        tp, fn, fp, tn = cells[cut]
        x0 = 30 + k * 290
        f.text(x0 + 135, 18, f'{t["cut"]} {num(lang, cut, 1)}', size=11.5, weight='600')
        f.text(x0 + 165, 44, t['pred'], size=10, fill='--paper-dim')
        f.text(x0 + 120, 64, t['c'], size=10)
        f.text(x0 + 210, 64, t['n'], size=10)
        f.text(x0 + 30, 150, t['act'], size=10, fill='--paper-dim')
        f.text(x0 + 70, 110, t['c'], size=10, anchor='end')
        f.text(x0 + 70, 180, t['n'], size=10, anchor='end')
        for (r, c_, v, hl) in ((0, 0, tp, True), (0, 1, fn, False), (1, 0, fp, False), (1, 1, tn, True)):
            x, y = x0 + 78 + c_ * 90, 78 + r * 70
            f.rect(x, y, 84, 64, stroke='--phosphor' if hl else '--amber', fill='--panel', rx=4)
            f.text(x + 42, y + 32, str(v), size=16, weight='600', fill='--paper' if hl else '--amber')
    return f, t['cap']


@figure('l21-model-map', 21)
def l21_model_map(lang):
    t = {'en': dict(
        label='A map from the kind of outcome to the model that fits it. A number with roughly normal '
              'noise: linear regression. Yes or no: logistic regression. A count: Poisson regression. '
              'One of several categories: multinomial logistic regression. Time until an event: '
              'survival analysis. Below them all, a box for many predictors and complex patterns: '
              'machine learning, such as trees and their ensembles.',
        q='what is the outcome?',
        rows=[('a number', 'linear regression'), ('yes or no', 'logistic regression'),
              ('a count', 'Poisson regression'), ('one of several categories', 'multinomial logistic'),
              ('time until an event', 'survival analysis')],
        ml='many predictors, complex patterns, prediction first: machine learning',
        cap='The outcome decides the family. Every one of these shares the ideas of the last three '
            'lessons: coefficients with the others held fixed, residuals to check, and data held '
            'back to test on.'),
        'pt': dict(
        label='Um mapa do tipo de resultado para o modelo que serve. Um número com ruído mais ou '
              'menos normal: regressão linear. Sim ou não: regressão logística. Uma contagem: '
              'regressão de Poisson. Uma de várias categorias: regressão logística multinomial. '
              'Tempo até um evento: análise de sobrevivência. Embaixo de todos, uma caixa para muitos '
              'preditores e padrões complexos: aprendizado de máquina, como árvores e seus conjuntos.',
        q='qual é o resultado?',
        rows=[('um número', 'regressão linear'), ('sim ou não', 'regressão logística'),
              ('uma contagem', 'regressão de Poisson'), ('uma de várias categorias', 'logística multinomial'),
              ('tempo até um evento', 'análise de sobrevivência')],
        ml='muitos preditores, padrões complexos, previsão em primeiro: aprendizado de máquina',
        cap='O resultado decide a família. Todas compartilham as ideias das últimas três aulas: '
            'coeficientes com os outros fixos, resíduos para checar e dados separados para testar.')}[lang]
    f = Fig('l21-model-map', 600, 340, t['label'])
    node(f, 90, 150, 150, t['q'], h=40, stroke='--amber')
    for i, (a, b) in enumerate(t['rows']):
        y = 30 + i * 50
        f.rect(200, y - 17, 170, 34, stroke='--wire', fill='--panel', rx=6)
        f.text(285, y, a, size=10.5)
        f.rect(400, y - 17, 180, 34, stroke='--phosphor', fill='--panel', rx=6)
        f.text(490, y, b, size=10.5, weight='600')
        f.line(165, 150, 198, y, stroke='--paper-dim', width=1.2)
        f.line(370, y, 398, y, stroke='--paper', width=1.4, arrow=True)
    f.rect(20, 285, 560, 40, stroke='--amber', fill='--panel', rx=6, dash='5 4')
    f.text(300, 305, t['ml'], size=10.5, weight='600')
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
