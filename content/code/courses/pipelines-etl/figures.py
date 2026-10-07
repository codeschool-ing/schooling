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


# ------------------------------------------------------------------ lesson 4

@figure('l04-watermark', 4)
def l04_watermark(lang):
    t = {'en': dict(
            label='Three nights on a line of updated_at times. On the first night the extraction '
                  'reads everything up to 23:50:30 on 1 March and the watermark is set there. On '
                  'the second it reads the 261 rows between that watermark and 23:59:47 on 2 '
                  'March, and the watermark moves to 23:59:47. On the third it reads the 301 rows '
                  'up to 23:51:38 on 3 March.',
            axis='updated_at of the shop\'s orders', nights=['night 1', 'night 2', 'night 3'],
            rows=['17,195 rows', '261 rows', '301 rows'], wm='watermark',
            ticks=['1 Mar 23:50:30', '2 Mar 23:59:47', '3 Mar 23:51:38'],
            cap='Each night reads the window between the last watermark and the newest row in its '
                'snapshot, and the watermark moves only when those rows have been loaded.'),
         'pt': dict(
            label='Três noites numa linha de horários updated_at. Na primeira noite a extração lê '
                  'tudo até 23:50:30 de 1º de março e a marca d\'água é posta ali. Na segunda ela '
                  'lê as 261 linhas entre essa marca e 23:59:47 de 2 de março, e a marca vai para '
                  '23:59:47. Na terceira ela lê as 301 linhas até 23:51:38 de 3 de março.',
            axis='updated_at dos pedidos da loja', nights=['noite 1', 'noite 2', 'noite 3'],
            rows=['17.195 linhas', '261 linhas', '301 linhas'], wm='marca d\'água',
            ticks=['1º mar 23:50:30', '2 mar 23:59:47', '3 mar 23:51:38'],
            cap='Cada noite lê a janela entre a última marca d\'água e a linha mais nova do seu '
                'snapshot, e a marca só anda quando essas linhas foram carregadas.')}[lang]
    f = Fig('l04-watermark', 720, 270, t['label'])
    xs = [90, 330, 490, 650]
    y = 210
    f.line(40, y, 690, y, stroke='--paper-dim', arrow=True)
    f.text(365, 250, t['axis'], size=10.5, fill='--paper-dim')
    for i in range(3):
        a, b = xs[i], xs[i + 1]
        yy = 40 + i * 50
        f.text(20, yy + 11, t['nights'][i], size=10.5, weight='600', anchor='start')
        f.rect(a, yy, b - a, 22, stroke='--phosphor', fill='--scan', rx=4)
        f.text((a + b) / 2, yy + 11, t['rows'][i], size=10)
        f.line(b, yy + 24, b, y - 4, stroke='--amber', dash='3 3')
        f.path(f'M{b - 5:.1f} {y - 12} L{b + 5:.1f} {y - 12} L{b:.1f} {y - 2} Z', stroke=None,
               fill='--amber')
        f.text(b, y + 16, t['ticks'][i], size=9.5, mono=True, fill='--paper-dim')
    f.text(xs[1] + 8, y - 20, t['wm'], size=10, fill='--amber', anchor='start')
    return f, t['cap']


@figure('l04-late', 4)
def l04_late(lang):
    t = {'en': dict(
            label='Order 900001 on a time line. Its updated_at is 23:40 on 2 March, but its '
                  'transaction commits after the night\'s extraction has read up to 23:59:47. The '
                  'next night reads only what is above 23:59:47, so the order falls in a gap '
                  'neither night reads. A lookback of sixty minutes starts the next window at '
                  '22:59:47 and covers it.',
            written='written: updated_at 23:40', committed='committed, after the extraction',
            wm='watermark 23:59:47', next='night 3 reads from here', look='with a 60-minute lookback',
            gap='read by neither night',
            cap='A row becomes visible when it commits, but carries the time it was written. '
                'Re-reading the end of the last window is what catches it.'),
         'pt': dict(
            label='O pedido 900001 numa linha do tempo. O updated_at dele é 23:40 de 2 de março, mas '
                  'a transação é confirmada depois de a extração da noite ter lido até 23:59:47. A '
                  'noite seguinte lê só o que está acima de 23:59:47, então o pedido cai num vão que '
                  'nenhuma noite lê. Um retrocesso de sessenta minutos começa a próxima janela em '
                  '22:59:47 e o cobre.',
            written='escrito: updated_at 23:40', committed='confirmado, depois da extração',
            wm='marca d\'água 23:59:47', next='a noite 3 lê a partir daqui',
            look='com retrocesso de 60 minutos', gap='lido por nenhuma noite',
            cap='Uma linha fica visível quando é confirmada, mas carrega o horário em que foi '
                'escrita. Reler o fim da última janela é o que a pega.')}[lang]
    f = Fig('l04-late', 720, 260, t['label'])
    y = 120
    f.line(30, y, 690, y, stroke='--paper-dim', arrow=True)
    wm, wr = 420, 280
    f.line(wm, 40, wm, 200, stroke='--amber', dash='4 3')
    f.text(wm, 30, t['wm'], size=10, fill='--amber', weight='600')
    f.circle(wr, y, 6, fill='--amber')
    f.text(wr - 10, y - 18, t['written'], size=10, anchor='end')
    f.path(f'M{wr + 6:.1f} {y - 8} C {wr + 80:.1f} {y - 70}, {wm + 60:.1f} {y - 70}, {wm + 106:.1f} {y - 9}',
           stroke='--paper-dim', dash='3 3', arrow=True)
    f.circle(wm + 110, y, 6, fill='--panel', stroke='--paper-dim', width=1.6)
    f.text(wm + 110, y + 20, t['committed'], size=10, fill='--paper-dim')
    f.rect(wm, 156, 220, 20, stroke='--phosphor', fill='--scan', rx=4)
    f.text(wm + 110, 166, t['next'], size=10)
    f.rect(wm - 160, 194, 380, 20, stroke='--phosphor', fill='--scan', rx=4, dash='4 3')
    f.text(wm + 30, 204, t['look'], size=10)
    f.text(wr, y + 20, t['gap'], size=10, fill='--amber')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 5

