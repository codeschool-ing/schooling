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


# ------------------------------------------------------------------ lesson 6

@figure('l06-process-groups', 6)
def l06_process_groups(lang):
    t = {
        'en': dict(g=['Initiating', 'Planning', 'Executing', 'Closing'], mc='Monitoring and Controlling',
                   mcn='runs alongside everything, from the first day to the last',
                   loop='planning is revisited as execution teaches something',
                   label='Four process groups in a row: initiating, planning, executing and closing, with an '
                         'arrow from executing back to planning. A fifth group, monitoring and controlling, is a '
                         'wide band underneath all four, because it runs throughout.',
                   cap='The five process groups of the sixth edition. They are not phases: a project with three '
                       'phases goes through all five groups in each, and monitoring runs underneath the rest.'),
        'pt': dict(g=['Iniciação', 'Planejamento', 'Execução', 'Encerramento'], mc='Monitoramento e Controle',
                   mcn='corre junto de tudo, do primeiro ao último dia',
                   loop='o planejamento é revisto quando a execução ensina algo',
                   label='Quatro grupos de processos em linha: iniciação, planejamento, execução e encerramento, '
                         'com uma seta da execução de volta ao planejamento. Um quinto grupo, monitoramento e '
                         'controle, é uma faixa larga embaixo dos quatro, porque corre o tempo todo.',
                   cap='Os cinco grupos de processos da sexta edição. Eles não são fases: um projeto com três fases '
                       'passa pelos cinco grupos em cada uma, e o monitoramento corre por baixo de todo o resto.'),
    }[lang]
    f = Fig('l06-process-groups', 660, 230, t['label'])
    xs = [20, 180, 340, 500]
    for i, (x, g) in enumerate(zip(xs, t['g'])):
        box(f, x, 50, 140, 46, [g], stroke='--phosphor' if i in (1, 2) else '--wire', weights=['600'])
        if i < 3:
            arrow(f, x + 142, 73, x + 158, 73)
    f.path('M410 50 C410 22 250 22 250 48', stroke='--amber', width=1.4, dash='4 3', arrow=True)
    f.text(330, 14, t['loop'], size=9.5, fill='--amber')
    box(f, 20, 130, 620, 56, [t['mc'], t['mcn']], stroke='--paper-dim', fill='--scan',
        fills=['--paper', '--paper-dim'], weights=['600', None])
    for x in xs:
        f.line(x + 70, 98, x + 70, 128, stroke='--wire', width=1.2, dash='2 3')
    return f, t['cap']


@figure('l06-wbs', 6)
def l06_wbs(lang):
    t = {
        'en': dict(root='Online booking', l1=['1 Booking rules', '2 Slots API', '3 Booking screens', '4 Pilot'],
                   l2=[['1.1 Interview clinics', '1.2 Write the rules'], ['2.1 Data model', '2.2 Endpoints'],
                       ['3.1 Design', '3.2 Build'], ['4.1 Train staff', '4.2 Run one clinic']],
                   wp='work packages: small enough to estimate and assign',
                   label='A work breakdown structure. The root, online booking, splits into four deliverables: '
                         'booking rules, slots API, booking screens and pilot. Each splits into two work packages, '
                         'such as interview clinics and write the rules under booking rules.',
                   cap='A work breakdown structure for the Agenda team’s online booking. Each level adds up to '
                       'exactly the level above it — the 100% rule — so nothing outside the tree is in the '
                       'project, and nothing in the project is outside the tree.'),
        'pt': dict(root='Agendamento online', l1=['1 Regras', '2 API de horários', '3 Telas', '4 Piloto'],
                   l2=[['1.1 Ouvir clínicas', '1.2 Escrever regras'], ['2.1 Modelo de dados', '2.2 Endpoints'],
                       ['3.1 Desenho', '3.2 Construção'], ['4.1 Treinar equipe', '4.2 Rodar uma clínica']],
                   wp='pacotes de trabalho: pequenos o bastante para estimar e atribuir',
                   label='Uma estrutura analítica do projeto. A raiz, agendamento online, se divide em quatro '
                         'entregas: regras, API de horários, telas e piloto. Cada uma se divide em dois pacotes de '
                         'trabalho, como ouvir clínicas e escrever regras sob regras.',
                   cap='Uma estrutura analítica do projeto (EAP) para o agendamento online do time Agenda. Cada '
                       'nível soma exatamente o nível de cima — a regra dos 100% —, então nada fora da árvore está '
                       'no projeto, e nada do projeto está fora da árvore.'),
    }[lang]
    f = Fig('l06-wbs', 680, 270, t['label'])
    box(f, 260, 14, 160, 36, [t['root']], stroke='--phosphor', weights=['600'])
    for i, name in enumerate(t['l1']):
        x = 14 + i * 166
        f.path(f'M340 50 L340 66 L{x + 76} 66 L{x + 76} 80', stroke='--paper-dim', width=1.2)
        box(f, x, 80, 152, 34, [name], size=10, weights=['600'])
        for k, wp in enumerate(t['l2'][i]):
            y = 136 + k * 44
            f.path(f'M{x + 12} 114 L{x + 12} {y + 17} L{x + 22} {y + 17}', stroke='--paper-dim', width=1.1)
            box(f, x + 22, y, 130, 34, [wp], size=9.5, fill='--scan')
    f.text(340, 252, t['wp'], size=9.5, fill='--paper-dim')
    return f, t['cap']


