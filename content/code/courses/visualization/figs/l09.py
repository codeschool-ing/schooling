# Lesson 9 — boxplots, violins and distribution charts.


def quantile(sorted_xs, q):
    """numpy's default: linear interpolation between the two nearest ranks."""
    n = len(sorted_xs)
    pos = (n - 1) * q
    i = int(pos)
    j = min(i + 1, n - 1)
    return sorted_xs[i] + (sorted_xs[j] - sorted_xs[i]) * (pos - i)


def five(xs):
    s = sorted(xs)
    q1, med, q3 = quantile(s, 0.25), quantile(s, 0.5), quantile(s, 0.75)
    iqr = q3 - q1
    lo_f, hi_f = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    inside = [x for x in s if lo_f <= x <= hi_f]
    out = [x for x in s if x < lo_f or x > hi_f]
    return dict(q1=q1, med=med, q3=q3, wlo=inside[0], whi=inside[-1], out=out, iqr=iqr,
                min=s[0], max=s[-1])


def hbox(f, p, y, st, h=22, colour='--phosphor', fill='--phosphor-dim', outliers=True):
    """A horizontal boxplot at height y on plot p."""
    f.line(p.sx(st['wlo']), y, p.sx(st['q1']), y, stroke=colour, width=1.4)
    f.line(p.sx(st['q3']), y, p.sx(st['whi']), y, stroke=colour, width=1.4)
    for v in (st['wlo'], st['whi']):
        f.line(p.sx(v), y - h / 4, p.sx(v), y + h / 4, stroke=colour, width=1.4)
    f.bar(p.sx(st['q1']), y - h / 2, p.sx(st['q3']) - p.sx(st['q1']), h, stroke=colour,
          fill=fill, width=1.4, opacity=0.6)
    f.line(p.sx(st['med']), y - h / 2, p.sx(st['med']), y + h / 2, stroke='--amber', width=2.4)
    if outliers:
        for v in st['out']:
            f.circle(p.sx(v), y, 2.8, fill=None, stroke=colour, width=1.2)


def minutes_by_region():
    g = {r: [] for r in H.REGIONS}
    for r in H.deliveries():
        g[r['region']].append(r['minutes'])
    return g


@figure('l09-anatomy', 9)
def l09_anatomy(lang):
    xs = [r['minutes'] for r in H.deliveries()]
    st = five(xs)
    w = {'en': dict(
        label=f'One horizontal boxplot of the 400 delivery times, with every part named. The box '
              f'runs from the first quartile, 27.0 minutes, to the third, 39.8, with the median at '
              f'33.1 inside it. The whiskers reach from 12.2 on the left to {st["whi"]:.1f} on the '
              f'right, the last delivery within one and a half box lengths of the box. '
              f'{len(st["out"])} slower deliveries are drawn as separate circles, up to 101.3.',
        q1='Q1', med='median', q3='Q3', box='the middle half', wl='whisker', wr='whisker',
        out='beyond the fence', x='delivery time (minutes)',
        cap='Five numbers and a rule. The box holds the middle half of the deliveries, the line '
            'inside it is the median, and anything more than one and a half box lengths out is '
            'drawn on its own.'),
        'pt': dict(
        label=f'Um boxplot horizontal dos 400 tempos de entrega, com cada parte nomeada. A caixa '
              f'vai do primeiro quartil, 27,0 minutos, ao terceiro, 39,8, com a mediana em 33,1 '
              f'dentro dela. Os bigodes vão de 12,2 à esquerda até {num("pt", st["whi"], 1)} à '
              f'direita, a última entrega a menos de uma caixa e meia da caixa. '
              f'{len(st["out"])} entregas mais lentas são desenhadas como círculos separados, até '
              f'101,3.',
        q1='Q1', med='mediana', q3='Q3', box='a metade do meio', wl='bigode', wr='bigode',
        out='além da cerca', x='tempo de entrega (minutos)',
        cap='Cinco números e uma regra. A caixa guarda a metade do meio das entregas, a linha '
            'dentro dela é a mediana, e o que passa de uma caixa e meia para fora é desenhado '
            'sozinho.')}[lang]
    f = Fig('l09-anatomy', 620, 230, w['label'])
    p = Plot(f, 30, 40, 600, 170, 0, 105, 0, 1)
    y = 105
    hbox(f, p, y, st, h=40)
    p.xaxis(range(0, 106, 15), label=w['x'])
    f.text(p.sx(st['q1']), y - 34, w['q1'], size=10, mono=True)
    f.text(p.sx(st['q3']), y - 34, w['q3'], size=10, mono=True)
    f.text(p.sx(st['med']), y + 34, w['med'], size=10, fill='--amber', weight='600')
    f.text((p.sx(st['q1']) + p.sx(st['q3'])) / 2, y - 50, w['box'], size=10, weight='600')
    f.text((p.sx(st['wlo']) + p.sx(st['q1'])) / 2, y - 12, w['wl'], size=9.5, fill='--paper-dim')
    f.text((p.sx(st['q3']) + p.sx(st['whi'])) / 2, y - 12, w['wr'], size=9.5, fill='--paper-dim')
    f.text(p.sx(80), y - 22, w['out'], size=10, fill='--paper-dim')
    return f, w['cap']


