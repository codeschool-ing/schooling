# Lesson 4 — line charts.


def month_ticks(lang):
    return [0, 6, 12, 18, 23], {0: f'{MONTH_SHORT[lang][0]} 2024', 6: f'{MONTH_SHORT[lang][6]}',
                                12: f'{MONTH_SHORT[lang][0]} 2025', 18: f'{MONTH_SHORT[lang][6]}',
                                23: f'{MONTH_SHORT[lang][11]}'}


def total_series():
    m = monthly_by_region()
    return [sum(m[r][i] for r in H.REGIONS) for i in range(24)]


@figure('l04-total', 4)
def l04_total(lang):
    tot = total_series()
    ticks, names = month_ticks(lang)
    w = {'en': dict(
        label=f'A line of Horta\'s total orders per month from January 2024 to December 2025. It '
              f'climbs from {tot[0]:,} to {tot[-1]:,}, with a sharp peak each December, '
              f'{tot[11]:,} in 2024 and {tot[23]:,} in 2025, and a drop back the following '
              f'January.',
        y='orders per month',
        cap='A line joins the months in order, so the eye reads its slope as change: steady '
            'growth, and a December spike that falls back every January.'),
        'pt': dict(
        label=f'Uma linha dos pedidos totais da Horta por mês de janeiro de 2024 a dezembro de '
              f'2025. Ela sobe de {num("pt", tot[0])} para {num("pt", tot[-1])}, com um pico '
              f'forte a cada dezembro, {num("pt", tot[11])} em 2024 e {num("pt", tot[23])} em '
              f'2025, e uma queda de volta no janeiro seguinte.',
        y='pedidos por mês',
        cap='Uma linha liga os meses em ordem, então o olho lê a inclinação como mudança: um '
            'crescimento constante, e um pico de dezembro que cai de volta todo janeiro.')}[lang]
    f = Fig('l04-total', 620, 270, w['label'])
    p = Plot(f, 70, 40, 600, 220, 0, 23, 0, 22000)
    p.yaxis(range(0, 22001, 5000), fmt=lambda v: num(lang, v), label=w['y'])
    p.xaxis(ticks, fmt=lambda t: names[t])
    p.series(range(24), tot, width=2.2)
    for i in (11, 23):
        f.circle(p.sx(i), p.sy(tot[i]), 3.5, fill='--amber')
    return f, w['cap']


@figure('l04-aspect', 4)
def l04_aspect(lang):
    m = monthly_by_region()['Southeast']
    w = {'en': dict(
        label='The same line, Southeast\'s monthly orders over two years, drawn twice. In a wide, '
              'short frame it looks nearly flat. In a narrow, tall frame the same growth looks '
              'steep. The data and the axis ranges are identical; only the shape of the frame '
              'changed.',
        a='wide and short: "steady"', b='narrow and tall: "soaring"',
        cap='The slope a reader sees depends on the frame as much as on the data. Pick an aspect '
            'ratio that puts the important slopes near 45 degrees, and keep it when comparing.'),
        'pt': dict(
        label='A mesma linha, os pedidos mensais do Sudeste em dois anos, desenhada duas vezes. '
              'Num quadro largo e baixo ela parece quase plana. Num quadro estreito e alto o mesmo '
              'crescimento parece íngreme. O dado e as faixas dos eixos são idênticos; só a forma '
              'do quadro mudou.',
        a='largo e baixo: "estável"', b='estreito e alto: "disparando"',
        cap='A inclinação que o leitor vê depende tanto do quadro quanto do dado. Escolha uma '
            'proporção que deixe as inclinações importantes perto de 45 graus, e mantenha-a ao '
            'comparar.')}[lang]
    f = Fig('l04-aspect', 620, 280, w['label'])
    p = Plot(f, 30, 150, 390, 210, 0, 23, 4000, 9000)
    f.rect(30, 150, 360, 60, stroke='--wire', fill='--panel', rx=2)
    p.series(range(24), m, width=2)
    f.text(30, 236, w['a'], size=10.5, anchor='start')
    q = Plot(f, 470, 30, 560, 230, 0, 23, 4000, 9000)
    f.rect(470, 30, 90, 200, stroke='--wire', fill='--panel', rx=2)
    q.series(range(24), m, width=2)
    f.text(515, 256, w['b'], size=10.5)
    return f, w['cap']