@figure('l06-network', 6)
def l06_network(lang):
    es, ef, ls, lf, slack, end = S.cpm()
    t = {
        'en': dict(names={'A': 'agree rules', 'B': 'slots API', 'C': 'design screens', 'D': 'build screens',
                          'E': 'integrate', 'F': 'pilot'},
                   d='days', crit='critical path: 14 days', fl='slack 1',
                   label='An activity network. A, agree the rules, 3 days, leads to B, the slots API, 5 days, and '
                         'to C, design the screens, 2 days. C leads to D, build the screens, 4 days. B and D both '
                         'lead to E, integrate, 3 days, which leads to F, the pilot, 2 days. The path A, C, D, E, F '
                         'is critical at 14 days; B has 1 day of slack.',
                   cap='Each box shows the earliest start and finish above the duration, and the latest start and '
                       'finish below it. Where earliest and latest are equal the slack is zero, and those boxes form '
                       'the critical path.'),
        'pt': dict(names={'A': 'combinar regras', 'B': 'API de horários', 'C': 'desenhar telas',
                          'D': 'construir telas', 'E': 'integrar', 'F': 'piloto'},
                   d='dias', crit='caminho crítico: 14 dias', fl='folga 1',
                   label='Uma rede de atividades. A, combinar as regras, 3 dias, leva a B, a API de horários, 5 dias, '
                         'e a C, desenhar as telas, 2 dias. C leva a D, construir as telas, 4 dias. B e D levam a E, '
                         'integrar, 3 dias, que leva a F, o piloto, 2 dias. O caminho A, C, D, E, F é crítico, com 14 '
                         'dias; B tem 1 dia de folga.',
                   cap='Cada caixa mostra o início e o fim mais cedo acima da duração, e o início e o fim mais tarde '
                       'abaixo dela. Onde mais cedo e mais tarde coincidem, a folga é zero, e essas caixas formam o '
                       'caminho crítico.'),
    }[lang]
    f = Fig('l06-network', 680, 270, t['label'])
    pos = {'A': (14, 104), 'B': (200, 30), 'C': (148, 170), 'D': (290, 170), 'E': (420, 104), 'F': (556, 104)}
    w, h = 110, 70
    edges = [('A', 'B'), ('A', 'C'), ('C', 'D'), ('B', 'E'), ('D', 'E'), ('E', 'F')]
    for a, b in edges:
        (x1, y1), (x2, y2) = pos[a], pos[b]
        crit = slack[a] == 0 and slack[b] == 0
        sx_, sy_ = x1 + w, y1 + h / 2
        ex, ey = x2, y2 + h / 2
        if a == 'A' and b == 'C':
            sx_, sy_, ex, ey = x1 + w / 2 + 20, y1 + h, x2 + 10, y2 + h / 2
        f.line(sx_, sy_, ex - 2, ey, stroke='--amber' if crit else '--paper-dim', width=2 if crit else 1.2,
               arrow=True)
    for k, (x, y) in pos.items():
        crit = slack[k] == 0
        f.rect(x, y, w, h, stroke='--amber' if crit else '--wire', fill='--panel', rx=4, width=1.8 if crit else 1.2)
        f.text(x + 8, y + 12, str(es[k]), size=9.5, anchor='start', mono=True, fill='--paper-dim')
        f.text(x + w - 8, y + 12, str(ef[k]), size=9.5, anchor='end', mono=True, fill='--paper-dim')
        f.text(x + w / 2, y + 28, f'{k} · {t["names"][k]}', size=9.5, weight='600')
        f.text(x + w / 2, y + 44, f'{S.ACTIVITIES[k][0]} {t["d"]}', size=9.5, fill='--paper-dim')
        f.text(x + 8, y + 60, str(ls[k]), size=9.5, anchor='start', mono=True, fill='--paper-dim')
        f.text(x + w - 8, y + 60, str(lf[k]), size=9.5, anchor='end', mono=True, fill='--paper-dim')
    f.text(255, 116, t['fl'], size=9.5, fill='--phosphor', weight='600')
    f.text(670, 258, t['crit'], size=10, anchor='end', fill='--amber', weight='600')
    return f, t['cap']


@figure('l06-evm', 6)
def l06_evm(lang):
    e = S.EVM
    t = {
        'en': dict(y='thousands of R$', x='week', pv='planned value (PV)', ev='earned value (EV)',
                   ac='actual cost (AC)', bac='budget at completion: 200', now='today, week 6',
                   label='Three lines over ten weeks against a budget of 200 thousand. Planned value rises to 120 '
                         'thousand at week 6 and 200 at week 10. At week 6, earned value has reached only 100 '
                         'thousand and actual cost has reached 125 thousand.',
                   cap='At week 6 the project has spent 125 thousand to earn 100 thousand of work it had planned to '
                       'have finished at 120 thousand. Over budget and behind schedule, and the two gaps are read '
                       'separately.'),
        'pt': dict(y='milhares de R$', x='semana', pv='valor planejado (VP)', ev='valor agregado (VA)',
                   ac='custo real (CR)', bac='orçamento no término: 200', now='hoje, semana 6',
                   label='Três linhas ao longo de dez semanas contra um orçamento de 200 mil. O valor planejado sobe '
                         'a 120 mil na semana 6 e a 200 na semana 10. Na semana 6, o valor agregado chegou só a 100 '
                         'mil e o custo real a 125 mil.',
                   cap='Na semana 6 o projeto gastou 125 mil para agregar 100 mil de um trabalho que planejava ter '
                       'terminado a 120 mil. Acima do orçamento e atrasado, e as duas lacunas são lidas '
                       'separadamente.'),
    }[lang]
    f = Fig('l06-evm', 640, 300, t['label'])
    p = Plot(f, 70, 40, 520, 240, 0, 10, 0, 220)
    p.yaxis([0, 50, 100, 150, 200], label=t['y'])
    p.xaxis(range(0, 11, 2), label=t['x'])
    f.line(p.x0, p.sy(200), p.x1, p.sy(200), stroke='--paper-dim', width=1.2, dash='5 4')
    f.text(p.x0 + 6, p.sy(200) - 10, t['bac'], size=9.5, anchor='start', fill='--paper-dim')
    f.line(p.sx(0), p.sy(0), p.sx(6), p.sy(e['PV'] / 1000), stroke='--paper', width=1.8)
    f.line(p.sx(0), p.sy(0), p.sx(6), p.sy(e['EV'] / 1000), stroke='--phosphor', width=2.2)
    f.line(p.sx(0), p.sy(0), p.sx(6), p.sy(e['AC'] / 1000), stroke='--amber', width=2.2)
    f.line(p.sx(6), p.y0, p.sx(6), p.y1, stroke='--wire', width=1.2, dash='3 3')
    f.text(p.sx(6), p.y0 - 8, t['now'], size=9.5, fill='--paper-dim')
    for v, key, c in ((e['AC'], 'ac', '--amber'), (e['PV'], 'pv', '--paper'), (e['EV'], 'ev', '--phosphor')):
        f.circle(p.sx(6), p.sy(v / 1000), 3.5, fill=c)
    f.text(p.sx(6) + 10, p.sy(125) - 6, t['ac'] + ' 125', size=9.5, anchor='start', fill='--amber', weight='600')
    f.text(p.sx(6) + 10, p.sy(120) + 8, t['pv'] + ' 120', size=9.5, anchor='start', fill='--paper', weight='600')
    f.text(p.sx(6) + 10, p.sy(100) + 6, t['ev'] + ' 100', size=9.5, anchor='start', fill='--phosphor', weight='600')
    return f, t['cap']

# ---- end of lesson 6


