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

