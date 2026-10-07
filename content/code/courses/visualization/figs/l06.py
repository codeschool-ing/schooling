# Lesson 6 — scatterplots, bubbles and trend lines.


def fit(xs, ys):
    n = len(xs)
    mx, my = sum(xs) / n, sum(ys) / n
    sxx = sum((x - mx) ** 2 for x in xs)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    b = sxy / sxx
    return my - b * mx, b


def jit(i, spread):
    return (((i * 2654435761) % 4294967296) / 4294967296 - 0.5) * spread


@figure('l06-scatter', 6)
def l06_scatter(lang):
    d = H.deliveries()
    km = [r['km'] for r in d]
    mi = [r['minutes'] for r in d]
    a, b = fit(km, mi)
    w = {'en': dict(
        label='A scatterplot of 400 deliveries, distance in kilometres across and delivery time '
              'in minutes up. The points form a rising cloud, dense below 10 km and sparse beyond '
              '20, and a straight trend line runs through them from about 23 minutes at 0 km to '
              'about 97 minutes at 34 km.',
        x='distance (km)', y='delivery time (minutes)', line='trend line',
        cap='Each point is one delivery. The cloud rises: longer trips take longer. The line '
            'summarises the rise as about 2.2 extra minutes per kilometre.'),
        'pt': dict(
        label='Um gráfico de dispersão de 400 entregas, a distância em quilômetros na horizontal e '
              'o tempo de entrega em minutos na vertical. Os pontos formam uma nuvem que sobe, '
              'densa abaixo de 10 km e rala passando de 20, e uma linha de tendência reta passa '
              'por eles de uns 23 minutos em 0 km a uns 97 minutos em 34 km.',
        x='distância (km)', y='tempo de entrega (minutos)', line='linha de tendência',
        cap='Cada ponto é uma entrega. A nuvem sobe: viagens mais longas demoram mais. A linha '
            'resume a subida como uns 2,2 minutos a mais por quilômetro.')}[lang]
    f = Fig('l06-scatter', 600, 320, w['label'])
    p = Plot(f, 60, 40, 570, 260, 0, 36, 0, 110)
    p.yaxis(range(0, 111, 20), label=w['y'])
    p.xaxis(range(0, 37, 5), label=w['x'])
    for x, y in zip(km, mi):
        f.circle(p.sx(x), p.sy(y), 2.6, fill='--phosphor', opacity=0.55)
    f.line(p.sx(0), p.sy(a), p.sx(34.3), p.sy(a + b * 34.3), stroke='--amber', width=2)
    f.text(p.sx(34.3), p.sy(a + b * 34.3) + 16, w['line'], size=10, anchor='end', fill='--amber')
    return f, w['cap']


@figure('l06-overplot', 6)
def l06_overplot(lang):
    d = H.deliveries()
    w = {'en': dict(
        label='Two scatterplots of items in the basket against basket value. On the left, items '
              'are whole numbers, so the 400 points pile into 17 thin columns and the many points '
              'hidden behind each other cannot be counted. On the right the same points are moved '
              'a little sideways at random and drawn half transparent, and the crowded middle, '
              'eight to ten items, shows as the darkest region.',
        a='as drawn', b='jittered and transparent', x='items in the basket', y='basket (R$)',
        cap='When values repeat, points hide behind each other and the busiest places look no '
            'busier than the empty ones. A little jitter and some transparency bring the count '
            'back.'),
        'pt': dict(
        label='Dois gráficos de dispersão de itens na cesta contra o valor da cesta. À esquerda, '
              'itens são números inteiros, então os 400 pontos se empilham em 17 colunas finas e os '
              'muitos pontos escondidos uns atrás dos outros não podem ser contados. À direita os '
              'mesmos pontos são deslocados um pouco para o lado ao acaso e desenhados meio '
              'transparentes, e o meio lotado, de oito a dez itens, aparece como a região mais '
              'escura.',
        a='como desenhado', b='com jitter e transparência', x='itens na cesta', y='cesta (R$)',
        cap='Quando os valores se repetem, os pontos se escondem uns atrás dos outros e os lugares '
            'mais cheios não parecem mais cheios que os vazios. Um pouco de jitter e alguma '
            'transparência trazem a contagem de volta.')}[lang]
    f = Fig('l06-overplot', 640, 290, w['label'])
    for k in range(2):
        x0 = 60 + k * 310
        p = Plot(f, x0, 40, x0 + 240, 230, 0, 18, 0, 220)
        p.yaxis(range(0, 221, 50), size=9, label=w['y'] if k == 0 else None)
        p.xaxis(range(0, 19, 3), size=9, label=w['x'])
        f.text(x0 + 120, 18, w['a'] if k == 0 else w['b'], size=10.5, weight='600')
        for i, r in enumerate(d):
            if k == 0:
                f.circle(p.sx(r['items']), p.sy(r['basket']), 2.6, fill='--phosphor')
            else:
                f.circle(p.sx(r['items'] + jit(i, 0.7)), p.sy(r['basket']), 2.6, fill='--phosphor',
                         opacity=0.3)
    return f, w['cap']