# ------------------------------------------------------------------ lesson 7

@figure('l07-levels', 7)
def l07_levels(lang):
    t = {
        'en': dict(levels=[('Corporate or programme', 'sets the project’s tolerances'),
                           ('Directing: the Project Board', 'Executive, Senior User, Senior Supplier'),
                           ('Managing: the Project Manager', 'runs each stage day to day'),
                           ('Delivering: Team Managers', 'produce the products')],
                   down='tolerances handed down', up='exception: escalated up',
                   label='Four levels of management stacked from top to bottom: corporate or programme management, '
                         'the Project Board, the Project Manager and the Team Managers. Arrows on the left run down '
                         'from each level to the next, labelled tolerances handed down. Arrows on the right run up, '
                         'labelled exception escalated up.',
                   cap='PRINCE2’s levels of management. Each level gives the one below it room to work, in '
                       'tolerances, and hears from it only when a forecast says the room will be exceeded.'),
        'pt': dict(levels=[('Corporativo ou programa', 'define as tolerâncias do projeto'),
                           ('Direção: o Comitê do Projeto', 'Executivo, Usuário Sênior, Fornecedor Sênior'),
                           ('Gerenciamento: o Gerente de Projeto', 'conduz cada estágio no dia a dia'),
                           ('Entrega: Gerentes de Equipe', 'produzem os produtos')],
                   down='tolerâncias passadas para baixo', up='exceção: escalada para cima',
                   label='Quatro níveis de gerenciamento empilhados de cima para baixo: gerenciamento corporativo ou '
                         'de programa, o Comitê do Projeto, o Gerente de Projeto e os Gerentes de Equipe. Setas à '
                         'esquerda descem de cada nível para o seguinte, com o rótulo tolerâncias passadas para '
                         'baixo. Setas à direita sobem, com o rótulo exceção escalada para cima.',
                   cap='Os níveis de gerenciamento do PRINCE2. Cada nível dá ao de baixo espaço para trabalhar, em '
                       'tolerâncias, e só ouve falar dele quando uma previsão diz que o espaço vai ser ultrapassado.'),
    }[lang]
    f = Fig('l07-levels', 660, 290, t['label'])
    for i, (name, note) in enumerate(t['levels']):
        y = 20 + i * 66
        box(f, 150, y, 360, 48, [name, note], stroke='--phosphor' if i == 1 else '--wire',
            fills=['--paper', '--paper-dim'], weights=['600', None], size=10)
        if i < 3:
            arrow(f, 200, y + 50, 200, y + 64, stroke='--phosphor', width=1.6)
            arrow(f, 460, y + 64, 460, y + 50, stroke='--amber', width=1.6)
    f.text(140, 150, t['down'], size=9.5, anchor='end', fill='--phosphor')
    f.text(520, 150, t['up'], size=9.5, anchor='start', fill='--amber')
    return f, t['cap']


@figure('l07-hump', 7)
def l07_hump(lang):
    t = {
        'en': dict(phases=['Inception', 'Elaboration', 'Construction', 'Transition'],
                   disc=['Business modelling', 'Requirements', 'Analysis and design', 'Implementation', 'Test',
                         'Deployment'],
                   iters='iterations inside every phase',
                   label='A chart with four phases across the top: inception, elaboration, construction and '
                         'transition. Six disciplines run down the side. Each discipline is a band whose height is '
                         'its effort over time: requirements peak in inception and elaboration, analysis and design '
                         'peak in elaboration, implementation in construction, deployment in transition, and test '
                         'is present throughout.',
                   cap='The RUP “hump chart”, redrawn. Every discipline happens in every phase in different '
                       'amounts, which is the difference between RUP’s phases and the waterfall’s: none of them '
                       'is a single activity.'),
        'pt': dict(phases=['Concepção', 'Elaboração', 'Construção', 'Transição'],
                   disc=['Modelagem de negócio', 'Requisitos', 'Análise e projeto', 'Implementação', 'Teste',
                         'Implantação'],
                   iters='iterações dentro de toda fase',
                   label='Um gráfico com quatro fases no topo: concepção, elaboração, construção e transição. Seis '
                         'disciplinas descem pela lateral. Cada disciplina é uma faixa cuja altura é o esforço ao '
                         'longo do tempo: requisitos têm pico na concepção e na elaboração, análise e projeto na '
                         'elaboração, implementação na construção, implantação na transição, e teste está presente '
                         'o tempo todo.',
                   cap='O "gráfico de corcovas" do RUP, redesenhado. Toda disciplina acontece em toda fase em '
                       'quantidades diferentes, que é a diferença entre as fases do RUP e as da cascata: nenhuma '
                       'delas é uma atividade só.'),
    }[lang]
    f = Fig('l07-hump', 680, 320, t['label'])
    x0, x1 = 170, 660
    bounds = [x0, x0 + 70, x0 + 200, x0 + 400, x1]
    for k, ph in enumerate(t['phases']):
        f.text((bounds[k] + bounds[k + 1]) / 2, 20, ph, size=10, weight='600')
        f.line(bounds[k + 1], 30, bounds[k + 1], 290, stroke='--wire', width=1, dash='3 3')
    # effort profile per discipline as a list of (x fraction, height 0..1)
    prof = [
        [(0, .8), (.12, .9), (.3, .4), (.6, .15), (1, .05)],
        [(0, .6), (.12, 1), (.3, .7), (.6, .25), (1, .1)],
        [(0, .15), (.15, .6), (.3, 1), (.6, .4), (1, .1)],
        [(0, .02), (.2, .3), (.45, .7), (.65, 1), (.82, .4), (1, .1)],
        [(0, .05), (.2, .3), (.4, .6), (.65, .9), (.85, .8), (1, .4)],
        [(0, 0), (.4, .02), (.7, .2), (.85, .9), (1, .7)],
    ]
    for i, (name, pr) in enumerate(zip(t['disc'], prof)):
        base = 64 + i * 42
        f.text(x0 - 10, base - 10, name, size=9.5, anchor='end')
        f.line(x0, base, x1, base, stroke='--wire', width=1)
        pts = []
        for k in range(61):
            u = k / 60
            for (a, ha), (b, hb) in zip(pr, pr[1:]):
                if a <= u <= b:
                    w = (u - a) / (b - a)
                    w = (1 - math.cos(math.pi * w)) / 2
                    h = ha + (hb - ha) * w
                    break
            pts.append((x0 + u * (x1 - x0), base - h * 30))
        d = f'M{x0:.1f} {base:.1f} L' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + f' L{x1:.1f} {base:.1f} Z'
        f.path(d, stroke='--phosphor', width=1, fill='--phosphor-dim', opacity=0.8)
    f.text(x1, 308, t['iters'], size=9.5, anchor='end', fill='--paper-dim')
    return f, t['cap']

