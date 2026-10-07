# Lesson 16 — charts that mislead.

PIE_ORDER = ['Vegetables', 'Fruit', 'Dairy', 'Bakery', 'Drinks', 'Pantry']
PIE_R, PIE_K, PIE_D = 110, 0.42, 28


def year_totals(region):
    t = {'2024': 0, '2025': 0}
    for row in H.monthly_orders():
        if row['region'] == region:
            t[row['month'][:4]] += row['orders']
    return t['2024'], t['2025']


@figure('l16-truncated', 16)
def l16_truncated(lang):
    a, b = year_totals('Southeast')
    w = {'en': dict(
        label=f'Southeast\'s orders in 2024, {a:,}, and 2025, {b:,}, drawn as two bar charts. On '
              f'the left the axis starts at zero and the 2025 bar is a little taller, as the data '
              f'is 14.6% higher. On the right the axis starts at 65,000 and the 2025 bar is nearly '
              f'five times as tall as the 2024 bar.',
        a='axis from 0', b='axis from 65,000', la='lie factor 1.0', lb='lie factor 25.4',
        cap='The same two numbers. A bar is read by its length, so cutting the bottom off the axis '
            'turns a rise of 14.6% into a bar that looks 372% taller.'),
        'pt': dict(
        label=f'Os pedidos do Sudeste em 2024, {num("pt", a)}, e 2025, {num("pt", b)}, desenhados '
              f'como dois gráficos de barras. À esquerda o eixo começa no zero e a barra de 2025 é '
              f'um pouco mais alta, como o dado é 14,6% maior. À direita o eixo começa em 65.000 e '
              f'a barra de 2025 fica quase cinco vezes mais alta que a de 2024.',
        a='eixo a partir de 0', b='eixo a partir de 65.000', la='fator de mentira 1,0',
        lb='fator de mentira 25,4',
        cap='Os mesmos dois números. Uma barra se lê pelo comprimento, então cortar o pé do eixo '
            'transforma uma alta de 14,6% numa barra que parece 372% mais alta.')}[lang]
    f = Fig('l16-truncated', 620, 260, w['label'])
    for k, (lo, title, lie) in enumerate(((0, w['a'], w['la']), (65000, w['b'], w['lb']))):
        x0 = 80 + k * 300
        p = Plot(f, x0, 50, x0 + 200, 220, 0, 2, lo, 80000)
        ticks = range(0, 80001, 20000) if lo == 0 else range(65000, 80001, 5000)
        p.yaxis(ticks, fmt=lambda v: num(lang, v), size=9)
        f.text(x0 - 60, 18, title, size=10.5, anchor='start', weight='600')
        f.text(x0 - 60, 34, lie, size=9.5, anchor='start',
               fill='--paper-dim' if lo == 0 else '--amber')
        for i, (yr, v) in enumerate((('2024', a), ('2025', b))):
            f.bar(p.sx(i) + 25, p.sy(v), 50, p.y1 - p.sy(v))
            f.text(p.sx(i) + 50, p.y1 + 14, yr, size=9.5, fill='--paper-dim')
            f.text(p.sx(i) + 50, p.sy(v) - 8, num(lang, v), size=9, mono=True)
    return f, w['cap']


