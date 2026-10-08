# Lesson 18 — dashboard design. The numbers on the cards are the ones `dashboard.py` printed in
# lesson 18's captures.


def tile(f, x, y, w, h, title=None):
    f.rect(x, y, w, h, stroke='--wire', fill='--panel', rx=4, width=1)
    if title:
        f.text(x + 8, y + 12, title, size=8.5, anchor='start', fill='--paper-dim')


def mini_line(f, x, y, w, h, stroke='--phosphor'):
    m = monthly_by_region()
    tot = [sum(m[r][i] for r in H.REGIONS) for i in range(24)]
    lo, hi = min(tot), max(tot)
    f.poly([(x + w * i / 23, y + h - h * (v - lo) / (hi - lo)) for i, v in enumerate(tot)],
           stroke=stroke, width=1.8)


def mini_bars(f, x, y, w, h, fill='--phosphor-dim', stroke='--phosphor'):
    vals = [60.5, 44.8, 30.0, 23.5, 14.6]
    bh = h / len(vals)
    for i, v in enumerate(vals):
        f.bar(x, y + i * bh + 2, w * v / 62, bh - 4, stroke=stroke, fill=fill)


def mini_pie(f, cx, cy, r):
    a = 0
    for v, c in zip((30, 25, 20, 15, 10), ('#E69F00', '#56B4E9', '#009E73', '#F0E442', '#CC79A7')):
        f.wedge(cx, cy, r, a, a + 3.6 * v, fill=c, stroke='--panel', width=1)
        a += 3.6 * v