STATE_POP = {k: v[1] for k, v in H.STATES.items()}
STATE_ORD = {k: v[0] for k, v in H.STATES.items()}


@figure('l06-bubbles', 6)
def l06_bubbles(lang):
    w = {'en': dict(
        label='A bubble chart of Brazil\'s 27 states. Across, population in millions; up, Horta '
              'orders per thousand people; the area of each bubble is the state\'s total orders. '
              'São Paulo is the largest bubble at 44.4 million people and 1.4 orders per thousand. '
              'The Federal District stands highest, at about 2 orders per thousand, with a small '
              'bubble. Most northern states sit low and small.',
        x='population (millions)', y='orders per 1,000 people', note='bubble area = orders in 2025',
        cap='Three variables: position carries the two that matter most, and area carries the '
            'third. The labels name the states the eye goes to first.'),
        'pt': dict(
        label='Um gráfico de bolhas dos 27 estados do Brasil. Na horizontal, a população em '
              'milhões; na vertical, pedidos da Horta por mil habitantes; a área de cada bolha é o '
              'total de pedidos do estado. São Paulo é a maior bolha, com 44,4 milhões de pessoas e '
              '1,4 pedido por mil. O Distrito Federal fica mais alto, com uns 2 pedidos por mil, '
              'numa bolha pequena. A maioria dos estados do Norte fica baixa e pequena.',
        x='população (milhões)', y='pedidos por 1.000 habitantes', note='área da bolha = pedidos em 2025',
        cap='Três variáveis: a posição carrega as duas que mais importam, e a área carrega a '
            'terceira. Os rótulos dão nome aos estados para onde o olho vai primeiro.')}[lang]
    f = Fig('l06-bubbles', 620, 330, w['label'])
    p = Plot(f, 70, 40, 590, 270, 0, 48, 0, 2.4)
    p.yaxis([0, 0.5, 1.0, 1.5, 2.0], fmt=lambda v: num(lang, v, 1), label=w['y'])
    p.xaxis(range(0, 49, 8), label=w['x'])
    top = max(STATE_ORD.values())
    for s in sorted(H.STATES, key=lambda s: -STATE_ORD[s]):
        x, y = STATE_POP[s], STATE_ORD[s] / (STATE_POP[s] * 1000)
        r = 26 * math.sqrt(STATE_ORD[s] / top)
        f.circle(p.sx(x), p.sy(y), max(r, 1.5), fill='--phosphor-dim', stroke='--phosphor',
                 width=1, opacity=0.6)
    for s in ('SP', 'DF', 'MG', 'RJ', 'PA', 'SC'):
        x, y = STATE_POP[s], STATE_ORD[s] / (STATE_POP[s] * 1000)
        r = 26 * math.sqrt(STATE_ORD[s] / top)
        f.text(p.sx(x) + r + 4, p.sy(y), s, size=9.5, anchor='start', mono=True)
    f.text(p.x1, p.y0 - 14, w['note'], size=9.5, anchor='end', fill='--paper-dim')
    return f, w['cap']


@figure('l06-extrapolate', 6)
def l06_extrapolate(lang):
    d = H.deliveries()
    km = [r['km'] for r in d]
    mi = [r['minutes'] for r in d]
    a, b = fit(km, mi)
    w = {'en': dict(
        label='The deliveries scatterplot with its trend line extended past the data. Points stop '
              'at 34 km, and only six deliveries are beyond 20 km. The line is solid where there is '
              'data and dashed beyond it, reaching 153 minutes at 60 km, a value nothing measured.',
        x='distance (km)', y='minutes', data='the data ends here', guess='a guess, not a finding',
        cap='Inside the cloud the line summarises what was measured. Outside it, the line is a '
            'guess that the trend continues, and nothing on the chart supports that.'),
        'pt': dict(
        label='O gráfico de dispersão das entregas com a linha de tendência prolongada além do '
              'dado. Os pontos param em 34 km, e só seis entregas passam de 20 km. A linha é '
              'contínua onde há dado e tracejada depois, chegando a 153 minutos em 60 km, um valor '
              'que nada mediu.',
        x='distância (km)', y='minutos', data='o dado termina aqui', guess='um palpite, não um achado',
        cap='Dentro da nuvem a linha resume o que foi medido. Fora dela, a linha é um palpite de '
            'que a tendência continua, e nada no gráfico sustenta isso.')}[lang]
    f = Fig('l06-extrapolate', 600, 300, w['label'])
    p = Plot(f, 60, 30, 570, 240, 0, 62, 0, 170)
    p.yaxis(range(0, 161, 40), label=w['y'])
    p.xaxis(range(0, 61, 10), label=w['x'])
    for x, y in zip(km, mi):
        f.circle(p.sx(x), p.sy(y), 2.2, fill='--phosphor', opacity=0.5)
    f.line(p.sx(0), p.sy(a), p.sx(34.3), p.sy(a + b * 34.3), stroke='--amber', width=2)
    f.line(p.sx(34.3), p.sy(a + b * 34.3), p.sx(60), p.sy(a + b * 60), stroke='--amber', width=2,
           dash='6 5')
    f.line(p.sx(34.3), p.y0, p.sx(34.3), p.y1, stroke='--paper-dim', width=1, dash='3 3')
    f.text(p.sx(34.3) - 6, p.y0 + 8, w['data'], size=9.5, anchor='end', fill='--paper-dim')
    f.text(p.sx(60), p.sy(a + b * 60) + 18, w['guess'], size=10, anchor='end', fill='--amber')
    return f, w['cap']


