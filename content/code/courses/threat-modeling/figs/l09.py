"""Lesson 9: likelihood, impact and expected value."""
import csv
import math
import os
from figures import Fig, T, figure, HERE


def risks():
    return list(csv.DictReader(open(os.path.join(HERE, 'lab', 'risks.csv'))))


def money(v):
    s = f'{v:,.0f}'
    return s if T('en', 'pt') == 'en' else s.replace(',', '.')


@figure('l09-map', 9)
def risk_map():
    rs = risks()
    f = Fig('l09-map', 720, 380, T(
        'The nine risks placed by how often they are expected per year, on a logarithmic axis '
        'from 0.01 to 10, and what one event costs, on a logarithmic axis from 1,000 to 1,000,000 '
        'reais. Dashed curves join points of equal expected loss per year: 1,000, 10,000 and '
        '100,000 reais. T03 sits alone near the 100,000 curve. T07, T13, T02 and T14 sit near '
        '10,000. T02 is frequent and cheap; T13 and T14 are rare and expensive.',
        'Os nove riscos posicionados por quantas vezes são esperados por ano, num eixo logarítmico '
        'de 0,01 a 10, e quanto custa um evento, num eixo logarítmico de 1.000 a 1.000.000 de '
        'reais. Curvas tracejadas ligam pontos de igual perda esperada por ano: 1.000, 10.000 e '
        '100.000 reais. A T03 fica sozinha perto da curva de 100.000. T07, T13, T02 e T14 ficam '
        'perto de 10.000. A T02 é frequente e barata; T13 e T14 são raras e caras.'))
    x0, x1, y0, y1 = 90, 690, 20, 320
    lx = lambda v: x0 + (math.log10(v) + 2) / 3 * (x1 - x0)
    ly = lambda v: y1 - (math.log10(v) - 3) / 3 * (y1 - y0)
    f.line(x0, y1, x1, y1, stroke='--paper-dim')
    f.line(x0, y0, x0, y1, stroke='--paper-dim')
    for v, lab in ((0.01, '0.01'), (0.1, '0.1'), (1, '1'), (10, '10')):
        f.line(lx(v), y1, lx(v), y1 + 4, stroke='--paper-dim')
        f.text(lx(v), y1 + 14, lab if T('en', 'pt') == 'en' else lab.replace('.', ','), size=9.5, fill='--paper-dim')
    for v in (1000, 10000, 100000, 1000000):
        f.line(x0 - 4, ly(v), x0, ly(v), stroke='--paper-dim')
        f.text(x0 - 8, ly(v), money(v), size=9.5, anchor='end', fill='--paper-dim')
    f.text((x0 + x1) / 2, y1 + 34, T('events per year (log scale)', 'eventos por ano (escala log)'), size=10, weight='600')
    f.text(x0, 12, T('R$ per event (log scale)', 'R$ por evento (escala log)'), size=10, anchor='start', weight='600')
    for ev in (1000, 10000, 100000):
        pts = []
        for i in range(61):
            fr = 10 ** (-2 + 3 * i / 60)
            loss = ev / fr
            if 1000 <= loss <= 1000000:
                pts.append((lx(fr), ly(loss)))
        f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke='--wire', width=1.2, dash='5 4')
        ex, ey = pts[-1]
        f.text(ex - 4, ey - 8, T(f'R$ {money(ev)} a year', f'R$ {money(ev)} por ano'), size=9, anchor='end', fill='--paper-dim')
    for r in rs:
        x, y = lx(float(r['per_year'])), ly(float(r['loss']))
        f.circle(x, y, 6, fill='--amber' if r['id'] == 'T03' else '--phosphor')
        f.text(x + 9, y - 9, r['id'], size=9.5, anchor='start', weight='600', mono=True)
    return f, T('Expected loss is the product of the two axes, so a risk can sit high on the curve by being frequent or by being expensive. The curve cannot tell you which.',
                'A perda esperada é o produto dos dois eixos, então um risco pode ficar no alto da curva por ser frequente ou por ser caro. A curva não diz qual.')


def poisson(lam, k):
    return math.exp(-lam) * lam ** k / math.factorial(k)