@figure('l16-lines', 16)
def l16_lines(lang):
    m = monthly_by_region()
    se = m['Southeast']
    w = {'en': dict(
        label='Southeast\'s monthly orders drawn as a line twice. On the left the axis runs from '
              'zero to 9,000 and the line sits in the top third, its monthly changes squeezed '
              'into a narrow band. On the right the axis runs from 4,000 to 9,000 and the rise '
              'through 2025 and the two December peaks are easy to see.',
        a='axis from 0', b='axis from 4,000', y='orders per month',
        cap='A line is read by its position and its slope, not by its distance from the bottom, so '
            'it may start where the data is. A bar may not.'),
        'pt': dict(
        label='Os pedidos mensais do Sudeste desenhados como linha duas vezes. À esquerda o eixo vai '
              'de zero a 9.000 e a linha fica no terço de cima, com as mudanças de mês espremidas '
              'numa faixa estreita. À direita o eixo vai de 4.000 a 9.000 e a subida ao longo de 2025 e '
              'os dois picos de dezembro ficam fáceis de ver.',
        a='eixo a partir de 0', b='eixo a partir de 4.000', y='pedidos por mês',
        cap='Uma linha se lê pela posição e pela inclinação, não pela distância até o pé, então ela '
            'pode começar onde o dado está. Uma barra não pode.')}[lang]
    f = Fig('l16-lines', 620, 240, w['label'])
    for k, (lo, title) in enumerate(((0, w['a']), (4000, w['b']))):
        x0 = 70 + k * 300
        p = Plot(f, x0, 50, x0 + 220, 210, 0, 23, lo, 9000)
        p.yaxis(range(lo, 9001, 3000 if lo == 0 else 1000), fmt=lambda v: num(lang, v), size=9)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1)
        p.series(range(24), se, width=2.2)
        f.text(x0 - 50, 18, title, size=10.5, anchor='start', weight='600')
    f.text(20, 34, w['y'], size=9, anchor='start', fill='--paper-dim')
    return f, w['cap']


DUAL_RANGES = ((300, 1400), (400, 1700), (0, 2100))


@figure('l16-dual', 16)
def l16_dual(lang):
    m = monthly_by_region()
    ne, no = m['Northeast'], m['North']
    w = {'en': dict(
        label='Northeast and North monthly orders drawn three times on two vertical axes. Northeast '
              'always uses a left scale from 1,500 to 5,000; only North\'s right-hand scale changes. '
              'With North on 300 to 1,400 its line sits above Northeast all along. With 400 to '
              '1,700 it sits below all along. With 0 to 2,100 it starts above and falls below in '
              'early 2025.',
        heads=('North ahead all along', 'North behind all along', 'North falls behind in 2025'),
        right='right axis', ne='Northeast', no='North',
        cap='The same 48 numbers each time. Whoever picks the range of the second axis picks where '
            'the lines cross, and so picks the headline.'),
        'pt': dict(
        label='Os pedidos mensais de Nordeste e Norte desenhados três vezes em dois eixos verticais. '
              'O Nordeste usa sempre uma escala à esquerda de 1.500 a 5.000; só muda a escala do '
              'Norte, à direita. Com o Norte de 300 a 1.400 a linha dele fica acima do Nordeste o '
              'tempo todo. De 400 a 1.700 fica abaixo o tempo todo. De 0 a 2.100 começa acima e cai '
              'para baixo no começo de 2025.',
        heads=('Norte à frente o tempo todo', 'Norte atrás o tempo todo',
               'Norte fica para trás em 2025'),
        right='eixo direito', ne='Nordeste', no='Norte',
        cap='Os mesmos 48 números toda vez. Quem escolhe a faixa do segundo eixo escolhe onde as '
            'linhas se cruzam, e com isso escolhe a manchete.')}[lang]
    f = Fig('l16-dual', 660, 250, w['label'])
    for k, ((lo, hi), head) in enumerate(zip(DUAL_RANGES, w['heads'])):
        x0 = 20 + k * 215
        pl = Plot(f, x0 + 10, 50, x0 + 160, 190, 0, 23, 1500, 5000)
        pr = Plot(f, x0 + 10, 50, x0 + 160, 190, 0, 23, lo, hi)
        f.line(pl.x0, pl.y0, pl.x0, pl.y1, stroke='--phosphor', width=1.2)
        f.line(pr.x1, pr.y0, pr.x1, pr.y1, stroke='--amber', width=1.2)
        f.line(pl.x0, pl.y1, pl.x1, pl.y1, stroke='--paper-dim', width=1)
        for v in (lo, hi):
            f.text(pr.x1 + 5, pr.sy(v), num(lang, v), size=8.5, anchor='start', fill='--amber',
                   mono=True)
        pl.series(range(24), ne, width=2.2)
        pr.series(range(24), no, stroke='--amber', width=2.2, dash='6 4')
        f.text(x0, 18, head, size=10, anchor='start', weight='600')
        f.text(x0, 34, f'{w["right"]}: {num(lang, lo)}–{num(lang, hi)}', size=9, anchor='start',
               fill='--paper-dim')
    f.line(30, 222, 50, 222, stroke='--phosphor', width=2.2)
    f.text(56, 222, w['ne'] + ' (1.500–5.000)' if lang == 'pt' else w['ne'] + ' (1,500–5,000)',
           size=9.5, anchor='start')
    f.line(250, 222, 270, 222, stroke='--amber', width=2.2, dash='6 4')
    f.text(276, 222, w['no'], size=9.5, anchor='start')
    return f, w['cap']


