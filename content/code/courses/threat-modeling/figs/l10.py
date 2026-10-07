"""Lesson 10: FAIR and qualitative matrices."""
import bisect
import contextlib
import csv
import io
import os
import runpy
from figures import Fig, T, figure, HERE


def money(v):
    s = f'{v:,.0f}'
    return s if T('en', 'pt') == 'en' else s.replace(',', '.')


@figure('l10-fair-tree', 10)
def fair_tree():
    f = Fig('l10-fair-tree', 720, 290, T(
        'The FAIR taxonomy as a tree. Risk splits into loss event frequency and loss magnitude. '
        'Loss event frequency splits into threat event frequency, how often somebody tries, and '
        'vulnerability, the chance that a try becomes a loss. Threat event frequency splits into '
        'contact frequency and probability of action. Vulnerability splits into threat capability '
        'and resistance strength. Loss magnitude splits into primary loss, borne directly, and '
        'secondary loss, caused by how others react.',
        'A taxonomia do FAIR como árvore. O risco se divide em frequência de eventos de perda e '
        'magnitude da perda. A frequência de eventos de perda se divide em frequência de eventos '
        'de ameaça, quantas vezes alguém tenta, e vulnerabilidade, a chance de uma tentativa virar '
        'perda. A frequência de eventos de ameaça se divide em frequência de contato e '
        'probabilidade de ação. A vulnerabilidade se divide em capacidade da ameaça e força de '
        'resistência. A magnitude da perda se divide em perda primária, sofrida diretamente, e '
        'perda secundária, causada pela reação dos outros.'))
    def node(x, y, w, rows, c='--paper-dim', bold=False):
        f.rect(x - w / 2, y - 18, w, 36, stroke=c, fill='--panel', width=1.5)
        f.lines(x, y, rows, size=9.5, weight='600' if bold else None, gap=12)
    node(360, 28, 120, [T('risk', 'risco')], '--amber', True)
    node(190, 98, 200, [T('loss event frequency', 'frequência de eventos de perda')], '--phosphor', True)
    node(560, 98, 170, [T('loss magnitude', 'magnitude da perda')], '--phosphor', True)
    node(100, 172, 170, [T('threat event', 'frequência de'), T('frequency', 'eventos de ameaça')])
    node(290, 172, 150, [T('vulnerability', 'vulnerabilidade')])
    node(490, 172, 140, [T('primary loss', 'perda primária')])
    node(640, 172, 140, [T('secondary loss', 'perda secundária')])
    node(52, 252, 96, [T('contact', 'frequência'), T('frequency', 'de contato')])
    node(152, 252, 96, [T('probability', 'probabilidade'), T('of action', 'de ação')])
    node(250, 252, 96, [T('threat', 'capacidade'), T('capability', 'da ameaça')])
    node(350, 252, 96, [T('resistance', 'força de'), T('strength', 'resistência')])
    P = dict(stroke='--paper-dim', width=1.2)
    for a, b in (((360, 46), (190, 80)), ((360, 46), (560, 80)), ((190, 116), (100, 154)), ((190, 116), (290, 154)),
                 ((560, 116), (490, 154)), ((560, 116), (640, 154)), ((100, 190), (52, 234)), ((100, 190), (152, 234)),
                 ((290, 190), (250, 234)), ((290, 190), (350, 234))):
        f.line(*a, *b, **P)
    f.text(560, 240, T('six forms of loss: productivity, response,', 'seis formas de perda: produtividade, resposta,'), size=9.5, fill='--paper-dim')
    f.text(560, 256, T('replacement, fines, competitive advantage,', 'reposição, multas, vantagem competitiva,'), size=9.5, fill='--paper-dim')
    f.text(560, 272, T('reputation', 'reputação'), size=9.5, fill='--paper-dim')
    return f, T('Lesson 9 estimated the top two boxes directly. FAIR lets you estimate any box lower down when the top one is too hard to guess.',
                'A aula 9 estimou direto as duas caixas de cima. O FAIR deixa você estimar qualquer caixa mais abaixo quando a de cima é difícil demais de chutar.')


def simulate():
    here = os.getcwd()
    os.chdir(os.path.join(HERE, 'lab'))
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            g = runpy.run_path('fair.py')
    finally:
        os.chdir(here)
    return g['total']


