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


# ------------------------------------------------------------------ lesson 2

@figure('l02-arc', 2)
def l02_arc(lang):
    f = Fig('l02-arc', 680, 250, T(
        lang,
        'Four boxes in a row under a curve of tension. Context: deliveries are 94.5% on time. '
        'Conflict: first deliveries are only 82.7% on time. Evidence: late first boxes more than '
        'double early cancellations. Recommendation: a pilot that removes the manual address check. '
        'The curve rises through the conflict and the evidence and falls at the recommendation.',
        'Quatro caixas em fila sob uma curva de tensão. Contexto: as entregas saem 94,5% no prazo. '
        'Conflito: as primeiras entregas saem só 82,7% no prazo. Evidência: a primeira caixa '
        'atrasada mais que dobra o cancelamento precoce. Recomendação: um piloto que tira a '
        'conferência manual de endereço. A curva sobe no conflito e na evidência e cai na '
        'recomendação.'))
    xs = [14, 182, 350, 518]
    heads = [T(lang, 'context', 'contexto'), T(lang, 'conflict', 'conflito'),
             T(lang, 'evidence', 'evidência'), T(lang, 'recommendation', 'recomendação')]
    bodies = [T(lang, ['deliveries are', '94.5% on time'], ['as entregas saem', '94,5% no prazo']),
              T(lang, ['first deliveries are', 'only 82.7% on time'],
                ['as primeiras saem', 'só 82,7% no prazo']),
              T(lang, ['a late first box more', 'than doubles cancelling'],
                ['a 1ª caixa atrasada mais', 'que dobra o cancelamento']),
              T(lang, ['pilot: remove the manual', 'address check'],
                ['piloto: tirar a conferência', 'manual de endereço'])]
    tension = [150, 92, 64, 132]
    pts = [(x + 74, t) for x, t in zip(xs, tension)]
    d = f'M{pts[0][0]:.1f} {pts[0][1]:.1f}'
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        mx = (x0 + x1) / 2
        d += f' C{mx:.1f} {y0:.1f} {mx:.1f} {y1:.1f} {x1:.1f} {y1:.1f}'
    f.path(d, stroke='--amber', width=2)
    for x, y in pts:
        f.circle(x, y, 4, fill='--amber')
    f.text(14, 40, T(lang, 'tension in the room', 'tensão na sala'), size=10, anchor='start',
           fill='--amber')
    for i, (x, h, b) in enumerate(zip(xs, heads, bodies)):
        f.rect(x, 170, 148, 70, stroke='--phosphor' if i == 3 else '--wire', width=1.3)
        f.text(x + 74, 186, h, size=11, weight='600')
        f.lines(x + 74, 206, b, size=9.5, gap=14)
    return f, T(lang,
                'Each part prepares the next: the context gives the conflict something to '
                'disturb, and the recommendation is what releases the tension the evidence built.',
                'Cada parte prepara a seguinte: o contexto dá ao conflito algo para perturbar, e a '
                'recomendação é o que libera a tensão que a evidência construiu.')


@figure('l02-sliver', 2)
def l02_sliver(lang):
    renew_on = S.RENEWAL_DELIVERIES - S.RENEWAL_LATE
    f = Fig('l02-sliver', 680, 232, T(
        lang,
        f'Two horizontal bars. The top one is every delivery in the half-year, '
        f'{S.ALL_DELIVERIES:,}: renewals fill almost all of it and first deliveries are a sliver of '
        f'4.6% at the right-hand end. The bottom bar enlarges that sliver: of {S.NEW:,} first '
        f'deliveries, 82.7% were on time and 17.3% late.',
        f'Duas barras horizontais. A de cima é toda entrega do semestre, '
        f'{num(lang, S.ALL_DELIVERIES, 0)}: as renovações ocupam quase tudo e as primeiras entregas '
        f'são uma fatia de 4,6% na ponta direita. A barra de baixo amplia essa fatia: das '
        f'{num(lang, S.NEW, 0)} primeiras entregas, 82,7% chegaram no prazo e 17,3% atrasaram.'))
    x0, x1 = 30, 650
    W = x1 - x0
    tot = S.ALL_DELIVERIES
    f.text(x0, 24, T(lang, f'all deliveries, {num(lang, tot, 0)}: {pct(lang, S.ALL_ON_TIME)} on time',
                     f'todas as entregas, {num(lang, tot, 0)}: {pct(lang, S.ALL_ON_TIME)} no prazo'),
           size=11, anchor='start', weight='600')
    segs = [(renew_on, '--phosphor-dim', '--phosphor'), (S.RENEWAL_LATE, '--scan', '--amber'),
            (S.NEW, '--paper-dim', '--paper')]
    x = x0
    for n, fill, stroke in segs:
        w = W * n / tot
        f.bar(x, 40, w, 30, fill=fill, stroke=stroke)
        x += w
    first_x = x0 + W * (renew_on + S.RENEWAL_LATE) / tot
    f.text(x0 + 8, 85, T(lang, 'renewals', 'renovações'), size=10, anchor='start')
    f.text(x1, 85, T(lang, 'first deliveries, 4.6%', 'primeiras entregas, 4,6%'), size=10,
           anchor='end')
    f.path(f'M{first_x:.1f} 94 L{x0:.1f} 120 M{x1:.1f} 94 L{x1:.1f} 120', stroke='--paper-dim',
           width=1, dash='3 3')
    won = W * S.FIRST_ON_TIME
    f.bar(x0, 120, won, 30, fill='--phosphor-dim', stroke='--phosphor')
    f.bar(x0 + won, 120, W - won, 30, fill='--scan', stroke='--amber', width=1.6)
    f.text(x0 + won / 2, 164, T(lang, f'on time, {num(lang, S.ON_TIME, 0)}',
                                f'no prazo, {num(lang, S.ON_TIME, 0)}'), size=10)
    f.text(x0 + won + (W - won) / 2, 164, T(lang, f'late, {num(lang, S.LATE, 0)}',
                                             f'atrasadas, {num(lang, S.LATE, 0)}'),
           size=10, fill='--amber')
    f.text(x0, 190, T(lang, f'first deliveries, {num(lang, S.NEW, 0)}: '
                            f'{pct(lang, S.FIRST_ON_TIME)} on time',
                      f'primeiras entregas, {num(lang, S.NEW, 0)}: '
                      f'{pct(lang, S.FIRST_ON_TIME)} no prazo'),
           size=11, anchor='start', weight='600')
    f.text(x0, 218, T(lang, 'the overall rate is set by the renewals; the first box is too small to '
                            'move it',
                      'a taxa geral é definida pelas renovações; a primeira caixa é pequena demais '
                      'para mexer nela'), size=10, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'Sandra’s 94.5% and Marina’s 17.3% late are both correct. First deliveries are '
                'one delivery in twenty-two, so a problem confined to them barely shows in the '
                'overall rate.',
                'Os 94,5% da Sandra e os 17,3% de atraso da Marina estão certos. As primeiras '
                'entregas são uma em cada vinte e duas, então um problema restrito a elas mal aparece '
                'na taxa geral.')


@figure('l02-evidence', 2)
def l02_evidence(lang):
    f = Fig('l02-evidence', 680, 230, T(
        lang,
        'One claim at the top, late first deliveries are costing us customers, resting on three '
        'boxes. The gap is real: 41.5% against 17.4%. It is not the region: the gap holds inside '
        'each one. It is big enough: sized in money in lesson 11. Under each box, the question it '
        'answers.',
        'Uma afirmação no alto, as primeiras entregas atrasadas estão nos custando clientes, apoiada '
        'em três caixas. A distância é real: 41,5% contra 17,4%. Não é a região: a distância se '
        'mantém em cada uma. É grande o bastante: medida em dinheiro na aula 11. Embaixo de cada '
        'caixa, a pergunta que ela responde.'))
    f.rect(140, 12, 400, 40, stroke='--amber', width=1.5)
    f.text(340, 32, T(lang, 'late first deliveries are costing us customers',
                      'as primeiras entregas atrasadas nos custam clientes'),
           size=11.5, weight='600')
    cols = [(T(lang, 'the gap is real', 'a distância é real'),
             T(lang, ['41.5% cancel against', '17.4% in 90 days'], ['41,5% cancelam contra', '17,4% em 90 dias']),
             T(lang, 'is it real?', 'é real?')),
            (T(lang, 'it is not the region', 'não é a região'),
             T(lang, ['the gap holds inside', 'capital and interior'], ['a distância se mantém', 'na capital e no interior']),
             T(lang, 'is it something else?', 'é outra coisa?')),
            (T(lang, 'it is big enough', 'é grande o bastante'),
             T(lang, ['1,058 late first boxes;', 'margin lost: lesson 11'], ['1.058 primeiras atrasadas;', 'margem perdida: aula 11']),
             T(lang, 'does it matter?', 'importa?'))]
    for i, (h, body, q) in enumerate(cols):
        x = 30 + i * 214
        f.line(340, 54, x + 95, 92, stroke='--paper-dim', width=1)
        f.rect(x, 94, 190, 86, stroke='--phosphor', width=1.3)
        f.text(x + 95, 114, h, size=11, weight='600')
        f.lines(x + 95, 140, body, size=9.5, gap=15)
        f.text(x + 95, 202, q, size=10, fill='--paper-dim', italic=True)
    return f, T(lang,
                'Each support answers a question a reasonable sceptic would ask. Evidence that '
                'answers no such question belongs in the appendix.',
                'Cada apoio responde a uma pergunta que um cético razoável faria. Evidência que não '
                'responde a nenhuma pergunta assim vai para o apêndice.')

# ------------------------------------------------------------------ lesson 3