def same_box_sets():
    """Two sets of 100 values with the same five numbers: one with a single peak, one with two
    clusters and nothing at all near its median. Positions 24-25, 49-50 and 74-75 are what the
    quartiles and the median are read from, so those are fixed and the rest fill the quarters."""
    def fill(a, b, n, bend):
        return [a + (b - a) * ((k + 0.5) / n) ** bend for k in range(n)]

    def build(mid_lo, mid_hi, tail, inner):
        return ([10.0] + fill(10, 22, 23, tail) + [22.0, 22.0] + inner[0] + [mid_lo, mid_hi] +
                inner[1] + [38.0, 38.0] + [60 - v for v in reversed(fill(10, 22, 23, tail))] +
                [50.0])
    one = build(30.0, 30.0, 0.5, (fill(22, 30, 23, 0.5),
                                  [60 - v for v in reversed(fill(22, 30, 23, 0.5))]))
    two = build(26.0, 34.0, 1.0, (fill(22, 26, 23, 1),
                                  [60 - v for v in reversed(fill(22, 26, 23, 1))]))
    return sorted(one), sorted(two)


@figure('l09-hides', 9)
def l09_hides(lang):
    one, two = same_box_sets()
    w = {'en': dict(
        label='Two groups of 100 values, each drawn as a boxplot with every value as a dot '
              'beneath it. The two boxplots are identical: minimum 10, quartiles 22 and 38, '
              'median 30, maximum 50. Underneath, the first group has one peak around 30, and the '
              'second has two clusters, around 24 and 36, with no value at all between 26 and 34, '
              'right where both boxes put the median.',
        a='group A', b='group B',
        cap='Identical boxes, opposite data. A boxplot summarises five numbers and cannot see a '
            'gap, a second peak or how many values there were. Show the points when there are '
            'few enough to show.'),
        'pt': dict(
        label='Dois grupos de 100 valores, cada um desenhado como boxplot com todo valor como um '
              'ponto embaixo. Os dois boxplots são idênticos: mínimo 10, quartis 22 e 38, mediana '
              '30, máximo 50. Embaixo, o primeiro grupo tem um pico perto de 30, e o segundo tem '
              'dois aglomerados, perto de 24 e de 36, sem valor nenhum entre 26 e 34, justo onde '
              'as duas caixas põem a mediana.',
        a='grupo A', b='grupo B',
        cap='Caixas idênticas, dados opostos. Um boxplot resume cinco números e não enxerga um '
            'vão, um segundo pico nem quantos valores havia. Mostre os pontos quando forem poucos '
            'o bastante para mostrar.')}[lang]
    f = Fig('l09-hides', 600, 260, w['label'])
    p = Plot(f, 80, 20, 580, 240, 5, 55, 0, 1)
    for k, (xs, name) in enumerate(((one, w['a']), (two, w['b']))):
        y = 50 + k * 110
        st = five(xs)
        hbox(f, p, y, st, h=26)
        f.text(70, y + 20, name, size=10.5, anchor='end', weight='600')
        for i, v in enumerate(xs):
            jitter = (((i * 2654435761) % 4294967296) / 4294967296 - 0.5) * 18
            f.circle(p.sx(v), y + 40 + jitter, 2, fill='--phosphor', opacity=0.7)
    for t in range(10, 51, 10):
        f.text(p.sx(t), 250, str(t), size=9, fill='--paper-dim')
    return f, w['cap']


def kde(xs, grid, bw):
    n = len(xs)
    return [sum(math.exp(-0.5 * ((g - x) / bw) ** 2) for x in xs) / (n * bw * math.sqrt(2 * math.pi))
            for g in grid]


