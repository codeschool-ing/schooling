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


# ------------------------------------------------------------------ lesson 8

CATEGORY_MAP = {
    'frutas': ('Frutas', 'Hortifruti'), 'fruta': ('Frutas', 'Hortifruti'), 'fruits': ('Frutas', 'Hortifruti'),
    'verduras': ('Verduras', 'Hortifruti'), 'folhas': ('Verduras', 'Hortifruti'),
    'legumes': ('Legumes', 'Hortifruti'), 'legume': ('Legumes', 'Hortifruti'),
    'ovos e laticinios': ('Ovos e laticínios', 'Frios'), 'laticinios': ('Ovos e laticínios', 'Frios'),
    'graos e cereais': ('Grãos e cereais', 'Mercearia'), 'graos': ('Grãos e cereais', 'Mercearia'),
    'mercearia': ('Mercearia', 'Mercearia'), 'emporio': ('Mercearia', 'Mercearia'),
    'cestas': ('Cestas', 'Cestas'), 'cesta': ('Cestas', 'Cestas'),
}


@figure('l08-three-levels', 8)
def l08_three_levels(lang):
    raw = collections.Counter(r['category'] for r in rows('raw/products.csv'))
    spellings = sorted(raw, key=lambda v: (CATEGORY_MAP[plain(v)][1], CATEGORY_MAP[plain(v)][0], v))
    cats = []
    for v in spellings:
        c = CATEGORY_MAP[plain(v)][0]
        if c not in cats:
            cats.append(c)
    deps = []
    for c in cats:
        d = next(dd for cc, dd in CATEGORY_MAP.values() if cc == c)
        if d not in deps:
            deps.append(d)
    H = 40 + 22 * len(spellings)
    fig = Fig('l08-three-levels', 720, H + 20, {
        'en': f'Three columns joined by lines. On the left, the {len(spellings)} spellings of category in '
              f'products.csv; in the middle, the {len(cats)} categories they mean; on the right, the '
              f'{len(deps)} departments those roll up to. Several spellings run into each category, and '
              'several categories into each department.',
        'pt': f'Três colunas ligadas por linhas. À esquerda, as {len(spellings)} grafias de categoria do '
              f'products.csv; no meio, as {len(cats)} categorias que elas querem dizer; à direita, os '
              f'{len(deps)} departamentos em que elas se agrupam. Várias grafias desembocam em cada '
              'categoria, e várias categorias em cada departamento.'}[lang])
    ys = {v: 40 + 22 * i for i, v in enumerate(spellings)}
    span = 22 * (len(spellings) - 1)
    yc = {c: 40 + span * i / max(1, len(cats) - 1) for i, c in enumerate(cats)}
    yd = {d: 40 + span * i / max(1, len(deps) - 1) for i, d in enumerate(deps)}
    xl, xc, xd = 170, 330, 560
    for v in spellings:
        c = CATEGORY_MAP[plain(v)][0]
        fig.line(xl + 6, ys[v], xc - 6, yc[c], stroke='--wire', width=1.2)
    for c in cats:
        d = next(dd for cc, dd in CATEGORY_MAP.values() if cc == c)
        fig.line(xc + 150, yc[c], xd - 6, yd[d], stroke='--phosphor-dim', width=1.6)
    for v in spellings:
        fig.text(xl, ys[v], '"' + v + '"', size=10.5, anchor='end', mono=True)
    for c in cats:
        fig.text(xc, yc[c], c, size=11, anchor='start', weight='600')
    for d in deps:
        fig.text(xd, yd[d], d, size=11, anchor='start', weight='600', fill='--phosphor')
    lab = {'en': ('as typed', 'category', 'department'), 'pt': ('como digitado', 'categoria', 'departamento')}[lang]
    fig.text(xl, 16, lab[0], size=10, anchor='end', fill='--paper-dim')
    fig.text(xc, 16, lab[1], size=10, anchor='start', fill='--paper-dim')
    fig.text(xd, 16, lab[2], size=10, anchor='start', fill='--paper-dim')
    cap = {'en': 'One file, category_map.csv, holds both arrows: from a spelling to the category it means, and '
                 'from the category to the department it belongs to.',
           'pt': 'Um arquivo, o category_map.csv, guarda as duas setas: da grafia à categoria que ela quer dizer, '
                 'e da categoria ao departamento a que ela pertence.'}
    return fig, cap[lang]


# ------------------------------------------------------------------ lesson 9