# ---- end of lesson 7


# ------------------------------------------------------------------ lesson 8

@figure('l08-priority', 8)
def l08_priority(lang):
    t = {
        'en': dict(impact='rows, impact: how much of the service, for how many', urgency='columns, urgency: how soon it hurts',
                   lv=['high', 'medium', 'low'],
                   label='A three by three grid. Impact runs down the side, high, medium and low; urgency runs '
                         'across the top, high, medium and low. High impact and high urgency give priority 1; high '
                         'and medium, or medium and high, give 2; high and low, medium and medium, or low and high, '
                         'give 3; medium and low, or low and medium, give 4; low and low give 5.',
                   cap='A priority matrix of the kind ITIL describes. Priority is computed from two questions somebody '
                       'can answer, so it does not depend on who shouts loudest.'),
        'pt': dict(impact='linhas, impacto: quanto do serviço, para quantos', urgency='colunas, urgência: quão cedo dói',
                   lv=['alto', 'médio', 'baixo'],
                   label='Uma grade de três por três. O impacto desce pela lateral, alto, médio e baixo; a urgência '
                         'corre pelo topo, alta, média e baixa. Impacto alto e urgência alta dão prioridade 1; alto e '
                         'média, ou médio e alta, dão 2; alto e baixa, médio e média, ou baixo e alta, dão 3; médio e '
                         'baixa, ou baixo e média, dão 4; baixo e baixa dão 5.',
                   cap='Uma matriz de prioridade do tipo que o ITIL descreve. A prioridade é calculada a partir de duas '
                       'perguntas que alguém consegue responder, então não depende de quem grita mais alto.'),
    }[lang]
    ulv = t['lv'] if lang == 'en' else ['alta', 'média', 'baixa']
    f = Fig('l08-priority', 560, 310, t['label'])
    x0, y0, c = 200, 70, 90
    f.text(x0 + 1.5 * c, 22, t['urgency'], size=10, weight='600')
    for j, u in enumerate(ulv):
        f.text(x0 + j * c + c / 2, 50, u, size=10, fill='--paper-dim')
    f.text(x0 - 12, 298, t['impact'], size=10, anchor='start', weight='600')
    for i, im in enumerate(t['lv']):
        f.text(x0 - 12, y0 + i * c / 1.3 + c / 2.6, im, size=10, anchor='end', fill='--paper-dim')
        for j in range(3):
            pr = i + j + 1
            f.rect(x0 + j * c, y0 + i * c / 1.3, c - 6, c / 1.3 - 6, stroke='--wire', fill='--panel' if pr > 1 else '--scan',
                   rx=4, width=1.2)
            f.text(x0 + j * c + (c - 6) / 2, y0 + i * c / 1.3 + (c / 1.3 - 6) / 2, f'P{pr}', size=14, weight='600',
                   fill='--amber' if pr == 1 else '--phosphor' if pr == 2 else '--paper', mono=True)
    return f, t['cap']


@figure('l08-change', 8)
def l08_change(lang):
    t = {
        'en': dict(req='change proposed', std='standard', stdn='low risk, done often, pre-authorised',
                   norm='normal', normn='assessed and authorised by a change authority',
                   emer='emergency', emern='authorised fast, by a smaller authority',
                   do='implemented', rev='reviewed',
                   label='A change is proposed and takes one of three routes. A standard change, low risk and '
                         'pre-authorised, goes straight to implementation. A normal change is assessed and '
                         'authorised by a change authority first. An emergency change is authorised quickly by a '
                         'smaller authority. All three are implemented and then reviewed.',
                   cap='Three kinds of change, three routes to production. The work of change enablement is mostly '
                       'deciding which route a change deserves, and moving as many changes as possible onto the '
                       'first.'),
        'pt': dict(req='mudança proposta', std='padrão', stdn='baixo risco, frequente, pré-autorizada',
                   norm='normal', normn='avaliada e autorizada por uma autoridade de mudança',
                   emer='emergencial', emern='autorizada rápido, por uma autoridade menor',
                   do='implementada', rev='revista',
                   label='Uma mudança é proposta e segue um de três caminhos. Uma mudança padrão, de baixo risco e '
                         'pré-autorizada, vai direto para a implementação. Uma mudança normal é avaliada e autorizada '
                         'por uma autoridade de mudança antes. Uma mudança emergencial é autorizada rapidamente por '
                         'uma autoridade menor. As três são implementadas e depois revistas.',
                   cap='Três tipos de mudança, três caminhos até a produção. O trabalho da habilitação de mudanças é '
                       'sobretudo decidir que caminho uma mudança merece, e passar o máximo possível de mudanças para '
                       'o primeiro.'),
    }[lang]
    f = Fig('l08-change', 680, 250, t['label'])
    box(f, 14, 100, 120, 44, [t['req']], weights=['600'], size=10)
    rows = [(t['std'], t['stdn'], '--phosphor', 30), (t['norm'], t['normn'], '--paper', 100),
            (t['emer'], t['emern'], '--amber', 170)]
    for name, note, c, y in rows:
        f.path(f'M136 122 C160 122 160 {y + 22} 184 {y + 22}', stroke='--paper-dim', width=1.2, arrow=True)
        box(f, 186, y, 250, 44, [name, note], stroke=c, fills=['--paper', '--paper-dim'], weights=['600', None],
            size=9.5)
        f.path(f'M438 {y + 22} C462 {y + 22} 462 122 486 122', stroke='--paper-dim', width=1.2, arrow=True)
    box(f, 488, 100, 90, 44, [t['do']], size=10, weights=['600'])
    arrow(f, 580, 122, 594, 122)
    box(f, 596, 100, 76, 44, [t['rev']], size=10, weights=['600'])
    return f, t['cap']

# ---- end of lesson 8


# ------------------------------------------------------------------ lesson 9

def _beta_pdf(x, o, m, p):
    """A PERT-style beta: shape parameters from the mode, as PERT assumes."""
    a = 1 + 4 * (m - o) / (p - o)
    b = 1 + 4 * (p - m) / (p - o)
    u = (x - o) / (p - o)
    if u <= 0 or u >= 1:
        return 0.0
    return u ** (a - 1) * (1 - u) ** (b - 1)