@figure('l06-log', 6)
def l06_log(lang):
    w = {'en': dict(
        label='Orders against population for the 27 states, drawn twice. On the left, with linear '
              'axes, São Paulo sits alone in the top right and the other 26 states crowd into the '
              'bottom left corner. On the right, with logarithmic axes where each step is ten '
              'times the last, the states spread out along a rising band and the outliers, such '
              'as the Federal District above it, become visible.',
        a='linear axes', b='logarithmic axes', x='population (millions)', y='orders',
        cap='When values span a hundredfold or more, a linear axis spends most of its length on a '
            'few giants. A logarithmic axis gives every factor of ten the same room.'),
        'pt': dict(
        label='Pedidos contra população nos 27 estados, desenhados duas vezes. À esquerda, com '
              'eixos lineares, São Paulo fica sozinho no canto de cima à direita e os outros 26 '
              'estados se amontoam no canto de baixo à esquerda. À direita, com eixos '
              'logarítmicos em que cada passo é dez vezes o anterior, os estados se espalham numa '
              'faixa que sobe e os pontos fora da curva, como o Distrito Federal acima dela, '
              'aparecem.',
        a='eixos lineares', b='eixos logarítmicos', x='população (milhões)', y='pedidos',
        cap='Quando os valores cobrem cem vezes ou mais, um eixo linear gasta quase todo o '
            'comprimento com poucos gigantes. Um eixo logarítmico dá a cada fator de dez o mesmo '
            'espaço.')}[lang]
    f = Fig('l06-log', 640, 290, w['label'])
    p = Plot(f, 70, 52, 300, 230, 0, 48, 0, 65000)
    p.yaxis(range(0, 65001, 20000), fmt=lambda v: f'{v // 1000}k', size=9, label=w['y'])
    p.xaxis(range(0, 49, 12), size=9, label=w['x'])
    f.text(185, 14, w['a'], size=10.5, weight='600')
    for s in H.STATES:
        f.circle(p.sx(STATE_POP[s]), p.sy(STATE_ORD[s]), 3.2, fill='--phosphor', opacity=0.8)
    lg = math.log10
    q = Plot(f, 400, 52, 620, 230, lg(0.5), lg(50), lg(100), lg(100000))
    f.text(510, 14, w['b'], size=10.5, weight='600')
    q.yaxis([lg(v) for v in (100, 1000, 10000, 100000)],
            fmt=lambda v: {2: '100', 3: '1k', 4: '10k', 5: '100k'}[round(v)], size=9,
            label=w['y'])
    q.xaxis([lg(v) for v in (1, 10)], fmt=lambda v: {0: '1', 1: '10'}[round(v)], size=9,
            label=w['x'])
    for s in H.STATES:
        f.circle(q.sx(lg(STATE_POP[s])), q.sy(lg(STATE_ORD[s])), 3.2, fill='--phosphor',
                 opacity=0.8)
    f.text(q.sx(lg(2.8)) - 6, q.sy(lg(5480)) - 8, 'DF', size=9, anchor='end', mono=True)
    return f, w['cap']


@image('l06-scatter.svg', 6)
def l06_scatter_image():
    d = H.deliveries()
    km = [r['km'] for r in d]
    mi = [r['minutes'] for r in d]
    a, b = fit(km, mi)
    f = Fig('l06-scatter-image', 600, 340,
            'A scatterplot with no words: a rising cloud of points, dense at the lower left and '
            'sparse to the right, a straight line through it, and a numbered horizontal axis.')
    p = Plot(f, 50, 30, 570, 290, 0, 36, 0, 110)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.5)
    f.line(p.x0, p.y0, p.x0, p.y1, stroke='--paper-dim', width=1.5)
    for t in range(0, 37, 5):
        f.text(p.sx(t), p.y1 + 16, str(t), size=11, fill='--paper-dim', mono=True)
    for x, y in zip(km, mi):
        f.circle(p.sx(x), p.sy(y), 3, fill='--phosphor', opacity=0.55)
    f.line(p.sx(0), p.sy(a), p.sx(34.3), p.sy(a + b * 34.3), stroke='--amber', width=2.5)
    return f
