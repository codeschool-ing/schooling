#!/usr/bin/env python3
"""Every diagram in the ml-mlops course.

    python3 figures.py            # rewrite every figure in the lessons
    python3 figures.py --list     # the names, and the lesson each lives in

The machinery is pipelines-etl's figures.py, forked: a figure lives in a lesson's
prose as an ordinary `schooling-figure` fence whose SVG carries
`data-fig="<name>"`, which is how this file finds it again, and a placeholder
line `@@fig:<name>@@` is replaced the same way, which is how a figure enters a
section the first time. Running it redraws each one in both languages.

Only palette tokens are used, so each drawing turns over with the theme like
the page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel.

Standard library only.
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

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
def box(f, x, y, w, h, title, sub=None, stroke='--wire', fill='--panel', mono_sub=False, size=11.5):
    f.rect(x, y, w, h, stroke=stroke, fill=fill)
    if sub:
        f.text(x + w / 2, y + h / 2 - 8, title, size=size, weight='600')
        f.text(x + w / 2, y + h / 2 + 9, sub, size=10, fill='--paper-dim', mono=mono_sub)
    else:
        f.text(x + w / 2, y + h / 2, title, size=size, weight='600')


# ------------------------------------------------------------------ lesson 1

@figure('l01-rule-or-model', 1)
def l01_rule_or_model(lang):
    t = {'en': dict(
            label='Two ways to decide whether a member has lapsed. Above, a rule a person wrote: '
                  'a member today goes through the rule recency_days > 120 and comes out yes or '
                  'no. Below, a rule learned: last year\'s members, each with features and a known '
                  'label, are read by training, which produces a model; a member today goes '
                  'through the model and comes out with a probability, 0.86.',
            person='written by a person', learned='learned from examples',
            today='a member today', rule='a rule', yesno='yes or no',
            table='last year\'s members', feat='features', lab='label',
            training='training', model='a model', weights='one weight per feature',
            cap='The same question answered two ways. The rule is one line anybody can read; the '
                'model is a table of weights nobody wrote, and what it learned depends on which '
                'rows it was shown.'),
         'pt': dict(
            label='Duas formas de decidir se um membro se afastou. Em cima, uma regra que uma '
                  'pessoa escreveu: um membro de hoje passa pela regra recency_days > 120 e sai '
                  'sim ou não. Embaixo, uma regra aprendida: os membros do ano passado, cada um '
                  'com atributos e um rótulo conhecido, são lidos pelo treino, que produz um '
                  'modelo; um membro de hoje passa pelo modelo e sai com uma probabilidade, 0,86.',
            person='escrita por uma pessoa', learned='aprendida com exemplos',
            today='um membro hoje', rule='uma regra', yesno='sim ou não',
            table='membros do ano passado', feat='atributos', lab='rótulo',
            training='treino', model='um modelo', weights='um peso por atributo',
            cap='A mesma pergunta respondida de duas formas. A regra é uma linha que qualquer um '
                'lê; o modelo é uma tabela de pesos que ninguém escreveu, e o que ele aprendeu '
                'depende de quais linhas lhe foram mostradas.')}[lang]
    f = Fig('l01-rule-or-model', 720, 330, t['label'])
    f.text(20, 24, t['person'], size=11.5, anchor='start', weight='600', fill='--amber')
    box(f, 40, 44, 150, 50, t['today'])
    box(f, 280, 44, 180, 50, t['rule'], 'recency_days > 120', mono_sub=True)
    f.line(190, 69, 278, 69, stroke='--phosphor', width=1.6, arrow=True)
    f.line(460, 69, 548, 69, stroke='--phosphor', width=1.6, arrow=True)
    f.rect(550, 50, 140, 38, stroke='--amber', fill='--scan')
    f.text(620, 69, t['yesno'], size=11)
    f.line(20, 128, 700, 128, stroke='--wire', dash='4 4')
    f.text(20, 154, t['learned'], size=11.5, anchor='start', weight='600', fill='--amber')
    # the table of examples
    f.rect(40, 174, 200, 120, stroke='--wire', fill='--panel')
    f.text(140, 190, t['table'], size=11, weight='600')
    f.line(40, 202, 240, 202, stroke='--wire')
    f.text(105, 216, t['feat'], size=10, fill='--paper-dim')
    f.text(205, 216, t['lab'], size=10, fill='--paper-dim')
    f.line(170, 202, 170, 294, stroke='--wire')
    for i, (a, b) in enumerate([('4  4  33940', '0'), ('105  1  4990', '1'), ('30  6  76870', '0')]):
        f.text(105, 238 + i * 20, a, size=10, mono=True)
        f.text(205, 238 + i * 20, b, size=10, mono=True, fill='--amber')
    f.line(240, 234, 318, 234, stroke='--phosphor', width=1.6, arrow=True)
    f.text(279, 224, t['training'], size=10, fill='--paper-dim')
    box(f, 320, 204, 160, 60, t['model'], t['weights'], stroke='--phosphor')
    f.rect(330, 300, 140, 26, stroke='--wire', fill='--panel')
    f.text(400, 313, t['today'], size=10.5)
    f.line(400, 300, 400, 266, stroke='--phosphor', width=1.6, arrow=True)
    f.line(480, 234, 548, 234, stroke='--phosphor', width=1.6, arrow=True)
    f.rect(550, 215, 140, 38, stroke='--amber', fill='--scan')
    f.text(620, 234, 'p = 0.86' if lang == 'en' else 'p = 0,86', size=11, mono=True)
    return f, t['cap']


@figure('l01-three-kinds', 1)
def l01_three_kinds(lang):
    t = {'en': dict(
            label='Three columns, one per kind of learning, showing what each is given. '
                  'Supervised: rows, each with an answer beside it. Unsupervised: rows and no '
                  'answer; it returns groups. Reinforcement: no rows at the start; an agent '
                  'acts on an environment, receives a reward, and acts again, in a loop.',
            kinds=['supervised', 'unsupervised', 'reinforcement'],
            given=['rows, each with its answer', 'rows, no answer', 'no rows: a loop'],
            gets=['a function from row to answer', 'groups, or structure', 'a policy: what to do next'],
            agent='agent', env='environment', act='action', rew='reward',
            row='row', ans='answer',
            cap='What each kind is given decides it. The data you have, or can collect, sorts the '
                'question before any algorithm is chosen.'),
         'pt': dict(
            label='Três colunas, uma por tipo de aprendizado, mostrando o que cada um recebe. '
                  'Supervisionado: linhas, cada uma com uma resposta ao lado. Não supervisionado: '
                  'linhas e nenhuma resposta; devolve grupos. Por reforço: nenhuma linha no '
                  'começo; um agente age sobre um ambiente, recebe uma recompensa e age de novo, '
                  'em ciclo.',
            kinds=['supervisionado', 'não supervisionado', 'por reforço'],
            given=['linhas, cada uma com a resposta', 'linhas, sem resposta', 'sem linhas: um ciclo'],
            gets=['uma função de linha para resposta', 'grupos, ou estrutura', 'uma política: o que fazer'],
            agent='agente', env='ambiente', act='ação', rew='recompensa',
            row='linha', ans='resposta',
            cap='O que cada tipo recebe é o que o define. Os dados que você tem, ou pode coletar, '
                'classificam a pergunta antes de qualquer algoritmo ser escolhido.')}[lang]
    f = Fig('l01-three-kinds', 720, 300, t['label'])
    for c in range(3):
        x = 20 + c * 236
        f.rect(x, 20, 220, 260, stroke='--wire', fill='--panel')
        f.text(x + 110, 42, t['kinds'][c], size=12.5, weight='700', fill='--amber')
        f.text(x + 110, 64, t['given'][c], size=10.5, fill='--paper-dim')
        f.text(x + 110, 258, t['gets'][c], size=10.5)
    # supervised rows with answers
    for i in range(4):
        y = 92 + i * 30
        f.rect(40, y, 120, 20, stroke='--phosphor', fill='--scan', rx=3)
        f.text(100, y + 10, t['row'], size=9.5)
        f.rect(168, y, 52, 20, stroke='--amber', fill='--scan', rx=3)
        f.text(194, y + 10, t['ans'], size=9.5)
    # unsupervised dots in groups
    import math
    for gx, gy, n in [(320, 120, 6), (400, 110, 5), (350, 190, 7)]:
        f.circle(gx, gy, 24, fill=None, stroke='--amber', width=1)
        for k in range(n):
            a = 2 * math.pi * k / n
            f.circle(gx + 12 * math.cos(a), gy + 12 * math.sin(a), 3.2, fill='--phosphor')
    # reinforcement loop
    x0 = 492
    box(f, x0 + 20, 92, 180, 34, t['agent'], stroke='--phosphor')
    box(f, x0 + 20, 186, 180, 34, t['env'])
    f.path(f'M{x0 + 60} 127 L{x0 + 60} 184', stroke='--phosphor', width=1.6, arrow=True)
    f.text(x0 + 66, 156, t['act'], size=10, anchor='start', fill='--paper-dim')
    f.path(f'M{x0 + 160} 185 L{x0 + 160} 128', stroke='--amber', width=1.6, arrow=True)
    f.text(x0 + 154, 156, t['rew'], size=10, anchor='end', fill='--paper-dim')
    return f, t['cap']


@figure('l02-four-answers', 2)
def l02_four_answers(lang):
    t = {'en': dict(
            label='Four panels, one per task, each showing what goes in and what comes out. '
                  'Classification: member 1 goes in, a probability of 0.129 comes out. Regression: '
                  'member 1 goes in, R$ 283.75 comes out. Clustering: many members go in, and each '
                  'comes out with a group number. Recommendation: member 2 goes in, a ranked list of '
                  'five titles comes out.',
            names=['classification', 'regression', 'clustering', 'recommendation'],
            ins=['member 1', 'member 1', 'every member', 'member 2'],
            outs=['p(lapse) = 0.129', 'R$ 283.75', 'group 6', '1. The Harbour of Crime'],
            more=['2. The Mirror of Crime', '3. The Station of Crime'],
            notes=['a category, with a probability', 'an amount', 'a number with no name',
                   'a ranked list, keyed by a pair'],
            cap='What comes out is what the platform stores. A probability, an amount, a group '
                'number that only means something within one run, and a list of pairs.'),
         'pt': dict(
            label='Quatro painéis, um por tarefa, cada um mostrando o que entra e o que sai. '
                  'Classificação: entra o membro 1, sai uma probabilidade de 0,129. Regressão: '
                  'entra o membro 1, sai R$ 283,75. Agrupamento: entram muitos membros, e cada um '
                  'sai com um número de grupo. Recomendação: entra o membro 2, sai uma lista '
                  'ordenada de cinco títulos.',
            names=['classificação', 'regressão', 'agrupamento', 'recomendação'],
            ins=['membro 1', 'membro 1', 'todos os membros', 'membro 2'],
            outs=['p(lapse) = 0,129', 'R$ 283,75', 'grupo 6', '1. The Harbour of Crime'],
            more=['2. The Mirror of Crime', '3. The Station of Crime'],
            notes=['uma categoria, com probabilidade', 'uma quantia', 'um número sem nome',
                   'uma lista, por par'],
            cap='O que sai é o que a plataforma guarda. Uma probabilidade, uma quantia, um número '
                'de grupo que só significa algo dentro de uma rodada, e uma lista de pares.')}[lang]
    f = Fig('l02-four-answers', 720, 300, t['label'])
    for i in range(4):
        x = 12 + i * 177
        f.rect(x, 14, 167, 272, stroke='--wire', fill='--panel')
        f.text(x + 83, 34, t['names'][i], size=12, weight='700', fill='--amber')
        f.rect(x + 18, 56, 131, 30, stroke='--wire', fill='--scan')
        f.text(x + 83, 71, t['ins'][i], size=10.5)
        f.line(x + 83, 88, x + 83, 124, stroke='--phosphor', width=1.6, arrow=True)
        f.text(x + 83, 262, t['notes'][i], size=9.5, fill='--paper-dim')
    # outputs
    f.rect(12 + 10, 128, 147, 32, stroke='--amber', fill='--scan')
    f.text(12 + 83, 144, t['outs'][0], size=10.5, mono=True)
    f.rect(189 + 10, 128, 147, 32, stroke='--amber', fill='--scan')
    f.text(189 + 83, 144, t['outs'][1], size=10.5, mono=True)
    x = 366
    for k, (dx, dy, g) in enumerate([(30, 140, '6'), (70, 150, '6'), (110, 138, '2'), (50, 185, '2'),
                                    (95, 190, '6'), (130, 175, '3'), (35, 220, '3'), (120, 218, '2')]):
        f.circle(x + dx + 8, dy, 9, fill='--scan', stroke='--phosphor')
        f.text(x + dx + 8, dy, g, size=9, mono=True)
    f.text(x + 83, 240, t['outs'][2], size=10, fill='--paper-dim')
    x = 543
    for k, s in enumerate([t['outs'][3]] + t['more']):
        f.rect(x + 8, 128 + k * 30, 151, 24, stroke='--amber' if k == 0 else '--wire', fill='--scan')
        f.text(x + 83, 140 + k * 30, s, size=9, mono=True)
    return f, t['cap']


@figure('l02-silhouette', 2)
def l02_silhouette(lang):
    vals = [(2, 0.129), (3, 0.176), (4, 0.227), (5, 0.258), (6, 0.281), (7, 0.309), (8, 0.322),
            (9, 0.304), (10, 0.295)]
    t = {'en': dict(
            label='The silhouette for k from 2 to 10: 0.129, 0.176, 0.227, 0.258, 0.281, 0.309, '
                  '0.322, 0.304, 0.295. It rises to a peak at k = 8 and falls after.',
            x='number of groups, k', y='silhouette', peak='peak at 8',
            cap='The silhouette climbs until eight groups and falls after: eight is where each '
                'member is most clearly closer to their own group than to the next.'),
         'pt': dict(
            label='A silhueta para k de 2 a 10: 0,129, 0,176, 0,227, 0,258, 0,281, 0,309, 0,322, '
                  '0,304, 0,295. Ela sobe até um pico em k = 8 e cai depois.',
            x='número de grupos, k', y='silhueta', peak='pico em 8',
            cap='A silhueta sobe até oito grupos e cai depois: oito é onde cada membro está mais '
                'claramente mais perto do próprio grupo do que do seguinte.')}[lang]
    f = Fig('l02-silhouette', 720, 280, t['label'])
    p = Plot(f, 80, 40, 680, 220, 1.5, 10.5, 0, 0.4)
    p.yaxis([0, 0.1, 0.2, 0.3, 0.4], fmt=lambda v: num(lang, v, 1), label=t['y'])
    p.xaxis(range(2, 11), label=t['x'])
    d = 'M' + ' L'.join(f'{p.sx(k):.1f} {p.sy(v):.1f}' for k, v in vals)
    f.path(d, stroke='--phosphor', width=2)
    for k, v in vals:
        f.circle(p.sx(k), p.sy(v), 4.5 if k == 8 else 3.5, fill='--amber' if k == 8 else '--phosphor')
    f.text(p.sx(8), p.sy(0.322) - 16, t['peak'] + ' · ' + num(lang, 0.322, 3), size=10.5,
           fill='--amber', weight='600')
    return f, t['cap']


@figure('l03-overfit', 3)
def l03_overfit(lang):
    rows = [('2', 0.734, 0.719), ('4', 0.795, 0.762), ('6', 0.831, 0.751), ('8', 0.871, 0.723),
            ('12', 0.957, 0.662), ('∞' if False else 'none', 1.000, 0.636)]
    t = {'en': dict(
            label='AUC of a decision tree against its maximum depth: 2, 4, 6, 8, 12 and no limit. On '
                  'the training rows it rises steadily: 0.734, 0.795, 0.831, 0.871, 0.957, 1.000. '
                  'On the validation rows it rises to 0.762 at depth 4 and then falls: 0.751, '
                  '0.723, 0.662, 0.636.',
            x='maximum depth of the tree', train='training rows', valid='validation rows',
            none='none', best='best on validation',
            cap='The deeper the tree, the better it remembers the rows it learned from and the '
                'worse it does on the next month. The gap between the lines is overfitting.'),
         'pt': dict(
            label='AUC de uma árvore de decisão contra a sua profundidade máxima: 2, 4, 6, 8, 12 e '
                  'sem limite. Nas linhas de treino ela sobe sem parar: 0,734, 0,795, 0,831, 0,871, '
                  '0,957, 1,000. Nas linhas de validação ela sobe até 0,762 na profundidade 4 e '
                  'depois cai: 0,751, 0,723, 0,662, 0,636.',
            x='profundidade máxima da árvore', train='linhas de treino', valid='linhas de validação',
            none='sem limite', best='melhor na validação',
            cap='Quanto mais funda a árvore, melhor ela lembra as linhas com que aprendeu e pior se '
                'sai no mês seguinte. A distância entre as linhas é o sobreajuste.')}[lang]
    f = Fig('l03-overfit', 720, 290, t['label'])
    p = Plot(f, 80, 40, 560, 230, -0.5, 5.5, 0.6, 1.0)
    p.yaxis([0.6, 0.7, 0.8, 0.9, 1.0], fmt=lambda v: num(lang, v, 1), label='AUC')
    labels = [r[0] for r in rows[:-1]] + [t['none']]
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for i, lab in enumerate(labels):
        f.text(p.sx(i), p.y1 + 13, lab, size=9.5, fill='--paper-dim')
    f.text((p.x0 + p.x1) / 2, p.y1 + 31, t['x'], size=10, weight='600')
    for k, stroke in ((1, '--paper-dim'), (2, '--phosphor')):
        d = 'M' + ' L'.join(f'{p.sx(i):.1f} {p.sy(r[k]):.1f}' for i, r in enumerate(rows))
        f.path(d, stroke=stroke, width=2, dash='5 4' if k == 1 else None)
        for i, r in enumerate(rows):
            f.circle(p.sx(i), p.sy(r[k]), 3.5, fill='--amber' if (k == 2 and i == 1) else stroke)
    f.text(p.sx(1), p.sy(0.762) + 18, t['best'], size=10, fill='--amber', weight='600')
    f.line(580, 70, 610, 70, stroke='--paper-dim', width=2, dash='5 4')
    f.text(618, 70, t['train'], size=10.5, anchor='start')
    f.line(580, 96, 610, 96, stroke='--phosphor', width=2)
    f.text(618, 96, t['valid'], size=10.5, anchor='start')
    return f, t['cap']


@figure('l03-moment', 3)
def l03_moment(lang):
    t = {'en': dict(
            label='A timeline around the cutoff, 30 November 2025. To its left, the 180 days the '
                  'features are computed from. To its right, the 90 days the label is computed '
                  'from. Anything from the right-hand side that reaches a feature is leakage.',
            cutoff='the cutoff: the moment of prediction', feat='features: 180 days before',
            lab='label: 90 days after', leak='any of this in a feature is leakage',
            d=['4 Jun 2025', '30 Nov 2025', '28 Feb 2026'],
            cap='One date divides every example. What is to its left may describe the member; what '
                'is to its right may only be the answer.'),
         'pt': dict(
            label='Uma linha do tempo em volta do corte, 30 de novembro de 2025. À esquerda, os 180 '
                  'dias de onde os atributos são calculados. À direita, os 90 dias de onde o rótulo '
                  'é calculado. Qualquer coisa do lado direito que chegue a um atributo é '
                  'vazamento.',
            cutoff='o corte: o momento da predição', feat='atributos: 180 dias antes',
            lab='rótulo: 90 dias depois', leak='qualquer coisa daqui num atributo é vazamento',
            d=['4 jun 2025', '30 nov 2025', '28 fev 2026'],
            cap='Uma data divide cada exemplo. O que está à esquerda pode descrever o membro; o que '
                'está à direita só pode ser a resposta.')}[lang]
    f = Fig('l03-moment', 720, 220, t['label'])
    x0, xc, x1, y = 40, 440, 680, 110
    f.rect(x0, y - 22, xc - x0, 44, stroke='--phosphor', fill='--scan')
    f.text((x0 + xc) / 2, y, t['feat'], size=11)
    f.rect(xc, y - 22, x1 - xc, 44, stroke='--amber', fill='--panel', dash='5 4')
    f.text((xc + x1) / 2, y, t['lab'], size=11)
    f.line(xc, 40, xc, 160, stroke='--amber', width=2)
    f.text(xc, 30, t['cutoff'], size=11, weight='600', fill='--amber')
    for x, d in zip((x0, xc, x1), t['d']):
        f.text(x, 150, d, size=9.5, fill='--paper-dim', mono=True,
               anchor='start' if x == x0 else ('end' if x == x1 else 'middle'))
    f.path(f'M{(xc + x1) / 2:.1f} 134 C {(xc + x1) / 2:.1f} 190, {(x0 + xc) / 2 + 60:.1f} 190, '
           f'{(x0 + xc) / 2 + 60:.1f} 134', stroke='--amber', width=1.4, dash='4 3', arrow=True)
    f.text((x0 + x1) / 2 + 40, 200, t['leak'], size=10, fill='--amber')
    return f, t['cap']


@figure('l03-timeline', 3)
def l03_timeline(lang):
    months = ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb']
    if lang == 'pt':
        months = ['mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez', 'jan', 'fev']
    t = {'en': dict(
            label='A calendar from March 2025 to February 2026. Six training cutoffs, at the ends of '
                  'March to August, each followed by its 90-day label window; the last window, '
                  'from 31 August, closes on 29 November. The test cutoff is 30 November, and its '
                  'own label window runs to 28 February.',
            train='training cutoffs and their 90 days', test='test cutoff',
            gap='the newest training label closes 29 Nov',
            cap='Every training label has to be closed by the test cutoff, because on that night '
                'in production nothing later exists. The gap is the label window.'),
         'pt': dict(
            label='Um calendário de março de 2025 a fevereiro de 2026. Seis cortes de treino, nos '
                  'fins de março a agosto, cada um seguido da sua janela de rótulo de 90 dias; a '
                  'última janela, de 31 de agosto, fecha em 29 de novembro. O corte de teste é 30 de '
                  'novembro, e a janela de rótulo dele vai até 28 de fevereiro.',
            train='cortes de treino e os seus 90 dias', test='corte de teste',
            gap='o rótulo de treino mais novo fecha em 29 nov',
            cap='Todo rótulo de treino precisa estar fechado no corte de teste, porque naquela noite, '
                'em produção, nada posterior existe. A distância é a janela do rótulo.')}[lang]
    f = Fig('l03-timeline', 720, 300, t['label'])
    x0, w = 50, 52
    for i, m in enumerate(months):
        f.text(x0 + i * w + w / 2, 30, m, size=10, fill='--paper-dim')
        f.line(x0 + i * w, 40, x0 + i * w, 250, stroke='--wire', width=0.8)
    for k in range(6):
        y = 60 + k * 22
        xs = x0 + (k + 1) * w
        f.circle(xs, y, 4, fill='--phosphor')
        f.rect(xs + 4, y - 6, 3 * w - 4, 12, stroke='--phosphor', fill='--scan', rx=3)
    xt = x0 + 9 * w
    f.line(xt, 40, xt, 250, stroke='--amber', width=2)
    f.circle(xt, 210, 5, fill='--amber')
    f.rect(xt + 5, 204, 3 * w - 5, 12, stroke='--amber', fill='--panel', rx=3, dash='4 3')
    f.text(xt - 8, 238, t['test'], size=10.5, anchor='end', fill='--amber', weight='600')
    f.text(x0, 270, t['train'], size=10.5, anchor='start', fill='--phosphor', weight='600')
    f.text(xt - 8, 186, t['gap'], size=10, anchor='end', fill='--paper')
    return f, t['cap']


@figure('l03-maturity', 3)
def l03_maturity(lang):
    vals = [('2025-10-31', 17.1), ('2025-11-15', 17.0), ('2025-11-30', 16.9), ('2025-12-15', 19.2),
            ('2025-12-31', 23.2), ('2026-01-15', 30.1), ('2026-01-31', 43.1), ('2026-02-15', 65.5)]
    t = {'en': dict(
            label='Share of active members labelled lapsed, by cutoff: 17.1% at 31 October, 17.0% '
                  'at 15 November, 16.9% at 30 November, then 19.2%, 23.2%, 30.1%, 43.1% and 65.5% '
                  'at 15 February, as the 90-day window runs past the last day of data.',
            y='labelled lapsed', closed='window closed', open='window still open',
            cap='The label is honest until its window reaches past the data. After that, every '
                'member who has not yet come back is counted as gone.'),
         'pt': dict(
            label='Fração de membros ativos rotulados como afastados, por corte: 17,1% em 31 de '
                  'outubro, 17,0% em 15 de novembro, 16,9% em 30 de novembro, depois 19,2%, 23,2%, '
                  '30,1%, 43,1% e 65,5% em 15 de fevereiro, à medida que a janela de 90 dias passa '
                  'do último dia dos dados.',
            y='rotulados afastados', closed='janela fechada', open='janela ainda aberta',
            cap='O rótulo é honesto até a janela passar dos dados. Depois disso, todo membro que '
                'ainda não voltou conta como perdido.')}[lang]
    f = Fig('l03-maturity', 720, 290, t['label'])
    p = Plot(f, 70, 40, 690, 220, -0.6, 7.6, 0, 70)
    p.yaxis([0, 20, 40, 60], fmt=lambda v: f'{v}%', label=t['y'])
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for i, (c, v) in enumerate(vals):
        x = p.sx(i)
        fill = '--phosphor-dim' if i < 3 else '--amber'
        f.path(f'M{x - 22:.1f} {p.y1:.1f} L{x - 22:.1f} {p.sy(v):.1f} L{x + 22:.1f} {p.sy(v):.1f} '
               f'L{x + 22:.1f} {p.y1:.1f} Z', stroke='--phosphor' if i < 3 else '--amber', width=1,
               fill=fill)
        f.text(x, p.sy(v) - 9, num(lang, v, 1) + '%', size=9.5)
        f.text(x, p.y1 + 13, c[2:], size=9, fill='--paper-dim', mono=True)
    f.text(p.sx(1), p.y1 + 32, t['closed'], size=10, fill='--phosphor', weight='600')
    f.text(p.sx(5.5), p.y1 + 32, t['open'], size=10, fill='--amber', weight='600')
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
