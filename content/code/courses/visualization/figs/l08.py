# Lesson 8 — maps.

# One square per state, placed roughly where the state is. Column, row.
TILES = {
    'RR': (1, 0), 'AP': (2, 0),
    'AM': (1, 1), 'PA': (2, 1), 'MA': (3, 1), 'CE': (4, 1), 'RN': (5, 1),
    'AC': (0, 2), 'RO': (1, 2), 'TO': (2, 2), 'PI': (3, 2), 'PE': (4, 2), 'PB': (5, 2),
    'MT': (1, 3), 'GO': (2, 3), 'BA': (3, 3), 'SE': (4, 3), 'AL': (5, 3),
    'MS': (1, 4), 'DF': (2, 4), 'MG': (3, 4), 'ES': (4, 4),
    'PR': (2, 5), 'SP': (3, 5), 'RJ': (4, 5),
    'SC': (2, 6),
    'RS': (2, 7),
}


def rate(s):
    o, p = H.STATES[s]
    return o / (p * 1000)


def tile_map(f, x0, y0, size, value, vmax, labels=True, gap=3):
    for s, (c, r) in TILES.items():
        x, y = x0 + c * size, y0 + r * size
        v = value(s) / vmax
        f.rect(x, y, size - gap, size - gap, stroke='--wire', fill='--panel', rx=2, width=1)
        f.rect(x, y, size - gap, size - gap, stroke='--wire', fill='--phosphor', rx=2, width=1,
               opacity=round(0.06 + 0.94 * v, 2))
        if labels:
            alpha = round(0.06 + 0.94 * v, 2)
            ink = ink_on('--phosphor', alpha)
            cx, cy = x + (size - gap) / 2, y + (size - gap) / 2
            if ink is None:
                # A mid tint has no ink that reads on it in both themes, so the label gets a chip
                # of the panel under it, and the tint still shows around the chip.
                f.rect(cx - 9, cy - 6, 18, 12, stroke='--panel', fill='--panel', rx=2, width=1)
                ink = '--paper'
            f.text(cx, cy, s, size=9, mono=True, fill=ink)


@figure('l08-counts-vs-rates', 8)
def l08_counts_vs_rates(lang):
    w = {'en': dict(
        label='Two maps of Brazil drawn as one square per state. On the left each square is shaded '
              'by Horta\'s total orders, and São Paulo is the only strong square, with Rio de '
              'Janeiro, Minas Gerais and the southern states paler, and almost everything else '
              'faint. On the right each square is shaded by orders per thousand people, and the '
              'picture changes: the Federal District is strongest, the South and Southeast are '
              'strong, and the North is faint.',
        a='total orders', b='orders per 1,000 people',
        cap='Shaded by count, the map mostly shows where people live. Shaded by rate, it shows '
            'where Horta does well, which is the question a map of a business usually asks.'),
        'pt': dict(
        label='Dois mapas do Brasil desenhados como um quadrado por estado. À esquerda cada '
              'quadrado é pintado pelo total de pedidos da Horta, e São Paulo é o único quadrado '
              'forte, com Rio de Janeiro, Minas Gerais e os estados do Sul mais claros, e quase '
              'todo o resto fraco. À direita cada quadrado é pintado pelos pedidos por mil '
              'habitantes, e a figura muda: o Distrito Federal é o mais forte, o Sul e o Sudeste '
              'são fortes, e o Norte é fraco.',
        a='total de pedidos', b='pedidos por 1.000 habitantes',
        cap='Pintado pela contagem, o mapa mostra sobretudo onde as pessoas moram. Pintado pela '
            'taxa, mostra onde a Horta vai bem, que é a pergunta que um mapa de um negócio '
            'costuma fazer.')}[lang]
    f = Fig('l08-counts-vs-rates', 600, 330, w['label'])
    tile_map(f, 40, 40, 34, lambda s: H.STATES[s][0], max(o for o, _ in H.STATES.values()))
    tile_map(f, 340, 40, 34, rate, max(rate(s) for s in H.STATES))
    f.text(142, 20, w['a'], size=10.5, weight='600')
    f.text(442, 20, w['b'], size=10.5, weight='600')
    return f, w['cap']


