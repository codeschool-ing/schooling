#!/usr/bin/env python3
"""Every diagram in the process-management course, drawn in code.

A diagram drawn by hand is a claim nobody can check twice. These are drawn from
sheet.py where they show numbers — a burndown, a cycle-time chart, a velocity
range, a risk matrix — so a figure cannot drift from the sentence beside it, and
the conceptual ones (a Scrum cycle, a Kanban board, the ITIL change flow) are
drawn here too so that both languages come from one drawing.

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

The drawing helpers are the statistics course's, copied rather than imported,
because a course directory is not a package and one course's figures must not
break when another's are redrawn.

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
import sheet as S  # noqa: E402,F401

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
            mid = f'pm-ah{stroke.replace("--", "-")}'
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


def box(f, x, y, w, h, lines, stroke='--wire', fill='--panel', size=10.5, fills=None, weights=None,
        mono=False, lh=None, rx=4, width=1.2, dash=None):
    """A rectangle with one or more centred lines of text inside it."""
    f.rect(x, y, w, h, stroke=stroke, fill=fill, rx=rx, width=width, dash=dash)
    lh = lh or size * 1.35
    top = y + h / 2 - lh * (len(lines) - 1) / 2
    for i, t in enumerate(lines):
        f.text(x + w / 2, top + i * lh, t, size=size,
               fill=(fills[i] if fills else '--paper'),
               weight=(weights[i] if weights else None), mono=mono)


def arrow(f, x1, y1, x2, y2, stroke='--paper-dim', width=1.4, dash=None):
    f.line(x1, y1, x2, y2, stroke=stroke, width=width, arrow=True, dash=dash)


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

@figure('l01-waterfall', 1)
def l01_waterfall(lang):
    t = {
        'en': dict(phases=['Requirements', 'Design', 'Implementation', 'Verification', 'Operation'],
                   back='what Royce added: each phase hands problems back',
                   twice='and he asked for it all to be done twice',
                   label='Five phases stepped down from left to right: requirements, design, implementation, '
                         'verification and operation. Solid arrows run down from each phase to the next. '
                         'Dashed arrows run back up from each phase to the one before, which is what Royce '
                         'added to the plain sequence in 1970.',
                   cap='The sequence everybody calls waterfall, and the dashed arrows its own author drew. '
                       'Royce presented the straight run down as the version that invites failure.'),
        'pt': dict(phases=['Requisitos', 'Projeto', 'Implementação', 'Verificação', 'Operação'],
                   back='o que Royce acrescentou: cada fase devolve problemas',
                   twice='e ele pediu que tudo fosse feito duas vezes',
                   label='Cinco fases em escada, da esquerda para a direita: requisitos, projeto, '
                         'implementação, verificação e operação. Setas cheias descem de cada fase para a '
                         'seguinte. Setas tracejadas sobem de cada fase para a anterior, que é o que Royce '
                         'acrescentou à sequência simples em 1970.',
                   cap='A sequência que todo mundo chama de cascata, e as setas tracejadas que o próprio autor '
                       'desenhou. Royce apresentou a descida em linha reta como a versão que convida ao fracasso.'),
    }[lang]
    f = Fig('l01-waterfall', 640, 320, t['label'])
    w, h, dy = 130, 32, 58
    for i, name in enumerate(t['phases']):
        x, y = 20 + i * 118, 24 + i * dy
        box(f, x, y, w, h, [name], stroke='--phosphor' if i == 0 else '--wire', weights=['600'])
        if i < 4:
            arrow(f, x + w - 22, y + h, x + w - 22, y + dy - 2, stroke='--paper-dim', width=1.6)
        if i > 0:
            arrow(f, x + 22, y - 2, x + 22, y - dy + h + 2, stroke='--amber', dash='4 3', width=1.6)
    f.text(360, 46, t['back'], size=10.5, anchor='start', fill='--amber')
    f.text(360, 64, t['twice'], size=10.5, anchor='start', fill='--paper-dim')
    return f, t['cap']


@figure('l01-two-ways', 1)
def l01_two_ways(lang):
    t = {
        'en': dict(inc='incremental', it='iterative', both='both, which is what agile does',
                   rounds=['first delivery', 'second', 'third'],
                   inc_note='one finished piece at a time',
                   it_note='the whole thing, rough, then better',
                   both_note='a thin slice, finished, then widened',
                   label='Three rows, three deliveries each. Incremental: one third of the product finished, '
                         'then two thirds, then all of it. Iterative: the whole product as a faint sketch, '
                         'then half filled in, then complete. Both: a thin finished slice that grows wider '
                         'and deeper each time.',
                   cap='Incremental adds finished pieces; iterative revisits the whole. Most agile teams do both: '
                       'each delivery is a working slice, and the next one improves what is already there.'),
        'pt': dict(inc='incremental', it='iterativo', both='os dois, que é o que o ágil faz',
                   rounds=['primeira entrega', 'segunda', 'terceira'],
                   inc_note='uma parte pronta de cada vez',
                   it_note='o todo, tosco, depois melhor',
                   both_note='uma fatia fina, pronta, depois ampliada',
                   label='Três linhas, três entregas cada. Incremental: um terço do produto pronto, depois '
                         'dois terços, depois tudo. Iterativo: o produto inteiro como um esboço fraco, depois '
                         'meio preenchido, depois completo. Os dois: uma fatia fina pronta que fica mais larga '
                         'e mais funda a cada vez.',
                   cap='O incremental soma partes prontas; o iterativo revisita o todo. A maioria dos times ágeis '
                       'faz os dois: cada entrega é uma fatia que funciona, e a seguinte melhora o que já existe.'),
    }[lang]
    f = Fig('l01-two-ways', 660, 300, t['label'])
    x0, cw, gap = 190, 130, 18
    for j, r in enumerate(t['rounds']):
        f.text(x0 + j * (cw + gap) + cw / 2, 22, r, size=10, fill='--paper-dim')
    rows = [(t['inc'], t['inc_note']), (t['it'], t['it_note']), (t['both'], t['both_note'])]
    for i, (name, note) in enumerate(rows):
        y = 44 + i * 84
        f.text(20, y + 22, name, size=11, anchor='start', weight='600')
        f.text(20, y + 40, note, size=9.5, anchor='start', fill='--paper-dim')
        for j in range(3):
            x = x0 + j * (cw + gap)
            f.rect(x, y, cw, 56, stroke='--wire', fill='--panel', rx=3)
            if i == 0:
                f.rect(x, y, cw * (j + 1) / 3, 56, stroke='--phosphor', fill='--phosphor-dim', rx=3)
            elif i == 1:
                for k in range(j + 1):
                    f.rect(x + 4, y + 4 + k * 0, cw - 8, 48, stroke='--phosphor' if j == 2 else '--paper-dim',
                           fill='--scan' if j < 2 else '--phosphor-dim', rx=2, dash=None if j == 2 else '3 3')
            else:
                wdt = cw * (j + 1) / 3
                hgt = 18 + j * 19
                f.rect(x, y + 56 - hgt, wdt, hgt, stroke='--phosphor', fill='--phosphor-dim', rx=2)
    return f, t['cap']


@figure('l01-cone', 1)
def l01_cone(lang):
    t = {
        'en': dict(stages=['initial idea', 'product defined', 'requirements done', 'interface designed',
                           'detailed design', 'shipped'],
                   y='actual effort as a multiple of the estimate',
                   note='the cone narrows when decisions are made, not when time passes',
                   label='A cone lying on its side. At the initial idea the actual effort can be anywhere from '
                         'a quarter to four times the estimate. The range narrows to half to double when the '
                         'product is defined, two thirds to one and a half when the requirements are done, '
                         'and close to one by the detailed design.',
                   cap='The cone of uncertainty as McConnell drew it from Boehm’s data. A four-times overrun on '
                       'an estimate made at the initial idea is inside the range, not a failure of the people '
                       'who made it.'),
        'pt': dict(stages=['ideia inicial', 'produto definido', 'requisitos prontos', 'interface desenhada',
                           'projeto detalhado', 'entregue'],
                   y='esforço real como múltiplo da estimativa',
                   note='o cone estreita quando decisões são tomadas, não quando o tempo passa',
                   label='Um cone deitado. Na ideia inicial o esforço real pode ficar entre um quarto e quatro '
                         'vezes a estimativa. A faixa estreita para metade a o dobro quando o produto está '
                         'definido, dois terços a uma vez e meia quando os requisitos estão prontos, e perto de '
                         'um no projeto detalhado.',
                   cap='O cone da incerteza como McConnell o desenhou a partir dos dados de Boehm. Um estouro de '
                       'quatro vezes numa estimativa feita na ideia inicial está dentro da faixa, não é falha de '
                       'quem estimou.'),
    }[lang]
    f = Fig('l01-cone', 640, 300, t['label'])
    hi = [4, 2, 1.5, 1.25, 1.1, 1]
    lo = [0.25, 0.5, 0.67, 0.8, 0.9, 1]
    x0, x1, yt, yb = 90, 600, 40, 230
    def sy(v):
        return yb - (math.log2(v) + 2) / 4 * (yb - yt)
    def sx(i):
        return x0 + i * (x1 - x0) / 5
    for v, lab in ((4, '4×'), (2, '2×'), (1, '1×'), (0.5, '0.5×' if lang == 'en' else '0,5×'),
                   (0.25, '0.25×' if lang == 'en' else '0,25×')):
        f.line(x0, sy(v), x1, sy(v), stroke='--wire', width=1)
        f.text(x0 - 8, sy(v), lab, size=9.5, anchor='end', fill='--paper-dim')
    up = 'M' + ' L'.join(f'{sx(i):.1f} {sy(v):.1f}' for i, v in enumerate(hi))
    dn = ' L'.join(f'{sx(i):.1f} {sy(v):.1f}' for i, v in reversed(list(enumerate(lo))))
    f.path(up + ' L' + dn + ' Z', stroke='--phosphor', width=1.6, fill='--scan')
    f.line(x0, sy(1), x1, sy(1), stroke='--paper-dim', width=1.2, dash='4 3')
    for i, s in enumerate(t['stages']):
        f.line(sx(i), yb, sx(i), yb + 4, stroke='--paper-dim', width=1)
        f.text(sx(i), yb + 16, s, size=9.5, fill='--paper-dim',
               anchor='start' if i == 0 else 'end' if i == 5 else 'middle')
    f.text(x0, 20, t['y'], size=10, anchor='start', weight='600')
    f.text(x1, 270, t['note'], size=10, anchor='end', fill='--amber')
    return f, t['cap']

# ---- end of lesson 1


# ------------------------------------------------------------------ lesson 2

@figure('l02-sprint', 2)
def l02_sprint(lang):
    t = {
        'en': dict(pb='Product Backlog', pg='Product Goal', planning='Sprint Planning',
                   sb='Sprint Backlog', sg='Sprint Goal', daily='Daily Scrum', daily2='15 minutes, every day',
                   sprint='the Sprint: one month or less', inc='Increment', dod='Definition of Done',
                   review='Sprint Review', retro='Sprint Retrospective', refine='refinement, ongoing',
                   next='the next Sprint starts at once',
                   label='The Scrum cycle. The Product Backlog, committed to a Product Goal, feeds Sprint '
                         'Planning, which produces the Sprint Backlog with its Sprint Goal. Inside a Sprint of '
                         'one month or less the Developers meet each day in a 15-minute Daily Scrum. The Sprint '
                         'produces an Increment that meets the Definition of Done, shown at the Sprint Review; '
                         'the Sprint Retrospective follows, and the next Sprint starts at once.',
                   cap='Five events, three artefacts and the commitment attached to each artefact, as the 2020 Scrum '
                       'Guide arranges them. Refinement is an activity, not an event, which is why it has no box.'),
        'pt': dict(pb='Product Backlog', pg='Meta do Produto', planning='Planejamento da Sprint',
                   sb='Sprint Backlog', sg='Meta da Sprint', daily='Daily Scrum', daily2='15 minutos, todo dia',
                   sprint='a Sprint: um mês ou menos', inc='Incremento', dod='Definição de Pronto',
                   review='Revisão da Sprint', retro='Retrospectiva da Sprint', refine='refinamento, contínuo',
                   next='a próxima Sprint começa em seguida',
                   label='O ciclo do Scrum. O Product Backlog, comprometido com uma Meta do Produto, alimenta o '
                         'Planejamento da Sprint, que produz o Sprint Backlog com a Meta da Sprint. Dentro de uma '
                         'Sprint de um mês ou menos, os Desenvolvedores se reúnem todo dia numa Daily Scrum de 15 '
                         'minutos. A Sprint produz um Incremento que atende à Definição de Pronto, mostrado na '
                         'Revisão da Sprint; depois vem a Retrospectiva, e a próxima Sprint começa em seguida.',
                   cap='Cinco eventos, três artefatos e o compromisso preso a cada artefato, como o Guia do Scrum de '
                       '2020 os organiza. O refinamento é uma atividade, não um evento, e por isso não tem caixa.'),
    }[lang]
    f = Fig('l02-sprint', 700, 300, t['label'])
    box(f, 14, 40, 130, 54, [t['pb'], t['pg']], stroke='--phosphor', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10)
    f.text(79, 112, t['refine'], size=9.5, fill='--paper-dim')
    arrow(f, 146, 67, 172, 67)
    box(f, 174, 44, 120, 46, [t['planning']], weights=['600'], size=10)
    arrow(f, 296, 67, 318, 67)
    box(f, 320, 40, 120, 54, [t['sb'], t['sg']], stroke='--phosphor', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10)
    # the sprint band
    f.rect(170, 130, 360, 70, stroke='--amber', fill='--scan', rx=6, dash='5 3')
    f.text(350, 145, t['sprint'], size=10, fill='--amber', weight='600')
    f.circle(350, 176, 13, fill=None, stroke='--paper', width=1.4)
    f.text(350, 176, '24h' if lang == 'en' else '24h', size=8.5, mono=True)
    f.text(372, 172, t['daily'], size=10, anchor='start', weight='600')
    f.text(372, 186, t['daily2'], size=9.5, anchor='start', fill='--paper-dim')
    arrow(f, 380, 96, 380, 128)
    arrow(f, 532, 165, 556, 165)
    box(f, 558, 138, 128, 54, [t['inc'], t['dod']], stroke='--phosphor', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10)
    arrow(f, 622, 194, 622, 222)
    box(f, 520, 224, 166, 34, [t['review']], weights=['600'], size=10)
    arrow(f, 518, 241, 452, 241)
    box(f, 270, 224, 180, 34, [t['retro']], weights=['600'], size=10)
    f.path('M268 241 L120 241 L120 96', stroke='--paper-dim', width=1.4, dash='4 3', arrow=True)
    f.text(194, 272, t['next'], size=9.5, fill='--paper-dim')
    return f, t['cap']


@figure('l02-burndown', 2)
def l02_burndown(lang):
    t = {
        'en': dict(y='points still open', x='day of the sprint', ideal='ideal line', actual='what happened',
                   left='5 points left over', flat='flat: nothing finished',
                   label='A burndown over ten days. The ideal line falls from 34 points to zero. The actual line '
                         'stays at 34 after day 1, drops to 31, stays flat on day 3, falls to 26, 23, stays at 23 '
                         'on day 6, then falls to 18, 13, 8 and ends at 5 points on day 10.',
                   cap='The Agenda team’s sprint, from the course’s sheet. The flat stretches are days on which '
                       'work was done and nothing reached Done, and the line ends above zero.'),
        'pt': dict(y='pontos ainda abertos', x='dia da sprint', ideal='linha ideal', actual='o que aconteceu',
                   left='sobraram 5 pontos', flat='plano: nada terminou',
                   label='Um burndown de dez dias. A linha ideal cai de 34 pontos a zero. A linha real fica em 34 '
                         'depois do dia 1, cai para 31, fica plana no dia 3, cai para 26 e 23, fica em 23 no dia 6, '
                         'depois cai para 18, 13, 8 e termina em 5 pontos no dia 10.',
                   cap='A sprint do time Agenda, a partir da planilha do curso. Os trechos planos são dias em que '
                       'houve trabalho e nada chegou a Pronto, e a linha termina acima de zero.'),
    }[lang]
    f = Fig('l02-burndown', 640, 300, t['label'])
    p = Plot(f, 70, 40, 510, 240, 0, 10, 0, 35)
    p.yaxis([0, 5, 10, 15, 20, 25, 30, 35], label=t['y'])
    p.xaxis(range(0, 11), label=t['x'])
    f.line(p.sx(0), p.sy(34), p.sx(10), p.sy(0), stroke='--paper-dim', width=1.4, dash='5 4')
    d = 'M' + ' L'.join(f'{p.sx(i):.1f} {p.sy(v):.1f}' for i, v in enumerate(S.BURNDOWN))
    f.path(d, stroke='--phosphor', width=2.2)
    for i, v in enumerate(S.BURNDOWN):
        f.circle(p.sx(i), p.sy(v), 3, fill='--phosphor')
    f.text(p.sx(2.6), p.sy(17), t['ideal'], size=10, anchor='middle', fill='--paper-dim')
    f.text(p.sx(4.2), p.sy(30), t['actual'], size=10, anchor='start', fill='--phosphor', weight='600')
    f.text(p.sx(10) + 10, p.sy(5), t['left'], size=10, anchor='start', fill='--amber', weight='600')
    f.text(p.sx(6), p.sy(23) - 14, t['flat'], size=9.5, anchor='middle', fill='--amber')
    return f, t['cap']

# ---- end of lesson 2


# ------------------------------------------------------------------ lesson 3

@figure('l03-board', 3)
def l03_board(lang):
    t = {
        'en': dict(cols=['Ready', 'Developing', 'Review', 'Testing', 'Done'], doing='doing', done='done',
                   commit='commitment point: the clock starts', deliver='the clock stops',
                   pull='work is pulled from the left when a column has room',
                   label='A Kanban board with five columns. Ready has a limit of 5 and holds 4 cards. Developing '
                         'has a limit of 3, split into doing and done, and holds 3. Review has a limit of 2 and '
                         'holds 2. Testing has a limit of 2 and holds 1. Done has no limit and holds 10. The clock '
                         'starts when a card leaves Ready and stops when it reaches Done.',
                   cap='The Agenda team’s board on the morning of 16 March. Developing and Review are full, so '
                       'nobody may start anything new there; the free slot is in Testing, and the way to use it is '
                       'to help finish what is in Review.'),
        'pt': dict(cols=['Pronto p/ começar', 'Desenvolvendo', 'Revisão', 'Teste', 'Feito'], doing='fazendo',
                   done='feito', commit='ponto de compromisso: o relógio começa', deliver='o relógio para',
                   pull='o trabalho é puxado da esquerda quando uma coluna tem espaço',
                   label='Um quadro Kanban com cinco colunas. Pronto para começar tem limite 5 e quatro cartões. '
                         'Desenvolvendo tem limite 3, dividida em fazendo e feito, e três cartões. Revisão tem '
                         'limite 2 e dois cartões. Teste tem limite 2 e um cartão. Feito não tem limite e tem dez '
                         'cartões. O relógio começa quando um cartão sai de Pronto para começar e para quando '
                         'chega a Feito.',
                   cap='O quadro do time Agenda na manhã de 16 de março. Desenvolvendo e Revisão estão cheias, então '
                       'ninguém pode começar nada novo ali; a vaga livre está em Teste, e o jeito de usá-la é ajudar '
                       'a terminar o que está em Revisão.'),
    }[lang]
    f = Fig('l03-board', 700, 330, t['label'])
    widths = [118, 150, 118, 118, 150]
    x = 14
    cards = {0: ['AG-122', 'AG-123', 'AG-124', 'AG-125'], 1: ['AG-117', 'AG-121', 'AG-111'],
             2: ['AG-113', 'AG-102'], 3: ['AG-115'],
             4: [i for i, _, fin in S.FINISHED if fin < '2026-03-16']}
    for i, (name, lim, n) in enumerate(S.BOARD):
        w = widths[i]
        full = lim is not None and n >= lim
        f.rect(x, 50, w, 230, stroke='--amber' if full else '--wire', fill='--panel', rx=4,
               width=1.6 if full else 1.2)
        f.text(x + w / 2, 66, t['cols'][i], size=10.5, weight='600')
        f.text(x + w / 2, 82, ('WIP ' + str(lim)) if lim else '—', size=9.5, mono=True,
               fill='--amber' if full else '--paper-dim')
        if i == 1:
            f.line(x + w / 2, 92, x + w / 2, 272, stroke='--wire', width=1, dash='3 3')
            f.text(x + w / 4, 100, t['doing'], size=9, fill='--paper-dim')
            f.text(x + 3 * w / 4, 100, t['done'], size=9, fill='--paper-dim')
        for k, c in enumerate(cards[i]):
            if i == 4:
                cx, cy = x + 8 + (k % 2) * 70, 94 + (k // 2) * 34
                cw = 64
            elif i == 1:
                cx, cy = x + 6 + (0 if k < 2 else w / 2), 110 + (k % 2 if k < 2 else 0) * 34
                cw = w / 2 - 12
            else:
                cx, cy, cw = x + 10, 94 + k * 34, w - 20
            f.rect(cx, cy, cw, 26, stroke='--phosphor', fill='--scan', rx=3)
            f.text(cx + cw / 2, cy + 13, c, size=9.5, mono=True)
        x += w + 8
    xs = 14 + widths[0] + 4
    f.line(xs, 40, xs, 290, stroke='--phosphor', width=1.6, dash='5 3')
    f.text(xs, 30, t['commit'], size=9.5, anchor='start', fill='--phosphor', weight='600')
    xd = 14 + sum(widths[:4]) + 4 * 8 - 4
    f.line(xd, 40, xd, 290, stroke='--phosphor', width=1.6, dash='5 3')
    f.text(xd, 300, t['deliver'], size=9.5, anchor='middle', fill='--phosphor', weight='600')
    f.text(14, 318, t['pull'], size=9.5, anchor='start', fill='--paper-dim')
    return f, t['cap']


@figure('l03-cycle-times', 3)
def l03_cycle_times(lang):
    ct = S.cycle_times()
    p50, p85 = S.median(ct), S.percentile_inc(ct, 0.85)
    t = {
        'en': dict(y='cycle time, days', x='date finished, March 2026',
                   p50=f'50% finish within {p50:g} days', p85=f'85% within {num(lang, p85, 1)} days',
                   label='A scatter of the twenty items the Agenda team finished in March 2026, each a dot at the '
                         'date it finished and its cycle time in days, from 2 to 19. A line at 7 days marks the '
                         'median and a line at 11.6 days marks the 85th percentile; three items sit above it, at '
                         '15, 18 and 19 days.',
                   cap='Twenty items, one dot each. The 85th-percentile line is the honest answer to "how long does '
                       'an item take?": 17 of the 20 finished within it, and the three above it are the ones worth '
                       'asking about.'),
        'pt': dict(y='tempo de ciclo, dias', x='data em que terminou, março de 2026',
                   p50=f'50% terminam em até {p50:g} dias', p85=f'85% em até {num(lang, p85, 1)} dias',
                   label='Um gráfico de dispersão dos vinte itens que o time Agenda terminou em março de 2026, cada '
                         'um um ponto na data em que terminou e no tempo de ciclo em dias, de 2 a 19. Uma linha em 7 '
                         'dias marca a mediana e uma linha em 11,6 dias marca o percentil 85; três itens ficam '
                         'acima dela, em 15, 18 e 19 dias.',
                   cap='Vinte itens, um ponto cada. A linha do percentil 85 é a resposta honesta a "quanto tempo um '
                       'item leva?": 17 dos 20 terminaram dentro dela, e os três acima são os que merecem pergunta.'),
    }[lang]
    f = Fig('l03-cycle-times', 640, 300, t['label'])
    p = Plot(f, 60, 40, 600, 240, 1, 28, 0, 20)
    p.yaxis([0, 5, 10, 15, 20], label=t['y'])
    p.xaxis([2, 9, 16, 23], fmt=lambda d: f'{d} mar' if lang == 'pt' else f'Mar {d}', label=t['x'])
    for (_, s, fin), c in zip(S.FINISHED, ct):
        d = S.day(fin).day
        f.circle(p.sx(d), p.sy(c), 4, fill='--phosphor' if c <= p85 else '--amber')
    f.line(p.x0, p.sy(p50), p.x1, p.sy(p50), stroke='--paper-dim', width=1.2, dash='4 3')
    f.text(p.x0 + 8, p.sy(p50) - 11, t['p50'], size=9.5, anchor='start', fill='--paper-dim')
    f.line(p.x0, p.sy(p85), p.x1, p.sy(p85), stroke='--amber', width=1.4, dash='5 3')
    f.text(p.x1, p.sy(p85) - 10, t['p85'], size=10, anchor='end', fill='--amber', weight='600')
    return f, t['cap']

# ---- end of lesson 3


# ------------------------------------------------------------------ lesson 4

@figure('l04-loops', 4)
def l04_loops(lang):
    t = {
        'en': dict(rows=[('seconds', 'pair programming', 'the partner reads every line as it is typed'),
                         ('minutes', 'test-first', 'a failing test, then the code that passes it'),
                         ('hours', 'continuous integration', 'everybody’s work merged and built'),
                         ('one day', 'stand-up', 'the team sees where everyone is'),
                         ('a week or two', 'iteration', 'the customer sees working software'),
                         ('a few months', 'release', 'the users have it')],
                   title='how long until somebody tells you that you are wrong',
                   label='Six feedback loops of Extreme Programming, from the fastest to the slowest: pair '
                         'programming in seconds, test-first programming in minutes, continuous integration in '
                         'hours, the stand-up in a day, the iteration in a week or two and the release in a few '
                         'months.',
                   cap='XP is a stack of feedback loops, each catching a different kind of mistake at the earliest '
                       'moment it can be caught. The outer loops are what every agile method has; the inner three '
                       'are what XP added.'),
        'pt': dict(rows=[('segundos', 'programação em par', 'o parceiro lê cada linha enquanto é digitada'),
                         ('minutos', 'teste primeiro', 'um teste que falha, depois o código que o faz passar'),
                         ('horas', 'integração contínua', 'o trabalho de todos integrado e compilado'),
                         ('um dia', 'reunião diária', 'o time vê onde cada um está'),
                         ('uma ou duas semanas', 'iteração', 'o cliente vê software funcionando'),
                         ('alguns meses', 'release', 'os usuários o têm')],
                   title='quanto tempo até alguém dizer que você está errado',
                   label='Seis ciclos de feedback do Extreme Programming, do mais rápido ao mais lento: '
                         'programação em par em segundos, teste primeiro em minutos, integração contínua em horas, '
                         'a reunião diária em um dia, a iteração em uma ou duas semanas e o release em alguns meses.',
                   cap='O XP é uma pilha de ciclos de feedback, cada um pegando um tipo diferente de erro no momento '
                       'mais cedo em que ele pode ser pego. Os ciclos de fora são o que todo método ágil tem; os três '
                       'de dentro são o que o XP acrescentou.'),
    }[lang]
    f = Fig('l04-loops', 660, 300, t['label'])
    f.text(20, 20, t['title'], size=10.5, anchor='start', weight='600')
    for i, (when, what, note) in enumerate(t['rows']):
        y = 40 + i * 42
        inner = i < 3
        f.rect(20, y, 620, 34, stroke='--phosphor' if inner else '--wire', fill='--scan' if inner else '--panel', rx=4)
        f.text(32, y + 17, when, size=10, anchor='start', fill='--paper-dim')
        f.text(190, y + 11, what, size=10.5, anchor='start', weight='600')
        f.text(190, y + 25, note, size=9.5, anchor='start', fill='--paper-dim')
    return f, t['cap']


@figure('l04-tdd', 4)
def l04_tdd(lang):
    t = {
        'en': dict(red='red', redn='write a test that fails', green='green', greenn='write just enough code to pass',
                   ref='refactor', refn='improve the code, tests still passing',
                   label='Three steps in a loop: red, write a test that fails; green, write just enough code to '
                         'pass it; refactor, improve the code while the tests still pass; then back to red.',
                   cap='The test-first loop. Each turn takes minutes, and the code is never more than one small '
                       'step away from a state where every test passes.'),
        'pt': dict(red='vermelho', redn='escreva um teste que falha', green='verde',
                   greenn='escreva só o código para passar', ref='refatorar',
                   refn='melhore o código, com os testes passando',
                   label='Três passos em ciclo: vermelho, escreva um teste que falha; verde, escreva só o código '
                         'necessário para passar; refatorar, melhore o código com os testes ainda passando; e de '
                         'volta ao vermelho.',
                   cap='O ciclo do teste primeiro. Cada volta leva minutos, e o código nunca está a mais de um passo '
                       'pequeno de um estado em que todos os testes passam.'),
    }[lang]
    f = Fig('l04-tdd', 620, 230, t['label'])
    pts = [(110, 110), (310, 110), (510, 110)]
    names = [(t['red'], t['redn'], '--amber'), (t['green'], t['greenn'], '--phosphor'), (t['ref'], t['refn'], '--paper')]
    for (x, y), (n, note, c) in zip(pts, names):
        f.circle(x, y - 20, 34, fill='--panel', stroke=c, width=2.2)
        f.text(x, y - 20, n, size=11.5, weight='600', fill=c)
        f.text(x, y + 34, note, size=9.5, fill='--paper-dim')
    arrow(f, 148, 90, 272, 90)
    arrow(f, 348, 90, 472, 90)
    f.path('M510 158 C510 212 110 212 110 160', stroke='--paper-dim', width=1.4, arrow=True)
    return f, t['cap']

# ---- end of lesson 4


# ------------------------------------------------------------------ lesson 5

def _ring(f, cx, cy, r, n, stroke):
    pts = [(cx + r * math.cos(2 * math.pi * k / n - math.pi / 2), cy + r * math.sin(2 * math.pi * k / n - math.pi / 2))
           for k in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            f.line(pts[i][0], pts[i][1], pts[j][0], pts[j][1], stroke=stroke, width=0.9)
    for x, y in pts:
        f.circle(x, y, 6, fill='--panel', stroke='--paper', width=1.4)


@figure('l05-paths', 5)
def l05_paths(lang):
    t = {
        'en': dict(a='6 people', b='12 people', pa='15 paths', pb='66 paths',
                   label='Two groups drawn as dots with a line between every pair. Six people have 15 lines '
                         'between them; twelve people have 66.',
                   cap='Doubling a team from six to twelve more than quadruples the pairs of people who may need to '
                       'talk. The formula is n(n−1)/2, and at the 125 people of a large release train it gives '
                       '7,750.'),
        'pt': dict(a='6 pessoas', b='12 pessoas', pa='15 caminhos', pb='66 caminhos',
                   label='Dois grupos desenhados como pontos com uma linha entre cada par. Seis pessoas têm 15 '
                         'linhas entre si; doze pessoas têm 66.',
                   cap='Dobrar um time de seis para doze mais que quadruplica os pares de pessoas que podem precisar '
                       'conversar. A fórmula é n(n−1)/2, e nas 125 pessoas de um release train grande ela dá '
                       '7.750.'),
    }[lang]
    f = Fig('l05-paths', 600, 260, t['label'])
    _ring(f, 150, 120, 80, 6, '--phosphor')
    _ring(f, 440, 120, 90, 12, '--amber')
    f.text(150, 230, t['a'], size=11, weight='600')
    f.text(150, 248, t['pa'], size=10, fill='--paper-dim')
    f.text(440, 230, t['b'], size=11, weight='600')
    f.text(440, 248, t['pb'], size=10, fill='--paper-dim')
    return f, t['cap']


@figure('l05-pi', 5)
def l05_pi(lang):
    t = {
        'en': dict(plan='PI Planning', planw='two days, everybody', it='iteration', ip='IP iteration',
                   ipw='innovation and planning', demo='system demo', ia='Inspect and Adapt',
                   span='one Planning Interval: 8 to 12 weeks, commonly 10',
                   label='A Planning Interval drawn as a timeline. It opens with PI Planning, two days with the '
                         'whole release train. Four development iterations of two weeks follow, each ending in a '
                         'system demo. The fifth is the innovation and planning iteration, which holds the '
                         'Inspect and Adapt event and the next PI Planning.',
                   cap='One Planning Interval of SAFe, in its most common shape: ten weeks, five iterations, the last '
                       'reserved for innovation, planning and the slack a plan needs.'),
        'pt': dict(plan='PI Planning', planw='dois dias, todo mundo', it='iteração', ip='iteração IP',
                   ipw='inovação e planejamento', demo='demo do sistema', ia='Inspect and Adapt',
                   span='um Planning Interval: de 8 a 12 semanas, muitas vezes 10',
                   label='Um Planning Interval desenhado como linha do tempo. Ele abre com o PI Planning, dois dias '
                         'com o release train inteiro. Seguem quatro iterações de desenvolvimento de duas semanas, '
                         'cada uma terminando numa demo do sistema. A quinta é a iteração de inovação e '
                         'planejamento, que abriga o evento Inspect and Adapt e o próximo PI Planning.',
                   cap='Um Planning Interval do SAFe, no formato mais comum: dez semanas, cinco iterações, a última '
                       'reservada para inovação, planejamento e a folga de que um plano precisa.'),
    }[lang]
    f = Fig('l05-pi', 680, 210, t['label'])
    box(f, 14, 60, 110, 54, [t['plan'], t['planw']], stroke='--phosphor', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10)
    x = 134
    for k in range(4):
        box(f, x, 60, 96, 54, [f"{t['it']} {k + 1}"], size=10, weights=['600'])
        f.text(x + 48, 130, t['demo'], size=9, fill='--paper-dim')
        x += 102
    box(f, x, 60, 128, 54, [t['ip'], t['ipw']], stroke='--amber', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10)
    f.text(x + 64, 130, t['ia'], size=9, fill='--amber')
    f.line(14, 40, x + 128, 40, stroke='--paper-dim', width=1.2)
    f.line(14, 34, 14, 46, stroke='--paper-dim', width=1.2)
    f.line(x + 128, 34, x + 128, 46, stroke='--paper-dim', width=1.2)
    f.text((14 + x + 128) / 2, 26, t['span'], size=10, fill='--paper-dim')
    f.path(f'M{x + 100:.0f} 116 C{x + 100:.0f} 190 70 190 70 118', stroke='--paper-dim', width=1.2,
           dash='4 3', arrow=True)
    return f, t['cap']


@figure('l05-feature-teams', 5)
def l05_feature_teams(lang):
    t = {
        'en': dict(comp='component teams', feat='feature teams',
                   layers=['screens', 'API', 'database'],
                   cteam=['screens team', 'API team', 'database team'],
                   fteam=['team 1', 'team 2', 'team 3'],
                   feature='one feature', note1='one feature crosses three teams: three backlogs, three queues',
                   note2='one feature, one team, every layer',
                   label='Two arrangements side by side. On the left, three component teams each own one layer: '
                         'screens, API and database; a single feature, drawn as a vertical arrow, crosses all three '
                         'teams. On the right, three feature teams each own a vertical slice through all three '
                         'layers, and the same feature sits inside one team.',
                   cap='A feature is a vertical slice; a component team owns a horizontal one. Every feature then '
                       'needs several teams to finish it, and the coordination becomes the work.'),
        'pt': dict(comp='times de componente', feat='times de funcionalidade',
                   layers=['telas', 'API', 'banco de dados'],
                   cteam=['time de telas', 'time de API', 'time de banco'],
                   fteam=['time 1', 'time 2', 'time 3'],
                   feature='uma funcionalidade', note1='uma funcionalidade cruza três times: três backlogs, três filas',
                   note2='uma funcionalidade, um time, todas as camadas',
                   label='Dois arranjos lado a lado. À esquerda, três times de componente, cada um dono de uma '
                         'camada: telas, API e banco de dados; uma única funcionalidade, desenhada como uma seta '
                         'vertical, cruza os três times. À direita, três times de funcionalidade, cada um dono de '
                         'uma fatia vertical pelas três camadas, e a mesma funcionalidade fica dentro de um time.',
                   cap='Uma funcionalidade é uma fatia vertical; um time de componente é dono de uma horizontal. Aí '
                       'toda funcionalidade precisa de vários times para terminar, e a coordenação vira o trabalho.'),
    }[lang]
    f = Fig('l05-feature-teams', 680, 280, t['label'])
    f.text(145, 22, t['comp'], size=11, weight='600')
    for i, name in enumerate(t['cteam']):
        y = 40 + i * 58
        box(f, 20, y, 250, 46, [name], size=10)
        f.rect(222, y + 14, 30, 18, stroke='--amber', fill='--scan', rx=3, width=1.6)
        if i < 2:
            arrow(f, 237, y + 33, 237, y + 70, stroke='--amber', width=1.6)
    f.text(237, 220, t['feature'], size=9.5, anchor='middle', fill='--amber')
    f.text(145, 260, t['note1'], size=9.5, fill='--paper-dim')
    f.text(493, 22, t['feat'], size=11, weight='600')
    for j, name in enumerate(t['fteam']):
        x = 320 + j * 118
        f.rect(x, 40, 110, 162, stroke='--phosphor' if j == 1 else '--wire', fill='--panel', rx=4,
               width=1.8 if j == 1 else 1.2)
        f.text(x + 44, 56, name, size=10, weight='600')
        for i, lay in enumerate(t['layers']):
            f.rect(x + 6, 70 + i * 42, 76, 34, stroke='--wire', fill='--scan', rx=3)
            f.text(x + 44, 87 + i * 42, lay, size=9)
    arrow(f, 534, 62, 534, 200, stroke='--amber', width=2)
    f.text(534, 232, t['feature'], size=9.5, anchor='middle', fill='--amber')
    f.text(493, 260, t['note2'], size=9.5, fill='--paper-dim')
    return f, t['cap']

# ---- end of lesson 5


# ------------------------------------------------------------------ the figures


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