@figure('l03-pyramid', 3)
def l03_pyramid(lang):
    f = Fig('l03-pyramid', 680, 250, T(
        lang,
        'An inverted triangle in three bands. The widest band, at the top, holds the finding and the '
        'request, and everybody reads it. The middle band holds the reasons, most important first, '
        'and most people read it. The narrow tip at the bottom holds the method, the caveats and the '
        'detail, read by few, and in a deck it is the appendix.',
        'Um triângulo invertido em três faixas. A faixa mais larga, no alto, tem o achado e o pedido, '
        'e todo mundo lê. A do meio tem as razões, da mais importante para a menos, e a maioria lê. '
        'A ponta estreita embaixo tem o método, as ressalvas e o detalhe, lida por poucos, e num deck '
        'é o apêndice.'))
    top, bottom, left, right, cx = 20, 236, 30, 450, 240
    ys = [top, 92, 164, bottom]

    def edge(y):
        k = (y - top) / (bottom - top)
        return left + k * (cx - left), right - k * (right - cx)

    fills = [('--phosphor-dim', '--phosphor'), ('--panel', '--wire'), ('--ink', '--wire')]
    texts = [(T(lang, 'the finding and the request', 'o achado e o pedido'), 12, '600'),
             (T(lang, 'the reasons, best first', 'as razões, a melhor primeiro'), 11, None),
             (T(lang, 'method', 'método'), 10, None)]
    notes = [T(lang, 'everybody reads this', 'todo mundo lê'),
             T(lang, 'most people read this', 'a maioria lê'),
             T(lang, 'few read this: the appendix', 'poucos leem: o apêndice')]
    for i in range(3):
        a0, b0 = edge(ys[i])
        a1, b1 = edge(ys[i + 1])
        fill, stroke = fills[i]
        f.path(f'M{a0:.1f} {ys[i]:.1f} L{b0:.1f} {ys[i]:.1f} L{b1:.1f} {ys[i + 1]:.1f} '
               f'L{a1:.1f} {ys[i + 1]:.1f} Z', stroke=stroke, width=1.2, fill=fill)
        mid = (ys[i] + ys[i + 1]) / 2 - (8 if i == 2 else 0)
        t, size, weight = texts[i]
        f.text(cx, mid, t, size=size, weight=weight)
        f.line(b0 - (b0 - b1) / 2 + 12, mid, 470, mid, stroke='--paper-dim', width=1, dash='2 3')
        f.text(478, mid, notes[i], size=10, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'Widest where the weight is. A reader who stops after the top band has the news; '
                'every band below it is for somebody who wants more.',
                'Mais larga onde está o peso. Quem para depois da faixa de cima já tem a notícia; cada '
                'faixa abaixo é para quem quer mais.')


@figure('l03-two-orders', 3)
def l03_two_orders(lang):
    f = Fig('l03-two-orders', 680, 220, T(
        lang,
        'Two strips of slides from 1 to 37. In the order of the work, the data takes slides 2 to 4, '
        'exploration slides 5 to 12, the finding first appears on slide 14 and the recommendation on '
        'slide 37. In the order of the story, the answer is slide 1, context and conflict slides 2 and '
        '3, evidence slides 4 to 6, the recommendation slide 7, and everything else is appendix.',
        'Duas faixas de slides de 1 a 37. Na ordem do trabalho, os dados ocupam os slides 2 a 4, a '
        'exploração os slides 5 a 12, o achado aparece pela primeira vez no slide 14 e a recomendação '
        'no slide 37. Na ordem da história, a resposta é o slide 1, contexto e conflito os slides 2 e '
        '3, a evidência os slides 4 a 6, a recomendação o slide 7, e todo o resto é apêndice.'))
    x0, x1 = 150, 664
    n = 37
    w = (x1 - x0) / n

    def strip(y, spans, title):
        f.text(14, y + 11, title, size=10.5, anchor='start', weight='600')
        for i in range(n):
            f.bar(x0 + i * w + 1, y, w - 2, 22, fill='--ink', stroke='--wire', width=0.8)
        for a, b, fill, stroke in spans:
            f.bar(x0 + (a - 1) * w + 1, y, (b - a + 1) * w - 2, 22, fill=fill, stroke=stroke, width=1)

    strip(40, [(2, 4, '--panel', '--paper-dim'), (5, 12, '--panel', '--paper-dim'),
               (14, 14, '--scan', '--amber'), (37, 37, '--phosphor-dim', '--phosphor')],
          T(lang, 'order of the work', 'ordem do trabalho'))
    f.text(x0 + 1.5 * w, 76, T(lang, 'data', 'dados'), size=9.5, fill='--paper-dim')
    f.text(x0 + 8 * w, 76, T(lang, 'exploration', 'exploração'), size=9.5, fill='--paper-dim')
    f.text(x0 + 13.5 * w, 96, T(lang, 'finding, slide 14', 'achado, slide 14'), size=9.5,
           fill='--amber')
    f.text(x1, 96, T(lang, 'request, slide 37', 'pedido, slide 37'), size=9.5, anchor='end',
           fill='--phosphor')
    strip(130, [(1, 1, '--scan', '--amber'), (2, 3, '--panel', '--paper-dim'),
                (4, 6, '--panel', '--paper-dim'), (7, 7, '--phosphor-dim', '--phosphor')],
          T(lang, 'order of the story', 'ordem da história'))
    f.text(x0, 166, T(lang, 'answer, slide 1', 'resposta, slide 1'), size=9.5, anchor='start',
           fill='--amber')
    f.text(x0 + 6.5 * w, 186, T(lang, 'request, slide 7', 'pedido, slide 7'), size=9.5,
           fill='--phosphor')
    f.text(x0 + 22 * w, 166, T(lang, 'appendix, shown only when asked',
                               'apêndice, mostrado só se perguntarem'),
           size=9.5, fill='--paper-dim')
    return f, T(lang,
                'The same thirty-seven slides in two orders. In the first, the room meets the finding '
                'two-thirds of the way through; in the second, in the first minute.',
                'Os mesmos trinta e sete slides em duas ordens. Na primeira, a sala encontra o achado a '
                'dois terços do caminho; na segunda, no primeiro minuto.')


@figure('l03-minto', 3)
def l03_minto(lang):
    f = Fig('l03-minto', 680, 270, T(
        lang,
        'A tree. At the top, the governing thought: fix first deliveries, starting with a pilot. Under '
        'it, three reasons: the gap is real, it is not the region, it is big enough. Under each '
        'reason, the evidence: 41.5% against 17.4%; the gap holds in the capital and in the interior; '
        'margin lost per year. A bracket marks the three reasons as mutually exclusive and '
        'collectively exhaustive.',
        'Uma árvore. No alto, a ideia governante: consertar as primeiras entregas, começando por um '
        'piloto. Abaixo, três razões: a distância é real, não é a região, é grande o bastante. Sob '
        'cada razão, a evidência: 41,5% contra 17,4%; a distância se mantém na capital e no interior; '
        'margem perdida por ano. Uma chave marca as três razões como mutuamente exclusivas e '
        'coletivamente exaustivas.'))
    f.rect(170, 12, 340, 38, stroke='--amber', width=1.5)
    f.text(340, 31, T(lang, 'fix first deliveries, starting with a pilot',
                      'consertar a 1ª entrega, começando por um piloto'), size=11.5, weight='600')
    reasons = [T(lang, 'the gap is real', 'a distância é real'),
               T(lang, 'it is not the region', 'não é a região'),
               T(lang, 'it is big enough', 'é grande o bastante')]
    leaves = [T(lang, ['41.5% cancel', 'against 17.4%'], ['41,5% cancelam', 'contra 17,4%']),
              T(lang, ['the gap holds in', 'capital and interior'], ['a distância se mantém', 'na capital e no interior']),
              T(lang, ['margin lost', 'per year'], ['margem perdida', 'por ano'])]
    for i in range(3):
        x = 40 + i * 210
        f.line(340, 50, x + 90, 96, stroke='--paper-dim', width=1)
        f.rect(x, 96, 180, 36, stroke='--phosphor', width=1.3)
        f.text(x + 90, 114, reasons[i], size=11, weight='600')
        f.line(x + 90, 132, x + 90, 170, stroke='--paper-dim', width=1)
        f.rect(x + 15, 170, 150, 50, stroke='--wire', width=1.1)
        f.lines(x + 90, 186, leaves[i], size=9.5, gap=15)
    f.path('M40 236 L40 244 L610 244 L610 236', stroke='--paper-dim', width=1)
    f.text(325, 258, T(lang, 'no overlaps, no gaps: mutually exclusive, collectively exhaustive',
                       'sem sobreposição, sem lacuna: mutuamente exclusivas, coletivamente exaustivas'),
           size=10, fill='--paper-dim')
    return f, T(lang,
                'Each level summarises the one below. If a piece of the analysis fits nowhere in the '
                'tree, it is not part of this presentation.',
                'Cada nível resume o de baixo. Se uma parte da análise não cabe em lugar nenhum da '
                'árvore, ela não faz parte desta apresentação.')

# ------------------------------------------------------------------ lesson 4

