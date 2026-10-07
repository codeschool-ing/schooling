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