@figure('l05-two-views', 5)
def l05_two_views(lang):
    t = {'en': dict(
            label='One order during one day. At 10:00 it is inserted as completed; at 15:00 it is '
                  'updated to refunded. A watermark extraction at night reads the table once and '
                  'sees one row, refunded. Change data capture reads the log and sees two changes, '
                  'the insert and the update, in the order they committed.',
            day='one order, one day', ins='10:00 INSERT completed', upd='15:00 UPDATE refunded',
            night='night', wm='watermark: reads the table', wmsees='one row: refunded',
            cdc='change data capture: reads the log', cdcsees='two changes, in commit order',
            cap='A table holds the present. The log holds what happened, which is the only place '
                'the completed sale still exists.'),
         'pt': dict(
            label='Um pedido durante um dia. Às 10:00 ele é inserido como concluído; às 15:00 é '
                  'atualizado para estornado. Uma extração por marca d\'água à noite lê a tabela uma '
                  'vez e vê uma linha, estornada. A captura de mudanças lê o log e vê duas mudanças, '
                  'a inserção e a atualização, na ordem em que foram confirmadas.',
            day='um pedido, um dia', ins='10:00 INSERT concluído', upd='15:00 UPDATE estornado',
            night='noite', wm='marca d\'água: lê a tabela', wmsees='uma linha: estornado',
            cdc='captura de mudanças: lê o log', cdcsees='duas mudanças, em ordem de confirmação',
            cap='Uma tabela guarda o presente. O log guarda o que aconteceu, que é o único lugar onde '
                'a venda concluída ainda existe.')}[lang]
    f = Fig('l05-two-views', 720, 270, t['label'])
    y = 60
    f.text(40, 22, t['day'], size=11, weight='600', anchor='start')
    f.line(40, y, 680, y, stroke='--paper-dim', arrow=True)
    for x, lab in [(200, t['ins']), (420, t['upd'])]:
        f.circle(x, y, 6, fill='--phosphor')
        f.text(x, y + 20, lab, size=10, mono=True)
    f.line(620, y - 12, 620, y + 12, stroke='--amber', width=2)
    f.text(620, y - 22, t['night'], size=10, fill='--amber')
    f.rect(40, 130, 300, 100, stroke='--wire', fill='--panel')
    f.text(190, 152, t['wm'], size=11, weight='600')
    f.rect(80, 176, 220, 26, stroke='--amber', fill='--scan', rx=4)
    f.text(190, 189, t['wmsees'], size=10.5)
    f.rect(380, 130, 300, 100, stroke='--wire', fill='--panel')
    f.text(530, 152, t['cdc'], size=11, weight='600')
    f.rect(400, 170, 125, 24, stroke='--phosphor', fill='--scan', rx=4)
    f.text(462, 182, 'INSERT', size=10, mono=True)
    f.rect(535, 170, 125, 24, stroke='--phosphor', fill='--scan', rx=4)
    f.text(597, 182, 'UPDATE', size=10, mono=True)
    f.text(530, 214, t['cdcsees'], size=10, fill='--paper-dim')
    return f, t['cap']


@figure('l05-slots', 5)
def l05_slots(lang):
    t = {'en': dict(
            label='The write-ahead log drawn as a strip, oldest on the left. The slot wh_cdc sits '
                  'near the right-hand end, so almost nothing behind it is kept. The slot forgotten '
                  'sits at the left-hand end, where it was created, and every byte between it and '
                  'the end of the log is kept on the source\'s disk: 6085 kB after fourteen days.',
            wal='the write-ahead log, on the source\'s disk', old='older', new='now',
            kept='kept for forgotten: 6085 kB', kept2='176 bytes',
            cap='PostgreSQL keeps every byte a slot has not consumed. A slot nobody reads keeps all '
                'of them, until the disk is full.'),
         'pt': dict(
            label='O log de escrita antecipada desenhado como uma faixa, o mais antigo à esquerda. O '
                  'slot wh_cdc fica perto da ponta direita, então quase nada atrás dele é guardado. '
                  'O slot forgotten fica na ponta esquerda, onde foi criado, e cada byte entre ele e '
                  'o fim do log é guardado no disco da origem: 6085 kB depois de catorze dias.',
            wal='o log de escrita antecipada, no disco da origem', old='mais antigo', new='agora',
            kept='guardado para forgotten: 6085 kB', kept2='176 bytes',
            cap='O PostgreSQL guarda cada byte que um slot ainda não consumiu. Um slot que ninguém '
                'lê guarda todos, até o disco encher.')}[lang]
    f = Fig('l05-slots', 720, 230, t['label'])
    x0, x1, y = 60, 660, 100
    f.text(x0, 40, t['wal'], size=11, weight='600', anchor='start')
    n = 24
    for i in range(n):
        x = x0 + (x1 - x0) * i / n
        f.rect(x + 1, y, (x1 - x0) / n - 2, 30, stroke='--wire',
               fill='--scan' if i >= 2 else '--panel', rx=2)
    f.text(x0, y + 48, t['old'], size=10, fill='--paper-dim', anchor='start')
    f.text(x1, y + 48, t['new'], size=10, fill='--paper-dim', anchor='end')
    fx, wx = x0 + (x1 - x0) * 2 / n, x1 + 6
    for x, name, col in [(fx, 'forgotten', '--amber'), (wx, 'wh_cdc', '--phosphor')]:
        f.line(x, y - 18, x, y + 34, stroke=col, width=2)
        f.text(x, y - 26, name, size=10.5, mono=True, fill=col,
               anchor='middle' if x < 600 else 'end')
    f.path(f'M{fx:.1f} {y + 70} L{wx:.1f} {y + 70}', stroke='--amber', width=1.4, arrow=True)
    f.text((fx + wx) / 2, y + 88, t['kept'], size=10.5, fill='--amber', weight='600')
    f.text(wx, y + 106, t['kept2'] + ' (wh_cdc)', size=10, fill='--paper-dim', anchor='end', mono=True)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 6