@figure('l18-before-after', 18)
def l18_before_after(lang):
    w = {'en': dict(
        label='Two dashboard layouts drawn as wireframes. Before: nine tiles of the same size in a '
              'three by three grid, holding a logo, a pie, a gauge, a table, a line, bars, a second '
              'pie, a map and, in the bottom right corner, the total orders. After: a row of three '
              'numbers across the top with the total orders first, a large line chart of orders per '
              'month below them, and a smaller bar chart of growth by region beside it.',
        a='before: nine equal tiles', b='after: an order of importance',
        logo='logo', map='map', table='table', gauge='gauge',
        k=('orders in 2025', 'orders in December', 'median delivery'), trend='Orders per month',
        g='Growth by region',
        cap='Every tile on the left is the same size, so nothing says what matters; the number the '
            'director wanted is in the last place anybody looks. On the right, size and position '
            'say it before a word is read.'),
        'pt': dict(
        label='Dois layouts de painel desenhados como esboços. Antes: nove blocos do mesmo tamanho '
              'numa grade de três por três, com um logotipo, uma pizza, um medidor, uma tabela, uma '
              'linha, barras, uma segunda pizza, um mapa e, no canto de baixo à direita, o total de '
              'pedidos. Depois: uma fileira de três números no topo com o total de pedidos primeiro, '
              'um gráfico de linha grande dos pedidos por mês embaixo deles, e um gráfico de barras '
              'menor do crescimento por região ao lado.',
        a='antes: nove blocos iguais', b='depois: uma ordem de importância',
        logo='logotipo', map='mapa', table='tabela', gauge='medidor',
        k=('pedidos em 2025', 'pedidos em dezembro', 'entrega mediana'), trend='Pedidos por mês',
        g='Alta por região',
        cap='Todos os blocos da esquerda têm o mesmo tamanho, então nada diz o que importa; o número '
            'que a direção queria está no último lugar onde alguém olha. À direita, tamanho e '
            'posição dizem isso antes de qualquer palavra ser lida.')}[lang]
    f = Fig('l18-before-after', 660, 300, w['label'])
    f.text(20, 18, w['a'], size=10.5, anchor='start', weight='600')
    x0, y0, s = 20, 34, 94
    for r in range(3):
        for c in range(3):
            tile(f, x0 + c * (s + 4), y0 + r * (s - 10 + 4), s, s - 10)
    cx = lambda c: x0 + c * (s + 4)
    cy = lambda r: y0 + r * (s - 6)
    f.text(cx(0) + s / 2, cy(0) + 42, w['logo'], size=11, fill='--paper-dim', weight='600')
    mini_pie(f, cx(1) + s / 2, cy(0) + 42, 28)
    f.path(f'M{cx(2) + 20:.1f} {cy(0) + 60:.1f} A27 27 0 0 1 {cx(2) + 74:.1f} {cy(0) + 60:.1f}',
           stroke='--amber', width=6)
    f.text(cx(2) + s / 2, cy(0) + 72, w['gauge'], size=8.5, fill='--paper-dim')
    for i in range(4):
        f.line(cx(0) + 10, cy(1) + 22 + i * 12, cx(0) + s - 10, cy(1) + 22 + i * 12, stroke='--wire',
               width=1)
    f.text(cx(0) + s / 2, cy(1) + 72, w['table'], size=8.5, fill='--paper-dim')
    mini_line(f, cx(1) + 8, cy(1) + 14, s - 16, 56)
    mini_bars(f, cx(2) + 10, cy(1) + 12, s - 20, 60)
    mini_pie(f, cx(0) + s / 2, cy(2) + 42, 28)
    f.text(cx(1) + s / 2, cy(2) + 42, w['map'], size=11, fill='--paper-dim', weight='600')
    f.text(cx(2) + s / 2, cy(2) + 36, '180,682' if lang == 'en' else '180.682', size=13,
           weight='600')
    f.text(cx(2) + s / 2, cy(2) + 56, w['k'][0], size=8, fill='--paper-dim')

    X = 350
    f.text(X, 18, w['b'], size=10.5, anchor='start', weight='600')
    vals = (('180,682', '+25.9%'), ('20,586', '+23.5%'), ('33 min', '14.5% > 45 min'))
    if lang == 'pt':
        vals = (('180.682', '+25,9%'), ('20.586', '+23,5%'), ('33 min', '14,5% > 45 min'))
    for i, ((v, c), label) in enumerate(zip(vals, w['k'])):
        x = X + i * 98
        tile(f, x, 34, 94, 64, label)
        f.text(x + 8, 66, v, size=16 if i == 0 else 13, anchor='start', weight='600')
        f.text(x + 8, 88, c, size=8.5, anchor='start', fill='--paper-dim', mono=True)
    tile(f, X, 104, 192, 172, w['trend'])
    mini_line(f, X + 12, 130, 168, 130)
    tile(f, X + 196, 104, 94, 172, w['g'])
    mini_bars(f, X + 206, 126, 78, 140, fill='--scan', stroke='--paper-dim')
    return f, w['cap']


@figure('l18-eye-path', 18)
def l18_eye_path(lang):
    w = {'en': dict(
        label='A dashboard wireframe with the order in which a reader\'s eye usually travels drawn '
              'over it: first the top left, then across the top to the right, then down to the '
              'large chart on the left, and last the bottom right.',
        steps=('first', 'second', 'third', 'last'),
        cap='Readers of left-to-right languages start at the top left and sweep across before they '
            'go down. The top-left corner is the most valuable space on the screen; the bottom '
            'right is where anything not read ends up.'),
        'pt': dict(
        label='Um esboço de painel com a ordem em que o olho do leitor costuma andar desenhada por '
              'cima: primeiro o canto de cima à esquerda, depois o topo até a direita, depois para '
              'baixo até o gráfico grande à esquerda, e por último o canto de baixo à direita.',
        steps=('primeiro', 'segundo', 'terceiro', 'último'),
        cap='Quem lê línguas da esquerda para a direita começa no canto de cima à esquerda e varre '
            'o topo antes de descer. Esse canto é o espaço mais valioso da tela; o canto de baixo à '
            'direita é para onde vai o que ninguém lê.')}[lang]
    f = Fig('l18-eye-path', 520, 290, w['label'])
    # The tiles are drawn as marks rather than boxes: the path of the eye is meant to cross them.
    for x, y, w_, h in [(20 + i * 162, 20, 156, 64) for i in range(3)] + [(20, 92, 318, 180),
                                                                          (344, 92, 156, 180)]:
        f.bar(x, y, w_, h, stroke='--wire', fill='--panel', width=1)
    pts = [(70, 52), (450, 52), (150, 180), (430, 230)]
    for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
        f.line(xa, ya, xb, yb, stroke='--amber', width=2, dash='6 4', arrow=True)
    for k, ((x, y), s) in enumerate(zip(pts, w['steps'])):
        f.badge(x, y, 13, str(k + 1), size=11)
        f.text(x + 18, y + (16 if k != 1 else 22), s, size=9.5, anchor='start' if k != 1 else 'middle',
               fill='--amber', weight='600')
    return f, w['cap']


