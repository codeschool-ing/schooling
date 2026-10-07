"""Lesson 11: prioritisation, risk against the cost of mitigation."""
import bisect
import contextlib
import csv
import io
import math
import os
import runpy
import shutil
import sys
import tempfile
from figures import Fig, T, figure, HERE

LAB = os.path.join(HERE, 'lab')


def money(v):
    s = f'{v:,.0f}'
    return s if T('en', 'pt') == 'en' else s.replace(',', '.')


def ranked():
    risks = {r['id']: r for r in csv.DictReader(open(os.path.join(LAB, 'risks.csv')))}
    controls = {}
    for row in csv.DictReader(open(os.path.join(LAB, 'controls.csv'))):
        c = controls.setdefault(row['control'], {'name': row['name'], 'cost': float(row['cost_per_year']), 'cuts': {}})
        c['cuts'][row['risk']] = float(row['reduction'])
    out = []
    for cid, c in controls.items():
        saved = sum(float(risks[r]['per_year']) * float(risks[r]['loss']) * cut for r, cut in c['cuts'].items())
        out.append((saved / c['cost'], cid, c['cost'], saved))
    return sorted(out, reverse=True)


@figure('l11-value', 11)
def value():
    rows = ranked()
    f = Fig('l11-value', 720, 400, T(
        'Each control’s yearly cost against the expected loss it removes on its own, on a '
        'logarithmic scale, sorted by the ratio of the two. C5, the worker’s least-privilege '
        'account, costs 500 and saves 13,500. C1, a second factor for staff, costs 3,000 and saves '
        '60,000. C8 costs 200 and saves 3,600. Down the list the gap narrows, and for C6, the '
        'isolated PDF viewer, the cost of 18,000 is larger than the 7,200 it saves.',
        'O custo anual de cada controle contra a perda esperada que ele remove sozinho, numa '
        'escala logarítmica, em ordem da razão entre os dois. O C5, a conta de mínimo privilégio do '
        'worker, custa 500 e economiza 13.500. O C1, segundo fator para a equipe, custa 3.000 e '
        'economiza 60.000. O C8 custa 200 e economiza 3.600. Descendo a lista a diferença diminui, e '
        'no C6, o visualizador isolado de PDF, o custo de 18.000 é maior que os 7.200 que ele '
        'economiza.'))
    x0, x1 = 90, 600
    lx = lambda v: x0 + (math.log10(v) - 2) / 3 * (x1 - x0)
    for k, (ratio, cid, cost, saved) in enumerate(rows):
        y = 26 + k * 29
        f.text(x0 - 12, y + 9, cid, size=9.5, anchor='end', weight='600', mono=True)
        f.rect(x0, y, lx(saved) - x0, 9, stroke=None, fill='--phosphor', rx=1)
        f.rect(x0, y + 10, lx(cost) - x0, 9, stroke=None, fill='--amber', rx=1)
        r = f'{ratio:.1f}' if T('en', 'pt') == 'en' else f'{ratio:.1f}'.replace('.', ',')
        f.text(700, y + 9, r, size=9.5, anchor='end', weight='600', fill='--paper' if ratio >= 1 else '--amber')
    yb = 26 + len(rows) * 29
    f.line(x0, yb, x1, yb, stroke='--paper-dim')
    for v in (100, 1000, 10000, 100000):
        f.line(lx(v), yb, lx(v), yb + 4, stroke='--paper-dim')
        f.text(lx(v), yb + 15, money(v), size=9.5, fill='--paper-dim')
    f.text(700, 14, T('saved/cost', 'econ./custo'), size=9.5, anchor='end', fill='--paper-dim')
    f.rect(x0, yb + 28, 12, 8, stroke=None, fill='--phosphor', rx=1)
    f.text(x0 + 18, yb + 32, T('R$ a year saved, alone', 'R$ por ano economizados, sozinho'), size=9.5, anchor='start')
    f.rect(x0 + 230, yb + 28, 12, 8, stroke=None, fill='--amber', rx=1)
    f.text(x0 + 248, yb + 32, T('R$ a year it costs', 'R$ por ano que custa'), size=9.5, anchor='start')
    return f, T('Ten of the eleven save more than they cost, when each is judged alone. That last phrase is the subject of the section after next.',
                'Dez dos onze economizam mais do que custam, quando cada um é julgado sozinho. Essa última frase é o assunto da seção depois da próxima.')