@figure('l10-exceedance', 10)
def exceedance():
    total = sorted(simulate())
    n = len(total)
    f = Fig('l10-exceedance', 720, 330, T(
        'The loss exceedance curve from the simulation: for each amount on a logarithmic axis '
        'from 10,000 to 3,000,000 reais, the chance that one year’s total loss is larger. The '
        'curve falls from almost 100% at 10,000 through 46.4% at 100,000, 28.1% at 250,000 and '
        '14.1% at 500,000 to 4.8% at 1,000,000. A dashed line marks daniel’s tolerance: no more '
        'than a 10% chance of losing more than 500,000 in a year. The curve passes above that '
        'point.',
        'A curva de excedência de perdas da simulação: para cada valor num eixo logarítmico de '
        '10.000 a 3.000.000 de reais, a chance de a perda total de um ano ser maior. A curva cai de '
        'quase 100% em 10.000, passando por 46,4% em 100.000, 28,1% em 250.000 e 14,1% em 500.000, '
        'até 4,8% em 1.000.000. Uma linha tracejada marca a tolerância do daniel: no máximo 10% de '
        'chance de perder mais de 500.000 num ano. A curva passa acima desse ponto.'))
    import math
    x0, x1, y0, y1 = 80, 690, 25, 270
    lx = lambda v: x0 + (math.log10(v) - 4) / (math.log10(3e6) - 4) * (x1 - x0)
    py = lambda p: y1 - p * (y1 - y0)
    f.line(x0, y1, x1, y1, stroke='--paper-dim')
    f.line(x0, y0, x0, y1, stroke='--paper-dim')
    for p in (0, 0.25, 0.5, 0.75, 1):
        f.line(x0 - 4, py(p), x0, py(p), stroke='--paper-dim')
        if p:
            f.line(x0, py(p), x1, py(p), stroke='--wire', width=0.8)
        f.text(x0 - 8, py(p), f'{int(p * 100)}%', size=9.5, anchor='end', fill='--paper-dim')
    for v in (10_000, 100_000, 1_000_000):
        f.line(lx(v), y1, lx(v), y1 + 4, stroke='--paper-dim')
        f.text(lx(v), y1 + 15, money(v), size=9.5, fill='--paper-dim')
    pts = []
    for i in range(121):
        v = 10 ** (4 + (math.log10(3e6) - 4) * i / 120)
        p = (n - bisect.bisect_right(total, v)) / n
        pts.append((lx(v), py(p)))
    f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke='--phosphor', width=2.2)
    for v in (100_000, 250_000, 500_000, 1_000_000):
        p = (n - bisect.bisect_right(total, v)) / n
        f.circle(lx(v), py(p), 4.5, fill='--phosphor')
        lab = f'{100 * p:.1f}%'
        f.text(lx(v) + 8, py(p) - 10, lab if T('en', 'pt') == 'en' else lab.replace('.', ','), size=9.5, anchor='start', weight='600')
    f.line(lx(500_000), py(0.10), x1, py(0.10), stroke='--amber', width=1.5, dash='5 4')
    f.line(lx(500_000), py(0.10), lx(500_000), y1, stroke='--amber', width=1.5, dash='5 4')
    f.circle(lx(500_000), py(0.10), 4.5, fill='--amber')
    f.text(lx(500_000) - 8, py(0.10) + 14, T('daniel’s tolerance: 10% at R$ 500,000', 'tolerância do daniel: 10% em R$ 500.000'), size=9.5, anchor='end', fill='--amber', weight='600')
    f.text((x0 + x1) / 2, y1 + 36, T('total loss in one year, R$ (log scale)', 'perda total em um ano, R$ (escala log)'), size=10, weight='600')
    f.text(x0, 14, T('chance of losing more', 'chance de perder mais'), size=10, anchor='start', weight='600')
    return f, T('One curve for the whole portfolio. Where it runs above the tolerance point, the business is carrying more risk than it said it would.',
                'Uma curva para o portfólio inteiro. Onde ela passa acima do ponto de tolerância, o negócio está carregando mais risco do que disse que carregaria.')


