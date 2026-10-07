# Lesson 1 — visual encoding.


def totals_2025():
    t = {r: 0 for r in H.REGIONS}
    for row in H.monthly_orders():
        if row['month'].startswith('2025'):
            t[row['region']] += row['orders']
    return t


@figure('l01-anatomy', 1)
def l01_anatomy(lang):
    t = totals_2025()
    order = sorted(H.REGIONS, key=t.get, reverse=True)
    w = {'en': dict(
        label='A bar chart of Horta\'s orders in 2025 by region, from Southeast with '
              '77,567 down to North with 11,852, with three notes pointing into it. One '
              'points at a bar: the mark. One points along the bar\'s length: the channel '
              'that carries the number. One points at the column of region names: the '
              'position that says which bar is which region.',
        mark='mark: one bar per region', chan='channel: length, read against the axis',
        cat='channel: position down the page names the region',
        x='orders in 2025 (thousands)',
        cap='Every chart is marks and channels. Here the mark is a bar, the length of each '
            'bar carries the number, and the bar\'s place in the column says which region '
            'it belongs to.'),
        'pt': dict(
        label='Um gráfico de barras dos pedidos da Horta em 2025 por região, do Sudeste com '
              '77.567 até o Norte com 11.852, com três notas apontando para ele. Uma aponta '
              'para uma barra: a marca. Uma aponta ao longo do comprimento da barra: o canal '
              'que carrega o número. Uma aponta para a coluna de nomes das regiões: a '
              'posição que diz qual barra é qual região.',
        mark='marca: uma barra por região', chan='canal: comprimento, lido contra o eixo',
        cat='canal: a posição na vertical diz a região',
        x='pedidos em 2025 (milhares)',
        cap='Todo gráfico é marcas e canais. Aqui a marca é uma barra, o comprimento de cada '
            'barra carrega o número, e o lugar da barra na coluna diz a que região ela '
            'pertence.')}[lang]
    f = Fig('l01-anatomy', 640, 300, w['label'])
    p = Plot(f, 120, 40, 430, 220, 0, 80, 0, 5)
    for i, r in enumerate(order):
        y = 50 + i * 34
        f.bar(p.sx(0), y, p.sx(t[r] / 1000) - p.sx(0), 22, stroke='--phosphor',
               fill='--phosphor-dim', rx=1)
        f.text(p.x0 - 8, y + 11, REGION[lang][r], size=10, anchor='end')
    p.xaxis(range(0, 81, 20), label=w['x'])
    f.line(p.x0, 44, p.x0, p.y1, stroke='--paper-dim', width=1.2)
    f.line(470, 61, p.sx(t[order[0]] / 1000) + 4, 61, stroke='--amber', width=1.4, arrow=True)
    f.text(474, 61, w['mark'], size=10, anchor='start', fill='--amber')
    yb = 50 + 1 * 34 + 11
    f.line(p.sx(0) + 4, yb + 18, p.sx(t[order[1]] / 1000) - 4, yb + 18, stroke='--amber',
           width=1.4, arrow=True)
    f.text(p.sx(t[order[1]] / 1000) + 12, yb + 18, w['chan'], size=10, anchor='start',
           fill='--amber')
    f.text(20, 276, w['cat'], size=10, anchor='start', fill='--amber')
    f.line(80, 266, 88, 208, stroke='--amber', width=1.4, arrow=True)
    return f, w['cap']