@figure('l08-classes', 8)
def l08_classes(lang):
    rs = sorted(rate(s) for s in H.STATES)
    lo, hi = rs[0], rs[-1]
    eq = [lo + (hi - lo) * k / 4 for k in range(5)]
    n = len(rs)

    def pct(q):
        pos = (n - 1) * q
        i = int(pos)
        return rs[i] + (rs[min(i + 1, n - 1)] - rs[i]) * (pos - i)
    qu = [pct(k / 4) for k in range(5)]
    w = {'en': dict(
        label='The 27 state rates drawn as dots along a line from 0.23 to 1.96 orders per thousand '
              'people, twice, each time with four classes marked. With equal intervals, the breaks '
              'are at 0.66, 1.09 and 1.52, and 21 of the states fall into the two lowest classes. With '
              'quantiles, the breaks are at 0.44, 0.68 and 1.01, and each class holds about a '
              'quarter of the states.',
        a='equal intervals', b='quantiles', x='orders per 1,000 people',
        cap='The same 27 numbers, cut into four classes two ways. The map\'s colours will look '
            'completely different depending on which cut is chosen, so the choice belongs in the '
            'legend.'),
        'pt': dict(
        label='As taxas dos 27 estados desenhadas como pontos numa linha de 0,23 a 1,96 pedido por '
              'mil habitantes, duas vezes, cada uma com quatro classes marcadas. Com intervalos '
              'iguais, os cortes ficam em 0,66, 1,09 e 1,52, e 21 dos estados caem nas duas '
              'classes mais baixas. Com quantis, os cortes ficam em 0,44, 0,68 e 1,01, e cada classe '
              'guarda cerca de um quarto dos estados.',
        a='intervalos iguais', b='quantis', x='pedidos por 1.000 habitantes',
        cap='Os mesmos 27 números, cortados em quatro classes de dois jeitos. As cores do mapa vão '
            'parecer completamente diferentes conforme o corte escolhido, então a escolha vai na '
            'legenda.')}[lang]
    f = Fig('l08-classes', 600, 270, w['label'])
    for k, (breaks, title) in enumerate(((eq, w['a']), (qu, w['b']))):
        y = 60 + k * 90
        p = Plot(f, 60, y - 20, 560, y + 20, 0, 2.1, 0, 1)
        f.text(60, y - 30, title, size=10.5, anchor='start', weight='600')
        for c in range(4):
            a, b = breaks[c], breaks[c + 1]
            f.bar(p.sx(a), y - 14, p.sx(b) - p.sx(a), 28, stroke='--wire', fill='--phosphor',
                  width=1, opacity=round(0.12 + 0.25 * c, 2))
        for i, v in enumerate(rs):
            f.circle(p.sx(v), y + (5 if i % 2 else -5), 3.2, fill='--amber')
        for v in breaks[1:4]:
            f.text(p.sx(v), y + 26, num(lang, v, 2), size=9, mono=True, fill='--paper-dim')
    p = Plot(f, 60, 200, 560, 220, 0, 2.1, 0, 1)
    p.xaxis([0, 0.5, 1.0, 1.5, 2.0], fmt=lambda v: num(lang, v, 1), label=w['x'], size=9)
    return f, w['cap']


@figure('l08-symbols', 8)
def l08_symbols(lang):
    top = max(o for o, _ in H.STATES.values())
    w = {'en': dict(
        label='Brazil as one square per state, all squares the same pale grey, with a circle on '
              'each whose area is the state\'s total orders. São Paulo\'s circle overflows its '
              'square; Rio de Janeiro, Minas Gerais, Paraná, Rio Grande do Sul and Santa Catarina '
              'have middle-sized circles, and the northern states have dots.',
        note='circle area = orders in 2025',
        cap='A count belongs on a symbol, not on a shade: the circle grows with the number '
            'whatever the size of the state underneath it.'),
        'pt': dict(
        label='O Brasil como um quadrado por estado, todos no mesmo cinza claro, com um círculo em '
              'cada um cuja área é o total de pedidos do estado. O círculo de São Paulo transborda '
              'o quadrado; Rio de Janeiro, Minas Gerais, Paraná, Rio Grande do Sul e Santa Catarina '
              'têm círculos médios, e os estados do Norte têm pontinhos.',
        note='área do círculo = pedidos em 2025',
        cap='Uma contagem vai num símbolo, não num tom: o círculo cresce com o número, seja qual '
            'for o tamanho do estado embaixo dele.')}[lang]
    f = Fig('l08-symbols', 420, 330, w['label'])
    size = 36
    x0, y0 = 40, 30
    for s, (c, r) in TILES.items():
        f.rect(x0 + c * size, y0 + r * size, size - 3, size - 3, stroke='--wire', fill='--scan',
               rx=2, width=1)
    for s in sorted(TILES, key=lambda s: -H.STATES[s][0]):
        c, r = TILES[s]
        rad = 26 * math.sqrt(H.STATES[s][0] / top)
        f.circle(x0 + c * size + 16.5, y0 + r * size + 16.5, max(rad, 1.5), fill='--phosphor',
                 stroke='--panel', width=1, opacity=0.75)
    f.text(410, 312, w['note'], size=9.5, anchor='end', fill='--paper-dim')
    return f, w['cap']