@figure('l04-openings', 4)
def l04_openings(lang):
    f = Fig('l04-openings', 680, 360, T(
        lang,
        'Four opening slides for the same finding. For the board: late first deliveries cost about '
        'R$ 790 thousand a year in margin. For management: cut late first deliveries with an '
        'eight-week pilot, with the owner and the start date. For the technical team: what late means '
        'in this analysis, with a table of definitions. For Ligeiro, the carrier: the contract '
        'promises two working days, and first orders miss it 17.3% of the time.',
        'Quatro slides de abertura para o mesmo achado. Para o conselho: as primeiras entregas '
        'atrasadas custam cerca de R$ 790 mil por ano em margem. Para a gestão: reduzir o atraso da '
        'primeira entrega com um piloto de oito semanas, com dono e data de início. Para a área '
        'técnica: o que atraso quer dizer nesta análise, com uma tabela de definições. Para a '
        'Ligeiro, a transportadora: o contrato promete dois dias úteis, e os primeiros pedidos '
        'falham nisso 17,3% das vezes.'))
    rooms = [T(lang, 'board', 'conselho'), T(lang, 'management', 'gestão'),
             T(lang, 'technical team', 'área técnica'), T(lang, 'client: Ligeiro', 'cliente: Ligeiro')]
    titles = [T(lang, ['Late first deliveries cost us', 'about R$ 790 thousand a year'],
                ['A 1ª entrega atrasada nos custa', 'cerca de R$ 790 mil por ano']),
              T(lang, ['Cut late first deliveries with', 'an 8-week pilot from 1 Sept'],
                ['Reduzir o atraso da 1ª entrega', 'com um piloto de 8 semanas']),
              T(lang, ['What late means in this', 'analysis, and how it is counted'],
                ['O que atraso quer dizer nesta', 'análise, e como é contado']),
              T(lang, ['Our contract promises two', 'working days; first orders miss it'],
                ['O contrato promete dois dias', 'úteis; os 1ºs pedidos falham'])]
    for i in range(4):
        col, row = i % 2, i // 2
        x, y = 14 + col * 336, 24 + row * 172
        f.text(x, y - 10, rooms[i], size=10, anchor='start', fill='--paper-dim', weight='600')
        f.rect(x, y, 316, 150, stroke='--wire', fill='--ink', rx=3)
        f.lines(x + 14, y + 20, titles[i], size=11.5, anchor='start', weight='600', gap=16)
        cx, cy = x + 14, y + 62
        if i == 0:
            k = round(S.LOSS_PER_YEAR / 100 / 10000) * 10
            f.text(x + 158, cy + 32, T(lang, f'R$ {k} thousand', f'R$ {k} mil'), size=22,
                   weight='600', fill='--amber')
            f.text(x + 158, cy + 60, T(lang, 'customer margin lost each year', 'margem de clientes perdida por ano'),
                   size=9.5, fill='--paper-dim')
        elif i == 1:
            rows = [T(lang, 'lever: remove the address check', 'alavanca: tirar a conferência'),
                    T(lang, 'owner: Sandra’s team', 'dono: equipe da Sandra'),
                    T(lang, 'goal: 17.3% late → 8%', 'meta: 17,3% de atraso → 8%'),
                    T(lang, 'start: 1 September', 'início: 1º de setembro')]
            f.lines(cx, cy + 4, rows, size=10, anchor='start', gap=18)
        elif i == 2:
            rows = [('late', T(lang, 'after the checkout date', 'depois da data da compra')),
                    ('first_delivery', T(lang, 'first box of the subscription', '1ª caixa da assinatura')),
                    ('cancelled_90d', T(lang, 'within 90 days of it', 'em até 90 dias dela'))]
            for k, (term, d) in enumerate(rows):
                f.text(cx, cy + 4 + k * 22, term, size=9.5, anchor='start', mono=True, fill='--phosphor')
                f.text(cx + 120, cy + 4 + k * 22, d, size=9.5, anchor='start')
        else:
            for k, (lab, v, col_) in enumerate([
                    (T(lang, 'renewals', 'renovações'), S.RENEWAL_ON_TIME, '--phosphor'),
                    (T(lang, 'first orders', '1ºs pedidos'), S.FIRST_ON_TIME, '--amber')]):
                yy = cy + 6 + k * 30
                f.text(cx + 82, yy + 8, lab, size=9.5, anchor='end')
                w = (x + 260 - (cx + 90)) * v
                f.bar(cx + 90, yy, w, 16, fill='--scan', stroke=col_, width=1.4)
                f.text(cx + 94 + w, yy + 8, pct(lang, v), size=9.5, anchor='start', fill=col_)
    return f, T(lang,
                'Same finding, four first slides. Each opens with what that room decides and the unit '
                'it thinks in; none would work in another room.',
                'O mesmo achado, quatro primeiros slides. Cada um abre com o que aquela sala decide e a '
                'unidade em que ela pensa; nenhum funcionaria em outra sala.')

# ------------------------------------------------------------------ lesson 5

def region_rates():
    out = []
    for r in S.REGIONS:
        b = S.BY_REGION[r]
        out.append((r, b['late'], b['on time']))
    return out


def grouped_bars(f, x0, y0, x1, y1, lang, grey=False, labels=True, legend=False, size=9.5):
    """Cancellation rate by region, late against on time."""
    p = Plot(f, x0, y0, x1, y1, 0, 2, 0, 0.5)
    names = {'capital': T(lang, 'capital', 'capital'), 'interior': T(lang, 'interior', 'interior')}
    for i, (r, late, on) in enumerate(region_rates()):
        for j, (v, kind) in enumerate([(late, 'late'), (on, 'on')]):
            xa = p.sx(i + 0.18 + j * 0.33)
            xb = xa + (p.sx(0.3) - p.sx(0))
            if grey:
                stroke = '--amber' if kind == 'late' else '--paper-dim'
                fill = '--scan' if kind == 'late' else '--panel'
            else:
                stroke = '--amber' if kind == 'late' else '--phosphor'
                fill = '--scan'
            f.bar(xa, p.sy(v), xb - xa, p.sy(0) - p.sy(v), fill=fill, stroke=stroke, width=1.4)
            if labels:
                f.text((xa + xb) / 2, p.sy(v) - 8, pct(lang, v, 0), size=size,
                       fill='--amber' if kind == 'late' else '--paper')
        f.text(p.sx(i + 0.5), p.y1 + 12, names[r], size=size)
    p.baseline()
    return p


@figure('l05-topic-vs-assertion', 5)
def l05_topic_vs_assertion(lang):
    f = Fig('l05-topic-vs-assertion', 680, 270, T(
        lang,
        'The same grouped bar chart on two slides. On the left the title is a topic: cancellations by '
        'region and first delivery. On the right it is a sentence: the gap holds in the capital and in '
        'the interior. The bars show 39% against 16% in the capital and 44% against 20% in the '
        'interior, late first delivery against on time.',
        'O mesmo gráfico de barras agrupadas em dois slides. À esquerda o título é um assunto: '
        'cancelamentos por região e primeira entrega. À direita é uma frase: a distância se mantém na '
        'capital e no interior. As barras mostram 39% contra 16% na capital e 44% contra 20% no '
        'interior, primeira entrega atrasada contra no prazo.'))
    f.text(170, 12, T(lang, 'a topic', 'um assunto'), size=10, fill='--paper-dim')
    f.text(510, 12, T(lang, 'a sentence', 'uma frase'), size=10, fill='--paper-dim')
    for k, title in enumerate([T(lang, ['Cancellations by region', 'and first delivery'],
                                 ['Cancelamentos por região', 'e primeira entrega']),
                               T(lang, ['The gap holds in the capital', 'and in the interior'],
                                 ['A distância se mantém na', 'capital e no interior'])]):
        x = 10 + k * 340
        f.rect(x, 24, 320, 236, stroke='--phosphor' if k else '--wire', fill='--ink', rx=3)
        f.lines(x + 14, 44, title, size=12, anchor='start', weight='600', gap=17)
        grouped_bars(f, x + 30, 100, x + 300, 222, lang)
        f.text(x + 14, 248, T(lang, 'late first delivery', 'primeira entrega atrasada'), size=9,
               anchor='start', fill='--amber')
        f.text(x + 306, 248, T(lang, 'on time', 'no prazo'), size=9, anchor='end', fill='--phosphor')
    return f, T(lang,
                'Nothing in the chart changed. On the left the reader has to find the point; on the '
                'right the title says it and the chart is there to check it.',
                'Nada no gráfico mudou. À esquerda o leitor precisa achar o ponto; à direita o título o '
                'diz e o gráfico está lá para conferir.')


GHOST = [
    (['Late first boxes more than', 'double early cancellations;', 'we propose a pilot'],
     ['A 1ª caixa atrasada mais', 'que dobra o cancelamento;', 'propomos um piloto']),
    (['Deliveries are on time', '94.5% of the time'], ['As entregas saem no', 'prazo 94,5% das vezes']),
    (['But first deliveries are', 'on time only 82.7%'], ['Mas as primeiras saem', 'no prazo só 82,7%']),
    (['Late first box: 41.5%', 'cancel, against 17.4%'], ['1ª caixa atrasada: 41,5%', 'cancelam, contra 17,4%']),
    (['The gap holds in the', 'capital and the interior'], ['A distância se mantém na', 'capital e no interior']),
    (['It costs about R$ 790', 'thousand a year in margin'], ['Custa cerca de R$ 790 mil', 'por ano em margem']),
    (['Pilot: no address check', 'in the interior, 8 weeks'], ['Piloto: sem conferência', 'no interior, 8 semanas']),
]


@figure('l05-ghost-deck', 5)
def l05_ghost_deck(lang):
    f = Fig('l05-ghost-deck', 680, 250, T(
        lang,
        'Seven empty slides with only their titles. One: late first boxes more than double early '
        'cancellations; we propose a pilot. Two: deliveries are on time 94.5% of the time. Three: but '
        'first deliveries are on time only 82.7%. Four: late first box, 41.5% cancel against 17.4%. '
        'Five: the gap holds in the capital and the interior. Six: it costs about R$ 790 thousand a '
        'year in margin. Seven: pilot, no address check in the interior for eight weeks.',
        'Sete slides vazios, só com os títulos. Um: a primeira caixa atrasada mais que dobra o '
        'cancelamento; propomos um piloto. Dois: as entregas saem no prazo 94,5% das vezes. Três: mas '
        'as primeiras saem no prazo só 82,7%. Quatro: primeira caixa atrasada, 41,5% cancelam contra '
        '17,4%. Cinco: a distância se mantém na capital e no interior. Seis: custa cerca de R$ 790 mil '
        'por ano em margem. Sete: piloto sem conferência no interior por oito semanas.'))
    for i, (en, pt) in enumerate(GHOST):
        row, col = (0, i) if i < 4 else (1, i - 4)
        x = 10 + col * 168 + (84 if row else 0)
        y = 14 + row * 118
        f.rect(x, y, 156, 100, stroke='--amber' if i in (0, 6) else '--wire', fill='--ink', rx=3)
        f.text(x + 8, y + 12, str(i + 1), size=9, anchor='start', fill='--paper-dim', mono=True)
        f.lines(x + 8, y + 32, T(lang, en, pt), size=9.5, anchor='start', weight='600', gap=14)
    return f, T(lang,
                'Faro’s presentation as a ghost deck: titles only, before any chart is drawn. Read '
                'in order, they are the whole story.',
                'A apresentação da Faro como deck fantasma: só títulos, antes de qualquer gráfico. '
                'Lidos em ordem, são a história inteira.')