@figure('l09-rules-and-truth', 9)
def l09_rules(lang):
    seen, totals = set(), {}
    for r in rows('raw/orders.csv'):
        if r['order_id'] not in seen:
            seen.add(r['order_id'])
            totals[r['order_id']] = float(r['total'])
    marks = {}
    for r in rows('truth/orders.csv'):
        if r['what'] in ('typo-x10', 'corporate'):
            marks[r['order_id']] = r['what']
    vals = sorted(v for v in totals.values() if v > 0)
    n = len(totals)
    mean = sum(totals.values()) / n
    sd = math.sqrt(sum((v - mean) ** 2 for v in totals.values()) / (n - 1))
    allv = sorted(totals.values())
    def q(p):
        k = (len(allv) - 1) * p
        f = math.floor(k)
        return allv[f] + (allv[min(f + 1, len(allv) - 1)] - allv[f]) * (k - f)
    fence = q(0.75) + 1.5 * (q(0.75) - q(0.25))
    zline = mean + 3 * sd
    lo, hi = 1, 5  # log10 of R$ 10 .. R$ 100,000
    edges = [10 ** (lo + (hi - lo) * i / 40) for i in range(41)]
    counts = histogram(vals, edges)
    fig = Fig('l09-rules-and-truth', 720, 340, {
        'en': f'A histogram of order totals on a logarithmic scale from R$ 10 to R$ 100,000, most of them '
              f'between R$ 20 and R$ 300. Two vertical lines mark where the IQR fence ({fence:.2f}) and the '
              f'z-score of 3 ({zline:.2f}) begin. Below the axis, the seven typed totals and the sixteen '
              'corporate orders are marked: the corporate orders sit far right, beyond both lines, and the '
              'typos are scattered, some beyond the lines and some well inside them.',
        'pt': f'Um histograma dos totais de pedido em escala logarítmica de R$ 10 a R$ 100.000, a maioria '
              f'entre R$ 20 e R$ 300. Duas linhas verticais marcam onde começam a cerca do IQR '
              f'({num(lang, fence, 2)}) e o escore z de 3 ({num(lang, zline, 2)}). Abaixo do eixo, os sete '
              'totais digitados e os dezesseis pedidos corporativos estão marcados: os corporativos ficam '
              'bem à direita, além das duas linhas, e os erros se espalham, alguns além das linhas e alguns '
              'bem dentro delas.'}[lang])
    p = Plot(fig, 200, 40, 690, 220, lo, hi, 0, max(counts) * 1.1)
    p.yaxis([0, 1000, 2000, 3000], label={'en': 'orders', 'pt': 'pedidos'}[lang])
    for i, c in enumerate(counts):
        if c:
            x0, x1 = p.sx(math.log10(edges[i])), p.sx(math.log10(edges[i + 1]))
            fig.rect(x0, p.sy(c), x1 - x0, p.sy(0) - p.sy(c), stroke='--phosphor', fill='--phosphor-dim', rx=0, width=0.6)
    fig.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for e in range(lo, hi + 1):
        x = p.sx(e)
        fig.line(x, p.y1, x, p.y1 + 4, stroke='--paper-dim', width=1)
        fig.text(x, p.y1 + 14, 'R$ ' + num(lang, 10 ** e, 0), size=9.5, fill='--paper-dim')
    for v, label, anchor in ((fence, {'en': 'IQR fence', 'pt': 'cerca do IQR'}[lang], 'end'), (zline, 'z = 3', 'start')):
        x = p.sx(math.log10(v))
        fig.line(x, p.y1 + 22, x, 292, stroke='--paper-dim', width=1.4, dash='4 3')
        fig.text(x + (-4 if anchor == 'end' else 4), 302, label, size=10, anchor=anchor, fill='--paper-dim')
    for oid, what in marks.items():
        v = totals[oid]
        y = 258 if what == 'typo-x10' else 280
        fill = '--amber' if what == 'typo-x10' else '--phosphor'
        fig.circle(p.sx(math.log10(v)), y, 4, fill=fill)
    fig.text(190, 258, {'en': 'typed with a zero too many', 'pt': 'digitado com um zero a mais'}[lang], size=10,
             anchor='end', fill='--amber')
    fig.text(190, 280, {'en': 'corporate orders', 'pt': 'pedidos corporativos'}[lang], size=10, anchor='end',
             fill='--phosphor')
    fig.text(445, 326, {'en': 'order total, logarithmic scale', 'pt': 'total do pedido, escala logarítmica'}[lang],
             size=10, weight='600')
    cap = {'en': 'Marked from the lab\'s truth file. Both rules flag every corporate order, which is real, and '
                 'miss some of the typos, which are not.',
           'pt': 'Marcado a partir do arquivo de verdade do laboratório. As duas regras marcam todo pedido '
                 'corporativo, que é real, e deixam passar alguns erros, que não são.'}
    return fig, cap[lang]

# @@FIGURES@@



# ------------------------------------------------------------------ main

# ----------------------------------------------------------------- lesson 11

