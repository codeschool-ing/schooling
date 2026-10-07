# Lesson 3 — bar and column charts.


def totals_by_year():
    t = {'2024': {r: 0 for r in H.REGIONS}, '2025': {r: 0 for r in H.REGIONS}}
    for row in H.monthly_orders():
        t[row['month'][:4]][row['region']] += row['orders']
    return t


def hbars(f, p, items, lang, fill='--phosphor-dim', stroke='--phosphor', step=30, h=20,
          top=None, values=True, names=None):
    y0 = p.y0 if top is None else top
    for i, (name, v) in enumerate(items):
        y = y0 + i * step
        f.rect(p.sx(0), y, p.sx(v) - p.sx(0), h, stroke=stroke, fill=fill, rx=1)
        f.text(p.x0 - 8, y + h / 2, (names or {}).get(name, name), size=10, anchor='end')
        if values:
            f.text(p.sx(v) + 5, y + h / 2, num(lang, v), size=9, anchor='start', mono=True,
                   fill='--paper-dim')


@figure('l03-columns-vs-bars', 3)
def l03_columns_vs_bars(lang):
    t = totals_by_year()['2025']
    items = sorted(t.items(), key=lambda kv: kv[1], reverse=True)
    w = {'en': dict(
        label='The same five regional totals drawn as columns and as bars. In the columns on the '
              'left, the region names have to be tilted to fit under the narrow columns and are '
              'read at an angle. In the bars on the right, each name sits level beside its bar.',
        cap='Columns leave the names a column\'s width; bars give them the whole margin. With '
            'more than a handful of categories, or long names, turn the chart on its side.'),
        'pt': dict(
        label='Os mesmos cinco totais regionais desenhados como colunas e como barras. Nas colunas '
              'à esquerda, os nomes das regiões têm de ser inclinados para caber embaixo das '
              'colunas estreitas e são lidos de lado. Nas barras à direita, cada nome fica '
              'na horizontal ao lado da sua barra.',
        cap='As colunas deixam para os nomes a largura de uma coluna; as barras dão a eles a '
            'margem inteira. Com mais de um punhado de categorias, ou nomes longos, deite o '
            'gráfico.')}[lang]
    f = Fig('l03-columns-vs-bars', 660, 260, w['label'])
    p = Plot(f, 50, 20, 270, 180, 0, 5, 0, 80000)
    for i, (name, v) in enumerate(items):
        x = p.x0 + 10 + i * 42
        f.bar(x, p.sy(v), 28, p.y1 - p.sy(v), stroke='--phosphor', fill='--phosphor-dim', rx=1)
        f.text(x + 18, p.y1 + 10, REGION[lang][name], size=9.5, anchor='end', rotate=-40)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    q = Plot(f, 440, 30, 610, 200, 0, 80000, 0, 5)
    hbars(f, q, items, lang, step=32, h=22, values=False, names=REGION[lang])
    f.line(q.x0, 26, q.x0, 190, stroke='--paper-dim', width=1.2)
    return f, w['cap']


@figure('l03-sorted', 3)
def l03_sorted(lang):
    t = totals_by_year()['2025']
    names = REGION[lang]
    alpha = sorted(t.items(), key=lambda kv: names[kv[0]])
    ranked = sorted(t.items(), key=lambda kv: kv[1], reverse=True)
    w = {'en': dict(
        label='Two bar charts of the 2025 regional totals. On the left the regions are in '
              'alphabetical order, Centre-West, North, Northeast, South, Southeast, and the eye '
              'zigzags to rank them. On the right they are sorted from Southeast, the largest, to '
              'North, the smallest, and the ranking is the picture.',
        a='alphabetical', b='sorted by value',
        cap='Alphabetical order helps somebody look a name up and helps nobody compare. Sorted '
            'by value, the chart answers "which is largest, which is second" before it is asked.'),
        'pt': dict(
        label='Dois gráficos de barras dos totais regionais de 2025. À esquerda as regiões estão '
              'em ordem alfabética, Centro-Oeste, Nordeste, Norte, Sudeste, Sul, e o olho '
              'ziguezagueia para ordená-las. À direita estão ordenadas do Sudeste, o maior, ao '
              'Norte, o menor, e o ranking é a própria figura.',
        a='ordem alfabética', b='ordenado pelo valor',
        cap='A ordem alfabética ajuda quem procura um nome e não ajuda ninguém a comparar. '
            'Ordenado pelo valor, o gráfico responde "qual é o maior, qual é o segundo" antes da '
            'pergunta.')}[lang]
    f = Fig('l03-sorted', 660, 230, w['label'])
    for k, (items, title) in enumerate(((alpha, w['a']), (ranked, w['b']))):
        x0 = 110 + k * 330
        p = Plot(f, x0, 40, x0 + 190, 200, 0, 80000, 0, 5)
        f.text(x0 - 90, 16, title, size=10.5, anchor='start', weight='600')
        hbars(f, p, items, lang, step=31, h=21, values=False, names=names)
        f.line(p.x0, 36, p.x0, 196, stroke='--paper-dim', width=1.2)
    return f, w['cap']


