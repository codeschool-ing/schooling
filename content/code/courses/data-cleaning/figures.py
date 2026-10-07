#!/usr/bin/env python3
"""Every diagram in the data-cleaning course, drawn from the lab's own files.

A bar for a dirty column drawn by hand is a claim about data nobody can check.
These are computed: every bar, point and count comes from the files
lab/generate.py writes, the same files every capture in the course reads, so a
figure cannot drift from the transcript beside it.

    sudo bash lab.sh up           # once: the data lives in /var/lib/clean-data
    python3 figures.py            # rewrite every figure in the lessons
    python3 figures.py --list     # the names, and the lesson each lives in

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

Only palette tokens are used, so each drawing turns over with the theme like
the page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel. The drawing helpers are the statistics
course's, copied.

Standard library only.
"""
import collections
import csv
import datetime as dt
import glob
import json
import math
import os
import re
import sys
import unicodedata

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.environ.get('CLEAN_DATA', '/var/lib/clean-data')
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


def rows(name, encoding='utf-8', delimiter=','):
    with open(os.path.join(DATA, name), encoding=encoding, newline='') as f:
        return list(csv.DictReader(f, delimiter=delimiter))

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


def histogram(xs, edges):
    counts = [0] * (len(edges) - 1)
    for x in xs:
        for i in range(len(edges) - 1):
            last = i == len(edges) - 2
            if edges[i] <= x < edges[i + 1] or (last and x == edges[-1]):
                counts[i] += 1
                break
    return counts


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

def spelling_kinds(v):
    if v == 'São Paulo':
        return ['canonical']
    out = []
    core = unicodedata.normalize('NFC', v).strip()
    if 'Ã' in v:
        out.append('mojibake')
    if unicodedata.normalize('NFC', v) != v:
        out.append('nfd')
    if v != v.strip():
        out.append('space')
    if 'Ã' not in v and core.lower() == 'sao paulo':
        out.append('accent')
    if core.startswith('S.'):
        out.append('abbrev')
    if core.lower() in ('são paulo', 'sao paulo', 'sã£o paulo') and core not in ('São Paulo', 'Sao Paulo', 'SÃ£o Paulo'):
        out.append('case')
    return out


KIND = {
    'en': {'canonical': 'the spelling everybody means', 'nfd': 'accent stored apart',
           'space': 'a space after it', 'accent': 'no accent', 'case': 'capitals differ',
           'abbrev': 'abbreviated', 'mojibake': 'accent mangled in 2023'},
    'pt': {'canonical': 'a grafia que todo mundo quer dizer', 'nfd': 'acento guardado à parte',
           'space': 'um espaço depois', 'accent': 'sem acento', 'case': 'maiúsculas',
           'abbrev': 'abreviado', 'mojibake': 'acento estragado em 2023'},
}


@figure('l01-sao-paulo', 1)
def l01_sao_paulo(lang):
    c = collections.Counter(r['city'] for r in rows('raw/customers.csv') if 'paulo' in r['city'].lower())
    items = c.most_common()
    total = sum(c.values())
    fig = Fig('l01-sao-paulo', 720, 60 + 26 * len(items), {
        'en': f'A bar chart of the {len(items)} ways the city column of customers.csv spells São Paulo, '
              f'{total} customers in all. The correct spelling has {items[0][1]} rows; the rest are split '
              'between a decomposed accent, no accent, capitals, an abbreviation, a trailing space and '
              'text mangled by a migration.',
        'pt': f'Um gráfico de barras das {len(items)} maneiras como a coluna city do customers.csv escreve '
              f'São Paulo, {total} clientes ao todo. A grafia certa tem {items[0][1]} linhas; o resto se '
              'divide entre acento decomposto, sem acento, maiúsculas, abreviação, espaço no fim e texto '
              'estragado por uma migração.'}[lang])
    top = 40
    mx = items[0][1]
    for i, (v, n) in enumerate(items):
        y = top + 26 * i
        ks = spelling_kinds(v)
        k = ks[0]
        shown = '"' + unicodedata.normalize('NFC', v) + '"'
        fig.text(200, y + 9, shown, size=11, anchor='end', mono=True)
        w = 260 * n / mx
        fig.rect(210, y, w, 18, stroke='--phosphor' if k == 'canonical' else '--amber',
                 fill='--phosphor-dim' if k == 'canonical' else '--scan', rx=2)
        fig.text(216 + w, y + 9, str(n), size=10, anchor='start', mono=True)
        fig.text(500, y + 9, ', '.join(KIND[lang][x] for x in ks), size=10, anchor='start',
                 fill='--paper-dim')
    fig.text(20, 20, {'en': 'city, in customers.csv', 'pt': 'city, no customers.csv'}[lang],
             size=11, anchor='start', weight='600')
    fig.text(500, 20, {'en': 'what is different', 'pt': 'o que muda'}[lang], size=11, anchor='start',
             weight='600')
    cap = {'en': f'One city, {len(items)} values. Only the first bar is what a GROUP BY would call São Paulo.',
           'pt': f'Uma cidade, {len(items)} valores. Só a primeira barra é o que um GROUP BY chamaria de São Paulo.'}
    return fig, cap[lang]


