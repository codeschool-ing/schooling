#!/usr/bin/env python3
"""Every diagram in the pipelines-etl course.

    python3 figures.py            # rewrite every figure in the lessons
    python3 figures.py --list     # the names, and the lesson each lives in

The machinery is statistics' figures.py, forked: a figure lives in a lesson's
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

@figure('l01-freshness', 1)
def l01_freshness(lang):
    t = {'en': dict(
            label='A line from seconds to a day, measuring how old an answer may be when it is '
                  'read. Three questions sit on it: whether a book is in stock now, at seconds; '
                  'which books sold this morning, at an hour; sales per shop last month, at a day. '
                  'Below the line, three bands: a stream covers seconds to a minute, a micro-batch '
                  'minutes to an hour, and a batch hours to a day.',
            axis='how old the answer may be when somebody reads it',
            ticks=['1 second', '1 minute', '1 hour', '1 day'],
            q=['is this book in stock now?', 'which books sold this morning?',
               'sales per shop last month'],
            bands=['stream', 'micro-batch', 'batch'],
            cap='Put an age on each question first. The kind of ingestion is whatever band the '
                'age falls in, and the cheapest one that reaches it wins.'),
         'pt': dict(
            label='Uma linha de segundos a um dia, medindo quão velha uma resposta pode ser quando '
                  'é lida. Três perguntas estão sobre ela: se um livro tem estoque agora, em '
                  'segundos; quais livros venderam hoje de manhã, em uma hora; vendas por loja no '
                  'mês passado, em um dia. Abaixo da linha, três faixas: um stream cobre de '
                  'segundos a um minuto, um micro-batch de minutos a uma hora, e um batch de horas '
                  'a um dia.',
            axis='quão velha a resposta pode estar quando alguém a lê',
            ticks=['1 segundo', '1 minuto', '1 hora', '1 dia'],
            q=['este livro tem estoque agora?', 'que livros venderam hoje de manhã?',
               'vendas por loja no mês passado'],
            bands=['stream', 'micro-batch', 'batch'],
            cap='Ponha uma idade em cada pergunta primeiro. O tipo de ingestão é a faixa onde a '
                'idade cai, e ganha a mais barata que chega lá.')}[lang]
    f = Fig('l01-freshness', 720, 260, t['label'])
    x0, x1, y = 70, 650, 120
    xs = [x0 + (x1 - x0) * i / 3 for i in range(4)]
    f.line(x0, y, x1 + 20, y, stroke='--paper-dim', width=1.4, arrow=True)
    for x, tk in zip(xs, t['ticks']):
        f.line(x, y - 5, x, y + 5, stroke='--paper-dim')
        f.text(x, y + 18, tk, size=10.5, fill='--paper-dim')
    f.text((x0 + x1) / 2, 236, t['axis'], size=11, weight='600')
    for x, q, ny in zip([xs[0] + 8, xs[2], xs[3]], t['q'], [40, 70, 40]):
        f.circle(x, y, 5, fill='--amber')
        f.line(x, y - 6, x, ny + 10, stroke='--amber', dash='3 3')
        f.text(x, ny, q, size=11, fill='--paper',
               anchor='start' if x < 200 else ('end' if x > 600 else 'middle'))
    for (a, b), name, row in zip([(xs[0], xs[1]), (xs[1] - 30, xs[2]), (xs[2] - 30, xs[3])],
                                 t['bands'], [0, 1, 0]):
        yy = 150 + row * 30
        f.rect(a, yy, b - a, 22, stroke='--phosphor', fill='--scan', rx=11)
        f.text((a + b) / 2, yy + 11, name, size=10.5, fill='--paper', mono=True)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 2

def box(f, x, y, w, h, title, sub=None, stroke='--wire', fill='--panel', mono_sub=False, size=11.5):
    f.rect(x, y, w, h, stroke=stroke, fill=fill)
    if sub:
        f.text(x + w / 2, y + h / 2 - 8, title, size=size, weight='600')
        f.text(x + w / 2, y + h / 2 + 9, sub, size=10, fill='--paper-dim', mono=mono_sub)
    else:
        f.text(x + w / 2, y + h / 2, title, size=size, weight='600')


@figure('l02-etl-elt', 2)
def l02_etl_elt(lang):
    t = {'en': dict(
            label='Two lanes from the shop to the warehouse. In ETL, rows are extracted, '
                  'transformed in a program between the two systems, and only the answer is '
                  'loaded. In ELT, rows are extracted and loaded unchanged into a raw layer, and '
                  'the transformation runs as SQL inside the warehouse.',
            shop='the shop', wh='the warehouse', prog='a program',
            etl=['extract', 'transform', 'load'], elt=['extract', 'load', 'transform'],
            moved_etl='98 rows cross', moved_elt='6,181 rows cross',
            raw='raw rows', answer='the answer', sql='SQL, in here',
            cap='The same three steps in a different order. What changes is which machine does '
                'the transformation, and how much of the source crosses to the warehouse.'),
         'pt': dict(
            label='Duas faixas da loja ao warehouse. No ETL, as linhas são extraídas, '
                  'transformadas num programa entre os dois sistemas, e só a resposta é '
                  'carregada. No ELT, as linhas são extraídas e carregadas sem mudança numa camada '
                  'crua, e a transformação roda como SQL dentro do warehouse.',
            shop='a loja', wh='o warehouse', prog='um programa',
            etl=['extrair', 'transformar', 'carregar'], elt=['extrair', 'carregar', 'transformar'],
            moved_etl='98 linhas atravessam', moved_elt='6.181 linhas atravessam',
            raw='linhas cruas', answer='a resposta', sql='SQL, aqui dentro',
            cap='Os mesmos três passos em outra ordem. O que muda é qual máquina faz a '
                'transformação, e quanto da origem atravessa até o warehouse.')}[lang]
    f = Fig('l02-etl-elt', 720, 330, t['label'])
    for row, (name, steps, moved) in enumerate([('ETL', t['etl'], t['moved_etl']),
                                                ('ELT', t['elt'], t['moved_elt'])]):
        y = 30 + row * 150
        f.text(30, y + 35, name, size=13, weight='700', fill='--amber', mono=True)
        box(f, 70, y + 10, 120, 50, t['shop'], 'PostgreSQL', mono_sub=True)
        f.rect(530, y + 10, 160, 100, stroke='--wire', fill='--panel')
        f.text(610, y + 30, t['wh'], size=11.5, weight='600')
        if row == 0:
            box(f, 290, y + 10, 140, 50, t['prog'], 'Python', mono_sub=True)
            f.line(190, y + 35, 288, y + 35, stroke='--phosphor', width=1.6, arrow=True)
            f.text(239, y + 25, steps[0], size=10, fill='--paper-dim')
            f.text(360, y + 76, steps[1], size=10.5, fill='--amber', weight='600')
            f.line(430, y + 35, 528, y + 35, stroke='--phosphor', width=1.6, arrow=True)
            f.text(479, y + 25, steps[2], size=10, fill='--paper-dim')
            f.text(479, y + 50, moved, size=9.5, fill='--paper-dim')
            f.rect(545, y + 64, 130, 22, stroke='--amber', fill='--scan', rx=4)
            f.text(610, y + 75, t['answer'], size=10)
        else:
            f.line(190, y + 35, 528, y + 35, stroke='--phosphor', width=1.6, arrow=True)
            f.text(359, y + 25, steps[0] + ' + ' + steps[1], size=10, fill='--paper-dim')
            f.text(359, y + 50, moved, size=9.5, fill='--paper-dim')
            f.rect(545, y + 48, 130, 22, stroke='--wire', fill='--scan', rx=4)
            f.text(610, y + 59, t['raw'], size=10)
            f.rect(545, y + 80, 130, 22, stroke='--amber', fill='--scan', rx=4)
            f.text(610, y + 91, t['answer'], size=10)
            f.path(f'M676 {y + 59} C 700 {y + 62}, 700 {y + 88}, 677 {y + 91}', stroke='--amber',
                   width=1.4, arrow=True)
            f.text(610, y + 128, steps[2] + ': ' + t['sql'], size=10.5, fill='--amber', weight='600')
    return f, t['cap']


@figure('l02-layers', 2)
def l02_layers(lang):
    t = {'en': dict(
            label='Three layers stacked inside the warehouse. At the bottom, raw: the source\'s '
                  'tables as they arrived, written only by the extraction. In the middle, staging: '
                  'one cleaned table per raw table. At the top, marts: facts, dimensions and '
                  'summaries, the only layer reports read. Arrows go upwards only.',
            layers=[('marts', 'facts, dimensions, summaries', 'read by reports'),
                    ('staging', 'one cleaned table per source table', 'read by marts'),
                    ('raw', 'the source, as it arrived', 'written by the extraction')],
            src='sources', reports='reports',
            cap='Each layer is a schema, and each reads only the one below it. A report that '
                'reaches past staging into raw repeats the cleaning, a little differently.'),
         'pt': dict(
            label='Três camadas empilhadas dentro do warehouse. Embaixo, raw: as tabelas da origem '
                  'como chegaram, escritas só pela extração. No meio, staging: uma tabela limpa por '
                  'tabela crua. No topo, marts: fatos, dimensões e resumos, a única camada que os '
                  'relatórios leem. As setas só sobem.',
            layers=[('marts', 'fatos, dimensões, resumos', 'lida pelos relatórios'),
                    ('staging', 'uma tabela limpa por tabela de origem', 'lida pelos marts'),
                    ('raw', 'a origem, como chegou', 'escrita pela extração')],
            src='origens', reports='relatórios',
            cap='Cada camada é um schema, e cada uma lê só a de baixo. Um relatório que passa por '
                'cima do staging até o raw repete a limpeza, um pouco diferente.')}[lang]
    f = Fig('l02-layers', 720, 300, t['label'])
    for i, (name, what, who) in enumerate(t['layers']):
        y = 40 + i * 80
        f.rect(170, y, 380, 54, stroke='--phosphor' if i == 0 else '--wire', fill='--panel')
        f.text(190, y + 18, name, size=12.5, weight='700', anchor='start', mono=True,
               fill='--amber' if i == 0 else '--paper')
        f.text(190, y + 38, what, size=10.5, anchor='start', fill='--paper')
        f.text(570, y + 27, who, size=10, anchor='start', fill='--paper-dim')
        if i < 2:
            f.line(360, y + 78, 360, y + 56, stroke='--phosphor', width=1.4, arrow=True)
    f.text(90, 287, t['src'], size=10.5, fill='--paper-dim')
    f.line(90, 277, 168, 230, stroke='--paper-dim', width=1.2, arrow=True)
    f.text(90, 22, t['reports'], size=10.5, fill='--paper-dim')
    f.line(168, 62, 110, 30, stroke='--paper-dim', width=1.2, arrow=True)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 3

@figure('l03-torn', 3)
def l03_torn(lang):
    t = {'en': dict(
            label='A timeline of four seconds. At the start, the extraction counts orders and gets '
                  '17,453. A second later a day of trade commits 296 new orders and their lines. '
                  'At four seconds the extraction reads the lines, and they belong to 17,749 '
                  'orders. Below, the same reads inside one REPEATABLE READ transaction both see '
                  'the moment of the first query.',
            two='two statements', one='one REPEATABLE READ transaction',
            q1='count orders', q2='read lines',
            commit='a day of trade commits', n1='17,453', n2='17,749', n3='17,749', n4='17,749',
            sec='seconds',
            cap='Each read is correct for its own moment. The snapshot makes both reads describe '
                'the same one.'),
         'pt': dict(
            label='Uma linha do tempo de quatro segundos. No início, a extração conta os pedidos e '
                  'obtém 17.453. Um segundo depois, um dia de vendas confirma 296 pedidos novos e '
                  'as suas linhas. Aos quatro segundos a extração lê as linhas, e elas pertencem a '
                  '17.749 pedidos. Embaixo, as mesmas leituras dentro de uma transação REPEATABLE '
                  'READ veem as duas o momento da primeira consulta.',
            two='dois comandos', one='uma transação REPEATABLE READ',
            q1='contar pedidos', q2='ler linhas',
            commit='um dia de vendas é confirmado', n1='17.453', n2='17.749', n3='17.749',
            n4='17.749', sec='segundos',
            cap='Cada leitura está certa para o seu próprio momento. O snapshot faz as duas '
                'descreverem o mesmo.')}[lang]
    f = Fig('l03-torn', 720, 290, t['label'])
    x0, x1 = 140, 610
    sx = lambda s: x0 + (x1 - x0) * s / 4
    f.line(x0, 250, x1 + 15, 250, stroke='--paper-dim', arrow=True)
    for s_ in range(5):
        f.line(sx(s_), 246, sx(s_), 254, stroke='--paper-dim')
        f.text(sx(s_), 266, str(s_), size=10, fill='--paper-dim')
    f.text(x1 + 22, 250, t['sec'], size=10, fill='--paper-dim', anchor='start')
    for xx in (sx(1), sx(1.6)):
        f.line(xx, 30, xx, 232, stroke='--amber', dash='4 3')
    f.text(sx(1.3), 20, t['commit'], size=10.5, fill='--amber', weight='600')
    for row, (name, a, b) in enumerate([(t['two'], t['n1'], t['n2']), (t['one'], t['n3'], t['n4'])]):
        y = 80 + row * 95
        f.text(20, y - 30, name, size=11, weight='600', anchor='start')
        f.line(sx(0), y, sx(4), y, stroke='--wire', width=1.2, dash='2 3')
        for s_, q, n in [(0, t['q1'], a), (4, t['q2'], b)]:
            f.circle(sx(s_), y, 6, fill='--phosphor')
            f.text(sx(s_), y + 18, q, size=10, fill='--paper-dim')
            f.text(sx(s_), y - 14, n, size=11, weight='600', mono=True,
                   fill='--amber' if (row == 0 and s_ == 4) else '--paper')
        if row == 1:
            f.path(f'M{sx(4) - 8:.1f} {y - 4} C {sx(3):.1f} {y - 40}, {sx(1):.1f} {y - 40}, '
                   f'{sx(0) + 8:.1f} {y - 6}', stroke='--phosphor', dash='3 3', arrow=True)
    return f, t['cap']


@figure('l03-late', 3)
def l03_late(lang):
    t = {'en': dict(
            label='Two time lines, one above the other. The top one is when events happened, '
                  'the bottom one is which file they landed in. Most events drop straight down into '
                  'the file of their own day. One event that happened at 23:01 on 4 March slants '
                  'across midnight and lands in the file for 5 March.',
            top='event time: when it happened', bottom='processing time: the file it landed in',
            d4='4 March', d5='5 March', late='23:01, sent from a train',
            cap='Group by when it happened, not by where it landed, or a late event counts on the '
                'wrong day.'),
         'pt': dict(
            label='Duas linhas do tempo, uma acima da outra. A de cima é quando os eventos '
                  'aconteceram, a de baixo é em que arquivo eles caíram. A maioria dos eventos desce '
                  'reto para o arquivo do próprio dia. Um evento que aconteceu às 23:01 de 4 de '
                  'março cruza a meia-noite na diagonal e cai no arquivo de 5 de março.',
            top='horário do evento: quando aconteceu',
            bottom='horário de processamento: o arquivo onde caiu',
            d4='4 de março', d5='5 de março', late='23:01, mandado de um trem',
            cap='Agrupe por quando aconteceu, não por onde caiu, ou um evento atrasado conta no '
                'dia errado.')}[lang]
    f = Fig('l03-late', 720, 250, t['label'])
    x0, xm, x1 = 60, 380, 690
    for y, name in [(60, t['top']), (190, t['bottom'])]:
        f.line(x0, y, x1, y, stroke='--paper-dim', width=1.3)
        f.text(x0, y - 18 if y == 60 else y + 22, name, size=10.5, anchor='start',
               fill='--paper-dim')
    f.line(xm, 40, xm, 210, stroke='--wire', dash='4 4')
    f.text((x0 + xm) / 2, 125, t['d4'], size=11, weight='600')
    f.text((xm + x1) / 2, 125, t['d5'], size=11, weight='600')
    for x in [110, 170, 240, 300, 430, 500, 560, 630]:
        f.line(x, 66, x, 182, stroke='--phosphor-dim', width=1, arrow=True)
        f.circle(x, 60, 4, fill='--phosphor')
    f.circle(350, 60, 5, fill='--amber')
    f.line(350, 66, 455, 182, stroke='--amber', width=1.8, arrow=True)
    f.text(350, 34, t['late'], size=10, fill='--amber', anchor='middle')
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