@figure('l06-fanout', 6)
def l06_fanout(lang):
    t = {'en': dict(
            label='One order with three lines and one payment of R$ 159.70. Joined, the result has '
                  'three rows, each carrying the same payment, so a sum of the payment column says '
                  'R$ 479.10 for an order that was paid R$ 159.70.',
            order='order 1', lines='3 lines', pay='1 payment', joined='after the join',
            line='line', sum_='sum of the payment column', paid='what was paid',
            cap='The join goes down from the order to its lines, and everything at order grain is '
                'repeated once per line.'),
         'pt': dict(
            label='Um pedido com três linhas e um pagamento de R$ 159,70. Depois do join, o '
                  'resultado tem três linhas, cada uma levando o mesmo pagamento, então uma soma da '
                  'coluna de pagamento diz R$ 479,10 para um pedido que pagou R$ 159,70.',
            order='pedido 1', lines='3 linhas', pay='1 pagamento', joined='depois do join',
            line='linha', sum_='soma da coluna de pagamento', paid='o que foi pago',
            cap='O join desce do pedido para as suas linhas, e tudo o que está no grão do pedido '
                'se repete uma vez por linha.')}[lang]
    money = (lambda c: f"R$ {c / 100:,.2f}") if lang == 'en' else \
            (lambda c: "R$ " + f"{c / 100:,.2f}".replace(',', '_').replace('.', ',').replace('_', '.'))
    f = Fig('l06-fanout', 720, 260, t['label'])
    f.rect(40, 40, 170, 50, stroke='--wire', fill='--panel')
    f.text(125, 58, t['order'], size=11, weight='600')
    f.text(125, 76, t['pay'] + ': ' + money(15970), size=10, fill='--paper-dim')
    for i in range(3):
        y = 120 + i * 40
        f.rect(60, y, 130, 28, stroke='--wire', fill='--scan', rx=4)
        f.text(125, y + 14, f"{t['line']} {i + 1}", size=10)
    f.text(125, 112 - 4, t['lines'], size=10, fill='--paper-dim')
    f.text(470, 28, t['joined'], size=11, weight='600')
    for i in range(3):
        y = 50 + i * 40
        f.rect(330, y, 280, 28, stroke='--wire', fill='--panel', rx=4)
        f.text(345, y + 14, f"{t['line']} {i + 1}", size=10, anchor='start')
        f.text(595, y + 14, money(15970), size=10.5, anchor='end', mono=True, fill='--amber')
        f.line(192, 134 + i * 40, 328, y + 14, stroke='--paper-dim', width=1, arrow=True)
    f.text(330, 190, t['sum_'], size=10.5, anchor='start')
    f.text(610, 190, money(47910), size=11, anchor='end', mono=True, fill='--amber', weight='600')
    f.text(330, 214, t['paid'], size=10.5, anchor='start', fill='--paper-dim')
    f.text(610, 214, money(15970), size=11, anchor='end', mono=True)
    return f, t['cap']


@figure('l06-zones', 6)
def l06_zones(lang):
    t = {'en': dict(
            label='Two clocks over the same evening. On the São Paulo clock, Friday runs until '
                  'midnight. On the UTC clock, the day changes at 21:00 São Paulo time, so every '
                  'order between 21:00 and midnight is dated Saturday.',
            sp='São Paulo', utc='UTC', fri='Friday 6 March', sat='Saturday 7 March',
            orders='orders placed 21:00–24:00', moved='dated Saturday in UTC',
            cap='The same moment falls on two dates. Whose day it is has to be written into the '
                'derivation, once.'),
         'pt': dict(
            label='Dois relógios sobre a mesma noite. No relógio de São Paulo, a sexta-feira vai '
                  'até a meia-noite. No relógio UTC, o dia muda às 21:00 de São Paulo, então todo '
                  'pedido entre 21:00 e meia-noite fica com data de sábado.',
            sp='São Paulo', utc='UTC', fri='sexta, 6 de março', sat='sábado, 7 de março',
            orders='pedidos feitos entre 21:00 e 24:00', moved='com data de sábado em UTC',
            cap='O mesmo momento cai em duas datas. De quem é o dia precisa ser escrito na '
                'derivação, uma vez.')}[lang]
    f = Fig('l06-zones', 720, 230, t['label'])
    x0, x1 = 120, 680
    hx = lambda h: x0 + (x1 - x0) * (h - 12) / 16      # 12:00 to 04:00 next day, SP hours
    for row, (name, cut_h) in enumerate([(t['sp'], 24), (t['utc'], 21)]):
        y = 60 + row * 70
        f.text(x0 - 12, y + 12, name, size=11, weight='600', anchor='end')
        f.rect(x0, y, hx(cut_h) - x0, 24, stroke='--wire', fill='--panel', rx=3)
        f.rect(hx(cut_h), y, x1 - hx(cut_h), 24, stroke='--wire', fill='--scan', rx=3)
        f.text((x0 + hx(cut_h)) / 2, y + 12, t['fri'], size=10)
        f.text((hx(cut_h) + x1) / 2, y + 12, t['sat'], size=10)
    for xx in (hx(21), hx(24)):
        f.line(xx, 40, xx, 56, stroke='--amber', dash='4 3')
        f.line(xx, 88, xx, 126, stroke='--amber', dash='4 3')
        f.line(xx, 158, xx, 180, stroke='--amber', dash='4 3')
    f.text((hx(21) + hx(24)) / 2, 30, t['orders'], size=10, fill='--amber')
    f.text((hx(21) + hx(24)) / 2, 196, t['moved'], size=10, fill='--amber')
    for h in (12, 16, 20, 24, 28):
        f.text(hx(h), 216, f"{h % 24:02d}:00", size=9.5, fill='--paper-dim', mono=True)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 7