@figure('l11-fan-out', 11)
def l11_fan_out(lang):
    cat = {}
    for r in rows('raw/products.csv'):
        cat.setdefault(r['product_code'], []).append(r['price'])
    names = {'en': {'00467': 'banana', '00325': 'rocket', '00641': 'cucumber'},
             'pt': {'00467': 'banana', '00325': 'rúcula', '00641': 'pepino'}}[lang]
    picks = [('00467', '2 kg'), ('00325', '1 un'), ('00641', '1 kg')]
    head = {'en': ['order lines', 'catalogue', 'after the join'],
            'pt': ['itens do pedido', 'catálogo', 'depois da junção']}[lang]
    fig = Fig('l11-fan-out', 720, 310, {
        'en': 'Three order lines joined to a catalogue that lists banana and rocket twice, at two prices each. '
              'The banana line and the rocket line each meet two catalogue rows and come out twice; the cucumber '
              'line meets one and comes out once. Three lines go in and five come out.',
        'pt': 'Três itens de pedido juntados a um catálogo que lista banana e rúcula duas vezes, com dois preços '
              'cada. O item de banana e o de rúcula encontram duas linhas do catálogo cada e saem duas vezes; o de '
              'pepino encontra uma e sai uma vez. Entram três itens e saem cinco.'}[lang])
    X = [30, 275, 520]
    W, H, GAP, TOP = 170, 26, 36, 58
    for x, h in zip(X, head):
        fig.text(x + W / 2, 32, h, size=12, weight='600')
    row = 0
    for code, qty in picks:
        prices = sorted(cat[code], key=float)
        ys = [TOP + GAP * (row + i) for i in range(len(prices))]
        mid = (ys[0] + ys[-1]) / 2
        two = len(prices) > 1
        fig.rect(X[0], mid, W, H)
        fig.text(X[0] + 12, mid + H / 2, names[code], size=11, anchor='start')
        fig.text(X[0] + W - 12, mid + H / 2, f'{code} · {qty}', size=10, anchor='end', mono=True,
                 fill='--paper-dim')
        for y, price in zip(ys, prices):
            fig.path(f'M{X[0] + W:.1f} {mid + H / 2:.1f} C{X[0] + W + 40:.1f} {mid + H / 2:.1f} '
                     f'{X[1] - 40:.1f} {y + H / 2:.1f} {X[1] - 2:.1f} {y + H / 2:.1f}',
                     stroke='--amber' if two else '--paper-dim', arrow=True)
            fig.rect(X[1], y, W, H)
            fig.text(X[1] + 12, y + H / 2, code, size=10, anchor='start', mono=True, fill='--paper-dim')
            fig.text(X[1] + W - 12, y + H / 2, num(lang, float(price), 2), size=11, anchor='end', mono=True)
            fig.line(X[1] + W, y + H / 2, X[2] - 2, y + H / 2, stroke='--paper-dim', arrow=True)
            fig.rect(X[2], y, W, H, stroke='--amber' if two else '--wire',
                     fill='--panel')
            fig.text(X[2] + 12, y + H / 2, names[code], size=11, anchor='start')
            fig.text(X[2] + W - 12, y + H / 2, qty, size=10, anchor='end', mono=True, fill='--paper-dim')
        row += len(prices)
    ly = TOP + GAP * row + 22
    fig.rect(X[2], ly - 7, 14, 14, stroke='--amber', fill='--panel', rx=2)
    fig.text(X[2] + 22, ly, {'en': 'one line, counted twice', 'pt': 'um item, contado duas vezes'}[lang],
             size=11, anchor='start')
    fig.text(X[0], ly, {'en': '3 lines in, 5 out', 'pt': 'entram 3 itens, saem 5'}[lang], size=11,
             anchor='start', weight='600')
    cap = {'en': 'A key that repeats on the right copies every line that meets it. Across the year: 99,161 lines '
                 'in, 103,578 out, and R$ 167,603.55 of revenue nobody sold.',
           'pt': 'Uma chave que se repete do lado direito copia todo item que a encontra. No ano: entram 99.161 '
                 'itens, saem 103.578, e R$ 167.603,55 de receita que ninguém vendeu.'}
    return fig, cap[lang]


# ----------------------------------------------------------------- lesson 12

@figure('l12-bin-edges', 12)
def l12_bin_edges(lang):
    fig = Fig('l12-bin-edges', 720, 250, {
        'en': 'Two ways of cutting ages at 18, 25 and 35. With pandas\' default, the bands are (18, 25] and '
              '(25, 35], so an age of exactly 25 falls in the first band. With right=False they are [18, 25) and '
              '[25, 35), so 25 starts the second band, which matches labels such as 18-24 and 25-34.',
        'pt': 'Dois jeitos de cortar idades em 18, 25 e 35. Com o padrão do pandas, as faixas são (18, 25] e '
              '(25, 35], então uma idade de exatamente 25 cai na primeira faixa. Com right=False elas são [18, 25) '
              'e [25, 35), então o 25 abre a segunda faixa, o que combina com rótulos como 18-24 e 25-34.'}[lang])
    sx = lambda v: 170 + (v - 18) / 17 * 350
    rows = [({'en': 'default', 'pt': 'padrão'}[lang], False, 70,
             {'en': '25 falls in the first band', 'pt': 'o 25 cai na primeira faixa'}[lang]),
            ('right=False', True, 160,
             {'en': '25 starts the second band', 'pt': 'o 25 abre a segunda faixa'}[lang])]
    fig.line(sx(25), 30, sx(25), 205, stroke='--paper-dim', dash='4 3', width=1)
    fig.text(sx(25), 22, '25', size=10, mono=True, fill='--paper-dim')
    for label, left_closed, y, note in rows:
        fig.text(20, y, label, size=11, anchor='start', mono=label.startswith('right'), weight='600')
        for k, (a, b) in enumerate([(18, 25), (25, 35)]):
            yy = y - 13 if k == 0 else y + 13
            hit = (k == 1) == left_closed
            col = '--amber' if hit else '--phosphor'
            fig.line(sx(a), yy, sx(b), yy, stroke=col, width=3)
            for v, closed in [(a, left_closed), (b, not left_closed)]:
                fig.circle(sx(v), yy, 5, fill=col if closed else '--panel', stroke=col, width=1.6)
            txt = ('[' if left_closed else '(') + f'{a}, {b}' + (')' if left_closed else ']')
            fig.text((sx(a) + sx(b)) / 2, yy - 12 if k == 0 else yy + 14, txt, size=10, mono=True,
                     fill=col)
        fig.text(545, y, note, size=10.5, anchor='start', fill='--amber')
    fig.line(sx(16), 222, sx(37), 222, stroke='--paper-dim', width=1.2)
    for v in (18, 25, 35):
        fig.line(sx(v), 222, sx(v), 226, stroke='--paper-dim', width=1)
        fig.text(sx(v), 236, str(v), size=9.5, mono=True, fill='--paper-dim')
    cap = {'en': 'A filled end is included and a hollow end is not. The edges are the same; one argument decides '
                 'which side of 25 the 35 customers born in 2000 land on.',
           'pt': 'Uma ponta cheia está incluída e uma vazia não. As bordas são as mesmas; um argumento decide de '
                 'que lado do 25 caem os 35 clientes nascidos em 2000.'}
    return fig, cap[lang]


