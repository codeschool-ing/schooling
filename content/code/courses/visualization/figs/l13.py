# Lesson 13 — meaningful and decorative colour.

DECOR = ['#4f81bd', '#c0504d', '#9bbb59', '#8064a2', '#4bacc6', '#f79646']


def growth_pct():
    t = {'2024': {r: 0 for r in H.REGIONS}, '2025': {r: 0 for r in H.REGIONS}}
    for row in H.monthly_orders():
        t[row['month'][:4]][row['region']] += row['orders']
    return {r: 100 * (t['2025'][r] / t['2024'][r] - 1) for r in H.REGIONS}


@figure('l13-decoration', 13)
def l13_decoration(lang):
    cats = sorted(H.CATEGORIES.items(), key=lambda kv: -kv[1])
    w = {'en': dict(
        label='Two bar charts of revenue by category. On the left every bar has a different '
              'colour, blue, red, green, purple, cyan and orange, though the bars are already '
              'named on the axis. On the right all six bars are one colour.',
        a='a colour per bar', b='one colour',
        cap='The colours on the left say six different things, and there is nothing to say: the '
            'names are on the axis already. Colour that carries no information still asks to be '
            'read.'),
        'pt': dict(
        label='Dois gráficos de barras da receita por categoria. À esquerda cada barra tem uma cor '
              'diferente, azul, vermelho, verde, roxo, ciano e laranja, embora as barras já estejam '
              'nomeadas no eixo. À direita as seis barras têm uma cor só.',
        a='uma cor por barra', b='uma cor só',
        cap='As cores da esquerda dizem seis coisas diferentes, e não há nada a dizer: os nomes já '
            'estão no eixo. Uma cor que não carrega informação ainda pede para ser lida.')}[lang]
    f = Fig('l13-decoration', 640, 240, w['label'])
    for k, title in enumerate((w['a'], w['b'])):
        x0 = 100 + k * 320
        p = Plot(f, x0, 40, x0 + 200, 220, 0, 450, 0, 6)
        f.text(x0 + 60, 18, title, size=10.5, weight='600')
        f.line(p.x0, 34, p.x0, 216, stroke='--paper-dim', width=1.2)
        for i, (name, v) in enumerate(cats):
            y = 40 + i * 30
            fill = DECOR[i] if k == 0 else '--phosphor-dim'
            stroke = DECOR[i] if k == 0 else '--phosphor'
            f.bar(p.sx(0), y, p.sx(v) - p.sx(0), 20, stroke=stroke, fill=fill)
            f.text(p.x0 - 8, y + 10, CATEGORY[lang][name], size=9.5, anchor='end')
    return f, w['cap']


@figure('l13-highlight', 13)
def l13_highlight(lang):
    g = growth_pct()
    order = sorted(H.REGIONS, key=lambda r: -g[r])
    w = {'en': dict(
        label=f'A bar chart of each region\'s growth in orders from 2024 to 2025, sorted from '
              f'North, {g["North"]:.1f}%, to Southeast, {g["Southeast"]:.1f}%. Four bars are '
              f'grey and North\'s is drawn in a strong colour, with its value written beside it.',
        x='growth in orders, 2024 to 2025',
        title='North grew fastest, at four times Southeast\'s rate',
        cap='One colour, used once, tells the reader where to look before they read a word. The '
            'grey bars are still there, as the context that makes North\'s bar mean something.'),
        'pt': dict(
        label=f'Um gráfico de barras do crescimento dos pedidos de cada região de 2024 a 2025, '
              f'ordenado do Norte, {num("pt", g["North"], 1)}%, ao Sudeste, '
              f'{num("pt", g["Southeast"], 1)}%. Quatro barras são cinza e a do Norte está numa cor '
              f'forte, com o valor escrito ao lado.',
        x='crescimento dos pedidos, 2024 a 2025',
        title='O Norte cresceu mais rápido, no quádruplo do ritmo do Sudeste',
        cap='Uma cor, usada uma vez, diz ao leitor para onde olhar antes de ele ler uma palavra. As '
            'barras cinza continuam lá, como o contexto que faz a barra do Norte significar '
            'algo.')}[lang]
    f = Fig('l13-highlight', 600, 250, w['label'])
    p = Plot(f, 120, 50, 520, 210, 0, 70, 0, 5)
    f.text(20, 20, w['title'], size=11, anchor='start', weight='600')
    f.line(p.x0, 44, p.x0, 206, stroke='--paper-dim', width=1.2)
    for i, r in enumerate(order):
        y = 50 + i * 31
        hi = r == 'North'
        f.bar(p.sx(0), y, p.sx(g[r]) - p.sx(0), 22, stroke='--amber' if hi else '--paper-dim',
              fill='--amber' if hi else '--scan')
        f.text(p.x0 - 8, y + 11, REGION[lang][r], size=10, anchor='end',
               fill='--paper' if hi else '--paper-dim', weight='600' if hi else None)
        if hi:
            f.text(p.sx(g[r]) + 6, y + 11, num(lang, g[r], 1) + '%', size=10, anchor='start',
                   fill='--amber', weight='600')
    p.xaxis(range(0, 71, 10), fmt=lambda v: f'{v}%', label=w['x'])
    return f, w['cap']