@figure('l18-grouping', 18)
def l18_grouping(lang):
    w = {'en': dict(
        label='Six number tiles arranged two ways. On the left, six tiles evenly spaced in a row of '
              'three and a row of three, mixing sales and delivery measures in no order. On the '
              'right, the same six tiles in two groups of three, sales on the left and delivery on '
              'the right, separated by a wider gap and each under its own heading.',
        names=('orders', 'basket', 'median time', 'revenue', 'late share', 'rain days'),
        a='spaced evenly', b='grouped by what they measure', s='Sales', d='Delivery',
        cap='The eye groups what is close together. Spacing evenly says six unrelated things; two '
            'clusters with a heading each say two subjects of three numbers.'),
        'pt': dict(
        label='Seis blocos de números arrumados de dois jeitos. À esquerda, seis blocos com o mesmo '
              'espaço entre si, numa fileira de três e outra de três, misturando medidas de vendas e '
              'de entrega sem ordem. À direita, os mesmos seis blocos em dois grupos de três, vendas '
              'à esquerda e entrega à direita, separados por um vão maior e cada um sob o seu '
              'próprio título.',
        names=('pedidos', 'cesta', 'tempo mediano', 'receita', 'parcela atrasada',
               'dias de chuva'),
        a='espaçados por igual', b='agrupados pelo que medem', s='Vendas', d='Entrega',
        cap='O olho agrupa o que está perto. Espaçar por igual diz seis coisas sem relação; dois '
            'grupos com um título cada dizem dois assuntos de três números.')}[lang]
    f = Fig('l18-grouping', 660, 220, w['label'])
    f.text(20, 18, w['a'], size=10.5, anchor='start', weight='600')
    for i, n in enumerate(w['names']):
        x, y = 20 + (i % 3) * 96, 36 + (i // 3) * 82
        tile(f, x, y, 90, 74, n)
        f.rect(x + 8, y + 32, 50, 14, stroke='--paper', fill='--paper', rx=2, width=1)
    f.text(340, 18, w['b'], size=10.5, anchor='start', weight='600')
    groups = ((w['s'], (0, 1, 3)), (w['d'], (2, 4, 5)))
    for g, (head, idx) in enumerate(groups):
        x0 = 340 + g * 164
        f.text(x0, 44, head, size=10, anchor='start', weight='600', fill='--phosphor')
        f.line(x0, 54, x0 + 150, 54, stroke='--phosphor', width=1.2)
        for j, i in enumerate(idx):
            x, y = x0 + (j % 2) * 78, 62 + (j // 2) * 76
            tile(f, x, y, 72, 70, w['names'][i])
            f.rect(x + 8, y + 32, 44, 14, stroke='--paper', fill='--paper', rx=2, width=1)
    return f, w['cap']


@figure('l18-kpi', 18)
def l18_kpi(lang):
    m = monthly_by_region()
    tot = [sum(m[r][i] for r in H.REGIONS) for i in range(24)]
    w = {'en': dict(
        label='Three versions of a card for orders in 2025, 180,682. The first shows only the '
              'number. The second adds a comparison underneath: up 25.9% on 2024. The third adds a '
              'small line of the 24 monthly totals beneath that, with the last point marked.',
        a='a number', b='and a comparison', c='and the trend', lab='orders in 2025',
        v='180,682', cmp='▲ 25.9% on 2024',
        cap='A number alone cannot be judged: 180,682 is good or bad only against something. The '
            'comparison gives the direction; the small line, a sparkline, shows whether it is a '
            'steady climb or one good month.'),
        'pt': dict(
        label='Três versões de um cartão dos pedidos em 2025, 180.682. O primeiro mostra só o '
              'número. O segundo acrescenta uma comparação embaixo: alta de 25,9% sobre 2024. O '
              'terceiro acrescenta embaixo disso uma linha pequena dos 24 totais mensais, com o '
              'último ponto marcado.',
        a='um número', b='e uma comparação', c='e a tendência', lab='pedidos em 2025',
        v='180.682', cmp='▲ 25,9% sobre 2024',
        cap='Um número sozinho não se julga: 180.682 só é bom ou ruim comparado com algo. A '
            'comparação dá a direção; a linha pequena, uma sparkline, mostra se é uma subida '
            'constante ou um mês bom.')}[lang]
    f = Fig('l18-kpi', 600, 190, w['label'])
    for k, title in enumerate((w['a'], w['b'], w['c'])):
        x = 20 + k * 196
        f.text(x, 18, title, size=10.5, anchor='start', weight='600')
        tile(f, x, 32, 180, 140, w['lab'])
        f.text(x + 12, 70, w['v'], size=24, anchor='start', weight='600')
        if k >= 1:
            f.text(x + 12, 100, w['cmp'], size=10, anchor='start', fill='--phosphor', weight='600')
        if k == 2:
            lo, hi = min(tot), max(tot)
            pts = [(x + 12 + 150 * i / 23, 160 - 36 * (v - lo) / (hi - lo)) for i, v in enumerate(tot)]
            f.poly(pts, stroke='--paper-dim', width=1.4)
            f.circle(*pts[-1], 3, fill='--phosphor')
    return f, w['cap']


@image('l18-layout.svg', 18)
def l18_layout_image():
    f = Fig('l18-layout-image', 600, 340,
            'A dashboard wireframe with no words: a small box with a downward triangle at the top '
            'right, a row of three tiles holding a thick stroke each, the first tile\'s stroke the '
            'largest with a small upward triangle beneath it, a large line chart below on the left '
            'and a smaller bar chart on the right.')
    f.rect(470, 12, 110, 24, stroke='--paper-dim', fill='--panel', rx=3, width=1)
    f.rect(480, 20, 60, 8, stroke='--wire', fill='--wire', rx=2, width=1)
    f.path('M556 20 L568 20 L562 28 Z', stroke='--paper-dim', fill='--paper-dim', width=1)
    for i in range(3):
        x = 20 + i * 190
        f.rect(x, 46, 180, 80, stroke='--wire', fill='--panel', rx=4, width=1)
        f.rect(x + 12, 58, 70, 8, stroke='--wire', fill='--wire', rx=2, width=1)
        f.rect(x + 12, 76, 120 if i == 0 else 80, 22, stroke='--paper', fill='--paper', rx=3,
               width=1)
    f.path('M32 116 L44 116 L38 106 Z', stroke='--phosphor', fill='--phosphor', width=1)
    f.rect(50, 107, 50, 8, stroke='--phosphor', fill='--phosphor', rx=2, width=1)
    f.rect(20, 136, 370, 190, stroke='--wire', fill='--panel', rx=4, width=1)
    mini_line(f, 40, 160, 330, 150)
    f.rect(400, 136, 180, 190, stroke='--wire', fill='--panel', rx=4, width=1)
    mini_bars(f, 414, 160, 150, 150, fill='--scan', stroke='--paper-dim')
    return f