@figure('l12-log-scale', 12)
def l12_log_scale(lang):
    seen, totals = set(), []
    for r in rows('raw/orders.csv'):
        key = tuple(r.values())
        if key in seen:
            continue
        seen.add(key)
        v = float(r['total'])
        if v > 0:
            totals.append(v)
    fig = Fig('l12-log-scale', 720, 300, {
        'en': f'Two histograms of the {len(totals):,} order totals above zero. In reais, almost every order sits '
              'in the first few bars below R$ 150 and a long thin tail runs to the right. On a base-10 logarithmic '
              'scale the same orders form one roughly symmetrical hump centred near 1.8, about R$ 60.',
        'pt': f'Dois histogramas dos {len(totals):,} totais de pedido acima de zero'.replace(',', '.') +
              '. Em reais, quase todo pedido fica nas primeiras barras abaixo de R$ 150 e uma cauda longa e fina '
              'corre para a direita. Numa escala logarítmica de base 10 os mesmos pedidos formam um só morro, quase '
              'simétrico, centrado perto de 1,8, uns R$ 60.'}[lang])
    e1 = [20 * i for i in range(21)]
    c1 = histogram(totals, e1)
    over = sum(1 for v in totals if v > 400)
    p1 = Plot(fig, 70, 50, 340, 240, 0, 400, 0, max(c1) * 1.1)
    p1.bars(e1, c1)
    p1.xaxis([0, 100, 200, 300, 400], fmt=lambda v: str(v), label={'en': 'total, R$', 'pt': 'total, R$'}[lang])
    p1.yaxis([0, 2000, 4000, 6000], fmt=lambda v: num(lang, v, 0),
             label={'en': 'orders', 'pt': 'pedidos'}[lang])
    fig.text(335, 70, {'en': f'+ {num(lang, over, 0)} above 400', 'pt': f'+ {num(lang, over, 0)} acima de 400'}[lang],
             size=10, anchor='end', fill='--amber')
    e2 = [-0.8 + 0.2 * i for i in range(28)]
    c2 = histogram([math.log10(v) for v in totals], e2)
    p2 = Plot(fig, 420, 50, 690, 240, -0.8, 4.6, 0, max(c2) * 1.1)
    p2.bars(e2, c2)
    p2.xaxis([0, 1, 2, 3, 4], fmt=lambda v: str(v),
             label={'en': 'log10 of total', 'pt': 'log10 do total'}[lang])
    p2.yaxis([0, 2000, 4000, 6000], fmt=lambda v: num(lang, v, 0))
    cap = {'en': 'The same orders, twice. On the right, 1 is R$ 10, 2 is R$ 100 and 3 is R$ 1,000: equal steps '
                 'are equal ratios, and the tail on the left folds into a shape a mean can describe.',
           'pt': 'Os mesmos pedidos, duas vezes. À direita, 1 é R$ 10, 2 é R$ 100 e 3 é R$ 1.000: passos iguais são '
                 'razões iguais, e a cauda da esquerda se dobra num formato que uma média consegue descrever.'}
    return fig, cap[lang]


# ----------------------------------------------------------------- lesson 13