@figure('l07-scd2', 7)
def l07_scd2(lang):
    t = {'en': dict(
            label='Customer 3145 on a time line. Version 3133, São Paulo, is valid from 1 May 2025 '
                  'to 08:16:38 on 15 March 2026. Version 5393, Rio de Janeiro, is valid from that '
                  'moment with no end. A sale on 11 March points to version 3133, because the '
                  'sale happened while that version was true.',
            v1='key 3133 · São Paulo', v2='key 5393 · Rio de Janeiro', open_='still true',
            sale='sale, 11 March', moved='moved 15 March 08:16:38',
            start='1 May 2025',
            cap='The end of one version is the start of the next. A fact is joined to the version '
                'whose interval holds the moment of the sale.'),
         'pt': dict(
            label='O cliente 3145 numa linha do tempo. A versão 3133, São Paulo, vale de 1º de maio '
                  'de 2025 até 08:16:38 de 15 de março de 2026. A versão 5393, Rio de Janeiro, vale '
                  'a partir desse momento, sem fim. Uma venda em 11 de março aponta para a versão '
                  '3133, porque aconteceu enquanto essa versão era verdade.',
            v1='chave 3133 · São Paulo', v2='chave 5393 · Rio de Janeiro', open_='ainda vale',
            sale='venda, 11 de março', moved='mudou em 15 de março, 08:16:38',
            start='1º de maio de 2025',
            cap='O fim de uma versão é o começo da próxima. Um fato é ligado à versão cujo intervalo '
                'contém o momento da venda.')}[lang]
    f = Fig('l07-scd2', 720, 220, t['label'])
    x0, xm, x1, y = 40, 470, 690, 110
    f.line(x0, y + 50, x1, y + 50, stroke='--paper-dim', arrow=True)
    f.rect(x0, y, xm - x0, 30, stroke='--wire', fill='--panel', rx=4)
    f.text((x0 + xm) / 2, y + 15, t['v1'], size=10.5, weight='600')
    f.rect(xm, y, x1 - xm - 10, 30, stroke='--phosphor', fill='--scan', rx=4, dash='5 3')
    f.text((xm + x1 - 10) / 2, y + 15, t['v2'], size=10.5, weight='600')
    f.text(x1 - 12, y - 10, t['open_'], size=10, fill='--paper-dim', anchor='end')
    f.line(xm, y - 30, xm, y + 56, stroke='--amber', dash='4 3')
    f.text(xm, y - 38, t['moved'], size=10, fill='--amber')
    sx = xm - 70
    f.circle(sx, y + 50, 6, fill='--phosphor')
    f.text(sx, y + 72, t['sale'], size=10)
    f.line(sx, y + 44, sx, y + 32, stroke='--phosphor', width=1.4, arrow=True)
    f.text(x0, y + 72, t['start'], size=10, fill='--paper-dim', anchor='start')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 8

@figure('l08-components', 8)
def l08_components(lang):
    t = {'en': dict(
            label='Airflow\'s parts. The DAG folder is read by the DAG processor, which stores each '
                  'DAG in the metadata database. The scheduler reads the database, decides what is '
                  'due, and hands tasks to the executor, which runs them as processes. The '
                  'triggerer waits on behalf of waiting tasks. The API server serves the web '
                  'interface and the API, and also reads and writes the metadata database.',
            folder='DAG folder', files='~/etl/dags/*.py', proc='DAG processor', sched='scheduler',
            exe='executor', tasks='task processes', trig='triggerer', api='API server',
            ui='web interface and API', db='metadata database', dbname='PostgreSQL: airflow',
            cap='Four processes and a database. The files are only read; everything Airflow knows '
                'about runs and states is in the database.'),
         'pt': dict(
            label='As partes do Airflow. A pasta de DAGs é lida pelo processador de DAGs, que guarda '
                  'cada DAG no banco de metadados. O agendador lê o banco, decide o que está na hora '
                  'e entrega as tarefas ao executor, que as roda como processos. O triggerer espera '
                  'em nome das tarefas que esperam. O servidor da API serve a interface web e a API, '
                  'e também lê e escreve no banco de metadados.',
            folder='pasta de DAGs', files='~/etl/dags/*.py', proc='processador de DAGs',
            sched='agendador', exe='executor', tasks='processos das tarefas', trig='triggerer',
            api='servidor da API', ui='interface web e API', db='banco de metadados',
            dbname='PostgreSQL: airflow',
            cap='Quatro processos e um banco. Os arquivos são só lidos; tudo o que o Airflow sabe '
                'sobre execuções e estados está no banco.')}[lang]
    f = Fig('l08-components', 720, 300, t['label'])
    box(f, 20, 30, 150, 50, t['folder'], t['files'], mono_sub=True)
    box(f, 220, 30, 150, 50, t['proc'])
    box(f, 220, 130, 150, 50, t['sched'])
    box(f, 420, 130, 120, 50, t['exe'])
    box(f, 580, 130, 120, 50, t['tasks'])
    box(f, 220, 230, 150, 50, t['trig'])
    box(f, 410, 30, 120, 50, t['api'])
    box(f, 560, 30, 150, 50, t['ui'])
    f.rect(20, 120, 150, 70, stroke='--phosphor', fill='--scan', rx=8)
    f.text(95, 145, t['db'], size=11, weight='600')
    f.text(95, 166, t['dbname'], size=9.5, fill='--paper-dim', mono=True)
    f.line(170, 55, 218, 55, stroke='--phosphor', width=1.4, arrow=True)
    f.line(245, 82, 160, 118, stroke='--phosphor', width=1.4, arrow=True)
    f.line(218, 155, 172, 155, stroke='--paper-dim', width=1.4, arrow=True)
    f.line(370, 155, 418, 155, stroke='--phosphor', width=1.4, arrow=True)
    f.line(540, 155, 578, 155, stroke='--phosphor', width=1.4, arrow=True)
    f.line(218, 250, 150, 192, stroke='--paper-dim', width=1.2, arrow=True)
    f.line(530, 55, 558, 55, stroke='--phosphor', width=1.4, arrow=True)
    f.path('M410 70 C 330 110, 230 100, 172 130', stroke='--paper-dim', width=1.2, arrow=True)
    return f, t['cap']