@figure('l10-matrix', 10)
def matrix():
    risks = list(csv.DictReader(open(os.path.join(HERE, 'lab', 'risks.csv'))))
    LIK, IMP = [0.1, 0.3, 1, 3], [2_000, 10_000, 50_000, 200_000]
    f = Fig('l10-matrix', 720, 360, T(
        'A five by five matrix: likelihood bands across, from rare to almost certain, impact bands '
        'up, from under 2,000 reais to over 200,000. Each cell is coloured by its score, likelihood '
        'times impact. The nine risks sit in their cells: T03 at likelihood 2 and impact 5, score '
        '10; T01 at 3 and 3, score 9; T07 at 2 and 4, score 8; T10 at 3 and 2, score 6; T13 at 1 '
        'and 5 and T02 at 5 and 1, both score 5; T14 at 1 and 4, T08 and T11 at 4 and 1, all score '
        '4.',
        'Uma matriz cinco por cinco: faixas de probabilidade na horizontal, de rara a quase certa, '
        'faixas de impacto na vertical, de menos de 2.000 reais a mais de 200.000. Cada célula tem '
        'a cor da sua nota, probabilidade vezes impacto. Os nove riscos ficam nas suas células: T03 '
        'em probabilidade 2 e impacto 5, nota 10; T01 em 3 e 3, nota 9; T07 em 2 e 4, nota 8; T10 '
        'em 3 e 2, nota 6; T13 em 1 e 5 e T02 em 5 e 1, as duas com nota 5; T14 em 1 e 4, T08 e T11 '
        'em 4 e 1, todas com nota 4.'))
    x0, y0, cw, ch = 170, 20, 100, 52
    cells = {}
    for r in risks:
        l = bisect.bisect_left(LIK, float(r['per_year'])) + 1
        i = bisect.bisect_left(IMP, float(r['loss'])) + 1
        cells.setdefault((l, i), []).append(r['id'])
    for l in range(1, 6):
        for i in range(1, 6):
            score = l * i
            fill = '--amber' if score >= 12 else '--phosphor-dim' if score >= 6 else '--panel'
            x, y = x0 + (l - 1) * cw, y0 + (5 - i) * ch
            f.rect(x + 2, y + 2, cw - 4, ch - 4, stroke='--wire', fill=fill, width=1, rx=2)
            f.text(x + cw - 10, y + 13, str(score), size=8.5, anchor='end', fill='--ink' if score >= 12 else '--paper-dim')
            ids = cells.get((l, i), [])
            for k, rid in enumerate(ids):
                f.text(x + cw / 2, y + ch / 2 + 4 + (k - (len(ids) - 1) / 2) * 13, rid, size=9.5, weight='600', mono=True,
                       fill='--ink' if score >= 12 else '--paper')
    for k, lab in enumerate([T('rare', 'rara'), T('unlikely', 'improvável'), T('possible', 'possível'), T('likely', 'provável'), T('almost certain', 'quase certa')]):
        f.text(x0 + k * cw + cw / 2, y0 + 5 * ch + 14, lab, size=9.5, fill='--paper-dim')
    for k, lab in enumerate([T('< 2k', '< 2 mil'), T('2k to 10k', '2 a 10 mil'), T('10k to 50k', '10 a 50 mil'), T('50k to 200k', '50 a 200 mil'), T('> 200k', '> 200 mil')]):
        f.text(x0 - 10, y0 + (4 - k) * ch + ch / 2, lab, size=9.5, anchor='end', fill='--paper-dim')
    f.text(x0 + 2.5 * cw, y0 + 5 * ch + 34, T('likelihood: events per year, in five bands', 'probabilidade: eventos por ano, em cinco faixas'), size=10, weight='600')
    f.text(20, y0 + 2.5 * ch - 10, T('impact,', 'impacto,'), size=10, anchor='start', weight='600')
    f.text(20, y0 + 2.5 * ch + 6, T('R$ per event', 'R$ por evento'), size=10, anchor='start', weight='600')
    return f, T('The same nine estimates as lesson 9, put through bands. T01 now sits above T07 and T13, and three risks share a score of 4.',
                'As mesmas nove estimativas da aula 9, passadas por faixas. A T01 agora fica acima da T07 e da T13, e três riscos dividem a nota 4.')