@figure('l03-truncated', 3)
def l03_truncated(lang):
    t = totals_by_year()['2025']
    ne, so = t['Northeast'], t['South']
    w = {'en': dict(
        label=f'Two pairs of columns for Northeast, {ne:,}, and South, {so:,}. On the left the '
              f'axis starts at zero and Northeast\'s column is a little taller. On the right the '
              f'axis starts at 34,000 and Northeast\'s column is more than six times as tall as '
              f'South\'s.',
        a='axis from zero', b='axis from 34,000',
        cap='The same two numbers. Northeast had 14% more orders than South; the truncated axis '
            'draws it more than six times as tall, and a column\'s height is what the eye reads.'),
        'pt': dict(
        label=f'Dois pares de colunas para Nordeste, {num("pt", ne)}, e Sul, {num("pt", so)}. À '
              f'esquerda o eixo começa no zero e a coluna do Nordeste é um pouco mais alta. À '
              f'direita o eixo começa em 34.000 e a coluna do Nordeste tem mais de seis vezes a '
              f'altura da do Sul.',
        a='eixo a partir do zero', b='eixo a partir de 34.000',
        cap='Os mesmos dois números. O Nordeste teve 14% mais pedidos que o Sul; o eixo truncado '
            'desenha uma coluna mais de seis vezes mais alta, e é a altura que o olho lê.')}[lang]
    f = Fig('l03-truncated', 600, 270, w['label'])
    for k, (lo, title, ticks) in enumerate(((0, w['a'], range(0, 40001, 10000)),
                                            (34000, w['b'], range(34000, 40001, 2000)))):
        x0 = 90 + k * 300
        p = Plot(f, x0, 40, x0 + 170, 220, 0, 2, lo, 41000)
        p.yaxis(ticks, fmt=lambda v: num(lang, v), size=9)
        f.text(x0 + 85, 18, title, size=10.5, weight='600')
        for i, (name, v) in enumerate((('Northeast', ne), ('South', so))):
            x = x0 + 25 + i * 70
            f.bar(x, p.sy(v), 45, p.y1 - p.sy(v), stroke='--phosphor', fill='--phosphor-dim',
                   rx=1)
            f.text(x + 22, p.y1 + 13, REGION[lang][name], size=9.5)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    return f, w['cap']