@figure('l11-overlap', 11)
def overlap():
    f = Fig('l11-overlap', 720, 270, T(
        'T03’s expected loss as controls are added one after the other. With none: 75,000 reais a '
        'year. After C1, the second factor, which removes 80%: 15,000. After C2, the console on the '
        'clinic network, which removes half of what is left: 7,500. After C11, receptionists '
        'without notes, which removes 30% of what is left: 5,250. On its own, C11 claimed to save '
        '22,500; added last, it saves 2,250, less than its cost of 3,500.',
        'A perda esperada da T03 conforme controles são acrescentados um depois do outro. Sem '
        'nenhum: 75.000 reais por ano. Depois do C1, o segundo fator, que remove 80%: 15.000. '
        'Depois do C2, o console na rede da clínica, que remove metade do que sobrou: 7.500. '
        'Depois do C11, recepcionistas sem anotações, que remove 30% do que sobrou: 5.250. '
        'Sozinho, o C11 dizia economizar 22.500; acrescentado por último, economiza 2.250, menos que '
        'o custo de 3.500.'))
    steps = [(T('no controls', 'nenhum controle'), 75000), (T('+ C1, second factor', '+ C1, segundo fator'), 15000),
             (T('+ C2, clinic network', '+ C2, rede da clínica'), 7500), (T('+ C11, roles', '+ C11, papéis'), 5250)]
    base, top = 210, 30
    h = lambda v: (base - top) * v / 75000
    for k, (label, v) in enumerate(steps):
        x = 40 + k * 170
        if k:
            prev = steps[k - 1][1]
            f.rect(x, base - h(prev), 110, h(prev) - h(v), stroke='--wire', fill='--panel', width=1, rx=2, dash='4 3')
        f.rect(x, base - h(v), 110, h(v), stroke=None, fill='--amber' if k == 0 else '--phosphor-dim', rx=2)
        f.text(x + 55, base - h(v) - 10, f'R$ {money(v)}', size=10, weight='600')
        f.text(x + 55, base + 16, label, size=9.5)
    f.line(30, base, 700, base, stroke='--paper-dim')
    f.text(605, 120, T('C11 alone: R$ 22,500', 'C11 sozinho: R$ 22.500'), size=9.5, fill='--paper-dim')
    f.text(605, 136, T('C11 last: R$ 2,250', 'C11 por último: R$ 2.250'), size=9.5, fill='--amber', weight='600')
    f.text(360, 250, T('T03’s expected loss per year, as controls are added in order', 'perda esperada da T03 por ano, com controles acrescentados em ordem'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('A control is worth what it removes from what is left. Judged alone, C11 was worth ten times more than it is after C1 and C2.',
                'Um controle vale o que ele remove do que sobrou. Julgado sozinho, o C11 valia dez vezes mais do que vale depois do C1 e do C2.')


def simulate(plan):
    tmp = tempfile.mkdtemp()
    try:
        here = os.getcwd()
        os.chdir(LAB)
        argv = sys.argv
        sys.argv = ['prioritise.py'] + plan
        buf = io.StringIO()
        try:
            with contextlib.redirect_stdout(buf):
                if plan:
                    runpy.run_path('prioritise.py')
                else:
                    print(open('risks.csv').read(), end='')
        finally:
            sys.argv = argv
        open(os.path.join(tmp, 'risks.csv'), 'w').write(buf.getvalue())
        os.chdir(tmp)
        with contextlib.redirect_stdout(io.StringIO()):
            g = runpy.run_path(os.path.join(LAB, 'fair.py'))
        os.chdir(here)
        return sorted(g['total'])
    finally:
        shutil.rmtree(tmp)


@figure('l11-curves', 11)
def curves():
    sets = [([], T('today', 'hoje'), '--amber', None),
            (['C5', 'C1', 'C8', 'C4'], T('first four', 'quatro primeiros'), '--phosphor', '5 4'),
            (['C5', 'C1', 'C8', 'C4', 'C3', 'C9', 'C10', 'C7', 'C2'], T('all nine', 'os nove'), '--phosphor', None)]
    f = Fig('l11-curves', 720, 320, T(
        'Three loss exceedance curves on the same axes. Today: 14.1% chance of losing more than '
        '500,000 reais in a year, above daniel’s tolerance point of 10%. With the first four '
        'controls by ratio, costing 5,700 reais a year: 2.7%, below the point. With all nine '
        'controls worth their cost, 17,200 a year: 1.6%.',
        'Três curvas de excedência de perdas nos mesmos eixos. Hoje: 14,1% de chance de perder '
        'mais de 500.000 reais num ano, acima do ponto de tolerância do daniel, de 10%. Com os '
        'quatro primeiros controles pela razão, custando 5.700 reais por ano: 2,7%, abaixo do ponto. '
        'Com todos os nove controles que valem o custo, 17.200 por ano: 1,6%.'))
    x0, x1, y0, y1 = 80, 690, 25, 260
    lx = lambda v: x0 + (math.log10(v) - 4) / (math.log10(3e6) - 4) * (x1 - x0)
    py = lambda p: y1 - p * (y1 - y0)
    f.line(x0, y1, x1, y1, stroke='--paper-dim')
    f.line(x0, y0, x0, y1, stroke='--paper-dim')
    for p in (0, 0.25, 0.5, 0.75, 1):
        f.text(x0 - 8, py(p), f'{int(p * 100)}%', size=9.5, anchor='end', fill='--paper-dim')
        if p:
            f.line(x0, py(p), x1, py(p), stroke='--wire', width=0.8)
    for v in (10_000, 100_000, 1_000_000):
        f.text(lx(v), y1 + 15, money(v), size=9.5, fill='--paper-dim')
    for k, (plan, label, color, dash) in enumerate(sets):
        total = simulate(plan)
        n = len(total)
        pts = []
        for i in range(121):
            v = 10 ** (4 + (math.log10(3e6) - 4) * i / 120)
            pts.append((lx(v), py((n - bisect.bisect_right(total, v)) / n)))
        f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke=color, width=2, dash=dash)
        f.line(520, 60 + k * 18, 550, 60 + k * 18, stroke=color, width=2, dash=dash)
        f.text(558, 60 + k * 18, label, size=9.5, anchor='start')
    f.circle(lx(500_000), py(0.10), 5, fill='--amber')
    f.text(lx(500_000) + 8, py(0.10) - 10, T('tolerance', 'tolerância'), size=9.5, anchor='start', fill='--amber', weight='600')
    f.text((x0 + x1) / 2, y1 + 34, T('total loss in one year, R$ (log scale)', 'perda total em um ano, R$ (escala log)'), size=10, weight='600')
    return f, T('Four controls costing R$ 5,700 a year bring the curve under daniel’s point. The other five are worth their cost too, and are not what meets the appetite.',
                'Quatro controles custando R$ 5.700 por ano trazem a curva para baixo do ponto do daniel. Os outros cinco também valem o custo, e não são eles que atendem o apetite.')


@figure('l11-c1-worth', 11)
def c1_worth():
    m = (lambda v: f'R$ {v:,}') if T('en', 'pt') == 'en' else (lambda v: f'R$ {v:,}'.replace(',', '.'))
    f = Fig('l11-c1-worth', 720, 250, T(
        'What C1, a second factor for staff, is worth on T03. Before it, T03’s expected loss is '
        'R$ 75,000 a year. C1 removes 80% of its frequency, leaving R$ 15,000. The difference, '
        'R$ 60,000 a year, is C1’s value; it costs R$ 3,000 a year, so it saves twenty reais for '
        'each real it costs.',
        'Quanto vale o C1, segundo fator para a equipe, na T03. Antes dele, a perda esperada da T03 é '
        'R$ 75.000 por ano. O C1 remove 80% da frequência, deixando R$ 15.000. A diferença, '
        'R$ 60.000 por ano, é o valor do C1; ele custa R$ 3.000 por ano, então economiza vinte reais '
        'para cada real que custa.'))
    k = 2.2 / 1000
    bars = [(120, 75000, T('T03 before', 'T03 antes'), '--amber'), (300, 15000, T('T03 after C1', 'T03 depois do C1'), '--phosphor-dim')]
    for x, v, lab, c in bars:
        h = v * k
        f.rect(x, 200 - h, 110, h, stroke=None, fill=c, rx=2)
        f.text(x + 55, 200 - h - 12, m(v), size=10.5, weight='600')
        f.text(x + 55, 218, lab, size=9.5, fill='--paper-dim')
    f.rect(300, 200 - 75000 * k, 110, 60000 * k, stroke='--phosphor', fill='--panel', width=1.2, dash='4 3')
    f.text(355, 200 - 45000 * k, T('value', 'valor') + ' ' + m(60000), size=10, weight='600', fill='--phosphor')
    f.rect(500, 200 - 3000 * k, 110, 3000 * k, stroke=None, fill='--paper-dim', rx=1)
    f.text(555, 200 - 3000 * k - 12, m(3000), size=10.5, weight='600')
    f.text(555, 218, T('C1’s cost a year', 'custo do C1 por ano'), size=9.5, fill='--paper-dim')
    f.text(555, 120, T('saved ÷ cost = 20', 'economia ÷ custo = 20'), size=11, weight='600', fill='--phosphor')
    return f, T('A control’s value is the expected loss it removes; its ratio is that value over what it costs, every year.',
                'O valor de um controle é a perda esperada que ele remove; a razão é esse valor sobre o que ele custa, por ano.')