def ellipse_path(cx, cy, rx, ry, n=36):
    pts = [(cx + rx * math.cos(2 * math.pi * k / n), cy + ry * math.sin(2 * math.pi * k / n))
           for k in range(n)]
    return 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + ' Z'


@figure('l08-projections', 8)
def l08_projections(lang):
    w = {'en': dict(
        label='Two flat projections of the same globe, each with a grid of meridians and '
              'parallels every 30 degrees and identical small circles placed on the globe at the '
              'equator and at 30 and 60 degrees north and south. In Mercator, on the left, the '
              'circles stay round but grow towards the poles: at 60 degrees they are twice as wide '
              'and four times the area. In the equal-area projection, on the right, every circle '
              'keeps its area but is squashed into a flatter ellipse towards the poles.',
        a='Mercator: shapes kept, areas inflated', b='equal-area: areas kept, shapes squashed',
        cap='Every flat map of a round Earth distorts something. Mercator keeps local shapes and '
            'inflates areas away from the equator; an equal-area projection keeps areas, which is '
            'what a shaded map needs.'),
        'pt': dict(
        label='Duas projeções planas do mesmo globo, cada uma com uma grade de meridianos e '
              'paralelos a cada 30 graus e círculos pequenos idênticos postos no globo no equador e '
              'a 30 e 60 graus norte e sul. Em Mercator, à esquerda, os círculos continuam redondos '
              'mas crescem em direção aos polos: a 60 graus têm o dobro da largura e quatro vezes a '
              'área. Na projeção de área igual, à direita, todo círculo mantém a área mas é '
              'achatado numa elipse em direção aos polos.',
        a='Mercator: formas mantidas, áreas infladas', b='área igual: áreas mantidas, formas achatadas',
        cap='Todo mapa plano de uma Terra redonda distorce alguma coisa. Mercator mantém as formas '
            'locais e infla as áreas longe do equador; uma projeção de área igual mantém as áreas, '
            'que é do que um mapa pintado precisa.')}[lang]
    f = Fig('l08-projections', 640, 300, w['label'])
    r0 = 9.0
    for k, (title, proj) in enumerate(((w['a'], 'merc'), (w['b'], 'eqa'))):
        x0, x1 = 20 + k * 320, 300 + k * 320
        cx = (x0 + x1) / 2
        span = x1 - x0
        sxp = span / (2 * math.pi)

        def Y(phi):
            if proj == 'merc':
                return math.log(math.tan(math.pi / 4 + phi / 2))
            return math.sin(phi)
        cy = 160
        sy = sxp  # the same scale both ways, so the projection's own distortion is all there is

        f.text(cx, 22, title, size=10, weight='600')
        for lon in range(-180, 181, 30):
            x = cx + sxp * math.radians(lon)
            f.line(x, cy - sy * Y(math.radians(72 if proj == 'merc' else 90)), x,
                   cy + sy * Y(math.radians(72 if proj == 'merc' else 90)), stroke='--wire',
                   width=1)
        for lat in (-60, -30, 0, 30, 60):
            y = cy - sy * Y(math.radians(lat))
            f.line(x0, y, x1, y, stroke='--wire' if lat else '--paper-dim', width=1)
        for lat in (-60, -30, 0, 30, 60):
            phi = math.radians(lat)
            for lon in (-120, -30, 60, 150):
                x = cx + sxp * math.radians(lon)
                y = cy - sy * Y(phi)
                if proj == 'merc':
                    rx = ry = r0 / math.cos(phi)
                else:
                    rx, ry = r0 / math.cos(phi), r0 * math.cos(phi)
                f.path(ellipse_path(x, y, rx, ry), stroke='--amber', fill='--amber', width=1,
                       opacity=0.35)
    return f, w['cap']


@image('l08-tiles.svg', 8)
def l08_tiles_image():
    f = Fig('l08-tiles-image', 420, 340,
            'A tile map of Brazil with no words: one square per state in a rough outline of the '
            'country, each shaded by Horta orders per thousand people, from faint to strong.')
    tile_map(f, 90, 20, 38, rate, max(rate(s) for s in H.STATES), labels=False)
    return f