@figure('l16-area', 16)
def l16_area(lang):
    a, b = year_totals('North')
    g = b / a
    w = {'en': dict(
        label=f'North\'s orders in 2024, {a:,}, and 2025, {b:,}, a rise of {100 * (g - 1):.1f}%, '
              f'drawn three ways. First, two circles whose radius grows by {g:.2f} times: the '
              f'second circle has {g * g:.2f} times the area and looks it. Second, two circles whose '
              f'area grows by {g:.2f} times: the radius grows by only {math.sqrt(g):.2f}. Third, '
              f'two bars.',
        a='radius scaled', b='area scaled', c='bars',
        ra=f'looks {num(lang, g * g, 1)}×', rb=f'is {num(lang, g, 1)}×',
        cap='The eye reads a circle by its area. Scale the radius by the data and the area grows by '
            'the square of it; a pictogram scaled in height and width does the same, and a cube in '
            'all three goes to the cube.'),
        'pt': dict(
        label=f'Os pedidos do Norte em 2024, {num("pt", a)}, e 2025, {num("pt", b)}, uma alta de '
              f'{num("pt", 100 * (g - 1), 1)}%, desenhados de três jeitos. Primeiro, dois círculos '
              f'cujo raio cresce {num("pt", g, 2)} vezes: o segundo círculo tem {num("pt", g * g, 2)} '
              f'vezes a área e parece isso. Segundo, dois círculos cuja área cresce '
              f'{num("pt", g, 2)} vezes: o raio cresce só {num("pt", math.sqrt(g), 2)}. Terceiro, '
              f'duas barras.',
        a='raio na escala', b='área na escala', c='barras',
        ra=f'parece {num(lang, g * g, 1)}×', rb=f'é {num(lang, g, 1)}×',
        cap='O olho lê um círculo pela área. Ponha o raio na escala do dado e a área cresce pelo '
            'quadrado dele; um pictograma escalado em altura e largura faz o mesmo, e um cubo nas '
            'três dimensões vai ao cubo.')}[lang]
    f = Fig('l16-area', 640, 240, w['label'])
    r0 = 34
    for k, (title, r1, note) in enumerate(((w['a'], r0 * g, w['ra']),
                                           (w['b'], r0 * math.sqrt(g), w['rb']))):
        x0 = 30 + k * 220
        f.text(x0, 18, title, size=10.5, anchor='start', weight='600')
        base = 190
        f.circle(x0 + 45, base - r0, r0, fill='--phosphor-dim', stroke='--phosphor')
        f.circle(x0 + 100 + r1, base - r1, r1, fill='--phosphor-dim', stroke='--phosphor')
        f.text(x0 + 45, base + 14, '2024', size=9.5, fill='--paper-dim')
        f.text(x0 + 100 + r1, base + 14, '2025', size=9.5, fill='--paper-dim')
        f.text(x0, 36, note, size=9.5, anchor='start',
               fill='--amber' if k == 0 else '--paper-dim')
    x0 = 480
    f.text(x0, 18, w['c'], size=10.5, anchor='start', weight='600')
    p = Plot(f, x0, 50, x0 + 130, 190, 0, 2, 0, 12000)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1)
    for i, (yr, v) in enumerate((('2024', a), ('2025', b))):
        f.bar(p.sx(i) + 12, p.sy(v), 40, p.y1 - p.sy(v))
        f.text(p.sx(i) + 32, p.y1 + 14, yr, size=9.5, fill='--paper-dim')
        f.text(p.sx(i) + 32, p.sy(v) - 8, num(lang, v), size=9, mono=True)
    return f, w['cap']