@figure('l01-export-gap', 1)
def l01_export_gap(lang):
    known = {r['customer_id'] for r in rows('raw/customers.csv')}
    per = collections.Counter()
    seen = set()
    for r in rows('raw/orders.csv'):
        if r['order_id'] in seen:
            continue
        seen.add(r['order_id'])
        if r['ordered_at'][:7] == '2025-12' and r['customer_id'] not in known:
            per[int(r['ordered_at'][8:10])] += 1
    fig = Fig('l01-export-gap', 720, 300, {
        'en': 'Orders per day in December 2025 whose customer is missing from customers.csv. Up to the '
              'tenth, the day the customer file was exported, half the days have none and no day has '
              'more than two. From the thirteenth on, every day has between one and four.',
        'pt': 'Pedidos por dia em dezembro de 2025 cujo cliente falta no customers.csv. Até o dia dez, '
              'quando o arquivo de clientes foi exportado, metade dos dias não tem nenhum e nenhum dia '
              'tem mais de dois. Do dia treze em diante, todo dia tem entre um e quatro.'}[lang])
    ymax = max(per.values()) + 1
    p = Plot(fig, 70, 50, 690, 240, 0.5, 31.5, 0, ymax)
    p.yaxis(range(0, ymax + 1), label={'en': 'orders with no customer', 'pt': 'pedidos sem cliente'}[lang])
    p.xaxis([1, 5, 10, 15, 20, 25, 31], label={'en': 'day of December 2025', 'pt': 'dia de dezembro de 2025'}[lang])
    for d in range(1, 32):
        n = per.get(d, 0)
        if n:
            x0, x1 = p.sx(d - 0.38), p.sx(d + 0.38)
            fig.rect(x0, p.sy(n), x1 - x0, p.sy(0) - p.sy(n), stroke='--amber' if d > 10 else '--phosphor',
                     fill='--scan' if d > 10 else '--phosphor-dim', rx=1)
    p.vline(10.5, label={'en': 'customers.csv exported', 'pt': 'customers.csv exportado'}[lang], top=62,
            anchor='middle')
    cap = {'en': 'The customer file stops on 10 December and the orders do not. After that line, a new '
                 'customer\'s orders have no account to belong to.',
           'pt': 'O arquivo de clientes para em 10 de dezembro e os pedidos não. Depois dessa linha, os pedidos '
                 'de um cliente novo não têm conta a que pertencer.'}
    return fig, cap[lang]


# ------------------------------------------------------------------ lesson 2