@figure('l08-dag', 8)
def l08_dag(lang):
    t = {'en': dict(
            label='The six tasks of shop_nightly as a graph, left to right. extract leads to '
                  'transform, which leads to dim_customer and dim_book. day_to_load and '
                  'dim_customer both lead to fact_sales. dim_book leads nowhere further.',
            cap='Arrows are the only order. dim_book and dim_customer have none between them, so '
                'they may run at the same time; fact_sales waits for both of its arrows.'),
         'pt': dict(
            label='As seis tarefas do shop_nightly como grafo, da esquerda para a direita. extract '
                  'leva a transform, que leva a dim_customer e dim_book. day_to_load e dim_customer '
                  'levam ambos a fact_sales. dim_book não leva a mais nada.',
            cap='As setas são a única ordem. dim_book e dim_customer não têm nenhuma entre si, '
                'então podem rodar ao mesmo tempo; fact_sales espera as suas duas setas.')}[lang]
    f = Fig('l08-dag', 720, 220, t['label'])
    nodes = {'extract': (20, 40), 'transform': (180, 40), 'dim_customer': (360, 40),
             'dim_book': (360, 100), 'day_to_load': (360, 160), 'fact_sales': (560, 70)}
    w, h = 140, 40
    for name, (x, y) in nodes.items():
        f.rect(x, y, w, h, stroke='--phosphor' if name == 'fact_sales' else '--wire', fill='--panel')
        f.text(x + w / 2, y + h / 2, name, size=11, mono=True)
    def edge(a, b):
        (x0, y0), (x1, y1) = nodes[a], nodes[b]
        f.line(x0 + w, y0 + h / 2, x1 - 2, y1 + h / 2, stroke='--paper-dim', width=1.4, arrow=True)
    edge('extract', 'transform')
    edge('transform', 'dim_customer')
    f.path(f'M{180 + w} {60} C 340 60, 330 120, 358 120', stroke='--paper-dim', width=1.4, arrow=True)
    edge('dim_customer', 'fact_sales')
    edge('day_to_load', 'fact_sales')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 9

@figure('l09-two-schedules', 9)
def l09_two_schedules(lang):
    t = {'en': dict(
            label='Three days on a time line, 1 to 3 March. Above, the trigger schedule: a run at '
                  'each midnight, for that midnight, covering an instant. Below, the interval '
                  'schedule: a run at the end of each day, for that day, covering it from midnight '
                  'to midnight; its first run happens at midnight on 2 March and is for 1 March.',
            trig='cron string: a trigger', intv='CronDataIntervalTimetable: an interval',
            runs_at='runs at', is_for='is for', d=['1 March', '2 March', '3 March', '4 March'],
            cap='The same three days. One schedule runs at each midnight for that instant; the '
                'other runs when each day is over, for the whole day.'),
         'pt': dict(
            label='Três dias numa linha do tempo, de 1º a 3 de março. Em cima, o agendamento por '
                  'gatilho: uma execução a cada meia-noite, para aquela meia-noite, cobrindo um '
                  'instante. Embaixo, o agendamento por intervalo: uma execução no fim de cada dia, '
                  'para aquele dia, cobrindo-o de meia-noite a meia-noite; a primeira execução '
                  'acontece à meia-noite de 2 de março e é para 1º de março.',
            trig='string cron: um gatilho', intv='CronDataIntervalTimetable: um intervalo',
            runs_at='roda em', is_for='é para', d=['1º de março', '2 de março', '3 de março',
                                                   '4 de março'],
            cap='Os mesmos três dias. Um agendamento roda a cada meia-noite para aquele instante; o '
                'outro roda quando cada dia acaba, para o dia inteiro.')}[lang]
    f = Fig('l09-two-schedules', 720, 270, t['label'])
    xs = [80 + i * 190 for i in range(4)]
    y = 240
    f.line(40, y, 700, y, stroke='--paper-dim', arrow=True)
    for x, dname in zip(xs, t['d']):
        f.line(x, y - 5, x, y + 5, stroke='--paper-dim')
        f.text(x, y + 18, dname, size=10, fill='--paper-dim')
    f.text(40, 30, t['trig'], size=11, weight='600', anchor='start')
    for x in xs[:3]:
        f.circle(x, 60, 6, fill='--phosphor')
        f.line(x, 68, x, 100, stroke='--phosphor-dim', dash='2 3')
    f.text(40, 120, t['intv'], size=11, weight='600', anchor='start')
    for i in range(3):
        a, b = xs[i], xs[i + 1]
        f.rect(a + 2, 140, b - a - 4, 22, stroke='--amber', fill='--scan', rx=4)
        f.text((a + b) / 2, 151, t['is_for'] + ' ' + t['d'][i], size=10)
        f.circle(b, 186, 5, fill='--amber')
        f.text(b, 204, t['runs_at'] + ' ' + t['d'][i + 1], size=9.5, fill='--paper-dim')
    return f, t['cap']