def monthly_rates():
    out = {}
    for r in S.REGIONS:
        for st in ('late', 'on time'):
            out[(r, st)] = [next(row['cancelled_90d'] / row['subscribers'] for row in S.ROWS
                                 if row['cohort'] == m and row['region'] == r
                                 and row['first_delivery'] == st) for m in S.MONTHS]
    return out


@figure('l05-wrong-chart', 5)
def l05_wrong_chart(lang):
    f = Fig('l05-wrong-chart', 680, 270, T(
        lang,
        'Two charts under the same title, late first deliveries more than double cancellations. On '
        'the left, four lines of the monthly cancellation rate from January to June, one per region '
        'and first-delivery status, tangled between 15% and 50%. On the right, two bars: 41.5% for '
        'late first deliveries and 17.4% for on-time ones.',
        'Dois gráficos sob o mesmo título, a primeira entrega atrasada mais que dobra o '
        'cancelamento. À esquerda, quatro linhas da taxa mensal de cancelamento de janeiro a junho, '
        'uma por região e situação da primeira entrega, emaranhadas entre 15% e 50%. À direita, duas '
        'barras: 41,5% para a primeira entrega atrasada e 17,4% para a no prazo.'))
    f.text(340, 14, T(lang, 'Late first deliveries more than double cancellations',
                      'A primeira entrega atrasada mais que dobra o cancelamento'),
           size=12, weight='600')
    f.rect(10, 30, 400, 230, stroke='--wire', fill='--ink', rx=3)
    f.rect(430, 30, 240, 230, stroke='--phosphor', fill='--ink', rx=3)
    p = Plot(f, 60, 56, 330, 220, 0, 5, 0.1, 0.55)
    p.yaxis([0.2, 0.3, 0.4, 0.5], fmt=lambda v: pct(lang, v, 0), size=8.5)
    mr = monthly_rates()
    styles = {('capital', 'late'): ('--amber', None), ('interior', 'late'): ('--amber', '4 3'),
              ('capital', 'on time'): ('--phosphor', None), ('interior', 'on time'): ('--phosphor', '4 3')}
    months = T(lang, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'], ['jan', 'fev', 'mar', 'abr', 'mai', 'jun'])
    for i, m in enumerate(months):
        f.text(p.sx(i), p.y1 + 12, m, size=8.5, fill='--paper-dim')
    p.baseline()
    for key, ys in mr.items():
        stroke, dash = styles[key]
        p.polyline(range(6), ys, stroke=stroke, width=1.6, dash=dash)
    lab = {('capital', 'late'): T(lang, 'capital, late', 'capital, atrasada'),
           ('interior', 'late'): T(lang, 'interior, late', 'interior, atrasada'),
           ('capital', 'on time'): T(lang, 'capital, on time', 'capital, no prazo'),
           ('interior', 'on time'): T(lang, 'interior, on time', 'interior, no prazo')}
    order = sorted(mr, key=lambda k: -mr[k][-1])
    for n, key in enumerate(order):
        y = p.sy(mr[key][-1])
        y = [y - 6, y + 6][n % 2] if n < 2 else [y - 6, y + 6][n % 2]
        f.text(p.x1 + 6, y, lab[key], size=8.5, anchor='start', fill=styles[key][0])
    f.text(24, 250, T(lang, 'four lines to compare and average in your head',
                      'quatro linhas para comparar e somar de cabeça'), size=9.5, anchor='start',
           fill='--paper-dim')
    q = Plot(f, 470, 70, 640, 220, 0, 2, 0, 0.5)
    for i, (lab2, v, col) in enumerate([(T(lang, 'late', 'atrasada'), S.RATE_LATE, '--amber'),
                                        (T(lang, 'on time', 'no prazo'), S.RATE_ON, '--phosphor')]):
        xa, xb = q.sx(i + 0.2), q.sx(i + 0.8)
        f.bar(xa, q.sy(v), xb - xa, q.sy(0) - q.sy(v), fill='--scan', stroke=col, width=1.6)
        f.text((xa + xb) / 2, q.sy(v) - 10, pct(lang, v), size=11, weight='600', fill=col)
        f.text((xa + xb) / 2, q.y1 + 12, lab2, size=9.5)
    q.baseline()
    f.text(550, 250, T(lang, 'the comparison the title makes', 'a comparação que o título faz'),
           size=9.5, fill='--paper-dim')
    return f, T(lang,
                'Both charts are correct. Only the one on the right draws the sentence above it; the '
                'monthly lines answer another question and belong in the appendix.',
                'Os dois gráficos estão certos. Só o da direita desenha a frase de cima; as linhas '
                'mensais respondem a outra pergunta e vão para o apêndice.')


@figure('l05-emphasis', 5)
def l05_emphasis(lang):
    f = Fig('l05-emphasis', 680, 270, T(
        lang,
        'The regional chart twice. Before: four bars in two colours, a legend box in the corner, '
        'heavy gridlines and no values. After: the on-time bars are grey, the late bars are the only '
        'coloured marks, each bar carries its value, the legend is gone and a note beside the late '
        'bars says more than double, in both regions.',
        'O gráfico por região duas vezes. Antes: quatro barras em duas cores, uma caixa de legenda '
        'no canto, linhas de grade pesadas e nenhum valor. Depois: as barras no prazo são cinza, as '
        'de atraso são as únicas marcas coloridas, cada barra traz o valor, a legenda sumiu e uma '
        'nota ao lado das barras de atraso diz mais que o dobro, nas duas regiões.'))
    f.text(170, 12, T(lang, 'before', 'antes'), size=10, fill='--paper-dim')
    f.text(510, 12, T(lang, 'after', 'depois'), size=10, fill='--paper-dim')
    f.rect(10, 24, 320, 236, stroke='--wire', fill='--ink', rx=3)
    p = Plot(f, 60, 50, 230, 222, 0, 2, 0, 0.5)
    for t in [0.1, 0.2, 0.3, 0.4, 0.5]:
        f.line(p.x0, p.sy(t), p.x1, p.sy(t), stroke='--paper-dim', width=1)
        f.text(p.x0 - 6, p.sy(t), pct(lang, t, 0), size=8.5, anchor='end', fill='--paper-dim')
    grouped_bars(f, 60, 50, 230, 222, lang, labels=False)
    f.rect(240, 70, 82, 50, stroke='--paper-dim', fill='--panel', rx=2)
    f.bar(248, 80, 10, 10, fill='--scan', stroke='--amber')
    f.text(262, 85, T(lang, 'late', 'atraso'), size=9, anchor='start')
    f.bar(248, 100, 10, 10, fill='--scan', stroke='--phosphor')
    f.text(262, 105, T(lang, 'on time', 'prazo'), size=9, anchor='start')
    f.rect(350, 24, 320, 236, stroke='--phosphor', fill='--ink', rx=3)
    grouped_bars(f, 380, 60, 600, 222, lang, grey=True)
    f.lines(612, 92, T(lang, ['more', 'than', 'double,', 'in both', 'regions'],
                       ['mais', 'que o', 'dobro,', 'nas duas', 'regiões']),
            size=9.5, anchor='start', fill='--amber', gap=13)
    f.text(364, 248, T(lang, 'in colour: late first delivery; grey: on time',
                       'em cor: primeira entrega atrasada; cinza: no prazo'), size=9, anchor='start',
           fill='--paper-dim')
    return f, T(lang,
                'Same data, same chart type. The version on the right decides what the eye sees '
                'first, and puts the point where the eye already is.',
                'Mesmos dados, mesmo tipo de gráfico. A versão da direita decide o que o olho vê '
                'primeiro e põe o ponto onde o olho já está.')


@picture('l05-two-messages')
def p_l05_two_messages():
    """A slide with no words. Marks, in label order: second chart, distant legend,
    tiny footnote, decoration, title running to three lines."""
    f = Fig('l05-two-messages', 720, 405,
            'A slide drawn with no words. Three grey bars stand for a title running to three lines. '
            'Below on the left is a bar chart of five bars, one of them coloured; on the right a second '
            'chart, a line rising across six points. In the bottom right corner is a legend box with two '
            'colour squares, far from both charts. Along the bottom edge runs a row of tiny bars like '
            'small print. In the top right corner is a decorative round emblem.')
    f.rect(10, 10, 700, 385, stroke='--paper-dim', fill='--ink', rx=4)
    for k, w in enumerate([520, 560, 300]):
        f.bar(36, 32 + k * 22, w, 12, fill='--paper-dim', stroke='--paper-dim')
    f.circle(664, 50, 22, fill='--panel', stroke='--paper-dim', width=2)
    f.circle(664, 50, 10, fill='--paper-dim')
    # left chart
    f.line(40, 320, 330, 320, stroke='--paper-dim', width=1.4)
    for k, h in enumerate([90, 130, 70, 160, 110]):
        x = 56 + k * 54
        hl = k == 3
        f.bar(x, 320 - h, 36, h, fill='--amber' if hl else '--panel',
              stroke='--amber' if hl else '--paper-dim')
    # right chart
    f.line(380, 320, 640, 320, stroke='--paper-dim', width=1.4)
    f.line(380, 140, 380, 320, stroke='--paper-dim', width=1.4)
    ys = [290, 270, 276, 240, 210, 180]
    f.path('M' + ' L'.join(f'{400 + k * 44} {y}' for k, y in enumerate(ys)), stroke='--phosphor',
           width=2.4)
    for k, y in enumerate(ys):
        f.circle(400 + k * 44, y, 4, fill='--phosphor')
    # legend far away
    f.rect(600, 335, 96, 42, stroke='--paper-dim', fill='--panel', rx=2)
    f.bar(610, 343, 10, 10, fill='--amber', stroke='--amber')
    f.bar(626, 345, 50, 6, fill='--paper-dim', stroke='--paper-dim')
    f.bar(610, 360, 10, 10, fill='--phosphor', stroke='--phosphor')
    f.bar(626, 362, 50, 6, fill='--paper-dim', stroke='--paper-dim')
    # footnote
    for k in range(6):
        f.bar(36 + k * 88, 372, 76, 3, fill='--paper-dim', stroke='--paper-dim', width=0.5)
    marks = [(510, 230), (648, 356), (250, 373), (664, 50), (300, 54)]
    return f, marks

# ------------------------------------------------------------------ lesson 6

def two_bars(f, x0, y0, x1, y1, lang, late=('--scan', '--amber'), on=('--scan', '--paper-dim'),
             values=True, size=10):
    p = Plot(f, x0, y0, x1, y1, 0, 2, 0, 0.5)
    for i, (lab, v, (fill, stroke)) in enumerate([(T(lang, 'late', 'atrasada'), S.RATE_LATE, late),
                                                  (T(lang, 'on time', 'no prazo'), S.RATE_ON, on)]):
        xa, xb = p.sx(i + 0.22), p.sx(i + 0.78)
        f.bar(xa, p.sy(v), xb - xa, p.sy(0) - p.sy(v), fill=fill, stroke=stroke, width=1.4)
        if values:
            f.text((xa + xb) / 2, p.sy(v) - 9, pct(lang, v), size=size, fill='--paper')
        f.text((xa + xb) / 2, p.y1 + 12, lab, size=size)
    p.baseline()
    return p


@figure('l06-contrast', 6)
def l06_contrast(lang):
    f = Fig('l06-contrast', 680, 260, T(
        lang,
        'Two versions of one slide. Weak contrast: the title, the labels and the source note are all '
        'about the same size and weight, and the two bars are two shades of one colour. Strong '
        'contrast: a large heavy title, the late bar the only coloured mark, and a small grey source '
        'note.',
        'Duas versões de um slide. Contraste fraco: o título, os rótulos e a nota de fonte têm quase o '
        'mesmo tamanho e peso, e as duas barras são dois tons de uma cor. Contraste forte: um título '
        'grande e pesado, a barra de atraso como única marca colorida e uma nota de fonte pequena e '
        'cinza.'))
    f.text(170, 12, T(lang, 'weak contrast', 'contraste fraco'), size=10, fill='--paper-dim')
    f.text(510, 12, T(lang, 'strong contrast', 'contraste forte'), size=10, fill='--paper-dim')
    f.rect(10, 24, 320, 228, stroke='--wire', fill='--ink', rx=3)
    f.lines(24, 44, T(lang, ['Late first deliveries and', 'early cancellations'],
                      ['Primeiras entregas atrasadas', 'e cancelamento precoce']),
            size=11, anchor='start', gap=15)
    two_bars(f, 50, 92, 300, 206, lang, late=('--phosphor-dim', '--phosphor'),
             on=('--phosphor-dim', '--phosphor'), size=11)
    f.text(24, 238, T(lang, 'Source: orders, deliveries, cancellations', 'Fonte: pedidos, entregas, cancelamentos'),
           size=10.5, anchor='start')
    f.rect(350, 24, 320, 228, stroke='--phosphor', fill='--ink', rx=3)
    f.lines(364, 46, T(lang, ['Late first boxes more than', 'double early cancellations'],
                       ['A 1ª caixa atrasada mais que', 'dobra o cancelamento precoce']),
            size=14, anchor='start', weight='600', gap=19)
    two_bars(f, 390, 100, 640, 206, lang)
    f.text(364, 238, T(lang, 'Source: orders, deliveries, cancellations', 'Fonte: pedidos, entregas, cancelamentos'),
           size=8.5, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'On the left everything is about equally loud, so the eye wanders. On the right the '
                'reading order is claim, evidence, source, because the differences are large.',
                'À esquerda tudo tem mais ou menos o mesmo volume, então o olho vagueia. À direita a '
                'ordem de leitura é afirmação, evidência, fonte, porque as diferenças são grandes.')


@figure('l06-alignment', 6)
def l06_alignment(lang):
    f = Fig('l06-alignment', 680, 260, T(
        lang,
        'Two versions of one slide. Unaligned: the title, the chart and the source note each start '
        'at a different distance from the left edge, and the note beside the chart floats at its own '
        'height. Aligned: a dashed guide shows the title, the chart axis and the source note starting '
        'on one vertical line, and the note sharing the top edge of the chart.',
        'Duas versões de um slide. Desalinhado: o título, o gráfico e a nota de fonte começam cada '
        'um a uma distância diferente da borda esquerda, e a nota ao lado do gráfico flutua na própria '
        'altura. Alinhado: uma guia tracejada mostra o título, o eixo do gráfico e a nota de fonte '
        'começando na mesma linha vertical, e a nota compartilhando a borda de cima do gráfico.'))
    f.text(170, 12, T(lang, 'unaligned', 'desalinhado'), size=10, fill='--paper-dim')
    f.text(510, 12, T(lang, 'aligned', 'alinhado'), size=10, fill='--paper-dim')
    title = T(lang, ['Late first boxes more than', 'double early cancellations'],
              ['A 1ª caixa atrasada mais que', 'dobra o cancelamento precoce'])
    note = T(lang, ['more than', 'double'], ['mais que', 'o dobro'])
    src = T(lang, 'Source: Faro, H1 2025', 'Fonte: Faro, 1º sem. 2025')
    f.rect(10, 24, 320, 228, stroke='--wire', fill='--ink', rx=3)
    f.lines(40, 46, title, size=12, anchor='start', weight='600', gap=16)
    two_bars(f, 30, 104, 230, 206, lang)
    f.lines(252, 150, note, size=10, anchor='start', fill='--amber', gap=14)
    f.text(56, 238, src, size=9, anchor='start', fill='--paper-dim')
    f.rect(350, 24, 320, 228, stroke='--phosphor', fill='--ink', rx=3)
    f.line(366, 32, 366, 244, stroke='--paper-dim', width=1, dash='3 4')
    f.lines(366, 46, title, size=12, anchor='start', weight='600', gap=16)
    two_bars(f, 366, 104, 566, 206, lang)
    f.lines(590, 104, note, size=10, anchor='start', fill='--amber', gap=14)
    f.text(366, 238, src, size=9, anchor='start', fill='--paper-dim')
    return f, T(lang,
                'Nothing was added on the right; three things moved a few millimetres onto one line. '
                'The slide now looks put together on purpose.',
                'Nada foi acrescentado à direita; três coisas se moveram alguns milímetros para a mesma '
                'linha. O slide agora parece montado de propósito.')


@figure('l06-repetition', 6)
def l06_repetition(lang):
    f = Fig('l06-repetition', 680, 270, T(
        lang,
        'Two rows of three small slides. In the top row the colour of late deliveries changes from '
        'slide to slide, and on the third slide the first colour stands for the capital instead. In '
        'the bottom row late deliveries are the same colour on every slide and everything else is '
        'grey.',
        'Duas linhas de três slides pequenos. Na linha de cima a cor dos atrasos muda de slide para '
        'slide, e no terceiro a primeira cor representa a capital. Na linha de baixo os atrasos têm a '
        'mesma cor em todo slide e todo o resto é cinza.'))
    f.text(14, 16, T(lang, 'each slide chooses its own colours', 'cada slide escolhe as próprias cores'),
           size=10, anchor='start', fill='--paper-dim')
    f.text(14, 146, T(lang, 'one colour means late, everywhere', 'uma cor quer dizer atraso, em todo lugar'),
           size=10, anchor='start', fill='--paper-dim')
    late, other, grey = ('--scan', '--amber'), ('--scan', '--phosphor'), ('--panel', '--paper-dim')
    rows = [[(late, grey, T(lang, 'late', 'atraso')), (other, grey, T(lang, 'late', 'atraso')),
             (grey, late, T(lang, 'capital', 'capital'))],
            [(late, grey, T(lang, 'late', 'atraso')), (late, grey, T(lang, 'late', 'atraso')),
             (late, grey, T(lang, 'late', 'atraso'))]]
    for r, row in enumerate(rows):
        for c, (a, b, lab) in enumerate(row):
            x, y = 14 + c * 224, 26 + r * 130
            f.rect(x, y, 204, 108, stroke='--wire', fill='--ink', rx=3)
            f.bar(x + 14, y + 12, 120, 8, fill='--paper-dim', stroke='--paper-dim')
            for k, (h, col) in enumerate([(60, a), (30, b), (52, a), (24, b)]):
                xx = x + 22 + k * 34
                f.bar(xx, y + 92 - h, 24, h, fill=col[0], stroke=col[1], width=1.4)
            f.line(x + 14, y + 92, x + 160, y + 92, stroke='--paper-dim', width=1)
            f.text(x + 196, y + 40, lab, size=9.5, anchor='end',
                   fill=a[1] if a[1] != '--paper-dim' else b[1])
    return f, T(lang,
                'A reader carries the meaning of a colour from one slide to the next. In the top row '
                'that habit misleads them on the third slide; in the bottom row it saves them reading '
                'a legend.',
                'O leitor leva o significado de uma cor de um slide para o outro. Na linha de cima esse '
                'hábito o engana no terceiro slide; na de baixo, poupa a leitura de uma legenda.')


@figure('l06-whitespace', 6)
def l06_whitespace(lang):
    f = Fig('l06-whitespace', 680, 250, T(
        lang,
        'Two versions of a slide with three numbers and their labels. Evenly spread: numbers and '
        'labels sit at equal distances from one another, so it is unclear which label belongs to which '
        'number. Grouped: each label sits right under its number, and wide gaps separate the three '
        'pairs.',
        'Duas versões de um slide com três números e seus rótulos. Espalhado por igual: números e '
        'rótulos ficam à mesma distância uns dos outros, então não fica claro qual rótulo é de qual '
        'número. Agrupado: cada rótulo fica logo abaixo do seu número, e espaços largos separam os '
        'três pares.'))
    f.text(170, 12, T(lang, 'evenly spread', 'espalhado por igual'), size=10, fill='--paper-dim')
    f.text(510, 12, T(lang, 'grouped by space', 'agrupado pelo espaço'), size=10, fill='--paper-dim')
    nums = [pct(lang, S.LATE_SHARE_ALL), pct(lang, S.RATE_LATE), pct(lang, S.RATE_ON)]
    labs = [T(lang, 'first boxes late', '1ªs caixas atrasadas'),
            T(lang, 'cancel if late', 'cancelam se atrasou'),
            T(lang, 'cancel if on time', 'cancelam se no prazo')]
    head = T(lang, 'The first box, in three numbers', 'A primeira caixa em três números')
    f.rect(10, 24, 320, 218, stroke='--wire', fill='--ink', rx=3)
    f.text(24, 42, head, size=11.5, anchor='start', weight='600')
    for k in range(3):
        f.text(24, 74 + k * 50, nums[k], size=15, anchor='start', weight='600')
        f.text(24, 99 + k * 50, labs[k], size=10, anchor='start', fill='--paper-dim')
    f.rect(350, 24, 320, 218, stroke='--phosphor', fill='--ink', rx=3)
    f.text(364, 42, head, size=11.5, anchor='start', weight='600')
    for k in range(3):
        cx = 405 + k * 104
        f.text(cx, 130, nums[k], size=17, weight='600', fill='--amber' if k == 1 else '--paper')
        f.text(cx, 150, labs[k], size=9, fill='--paper-dim')
    return f, T(lang,
                'Nothing frames the groups on the right. The space between pairs is wider than the '
                'space inside them, and that alone says which label belongs to which number.',
                'Nada emoldura os grupos à direita. O espaço entre os pares é maior que o espaço dentro '
                'deles, e só isso diz qual rótulo é de qual número.')


@picture('l06-layout')
def p_l06_layout():
    """Marks, in label order: off the grid, no margin, caption far from its chart,
    text too faint, competing sizes (no hierarchy)."""
    f = Fig('l06-layout', 720, 405,
            'A slide drawn with no words. Grey bars stand for a title near the top left. Below it, a '
            'block of text bars starts noticeably further right than the title. A bar chart sits on the '
            'left; a short caption for it is placed far away on the right-hand side. At the very right '
            'edge, a column of text bars touches the frame. Near the bottom, a line of text bars is '
            'drawn so faint it almost disappears. Two large numbers of exactly the same size stand side '
            'by side at the top right.')
    f.rect(10, 10, 700, 385, stroke='--paper-dim', fill='--ink', rx=4)
    f.bar(40, 34, 300, 14, fill='--paper-dim', stroke='--paper-dim')
    for k, w in enumerate([240, 220, 180]):
        f.bar(84, 74 + k * 16, w, 7, fill='--paper-dim', stroke='--paper-dim')
    f.line(40, 320, 300, 320, stroke='--paper-dim', width=1.4)
    for k, h in enumerate([80, 120, 60, 140]):
        f.bar(56 + k * 60, 320 - h, 40, h, fill='--panel', stroke='--paper-dim')
    for k, w in enumerate([110, 90]):
        f.bar(470, 250 + k * 14, w, 6, fill='--paper-dim', stroke='--paper-dim')
    for k in range(5):
        f.bar(664, 150 + k * 16, 44, 6, fill='--paper-dim', stroke='--paper-dim')
    for k in range(4):
        f.bar(40 + k * 110, 362, 96, 5, fill='--panel', stroke='--wire', width=0.6)
    f.text(470, 50, '17', size=34, weight='600', fill='--paper')
    f.text(560, 50, '41', size=34, weight='600', fill='--paper')
    marks = [(190, 90), (686, 182), (520, 260), (230, 364), (515, 50)]
    return f, marks

# ------------------------------------------------------------------ lesson 7

TARGET_FIRST = 0.95


def june_rate():
    rows = [r for r in S.ROWS if r['cohort'] == S.MONTHS[-1]]
    return sum(r['cancelled_90d'] for r in rows) / sum(r['subscribers'] for r in rows)


def sparkline(f, x0, y0, w, h, ys, stroke='--phosphor', target=None, lo=None, hi=None):
    lo = min(ys) if lo is None else lo
    hi = max(ys) if hi is None else hi
    pts = [(x0 + w * i / (len(ys) - 1), y0 + h - (v - lo) / (hi - lo) * h) for i, v in enumerate(ys)]
    if target is not None:
        ty = y0 + h - (target - lo) / (hi - lo) * h
        f.line(x0, ty, x0 + w, ty, stroke='--paper-dim', width=1, dash='3 3')
    f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke=stroke, width=1.6)
    f.circle(pts[-1][0], pts[-1][1], 2.6, fill=stroke)