@figure('l02-cep-profile', 2)
def l02_cep_profile(lang):
    vals = [r['cep'] for r in rows('raw/customers.csv')]
    pat = collections.Counter(re.sub(r'[0-9]', '9', v) for v in vals)
    items = pat.most_common()
    lens = [len(v) for v in vals]
    W = {'en': dict(title='cep, profiled', filled='filled', empty='empty', distinct='distinct',
                    length='length', chars='characters', shape='pattern', rows='rows',
                    notes={'99999-999': 'as the post office writes it', '99999999': 'hyphen dropped',
                           '9999999': 'hyphen dropped and a leading zero lost'}),
         'pt': dict(title='cep, perfilado', filled='preenchidos', empty='vazios', distinct='distintos',
                    length='tamanho', chars='caracteres', shape='padrão', rows='linhas',
                    notes={'99999-999': 'como os Correios escrevem', '99999999': 'sem o hífen',
                           '9999999': 'sem o hífen e sem um zero à esquerda'})}[lang]
    fig = Fig('l02-cep-profile', 720, 220, {
        'en': f'A profile card for the cep column of customers.csv: {len(vals)} filled, none empty, '
              f'{len(set(vals))} distinct, {min(lens)} to {max(lens)} characters long. Beside it, the '
              f'three patterns: {items[0][1]} values written as the post office writes them, '
              f'{items[1][1]} without the hyphen, and {items[2][1]} without the hyphen and with a '
              'leading zero lost.',
        'pt': f'Um cartão de perfil da coluna cep do customers.csv: {len(vals)} preenchidos, nenhum vazio, '
              f'{len(set(vals))} distintos, de {min(lens)} a {max(lens)} caracteres. Ao lado, os três '
              f'padrões: {items[0][1]} valores escritos como os Correios escrevem, {items[1][1]} sem o '
              f'hífen e {items[2][1]} sem o hífen e com um zero à esquerda perdido.'}[lang])
    fig.rect(20, 30, 200, 160, stroke='--wire', fill='--panel')
    fig.text(120, 50, W['title'], size=12, weight='600')
    stats = [(W['filled'], f'{len(vals)}'), (W['empty'], '0'), (W['distinct'], f'{len(set(vals))}'),
             (W['length'], f'{min(lens)}–{max(lens)}')]
    for i, (k, v) in enumerate(stats):
        y = 82 + 26 * i
        fig.text(36, y, k, size=11, anchor='start', fill='--paper-dim')
        fig.text(204, y, v, size=11, anchor='end', mono=True)
    fig.text(250, 50, W['shape'], size=11, anchor='start', weight='600')
    mx = items[0][1]
    for i, (p, n) in enumerate(items):
        y = 70 + 44 * i
        fig.text(250, y + 10, p, size=12, anchor='start', mono=True)
        w = 200 * n / mx
        bad = p != '99999-999'
        fig.rect(345, y, w, 20, stroke='--amber' if bad else '--phosphor',
                 fill='--scan' if bad else '--phosphor-dim', rx=2)
        fig.text(351 + w, y + 10, str(n), size=10, anchor='start', mono=True)
        fig.text(345, y + 32, W['notes'][p], size=10, anchor='start', fill='--paper-dim')
    cap = {'en': 'The profile says the lengths disagree; the patterns say how. Only the first bar is a '
                 'postal code a lookup table would match as it stands.',
           'pt': 'O perfil diz que os tamanhos discordam; os padrões dizem como. Só a primeira barra é um '
                 'CEP que uma tabela de consulta reconheceria como está.'}
    return fig, cap[lang]


# ------------------------------------------------------------------ lesson 3

@figure('l03-mechanisms', 3)
def l03_mechanisms(lang):
    T = {'en': dict(mcar='completely at random', mar='at random', mnar='not at random',
                    sub1='nothing explains the gaps', sub2='the courier explains them',
                    sub3='the value itself explains them', courier='courier', minutes='minutes',
                    note='hollow: the value is missing; grey: what it would have been'),
         'pt': dict(mcar='completamente ao acaso', mar='ao acaso', mnar='não ao acaso',
                    sub1='nada explica os vazios', sub2='o entregador os explica',
                    sub3='o próprio valor os explica', courier='entregador', minutes='minutos',
                    note='vazado: o valor falta; cinza: o que ele teria sido')}[lang]
    fig = Fig('l03-mechanisms', 720, 360, {
        'en': 'Three panels of the same eight deliveries, each with a courier and a delivery time. In '
              'the first, two times are missing in rows that have nothing in common. In the second, '
              'the times are missing exactly where the courier is R, the partner that never reports. '
              'In the third, the times are missing exactly where the delivery took 120 minutes or '
              'more. An illustration, not data from the lab.',
        'pt': 'Três painéis das mesmas oito entregas, cada uma com entregador e tempo de entrega. No '
              'primeiro, faltam dois tempos em linhas que não têm nada em comum. No segundo, os tempos '
              'faltam exatamente onde o entregador é R, a parceira que nunca informa. No terceiro, os '
              'tempos faltam exatamente onde a entrega levou 120 minutos ou mais. Uma ilustração, não '
              'dados do laboratório.'}[lang])
    couriers = ['P', 'R', 'P', 'P', 'R', 'P', 'P', 'R']
    minutes = [42, 55, 131, 38, 61, 47, 126, 50]
    rules = [lambda i: i in (3, 5), lambda i: couriers[i] == 'R', lambda i: minutes[i] >= 120]
    heads = [(T['mcar'], T['sub1']), (T['mar'], T['sub2']), (T['mnar'], T['sub3'])]
    for k in range(3):
        x0 = 20 + 235 * k
        fig.text(x0 + 105, 24, heads[k][0], size=12, weight='600')
        fig.text(x0 + 105, 42, heads[k][1], size=10, fill='--paper-dim')
        fig.text(x0 + 50, 66, T['courier'], size=10, fill='--paper-dim')
        fig.text(x0 + 150, 66, T['minutes'], size=10, fill='--paper-dim')
        for i in range(8):
            y = 78 + 30 * i
            fig.rect(x0 + 25, y, 50, 22, stroke='--wire', fill='--panel', rx=2)
            fig.text(x0 + 50, y + 11, couriers[i], size=11, mono=True)
            if rules[k](i):
                fig.rect(x0 + 120, y, 60, 22, stroke='--amber', fill='--scan', rx=2, dash='4 3')
                fig.text(x0 + 150, y + 11, str(minutes[i]), size=11, mono=True, fill='--paper-dim')
            else:
                fig.rect(x0 + 120, y, 60, 22, stroke='--phosphor', fill='--phosphor-dim', rx=2)
                fig.text(x0 + 150, y + 11, str(minutes[i]), size=11, mono=True)
    fig.text(360, 338, T['note'], size=10, fill='--paper-dim')
    cap = {'en': 'The same blanks can come from three mechanisms. Only the first two leave a trace in the '
                 'columns you have.',
           'pt': 'Os mesmos vazios podem vir de três mecanismos. Só os dois primeiros deixam rastro nas '
                 'colunas que você tem.'}
    return fig, cap[lang]