@figure('l16-window', 16)
def l16_window(lang):
    m = monthly_by_region()
    tot = [sum(m[r][i] for r in H.REGIONS) for i in range(24)]
    drop = 100 * (tot[12] / tot[11] - 1)
    w = {'en': dict(
        label=f'Two charts of Horta\'s total monthly orders. On the left, only December 2024 and '
              f'January 2025, {tot[11]:,} and {tot[12]:,}, under the title "Orders fell 20% in a '
              f'month". On the right, all 24 months with those two shaded: orders rose through both '
              f'years, and every December spikes and falls back.',
        t='Orders fell 20% in a month', d='Dec 2024', j='Jan 2025',
        full='the whole series', y='orders per month',
        cap='Both charts are true. The window on the left was chosen to tell a story the full '
            'series contradicts, which is why a chart should say what period it covers and why.'),
        'pt': dict(
        label=f'Dois gráficos dos pedidos mensais totais da Horta. À esquerda, só dezembro de 2024 e '
              f'janeiro de 2025, {num("pt", tot[11])} e {num("pt", tot[12])}, sob o título "Os '
              f'pedidos caíram 20% em um mês". À direita, os 24 meses com esses dois sombreados: os '
              f'pedidos subiram nos dois anos, e todo dezembro tem um pico e depois volta.',
        t='Os pedidos caíram 20% em um mês', d='dez 2024', j='jan 2025',
        full='a série inteira', y='pedidos por mês',
        cap='Os dois gráficos são verdadeiros. A janela da esquerda foi escolhida para contar uma '
            'história que a série inteira desmente, e por isso um gráfico deve dizer que período '
            'cobre e por quê.')}[lang]
    assert round(drop) == -20
    f = Fig('l16-window', 640, 250, w['label'])
    f.text(20, 18, w['t'], size=10.5, anchor='start', weight='600', fill='--amber')
    p = Plot(f, 70, 50, 220, 210, -0.5, 1.5, 12000, 17000)
    p.yaxis(range(12000, 17001, 1000), fmt=lambda v: num(lang, v), size=9)
    p.series([0, 1], [tot[11], tot[12]], stroke='--amber', width=2.4)
    for i, lab in ((0, w['d']), (1, w['j'])):
        f.circle(p.sx(i), p.sy(tot[11 + i]), 4, fill='--amber')
        f.text(p.sx(i), p.y1 + 14, lab, size=9.5, fill='--paper-dim')
    f.text(330, 18, w['full'], size=10.5, anchor='start', weight='600')
    q = Plot(f, 330, 50, 610, 210, 0, 23, 8000, 22000)
    f.bar(q.sx(10.6), q.y0, q.sx(12.4) - q.sx(10.6), q.y1 - q.y0, stroke='--scan', fill='--scan',
          width=1)
    q.yaxis(range(8000, 22001, 4000), fmt=lambda v: num(lang, v), size=9, grid=False)
    q.series(range(24), tot, width=2.2)
    ticks, names = month_ticks(lang)
    q.xaxis(ticks, fmt=lambda t: names[t], size=9)
    return f, w['cap']