@figure('l07-wireframe', 7)
def l07_wireframe(lang):
    last = S.WEEKLY_FIRST[-1] / 100
    f = Fig('l07-wireframe', 680, 330, T(
        lang,
        'Faro’s redesigned dashboard in four numbered zones. Zone 1, top left: first deliveries on '
        'time last week, 84.1% against a target of 95%, and the June cohort’s 90-day cancellation '
        'rate, 21.6%. Zone 2, top right: first deliveries on time by region, 86.7% in the capital and '
        '76.4% in the interior. Zone 3: the weekly first-delivery rate over 26 weeks with the target '
        'line above it. Zone 4, along the bottom: orders, revenue and all deliveries on time, 94.5%, '
        'drawn small.',
        'O painel redesenhado da Faro em quatro zonas numeradas. Zona 1, no alto à esquerda: primeiras '
        'entregas no prazo na semana passada, 84,1% contra meta de 95%, e a taxa de cancelamento em '
        '90 dias da coorte de junho, 21,6%. Zona 2, no alto à direita: primeiras entregas no prazo por '
        'região, 86,7% na capital e 76,4% no interior. Zona 3: a taxa semanal de primeira entrega em 26 '
        'semanas com a linha da meta acima. Zona 4, embaixo: pedidos, receita e todas as entregas no '
        'prazo, 94,5%, em tamanho pequeno.'))
    f.rect(10, 10, 660, 310, stroke='--wire', fill='--ink', rx=4)

    def badge(x, y, n):
        f.circle(x, y, 9, fill='--amber')
        f.text(x, y + 0.5, str(n), size=10, weight='600', fill='--ink')

    # zone 1
    for k, (val, lab, sub) in enumerate([
            (pct(lang, last), T(lang, 'first deliveries on time', '1ªs entregas no prazo'),
             T(lang, 'target 95%, below', 'meta 95%, abaixo')),
            (pct(lang, june_rate()), T(lang, 'cancelled in 90 days', 'cancelaram em 90 dias'),
             T(lang, 'June cohort', 'coorte de junho'))]):
        x = 24 + k * 162
        f.rect(x, 26, 150, 96, stroke='--amber' if k == 0 else '--wire', fill='--panel', rx=3)
        f.text(x + 12, 56, val, size=24, anchor='start', weight='600',
               fill='--amber' if k == 0 else '--paper')
        f.text(x + 12, 84, lab, size=9.5, anchor='start')
        f.text(x + 12, 102, sub, size=9, anchor='start', fill='--paper-dim')
    badge(24, 26, 1)
    # zone 2
    f.rect(356, 26, 300, 96, stroke='--wire', fill='--panel', rx=3)
    f.text(368, 42, T(lang, 'first deliveries on time, by region', '1ªs entregas no prazo, por região'),
           size=9.5, anchor='start', fill='--paper-dim')
    for k, r in enumerate(S.REGIONS):
        v = 1 - S.BY_REGION[r]['late_share']
        y = 58 + k * 28
        f.text(430, y + 8, T(lang, r, r), size=9.5, anchor='end')
        w = 170 * v
        f.bar(438, y, w, 16, fill='--scan', stroke='--amber' if v < 0.8 else '--paper-dim', width=1.3)
        f.text(442 + w, y + 8, pct(lang, v), size=9.5, anchor='start')
    badge(356, 26, 2)
    # zone 3
    f.rect(24, 136, 632, 112, stroke='--wire', fill='--panel', rx=3)
    f.text(36, 152, T(lang, 'first deliveries on time, weekly, with the 95% target',
                      '1ªs entregas no prazo, por semana, com a meta de 95%'),
           size=9.5, anchor='start', fill='--paper-dim')
    sparkline(f, 40, 168, 600, 66, [v / 100 for v in S.WEEKLY_FIRST], stroke='--amber',
              target=TARGET_FIRST, lo=0.78, hi=0.97)
    badge(24, 136, 3)
    # zone 4
    small = [(T(lang, 'orders', 'pedidos'), None), (T(lang, 'revenue', 'receita'), None),
             (T(lang, 'all deliveries on time', 'todas no prazo'), pct(lang, S.ALL_ON_TIME))]
    for k, (lab, val) in enumerate(small):
        x = 24 + k * 214
        f.rect(x, 262, 204, 44, stroke='--wire', fill='--panel', rx=3)
        f.text(x + 10, 278, lab, size=9, anchor='start', fill='--paper-dim')
        if val:
            f.text(x + 10, 294, val, size=11, anchor='start')
        else:
            f.bar(x + 10, 290, 60, 6, fill='--paper-dim', stroke='--paper-dim', width=0.6)
    badge(24, 262, 4)
    return f, T(lang,
                'The answer to “are we all right?” is where the eye lands first; where the problem is '
                'sits beside it; what changed runs underneath; everything else is small at the bottom.',
                'A resposta a “estamos bem?” fica onde o olho cai primeiro; onde está o problema fica ao '
                'lado; o que mudou corre embaixo; todo o resto fica pequeno no rodapé.')


