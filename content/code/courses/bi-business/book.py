#!/usr/bin/env python3
"""What every lesson of bi-business shares: the company, the spreadsheet, the drawing.

The course installs nothing but a spreadsheet. Its practice is typing a small
table into LibreOffice Calc, Google Sheets or Excel and writing the formulas a
lesson shows, and it still quotes several hundred numbers: a share, a margin, a
rate computed two ways, a forecast, a reorder point. None of them is typed by
hand. Each lesson has a file in `sheets/` that lays out the table exactly as the
lesson tells the student to, has LibreOffice Calc recalculate it, prints every
formula beside what Calc returned, and draws the lesson's figures from the same
numbers. `sheet.py` beside this file runs them all.

The data belongs to the course's own example: Varanda Casa & Jardim, an invented
home-and-garden retailer from Belo Horizonte with nine stores and an online
shop. The industry lessons (17 to 21) bring in an invented credit company, an
invented hospital and an invented factory, each defined in its own lesson's
file. Nothing is random, so running this next year prints the same numbers.

Money is Brazilian reais. Standard library and LibreOffice only.
"""
import csv
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LESSONS = os.path.join(HERE, 'lessons')

# ------------------------------------------------------------- the company

COMPANY = 'Varanda Casa & Jardim'

# The nine stores, their sales floor in square metres, and their 2025 sales in
# thousands of reais. The online shop is a channel, not a store, and has no floor.
STORES = [
    ('Savassi', 1800, 11880),
    ('Pampulha', 2400, 10560),
    ('Contagem', 3200, 12480),
    ('Betim', 2600, 8840),
    ('Nova Lima', 1500, 9450),
    ('Sete Lagoas', 2100, 6720),
    ('Divinópolis', 1900, 6460),
    ('Ipatinga', 2200, 7040),
    ('Juiz de Fora', 2800, 8960),
]
ONLINE_2025 = 15610

# The whole company's sales by month, in thousands of reais, both channels.
MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
MONTHS_PT = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez']
SALES_2024 = [6420, 6180, 7050, 7210, 8340, 6990, 6870, 7380, 7640, 8020, 9310, 11290]
SALES_2025 = [6890, 6510, 7420, 7700, 8810, 7330, 7140, 7810, 8150, 7960, 10040, 12240]

assert sum(s for _, _, s in STORES) + ONLINE_2025 == sum(SALES_2025), \
    (sum(s for _, _, s in STORES) + ONLINE_2025, sum(SALES_2025))


# ---------------------------------------------------------- the spreadsheet

# Import: comma-separated, UTF-8, from line 1, and token 13 — evaluate formulas.
IMPORT = 'CSV:44,34,76,1,,1033,false,false,false,false,false,-1,true'
EXPORT = 'csv:Text - txt - csv (StarCalc):44,34,76,1,,1033,false,true,false'


def col(n):
    """0 -> A, 25 -> Z, 26 -> AA."""
    s = ''
    n += 1
    while n:
        n, r = divmod(n - 1, 26)
        s = chr(65 + r) + s
    return s


def cell(ref):
    m = re.fullmatch(r'([A-Z]+)(\d+)', ref)
    c = 0
    for ch in m.group(1):
        c = c * 26 + ord(ch) - 64
    return int(m.group(2)) - 1, c - 1


def calc(rows, show=()):
    """Lay `rows` out from A1, put each formula of `show` in a column of its own
    to the right, have LibreOffice Calc recalculate, and return (grid, shown):
    the recalculated grid as strings, and what each formula in `show` returned.

    Each call gets its own LibreOffice profile, so lessons can be calculated at
    the same time without two instances fighting over one."""
    if not shutil.which('soffice'):
        sys.exit('the sheets need LibreOffice: soffice is not on the PATH')
    rows = [list(r) for r in rows]
    width = max(len(r) for r in rows) if rows else 0
    out_col = width + 1
    for k, f in enumerate(show):
        while len(rows) <= k:
            rows.append([])
        rows[k] += [''] * (out_col - len(rows[k]))
        rows[k].append(f)
    tmp = tempfile.mkdtemp(prefix='bi-business-')
    try:
        src = os.path.join(tmp, 'sheet.csv')
        with open(src, 'w', newline='') as fh:
            csv.writer(fh).writerows(rows)
        out = os.path.join(tmp, 'out')
        subprocess.run(['soffice', f'-env:UserInstallation=file://{tmp}/profile', '--headless',
                        f'--infilter={IMPORT}', '--convert-to', EXPORT, '--outdir', out, src],
                       check=True, capture_output=True)
        with open(os.path.join(out, 'sheet.csv')) as fh:
            grid = list(csv.reader(fh))
    finally:
        shutil.rmtree(tmp)
    shown = [grid[k][out_col] for k in range(len(show))]
    return grid, shown


def report(title, rows, cells=(), show=()):
    """Calculate, print every asked-for cell and formula with what Calc returned,
    and hand back a dict from cell reference or formula to the returned value."""
    grid, shown = calc(rows, show)
    print('--- ' + title)
    got = {}
    for ref in cells:
        r, c = cell(ref)
        src = rows[r][c] if r < len(rows) and c < len(rows[r]) else ''
        got[ref] = grid[r][c]
        print(f'  {ref:<6} {str(src):<52} {grid[r][c]}')
    for f, v in zip(show, shown):
        got[f] = v
        print(f'  {f:<60} {v}')
    return got


# ------------------------------------------------------------- the drawing

SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def esc(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            .replace('"', '&quot;'))