@figure('l09-three-point', 9)
def l09_three_point(lang):
    o, m, p = S.TASKS['payment integration']
    mu, sd = S.pert(o, m, p)
    t = {
        'en': dict(x='working days', o='optimistic 3', m='most likely 6', p='pessimistic 20',
                   mean=f'PERT mean {num(lang, mu, 2)}',
                   label='A skewed curve over working days from 3 to 20 for the payment integration task. It peaks '
                         'at the most likely value, 6 days, and has a long tail to the right towards the '
                         'pessimistic 20. The PERT mean, 7.83 days, sits to the right of the peak.',
                   cap='One task, three figures. The most likely value is where the curve peaks, and the mean is to '
                       'its right, because a task can run much longer than expected and only a little shorter.'),
        'pt': dict(x='dias úteis', o='otimista 3', m='mais provável 6', p='pessimista 20',
                   mean=f'média PERT {num(lang, mu, 2)}',
                   label='Uma curva assimétrica sobre dias úteis de 3 a 20 para a tarefa de integração de pagamento. '
                         'Ela tem pico no valor mais provável, 6 dias, e uma cauda longa à direita em direção ao '
                         'pessimista 20. A média PERT, 7,83 dias, fica à direita do pico.',
                   cap='Uma tarefa, três números. O valor mais provável é onde a curva tem o pico, e a média fica à '
                       'direita dele, porque uma tarefa pode se alongar muito além do esperado e encurtar só um '
                       'pouco.'),
    }[lang]
    f = Fig('l09-three-point', 620, 260, t['label'])
    peak = _beta_pdf(m, o, m, p)
    pl = Plot(f, 40, 50, 590, 200, 0, 22, 0, peak * 1.15)
    pl.xaxis([0, 3, 6, 10, 15, 20], label=t['x'])
    pl.curve(lambda x: _beta_pdf(x, o, m, p), o, p, fill='--phosphor-dim')
    pl.curve(lambda x: _beta_pdf(x, o, m, p), o, p, stroke='--phosphor', width=2)
    for v, lab, anc in ((o, t['o'], 'end'), (p, t['p'], 'end')):
        f.line(pl.sx(v), pl.y1, pl.sx(v), pl.y1 - 30, stroke='--paper-dim', width=1.2, dash='3 3')
    f.text(pl.sx(o) - 4, pl.y1 - 38, t['o'], size=9.5, anchor='end', fill='--paper-dim')
    f.text(pl.sx(p), pl.y1 - 38, t['p'], size=9.5, anchor='middle', fill='--paper-dim')
    f.line(pl.sx(m), pl.y1, pl.sx(m), pl.sy(peak), stroke='--paper', width=1.2, dash='3 3')
    f.text(pl.sx(m), pl.sy(peak) - 10, t['m'], size=9.5, anchor='end', fill='--paper', weight='600')
    f.line(pl.sx(mu), pl.y1, pl.sx(mu), pl.y0 - 4, stroke='--amber', width=1.6, dash='5 3')
    f.text(pl.sx(mu) + 6, pl.y0 + 4, t['mean'], size=10, anchor='start', fill='--amber', weight='600')
    return f, t['cap']


@figure('l09-totals', 9)
def l09_totals(lang):
    tm = sum(S.pert(*v)[0] for v in S.TASKS.values())
    sd = math.sqrt(sum(S.pert(*v)[1] ** 2 for v in S.TASKS.values()))
    mm = sum(v[1] for v in S.TASKS.values())
    pp = sum(v[2] for v in S.TASKS.values())
    rows_en = [('sum of the most likely values', mm), ('sum of the PERT means', tm),
               ('about the 85th percentile', tm + 1.04 * sd), ('sum of the pessimistic values', pp)]
    rows_pt = [('soma dos mais prováveis', mm), ('soma das médias PERT', tm),
               ('perto do percentil 85', tm + 1.04 * sd), ('soma dos pessimistas', pp)]
    t = {
        'en': dict(rows=rows_en, x='working days for the four tasks together',
                   label='Four horizontal bars for the online booking feature. The sum of the most likely values is '
                         '17 days; the sum of the PERT means is 20.5; about the 85th percentile is 24.1; the sum of '
                         'the pessimistic values is 46.',
                   cap='Four ways to add up the same four tasks. The sum of the most likely values is the number '
                       'people quote, and it is the most optimistic of the four; the sum of the pessimistic values '
                       'is a world in which everything goes wrong at once.'),
        'pt': dict(rows=rows_pt, x='dias úteis das quatro tarefas juntas',
                   label='Quatro barras horizontais para a funcionalidade de agendamento online. A soma dos valores '
                         'mais prováveis é 17 dias; a soma das médias PERT é 20,5; perto do percentil 85 é 24,1; a '
                         'soma dos pessimistas é 46.',
                   cap='Quatro jeitos de somar as mesmas quatro tarefas. A soma dos mais prováveis é o número que as '
                       'pessoas citam, e é o mais otimista dos quatro; a soma dos pessimistas é um mundo em que tudo '
                       'dá errado ao mesmo tempo.'),
    }[lang]
    f = Fig('l09-totals', 640, 250, t['label'])
    pl = Plot(f, 220, 20, 600, 200, 0, 50, 0, 4)
    pl.xaxis([0, 10, 20, 30, 40, 50], label=t['x'])
    for i, (name, v) in enumerate(t['rows']):
        y = 32 + i * 42
        c = '--amber' if i == 2 else '--phosphor'
        f.rect(pl.sx(0), y, pl.sx(v) - pl.sx(0), 26, stroke=c, fill='--phosphor-dim' if i != 2 else '--scan', rx=2)
        f.text(pl.x0 - 10, y + 13, name, size=10, anchor='end')
        f.text(pl.sx(v) + 8, y + 13, num(lang, v, 1), size=10, anchor='start', weight='600', fill=c)
    return f, t['cap']

# ---- end of lesson 9


# ------------------------------------------------------------------ lesson 10

