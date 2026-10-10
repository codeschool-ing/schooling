#!/usr/bin/env python3
"""Every diagram in the machine-learning course, drawn from the lab's own files.

A decision boundary drawn by hand is a claim about a model nobody fitted. These
are computed: every point, curve and count comes from the files make_data.py
writes, through the same libraries the lessons pin, so a figure cannot drift
from the transcript beside it.

    sudo bash lab.sh up                          # once: the data, and the libraries
    /home/ana/ml/.venv/bin/python figures.py     # rewrite every figure in the lessons
    /home/ana/ml/.venv/bin/python figures.py NAME ...   # only these
    /home/ana/ml/.venv/bin/python figures.py --list     # the names, and their lessons

It runs as root, with the lab's Python because that is where the libraries are,
and reads the data from ML_DATA, /home/ana/ml/data unless told otherwise.

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

Only palette tokens are used, so each drawing turns over with the theme like
the page around it. Text is never drawn in `--wire` or `--phosphor-dim`, which
do not reach AA on the light panel. The drawing helpers are data-cleaning's,
which were the statistics course's, copied.
"""
import glob
import json
import math
import os
import re
import sys

import numpy as np
import pandas as pd

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.environ.get('ML_DATA', '/home/ana/ml/data')
SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def data(name, **kw):
    return pd.read_csv(os.path.join(DATA, name), **kw)


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


def apply(path, only=()):
    lang = 'pt' if path.endswith('.pt.md') else 'en'
    text = open(path, encoding='utf-8').read()

    def swap_fence(m):
        found = re.search(r'data-fig=\\"([a-z0-9-]+)\\"', m.group(1))
        if not found or found.group(1) not in FIGURES or (only and found.group(1) not in only):
            return m.group(0)
        return render(found.group(1), lang)

    new = FENCE.sub(swap_fence, text)
    new = PLACEHOLDER.sub(lambda m: render(m.group(1), lang), new)
    if new != text:
        open(path, 'w', encoding='utf-8').write(new)
        return True
    return False



def T(lang, en, pt):
    return en if lang == 'en' else pt


# ------------------------------------------------------------------ lesson 1

@figure('l01-four-outcomes', 1)
def l01_four_outcomes(lang):
    fig = Fig('l01-four-outcomes', 620, 300, T(lang,
        'A two by two grid. Columns: what the subscriber did, cancelled or stayed. Rows: what the '
        'model said, cancel or stay. The four cells are true positive, false positive, false '
        'negative and true negative, each with what it means for the R$ 40 credit.',
        'Uma grade dois por dois. Colunas: o que o assinante fez, cancelou ou ficou. Linhas: o que '
        'o modelo disse, cancela ou fica. As quatro células são verdadeiro positivo, falso positivo, '
        'falso negativo e verdadeiro negativo, cada uma com o que significa para o crédito de R$ 40.'))
    x0, y0, w, h = 190, 70, 200, 100
    fig.text(x0 + w, 22, T(lang, 'what the subscriber did', 'o que o assinante fez'), size=11,
             weight='600')
    fig.text(x0 + w / 2, 50, T(lang, 'cancelled', 'cancelou'), size=11)
    fig.text(x0 + 1.5 * w, 50, T(lang, 'stayed', 'ficou'), size=11)
    fig.text(20, 40, T(lang, 'what the model said', 'o que o modelo disse'), size=11,
             anchor='start', weight='600')
    fig.text(x0 - 14, y0 + h / 2, T(lang, 'cancel: credit sent', 'cancela: crédito enviado'),
             size=10.5, anchor='end')
    fig.text(x0 - 14, y0 + 1.5 * h, T(lang, 'stay: no credit', 'fica: sem crédito'),
             size=10.5, anchor='end')
    cells = [
        (0, 0, T(lang, 'true positive', 'verdadeiro positivo'),
         T(lang, 'some are kept: +R$ 104', 'alguns ficam: +R$ 104'), '--phosphor'),
        (1, 0, T(lang, 'false positive', 'falso positivo'),
         T(lang, 'credit wasted: −R$ 40', 'crédito perdido: −R$ 40'), '--amber'),
        (0, 1, T(lang, 'false negative', 'falso negativo'),
         T(lang, 'left, never asked', 'saiu sem ser chamado'), '--amber'),
        (1, 1, T(lang, 'true negative', 'verdadeiro negativo'),
         T(lang, 'nothing happens', 'nada acontece'), '--phosphor'),
    ]
    for c, r, title, sub, stroke in cells:
        x, y = x0 + c * w, y0 + r * h
        fig.rect(x + 4, y + 4, w - 8, h - 8, stroke=stroke, fill='--panel', width=1.6)
        fig.text(x + w / 2, y + h / 2 - 10, title, size=12, weight='600')
        fig.text(x + w / 2, y + h / 2 + 12, sub, size=10.5, fill='--paper-dim')
    cap = T(lang, 'Two ways to be right and two ways to be wrong, and the two wrong ones do not '
                  'cost the same.',
            'Dois jeitos de acertar e dois de errar, e os dois erros não custam o mesmo.')
    return fig, cap


def main():
    if '--list' in sys.argv:
        for name, (lesson, _) in FIGURES.items():
            print(f'{lesson:>3}  {name}')
        return
    only = [a for a in sys.argv[1:] if not a.startswith('-')]
    changed = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        changed += apply(path, only)
    print(f'{len(FIGURES)} figures known, {changed} file(s) rewritten')


if __name__ == '__main__':
    main()
