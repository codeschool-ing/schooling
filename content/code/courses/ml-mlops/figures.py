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
