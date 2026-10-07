# Lesson 7 — heatmaps and correlation matrices.

DAYS = {'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        'pt': ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom']}
CORR_COLS = ['km', 'items', 'rain', 'basket', 'minutes']


def week_grid():
    g = {}
    for r in H.hourly_orders():
        g[(r['day'], r['hour'])] = r['orders']
    return g


def corr_matrix():
    d = H.deliveries()
    cols = {c: [float(r[c]) for r in d] for c in CORR_COLS}

    def r(a, b):
        xa, xb = cols[a], cols[b]
        n = len(xa)
        ma, mb = sum(xa) / n, sum(xb) / n
        sab = sum((x - ma) * (y - mb) for x, y in zip(xa, xb))
        saa = sum((x - ma) ** 2 for x in xa)
        sbb = sum((y - mb) ** 2 for y in xb)
        return sab / math.sqrt(saa * sbb)
    return {(a, b): r(a, b) for a in CORR_COLS for b in CORR_COLS}


def cell(f, x, y, w, h, v, vmax, text=None, signed=False):
    """A heatmap cell: the strength is opacity of one colour, and text is drawn in whichever
    of ink or paper reads against it."""
    strength = abs(v) / vmax
    colour = '--amber' if signed and v < 0 else '--phosphor'
    f.rect(x, y, w, h, stroke='--panel', fill='--panel', width=1, rx=0)
    f.rect(x, y, w, h, stroke='--panel', fill=colour, width=1, rx=0,
           opacity=round(0.06 + 0.94 * strength, 2))
    if text is not None:
        f.text(x + w / 2, y + h / 2, text, size=10, mono=True,
               fill='--ink' if strength > 0.5 else '--paper')


@figure('l07-week', 7)
def l07_week(lang):
    g = week_grid()
    vmax = max(g.values())
    w = {'en': dict(
        label='A heatmap of orders in an ordinary week: seven rows, Monday to Sunday, and fifteen '
              'columns, 8:00 to 22:00. A stronger blue means more orders. On weekdays two bands '
              'appear, a modest one at lunch and a strong one at 19:00, where every weekday has its '
              'busiest hour. Saturday and Sunday look different: the strongest cells are in the late '
              'morning, around 11:00, with 182 and 189 orders.',
        lo='fewer', hi='more orders',
        cap='Seven times fifteen numbers, read in one glance. The weekday evening rush and the '
            'weekend morning are two patterns a table of 105 numbers would hide.'),
        'pt': dict(
        label='Um mapa de calor dos pedidos numa semana comum: sete linhas, de segunda a domingo, e '
              'quinze colunas, das 8h às 22h. Um azul mais forte quer dizer mais pedidos. Nos dias úteis '
              'aparecem duas faixas, uma modesta no almoço e uma forte às 19h, onde todo dia útil '
              'tem a sua hora mais cheia. Sábado e domingo são diferentes: as células mais fortes '
              'ficam no fim da manhã, por volta das 11h, com 182 e 189 pedidos.',
        lo='menos', hi='mais pedidos',
        cap='Sete vezes quinze números, lidos num relance. O pico da noite nos dias úteis e a manhã '
            'do fim de semana são dois padrões que uma tabela de 105 números esconderia.')}[lang]
    f = Fig('l07-week', 620, 270, w['label'])
    x0, y0, cw, ch = 70, 20, 34, 28
    days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    for i, d in enumerate(days):
        f.text(x0 - 10, y0 + i * ch + ch / 2, DAYS[lang][i], size=10, anchor='end')
        for j, hour in enumerate(range(8, 23)):
            cell(f, x0 + j * cw, y0 + i * ch, cw, ch, g[(d, hour)], vmax)
    for j, hour in enumerate(range(8, 23)):
        if hour % 2 == 0:
            f.text(x0 + j * cw + cw / 2, y0 + 7 * ch + 12, f'{hour}h', size=9, fill='--paper-dim')
    for k in range(10):
        cell(f, 360 + k * 18, 248, 18, 12, (k + 0.5) / 10, 1)
    f.text(354, 254, w['lo'], size=9, anchor='end', fill='--paper-dim')
    f.text(546, 254, w['hi'], size=9, anchor='start', fill='--paper-dim')
    return f, w['cap']


def corr_grid(f, x0, y0, order, m, size=46, text=True, half=False, names=None, lang='en'):
    for i, a in enumerate(order):
        f.text(x0 - 8, y0 + i * size + size / 2, (names or {}).get(a, a), size=10, anchor='end',
               mono=True)
        f.text(x0 + i * size + size / 2, y0 - 10, (names or {}).get(a, a), size=10, mono=True)
        for j, b in enumerate(order):
            if half and j > i:
                continue
            v = m[(a, b)]
            cell(f, x0 + j * size, y0 + i * size, size, size, v, 1,
                 num(lang, v, 2) if text else None, signed=True)