@figure('l10-velocity', 10)
def l10_velocity(lang):
    v = S.VELOCITY
    last6 = v[-6:]
    t = {
        'en': dict(y='points done', x='sprint', mean=f'mean {S.mean(v):g}', band='range of the last six: 19 to 31',
                   label='Eight bars, one per sprint: 21, 28, 24, 31, 19, 26, 27 and 24 points. A dashed line marks '
                         'the mean of 25. A shaded band covers 19 to 31, the range of the last six sprints.',
                   cap='The Agenda team’s last eight sprints. The mean is 25 points, and no single sprint is '
                       'unusual; a spread of twelve points between the slowest and the fastest of the last six is '
                       'what an ordinary team looks like.'),
        'pt': dict(y='pontos prontos', x='sprint', mean=f'média {S.mean(v):g}',
                   band='faixa das últimas seis: 19 a 31',
                   label='Oito barras, uma por sprint: 21, 28, 24, 31, 19, 26, 27 e 24 pontos. Uma linha tracejada '
                         'marca a média de 25. Uma faixa sombreada cobre de 19 a 31, a faixa das últimas seis sprints.',
                   cap='As últimas oito sprints do time Agenda. A média é 25 pontos, e nenhuma sprint isolada é fora '
                       'do comum; uma diferença de doze pontos entre a mais lenta e a mais rápida das últimas seis é '
                       'como um time comum se parece.'),
    }[lang]
    f = Fig('l10-velocity', 620, 280, t['label'])
    p = Plot(f, 60, 40, 590, 220, 0.4, 8.6, 0, 35)
    f.path(f'M{p.sx(2.5):.1f} {p.sy(31):.1f} L{p.x1:.1f} {p.sy(31):.1f} L{p.x1:.1f} {p.sy(19):.1f} '
           f'L{p.sx(2.5):.1f} {p.sy(19):.1f} Z', stroke=None, width=0, fill='--scan')
    p.yaxis([0, 10, 20, 30], label=t['y'])
    p.xaxis(range(1, 9), label=t['x'])
    for i, x in enumerate(v, start=1):
        f.path(f'M{p.sx(i) - 18:.1f} {p.sy(0):.1f} L{p.sx(i) - 18:.1f} {p.sy(x):.1f} L{p.sx(i) + 18:.1f} {p.sy(x):.1f} '
               f'L{p.sx(i) + 18:.1f} {p.sy(0):.1f} Z', stroke='--phosphor', width=1, fill='--phosphor-dim')
        f.text(p.sx(i), p.sy(x) - 9, str(x), size=9.5, weight='600')
    f.line(p.x0, p.sy(25), p.x1, p.sy(25), stroke='--amber', width=1.4, dash='5 3')
    f.text(p.x0 + 6, p.sy(25) - 8, t['mean'], size=9.5, anchor='start', fill='--amber', weight='600')
    f.text(p.x1, p.y0 - 14, t['band'], size=9.5, anchor='end', fill='--paper-dim')
    return f, t['cap']


@figure('l10-forecast', 10)
def l10_forecast(lang):
    t = {
        'en': dict(y='points done, from today', x='sprints from today', scope='backlog: 150 points',
                   fast='31 a sprint: sprint 5', mid='25 a sprint: sprint 6', slow='19 a sprint: sprint 8',
                   label='Three straight lines rise from zero towards a horizontal line at 150 points. The fastest, '
                         '31 points a sprint, crosses it in sprint 5; the middle, 25 a sprint, in sprint 6; the '
                         'slowest, 19 a sprint, in sprint 8.',
                   cap='The backlog of 150 points against three velocities taken from the team’s own history. '
                       'The honest forecast is the span the three lines cross the scope in: between sprint 5 and '
                       'sprint 8.'),
        'pt': dict(y='pontos prontos, a partir de hoje', x='sprints a partir de hoje', scope='backlog: 150 pontos',
                   fast='31 por sprint: sprint 5', mid='25 por sprint: sprint 6', slow='19 por sprint: sprint 8',
                   label='Três retas sobem de zero em direção a uma linha horizontal em 150 pontos. A mais rápida, 31 '
                         'pontos por sprint, cruza na sprint 5; a do meio, 25 por sprint, na sprint 6; a mais lenta, 19 '
                         'por sprint, na sprint 8.',
                   cap='O backlog de 150 pontos contra três velocidades tiradas da história do próprio time. A '
                       'previsão honesta é o intervalo em que as três retas cruzam o escopo: entre a sprint 5 e a '
                       'sprint 8.'),
    }[lang]
    f = Fig('l10-forecast', 620, 290, t['label'])
    p = Plot(f, 70, 40, 560, 230, 0, 9, 0, 180)
    p.yaxis([0, 50, 100, 150], label=t['y'])
    p.xaxis(range(0, 10), label=t['x'])
    f.path(f'M{p.sx(150 / 31):.1f} {p.sy(150):.1f} L{p.sx(150 / 19):.1f} {p.sy(150):.1f} '
           f'L{p.sx(150 / 19):.1f} {p.y1:.1f} L{p.sx(150 / 31):.1f} {p.y1:.1f} Z', stroke=None, width=0, fill='--scan')
    f.line(p.x0, p.sy(150), p.x1, p.sy(150), stroke='--paper', width=1.4)
    f.text(p.x0 + 6, p.sy(150) - 10, t['scope'], size=10, anchor='start', weight='600')
    for rate, key, c in ((31, 'fast', '--phosphor'), (25, 'mid', '--paper-dim'), (19, 'slow', '--amber')):
        end = min(9, 180 / rate)
        f.line(p.sx(0), p.sy(0), p.sx(end), p.sy(rate * end), stroke=c, width=1.8)
    f.text(p.sx(4.8), p.sy(170), t['fast'], size=9.5, anchor='end', fill='--phosphor', weight='600')
    f.text(p.sx(6.4), p.sy(110), t['mid'], size=9.5, anchor='start', fill='--paper-dim', weight='600')
    f.text(p.sx(8.1), p.sy(140), t['slow'], size=9.5, anchor='start', fill='--amber', weight='600')
    return f, t['cap']

# ---- end of lesson 10


# ------------------------------------------------------------------ lesson 11

RISK_SHORT = {
    'en': ['payment API changes', 'billing developer leaves', 'clinic data needs cleaning', 'app store rejection',
           'calendar library fits'],
    'pt': ['API de pagamento muda', 'dev do faturamento sai', 'dados das clínicas sujos', 'loja recusa o app',
           'biblioteca de calendário serve'],
}