@figure('l13-wide-long', 13)
def l13_wide_long(lang):
    sheet = {r['loja']: r for r in rows('raw/targets_2025.csv')}
    shops = ['Pinheiros', 'Cambuí']
    fig = Fig('l13-wide-long', 720, 290, {
        'en': 'On the left, the targets sheet in wide format: one row per shop, a column per month and a Total '
              'column at the end, drawn in amber. An arrow labelled melt leads to the long format on the right: '
              'one row per shop and month, with columns loja, month and target. The Total column does not '
              'appear in the long table; it is checked against the months and then left behind.',
        'pt': 'À esquerda, a planilha de metas no formato largo: uma linha por loja, uma coluna por mês e uma '
              'coluna Total no fim, desenhada em âmbar. Uma seta com o rótulo melt leva ao formato longo à '
              'direita: uma linha por loja e mês, com as colunas loja, month e target. A coluna Total não aparece '
              'na tabela longa; ela é conferida contra os meses e depois deixada para trás.'}[lang])
    RH, top = 30, 50

    def cell(x, y, w, s, mono=True, head=False, col='--wire', fill='--panel', tcol='--paper'):
        fig.rect(x, y, w, RH, stroke=col, fill=fill, rx=0, width=1)
        fig.text(x + w / 2, y + RH / 2, s, size=10, mono=mono, weight='600' if head else None, fill=tcol)

    cols = [('loja', 82), ('jan/25', 58), ('fev/25', 58), ('…', 30), ('Total', 70)]
    x = 20
    for i, (h, w) in enumerate(cols):
        amber = h == 'Total'
        cell(x, top, w, h, head=True, col='--amber' if amber else '--wire', tcol='--amber' if amber else '--paper')
        for k, s in enumerate(shops):
            v = {'loja': s, 'jan/25': sheet[s]['jan/25'], 'fev/25': sheet[s]['fev/25'], '…': '…',
                 'Total': sheet[s]['Total']}[h]
            cell(x, top + RH * (k + 1), w, v, col='--amber' if amber else '--wire',
                 tcol='--amber' if amber else '--paper')
        x += w
    fig.text(20 + sum(w for _, w in cols) - 35, top + RH * 3 + 18,
             {'en': 'checked, then left behind', 'pt': 'conferido, depois deixado'}[lang], size=10,
             anchor='middle', fill='--amber')
    fig.line(335, top + RH * 1.5, 405, top + RH * 1.5, stroke='--phosphor', width=1.6, arrow=True)
    fig.text(370, top + RH * 1.5 - 12, 'melt', size=10.5, mono=True, fill='--phosphor')
    lcols = [('loja', 92), ('month', 80), ('target', 80)]
    data = [('Pinheiros', '2025-01', sheet['Pinheiros']['jan/25']),
            ('Pinheiros', '2025-02', sheet['Pinheiros']['fev/25']),
            ('…', '…', '…'),
            ('Cambuí', '2025-01', sheet['Cambuí']['jan/25']),
            ('Cambuí', '2025-02', sheet['Cambuí']['fev/25']),
            ('…', '…', '…')]
    x = 420
    for j, (h, w) in enumerate(lcols):
        cell(x, top, w, h, head=True)
        for k, r in enumerate(data):
            cell(x, top + RH * (k + 1), w, r[j])
        x += w
    fig.text(20, top + RH * 3 + 50, {'en': '6 rows × 12 months', 'pt': '6 linhas × 12 meses'}[lang], size=10.5,
             anchor='start', fill='--paper-dim')
    fig.text(420, top + RH * 7 + 22, {'en': '72 rows', 'pt': '72 linhas'}[lang], size=10.5, anchor='start',
             fill='--paper-dim')
    cap = {'en': 'One shape for reading, one for computing. The month leaves the header and becomes a value; the '
                 'Total, which is not a month, does not come along.',
           'pt': 'Um formato para ler, outro para calcular. O mês sai do cabeçalho e vira valor; o Total, que não é '
                 'mês, não vem junto.'}
    return fig, cap[lang]


def attainment_by_shop():
    target = {r['loja']: int(r['Total']) for r in rows('raw/targets_2025.csv')}
    sold = collections.Counter()
    for r in rows('raw/store_sales.csv', encoding='latin-1', delimiter=';'):
        sold[r['loja']] += int(r['total'][3:].replace('.', '').replace(',', ''))
    fixed = {r['order_id']: int(r['value']) for r in rows('truth/orders.csv') if r['what'] == 'typo-x10'}
    seen = set()
    for r in rows('raw/orders.csv'):
        key = tuple(r.values())
        if key in seen or r['status'] != 'delivered':
            continue
        seen.add(key)
        cents = fixed.get(r['order_id'], round(float(r['total']) * 100))
        sold['Online'] += max(cents, 0)
    return {s: sold[s] / 100 / target[s] for s in target}


@figure('l13-attainment', 13)
def l13_attainment(lang):
    att = sorted(attainment_by_shop().items(), key=lambda kv: kv[1])
    fig = Fig('l13-attainment', 720, 280, {
        'en': 'Horizontal bars of each shop\'s sales in 2025 as a share of its target, against a line at 100%: '
              + ', '.join(f'{s} {round(a * 100)}%' for s, a in att) + '. Only Pinheiros is short of the line.',
        'pt': 'Barras horizontais das vendas de cada loja em 2025 como fração da sua meta, contra uma linha em '
              '100%: ' + ', '.join(f'{s} {round(a * 100)}%' for s, a in att) + '. Só Pinheiros fica antes da linha.'}[lang])
    p = Plot(fig, 130, 30, 650, 230, 0, 1.2, 0, len(att))
    for i, (s, a) in enumerate(att):
        y = 40 + i * 31
        fig.text(120, y + 11, s, size=11, anchor='end')
        short = a < 1
        fig.rect(p.sx(0), y, p.sx(a) - p.sx(0), 22, stroke='--amber' if short else '--phosphor',
                 fill='--panel' if short else '--phosphor-dim', rx=2)
        fig.text(p.sx(a) + 6, y + 11, f'{round(a * 100)}%', size=10.5, anchor='start', mono=True)
    x = p.sx(1)
    for i in range(len(att) + 1):
        y0 = 30 if i == 0 else 40 + i * 31 - 8
        y1 = 40 + i * 31 - 1 if i < len(att) else 40 + i * 31 + 14
        fig.line(x, y0, x, y1, stroke='--paper', width=2)
    fig.text(x, 40 + len(att) * 31 + 26, {'en': 'target', 'pt': 'meta'}[lang], size=10, fill='--paper-dim')
    cap = {'en': 'Sales over target for the year, from the sums rather than an average of months. The largest shop '
                 'is the only one short.',
           'pt': 'Vendas sobre meta no ano, pelas somas e não pela média dos meses. A maior loja é a única abaixo.'}
    return fig, cap[lang]


# ----------------------------------------------------------------- lesson 14