@figure('l07-order', 7)
def l07_order(lang):
    m = corr_matrix()
    w = {'en': dict(
        label='The same correlation matrix of five delivery variables drawn twice. On the left the '
              'variables are in the order of the file, km, items, rain, basket, minutes, and the two '
              'strong pairs sit apart as scattered strong cells. On the right they are reordered as '
              'items, basket, minutes, km, rain, and the strong pairs form two strong blocks next to '
              'the diagonal: items with basket, and minutes with km.',
        a='the order of the file', b='reordered to group',
        cap='Rows and columns have no natural order here, so choose one that puts related '
            'variables side by side. The strong pairs then form blocks instead of a scatter of '
            'squares.'),
        'pt': dict(
        label='A mesma matriz de correlação de cinco variáveis de entrega desenhada duas vezes. À '
              'esquerda as variáveis estão na ordem do arquivo, km, items, rain, basket, minutes, e '
              'os dois pares fortes ficam separados como células fortes espalhadas. À direita elas '
              'são reordenadas como items, basket, minutes, km, rain, e os pares fortes formam dois '
              'blocos fortes junto à diagonal: items com basket, e minutes com km.',
        a='a ordem do arquivo', b='reordenada para agrupar',
        cap='Linhas e colunas não têm ordem natural aqui, então escolha uma que ponha variáveis '
            'relacionadas lado a lado. Os pares fortes formam blocos em vez de quadrados '
            'espalhados.')}[lang]
    f = Fig('l07-order', 640, 250, w['label'])
    corr_grid(f, 70, 50, CORR_COLS, m, size=34, text=False)
    corr_grid(f, 400, 50, ['items', 'basket', 'minutes', 'km', 'rain'], m, size=34, text=False)
    f.text(155, 18, w['a'], size=10.5, weight='600')
    f.text(485, 18, w['b'], size=10.5, weight='600')
    return f, w['cap']


@figure('l07-annotated', 7)
def l07_annotated(lang):
    m = corr_matrix()
    w = {'en': dict(
        label='The lower half of the correlation matrix, reordered, with each correlation written '
              'in its cell to two decimal places. The diagonal of ones is kept as a border. Items '
              'and basket have 0.95, minutes and km 0.88, minutes and rain 0.26, and every other '
              'pair is below 0.25. A colour scale beside it runs from −1 in red through 0 to +1 in '
              'blue.',
        neg='−1', zero='0', pos='+1',
        cap='Half the matrix, because the other half is its mirror, and the number in every cell, '
            'because colour tells the reader where to look and the number tells them what they '
            'found.'),
        'pt': dict(
        label='A metade de baixo da matriz de correlação, reordenada, com cada correlação escrita '
              'na sua célula com duas casas decimais. A diagonal de uns fica como borda. Items e '
              'basket têm 0,95, minutes e km 0,88, minutes e rain 0,26, e todo outro par fica '
              'abaixo de 0,25. Uma escala de cor ao lado vai de −1 em vermelho, passando por 0, a '
              '+1 em azul.',
        neg='−1', zero='0', pos='+1',
        cap='Meia matriz, porque a outra metade é o espelho dela, e o número em cada célula, porque '
            'a cor diz ao leitor para onde olhar e o número diz o que ele achou.')}[lang]
    f = Fig('l07-annotated', 560, 300, w['label'])
    corr_grid(f, 90, 40, ['items', 'basket', 'minutes', 'km', 'rain'], m, size=48, half=True,
              lang=lang)
    for k in range(21):
        v = -1 + k / 10
        cell(f, 400 + 0 * k, 40 + (20 - k) * 11, 18, 11, v, 1, signed=True)
    f.text(424, 40 + 20 * 11 + 6, w['neg'], size=9.5, anchor='start', mono=True)
    f.text(424, 40 + 10 * 11 + 6, w['zero'], size=9.5, anchor='start', mono=True)
    f.text(424, 46, w['pos'], size=9.5, anchor='start', mono=True)
    return f, w['cap']


@image('l07-week.svg', 7)
def l07_week_image():
    g = week_grid()
    vmax = max(g.values())
    f = Fig('l07-week-image', 600, 300,
            'A heatmap with no words: seven rows and fifteen columns of cells shaded from pale to '
            'dark, with no labels on either axis.')
    x0, y0, cw, ch = 30, 30, 36, 34
    days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    for i, d in enumerate(days):
        for j, hour in enumerate(range(8, 23)):
            cell(f, x0 + j * cw, y0 + i * ch, cw, ch, g[(d, hour)], vmax)
    return f