def own_orders():
    seen, out = set(), []
    for r in rows('raw/orders.csv'):
        if r['order_id'] in seen:
            continue
        seen.add(r['order_id'])
        out.append(r)
    return out


@figure('l03-pattern-map', 3)
def l03_pattern_map(lang):
    orders = own_orders()
    segs = [('app', 'delivery', 'Rapidex'), ('app', 'delivery', 'propria'), ('app', 'pickup', ''),
            ('site', 'delivery', 'Rapidex'), ('site', 'delivery', 'propria'), ('site', 'pickup', '')]
    cols = ['courier', 'delivery_minutes', 'discount']
    share = {}
    for seg in segs:
        rs = [r for r in orders if (r['channel'], r['fulfilment'], r['courier']) == seg]
        for c in cols:
            share[seg, c] = 100 * sum(1 for r in rs if r[c] == '') / len(rs)
    names = {'en': {'pickup': 'pickup'}, 'pt': {'pickup': 'retirada'}}[lang]
    fig = Fig('l03-pattern-map', 720, 300, {
        'en': 'A grid of the share of empty cells in three columns of the orders file, for six groups '
              'of orders. Courier is empty in every pickup and nowhere else. Delivery minutes is empty '
              'in every pickup and every Rapidex delivery, and in about seven per cent of the own '
              'fleet\'s. Discount is empty in almost nine of ten website orders and in no app order.',
        'pt': 'Uma grade da fração de células vazias em três colunas do arquivo de pedidos, para seis '
              'grupos de pedidos. O entregador está vazio em toda retirada e em nenhum outro lugar. Os '
              'minutos de entrega estão vazios em toda retirada e em toda entrega da Rapidex, e em cerca '
              'de sete por cento das da frota própria. O desconto está vazio em quase nove de dez '
              'pedidos do site e em nenhum do aplicativo.'}[lang])
    x0, y0, cw, ch = 250, 50, 140, 36
    for j, c in enumerate(cols):
        fig.text(x0 + cw * j + cw / 2, y0 - 14, c, size=11, mono=True)
    for i, seg in enumerate(segs):
        y = y0 + ch * i
        label = f"{seg[0]} · {names.get(seg[1], seg[1]) if seg[1] == 'pickup' else seg[2]}"
        fig.text(x0 - 12, y + ch / 2, label, size=11, anchor='end', mono=seg[1] != 'pickup')
        for j, c in enumerate(cols):
            v = share[seg, c]
            fill = '--amber' if v >= 99.5 else ('--scan' if v > 0.05 else '--panel')
            stroke = '--wire'
            fig.rect(x0 + cw * j + 2, y + 2, cw - 4, ch - 4, stroke=stroke, fill=fill, rx=2)
            txt = num(lang, v, 1) + '%'
            fig.text(x0 + cw * j + cw / 2, y + ch / 2, txt, size=11, mono=True,
                     fill='--ink' if v >= 99.5 else '--paper')
    cap = {'en': 'Read down a column and across a row: each blank lines up with something you can see, '
                 'except the 7% of own-fleet times.',
           'pt': 'Leia descendo uma coluna e atravessando uma linha: cada vazio se alinha com algo que você '
                 'vê, menos os 7% de tempos da frota própria.'}
    return fig, cap[lang]