@figure('l03-grouped-stacked', 3)
def l03_grouped_stacked(lang):
    t = totals_by_year()
    order = sorted(H.REGIONS, key=lambda r: t['2025'][r], reverse=True)
    w = {'en': dict(
        label='Orders by region in 2024 and 2025, drawn twice. On the left, grouped bars: two '
              'bars per region side by side from one baseline, so each region\'s growth is easy '
              'to see and Northeast passing South is visible. On the right, two stacked bars, '
              'one per year, each split into five regions: the totals, 143,512 and 180,682, are '
              'easy to compare, and only Southeast, at the bottom, can be compared between the '
              'years.',
        a='grouped', b='stacked', y4='2024', y5='2025',
        cap='Grouped bars compare the parts; a stacked bar compares the totals and leaves only '
            'its bottom segment on a common baseline. Choose by which comparison the reader '
            'needs.'),
        'pt': dict(
        label='Pedidos por região em 2024 e 2025, desenhados duas vezes. À esquerda, barras '
              'agrupadas: duas barras por região lado a lado a partir de uma base, então o '
              'crescimento de cada região é fácil de ver e o Nordeste passando o Sul aparece. À '
              'direita, duas barras empilhadas, uma por ano, cada uma dividida nas cinco '
              'regiões: os totais, 143.512 e 180.682, se comparam fácil, e só o Sudeste, embaixo, '
              'se compara entre os anos.',
        a='agrupadas', b='empilhadas', y4='2024', y5='2025',
        cap='Barras agrupadas comparam as partes; uma barra empilhada compara os totais e deixa só '
            'o segmento de baixo sobre uma base comum. Escolha pela comparação de que o leitor '
            'precisa.')}[lang]
    f = Fig('l03-grouped-stacked', 660, 300, w['label'])
    p = Plot(f, 50, 40, 360, 240, 0, 5, 0, 80000)
    p.yaxis(range(0, 80001, 20000), fmt=lambda v: f'{v // 1000}k', size=9)
    f.text(205, 16, w['a'], size=10.5, weight='600')
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for i, r in enumerate(order):
        x = p.x0 + 12 + i * 60
        for k, (y, fill) in enumerate((('2024', '--phosphor-dim'), ('2025', '--phosphor'))):
            v = t[y][r]
            f.bar(x + k * 22, p.sy(v), 20, p.y1 - p.sy(v), stroke='--phosphor', fill=fill, rx=1)
        f.text(x + 21, p.y1 + 13, REGION[lang][r], size=8.5)
    f.bar(240, 44, 10, 10, stroke='--phosphor', fill='--phosphor-dim', rx=1)
    f.text(255, 49, w['y4'], size=9.5, anchor='start')
    f.bar(295, 44, 10, 10, stroke='--phosphor', fill='--phosphor', rx=1)
    f.text(310, 49, w['y5'], size=9.5, anchor='start')
    q = Plot(f, 440, 40, 580, 240, 0, 2, 0, 190000)
    q.yaxis(range(0, 180001, 60000), fmt=lambda v: f'{v // 1000}k', size=9)
    f.text(510, 16, w['b'], size=10.5, weight='600')
    f.line(q.x0, q.y1, q.x1, q.y1, stroke='--paper-dim', width=1.2)
    shades = ['--phosphor', '--phosphor-dim', '--scan', '--phosphor-dim', '--scan']
    for k, y in enumerate(('2024', '2025')):
        x = q.x0 + 15 + k * 65
        base = 0
        for j, r in enumerate(order):
            v = t[y][r]
            f.bar(x, q.sy(base + v), 40, q.sy(base) - q.sy(base + v), stroke='--phosphor',
                   fill=shades[j], rx=0)
            if k == 1:
                f.text(x + 46, (q.sy(base) + q.sy(base + v)) / 2, REGION[lang][r], size=8.5,
                       anchor='start')
            base += v
        f.text(x + 20, q.y1 + 13, w['y4'] if y == '2024' else w['y5'], size=9.5)
        f.text(x + 20, q.sy(base) - 9, num(lang, base), size=9, mono=True, fill='--paper-dim')
    return f, w['cap']


@image('l03-faults.svg', 3)
def l03_faults():
    f = Fig('l03-faults', 600, 340,
            'A column chart with six columns and no words. The vertical axis is numbered from '
            '34000 to 40000, the columns are separated by gaps, and under each column a tilted '
            'grey stroke stands where a label would be.')
    p = Plot(f, 90, 30, 570, 250, 0, 6, 34000, 40000)
    p.yaxis(range(34000, 40001, 2000), size=10)
    vals = [36200, 39400, 34900, 38100, 35600, 37300]
    for i, v in enumerate(vals):
        x = p.x0 + 18 + i * 78
        f.bar(x, p.sy(v), 50, p.y1 - p.sy(v), stroke='--phosphor', fill='--phosphor-dim', rx=1)
        f.path(f'M{x + 40} {p.y1 + 10} L{x - 6} {p.y1 + 52}', stroke='--paper-dim', width=6,
               cap='round')
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.5)
    return f