@figure('l07-kpi-context', 7)
def l07_kpi_context(lang):
    last = S.WEEKLY_FIRST[-1] / 100
    f = Fig('l07-kpi-context', 680, 190, T(
        lang,
        'The same number on three tiles. The first shows only 84.1%. The second adds the target, '
        '95%, and says it is below. The third adds the week before, level, and a sparkline of 26 '
        'weeks that stays between 80% and 85%, well under the dashed target line.',
        'O mesmo número em três blocos. O primeiro mostra só 84,1%. O segundo acrescenta a meta, 95%, '
        'e diz que está abaixo. O terceiro acrescenta a semana anterior, igual, e uma sparkline de 26 '
        'semanas que fica entre 80% e 85%, bem abaixo da linha tracejada da meta.'))
    heads = [T(lang, 'a number', 'um número'), T(lang, 'against a target', 'contra uma meta'),
             T(lang, 'target, last week and trend', 'meta, semana anterior e tendência')]
    for k in range(3):
        x = 10 + k * 226
        f.text(x + 103, 14, heads[k], size=10, fill='--paper-dim')
        f.rect(x, 26, 206, 152, stroke='--amber' if k else '--wire', fill='--panel', rx=3)
        f.text(x + 14, 46, T(lang, 'first deliveries on time', '1ªs entregas no prazo'), size=9.5,
               anchor='start', fill='--paper-dim')
        f.text(x + 14, 80, pct(lang, last), size=26, anchor='start', weight='600',
               fill='--amber' if k else '--paper')
        if k >= 1:
            f.text(x + 14, 110, T(lang, 'below the 95% target', 'abaixo da meta de 95%'), size=9.5,
                   anchor='start', fill='--amber')
        if k == 2:
            f.text(x + 14, 128, T(lang, 'level with the week before', 'igual à semana anterior'),
                   size=9.5, anchor='start')
            sparkline(f, x + 14, 140, 176, 28, [v / 100 for v in S.WEEKLY_FIRST], stroke='--amber',
                      target=TARGET_FIRST, lo=0.78, hi=0.97)
    return f, T(lang,
                'Only the third tile answers “are we all right?”, “is it moving?” and “is this week '
                'typical?” in one look.',
                'Só o terceiro bloco responde “estamos bem?”, “está mudando?” e “esta semana é típica?” '
                'numa olhada.')