@figure('l10-failures', 10)
def l10_failures(lang):
    t = {'en': dict(
            label='Three kinds of failure and what each asks for. A passing failure, such as a 503, '
                  'a 429 or a timeout, is retried later and alerts nobody unless the tries run out. '
                  'A permanent one, such as a 401, a 400 or a file in the wrong shape, fails at '
                  'once and alerts. A failure in the code itself, such as an import error, stops '
                  'the DAG from being scheduled at all and is fixed by changing the code.',
            head=['the failure', 'for example', 'what Airflow should do'],
            rows=[('passing', '503 · 429 · timeout', 'try again, later each time'),
                  ('permanent', '401 · 400 · a bad file', 'fail now, and say so'),
                  ('in the code', 'an import error', 'nothing runs: fix the code')],
            cap='Asking again only helps when the cause can go away by itself.'),
         'pt': dict(
            label='Três tipos de falha e o que cada um pede. Uma falha passageira, como um 503, um '
                  '429 ou um timeout, é tentada de novo mais tarde e não alerta ninguém, a menos '
                  'que as tentativas acabem. Uma permanente, como um 401, um 400 ou um arquivo no '
                  'formato errado, falha na hora e alerta. Uma falha no próprio código, como um '
                  'erro de importação, impede o DAG de ser agendado e se resolve mudando o código.',
            head=['a falha', 'por exemplo', 'o que o Airflow deve fazer'],
            rows=[('passageira', '503 · 429 · timeout', 'tentar de novo, cada vez mais tarde'),
                  ('permanente', '401 · 400 · um arquivo ruim', 'falhar agora, e avisar'),
                  ('no código', 'um erro de importação', 'nada roda: corrigir o código')],
            cap='Pedir de novo só ajuda quando a causa pode sumir sozinha.')}[lang]
    f = Fig('l10-failures', 720, 230, t['label'])
    cols = [30, 200, 410]
    for x, h in zip(cols, t['head']):
        f.text(x, 28, h, size=10.5, anchor='start', fill='--paper-dim', weight='600')
    f.line(30, 44, 690, 44, stroke='--wire')
    tones = ['--phosphor', '--amber', '--amber']
    for i, ((kind, eg, todo), tone) in enumerate(zip(t['rows'], tones)):
        y = 78 + i * 52
        f.rect(30, y - 17, 150, 34, stroke=tone, fill='--scan')
        f.text(105, y, kind, size=11.5, weight='600')
        f.text(cols[1], y, eg, size=10.5, anchor='start')
        f.text(cols[2], y, todo, size=11, anchor='start')
    return f, t['cap']


@figure('l10-night', 10)
def l10_night(lang):
    t = {'en': dict(
            label='The run for 03:00 on 10 March on a time line of a few minutes. Five tries, each '
                  'a failure, with the waits between them growing: about fifteen seconds, then '
                  'thirty, sixty and a hundred and twenty. Two minutes after the run was queued '
                  'the deadline passes and a LATE line is written while the run is still trying. '
                  'After the fifth try the task has failed for good and a FAILED line is written.',
            tries='tries', wait='waits', dl='deadline: 2 min after queued',
            late='LATE', failed='FAILED', queued='queued', mins='min',
            cap='The deadline speaks while the run is still trying; the failure callback only '
                'when the trying is over.'),
         'pt': dict(
            label='A execução das 03:00 de 10 de março numa linha do tempo de alguns minutos. Cinco '
                  'tentativas, todas falhas, com as esperas entre elas crescendo: uns quinze '
                  'segundos, depois trinta, sessenta e cento e vinte. Dois minutos depois de a '
                  'execução entrar na fila, o prazo passa e uma linha LATE é escrita enquanto a '
                  'execução ainda tenta. Depois da quinta tentativa a tarefa falhou de vez e uma '
                  'linha FAILED é escrita.',
            tries='tentativas', wait='esperas', dl='prazo: 2 min depois da fila',
            late='LATE', failed='FAILED', queued='na fila', mins='min',
            cap='O prazo fala enquanto a execução ainda tenta; o callback de falha só quando as '
                'tentativas acabaram.')}[lang]
    f = Fig('l10-night', 720, 250, t['label'])
    x0, x1, tmax = 90, 680, 330.0
    sx = lambda s: x0 + s / tmax * (x1 - x0)
    y = 200
    f.line(x0, y, x1 + 10, y, stroke='--paper-dim', arrow=True)
    for m in range(0, 6):
        x = sx(m * 60)
        f.line(x, y - 4, x, y + 4, stroke='--paper-dim')
        f.text(x, y + 18, f'{m} {t["mins"]}', size=9.5, fill='--paper-dim')
    starts, waits = [4], [22, 45, 90, 150]
    for w in waits:
        starts.append(starts[-1] + 3 + w)
    f.text(x0 - 10, 110, t['tries'], size=10, anchor='end', fill='--paper-dim')
    f.text(x0 - 10, 150, t['wait'], size=10, anchor='end', fill='--paper-dim')
    for i, s in enumerate(starts):
        f.circle(sx(s), 110, 6, fill='--amber')
        f.text(sx(s), 92, str(i + 1), size=10, weight='600')
        if i < len(waits):
            a, b = sx(s) + 8, sx(starts[i + 1]) - 8
            f.line(a, 150, b, 150, stroke='--phosphor-dim')
            f.text(a + (b - a) * (0.75 if i == 2 else 0.5), 164, ['15', '30', '60', '120'][i] + ' s', size=9.5,
                   fill='--paper-dim')
    xd = sx(120)
    f.line(xd, 40, xd, y, stroke='--phosphor', dash='4 3')
    f.text(xd + 6, 30, t['dl'], size=10, anchor='start')
    f.text(xd + 6, 56, t['late'], size=10.5, anchor='start', weight='600', mono=True,
           fill='--phosphor')
    f.text(sx(starts[-1]), 66, t['failed'], size=10.5, weight='600', mono=True, fill='--amber')
    return f, t['cap']