@figure('l11-matrix', 11)
def l11_matrix(lang):
    t = {
        'en': dict(p='probability', i='impact', lv=['very low', 'low', 'medium', 'high', 'very high'],
                   zones=['act now', 'watch', 'accept'],
                   label='A five by five grid, probability up the side and impact along the bottom, each from very '
                         'low to very high. Cells with a high product of the two are marked act now, the middle '
                         'band watch, and the low corner accept. Four risks are plotted: payment API changes at low '
                         'probability and high impact; billing developer leaves at very low probability and very high '
                         'impact; clinic data needs cleaning at medium and medium; app store rejection at low and low.',
                   cap='The Agenda team’s four threats on a probability-impact matrix. The grid ranks them for '
                       'attention; it does not say how many days they could cost, which is the next section’s job.'),
        'pt': dict(p='probabilidade', i='impacto', lv=['muito baixo', 'baixo', 'médio', 'alto', 'muito alto'],
                   zones=['agir já', 'observar', 'aceitar'],
                   label='Uma grade de cinco por cinco, probabilidade subindo pela lateral e impacto ao longo da '
                         'base, cada um de muito baixo a muito alto. Células com produto alto dos dois estão marcadas '
                         'agir já, a faixa do meio observar, e o canto baixo aceitar. Quatro riscos estão marcados: '
                         'API de pagamento muda em probabilidade baixa e impacto alto; dev do faturamento sai em '
                         'probabilidade muito baixa e impacto muito alto; dados das clínicas sujos em médio e médio; '
                         'loja recusa o app em baixo e baixo.',
                   cap='As quatro ameaças do time Agenda numa matriz de probabilidade e impacto. A grade as ordena '
                       'para atenção; não diz quantos dias podem custar, que é tarefa da próxima seção.'),
    }[lang]
    f = Fig('l11-matrix', 660, 340, t['label'])
    x0, y0, c = 120, 20, 52
    for pi in range(5):          # probability level 5 at the top
        for ii in range(5):
            score = (5 - pi) * (ii + 1)
            fill = '--scan' if score >= 12 else '--panel'
            stroke = '--amber' if score >= 12 else '--phosphor' if score >= 5 else '--wire'
            f.rect(x0 + ii * c, y0 + pi * c, c - 4, c - 4, stroke=stroke, fill=fill, rx=3)
    for k, lv in enumerate(t['lv']):
        f.text(x0 - 8, y0 + (4 - k) * c + c / 2 - 2, lv, size=9, anchor='end', fill='--paper-dim')
        f.text(x0 + k * c + c / 2 - 2, y0 + 5 * c + 10, lv, size=9, fill='--paper-dim')
    f.text(x0 + 2.5 * c, y0 + 5 * c + 30, t['i'], size=10, weight='600')
    f.text(14, y0 + 2.5 * c - 30, t['p'], size=10, anchor='start', weight='600')
    letters = 'ABCD'
    for k, (pl, il) in enumerate(S.MATRIX):
        cx = x0 + (il - 1) * c + (c - 4) / 2
        cy = y0 + (5 - pl) * c + (c - 4) / 2
        f.circle(cx, cy, 11, fill='--panel', stroke='--paper', width=1.4)
        f.text(cx, cy, letters[k], size=10, weight='600', mono=True)
    lx = x0 + 5 * c + 24
    for k in range(4):
        y = 40 + k * 26
        f.text(lx, y, letters[k], size=10, anchor='start', weight='600', mono=True)
        f.text(lx + 18, y, RISK_SHORT[lang][k], size=9.5, anchor='start')
    for k, (z, col) in enumerate(zip(t['zones'], ['--amber', '--phosphor', '--paper-dim'])):
        y = 180 + k * 24
        f.rect(lx, y - 8, 14, 14, stroke=col, fill='--scan' if k == 0 else '--panel', rx=2)
        f.text(lx + 22, y - 1, z, size=9.5, anchor='start', fill=col if k < 2 else '--paper-dim')
    return f, t['cap']


@figure('l11-emv', 11)
def l11_emv(lang):
    t = {
        'en': dict(x='expected value, working days', tot='threats: 9.0 days', net='net with the opportunity: 7.4',
                   label='Horizontal bars of expected value for five risks. Payment API changes, 3 days. Billing '
                         'developer leaves, 2 days. Clinic data needs cleaning, 3 days. App store rejection, 1 day. '
                         'Calendar library fits, an opportunity, minus 1.6 days.',
                   cap='Probability times impact, risk by risk. Two risks that look nothing alike on the matrix — a '
                       'likely small one and an unlikely large one — can carry the same expected cost.'),
        'pt': dict(x='valor esperado, dias úteis', tot='ameaças: 9,0 dias', net='líquido com a oportunidade: 7,4',
                   label='Barras horizontais de valor esperado para cinco riscos. API de pagamento muda, 3 dias. Dev '
                         'do faturamento sai, 2 dias. Dados das clínicas sujos, 3 dias. Loja recusa o app, 1 dia. '
                         'Biblioteca de calendário serve, uma oportunidade, menos 1,6 dia.',
                   cap='Probabilidade vezes impacto, risco a risco. Dois riscos que não se parecem em nada na '
                       'matriz — um provável e pequeno, outro improvável e grande — podem carregar o mesmo custo '
                       'esperado.'),
    }[lang]
    f = Fig('l11-emv', 640, 290, t['label'])
    p = Plot(f, 260, 40, 600, 230, -2, 4, 0, 5)
    p.xaxis([-2, -1, 0, 1, 2, 3, 4], fmt=lambda v: ('−' if v < 0 else '') + str(abs(v)), label=t['x'])
    f.line(p.sx(0), p.y0, p.sx(0), p.y1, stroke='--paper-dim', width=1.2)
    for k, (name, pr, im) in enumerate(S.RISKS):
        e = pr * im
        y = 48 + k * 34
        a, b = sorted([p.sx(0), p.sx(e)])
        c = '--amber' if e > 0 else '--phosphor'
        f.path(f'M{a:.1f} {y:.1f} L{b:.1f} {y:.1f} L{b:.1f} {y + 22:.1f} L{a:.1f} {y + 22:.1f} Z',
               stroke=c, width=1, fill='--scan')
        f.text(p.x0 - 10, y + 11, RISK_SHORT[lang][k], size=9.5, anchor='end')
        lab = num(lang, e, 1)
        if e < 0:
            lab = '−' + num(lang, -e, 1)
        f.text(b + 6 if e > 0 else a - 6, y + 11, lab, size=9.5, anchor='start' if e > 0 else 'end',
               fill=c, weight='600')
    f.text(p.x1, 16, t['tot'], size=9.5, anchor='end', fill='--amber', weight='600')
    f.text(p.x1, 32, t['net'], size=9.5, anchor='end', fill='--paper-dim')
    return f, t['cap']

# ---- end of lesson 11


# ------------------------------------------------------------------ lesson 12