@figure('l04-highlight', 4)
def l04_highlight(lang):
    m = monthly_by_region()
    ticks, names = month_ticks(lang)
    w = {'en': dict(
        label='Two line charts of monthly orders by region. On the left all five lines are drawn '
              'in five colours with a legend, and they tangle where South and Northeast cross. On '
              'the right four lines are grey and Northeast is drawn in a strong colour and '
              'labelled at its end, so its climb past South in 2025 is the first thing seen.',
        a='five colours and a legend', b='one line that matters',
        cap='When one series is the story, draw it in colour and the rest in grey, and put its '
            'name at the end of the line instead of in a legend.'),
        'pt': dict(
        label='Dois gráficos de linhas dos pedidos mensais por região. À esquerda as cinco linhas '
              'estão em cinco cores com legenda, e se embaraçam onde Sul e Nordeste se cruzam. À '
              'direita quatro linhas estão em cinza e o Nordeste está numa cor forte e rotulado '
              'na ponta, então a subida dele passando o Sul em 2025 é a primeira coisa vista.',
        a='cinco cores e uma legenda', b='uma linha que importa',
        cap='Quando uma série é a história, desenhe-a em cor e o resto em cinza, e ponha o nome '
            'dela na ponta da linha em vez de numa legenda.')}[lang]
    f = Fig('l04-highlight', 660, 290, w['label'])
    hues = {'Southeast': '#4f81bd', 'South': '#c0504d', 'Northeast': '#9bbb59',
            'Centre-West': '#8064a2', 'North': '#f79646'}
    p = Plot(f, 40, 40, 300, 220, 0, 23, 0, 9000)
    f.text(40, 18, w['a'], size=10.5, anchor='start', weight='600')
    p.yaxis(range(0, 9001, 3000), fmt=lambda v: f'{v // 1000}k', size=9)
    for r in H.REGIONS:
        p.series(range(24), m[r], stroke=hues[r], width=1.6)
    for i, r in enumerate(H.REGIONS):
        lx, ly = 40 + (i % 3) * 95, 248 + (i // 3) * 16
        f.rect(lx, ly - 5, 9, 9, stroke=hues[r], fill=hues[r], rx=1)
        f.text(lx + 14, ly, REGION[lang][r], size=8.5, anchor='start')
    q = Plot(f, 370, 40, 580, 220, 0, 23, 0, 9000)
    f.text(370, 18, w['b'], size=10.5, anchor='start', weight='600')
    q.yaxis(range(0, 9001, 3000), fmt=lambda v: f'{v // 1000}k', size=9)
    for r in H.REGIONS:
        if r != 'Northeast':
            q.series(range(24), m[r], stroke='--paper-dim', width=1.2)
    q.series(range(24), m['Northeast'], stroke='--amber', width=2.6)
    f.text(q.sx(23) + 6, q.sy(m['Northeast'][-1]), REGION[lang]['Northeast'], size=10,
           anchor='start', fill='--amber', weight='600')
    f.text(q.sx(23) + 6, q.sy(m['South'][-1]) + 4, REGION[lang]['South'], size=9,
           anchor='start', fill='--paper-dim')
    return f, w['cap']


@figure('l04-dual', 4)
def l04_dual(lang):
    m = monthly_by_region()
    se, no = m['Southeast'], m['North']
    w = {'en': dict(
        label='Two dual-axis charts of the same two series, Southeast\'s and North\'s monthly '
              'orders. On the left, Southeast\'s axis runs from 0 to 9,000 and North\'s from 0 to '
              '9,000 as well, and North is a thin line near the bottom. On the right, Southeast\'s '
              'axis runs from 4,000 to 9,000 and North\'s from 400 to 1,500, and North\'s line '
              'climbs steeply past Southeast\'s, crossing it in mid 2025. Nothing in the data '
              'changed.',
        a='one honest choice', b='another choice, same data',
        l='Southeast (left axis)', r='North (right axis)',
        cap='With two axes, whoever draws the chart sets where the lines cross and how steep each '
            'one looks. The crossing on the right means nothing at all.'),
        'pt': dict(
        label='Dois gráficos de eixo duplo das mesmas duas séries, os pedidos mensais do Sudeste e '
              'do Norte. À esquerda, o eixo do Sudeste vai de 0 a 9.000 e o do Norte também de 0 a '
              '9.000, e o Norte é uma linha fina perto do chão. À direita, o eixo do Sudeste vai de '
              '4.000 a 9.000 e o do Norte de 400 a 1.500, e a linha do Norte sobe íngreme passando '
              'a do Sudeste, cruzando-a no meio de 2025. Nada no dado mudou.',
        a='uma escolha honesta', b='outra escolha, mesmo dado',
        l='Sudeste (eixo esquerdo)', r='Norte (eixo direito)',
        cap='Com dois eixos, quem desenha o gráfico decide onde as linhas se cruzam e quão '
            'íngreme cada uma parece. O cruzamento da direita não significa nada.')}[lang]
    f = Fig('l04-dual', 660, 300, w['label'])
    for k, (lo1, hi1, lo2, hi2, title) in enumerate(((0, 9000, 0, 9000, w['a']),
                                                     (4000, 9000, 400, 1500, w['b']))):
        x0 = 60 + k * 330
        a = Plot(f, x0, 40, x0 + 220, 220, 0, 23, lo1, hi1)
        b = Plot(f, x0, 40, x0 + 220, 220, 0, 23, lo2, hi2)
        f.text(x0 + 110, 18, title, size=10.5, weight='600')
        f.line(a.x0, a.y0, a.x0, a.y1, stroke='--phosphor', width=1.2)
        f.line(a.x1, a.y0, a.x1, a.y1, stroke='--amber', width=1.2)
        f.line(a.x0, a.y1, a.x1, a.y1, stroke='--paper-dim', width=1.2)
        for v in (lo1, (lo1 + hi1) // 2, hi1):
            f.text(a.x0 - 6, a.sy(v), num(lang, v), size=8.5, anchor='end', fill='--phosphor')
        for v in (lo2, (lo2 + hi2) // 2, hi2):
            f.text(a.x1 + 6, b.sy(v), num(lang, v), size=8.5, anchor='start', fill='--amber')
        a.series(range(24), se, stroke='--phosphor', width=2)
        b.series(range(24), no, stroke='--amber', width=2, dash='5 3')
    f.line(60, 270, 80, 270, stroke='--phosphor', width=2)
    f.text(86, 270, w['l'], size=9.5, anchor='start')
    f.line(260, 270, 280, 270, stroke='--amber', width=2, dash='5 3')
    f.text(286, 270, w['r'], size=9.5, anchor='start')
    return f, w['cap']


@figure('l04-indexed', 4)
def l04_indexed(lang):
    m = monthly_by_region()
    ticks, names = month_ticks(lang)
    w = {'en': dict(
        label='Monthly orders for the five regions indexed so that January 2024 is 100 for each. '
              'All five lines start together at 100. By December 2025 North reaches 325, '
              'Northeast 260, Centre-West 217, South 190 and Southeast 159, in that order from '
              'top to bottom.',
        y='January 2024 = 100',
        cap='Indexed, every region starts at 100 and the lines compare growth on one axis, which '
            'two axes never could. Southeast is still the largest region; this chart is about '
            'how fast each one grew.'),
        'pt': dict(
        label='Os pedidos mensais das cinco regiões indexados para que janeiro de 2024 seja 100 '
              'para cada uma. As cinco linhas começam juntas em 100. Em dezembro de 2025 o Norte '
              'chega a 325, o Nordeste a 260, o Centro-Oeste a 217, o Sul a 190 e o Sudeste a '
              '159, nessa ordem de cima para baixo.',
        y='janeiro de 2024 = 100',
        cap='Indexadas, todas as regiões começam em 100 e as linhas comparam o crescimento num '
            'eixo só, o que dois eixos nunca conseguiriam. O Sudeste continua a maior região; '
            'este gráfico é sobre a velocidade com que cada uma cresceu.')}[lang]
    f = Fig('l04-indexed', 620, 290, w['label'])
    p = Plot(f, 60, 40, 520, 240, 0, 23, 50, 350)
    p.yaxis(range(50, 351, 50), label=w['y'])
    p.xaxis(ticks, fmt=lambda t: names[t])
    f.line(p.x0, p.sy(100), p.x1, p.sy(100), stroke='--paper-dim', width=1, dash='3 3')
    for r in H.REGIONS:
        idx = [100 * v / m[r][0] for v in m[r]]
        strong = r in ('North', 'Southeast')
        p.series(range(24), idx, stroke='--phosphor' if strong else '--paper-dim',
                 width=2 if strong else 1.3)
        f.text(p.x1 + 6, p.sy(idx[-1]), f'{REGION[lang][r]} {idx[-1]:.0f}', size=9.5,
               anchor='start', fill='--paper' if strong else '--paper-dim')
    return f, w['cap']


@image('l04-dual.svg', 4)
def l04_dual_image():
    m = monthly_by_region()
    f = Fig('l04-dual-image', 600, 340,
            'A line chart with no words: two lines, one solid and one dashed, each measured '
            'against its own vertical axis, one axis on the left and one on the right. The dashed '
            'line climbs steeply and crosses the solid one near the right-hand side. Both lines '
            'have a sharp peak at the twelfth and the last month.')
    a = Plot(f, 80, 30, 520, 290, 0, 23, 4000, 9000)
    b = Plot(f, 80, 30, 520, 290, 0, 23, 400, 1500)
    f.line(a.x0, a.y1, a.x1, a.y1, stroke='--paper-dim', width=1.5)
    f.line(a.x0, a.y0, a.x0, a.y1, stroke='--phosphor', width=1.5)
    f.line(a.x1, a.y0, a.x1, a.y1, stroke='--amber', width=1.5)
    for v in range(4000, 9001, 1000):
        f.line(a.x0 - 5, a.sy(v), a.x0, a.sy(v), stroke='--phosphor', width=1.2)
        f.text(a.x0 - 9, a.sy(v), str(v), size=10, anchor='end', fill='--phosphor', mono=True)
    for v in range(400, 1501, 200):
        f.line(a.x1, b.sy(v), a.x1 + 5, b.sy(v), stroke='--amber', width=1.2)
        f.text(a.x1 + 9, b.sy(v), str(v), size=10, anchor='start', fill='--amber', mono=True)
    a.series(range(24), m['Southeast'], stroke='--phosphor', width=2.4)
    b.series(range(24), m['North'], stroke='--amber', width=2.4, dash='7 4')
    return f