@figure('l01-six-ways', 1)
def l01_six_ways(lang):
    t = totals_2025()
    order = sorted(H.REGIONS, key=t.get, reverse=True)
    vals = [t[r] for r in order]
    top = max(vals)
    names = {'en': ['position', 'length', 'angle', 'area', 'lightness', 'hue'],
             'pt': ['posição', 'comprimento', 'ângulo', 'área', 'luminosidade', 'matiz']}[lang]
    w = {'en': dict(
        label='The same five numbers, Horta\'s 2025 orders for its five regions, drawn six '
              'ways. Position: five dots on one scale. Length: five bars. Angle: five slices '
              'of a pie. Area: five circles. Lightness: five squares from strong to faint. Hue: '
              'five squares in five different colours, which put the regions in no order at '
              'all. In every panel the regions run from the largest, Southeast, to the '
              'smallest, North.',
        cap='One table, six channels. In the first two you can say by how much one region '
            'beats another; by the fourth you are guessing, and the last one no longer says '
            'which region is larger at all.'),
        'pt': dict(
        label='Os mesmos cinco números, os pedidos de 2025 da Horta nas cinco regiões, '
              'desenhados de seis jeitos. Posição: cinco pontos numa escala. Comprimento: '
              'cinco barras. Ângulo: cinco fatias de uma pizza. Área: cinco círculos. '
              'Luminosidade: cinco quadrados do forte ao fraco. Matiz: cinco quadrados em '
              'cinco cores diferentes, que não põem as regiões em ordem nenhuma. Em todos os '
              'painéis as regiões vão da maior, Sudeste, à menor, Norte.',
        cap='Uma tabela, seis canais. Nos dois primeiros dá para dizer por quanto uma região '
            'passa a outra; no quarto você está chutando, e o último já não diz nem qual '
            'região é maior.')}[lang]
    f = Fig('l01-six-ways', 660, 330, w['label'])
    pw, ph = 200, 130
    for k in range(6):
        cx0 = 20 + (k % 3) * 215
        cy0 = 20 + (k // 3) * 155
        f.rect(cx0, cy0, pw, ph, stroke='--wire', fill='--panel', rx=6)
        f.text(cx0 + 10, cy0 + 14, names[k], size=10.5, anchor='start', weight='600')
        if k == 0:
            y = cy0 + 80
            f.line(cx0 + 15, y, cx0 + 185, y, stroke='--paper-dim', width=1)
            for i, v in enumerate(vals):
                x = cx0 + 15 + 170 * v / top
                f.circle(x, y, 5, fill='--phosphor')
                f.text(x, y - 13 if i % 2 == 0 else y + 14, str(i + 1), size=9, mono=True,
                       fill='--paper-dim')
        elif k == 1:
            for i, v in enumerate(vals):
                y = cy0 + 32 + i * 19
                f.bar(cx0 + 24, y, 160 * v / top, 13, stroke='--phosphor', fill='--phosphor-dim',
                       rx=1)
                f.text(cx0 + 14, y + 7, str(i + 1), size=9, mono=True, fill='--paper-dim')
        elif k == 2:
            cx, cy, r = cx0 + 100, cy0 + 75, 46
            a = 0
            s = sum(vals)
            for i, v in enumerate(vals):
                d = 360 * v / s
                f.wedge(cx, cy, r, a, a + d, fill='--phosphor-dim', stroke='--panel', width=2)
                mid = math.radians(a + d / 2 - 90)
                f.text(cx + (r + 12) * math.cos(mid), cy + (r + 12) * math.sin(mid), str(i + 1),
                       size=9, mono=True, fill='--paper-dim')
                a += d
        elif k == 3:
            x = cx0 + 14
            for i, v in enumerate(vals):
                r = 23 * math.sqrt(v / top)
                f.circle(x + r, cy0 + 75, r, fill='--phosphor-dim', stroke='--phosphor')
                f.text(x + r, cy0 + 75 + 23 + 10, str(i + 1), size=9, mono=True,
                       fill='--paper-dim')
                x += 2 * r + 5
        elif k == 4:
            for i, v in enumerate(vals):
                x = cx0 + 14 + i * 36
                f.rect(x, cy0 + 50, 30, 30, stroke='--wire', fill='--phosphor',
                       opacity=round(0.15 + 0.85 * v / top, 2), rx=2)
                f.text(x + 15, cy0 + 94, str(i + 1), size=9, mono=True, fill='--paper-dim')
        else:
            hues = ['#c0504d', '#4f81bd', '#9bbb59', '#8064a2', '#f79646']
            for i in range(5):
                x = cx0 + 14 + i * 36
                f.rect(x, cy0 + 50, 30, 30, stroke='--wire', fill=hues[(i * 2) % 5], rx=2)
                f.text(x + 15, cy0 + 94, str(i + 1), size=9, mono=True, fill='--paper-dim')
    return f, w['cap']


@figure('l01-ordered', 1)
def l01_ordered(lang):
    w = {'en': dict(
        label='Two rows of six squares. The top row changes lightness, from pale to dark blue, '
              'and anybody can put it in order. The bottom row changes hue, red, orange, '
              'green, blue, purple and pink, and there is no order to put it in that two '
              'people would agree on.',
        a='lightness: anyone can sort it', b='hue: nobody agrees on the order',
        cap='A channel that has an order can carry a quantity. Hue has none, so it is for '
            'telling categories apart and never for saying which is more.'),
        'pt': dict(
        label='Duas fileiras de seis quadrados. A de cima muda a luminosidade, de um azul '
              'claro a um escuro, e qualquer pessoa põe em ordem. A de baixo muda o matiz, '
              'vermelho, laranja, verde, azul, roxo e rosa, e não há ordem em que duas '
              'pessoas concordem.',
        a='luminosidade: todo mundo ordena', b='matiz: ninguém concorda com a ordem',
        cap='Um canal que tem ordem pode carregar uma quantidade. O matiz não tem nenhuma, '
            'então serve para separar categorias e nunca para dizer qual é mais.')}[lang]
    f = Fig('l01-ordered', 600, 200, w['label'])
    blues = ['#dbe4f7', '#b0c4ee', '#7f9fe3', '#5079d4', '#2b52c9', '#1a3380']
    hues = ['#d1495b', '#ed8b2d', '#5aa65a', '#3b7dd8', '#8a5cc7', '#d665a8']
    for i in range(6):
        f.rect(250 + i * 52, 30, 44, 44, stroke='--wire', fill=blues[i], rx=3)
        f.rect(250 + i * 52, 120, 44, 44, stroke='--wire', fill=hues[i], rx=3)
    f.text(236, 52, w['a'], size=10.5, anchor='end')
    f.text(236, 142, w['b'], size=10.5, anchor='end')
    return f, w['cap']


@image('l01-parts.svg', 1)
def l01_parts():
    f = Fig('l01-parts', 600, 340,
            'A scatter chart with no words on it: a horizontal axis along the bottom, a vertical '
            'axis on the left, about twenty points in two shapes, one point standing alone near '
            'the top right, and a legend box in the lower right corner.')
    f.line(60, 290, 570, 290, stroke='--paper-dim', width=1.5)
    f.line(60, 30, 60, 290, stroke='--paper-dim', width=1.5)
    for k in range(6):
        x = 60 + k * 100
        f.line(x, 290, x, 296, stroke='--paper-dim', width=1.2)
        y = 290 - k * 50
        f.line(54, y, 60, y, stroke='--paper-dim', width=1.2)
    pts = [(95, 250), (120, 236), (140, 245), (165, 222), (190, 210), (205, 228), (230, 196),
           (250, 205), (270, 180), (300, 170), (320, 186), (345, 150), (370, 160), (395, 132),
           (150, 200), (210, 175), (260, 150), (300, 140), (340, 118), (380, 100)]
    for i, (x, y) in enumerate(pts):
        if i < 14:
            f.circle(x, y, 6, fill='--phosphor', stroke='--panel', width=1)
        else:
            f.path(f'M{x} {y - 7} L{x + 7} {y + 5} L{x - 7} {y + 5} Z', stroke='--panel', width=1,
                   fill='--amber')
    f.circle(480, 80, 7, fill='--phosphor', stroke='--panel', width=1)
    f.rect(440, 220, 115, 52, stroke='--paper-dim', fill='--panel', rx=3)
    f.circle(458, 236, 6, fill='--phosphor')
    f.rect(472, 233, 66, 6, stroke='--wire', fill='--wire', rx=2)
    f.path('M458 249 L465 261 L451 261 Z', stroke='--amber', fill='--amber')
    f.rect(472, 253, 52, 6, stroke='--wire', fill='--wire', rx=2)
    return f