@figure('l09-same-mean', 9)
def same_mean():
    f = Fig('l09-same-mean', 720, 300, T(
        'Two risks with the same expected loss, 9,000 reais a year, as the chance of each yearly '
        'outcome. T02, a patient account taken over, six times a year at 1,500 reais: almost every '
        'year costs between 4,500 and 13,500, and a year with no event has a chance of about 0.2%. '
        'T14, a crafted PDF, once in about thirteen years at 120,000 reais: about 93% of years cost '
        'nothing, about 7% cost 120,000, and two events in one year are rarer still.',
        'Dois riscos com a mesma perda esperada, 9.000 reais por ano, como a chance de cada '
        'resultado anual. T02, conta de paciente tomada, seis vezes por ano a 1.500 reais: quase '
        'todo ano custa entre 4.500 e 13.500, e um ano sem evento tem chance de cerca de 0,2%. '
        'T14, PDF preparado, uma vez a cada uns treze anos a 120.000 reais: cerca de 93% dos anos '
        'não custam nada, cerca de 7% custam 120.000, e dois eventos num ano são mais raros ainda.'))
    panels = [(20, 'T02', 6, 1500, 13), (370, 'T14', 0.075, 120000, 3)]
    for ox, tid, lam, loss, kmax in panels:
        f.text(ox + 165, 18, T(f'{tid}: same R$ 9,000 a year', f'{tid}: os mesmos R$ 9.000 por ano'), size=10.5, weight='600')
        base, top, w = 220, 45, 330
        f.line(ox, base, ox + w, base, stroke='--paper-dim')
        bw = w / (kmax + 1)
        for k in range(kmax + 1):
            p = poisson(lam, k)
            h = (base - top) * p
            x = ox + k * bw
            f.rect(x + 2, base - h, bw - 4, h, stroke=None, fill='--amber' if tid == 'T14' else '--phosphor-dim', rx=1)
            if tid == 'T14' or k % 3 == 0:
                lab = money(k * loss) if k * loss < 1000 or tid == 'T14' else money(k * loss / 1000) + 'k'
                f.text(x + bw / 2, base + 13, lab, size=8.5, fill='--paper-dim')
            if tid == 'T14':
                pct = f'{100 * p:.1f}%' if T('en', 'pt') == 'en' else f'{100 * p:.1f}%'.replace('.', ',')
                f.text(x + bw / 2, base - h - 10, pct, size=9.5, weight='600')
        f.text(ox + w / 2, base + 30, T('R$ lost in one year', 'R$ perdidos em um ano'), size=9.5, fill='--paper-dim')
    f.text(185, 278, T('a cost of doing business', 'um custo de operar'), size=10, fill='--phosphor', italic=True)
    f.text(535, 278, T('a bad year, rarely', 'um ano ruim, raramente'), size=10, fill='--amber', italic=True)
    return f, T('The average is the same and the years are not. One is a budget line; the other is a year somebody has to survive.',
                'A média é a mesma e os anos não são. Um é uma linha do orçamento; o outro é um ano que alguém precisa atravessar.')


@figure('l09-ranges', 9)
def ranges():
    rs = risks()
    f = Fig('l09-ranges', 720, 330, T(
        'For each risk, the team’s 90% range for events per year as a bar on a logarithmic axis, '
        'with the single best guess as a dot. The ranges are wide: T03 from 0.05 to 1 a year, T13 '
        'from 0.01 to 0.25, T02 from 2 to 15. Every dot sits inside its bar.',
        'Para cada risco, a faixa de 90% da equipe para eventos por ano como uma barra num eixo '
        'logarítmico, com o melhor palpite único como um ponto. As faixas são largas: T03 de 0,05 a '
        '1 por ano, T13 de 0,01 a 0,25, T02 de 2 a 15. Todo ponto fica dentro da sua barra.'))
    x0, x1 = 90, 690
    lx = lambda v: x0 + (math.log10(v) + 2) / 3.3 * (x1 - x0)
    for i, r in enumerate(rs):
        y = 24 + i * 30
        f.text(x0 - 12, y, r['id'], size=9.5, anchor='end', weight='600', mono=True)
        a, b, p = float(r['per_year_low']), float(r['per_year_high']), float(r['per_year'])
        f.rect(lx(a), y - 6, lx(b) - lx(a), 12, stroke=None, fill='--phosphor-dim', rx=3)
        f.circle(lx(p), y, 5, fill='--amber')
    yb = 24 + len(rs) * 30
    f.line(x0, yb - 8, x1, yb - 8, stroke='--paper-dim')
    for v, lab in ((0.01, '0.01'), (0.1, '0.1'), (1, '1'), (10, '10')):
        f.line(lx(v), yb - 8, lx(v), yb - 4, stroke='--paper-dim')
        f.text(lx(v), yb + 6, lab if T('en', 'pt') == 'en' else lab.replace('.', ','), size=9.5, fill='--paper-dim')
    f.text((x0 + x1) / 2, yb + 24, T('events per year, 90% range (log scale)', 'eventos por ano, faixa de 90% (escala log)'), size=10, weight='600')
    return f, T('A range says how much the team does not know. A single number hides it, and lesson 10 puts the ranges to work.',
                'Uma faixa diz quanto a equipe não sabe. Um número único esconde isso, e a aula 10 põe as faixas para trabalhar.')