@figure('l10-years', 10)
def years():
    totals = simulate()
    n = len(totals)
    mean = sum(totals) / n
    p90 = sorted(totals)[int(0.9 * n)]
    edges = list(range(0, 1_500_001, 100_000))
    counts = [sum(1 for t in totals if lo <= t < lo + 100_000) for lo in edges[:-1]]
    counts.append(sum(1 for t in totals if t >= 1_500_000))
    fmt = (lambda v: f'R$ {v:,.0f}') if T('en', 'pt') == 'en' else (lambda v: f'R$ {v:,.0f}'.replace(',', '.'))
    f = Fig('l10-years', 720, 300, T(
        f'The {n:,} simulated years of fair.py, by total loss in steps of R$ 100,000. Most years '
        f'lose less than R$ 300,000, and the bars fall away to the right with a long tail. The mean '
        f'is {fmt(mean)}; one year in ten loses {fmt(p90)} or more.',
        f'Os {n:,} anos simulados do fair.py, pela perda total em passos de R$ 100.000. A maioria '
        f'dos anos perde menos de R$ 300.000, e as barras caem para a direita com uma cauda longa. A '
        f'média é {fmt(mean)}; um ano em dez perde {fmt(p90)} ou mais.'.replace(f'{n:,}', f'{n:,}'.replace(',', '.'))))
    x0, w, base, top = 60, 40, 210, 30
    peak = max(counts)
    for i, c in enumerate(counts):
        h = c / peak * (base - top)
        f.rect(x0 + i * w, base - h, w - 4, h, stroke=None, fill='--phosphor-dim' if i < 6 else '--amber', rx=1)
    f.line(x0, base, x0 + len(counts) * w, base, stroke='--paper-dim')
    for i in (0, 5, 10):
        f.text(x0 + i * w, base + 14, T(f'{i * 100}k', f'{i * 100} mil'), size=9, fill='--paper-dim')
    f.text(x0 + 15 * w + 18, base + 28, '1.5M+' if T('en', 'pt') == 'en' else '1,5 mi+', size=9, fill='--paper-dim')
    mx = x0 + mean / 100_000 * w
    f.line(mx, base + 22, mx, base + 34, stroke='--paper', width=2)
    f.text(mx, base + 46, T('mean', 'média') + ' ' + fmt(mean), size=9.5)
    px = x0 + p90 / 100_000 * w
    f.line(px, base + 22, px, base + 34, stroke='--amber', width=2)
    f.text(px + 4, base + 46, T('1 year in 10', '1 ano em 10') + ': ' + fmt(p90), size=9.5, anchor='start', fill='--amber')
    f.text(360, 290, T('each bar counts the years whose total fell in that step', 'cada barra conta os anos cujo total caiu naquele passo'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('The average year does not exist: most years cost less than the mean, and a few cost several times more.',
                'O ano médio não existe: a maioria dos anos custa menos que a média, e alguns custam várias vezes mais.')


@figure('l10-compression', 10)
def compression():
    import math
    f = Fig('l10-compression', 720, 210, T(
        'The impact bands of matrix.py on a scale of reais, with their edges at R$ 2,000, 10,000, '
        '50,000 and 200,000. R$ 60,000 and R$ 200,000 both fall in band 4, though one is more than '
        'three times the other.',
        'As faixas de impacto do matrix.py numa escala de reais, com as bordas em R$ 2.000, 10.000, '
        '50.000 e 200.000. R$ 60.000 e R$ 200.000 caem os dois na faixa 4, embora um seja mais de '
        'três vezes o outro.'))
    lo, hi, x0, x1 = 500, 1_000_000, 40, 680
    X = lambda v: x0 + (math.log10(v) - math.log10(lo)) / (math.log10(hi) - math.log10(lo)) * (x1 - x0)
    edges = [lo, 2_000, 10_000, 50_000, 200_000, hi]
    for b in range(5):
        a, z = X(edges[b]), X(edges[b + 1])
        f.rect(a, 60, z - a - 2, 50, stroke=None, fill='--phosphor-dim' if b != 3 else '--phosphor', rx=2)
        f.text((a + z) / 2, 85, T(f'band {b + 1}', f'faixa {b + 1}'), size=10, weight='600')
    for v in edges[1:-1]:
        f.text(X(v), 126, f'{v:,}' if T('en', 'pt') == 'en' else f'{v:,}'.replace(',', '.'), size=9, fill='--paper-dim')
    for v in (60_000, 200_000):
        f.line(X(v) - 1, 40, X(v) - 1, 60, arrow=True, stroke='--amber')
        f.text(X(v) - 1, 30, ('R$ 60,000' if v == 60_000 else 'R$ 200,000') if T('en', 'pt') == 'en' else ('R$ 60.000' if v == 60_000 else 'R$ 200.000'), size=9.5, fill='--amber', weight='600')
    f.text(360, 165, T('the same band, the same score: a matrix cannot see a factor of three inside one cell', 'a mesma faixa, a mesma nota: uma matriz não enxerga um fator de três dentro de uma célula'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('Range compression: everything between two edges is one number, however far apart the values are.',
                'Compressão de faixa: tudo entre duas bordas vira um número, por mais longe que os valores estejam.')