@figure('l11-graph', 11)
def l11_graph(lang):
    t = {'en': dict(
            label='The graph dbt builds from the shop project. Three sources in the raw schema '
                  'feed three staging views: orders, order lines and books. Orders and order '
                  'lines feed int_sales, an ephemeral model drawn dashed because it is never '
                  'built. int_sales feeds the two marts, daily_sales, which also reads the books, '
                  'and fact_sales.',
            src='source', view='view', eph='ephemeral', table='table', inc='incremental',
            cap='Nobody wrote these arrows. Each one is a ref() or a source() inside a model.'),
         'pt': dict(
            label='O grafo que o dbt monta a partir do projeto shop. Três fontes no schema raw '
                  'alimentam três views de staging: pedidos, linhas de pedido e livros. Pedidos e '
                  'linhas de pedido alimentam o int_sales, um modelo efêmero desenhado tracejado '
                  'porque nunca é construído. O int_sales alimenta os dois marts, o daily_sales, '
                  'que também lê os livros, e o fact_sales.',
            src='fonte', view='view', eph='efêmero', table='tabela', inc='incremental',
            cap='Ninguém escreveu estas setas. Cada uma é um ref() ou um source() dentro de um '
                'modelo.')}[lang]
    f = Fig('l11-graph', 720, 270, t['label'])
    W, H = 132, 44
    cols = [20, 192, 364, 560]
    rows = [30, 110, 190]
    def node(x, y, name, kind, stroke='--wire', dash=None):
        f.rect(x, y, W, H, stroke=stroke, fill='--panel', dash=dash)
        f.text(x + W / 2, y + 16, name, size=10.5, mono=True)
        f.text(x + W / 2, y + 32, kind, size=9.5, fill='--paper-dim')
    names = ['orders', 'order_lines', 'books']
    for r, n in zip(rows, names):
        node(cols[0], r, 'raw.' + n, t['src'])
        node(cols[1], r, 'stg_' + n, t['view'])
        f.line(cols[0] + W, r + H / 2, cols[1] - 2, r + H / 2, arrow=True)
    yi = 70
    node(cols[2], yi, 'int_sales', t['eph'], stroke='--paper-dim', dash='4 3')
    for r in rows[:2]:
        f.line(cols[1] + W, r + H / 2, cols[2] - 2, yi + H / 2, arrow=True)
    yd, yf = 150, 40
    node(cols[3], yd, 'daily_sales', t['table'], stroke='--amber')
    node(cols[3], yf, 'fact_sales', t['inc'], stroke='--phosphor')
    f.line(cols[2] + W, yi + H / 2, cols[3] - 2, yf + H / 2, arrow=True)
    f.line(cols[2] + W, yi + H / 2, cols[3] - 2, yd + H / 2 - 6, arrow=True)
    f.line(cols[1] + W, rows[2] + H / 2, cols[3] - 2, yd + H / 2 + 8, arrow=True)
    return f, t['cap']


@figure('l11-materialisations', 11)
def l11_materialisations(lang):
    t = {'en': dict(
            label='The four materialisations side by side. A view is stored as a query and run '
                  'whenever it is read. A table is rebuilt whole on every dbt run. Ephemeral '
                  'leaves nothing in the database and is pasted into the models that use it. '
                  'Incremental is built whole once and then only has new rows added on each run.',
            head=['materialized=', 'in the database', 'on each dbt run'],
            rows=[('view', 'a stored query', 'redefined; read runs the query'),
                  ('table', 'rows', 'rebuilt whole'),
                  ('ephemeral', 'nothing', 'pasted into its users as a CTE'),
                  ('incremental', 'rows', 'only the new rows, after the first run')],
            cap='Where the work happens: when the model is read, when dbt runs, or not at all.'),
         'pt': dict(
            label='As quatro materializações lado a lado. Uma view é guardada como consulta e roda '
                  'sempre que é lida. Uma tabela é refeita inteira a cada dbt run. Efêmero não '
                  'deixa nada no banco e é colado nos modelos que o usam. Incremental é construído '
                  'inteiro uma vez e depois só recebe linhas novas a cada execução.',
            head=['materialized=', 'no banco', 'a cada dbt run'],
            rows=[('view', 'uma consulta guardada', 'redefinida; ler roda a consulta'),
                  ('table', 'linhas', 'refeita inteira'),
                  ('ephemeral', 'nada', 'colado em quem o usa, como CTE'),
                  ('incremental', 'linhas', 'só as linhas novas, depois da primeira')],
            cap='Onde o trabalho acontece: quando o modelo é lido, quando o dbt roda, ou em lugar '
                'nenhum.')}[lang]
    f = Fig('l11-materialisations', 720, 250, t['label'])
    cols = [30, 200, 400]
    f.text(cols[0], 28, t['head'][0], size=10.5, anchor='start', fill='--paper-dim', weight='600',
           mono=True)
    for x, h in zip(cols[1:], t['head'][1:]):
        f.text(x, 28, h, size=10.5, anchor='start', fill='--paper-dim', weight='600')
    f.line(30, 44, 690, 44, stroke='--wire')
    for i, (m, db, run) in enumerate(t['rows']):
        y = 72 + i * 46
        f.rect(30, y - 16, 140, 32, stroke='--phosphor' if m == 'incremental' else '--wire',
               fill='--scan')
        f.text(100, y, m, size=11, mono=True, weight='600')
        f.text(cols[1], y, db, size=11, anchor='start')
        f.text(cols[2], y, run, size=11, anchor='start')
    return f, t['cap']

@figure('l12-two-answers', 12)
def l12_two_answers(lang):
    t = {'en': dict(
            label='A failed test leads to one question: is the rule wrong or the data? If the rule '
                  'is wrong, correct the test so that it says what is actually true, and keep it. '
                  'If the data is wrong, keep the test as it is and fix the data where it comes '
                  'from. Deleting the test is drawn crossed out, as the move that is never right.',
            fail='a test fails', q='the rule or the data?', rule='the rule is wrong',
            data='the data is wrong', fix_rule='narrow the test until it is true',
            fix_data='fix it upstream; the test stays', never='delete the test',
            cap='Both answers keep a test. The only wrong move is the one that keeps none.'),
         'pt': dict(
            label='Um teste que falha leva a uma pergunta: a regra está errada, ou os dados? Se a '
                  'regra está errada, corrija o teste para ele dizer o que é de fato verdade, e '
                  'mantenha-o. Se os dados estão errados, mantenha o teste como está e corrija os '
                  'dados de onde eles vêm. Apagar o teste aparece riscado, como o movimento que '
                  'nunca está certo.',
            fail='um teste falha', q='a regra ou os dados?', rule='a regra está errada',
            data='os dados estão errados', fix_rule='estreitar o teste até ele ser verdade',
            fix_data='corrigir na origem; o teste fica', never='apagar o teste',
            cap='As duas respostas mantêm um teste. O único movimento errado é o que não mantém '
                'nenhum.')}[lang]
    f = Fig('l12-two-answers', 720, 260, t['label'])
    box(f, 270, 16, 180, 40, t['fail'], stroke='--amber')
    box(f, 270, 86, 180, 40, t['q'])
    f.line(360, 56, 360, 84, arrow=True)
    box(f, 40, 150, 230, 40, t['rule'])
    box(f, 450, 150, 230, 40, t['data'])
    f.line(300, 126, 200, 148, arrow=True)
    f.line(420, 126, 520, 148, arrow=True)
    f.text(155, 214, t['fix_rule'], size=11)
    f.text(565, 214, t['fix_data'], size=11)
    f.line(155, 190, 155, 202)
    f.line(565, 190, 565, 202)
    f.text(360, 244, t['never'], size=11, fill='--paper-dim')
    f.line(300, 244, 420, 244, stroke='--amber', width=1.5)
    return f, t['cap']