@figure('l03-ceiling', 3)
def l03_ceiling(lang):
    t = [int(r['value']) for r in rows('truth/orders.csv') if r['what'] == 'minutes']
    edges = list(range(0, 240, 10))
    counts = histogram(t, edges)
    hidden = sum(1 for v in t if v >= 120)
    fig = Fig('l03-ceiling', 720, 320, {
        'en': f'A histogram of the real delivery times of {len(t)} own-fleet deliveries, in ten-minute '
              f'bins from 0 to 230 minutes, as the lab\'s generator knows them. Every bar below 120 '
              f'minutes was recorded. The {hidden} deliveries of 120 minutes or more, a thin tail out '
              'to 223, were never recorded, because the timer stops at two hours.',
        'pt': f'Um histograma dos tempos reais de {len(t)} entregas da frota própria, em faixas de dez '
              f'minutos de 0 a 230, como o gerador do laboratório os conhece. Toda barra abaixo de 120 '
              f'minutos foi registrada. As {hidden} entregas de 120 minutos ou mais, uma cauda fina até '
              '223, nunca foram registradas, porque o cronômetro para em duas horas.'}[lang])
    ymax = max(counts) * 1.12
    p = Plot(fig, 70, 50, 690, 250, 0, 230, 0, ymax)
    step = 1000 if ymax > 3000 else 500
    p.yaxis(range(0, int(ymax) + 1, step), label={'en': 'deliveries', 'pt': 'entregas'}[lang])
    p.xaxis(range(0, 231, 30), label={'en': 'real delivery time, minutes', 'pt': 'tempo real de entrega, minutos'}[lang])
    for i, c in enumerate(counts):
        if c <= 0:
            continue
        x0, x1 = p.sx(edges[i]), p.sx(edges[i + 1])
        y = p.sy(max(c, ymax * 0.006))
        if edges[i] >= 120:
            fig.rect(x0, y, x1 - x0, p.sy(0) - y, stroke='--amber', fill='--scan', rx=0, dash='3 2')
        else:
            fig.rect(x0, y, x1 - x0, p.sy(0) - y, stroke='--phosphor', fill='--phosphor-dim', rx=0)
    p.vline(120, label={'en': 'the timer stops', 'pt': 'o cronômetro para'}[lang], top=70)
    fig.text(p.sx(175), p.sy(ymax * 0.35), {'en': f'{hidden} never recorded', 'pt': f'{hidden} nunca registradas'}[lang],
             size=11, fill='--amber', weight='600')
    cap = {'en': 'Drawn from the lab\'s truth file, which no real data set has. In the orders file, everything '
                 'right of the line is simply a blank.',
           'pt': 'Desenhado a partir do arquivo de verdade do laboratório, que nenhum dado real tem. No arquivo '
                 'de pedidos, tudo à direita da linha é simplesmente um vazio.'}
    return fig, cap[lang]


# ------------------------------------------------------------------ lesson 5

def plain(text):
    text = unicodedata.normalize('NFKD', text)
    text = ''.join(ch for ch in text if not unicodedata.combining(ch))
    return ' '.join(text.lower().split())