@figure('l13-consistency', 13)
def l13_consistency(lang):
    t = {'2024': {r: 0 for r in H.REGIONS}, '2025': {r: 0 for r in H.REGIONS}}
    for row in H.monthly_orders():
        t[row['month'][:4]][row['region']] += row['orders']
    regs = ['Southeast', 'Northeast', 'South']
    w = {'en': dict(
        label='Two pairs of small bar charts for three regions, 2024 on the left of each pair and '
              '2025 on the right. In the top pair the colours change between the two charts: '
              'Southeast is blue in the first and orange in the second. In the bottom pair each '
              'region keeps one colour in both charts.',
        a='colours reassigned', b='colours kept',
        cap='A reader learns a colour on the first chart and reads the second with it. Reassign '
            'the colours and the second chart is read wrongly, with confidence.'),
        'pt': dict(
        label='Dois pares de pequenos gráficos de barras de três regiões, 2024 à esquerda de cada '
              'par e 2025 à direita. No par de cima as cores mudam entre os dois gráficos: o '
              'Sudeste é azul no primeiro e laranja no segundo. No par de baixo cada região mantém '
              'uma cor nos dois gráficos.',
        a='cores trocadas', b='cores mantidas',
        cap='O leitor aprende uma cor no primeiro gráfico e lê o segundo com ela. Troque as cores e '
            'o segundo gráfico é lido errado, com confiança.')}[lang]
    cols = {'Southeast': '#0072B2', 'Northeast': '#E69F00', 'South': '#009E73'}
    swapped = {'Southeast': '#E69F00', 'Northeast': '#009E73', 'South': '#0072B2'}
    f = Fig('l13-consistency', 600, 300, w['label'])
    for row, (title, second) in enumerate(((w['a'], swapped), (w['b'], cols))):
        y0 = 40 + row * 140
        f.text(20, y0 - 18, title, size=10.5, anchor='start', weight='600')
        for k, (year, palette) in enumerate((('2024', cols), ('2025', second))):
            x0 = 40 + k * 230
            p = Plot(f, x0, y0, x0 + 200, y0 + 90, 0, 3, 0, 80000)
            f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
            for i, r in enumerate(regs):
                v = t[year][r]
                f.bar(p.sx(i) + 14, p.sy(v), 40, p.y1 - p.sy(v), stroke=palette[r], fill=palette[r])
            f.text(x0 + 100, y0 + 104, year, size=9.5, fill='--paper-dim')
    for i, r in enumerate(regs):
        f.rect(500, 120 + i * 22, 12, 12, stroke=cols[r], fill=cols[r], rx=2, width=1)
        f.text(518, 126 + i * 22, REGION[lang][r], size=9.5, anchor='start')
    return f, w['cap']


@image('l13-highlight.svg', 13)
def l13_highlight_image():
    g = growth_pct()
    order = sorted(H.REGIONS, key=lambda r: -g[r])
    f = Fig('l13-highlight-image', 600, 300,
            'A horizontal bar chart with no words: a thick grey stroke across the top where a '
            'title would be, then five bars, the first in a strong red and the other four in '
            'grey, with a short stroke where a value would be written beside the red bar.')
    f.rect(30, 22, 330, 14, stroke='--paper-dim', fill='--paper-dim', rx=3, width=1)
    p = Plot(f, 110, 70, 560, 270, 0, 70, 0, 5)
    f.line(p.x0, 64, p.x0, 266, stroke='--paper-dim', width=1.5)
    for i, r in enumerate(order):
        y = 70 + i * 40
        hi = r == 'North'
        f.bar(p.sx(0), y, p.sx(g[r]) - p.sx(0), 28, stroke='--amber' if hi else '--paper-dim',
              fill='--amber' if hi else '--scan')
        f.rect(30, y + 9, 66, 10, stroke='--wire', fill='--wire', rx=2, width=1)
    f.rect(p.sx(g['North']) + 8, 79, 40, 10, stroke='--amber', fill='--amber', rx=2, width=1)
    return f