@figure('l14-calendar', 14)
def l14_calendar(lang):
    start, end = dt.date(2025, 3, 1), dt.date(2025, 5, 31)
    days = [start + dt.timedelta(n) for n in range((end - start).days + 1)]
    count = collections.Counter()
    for r in rows('raw/store_sales.csv', encoding='latin-1', delimiter=';'):
        d = dt.datetime.strptime(r['data'], '%d/%m/%Y').date()
        if start <= d <= end:
            count[d] += 1
    kind = {dt.date.fromisoformat(r['date']): r['kind'] for r in rows('ref/holidays_2025.csv')}
    fig = Fig('l14-calendar', 720, 300, {
        'en': 'Daily sales across the five shops from March to May 2025, one bar per day. The bars drop to zero '
              'every Sunday and on the three national holidays in the period, Good Friday on 18 April, Tiradentes '
              'on 21 April and Labour Day on 1 May. On the optional days, the two days of Carnival and Ash '
              'Wednesday in early March, the shops sold as usual.',
        'pt': 'Vendas diárias das cinco lojas de março a maio de 2025, uma barra por dia. As barras caem a zero '
              'todo domingo e nos três feriados nacionais do período, a Sexta-feira Santa em 18 de abril, '
              'Tiradentes em 21 de abril e o Dia do Trabalho em 1º de maio. Nos pontos facultativos, os dois dias '
              'de Carnaval e a Quarta-feira de Cinzas no começo de março, as lojas venderam normalmente.'}[lang])
    top = max(count.values()) * 1.12
    p = Plot(fig, 70, 40, 690, 210, 0, len(days), 0, top)
    p.yaxis([0, 50, 100], fmt=lambda v: str(int(v)), label={'en': 'shop sales', 'pt': 'vendas nas lojas'}[lang])
    for i, d in enumerate(days):
        c = count.get(d, 0)
        if c:
            x0, x1 = p.sx(i) + 0.8, p.sx(i + 1) - 0.8
            fig.rect(x0, p.sy(c), x1 - x0, p.y1 - p.sy(c), stroke='--phosphor', fill='--phosphor-dim', rx=0,
                     width=0.6)
        k = kind.get(d)
        if k:
            cx = (p.sx(i) + p.sx(i + 1)) / 2
            fig.circle(cx, p.y1 + 12, 4, fill='--amber' if k == 'holiday' else '--panel', stroke='--amber',
                       width=1.4)
    fig.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    names = {'en': ['March', 'April', 'May'], 'pt': ['março', 'abril', 'maio']}[lang]
    for m, name in zip([3, 4, 5], names):
        i = days.index(dt.date(2025, m, 1))
        fig.line(p.sx(i), p.y1, p.sx(i), p.y1 + 4, stroke='--paper-dim', width=1)
        fig.text(p.sx(i) + 4, p.y1 + 32, name, size=10, anchor='start', fill='--paper-dim')
    ly = 280
    fig.circle(80, ly, 4, fill='--amber', stroke='--amber', width=1.4)
    fig.text(90, ly, {'en': 'national holiday', 'pt': 'feriado nacional'}[lang], size=10.5, anchor='start')
    fig.circle(250, ly, 4, fill='--panel', stroke='--amber', width=1.4)
    fig.text(260, ly, {'en': 'optional day', 'pt': 'ponto facultativo'}[lang], size=10.5, anchor='start')
    cap = {'en': 'Every gap in the bars is a Sunday or a national holiday; every optional day is an ordinary day of '
                 'trade. Without the calendar, the three April and May gaps would be missing data.',
           'pt': 'Toda falha nas barras é um domingo ou um feriado nacional; todo ponto facultativo é um dia normal de '
                 'vendas. Sem o calendário, as três falhas de abril e maio seriam dado faltante.'}
    return fig, cap[lang]


# ----------------------------------------------------------------- lesson 15

def delivered_orders():
    """The delivered orders as lesson 15 reads them: times in São Paulo, decided totals."""
    truth = rows('truth/orders.csv')
    fixed = {r['order_id']: int(r['value']) for r in truth if r['what'] == 'typo-x10'}
    corporate = {r['order_id'] for r in truth if r['what'] == 'corporate'}
    out, seen = [], set()
    for r in rows('raw/orders.csv'):
        key = tuple(r.values())
        if key in seen or r['status'] != 'delivered':
            continue
        seen.add(key)
        if r['channel'] == 'site':
            placed = dt.datetime.strptime(r['ordered_at'], '%Y-%m-%dT%H:%M:%SZ') - dt.timedelta(hours=3)
        else:
            placed = dt.datetime.strptime(r['ordered_at'], '%Y-%m-%d %H:%M:%S')
        cents = max(fixed.get(r['order_id'], round(float(r['total']) * 100)), 0)
        out.append({'id': r['order_id'], 'placed': placed, 'cents': cents,
                    'corporate': r['order_id'] in corporate})
    return out