@figure('l05-blocking', 5)
def l05_blocking(lang):
    seen, people = set(), []
    for r in rows('raw/customers.csv'):
        key = tuple(r.values())
        if key not in seen:
            seen.add(key)
            people.append(r)
    n = len(people)
    allp = n * (n - 1) // 2
    blocks = collections.Counter(plain(r['name']).split()[-1] for r in people)
    within = sum(k * (k - 1) // 2 for k in blocks.values())
    fig = Fig('l05-blocking', 720, 340, {
        'en': f'Two squares drawn to scale by area. The large one is every possible pair of the {n} '
              f'customers, {allp:,}. The small one in its corner is the {within:,} pairs that share a '
              f'surname, the only ones compared: {100 * within / allp:.1f}% of the work.',
        'pt': f'Dois quadrados em escala de área. O grande é todo par possível dos {n} clientes, '
              f'{num(lang, allp, 0)}. O pequeno no canto é o dos {num(lang, within, 0)} pares que '
              f'compartilham sobrenome, os únicos comparados: {num(lang, 100 * within / allp, 1)}% do '
              'trabalho.'}[lang])
    side = 260
    small = side * math.sqrt(within / allp)
    x0, y0 = 60, 40
    fig.rect(x0, y0, side, side, stroke='--wire', fill='--scan', rx=0)
    fig.rect(x0, y0 + side - small, small, small, stroke='--phosphor', fill='--phosphor-dim', rx=0)
    t = {'en': (f'every pair: {allp:,}', 'compared each with each', f'same surname: {within:,}',
                f'{len(blocks)} blocks, one per surname'),
         'pt': (f'todo par: {num(lang, allp, 0)}', 'comparados cada um com cada um',
                f'mesmo sobrenome: {num(lang, within, 0)}', f'{len(blocks)} blocos, um por sobrenome')}[lang]
    fig.text(390, 90, t[0], size=13, anchor='start', weight='600')
    fig.text(390, 110, t[1], size=11, anchor='start', fill='--paper-dim')
    fig.text(390, 245, t[2], size=13, anchor='start', weight='600', fill='--phosphor')
    fig.text(390, 265, t[3], size=11, anchor='start', fill='--paper-dim')
    cap = {'en': 'Blocking compares only records that already share something. The price is every real pair '
                 'that does not share it.',
           'pt': 'Bloquear compara só registros que já compartilham alguma coisa. O preço é todo par real que '
                 'não compartilha.'}
    return fig, cap[lang]


# ------------------------------------------------------------------ lesson 6

def city_steps():
    seen, vals = set(), []
    for r in rows('raw/customers.csv'):
        k = tuple(r.values())
        if k not in seen:
            seen.add(k)
            vals.append(r['city'])
    fixes = [
        lambda v: ' '.join(v.split()),
        lambda v: unicodedata.normalize('NFC', v),
        lambda v: v.encode('latin-1').decode('utf-8') if 'Ã' in v else v,
        lambda v: v.lower(),
        lambda v: ''.join(c for c in unicodedata.normalize('NFKD', v) if not unicodedata.combining(c)),
    ]
    out = [len(set(vals))]
    for f in fixes:
        vals = [f(v) for v in vals]
        out.append(len(set(vals)))
    return out


ABBREV = {'s. paulo': 'São Paulo', 'sao paulo': 'São Paulo', 'campinas': 'Campinas', 'rio de janeiro': 'Rio de Janeiro',
          'rio': 'Rio de Janeiro', 'rj': 'Rio de Janeiro', 'belo horizonte': 'Belo Horizonte',
          'b. horizonte': 'Belo Horizonte', 'bh': 'Belo Horizonte', 'curitiba': 'Curitiba',
          'curitiba - pr': 'Curitiba'}


@figure('l06-cascade', 6)
def l06_cascade(lang):
    counts = city_steps() + [len(set(ABBREV.values()))]
    labels = {'en': ['as exported', 'spaces trimmed', 'Unicode to NFC', 'mojibake repaired', 'lower case',
                     'accents removed', 'abbreviations mapped'],
              'pt': ['como exportado', 'espaços aparados', 'Unicode em NFC', 'mojibake reparado', 'minúsculas',
                     'sem acentos', 'abreviações mapeadas']}[lang]
    fig = Fig('l06-cascade', 720, 330, {
        'en': 'A bar chart of how many distinct values the city column holds after each cleaning step: '
              + ', '.join(f'{l} {c}' for l, c in zip(labels, counts)) + '. The largest single drop is lower case.',
        'pt': 'Um gráfico de barras de quantos valores distintos a coluna de cidade tem depois de cada passo da '
              'limpeza: ' + ', '.join(f'{l} {c}' for l, c in zip(labels, counts)) + '. A maior queda isolada é a das minúsculas.'}[lang])
    top, mx = 30, counts[0]
    for i, (l, c) in enumerate(zip(labels, counts)):
        y = top + 40 * i
        fig.text(190, y + 12, l, size=11, anchor='end')
        w = 420 * c / mx
        last = i == len(counts) - 1
        fig.rect(200, y, w, 24, stroke='--phosphor' if last else '--wire',
                 fill='--phosphor-dim' if last else '--scan', rx=2)
        fig.text(206 + w, y + 12, str(c), size=11, anchor='start', mono=True)
    cap = {'en': 'Twenty-eight spellings, five cities. The steps are cheap and general; only the last one needs a '
                 'list somebody wrote.',
           'pt': 'Vinte e oito grafias, cinco cidades. Os passos são baratos e gerais; só o último precisa de uma lista '
                 'que alguém escreveu.'}
    return fig, cap[lang]


# ------------------------------------------------------------------ lesson 7

@figure('l07-two-clocks', 7)
def l07_two_clocks(lang):
    T = {'en': dict(utc='UTC, as the website writes it', sp='São Paulo, as the customer saw it',
                    order='one order', moved='same instant, previous day', jan1='1 January', jan2='2 January',
                    dec31='31 December'),
         'pt': dict(utc='UTC, como o site escreve', sp='São Paulo, como o cliente viu',
                    order='um pedido', moved='mesmo instante, dia anterior', jan1='1º de janeiro',
                    jan2='2 de janeiro', dec31='31 de dezembro')}[lang]
    fig = Fig('l07-two-clocks', 720, 240, {
        'en': 'Two time lines, one above the other, for the same stretch of time. The upper one is UTC '
              'and the lower one São Paulo, three hours behind. An order stamped 02:00 on 2 January in '
              'UTC sits at 23:00 on 1 January in São Paulo: the same instant, on the previous day.',
        'pt': 'Duas linhas do tempo, uma acima da outra, para o mesmo trecho de tempo. A de cima é UTC e a '
              'de baixo São Paulo, três horas atrás. Um pedido carimbado 02:00 de 2 de janeiro em UTC fica '
              'às 23:00 de 1º de janeiro em São Paulo: o mesmo instante, no dia anterior.'}[lang])
    x0, x1 = 60, 680
    hours = 18  # from 15:00 UTC on 1 Jan to 09:00 UTC on 2 Jan

    def sx(h):
        return x0 + (x1 - x0) * h / hours
    for y, label, shift in ((70, T['utc'], 0), (170, T['sp'], -3)):
        fig.text(x0, y - 30, label, size=11, anchor='start', weight='600')
        fig.line(x0, y, x1, y, stroke='--paper-dim', width=1.2)
        for h in range(0, hours + 1, 3):
            clock = (15 + h + shift) % 24
            fig.line(sx(h), y - 4, sx(h), y + 4, stroke='--paper-dim', width=1)
            fig.text(sx(h), y + 16, f'{clock:02d}:00', size=9.5, mono=True, fill='--paper-dim')
        mid = 9 - shift  # midnight on this clock
        fig.line(sx(mid), y + 24, sx(mid), y + 40, stroke='--wire', width=1.4, dash='3 2')
        fig.text(sx(mid) - 6, y + 34, T['jan1'], size=9.5, anchor='end', fill='--paper-dim')
        fig.text(sx(mid) + 6, y + 34, T['jan2'], size=9.5, anchor='start', fill='--paper-dim')
    t = 11  # 02:00 UTC
    fig.line(sx(t), 70, sx(t), 170, stroke='--amber', width=1.6, dash='4 3')
    fig.circle(sx(t), 70, 5, fill='--amber')
    fig.circle(sx(t), 170, 5, fill='--amber')
    fig.text(sx(t) + 10, 58, '02:00', size=11, anchor='start', mono=True, fill='--amber')
    fig.text(sx(t) + 10, 158, '23:00', size=11, anchor='start', mono=True, fill='--amber')
    fig.text(sx(t) + 54, 158, T['moved'], size=10, anchor='start', fill='--paper-dim')
    fig.text(sx(t) + 54, 58, T['order'], size=10, anchor='start', fill='--paper-dim')
    cap = {'en': 'Every website order stamped between 00:00 and 02:59 UTC belongs to the evening before on '
                 'the clock its customer used: 1,335 of them in 2025.',
           'pt': 'Todo pedido do site carimbado entre 00:00 e 02:59 UTC pertence à noite anterior no relógio do '
                 'cliente: 1.335 deles em 2025.'}
    return fig, cap[lang]

# @@FIGURES@@



# ------------------------------------------------------------------ main

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