@figure('l07-leading', 7)
def l07_leading(lang):
    f = Fig('l07-leading', 680, 200, T(
        lang,
        'A timeline in weeks from 0 to 14. At week 0 a new subscriber’s first box arrives on time or '
        'late, and the first-delivery rate shows it the same week: the leading indicator. At about '
        'week 13, ninety days later, the cancellation within 90 days is finally known: the lagging '
        'indicator. A bracket between them is labelled ninety days in which only the leading one can '
        'warn you.',
        'Uma linha do tempo em semanas de 0 a 14. Na semana 0 a primeira caixa de um assinante novo '
        'chega no prazo ou atrasada, e a taxa de primeira entrega mostra isso na mesma semana: o '
        'indicador antecedente. Por volta da semana 13, noventa dias depois, o cancelamento em 90 dias '
        'finalmente é conhecido: o indicador consequente. Uma chave entre os dois diz noventa dias em '
        'que só o antecedente pode avisar.'))
    p = Plot(f, 40, 60, 640, 120, 0, 14, 0, 1)
    p.baseline()
    for w in range(0, 15, 2):
        f.line(p.sx(w), 120, p.sx(w), 125, stroke='--paper-dim', width=1)
        f.text(p.sx(w), 136, str(w), size=9, fill='--paper-dim')
    f.text(640, 156, T(lang, 'weeks after the first box', 'semanas depois da 1ª caixa'), size=9.5,
           anchor='end', fill='--paper-dim')
    for wk, col, head, sub in [(0, '--phosphor', T(lang, 'first box: on time or late', '1ª caixa: no prazo ou atrasada'),
                                T(lang, 'leading: seen this week', 'antecedente: visto nesta semana')),
                               (90 / 7, '--amber', T(lang, 'cancelled within 90 days?', 'cancelou em 90 dias?'),
                                T(lang, 'lagging: known now', 'consequente: conhecido agora'))]:
        x = p.sx(wk)
        f.circle(x, 120, 6, fill=col)
        f.line(x, 114, x, 70, stroke=col, width=1.4)
        f.text(x, 46, head, size=10.5, weight='600', fill=col,
               anchor='start' if wk == 0 else 'end')
        f.text(x, 62, sub, size=9.5, anchor='start' if wk == 0 else 'end', fill='--paper-dim')
    x0, x1 = p.sx(0) + 10, p.sx(90 / 7) - 10
    f.path(f'M{x0:.1f} 100 L{x0:.1f} 106 L{x1:.1f} 106 L{x1:.1f} 100', stroke='--paper-dim', width=1)
    f.text((x0 + x1) / 2, 92, T(lang, 'ninety days in which only the leading indicator can warn you',
                                'noventa dias em que só o antecedente pode avisar'),
           size=9.5, fill='--paper-dim')
    f.text(40, 180, T(lang, 'a change made today appears in the cancellation rate a quarter later',
                      'uma mudança feita hoje aparece no cancelamento um trimestre depois'),
           size=9.5, anchor='start')
    return f, T(lang,
                'The outcome Faro cares about arrives ninety days late. The first-delivery rate moves '
                'the same week, which is why it gets the top-left corner.',
                'O resultado que importa à Faro chega com noventa dias de atraso. A taxa de primeira '
                'entrega se mexe na mesma semana, e é por isso que ganha o canto superior esquerdo.')


@figure('l07-bullet', 7)
def l07_bullet(lang):
    last = S.WEEKLY_FIRST[-1] / 100
    f = Fig('l07-bullet', 680, 200, T(
        lang,
        'The same number twice. On the left, a gauge: a half-circle dial with a needle at 84.1% and '
        'coloured arcs, taking a large square of space. On the right, a bullet graph: a thin bar to '
        '84.1%, a short vertical line at the 95% target, and three grey bands behind it for poor, fair '
        'and good, in a single row.',
        'O mesmo número duas vezes. À esquerda, um mostrador: um semicírculo com ponteiro em 84,1% e '
        'arcos coloridos, ocupando um quadrado grande. À direita, um gráfico de bala: uma barra fina até '
        '84,1%, um traço vertical na meta de 95% e três faixas cinza ao fundo para ruim, regular e bom, '
        'numa única linha.'))
    import math
    f.text(130, 14, T(lang, 'gauge', 'mostrador'), size=10, fill='--paper-dim')
    f.text(450, 14, T(lang, 'bullet graph', 'gráfico de bala'), size=10, fill='--paper-dim')
    f.rect(10, 26, 240, 164, stroke='--wire', fill='--ink', rx=3)
    cx, cy, r = 130, 150, 90

    def arc(a0, a1, col):
        p0 = (cx - r * math.cos(math.pi * a0), cy - r * math.sin(math.pi * a0))
        p1 = (cx - r * math.cos(math.pi * a1), cy - r * math.sin(math.pi * a1))
        f.path(f'M{p0[0]:.1f} {p0[1]:.1f} A{r} {r} 0 0 1 {p1[0]:.1f} {p1[1]:.1f}', stroke=col, width=10)
    arc(0.0, 0.6, '--amber')
    arc(0.6, 0.85, '--paper-dim')
    arc(0.85, 1.0, '--phosphor')
    a = last
    f.line(cx, cy, cx - 70 * math.cos(math.pi * a), cy - 70 * math.sin(math.pi * a), stroke='--paper',
           width=2.4)
    f.circle(cx, cy, 5, fill='--paper')
    f.text(cx, cy + 20, pct(lang, last), size=12, weight='600')
    f.rect(270, 26, 400, 164, stroke='--phosphor', fill='--ink', rx=3)
    x0, x1 = 300, 640
    lo = 0.7

    def sx(v):
        return x0 + (v - lo) / (1 - lo) * (x1 - x0)
    for a_, b_, fill in [(0.7, 0.85, '--panel'), (0.85, 0.92, '--scan'), (0.92, 1.0, '--wire')]:
        f.bar(sx(a_), 84, sx(b_) - sx(a_), 34, fill=fill, stroke=None, width=0)
    f.bar(sx(lo), 94, sx(last) - sx(lo), 14, fill='--amber', stroke='--amber')
    f.line(sx(TARGET_FIRST), 80, sx(TARGET_FIRST), 122, stroke='--paper', width=2.4)
    f.text(sx(TARGET_FIRST), 70, T(lang, 'target 95%', 'meta 95%'), size=9.5)
    f.text(sx(last), 134, pct(lang, last), size=10, weight='600', fill='--amber')
    for v in (0.7, 0.8, 0.9, 1.0):
        f.text(sx(v), 156, pct(lang, v, 0), size=9, fill='--paper-dim')
    f.text(x0, 46, T(lang, 'first deliveries on time', '1ªs entregas no prazo'), size=10, anchor='start')
    f.text(x0, 178, T(lang, 'grey bands: poor, fair, good', 'faixas cinza: ruim, regular, bom'), size=9,
           anchor='start', fill='--paper-dim')
    return f, T(lang,
                'The bullet graph carries the value, the target and the ranges in one row, and lines up '
                'with the next one. The gauge spends a square on one number.',
                'O gráfico de bala carrega o valor, a meta e as faixas numa linha, e se alinha com o '
                'próximo. O mostrador gasta um quadrado num número só.')