@figure('l15-hours', 15)
def l15_hours(lang):
    c = collections.Counter(o['placed'].hour for o in delivered_orders())
    hours = sorted(c)
    fig = Fig('l15-hours', 720, 290, {
        'en': 'A bar chart of delivered orders by the hour they were placed, from 7 to 22 o\'clock. The bars rise '
              'to a plateau at 10 and 11, dip after lunch, and rise again to the tallest bar at 19 with '
              f'{c[19]:,} orders. The mean hour, 15, falls in the dip between the two waves.',
        'pt': 'Um gráfico de barras dos pedidos entregues pela hora em que foram feitos, das 7 às 22 horas. As '
              'barras sobem até um platô às 10 e 11, caem depois do almoço e sobem de novo até a barra mais alta, '
              f'às 19, com {num(lang, c[19], 0)} pedidos. A hora média, 15, cai no vale entre as duas ondas.'}[lang])
    p = Plot(fig, 70, 40, 690, 230, hours[0] - 0.5, hours[-1] + 0.5, 0, max(c.values()) * 1.1)
    p.bars([h - 0.5 for h in hours] + [hours[-1] + 0.5], [c[h] for h in hours])
    p.xaxis(hours, fmt=str, label={'en': 'hour of the day', 'pt': 'hora do dia'}[lang])
    p.yaxis([0, 1000, 2000], fmt=lambda v: num(lang, v, 0), label={'en': 'orders', 'pt': 'pedidos'}[lang])
    p.vline(15, label={'en': 'mean hour', 'pt': 'hora média'}[lang], top=52)
    cap = {'en': 'Two waves, before lunch and after dinner. The average hour is arithmetically right and describes '
                 'neither of them.',
           'pt': 'Duas ondas, antes do almoço e depois do jantar. A hora média está certa na aritmética e não '
                 'descreve nenhuma das duas.'}
    return fig, cap[lang]


