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
        'R$ 793 thousand a year in margin. For management: cut late first deliveries with an '
        'eight-week pilot, with the owner and the start date. For the technical team: what late means '
        'in this analysis, with a table of definitions. For Ligeiro, the carrier: the contract '
        'promises two working days, and first orders miss it 17.3% of the time.',
        'Quatro slides de abertura para o mesmo achado. Para o conselho: as primeiras entregas '
        'atrasadas custam cerca de R$ 793 mil por ano em margem. Para a gestão: reduzir o atraso da '
        'primeira entrega com um piloto de oito semanas, com dono e data de início. Para a área '
        'técnica: o que atraso quer dizer nesta análise, com uma tabela de definições. Para a '
        'Ligeiro, a transportadora: o contrato promete dois dias úteis, e os primeiros pedidos '
        'falham nisso 17,3% das vezes.'))
    rooms = [T(lang, 'board', 'conselho'), T(lang, 'management', 'gestão'),
             T(lang, 'technical team', 'área técnica'), T(lang, 'client: Ligeiro', 'cliente: Ligeiro')]
    titles = [T(lang, ['Late first deliveries cost us', 'about R$ 793 thousand a year'],
                ['A 1ª entrega atrasada nos custa', 'cerca de R$ 793 mil por ano']),
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
            k = round(S.LOSS_PER_YEAR / 100 / 1000)
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