def pie_shares():
    tot = sum(H.CATEGORIES.values())
    spans, a = {}, 0.0
    for n in PIE_ORDER:
        spans[n] = (a, a + 360 * H.CATEGORIES[n] / tot)
        a = spans[n][1]
    off = 90 - sum(spans['Drinks']) / 2
    spans = {n: (a0 + off, a1 + off) for n, (a0, a1) in spans.items()}

    def side(a0, a1):
        s = 0.0
        for lo, hi in ((0, 180), (360, 540), (-360, -180)):
            x0, x1 = max(a0, lo), min(a1, hi)
            if x1 > x0:
                s += PIE_D * PIE_R * (math.cos(math.radians(x0)) - math.cos(math.radians(x1)))
        return s
    ink = {n: math.radians(a1 - a0) / 2 * PIE_R * PIE_R * PIE_K + side(a0, a1)
           for n, (a0, a1) in spans.items()}
    total_ink = sum(ink.values())
    return spans, {n: 100 * H.CATEGORIES[n] / tot for n in PIE_ORDER}, \
        {n: 100 * ink[n] / total_ink for n in PIE_ORDER}


def pie3d(f, cx, cy, spans, colours, R=PIE_R, k=PIE_K, d=PIE_D):
    def pt(a, dy=0):
        t = math.radians(a)
        return cx + R * math.cos(t), cy + k * R * math.sin(t) + dy
    walls = []
    for n, (a0, a1) in spans.items():
        for lo, hi in ((0, 180), (360, 540), (-360, -180)):
            x0, x1 = max(a0, lo), min(a1, hi)
            if x1 > x0:
                walls.append((n, x0, x1))
    for n, x0, x1 in walls:
        (ax, ay), (bx, by) = pt(x0), pt(x1)
        f.path(f'M{ax:.1f} {ay:.1f} A{R} {k * R:.1f} 0 0 1 {bx:.1f} {by:.1f} L{bx:.1f} {by + d:.1f} '
               f'A{R} {k * R:.1f} 0 0 0 {ax:.1f} {ay + d:.1f} Z', stroke='#20263c', width=0.8,
               fill=colours[n], opacity=0.75)
    for n, (a0, a1) in spans.items():
        (ax, ay), (bx, by) = pt(a0), pt(a1)
        big = 1 if a1 - a0 > 180 else 0
        f.path(f'M{cx:.1f} {cy:.1f} L{ax:.1f} {ay:.1f} A{R} {k * R:.1f} 0 {big} 1 {bx:.1f} '
               f'{by:.1f} Z', stroke='#20263c', width=0.8, fill=colours[n])


PIE_COLOURS = dict(zip(PIE_ORDER, ['#E69F00', '#56B4E9', '#009E73', '#F0E442', '#CC79A7',
                                    '#D55E00']))