@figure('l15-months', 15)
def l15_months(lang):
    hh, corp = collections.Counter(), collections.Counter()
    for o in delivered_orders():
        m = o['placed'].month
        (corp if o['corporate'] else hh)[m] += o['cents'] / 100
    months = list(range(1, 13))
    names = {'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
             'pt': ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']}[lang]
    top = max(hh[m] + corp[m] for m in months)
    fig = Fig('l15-months', 720, 300, {
        'en': 'A stacked bar chart of revenue from delivered orders by month in 2025. Household revenue grows from '
              f'about R$ {hh[1] / 1000:.0f} thousand in January to R$ {hh[11] / 1000:.0f} thousand in November and '
              f'R$ {hh[12] / 1000:.0f} thousand in December; the corporate orders, only in December, add about '
              f'R$ {corp[12] / 1000:.0f} thousand on top.',
        'pt': 'Um gráfico de barras empilhadas da receita dos pedidos entregues por mês em 2025. A receita das '
              f'famílias cresce de uns R$ {hh[1] / 1000:.0f} mil em janeiro para R$ {hh[11] / 1000:.0f} mil em '
              f'novembro e R$ {hh[12] / 1000:.0f} mil em dezembro; os pedidos corporativos, só em dezembro, somam '
              f'uns R$ {corp[12] / 1000:.0f} mil por cima.'}[lang])
    p = Plot(fig, 80, 40, 690, 230, 0.5, 12.5, 0, top * 1.08)
    for m in months:
        x0, x1 = p.sx(m - 0.36), p.sx(m + 0.36)
        fig.rect(x0, p.sy(hh[m]), x1 - x0, p.y1 - p.sy(hh[m]), stroke='--phosphor', fill='--phosphor-dim', rx=0,
                 width=1)
        if corp[m]:
            fig.rect(x0, p.sy(hh[m] + corp[m]), x1 - x0, p.sy(hh[m]) - p.sy(hh[m] + corp[m]), stroke='--amber',
                     fill='--panel', rx=0, width=1.4)
    p.yaxis([0, 100000, 200000, 300000, 400000], fmt=lambda v: num(lang, v / 1000, 0) + 'k',
            label={'en': 'revenue, R$', 'pt': 'receita, R$'}[lang], grid=False)
    fig.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for m in months:
        fig.text(p.sx(m), p.y1 + 14, names[m - 1], size=9.5, fill='--paper-dim')
    ly = 278
    fig.rect(90, ly - 6, 12, 12, stroke='--phosphor', fill='--phosphor-dim', rx=0, width=1)
    fig.text(108, ly, {'en': 'households', 'pt': 'famílias'}[lang], size=10.5, anchor='start')
    fig.rect(220, ly - 6, 12, 12, stroke='--amber', fill='--panel', rx=0, width=1.4)
    fig.text(238, ly, {'en': 'corporate', 'pt': 'corporativos'}[lang], size=10.5, anchor='start')
    cap = {'en': 'December is two stories, and the flag from lesson 9 is what keeps them apart.',
           'pt': 'Dezembro são duas histórias, e a marca da aula 9 é o que as mantém separadas.'}
    return fig, cap[lang]


@figure('l15-sugar', 15)
def l15_sugar(lang):
    month = {o['id']: o['placed'].month for o in delivered_orders()}
    prices = collections.defaultdict(set)
    for r in rows('raw/order_items.csv'):
        if r['product_code'].zfill(5) == '00343' and r['order_id'] in month:
            prices[month[r['order_id']]].add(float(r['unit_price']))
    months = list(range(1, 13))
    level = {m: max(prices[m]) for m in months}
    names = {'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
             'pt': ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']}[lang]
    fig = Fig('l15-sugar', 720, 260, {
        'en': f'A step chart of the price charged for a bag of sugar each month of 2025: R$ {level[1]:.2f} from '
              f'January to June, then R$ {level[7]:.2f} from July to December, with no month in between.',
        'pt': f'Um gráfico em degrau do preço cobrado por um pacote de açúcar em cada mês de 2025: R$ '
              f'{num(lang, level[1], 2)} de janeiro a junho, depois R$ {num(lang, level[7], 2)} de julho a dezembro, '
              'sem nenhum mês no meio.'}[lang])
    p = Plot(fig, 80, 40, 690, 200, 0.5, 12.5, 0, 150)
    d = ''
    for m in months:
        y = p.sy(level[m])
        d += (f'M{p.sx(m - 0.5):.1f} {y:.1f}' if m == 1 else f' L{p.sx(m - 0.5):.1f} {y:.1f}') + \
             f' L{p.sx(m + 0.5):.1f} {y:.1f}'
    fig.path(d, stroke='--amber', width=2.4)
    for m in months:
        fig.circle(p.sx(m), p.sy(level[m]), 3.5, fill='--amber')
    p.yaxis([0, 50, 100, 150], fmt=lambda v: str(int(v)), label={'en': 'price, R$', 'pt': 'preço, R$'}[lang])
    fig.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for m in months:
        fig.text(p.sx(m), p.y1 + 14, names[m - 1], size=9.5, fill='--paper-dim')
    fig.text(p.sx(3.5), p.sy(level[1]) - 14, num(lang, level[1], 2), size=10.5, mono=True)
    fig.text(p.sx(9.5), p.sy(level[7]) + 16, num(lang, level[7], 2), size=10.5, mono=True)
    cap = {'en': 'The catalogue typo of lesson 9, as a business user would first meet it: a product whose price '
                 'jumped overnight.',
           'pt': 'O erro de catálogo da aula 9, como alguém do negócio o encontraria primeiro: um produto cujo preço '
                 'saltou da noite para o dia.'}
    return fig, cap[lang]


# ----------------------------------------------------------------- lesson 17

@figure('l17-pipeline', 17)
def l17_pipeline(lang):
    T = {'en': dict(raw='raw files', ro='read-only', man='fingerprints', run='one command',
                    lessons='the lessons\' modules', out='clean tables', ch='change record',
                    chk='checks', git='under version control', disp='rebuilt on every run'),
         'pt': dict(raw='arquivos brutos', ro='só leitura', man='impressões digitais', run='um comando',
                    lessons='os módulos das aulas', out='tabelas limpas', ch='registro de mudanças',
                    chk='verificações', git='sob controle de versão', disp='refeito a cada execução')}[lang]
    fig = Fig('l17-pipeline', 720, 300, {
        'en': 'A diagram of the pipeline. On the left, the raw files, read-only, with their fingerprints in '
              'raw.sha256. An arrow leads to run.py, one command that imports the lessons\' modules. From it, '
              'arrows lead to two outputs in out/: the clean tables and the change record, and checks.py reads the outputs. '
              'A dashed outline around the code, the maps and raw.sha256 marks what is under version control; '
              'the raw files and out/ are outside it.',
        'pt': 'Um diagrama do pipeline. À esquerda, os arquivos brutos, só de leitura, com as suas impressões '
              'digitais em raw.sha256. Uma seta leva ao run.py, um comando que importa os módulos das aulas. '
              'Dele, setas levam a duas saídas em out/: as tabelas limpas e o registro de mudanças, e o checks.py '
              'lê as saídas. Um contorno tracejado em volta do código, dos mapas e do raw.sha256 marca o '
              'que está sob controle de versão; os arquivos brutos e out/ ficam fora dele.'}[lang])

    def box(x, y, w, h, title, sub, mono_title=True, stroke='--wire', fill='--panel'):
        fig.rect(x, y, w, h, stroke=stroke, fill=fill)
        fig.text(x + w / 2, y + h / 2 - 8, title, size=11, mono=mono_title, weight='600')
        fig.text(x + w / 2, y + h / 2 + 10, sub, size=10, fill='--paper-dim')

    fig.path('M188 20 L532 20 Q540 20 540 28 L540 262 Q540 270 532 270 L188 270 Q180 270 180 262 L180 28 '
             'Q180 20 188 20 Z', stroke='--phosphor', dash='5 4')
    fig.text(360, 36, T['git'], size=10.5, fill='--phosphor')
    box(20, 60, 140, 56, 'raw/', T['ro'], stroke='--amber')
    box(200, 60, 140, 56, 'raw.sha256', T['man'])
    box(200, 160, 140, 56, 'run.py', T['run'], stroke='--phosphor')
    box(380, 160, 140, 56, '*.py, *.csv', T['lessons'])
    box(570, 60, 130, 56, 'out/*.csv', T['out'])
    box(570, 160, 130, 56, 'changes.csv', T['ch'])
    box(380, 60, 140, 56, 'checks.py', T['chk'])
    fig.line(160, 88, 198, 88, stroke='--paper-dim', arrow=True)
    fig.path('M90 116 L90 188 L198 188', stroke='--paper-dim', arrow=True)
    fig.line(378, 188, 342, 188, stroke='--paper-dim', arrow=True)
    fig.path('M270 216 L270 245 L635 245 L635 218', stroke='--phosphor', arrow=True)
    fig.path('M300 160 L300 138 L635 138 L635 118', stroke='--phosphor', arrow=True)
    fig.line(568, 88, 522, 88, stroke='--paper-dim', arrow=True)
    fig.text(635, 285, T['disp'], size=10, fill='--paper-dim')
    cap = {'en': 'What is kept and what is rebuilt. Everything inside the dashed line is versioned; the raw files '
                 'are fingerprinted instead, and out/ is thrown away and made again.',
           'pt': 'O que se guarda e o que se reconstrói. Tudo dentro da linha tracejada é versionado; os arquivos '
                 'brutos recebem impressões digitais em vez disso, e o out/ é jogado fora e feito de novo.'}
    return fig, cap[lang]


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