@figure('l12-build', 12)
def l12_build(lang):
    t = {'en': dict(
            label='dbt build in graph order. stg_orders is built and then tested; its customer test '
                  'fails. Everything downstream of it is skipped: int_sales, and so daily_sales and '
                  'fact_sales, which keep the rows they had. stg_books, which does not depend on '
                  'stg_orders, is built and tested as usual.',
            built='built', tested='tested', failed='test failed', skipped='skipped',
            kept='kept yesterday\'s rows',
            cap='A failed test stops what reads the model, and nothing else.'),
         'pt': dict(
            label='O dbt build na ordem do grafo. O stg_orders é construído e depois testado; o '
                  'teste de cliente dele falha. Tudo abaixo dele é pulado: o int_sales, e portanto '
                  'o daily_sales e o fact_sales, que ficam com as linhas que tinham. O stg_books, '
                  'que não depende do stg_orders, é construído e testado normalmente.',
            built='construído', tested='testado', failed='teste falhou', skipped='pulado',
            kept='ficaram com as linhas de ontem',
            cap='Um teste que falha para o que lê o modelo, e mais nada.')}[lang]
    f = Fig('l12-build', 720, 210, t['label'])
    W, H = 140, 44
    def node(x, y, name, sub, stroke, dash=None):
        f.rect(x, y, W, H, stroke=stroke, fill='--panel', dash=dash)
        f.text(x + W / 2, y + 16, name, size=10.5, mono=True)
        f.text(x + W / 2, y + 32, sub, size=9.5, fill='--paper-dim')
    node(30, 40, 'stg_orders', t['failed'], '--amber')
    node(30, 150, 'stg_books', t['built'] + ' · ' + t['tested'], '--phosphor')
    node(270, 40, 'int_sales', t['skipped'], '--wire', dash='4 3')
    node(510, 20, 'fact_sales', t['skipped'], '--wire', dash='4 3')
    node(510, 110, 'daily_sales', t['skipped'], '--wire', dash='4 3')
    f.line(30 + W, 62, 268, 62, arrow=True)
    f.line(270 + W, 56, 508, 42, arrow=True)
    f.line(270 + W, 70, 508, 128, arrow=True)
    f.line(30 + W, 172, 508, 140, arrow=True)
    f.text(580, 182, t['kept'], size=10, fill='--paper-dim')
    return f, t['cap']


@figure('l12-lineage', 12)
def l12_lineage(lang):
    t = {'en': dict(
            label='Lineage from a source to a report. raw.orders feeds stg_orders, which feeds '
                  'int_sales, which feeds daily_sales and fact_sales; daily_sales feeds the morning '
                  'report, an exposure owned by Ana. Reading leftwards answers where a number came '
                  'from; reading rightwards answers what a change will reach.',
            up='where did this number come from?', down='what will this change reach?',
            exp='exposure · Ana',
            cap='One graph, read in two directions for two questions.'),
         'pt': dict(
            label='A linhagem de uma fonte até um relatório. O raw.orders alimenta o stg_orders, '
                  'que alimenta o int_sales, que alimenta o daily_sales e o fact_sales; o '
                  'daily_sales alimenta o relatório da manhã, uma exposure da Ana. Ler para a '
                  'esquerda responde de onde um número veio; ler para a direita responde o que uma '
                  'mudança vai alcançar.',
            up='de onde veio este número?', down='o que esta mudança vai alcançar?',
            exp='exposure · Ana',
            cap='Um grafo, lido em duas direções para duas perguntas.')}[lang]
    f = Fig('l12-lineage', 720, 230, t['label'])
    W, H = 112, 40
    xs = [14, 154, 294, 434, 580]
    y = 100
    names = ['raw.orders', 'stg_orders', 'int_sales', 'daily_sales', 'morning_report']
    for i, (x, n) in enumerate(zip(xs, names)):
        stroke = '--phosphor' if i == 4 else '--wire'
        w = 126 if i == 4 else W
        f.rect(x, y, w, H, stroke=stroke, fill='--panel')
        f.text(x + w / 2, y + H / 2, n, size=10.5, mono=True)
        if i < 4:
            f.line(x + W, y + H / 2, xs[i + 1] - 2, y + H / 2, arrow=True)
    f.text(643, y + H + 16, t['exp'], size=9.5, fill='--paper-dim')
    f.rect(434, 180, W, H - 8, stroke='--wire', fill='--panel')
    f.text(434 + W / 2, 196, 'fact_sales', size=10.5, mono=True)
    f.path(f'M{294 + W} {y + H - 6} C 420 {y + H + 10}, 400 196, 432 196', arrow=True)
    f.line(690, 40, 30, 40, stroke='--amber', arrow=True)
    f.text(360, 26, t['up'], size=11)
    f.line(30, 70, 690, 70, stroke='--phosphor', arrow=True)
    f.text(360, 84, t['down'], size=11)
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