@figure('l09-three-views', 9)
def l09_three_views(lang):
    g = minutes_by_region()
    pair = ['Southeast', 'Northeast']
    w = {'en': dict(
        label='Delivery times for Southeast and Northeast drawn three ways, side by side. As '
              'boxplots, Northeast\'s box sits a little to the right of Southeast\'s. As violins, '
              'each group\'s smoothed shape is mirrored around a centre line, and both have one '
              'peak with a long right tail. As strips of dots, every delivery is visible: 147 for '
              'Southeast and 67 for Northeast.',
        a='boxplot', b='violin', c='every point',
        cap='The box gives five numbers, the violin gives the shape, the strip gives everything '
            'and the count. A box on top of a strip, as in the last section, gets most of all '
            'three.'),
        'pt': dict(
        label='Os tempos de entrega do Sudeste e do Nordeste desenhados de três jeitos, lado a '
              'lado. Como boxplots, a caixa do Nordeste fica um pouco à direita da do Sudeste. Como '
              'violinos, a forma suavizada de cada grupo é espelhada em volta de uma linha central, '
              'e os dois têm um pico com uma cauda longa à direita. Como faixas de pontos, toda '
              'entrega aparece: 147 do Sudeste e 67 do Nordeste.',
        a='boxplot', b='violino', c='todos os pontos',
        cap='A caixa dá cinco números, o violino dá a forma, a faixa dá tudo e a contagem. Uma '
            'caixa por cima de uma faixa, como na última seção, pega a maior parte dos três.')}[lang]
    f = Fig('l09-three-views', 660, 250, w['label'])
    grid = [10 + 0.5 * k for k in range(181)]
    for col, title in enumerate((w['a'], w['b'], w['c'])):
        x0 = 100 + col * 192
        p = Plot(f, x0, 40, x0 + 160, 220, 10, 105, 0, 1)
        f.text(x0 + 80, 18, title, size=10.5, weight='600')
        for k, r in enumerate(pair):
            y = 85 + k * 85
            if col == 0:
                f.text(90, y, REGION[lang][r], size=10, anchor='end')
            xs = g[r]
            if col == 0:
                hbox(f, p, y, five(xs), h=24)
            elif col == 1:
                d = kde(xs, grid, 3.0)
                top = max(d)
                upper = [(p.sx(x), y - 26 * v / top) for x, v in zip(grid, d)]
                lower = [(p.sx(x), y + 26 * v / top) for x, v in reversed(list(zip(grid, d)))]
                f.poly(upper + lower + [upper[0]], stroke='--phosphor', fill='--phosphor-dim',
                       width=1.2, opacity=0.6)
                f.line(p.sx(five(xs)['med']), y - 10, p.sx(five(xs)['med']), y + 10,
                       stroke='--amber', width=2)
            else:
                for i, v in enumerate(xs):
                    jitter = (((i * 2654435761) % 4294967296) / 4294967296 - 0.5) * 40
                    f.circle(p.sx(v), y + jitter, 1.8, fill='--phosphor', opacity=0.6)
        for t in (20, 50, 80):
            f.text(p.sx(t), 238, str(t), size=9, fill='--paper-dim')
    return f, w['cap']


@figure('l09-regions', 9)
def l09_regions(lang):
    g = minutes_by_region()
    order = sorted(H.REGIONS, key=lambda r: five(g[r])['med'], reverse=True)
    w = {'en': dict(
        label='Five horizontal boxplots of delivery time, one per region, sorted by median from '
              'Centre-West, 35.5 minutes, to South, 30.8, each with its deliveries drawn faintly '
              'as dots behind the box and its count beside the name. The boxes overlap heavily: '
              'the medians differ by under five minutes, while each region\'s middle half spans '
              'ten to fifteen.',
        x='delivery time (minutes)',
        cap='Sorted by median, with the points behind and the counts beside. The differences '
            'between regions are smaller than the differences inside each one, and the chart '
            'shows both.'),
        'pt': dict(
        label='Cinco boxplots horizontais do tempo de entrega, um por região, ordenados pela '
              'mediana do Centro-Oeste, 35,5 minutos, ao Sul, 30,8, cada um com as suas entregas '
              'desenhadas fracas como pontos atrás da caixa e a contagem ao lado do nome. As '
              'caixas se sobrepõem muito: as medianas diferem menos de cinco minutos, enquanto a '
              'metade do meio de cada região cobre de dez a quinze.',
        x='tempo de entrega (minutos)',
        cap='Ordenados pela mediana, com os pontos atrás e as contagens ao lado. As diferenças '
            'entre as regiões são menores que as diferenças dentro de cada uma, e o gráfico mostra '
            'as duas.')}[lang]
    f = Fig('l09-regions', 620, 300, w['label'])
    p = Plot(f, 150, 20, 600, 240, 10, 105, 0, 1)
    for k, r in enumerate(order):
        y = 45 + k * 42
        xs = g[r]
        for i, v in enumerate(xs):
            jitter = (((i * 2654435761) % 4294967296) / 4294967296 - 0.5) * 22
            f.circle(p.sx(v), y + jitter, 1.6, fill='--paper-dim', opacity=0.5)
        hbox(f, p, y, five(xs), h=20, outliers=False)
        f.text(140, y, f'{REGION[lang][r]} ({len(xs)})', size=10, anchor='end')
    p.xaxis(range(15, 106, 15), label=w['x'])
    return f, w['cap']


@image('l09-box.svg', 9)
def l09_box_image():
    st = five([r['minutes'] for r in H.deliveries()])
    f = Fig('l09-box-image', 600, 220,
            'A horizontal boxplot with no words above a numbered axis: a box with a line inside it, '
            'a whisker to each side, and a row of separate small circles to the right of the right '
            'whisker.')
    p = Plot(f, 30, 30, 570, 170, 0, 105, 0, 1)
    hbox(f, p, 100, st, h=60)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.5)
    for t in range(0, 106, 15):
        f.text(p.sx(t), p.y1 + 18, str(t), size=11, fill='--paper-dim', mono=True)
    return f