@figure('l16-three-d', 16)
def l16_three_d(lang):
    spans, real, ink = pie_shares()
    w = {'en': dict(
        label=f'Revenue by category as a tilted pie with depth, beside a bar chart of the same '
              f'numbers. In the pie, Drinks sits at the front and its side wall shows, so it takes '
              f'{ink["Drinks"]:.1f}% of the ink while being {real["Drinks"]:.1f}% of revenue, the '
              f'second-smallest share. Vegetables, the largest at {real["Vegetables"]:.1f}%, sits at '
              f'the back and takes {ink["Vegetables"]:.1f}%. The bars show the real order.',
        ink='of the ink', rev='of revenue',
        cap='Tilting a pie gives the slices at the front a side wall, ink that the slices at the back '
            'never get. The second-smallest category ends up looking the largest.'),
        'pt': dict(
        label=f'A receita por categoria como uma pizza inclinada com profundidade, ao lado de um '
              f'gráfico de barras com os mesmos números. Na pizza, Bebidas fica na frente e a '
              f'parede lateral aparece, então ocupa {num("pt", ink["Drinks"], 1)}% da tinta sendo '
              f'{num("pt", real["Drinks"], 1)}% da receita, a segunda menor fatia. Verduras, a '
              f'maior com {num("pt", real["Vegetables"], 1)}%, fica atrás e ocupa '
              f'{num("pt", ink["Vegetables"], 1)}%. As barras mostram a ordem real.',
        ink='da tinta', rev='da receita',
        cap='Inclinar uma pizza dá às fatias da frente uma parede lateral, tinta que as fatias de trás '
            'nunca recebem. A segunda menor categoria acaba parecendo a maior.')}[lang]
    f = Fig('l16-three-d', 640, 270, w['label'])
    pie3d(f, 150, 110, spans, PIE_COLOURS)
    f.text(150, 200, f'{CATEGORY[lang]["Drinks"]}: {num(lang, real["Drinks"], 1)}% {w["rev"]}',
           size=9.5)
    f.text(150, 216, f'{num(lang, ink["Drinks"], 1)}% {w["ink"]}', size=9.5, fill='--amber',
           weight='600')
    p = Plot(f, 400, 30, 600, 240, 0, 25, 0, 6)
    f.line(p.x0, 26, p.x0, 244, stroke='--paper-dim', width=1.2)
    for i, n in enumerate(sorted(PIE_ORDER, key=lambda n: -real[n])):
        y = 32 + i * 35
        f.bar(p.x0, y, p.sx(real[n]) - p.x0, 24, stroke=PIE_COLOURS[n], fill=PIE_COLOURS[n])
        f.text(p.x0 - 8, y + 12, CATEGORY[lang][n], size=9.5, anchor='end')
        f.text(p.sx(real[n]) + 6, y + 12, f'{num(lang, real[n], 1)}%', size=9, anchor='start',
               mono=True)
    return f, w['cap']


@image('l16-faults.svg', 16)
def l16_faults_image():
    m = monthly_by_region()
    f = Fig('l16-faults-image', 600, 320,
            'A chart with numbers and no words: four bars drawn with a depth effect, each with a '
            'strongly coloured side face, standing on a left axis numbered 60 to 100; a dashed line '
            'runs across the bars and belongs to a second axis on the right, numbered 20 to 60.')
    p = Plot(f, 80, 40, 500, 270, -0.5, 3.5, 60, 100)
    f.line(p.x0, p.y0, p.x0, p.y1, stroke='--paper-dim', width=1.5)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.5)
    for v in range(60, 101, 10):
        f.line(p.x0 - 6, p.sy(v), p.x0, p.sy(v), stroke='--paper-dim', width=1.2)
        f.text(p.x0 - 10, p.sy(v), str(v), size=12, anchor='end', fill='--paper-dim', mono=True)
    f.line(p.x1, p.y0, p.x1, p.y1, stroke='--amber', width=1.5)
    for v in range(60, 101, 10):
        f.line(p.x1, p.sy(v), p.x1 + 6, p.sy(v), stroke='--amber', width=1.2)
        f.text(p.x1 + 10, p.sy(v), str(v - 40), size=12, anchor='start', fill='--amber', mono=True)
    vals = [68, 74, 79, 92]
    for i, v in enumerate(vals):
        x, y = p.sx(i) - 26, p.sy(v)
        f.path(f'M{x + 52:.1f} {y:.1f} l14 -10 v{p.y1 - y:.1f} l-14 10 Z', stroke='--phosphor',
               width=1, fill='--phosphor')
        f.path(f'M{x:.1f} {y:.1f} l14 -10 h52 l-14 10 Z', stroke='--phosphor', width=1,
               fill='--scan')
        f.bar(x, y, 52, p.y1 - y)
    line = [86, 75, 83, 66]
    f.poly([(p.sx(i), p.sy(v)) for i, v in enumerate(line)], stroke='--amber', width=2.4,
           dash='7 4')
    return f