@picture('l07-dashboard')
def p_l07_dashboard():
    """Marks, in label order: a gauge, a pie with too many slices, a number with no
    comparison, the key number placed last, a map nobody asked for."""
    import math
    f = Fig('l07-dashboard', 720, 405,
            'A dashboard drawn with no words. Top left, a large half-circle gauge with a needle. Top '
            'middle, a pie chart cut into ten thin slices. Top right, a tile holding the number 94 and '
            'nothing else. Middle left, a blob-shaped map filled with shades. Middle right, a table of '
            'grey bars. Bottom right corner, a small tile with a coloured number 84 and a thin target '
            'line.')
    f.rect(10, 10, 700, 385, stroke='--paper-dim', fill='--ink', rx=4)
    cx, cy, r = 120, 140, 80
    f.path(f'M{cx - r} {cy} A{r} {r} 0 0 1 {cx + r} {cy}', stroke='--paper-dim', width=12)
    f.line(cx, cy, cx + 50, cy - 50, stroke='--paper', width=3)
    f.circle(cx, cy, 6, fill='--paper')
    pcx, pcy, pr = 330, 100, 64
    fills = ['--panel', '--scan', '--paper-dim', '--wire']
    a0 = 0.0
    for k, share in enumerate([0.2, 0.15, 0.12, 0.1, 0.1, 0.09, 0.08, 0.07, 0.05, 0.04]):
        a1 = a0 + share * 2 * math.pi
        p0 = (pcx + pr * math.cos(a0), pcy + pr * math.sin(a0))
        p1 = (pcx + pr * math.cos(a1), pcy + pr * math.sin(a1))
        large = 1 if share > 0.5 else 0
        f.path(f'M{pcx} {pcy} L{p0[0]:.1f} {p0[1]:.1f} A{pr} {pr} 0 {large} 1 {p1[0]:.1f} {p1[1]:.1f} Z',
               stroke='--ink', width=1, fill=fills[k % 4])
        a0 = a1
    f.rect(470, 40, 200, 110, stroke='--paper-dim', fill='--panel', rx=3)
    f.text(570, 98, '94', size=44, weight='600', fill='--paper')
    f.path('M40 220 C70 190 140 190 170 215 C200 240 250 230 260 270 C270 310 200 330 150 320 '
           'C100 312 60 300 50 270 C42 250 30 240 40 220 Z', stroke='--paper-dim', width=1.4,
           fill='--scan')
    for k in range(5):
        f.bar(320, 200 + k * 20, 260, 8, fill='--paper-dim', stroke='--paper-dim', width=0.5)
    f.rect(600, 300, 96, 80, stroke='--paper-dim', fill='--panel', rx=3)
    f.text(648, 334, '84', size=24, weight='600', fill='--amber')
    f.line(612, 360, 684, 360, stroke='--paper-dim', width=1)
    f.line(670, 352, 670, 368, stroke='--paper', width=2)
    marks = [(120, 110), (330, 100), (570, 95), (648, 340), (150, 262)]
    return f, marks

# ------------------------------------------------------------------ lesson 8

PAGE = {
    'en': {
        'header': [('To', 'Paulo, Director of Operations (cc Renata, Sandra)'), ('From', 'Marina, Data'),
                   ('Date', 'Monday 18 August 2025'), ('Decision by', 'Friday 22 August')],
        'title': 'Late first deliveries are costing us customers',
        'blocks': [
            ('Finding', 'One new subscriber in six gets their first box late (17.3% in the first half of '
                        '2025), and those customers cancel within 90 days at 41.5%, against 17.4% for '
                        'everybody else. The gap holds in the capital and in the interior.'),
            ('Impact', 'About 510 customers a year cancel early who would otherwise have stayed. The '
                       'margin they would have brought over their lifetime is about R$ 790 thousand a '
                       'year, and Faro also spends about R$ 78 thousand a year acquiring them. The cause '
                       'is mostly inside our warehouse: a manual address check on first orders that uses '
                       'one of the two promised days.'),
            ('Next step', 'Approve an eight-week pilot in the interior, from 1 September, that removes the '
                          'manual check for addresses the postcode lookup confirms. Owner: Sandra’s team. '
                          'Cost: no new spending; the risk of more mis-delivered boxes is measured during '
                          'the pilot. Success: late first deliveries in the interior down from 23.6% to 8% '
                          'or less. Review: 27 October.'),
        ],
        'foot': 'Full analysis, definitions and arithmetic: first-delivery deck, appendix A to F.',
    },
    'pt': {
        'header': [('Para', 'Paulo, diretor de operações (cc Renata, Sandra)'), ('De', 'Marina, Dados'),
                   ('Data', 'segunda-feira, 18 de agosto de 2025'), ('Decisão até', 'sexta-feira, 22 de agosto')],
        'title': 'As primeiras entregas atrasadas estão nos custando clientes',
        'blocks': [
            ('Achado', 'Um em cada seis assinantes novos recebe a primeira caixa atrasada (17,3% no '
                       'primeiro semestre de 2025), e esses clientes cancelam em 90 dias em 41,5%, contra '
                       '17,4% de todos os outros. A distância se mantém na capital e no interior.'),
            ('Impacto', 'Cerca de 510 clientes por ano cancelam cedo e de outro modo teriam ficado. A '
                        'margem que eles trariam ao longo da vida é de cerca de R$ 790 mil por ano, e a '
                        'Faro ainda gasta cerca de R$ 78 mil por ano para conquistá-los. A causa está '
                        'principalmente no nosso depósito: uma conferência manual de endereço nos primeiros '
                        'pedidos que gasta um dos dois dias prometidos.'),
            ('Próximo passo', 'Aprovar um piloto de oito semanas no interior, a partir de 1º de setembro, '
                              'que retira a conferência manual dos endereços que a consulta de CEP confirma. '
                              'Dono: equipe da Sandra. Custo: nenhum gasto novo; o risco de mais caixas '
                              'entregues no endereço errado é medido durante o piloto. Sucesso: primeiras '
                              'entregas atrasadas no interior caindo de 23,6% para 8% ou menos. Revisão: 27 '
                              'de outubro.'),
        ],
        'foot': 'Análise completa, definições e contas: deck da primeira entrega, apêndice A a F.',
    },
}


@figure('l08-page', 8)
def l08_page(lang):
    import textwrap
    P = PAGE[lang]
    counts = [len(textwrap.wrap(b, 104)) for _, b in PAGE['en']['blocks']]

    def wrap_n(text, n):
        # the same number of lines in both languages, so the labels pair up
        for w in range(60, 140):
            ls = textwrap.wrap(text, w)
            if len(ls) == n:
                return ls
        raise SystemExit(f'l08-page: cannot wrap into {n} lines')
    wrapped = [(h, wrap_n(b, n)) for (h, b), n in zip(P['blocks'], counts)]
    h = 150 + sum(30 + 15 * len(ls) for _, ls in wrapped) + 40
    f = Fig('l08-page', 680, h, T(
        lang,
        'Faro’s executive summary as one page. A header says it is for Paulo, from Marina, dated '
        '18 August 2025, with a decision needed by 22 August. A title states that late first '
        'deliveries are costing customers. Three headed blocks follow: Finding, Impact and Next step, '
        'each a short paragraph. A last line points to the full analysis.',
        'O sumário executivo da Faro numa página. Um cabeçalho diz que é para o Paulo, da Marina, '
        'datado de 18 de agosto de 2025, com decisão necessária até 22 de agosto. Um título diz que as '
        'primeiras entregas atrasadas estão custando clientes. Seguem três blocos com título: Achado, '
        'Impacto e Próximo passo, cada um um parágrafo curto. Uma última linha aponta para a análise '
        'completa.'))
    f.rect(20, 8, 640, h - 16, stroke='--wire', fill='--panel', rx=3)
    y = 32
    for k, v in P['header']:
        f.text(44, y, k, size=9.5, anchor='start', fill='--paper-dim', weight='600')
        f.text(150, y, v, size=9.5, anchor='start', fill='--amber' if k in ('Decision by', 'Decisão até') else '--paper')
        y += 16
    f.line(44, y, 636, y, stroke='--wire', width=1)
    y += 26
    f.text(44, y, P['title'], size=14, anchor='start', weight='600')
    y += 30
    for head, ls in wrapped:
        f.text(44, y, head, size=11, anchor='start', weight='600', fill='--phosphor')
        y += 18
        for line in ls:
            f.text(44, y, line, size=9.5, anchor='start')
            y += 15
        y += 12
    f.line(44, y - 4, 636, y - 4, stroke='--wire', width=1)
    f.text(44, y + 12, P['foot'], size=9, anchor='start', fill='--paper-dim', italic=True)
    return f, T(lang,
                'Header, title, three blocks and a pointer to the rest. Each reader can find their own '
                'part without reading the others.',
                'Cabeçalho, título, três blocos e um ponteiro para o resto. Cada leitor acha a sua parte '
                'sem ler as outras.')


@picture('l08-summary-page')
def p_l08_summary_page():
    """Marks, in label order: header, finding, impact, next step, pointer to the rest."""
    f = Fig('l08-summary-page', 720, 405,
            'A page drawn with no words. At the top, four short lines of small bars in two columns form '
            'a header. Below, one thick bar stands for a title. Then three blocks, each led by a short '
            'heavy bar: the first block has two lines of text bars; the second has three lines and the '
            'number 790; the third has three lines and a small box with a tick. At the bottom, one thin '
            'line of bars under a rule.')
    f.rect(150, 8, 420, 389, stroke='--paper-dim', fill='--ink', rx=3)
    for k in range(4):
        f.bar(176, 24 + k * 12, 50, 5, fill='--paper-dim', stroke='--paper-dim', width=0.5)
        f.bar(240, 24 + k * 12, [180, 90, 140, 110][k], 5, fill='--paper-dim', stroke='--paper-dim', width=0.5)
    f.line(176, 76, 544, 76, stroke='--paper-dim', width=1)
    f.bar(176, 88, 300, 12, fill='--paper', stroke='--paper')
    y = 118
    marks = [(300, 42)]
    for b, (lines, extra) in enumerate([(2, None), (3, '790'), (3, 'tick')]):
        f.bar(176, y, 70, 8, fill='--phosphor', stroke='--phosphor')
        top = y
        y += 16
        for k in range(lines):
            full = 300 if extra else 360
            f.bar(176, y, full - (40 if k == lines - 1 else 0), 5, fill='--paper-dim', stroke='--paper-dim', width=0.5)
            y += 11
        if extra == '790':
            f.text(500, top + 20, '790', size=18, weight='600', fill='--amber')
        if extra == 'tick':
            f.rect(500, top + 6, 26, 26, stroke='--paper', fill='--panel', rx=2)
            f.path(f'M506 {top + 19} L512 {top + 26} L522 {top + 12}', stroke='--phosphor', width=2.4)
        marks.append((300, (top + y) / 2))
        y += 26
    f.line(176, 340, 544, 340, stroke='--paper-dim', width=1)
    f.bar(176, 352, 240, 5, fill='--paper-dim', stroke='--paper-dim', width=0.5)
    marks.append((300, 355))
    return f, marks

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