@figure('l12-urgency', 12)
def l12_urgency(lang):
    t = {
        'en': dict(titles=['standard', 'urgent', 'fixed date', 'intangible'],
                   notes=['value lost grows steadily', 'value lost grows fast, at once',
                          'nothing lost, then everything', 'little lost now, much later'],
                   x='time of delay', y='value lost',
                   label='Four small charts of value lost against time of delay. Standard: a straight line rising '
                         'steadily. Urgent: a steep line from the start. Fixed date: flat at zero, then a vertical '
                         'jump at the deadline. Intangible: nearly flat for a long time, then rising.',
                   cap='Four urgency profiles. The same feature can be worth the same in total and still deserve '
                       'opposite places in the queue, because what matters is how fast its value is lost while it '
                       'waits.'),
        'pt': dict(titles=['padrão', 'urgente', 'data fixa', 'intangível'],
                   notes=['a perda cresce de forma constante', 'a perda cresce rápido, já',
                          'nada se perde, depois tudo', 'pouca perda agora, muita depois'],
                   x='tempo de atraso', y='valor perdido',
                   label='Quatro gráficos pequenos de valor perdido contra tempo de atraso. Padrão: uma reta subindo '
                         'de forma constante. Urgente: uma reta íngreme desde o começo. Data fixa: plana em zero, '
                         'depois um salto vertical no prazo. Intangível: quase plana por muito tempo, depois subindo.',
                   cap='Quatro perfis de urgência. A mesma funcionalidade pode valer o mesmo no total e ainda merecer '
                       'lugares opostos na fila, porque o que importa é a rapidez com que o valor dela se perde '
                       'enquanto espera.'),
    }[lang]
    f = Fig('l12-urgency', 680, 230, t['label'])
    curves = [
        lambda u: u * 0.8,
        lambda u: min(1, u * 2.2),
        lambda u: 0 if u < 0.6 else 0.95,
        lambda u: 0.05 + 0.9 * u ** 4,
    ]
    for k, (title, note, fn) in enumerate(zip(t['titles'], t['notes'], curves)):
        x0 = 20 + k * 166
        w, h, top = 140, 110, 50
        f.text(x0 + w / 2, 22, title, size=10.5, weight='600')
        f.line(x0, top + h, x0 + w, top + h, stroke='--paper-dim', width=1.2)
        f.line(x0, top, x0, top + h, stroke='--paper-dim', width=1.2)
        if k == 2:
            d = (f'M{x0:.1f} {top + h:.1f} L{x0 + 0.6 * w:.1f} {top + h:.1f} L{x0 + 0.6 * w:.1f} '
                 f'{top + h - 0.95 * h:.1f} L{x0 + w:.1f} {top + h - 0.95 * h:.1f}')
        else:
            d = 'M' + ' L'.join(f'{x0 + u / 40 * w:.1f} {top + h - fn(u / 40) * h:.1f}' for u in range(41))
        f.path(d, stroke='--amber', width=2)
        f.text(x0 + w / 2, top + h + 16, note, size=9, fill='--paper-dim')
    f.text(20, 210, t['x'] + ' →', size=9.5, anchor='start', fill='--paper-dim')
    f.text(680 - 14, 210, '↑ ' + t['y'], size=9.5, anchor='end', fill='--paper-dim')
    return f, t['cap']


@figure('l12-kano', 12)
def l12_kano(lang):
    t = {
        'en': dict(x='how well the feature is provided', y='satisfaction',
                   basic='basic: expected, noticed only when missing', perf='performance: more is better',
                   delight='delighter: unexpected, pleases when present',
                   label='A chart with how well a feature is provided along the bottom and satisfaction up the side. '
                         'Three curves. Basic features stay below the middle line however well they are done, '
                         'rising only to neutral. Performance features rise in a straight line. Delighters start at '
                         'neutral and curve sharply upwards.',
                   cap='Kano’s three main kinds of requirement. Doing a basic one brilliantly earns nothing; leaving '
                       'it out is a disaster. Over the years, delighters drift down into basics, as every competitor '
                       'copies them.'),
        'pt': dict(x='quão bem a funcionalidade é oferecida', y='satisfação',
                   basic='básica: esperada, notada só quando falta', perf='de desempenho: mais é melhor',
                   delight='encantadora: inesperada, agrada quando existe',
                   label='Um gráfico com quão bem uma funcionalidade é oferecida na base e a satisfação na lateral. '
                         'Três curvas. Funcionalidades básicas ficam abaixo da linha do meio por melhor que sejam '
                         'feitas, subindo só até o neutro. As de desempenho sobem em linha reta. As encantadoras '
                         'começam no neutro e sobem em curva acentuada.',
                   cap='Os três tipos principais de requisito de Kano. Fazer uma básica de forma brilhante não rende '
                       'nada; deixá-la de fora é um desastre. Com os anos, as encantadoras descem para básicas, '
                       'conforme todo concorrente as copia.'),
    }[lang]
    f = Fig('l12-kano', 700, 300, t['label'])
    x0, x1, y0, y1 = 60, 400, 30, 250
    ym = (y0 + y1) / 2
    f.line(x0, ym, x1, ym, stroke='--paper-dim', width=1.2)
    f.line((x0 + x1) / 2, y0, (x0 + x1) / 2, y1, stroke='--paper-dim', width=1.2)
    f.text((x0 + x1) / 2, y1 + 18, t['x'] + ' →', size=9.5, fill='--paper-dim')
    f.text(x0 - 10, y0 + 4, t['y'], size=9.5, anchor='start', fill='--paper-dim')
    w = x1 - x0
    basic = 'M' + ' L'.join(f'{x0 + u / 40 * w:.1f} {ym + 100 * math.exp(-4 * u / 40) - 6:.1f}' for u in range(41))
    perf = f'M{x0:.1f} {y1 - 10:.1f} L{x1:.1f} {y0 + 10:.1f}'
    delight = 'M' + ' L'.join(f'{x0 + u / 40 * w:.1f} {ym - 100 * (math.exp(4 * u / 40) - 1) / (math.e ** 4 - 1) - 4:.1f}'
                              for u in range(41))
    f.path(basic, stroke='--paper', width=2)
    f.path(perf, stroke='--phosphor', width=2)
    f.path(delight, stroke='--amber', width=2)
    f.circle(420, 60, 5, fill='--amber')
    f.text(432, 60, t['delight'], size=9.5, anchor='start', fill='--amber')
    f.circle(420, 140, 5, fill='--phosphor')
    f.text(432, 140, t['perf'], size=9.5, anchor='start', fill='--phosphor')
    f.circle(420, 220, 5, fill='--paper')
    f.text(432, 220, t['basic'], size=9.5, anchor='start')
    return f, t['cap']

# ---- end of lesson 12


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

