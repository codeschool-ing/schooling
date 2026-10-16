#!/usr/bin/env python3
"""Every diagram in the bigdata course.

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


def box(f, x, y, w, h, title, sub=None, stroke='--wire', fill='--panel', mono_sub=False, size=11.5,
        mono=False):
    f.rect(x, y, w, h, stroke=stroke, fill=fill)
    if sub:
        f.text(x + w / 2, y + h / 2 - 8, title, size=size, weight='600', mono=mono)
        f.text(x + w / 2, y + h / 2 + 9, sub, size=10, fill='--paper-dim', mono=mono_sub)
    else:
        f.text(x + w / 2, y + h / 2, title, size=size, weight='600', mono=mono)


# FIGURES


# ------------------------------------------------------------------ lesson 1

@figure('l01-buckets', 1)
def l01_buckets(lang):
    t = {'en': dict(
            label='Two passes over the clicks. On the left, 365 daily files of events. Pass one '
                  'reads them once and sends each book and visitor pair to one of sixteen bucket '
                  'files, chosen by a hash of the visitor. Fifteen buckets are about 17 MB; bucket '
                  '09, which holds the crawler, is 28 MB. Pass two reads one bucket at a time, '
                  'counts the different visitors of each book in it, and adds the counts into one '
                  'total per book.',
            src='365 daily files', src2='24 million events',
            p1='pass 1: by visitor', p2='pass 2: one at a time',
            big='the crawler', out='visitors per book', out2='the counts add up',
            cap='Pass one decides where every pair goes; pass two never holds more than one '
                'bucket. The same visitor always lands in the same bucket, which is what lets '
                'the counts add up.'),
         'pt': dict(
            label='Duas passadas sobre os cliques. À esquerda, 365 arquivos diários de eventos. A '
                  'primeira passada os lê uma vez e manda cada par de livro e visitante para um de '
                  'dezesseis arquivos, escolhido por um hash do visitante. Quinze arquivos têm cerca '
                  'de 17 MB; o 09, que guarda o robô, tem 28 MB. A segunda passada lê um arquivo '
                  'por vez, conta os visitantes diferentes de cada livro nele e soma as contagens '
                  'num total por livro.',
            src='365 arquivos diários', src2='24 milhões de eventos',
            p1='passada 1: por visitante', p2='passada 2: um por vez',
            big='o robô', out='visitantes por livro', out2='as contagens se somam',
            cap='A primeira passada decide para onde vai cada par; a segunda nunca segura mais de '
                'um arquivo. O mesmo visitante sempre cai no mesmo arquivo, e é isso que deixa as '
                'contagens se somarem.')}[lang]
    f = Fig('l01-buckets', 720, 300, t['label'])
    box(f, 16, 115, 150, 60, t['src'], t['src2'])
    names = ['00', '01', '02', '…', '09', '…', '15']
    y = 30
    for n in names:
        h = 44 if n == '09' else 26
        if n == '…':
            f.text(330, y + 10, '· · ·', size=12, fill='--paper-dim')
            y += 26
            continue
        f.rect(290, y, 80, h, stroke='--amber' if n == '09' else '--wire')
        f.text(330, y + h / 2, n + '.csv', size=10.5, mono=True)
        f.line(166, 145, 288, y + h / 2, stroke='--paper-dim', width=1, arrow=True)
        f.line(370, y + h / 2, 470, 145, stroke='--paper-dim', width=1, arrow=True)
        if n == '09':
            f.text(380, y + h + 4, t['big'], size=10, anchor='start', fill='--amber')
        y += h + 8
    f.text(228, 20, t['p1'], size=10.5, weight='600')
    f.text(420, 20, t['p2'], size=10.5, weight='600')
    box(f, 472, 115, 220, 60, t['out'], t['out2'], stroke='--phosphor')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 2

@figure('l02-roles', 2)
def l02_roles(lang):
    t = {'en': dict(
            label='The four roles. The driver, your program, asks the cluster manager for '
                  'resources. The manager tells its workers to start executors for the '
                  'application. From then on the driver sends tasks straight to its executors and '
                  'they send results back; the manager is out of the conversation.',
            drv='driver', drv2='your program', mgr='cluster manager', mgr2='the master, here',
            wk='worker', ex='executor', ask='1. asks for cores', start='2. start executors',
            tasks='3. tasks and results, directly',
            cap='The master rents out cores and steps aside; the driver and its executors do the '
                'talking from then on.'),
         'pt': dict(
            label='Os quatro papéis. O driver, o seu programa, pede recursos ao gerenciador do '
                  'cluster. O gerenciador manda os workers iniciarem executores para a aplicação. '
                  'Dali em diante o driver envia tarefas direto aos executores e eles devolvem '
                  'resultados; o gerenciador sai da conversa.',
            drv='driver', drv2='o seu programa', mgr='gerenciador do cluster', mgr2='aqui, o master',
            wk='worker', ex='executor', ask='1. pede núcleos', start='2. iniciem executores',
            tasks='3. tarefas e resultados, direto',
            cap='O master aluga núcleos e sai de cena; dali em diante quem conversa são o driver e '
                'os seus executores.')}[lang]
    f = Fig('l02-roles', 720, 340, t['label'])
    box(f, 20, 40, 170, 56, t['drv'], t['drv2'], stroke='--phosphor')
    box(f, 280, 40, 190, 56, t['mgr'], t['mgr2'])
    f.line(190, 68, 278, 68, arrow=True)
    f.text(234, 58, t['ask'], size=9.5, fill='--paper-dim')
    xs = [250, 400, 550]
    for x in xs:
        f.rect(x - 60, 170, 120, 130, stroke='--wire', fill='--ink', dash='4 3')
        f.text(x, 186, t['wk'], size=10.5, fill='--paper-dim')
        box(f, x - 48, 210, 96, 40, t['ex'])
        f.line(375, 96, x, 168, arrow=True)
    f.text(560, 130, t['start'], size=9.5, fill='--paper-dim', anchor='start')
    f.path('M105 96 L105 322 L550 322', stroke='--amber', width=1.4)
    for x in xs:
        f.line(x, 322, x, 253, stroke='--amber', width=1.4, arrow=True)
    f.text(115, 312, t['tasks'], size=9.5, fill='--amber', anchor='start')
    return f, t['cap']


@figure('l02-waves', 2)
def l02_waves(lang):
    t = {'en': dict(
            label='Three cores against time. Thirty tasks of two seconds fill ten waves of three '
                  'and end at twenty seconds. A thirty-first task needs an eleventh wave in which '
                  'one core works and two sit idle, and the job ends at twenty-two seconds.',
            core='core', secs='seconds', extra='task 31', idle='idle',
            cap='Thirty-one tasks on three cores: the last wave holds one task and two idle cores, '
                'and costs a whole wave of time.'),
         'pt': dict(
            label='Três núcleos ao longo do tempo. Trinta tarefas de dois segundos enchem dez '
                  'ondas de três e terminam em vinte segundos. Uma trigésima primeira tarefa '
                  'precisa de uma décima primeira onda, em que um núcleo trabalha e dois ficam '
                  'parados, e o job termina em vinte e dois segundos.',
            core='núcleo', secs='segundos', extra='tarefa 31', idle='parado',
            cap='Trinta e uma tarefas em três núcleos: a última onda tem uma tarefa e dois '
                'núcleos parados, e custa uma onda inteira de tempo.')}[lang]
    f = Fig('l02-waves', 720, 210, t['label'])
    x0, w = 80, 26
    for c in range(3):
        y = 30 + c * 40
        f.text(x0 - 10, y + 14, f"{t['core']} {c + 1}", size=10, anchor='end', fill='--paper-dim')
        for i in range(10):
            f.rect(x0 + i * 2 * w + 1, y, 2 * w - 2, 28, stroke='--phosphor', fill='--scan', rx=2)
        if c == 0:
            f.rect(x0 + 20 * w + 1, y, 2 * w - 2, 28, stroke='--amber', fill='--panel', rx=2)
            f.text(x0 + 21 * w, y + 14, t['extra'], size=9, fill='--amber')
        else:
            f.rect(x0 + 20 * w + 1, y, 2 * w - 2, 28, stroke='--wire', fill='--ink', rx=2, dash='3 3')
            f.text(x0 + 21 * w, y + 14, t['idle'], size=9, fill='--paper-dim')
    y = 160
    f.line(x0, y, x0 + 22 * w + 10, y, stroke='--paper-dim')
    for s in range(0, 23, 2):
        f.line(x0 + s * w, y, x0 + s * w, y + 4, stroke='--paper-dim')
        f.text(x0 + s * w, y + 14, str(s), size=9.5, fill='--paper-dim', mono=True)
    f.text(x0 + 11 * w, y + 34, t['secs'], size=10, weight='600')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 3

@figure('l03-blocks', 3)
def l03_blocks(lang):
    t = {'en': dict(
            label='A file cut into blocks of 128 MB, numbered 0 to 3 here. The namenode holds '
                  'only the list of blocks and where each copy is. Four datanodes hold the copies: '
                  'every block is on three of them, never twice on the same one, and each datanode '
                  'holds some blocks and not others.',
            file='one file', nn='namenode', nn2='file → blocks → datanodes', dn='datanode',
            blk='block', cap='Every block is stored three times, on three different datanodes. '
                             'The namenode knows where; it never holds the data.'),
         'pt': dict(
            label='Um arquivo cortado em blocos de 128 MB, numerados aqui de 0 a 3. O namenode '
                  'guarda só a lista de blocos e onde está cada cópia. Quatro datanodes guardam as '
                  'cópias: cada bloco está em três deles, nunca duas vezes no mesmo, e cada '
                  'datanode guarda alguns blocos e outros não.',
            file='um arquivo', nn='namenode', nn2='arquivo → blocos → datanodes', dn='datanode',
            blk='bloco', cap='Cada bloco é guardado três vezes, em três datanodes diferentes. O '
                             'namenode sabe onde; ele nunca guarda os dados.')}[lang]
    f = Fig('l03-blocks', 720, 300, t['label'])
    f.text(20, 30, t['file'], size=10.5, anchor='start', weight='600')
    for i in range(4):
        f.rect(100 + i * 70, 16, 66, 28, stroke='--phosphor', fill='--scan', rx=2)
        f.text(133 + i * 70, 30, f"{t['blk']} {i}", size=10)
    box(f, 440, 12, 260, 56, t['nn'], t['nn2'])
    place = {1: [0, 1], 2: [0, 1, 2, 3], 3: [1, 2, 3], 4: [0, 2, 3]}
    for n in range(1, 5):
        x = 20 + (n - 1) * 175
        f.rect(x, 130, 160, 140, stroke='--wire', fill='--panel')
        f.text(x + 80, 148, f"{t['dn']} {n}", size=10.5, weight='600')
        for j, b in enumerate(place[n]):
            f.rect(x + 14 + (j % 2) * 70, 166 + (j // 2) * 44, 62, 34, stroke='--phosphor',
                   fill='--scan', rx=2)
            f.text(x + 45 + (j % 2) * 70, 183 + (j // 2) * 44, f"{t['blk']} {b}", size=10)
        f.line(570, 68, x + 80, 128, stroke='--paper-dim', dash='3 3', width=1)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 4

@figure('l04-mapreduce', 4)
def l04_mapreduce(lang):
    t = {'en': dict(
            label='The flow of a MapReduce job. Three input splits feed three map tasks. Each map '
                  'task writes its pairs into two partitions, one per reduce task, chosen by the '
                  'key. Every reduce task fetches its partition from every map task, sorts what it '
                  'received by key, and runs the reduce function on each key.',
            split='split', mapt='map', red='reduce', shuffle='shuffle: partition by key, then sort',
            out='output', cap='The programmer writes the two functions; the framework splits, '
                              'partitions, moves, sorts and reruns.'),
         'pt': dict(
            label='O fluxo de um job MapReduce. Três fatias da entrada alimentam três tarefas de map. '
                  'Cada tarefa de map escreve os pares em duas partições, uma por tarefa de reduce, '
                  'escolhidas pela chave. Cada tarefa de reduce busca a sua partição em toda tarefa '
                  'de map, ordena o que recebeu pela chave e roda a função de reduce em cada chave.',
            split='fatia', mapt='map', red='reduce', shuffle='shuffle: partição por chave, depois ordenação',
            out='saída', cap='Quem programa escreve as duas funções; o framework divide, particiona, '
                             'move, ordena e roda de novo.')}[lang]
    f = Fig('l04-mapreduce', 720, 260, t['label'])
    for i in range(3):
        y = 30 + i * 70
        box(f, 20, y, 90, 44, f"{t['split']} {i}")
        f.line(110, y + 22, 148, y + 22, arrow=True)
        box(f, 150, y, 110, 44, t['mapt'], stroke='--phosphor')
        for j in range(2):
            f.line(260, y + 22, 468, 75 + j * 100, stroke='--paper-dim', width=1, arrow=True)
    for j in range(2):
        y = 50 + j * 100
        box(f, 470, y, 110, 50, t['red'], stroke='--amber')
        f.line(580, y + 25, 618, y + 25, arrow=True)
        box(f, 620, y, 80, 50, t['out'])
    f.text(365, 250, t['shuffle'], size=10.5, fill='--paper-dim')
    return f, t['cap']


@figure('l04-joins', 4)
def l04_joins(lang):
    t = {'en': dict(
            label='Two ways to join purchases with books. On the left, the reduce-side join: both '
                  'inputs are mapped, tagged and shuffled by book id, and each reducer meets a book '
                  'with its purchases. On the right, the map-side join: the small book table is '
                  'copied to every map task, which looks each purchase up as it reads, and nothing '
                  'is shuffled.',
            rs='reduce-side join', ms='map-side join', books='books', purch='purchases',
            shuffle='shuffle by book_id', red='reducer: a book and its purchases',
            copy='a copy of the books in every task', mapt='map task',
            cap='The reduce-side join moves everything; the map-side join moves the small table '
                'to every task and nothing else.'),
         'pt': dict(
            label='Dois jeitos de juntar compras com livros. À esquerda, o join no reduce: as duas '
                  'entradas passam pelo map, recebem uma marca e são embaralhadas pelo id do livro, e '
                  'cada reducer encontra um livro com as suas compras. À direita, o join no map: a '
                  'pequena tabela de livros é copiada para cada tarefa de map, que procura cada compra '
                  'enquanto lê, e nada é embaralhado.',
            rs='join no reduce', ms='join no map', books='livros', purch='compras',
            shuffle='shuffle por book_id', red='reducer: um livro e as suas compras',
            copy='uma cópia dos livros em cada tarefa', mapt='tarefa de map',
            cap='O join no reduce move tudo; o join no map move a tabela pequena para cada tarefa '
                'e mais nada.')}[lang]
    f = Fig('l04-joins', 720, 250, t['label'])
    f.text(170, 20, t['rs'], size=11, weight='600')
    box(f, 20, 40, 120, 40, t['books'])
    box(f, 200, 40, 120, 40, t['purch'])
    f.line(80, 80, 160, 140, arrow=True)
    f.line(260, 80, 180, 140, arrow=True)
    f.text(20, 112, t['shuffle'], size=9.5, fill='--amber', anchor='start')
    box(f, 40, 142, 260, 46, t['red'], stroke='--amber')
    f.line(360, 20, 360, 230, stroke='--wire', dash='4 4')
    f.text(540, 20, t['ms'], size=11, weight='600')
    box(f, 390, 40, 120, 40, t['books'])
    f.text(522, 60, t['copy'], size=9.5, fill='--phosphor', anchor='start')
    for i in range(3):
        x = 390 + i * 110
        box(f, x, 142, 100, 46, t['mapt'], stroke='--phosphor')
        f.line(450, 80, x + 50, 140, stroke='--paper-dim', width=1, arrow=True)
        f.text(x + 50, 205, t['purch'], size=9.5, fill='--paper-dim')
        f.line(x + 50, 222, x + 50, 190, stroke='--paper-dim', width=1, arrow=True)
    return f, t['cap']


# ------------------------------------------------------------------ lesson 6

@figure('l06-catalyst', 6)
def l06_catalyst(lang):
    t = {'en': dict(
            label='The planner in five steps. A DataFrame program or a SQL query is parsed into a '
                  'parsed logical plan, analysed against the schema into an analysed plan, '
                  'rewritten by rules into an optimised plan, and given implementations as a '
                  'physical plan. While the job runs, adaptive execution looks at each finished '
                  'shuffle and replans what comes after it.',
            src='DataFrame or SQL', steps=['parsed', 'analysed', 'optimised', 'physical'],
            subs=['names as text', 'names checked', 'rules rewrite', 'joins, shuffles'],
            aqe='while it runs: replan after each shuffle', what='what', how='how',
            cap='Three plans say what; the fourth says how, and adaptive execution keeps '
                'revising it as the stages finish.'),
         'pt': dict(
            label='O planejador em cinco passos. Um programa DataFrame ou uma consulta SQL é '
                  'interpretado num plano lógico, analisado contra o esquema num plano analisado, '
                  'reescrito por regras num plano otimizado e recebe implementações como plano '
                  'físico. Enquanto o job roda, a execução adaptativa olha cada shuffle terminado e '
                  'replaneja o que vem depois.',
            src='DataFrame ou SQL', steps=['interpretado', 'analisado', 'otimizado', 'físico'],
            subs=['nomes como texto', 'nomes conferidos', 'regras reescrevem', 'joins, shuffles'],
            aqe='durante a execução: replaneja após cada shuffle', what='o quê', how='como',
            cap='Três planos dizem o quê; o quarto diz como, e a execução adaptativa continua '
                'revisando-o conforme os estágios terminam.')}[lang]
    f = Fig('l06-catalyst', 720, 230, t['label'])
    box(f, 10, 60, 110, 56, t['src'], size=10.5)
    x = 140
    for i, (s, sub) in enumerate(zip(t['steps'], t['subs'])):
        f.line(x - 18, 88, x - 2, 88, arrow=True)
        box(f, x, 60, 130, 56, s, sub, stroke='--amber' if i == 3 else '--phosphor')
        x += 145
    f.text(352, 40, t['what'], size=10.5, fill='--paper-dim')
    f.text(645, 40, t['how'], size=10.5, fill='--paper-dim')
    f.path('M645 116 L645 170 L560 170', stroke='--amber', width=1.3, dash='4 3')
    f.path('M560 182 L645 182 L645 120', stroke='--amber', width=1.3, dash='4 3', arrow=True)
    f.text(548, 176, t['aqe'], size=10, fill='--amber', anchor='end')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 7

@figure('l07-narrow-wide', 7)
def l07_narrow_wide(lang):
    t = {'en': dict(
            label='On the left, a narrow transformation: each of three input partitions feeds '
                  'exactly one output partition, and the steps chain inside one stage. On the '
                  'right, a wide transformation: each of three input partitions sends rows to '
                  'every output partition, a shuffle, and a new stage begins after it.',
            narrow='narrow: filter, select', wide='wide: groupBy, join', inp='input',
            out='output', stage='one stage', two='stage boundary',
            cap='Narrow steps chain inside a task; a wide step needs rows from every partition, '
                'and that is a shuffle.'),
         'pt': dict(
            label='À esquerda, uma transformação estreita: cada uma das três partições de entrada '
                  'alimenta exatamente uma partição de saída, e os passos se encadeiam dentro de um '
                  'estágio. À direita, uma transformação larga: cada uma das três partições de '
                  'entrada manda linhas a todas as partições de saída, um shuffle, e um estágio novo '
                  'começa depois dele.',
            narrow='estreita: filter, select', wide='larga: groupBy, join', inp='entrada',
            out='saída', stage='um estágio', two='fronteira de estágio',
            cap='Passos estreitos se encadeiam dentro de uma tarefa; um passo largo precisa de '
                'linhas de toda partição, e isso é um shuffle.')}[lang]
    f = Fig('l07-narrow-wide', 720, 260, t['label'])
    for side, x0 in ((0, 40), (1, 400)):
        f.text(x0 + 140, 20, t['wide'] if side else t['narrow'], size=11, weight='600')
        f.text(x0 + 20, 44, t['inp'], size=10, fill='--paper-dim')
        f.text(x0 + 260, 44, t['out'], size=10, fill='--paper-dim')
        for i in range(3):
            y = 60 + i * 55
            f.rect(x0, y, 40, 36, stroke='--phosphor', fill='--scan', rx=3)
            f.rect(x0 + 240, y, 40, 36, stroke='--phosphor' if not side else '--amber',
                   fill='--scan', rx=3)
            if side:
                for j in range(3):
                    f.line(x0 + 40, y + 18, x0 + 238, 78 + j * 55, stroke='--amber', width=1,
                           arrow=True)
            else:
                f.line(x0 + 40, y + 18, x0 + 238, y + 18, stroke='--paper-dim', arrow=True)
        if side:
            f.line(x0 + 140, 50, x0 + 140, 225, stroke='--amber', dash='4 3')
            f.text(x0 + 140, 240, t['two'], size=10, fill='--amber')
        else:
            f.text(x0 + 140, 240, t['stage'], size=10, fill='--paper-dim')
    f.line(360, 30, 360, 250, stroke='--wire', dash='4 4')
    return f, t['cap']


@figure('l07-memory', 7)
def l07_memory(lang):
    t = {'en': dict(
            label='The 768 MiB heap of one executor as a bar. 300 MiB are reserved. Of the 468 '
                  'left, 60 percent, 280.8 MiB, is the unified region shared by execution and '
                  'storage; the other 187.2 MiB is for user code. Overhead memory sits outside the '
                  'heap.',
            res='reserved', uni='execution + storage', user='user code', heap='768 MiB heap',
            over='overhead, outside the heap', exe='execution', sto='storage',
            cap='Spark keeps 300 MiB for itself and shares 60 percent of the rest between running '
                'tasks and cached data.'),
         'pt': dict(
            label='O heap de 768 MiB de um executor como uma barra. 300 MiB são reservados. Dos '
                  '468 que sobram, 60 por cento, 280,8 MiB, são a região unificada dividida entre '
                  'execução e armazenamento; os outros 187,2 MiB são para o código do usuário. A '
                  'memória de overhead fica fora do heap.',
            res='reservado', uni='execução + armazenamento', user='código do usuário',
            heap='heap de 768 MiB', over='overhead, fora do heap', exe='execução',
            sto='armazenamento',
            cap='O Spark guarda 300 MiB para si e divide 60 por cento do resto entre tarefas em '
                'execução e dados em cache.')}[lang]
    f = Fig('l07-memory', 720, 200, t['label'])
    x0, w = 30, 560
    sc = w / 768
    parts = [(300, t['res'], '300', '--wire'), (280.8, t['uni'], '280.8', '--phosphor'),
             (187.2, t['user'], '187.2', '--wire')]
    x = x0
    for size, name, num, stroke in parts:
        f.rect(x, 60, size * sc, 56, stroke=stroke, fill='--scan' if stroke == '--phosphor' else '--panel', rx=2)
        f.text(x + size * sc / 2, 80, name, size=10.5, weight='600')
        f.text(x + size * sc / 2, 98, (num.replace('.', ',') if lang == 'pt' else num) + ' MiB',
               size=10, fill='--paper-dim', mono=True)
        x += size * sc
    ux = x0 + 300 * sc
    f.line(ux + 280.8 * sc / 2, 116, ux + 280.8 * sc / 2, 150, stroke='--phosphor', dash='3 3')
    f.text(ux + 6, 150, t['exe'], size=10, anchor='start', fill='--phosphor')
    f.text(ux + 280.8 * sc - 6, 150, t['sto'], size=10, anchor='end', fill='--phosphor')
    f.text(x0 + w / 2, 40, t['heap'], size=11, weight='600')
    f.rect(x0 + w + 10, 60, 110, 56, stroke='--amber', fill='--panel', rx=2, dash='4 3')
    f.text(x0 + w + 65, 88, t['over'].split(',')[0], size=10.5, weight='600')
    f.text(x0 + w + 65, 130, t['over'].split(', ')[1], size=9.5, fill='--amber')
    return f, t['cap']


# ------------------------------------------------------------------ lesson 8

# Rows read by each of the 200 tasks of skew.py's join stage, in partition order,
# from the run its captures.sh records (see the header there).
L08_TASK_ROWS = [
    124925, 124405, 123857, 121535, 121911, 123349, 121036, 124774, 122578, 123454, 123963,
    126010, 121491, 122570, 122664, 125004, 126067, 123461, 123640, 124618, 122717, 123632,
    124822, 125371, 124789, 124238, 125750, 122182, 123486, 123846, 123862, 119806, 123523,
    124084, 123608, 128020, 125064, 123106, 125939, 126329, 123178, 123331, 124569, 123993,
    124789, 123062, 122845, 123760, 122810, 124884, 122972, 122406, 122890, 124330, 124151,
    126013, 124675, 123114, 123247, 124439, 120058, 122454, 120597, 123845, 122855, 124070,
    122926, 124191, 125366, 125295, 1086798, 123372, 124030, 123365, 125801, 122188, 122808,
    124627, 123643, 123488, 123431, 123925, 124696, 123908, 125636, 125945, 123064, 121275,
    121487, 125168, 122015, 122337, 125325, 124521, 125206, 123373, 125912, 122595, 121443,
    122855, 123683, 124756, 122740, 124058, 123476, 124695, 120542, 126722, 124981, 128274,
    123471, 123700, 123725, 123544, 126499, 121749, 124708, 125742, 124183, 122977, 124101,
    124895, 123138, 123280, 125295, 125179, 122105, 124873, 122008, 121513, 124898, 123606,
    123856, 122709, 123075, 125127, 121440, 123420, 124427, 125135, 124955, 121810, 123503,
    125008, 121763, 122958, 126386, 126532, 124685, 124302, 122358, 120268, 124007, 124482,
    121562, 123282, 120357, 127051, 124359, 124550, 124290, 123965, 124206, 121428, 125179,
    124943, 124434, 123536, 124117, 126590, 123864, 126440, 123370, 124250, 122336, 122328,
    125124, 123159, 123675, 124366, 124101, 124938, 123776, 122161, 124117, 121159, 127069,
    123908, 124148, 126509, 123691, 124497, 124231, 122231, 123554, 124224, 123518, 125357,
    122192, 122839,
]


@figure('l08-skew', 8)
def l08_skew(lang):
    rows = L08_TASK_ROWS
    med = sorted(rows)[len(rows) // 2]
    hot = max(rows)
    t = {'en': dict(
            label=f'A bar chart of the rows read by each of the 200 tasks of the join stage, in '
                  f'partition order. 199 bars stand close to the median of {num(lang, med, 0)} rows. '
                  f'One bar, the partition holding the crawler v0000000, reaches '
                  f'{num(lang, hot, 0)} rows.',
            x='the 200 tasks of the join stage, in partition order',
            y='thousands of rows read', med='median', hot='v0000000 is in here',
            cap='The hash spreads two million visitors evenly over 200 partitions, and cannot '
                'spread one.'),
         'pt': dict(
            label=f'Um gráfico de barras das linhas lidas por cada uma das 200 tarefas do estágio do '
                  f'join, na ordem das partições. 199 barras ficam perto da mediana de '
                  f'{num(lang, med, 0)} linhas. Uma barra, a da partição que guarda o robô '
                  f'v0000000, chega a {num(lang, hot, 0)} linhas.',
            x='as 200 tarefas do estágio do join, na ordem das partições',
            y='milhares de linhas lidas', med='mediana', hot='o v0000000 está aqui',
            cap='O hash espalha dois milhões de visitantes por igual em 200 partições, e não '
                'consegue espalhar um.')}[lang]
    f = Fig('l08-skew', 720, 300, t['label'])
    top = 1200
    p = Plot(f, 70, 40, 690, 250, 0, len(rows), 0, top)
    p.yaxis([0, 200, 400, 600, 800, 1000, 1200], fmt=lambda v: num(lang, v, 0), label=t['y'])
    p.xaxis([0, 50, 100, 150, 200], label=t['x'])
    i_hot = rows.index(hot)
    p.bars(list(range(len(rows) + 1)), [r / 1000 for r in rows], highlight=lambda i: i == i_hot)
    y = p.sy(med / 1000)
    f.line(p.x0, y, p.x1, y, stroke='--amber', dash='4 3', width=1.2)
    f.text(p.x1, y - 9, f"{t['med']} {num(lang, med, 0)}", size=9.5, anchor='end', fill='--amber')
    x = p.sx(i_hot + 0.5)
    f.text(x + (10 if i_hot < 120 else -10), p.sy(hot / 1000) + 4, t['hot'], size=10,
           anchor='start' if i_hot < 120 else 'end', fill='--amber')
    return f, t['cap']


@figure('l08-salting', 8)
def l08_salting(lang):
    t = {'en': dict(
            label='Two rows of partitions. Above, without a salt: the crawler v0000000 and all of '
                  'its 960,905 events go to one partition, together with its one visitor row. '
                  'Below, with eight salts: the events are split by salt 0 to 7 into eight '
                  'partitions of about 120,000 each, and the visitor row is copied eight times, '
                  'once into each of them.',
            before='join key: visitor_id', after='join key: visitor_id + salt',
            ev='960,905 events', ev8='~120,000 events', vis='1 visitor row',
            copy='copy', cap='The large side is split by the salt; the small side is copied once '
                             'per salt, so every piece still finds its match.'),
         'pt': dict(
            label='Duas fileiras de partições. Em cima, sem sal: o robô v0000000 e todos os seus '
                  '960.905 eventos vão para uma partição, junto com a sua única linha de '
                  'visitante. Embaixo, com oito sais: os eventos se dividem pelo sal de 0 a 7 em '
                  'oito partições de cerca de 120.000 cada, e a linha do visitante é copiada oito '
                  'vezes, uma em cada.',
            before='chave do join: visitor_id', after='chave do join: visitor_id + sal',
            ev='960.905 eventos', ev8='~120.000 eventos', vis='1 linha de visitante',
            copy='cópia', cap='O lado grande se divide pelo sal; o lado pequeno é copiado uma vez '
                              'por sal, então cada pedaço ainda acha o seu par.')}[lang]
    f = Fig('l08-salting', 720, 300, t['label'])
    f.text(20, 22, t['before'], size=11, anchor='start', weight='600')
    f.rect(20, 36, 300, 70, stroke='--amber', fill='--scan')
    f.text(170, 60, 'v0000000', size=11, mono=True)
    f.text(170, 84, t['ev'], size=10, fill='--paper-dim')
    f.rect(340, 52, 120, 38, stroke='--wire')
    f.text(400, 71, t['vis'], size=10)
    f.text(20, 140, t['after'], size=11, anchor='start', weight='600')
    w = 80
    for i in range(8):
        x = 20 + i * (w + 6)
        f.rect(x, 154, w, 56, stroke='--phosphor', fill='--scan')
        f.text(x + w / 2, 172, f'v0000000 · {i}', size=9, mono=True)
        f.text(x + w / 2, 192, t['ev8'], size=8.5, fill='--paper-dim')
        f.rect(x + 6, 226, w - 12, 30, stroke='--wire')
        f.text(x + w / 2, 241, f"{t['copy']} {i}", size=9.5)
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