def pick(s, lang):
    """A label is a string (the same in both languages) or an (en, pt) pair."""
    if isinstance(s, tuple):
        return s[0] if lang == 'en' else s[1]
    return s


class Fig:
    """An SVG drawn once and rendered once per language.

    Text is in the prose face unless `mono` is set; only palette tokens are
    used, so the figure turns over with the theme. Text is never drawn in
    `--wire` or `--phosphor-dim`, which do not reach AA on the light panel.
    Bars and lines are paths; a <rect> is a box, and `figure-fit` holds every
    label inside the smallest box around it."""

    def __init__(self, name, w, h, label):
        self.name, self.w, self.h, self.label = name, w, h, label
        self.items = []          # (kind, data)

    def text(self, x, y, s, size=12, anchor='start', fill='--paper', mono=False, weight=None):
        self.items.append(('text', (x, y, s, size, anchor, fill, mono, weight)))

    def rect(self, x, y, w, h, fill='--panel', stroke='--wire', sw=1.5, dash=None):
        self.items.append(('rect', (x, y, w, h, fill, stroke, sw, dash)))

    def path(self, d, stroke='--wire', sw=1.5, fill='none', dash=None):
        self.items.append(('path', (d, stroke, sw, fill, dash)))

    def bar(self, x, y, w, h, fill='--phosphor'):
        """A filled area that is not a box: nothing is measured against it."""
        self.path(f'M{x:.1f} {y:.1f} H{x + w:.1f} V{y + h:.1f} H{x:.1f} Z', stroke='none',
                  sw=0, fill=fill)

    def line(self, x1, y1, x2, y2, stroke='--wire', sw=1.5, dash=None):
        self.path(f'M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}', stroke, sw, dash=dash)

    def arrow(self, x1, y1, x2, y2, stroke='--paper-dim', sw=1.5):
        """A line with a head at (x2, y2)."""
        import math
        self.line(x1, y1, x2, y2, stroke, sw)
        a = math.atan2(y2 - y1, x2 - x1)
        p = [(x2, y2),
             (x2 - 9 * math.cos(a - 0.45), y2 - 9 * math.sin(a - 0.45)),
             (x2 - 9 * math.cos(a + 0.45), y2 - 9 * math.sin(a + 0.45))]
        self.path('M' + ' L'.join(f'{px:.1f} {py:.1f}' for px, py in p) + ' Z',
                  stroke='none', sw=0, fill=stroke)

    def render(self, lang):
        def c(tok):
            return 'none' if tok in (None, 'none') else f'var({tok})'
        out = [f'<svg viewBox="0 0 {self.w} {self.h}" role="img" '
               f'aria-label="{esc(pick(self.label, lang))}" data-fig="{self.name}">']
        same = []
        for kind, d in self.items:
            if kind == 'text':
                x, y, s, size, anchor, fill, mono, weight = d
                t = pick(s, lang)
                if not mono and lang == 'pt' and re.search(r'[A-Za-zÀ-ÿ]', t):
                    if not isinstance(s, tuple) or s[0] == s[1]:
                        same.append(t)
                wt = f' font-weight="{weight}"' if weight else ''
                out.append(f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" '
                           f'font-family="{MONO if mono else SANS}" font-size="{size}"{wt} '
                           f'fill="{c(fill)}">{esc(t)}</text>')
            elif kind == 'rect':
                x, y, w, h, fill, stroke, sw, dash = d
                da = f' stroke-dasharray="{dash}"' if dash else ''
                out.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" '
                           f'fill="{c(fill)}" stroke="{c(stroke)}" stroke-width="{sw}"{da}></rect>')
            else:
                dd, stroke, sw, fill, dash = d
                da = f' stroke-dasharray="{dash}"' if dash else ''
                out.append(f'<path d="{dd}" fill="{c(fill)}" stroke="{c(stroke)}" '
                           f'stroke-width="{sw}"{da}></path>')
        out.append('</svg>')
        return ''.join(out), sorted(set(same))


def place(lesson, fig, caption):
    """Write `fig` into lesson `lesson` (its id), in both languages.

    The fence is found by the `data-fig` it carries, or, the first time, by a
    line reading `@@fig:<name>@@`. Running a sheet twice changes nothing."""
    for lang, suffix in (('en', '.md'), ('pt', '.pt.md')):
        svg, same = fig.render(lang)
        block = {'svg': svg, 'caption': pick(caption, lang)}
        if lang == 'pt' and same:
            block['same'] = same
        fence = '```schooling-figure\n' + json.dumps(block, ensure_ascii=False) + '\n```'
        hit = False
        d = os.path.join(LESSONS, lesson)
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(suffix) or (lang == 'en' and fn.endswith('.pt.md')):
                continue
            p = os.path.join(d, fn)
            text = open(p, encoding='utf-8').read()
            new = text.replace(f'@@fig:{fig.name}@@', fence)
            pat = re.compile(r'```schooling-figure\n[^\n]*data-fig=\\"' + re.escape(fig.name)
                             + r'\\"[^\n]*\n```')
            new = pat.sub(lambda _: fence, new)
            if new != text:
                open(p, 'w', encoding='utf-8').write(new)
            if new != text or fence in text:
                hit = True
        if not hit:
            print(f'  ! figure {fig.name} has no place in {lesson} ({lang})')


def fmt(n, lang='en', dp=0):
    """A number as the lesson prints it: 12,480 in English, 12.480 in Portuguese."""
    s = f'{n:,.{dp}f}'
    if lang == 'pt':
        s = s.replace(',', '§').replace('.', ',').replace('§', '.')
    return s
