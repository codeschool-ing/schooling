# Lesson 12 — categorical, sequential and diverging palettes.
#
# The seven samples of each matplotlib colormap are the hex values `palettes.py` printed in
# lesson 12's captures, matplotlib 3.11.2. They are copied here so the figures show the
# colours the student's own run prints.

VIRIDIS = ['#440154', '#443983', '#31688e', '#21918c', '#35b779', '#90d743', '#fde725']
CIVIDIS = ['#00224e', '#2a3f6d', '#575d6d', '#7d7c78', '#a59c74', '#d2c060', '#fee838']
JET = ['#000080', '#0028ff', '#00d4ff', '#7dff7a', '#ffe600', '#ff4700', '#800000']
RDBU = ['#67001f', '#c94741', '#f7b799', '#f6f7f7', '#a7d0e4', '#3783bb', '#053061']
JET_L = [0.27, 0.47, 0.81, 0.90, 0.92, 0.66, 0.38]
VIRIDIS_L = [0.29, 0.40, 0.50, 0.60, 0.69, 0.80, 0.92]
# Okabe and Ito's palette for categories, designed to stay distinct for the common forms of
# colour blindness.
OKABE_ITO = ['#E69F00', '#56B4E9', '#009E73', '#F0E442', '#0072B2', '#D55E00', '#CC79A7',
             '#000000']


def swatch_row(f, x0, y, colours, w=36, h=30, gap=4):
    for i, c in enumerate(colours):
        f.rect(x0 + i * (w + gap), y, w, h, stroke='--wire', fill=c, rx=2, width=1)


@figure('l12-three-kinds', 12)
def l12_three_kinds(lang):
    w = {'en': dict(
        label='Three rows of swatches. Categorical: eight clearly different hues of similar '
              'weight, orange, sky blue, green, yellow, blue, vermilion, pink and black. '
              'Sequential: seven steps of viridis, from dark purple through blue and green to '
              'bright yellow, always getting lighter. Diverging: seven steps of a red-to-blue '
              'scale, dark red, light red, nearly white in the middle, light blue, dark blue.',
        a='categorical: kinds of thing', b='sequential: low to high',
        c='diverging: below and above a middle',
        cap='Three kinds of palette for three kinds of data. Hue separates kinds; lightness '
            'orders amounts; two hues meeting at a light middle show which side of a reference '
            'a value is on.'),
        'pt': dict(
        label='Três fileiras de amostras. Categórica: oito matizes bem diferentes de peso '
              'parecido, laranja, azul-celeste, verde, amarelo, azul, vermelhão, rosa e preto. '
              'Sequencial: sete passos do viridis, do roxo escuro, passando por azul e verde, ao '
              'amarelo vivo, sempre clareando. Divergente: sete passos de uma escala do vermelho ao '
              'azul, vermelho escuro, vermelho claro, quase branco no meio, azul claro, azul '
              'escuro.',
        a='categórica: tipos de coisa', b='sequencial: do baixo ao alto',
        c='divergente: abaixo e acima de um meio',
        cap='Três tipos de paleta para três tipos de dado. O matiz separa tipos; a luminosidade '
            'ordena quantidades; dois matizes que se encontram num meio claro mostram de que lado '
            'de uma referência um valor está.')}[lang]
    f = Fig('l12-three-kinds', 620, 220, w['label'])
    for k, (title, cols) in enumerate(((w['a'], OKABE_ITO), (w['b'], VIRIDIS), (w['c'], RDBU))):
        y = 30 + k * 66
        f.text(20, y - 12, title, size=10.5, anchor='start', weight='600')
        swatch_row(f, 20, y, cols)
    return f, w['cap']


def growth():
    t = {'2024': {r: 0 for r in H.REGIONS}, '2025': {r: 0 for r in H.REGIONS}}
    for row in H.monthly_orders():
        t[row['month'][:4]][row['region']] += row['orders']
    total = sum(t['2025'].values()) / sum(t['2024'].values()) - 1
    return {r: 100 * (t['2025'][r] / t['2024'][r] - 1 - total) for r in H.REGIONS}, 100 * total


STATE_REGION = {
    'North': ['AC', 'AM', 'AP', 'PA', 'RO', 'RR', 'TO'],
    'Northeast': ['AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE'],
    'Centre-West': ['DF', 'GO', 'MS', 'MT'],
    'Southeast': ['ES', 'MG', 'RJ', 'SP'],
    'South': ['PR', 'RS', 'SC'],
}


def diverging_colour(v, vmax):
    """Blue above zero, red below, near white at zero, on the RdBu samples."""
    x = max(-1.0, min(1.0, v / vmax))
    idx = 3 + 3 * x
    i = int(math.floor(idx))
    j = min(i + 1, 6)
    t = idx - i

    def mix(a, b):
        ca = [int(a[k:k + 2], 16) for k in (1, 3, 5)]
        cb = [int(b[k:k + 2], 16) for k in (1, 3, 5)]
        return '#' + ''.join(f'{round(p + (q - p) * t):02x}' for p, q in zip(ca, cb))
    return mix(RDBU[i], RDBU[j])


@figure('l12-diverging', 12)
def l12_diverging(lang):
    g, total = growth()
    w = {'en': dict(
        label=f'Brazil as one square per state, each coloured by how its region\'s growth from '
              f'2024 to 2025 compares with Horta\'s overall growth of {total:.1f}%. Blue is faster, '
              f'red is slower, and near white is about the same. North and Northeast are blue, '
              f'North the strongest; Centre-West is pale blue; South is nearly white; Southeast is '
              f'red.',
        lo='slower than the company', mid='same', hi='faster',
        cap=f'A diverging palette centred on the company\'s growth of {total:.1f}%. The middle '
            f'means something, so the colour says which side of it each region is on, and how '
            f'far.'),
        'pt': dict(
        label=f'O Brasil como um quadrado por estado, cada um pintado por como o crescimento da '
              f'sua região de 2024 a 2025 se compara com o crescimento geral da Horta de '
              f'{num("pt", total, 1)}%. Azul é mais rápido, vermelho é mais lento, e quase branco '
              f'é mais ou menos igual. Norte e Nordeste são azuis, o Norte o mais forte; o '
              f'Centro-Oeste é azul claro; o Sul é quase branco; o Sudeste é vermelho.',
        lo='mais lento que a empresa', mid='igual', hi='mais rápido',
        cap=f'Uma paleta divergente centrada no crescimento da empresa, de {num("pt", total, 1)}%. '
            f'O meio significa algo, então a cor diz de que lado dele cada região está, e quão '
            f'longe.')}[lang]
    f = Fig('l12-diverging', 560, 330, w['label'])
    vmax = max(abs(v) for v in g.values())
    for region, states in STATE_REGION.items():
        for s in states:
            c, r = TILES[s]
            f.rect(40 + c * 36, 20 + r * 36, 33, 33, stroke='--wire',
                   fill=diverging_colour(g[region], vmax), rx=2, width=1)
            f.text(40 + c * 36 + 16.5, 20 + r * 36 + 16.5, s, size=9, mono=True,
                   fill='#20263c' if abs(g[region]) / vmax < 0.6 else '#ffffff')
    for i in range(7):
        f.rect(320 + i * 30, 110, 30, 22, stroke='--wire', fill=RDBU[i], rx=0, width=1)
    f.text(320, 146, w['lo'], size=9.5, anchor='start', fill='--paper-dim')
    f.text(425, 98, w['mid'], size=9.5, fill='--paper-dim')
    f.text(530, 146, w['hi'], size=9.5, anchor='end', fill='--paper-dim')
    for k, r in enumerate(sorted(H.REGIONS, key=lambda r: -g[r])):
        sign = '+' if g[r] >= 0 else '−'
        f.text(320, 190 + k * 20, f'{REGION[lang][r]}: {sign}{num(lang, abs(g[r]), 1)} '
               f'{"pp" if lang == "en" else "p.p."}',
               size=10, anchor='start')
    return f, w['cap']


@figure('l12-rainbow', 12)
def l12_rainbow(lang):
    w = {'en': dict(
        label='Two colour scales, each with its perceived lightness plotted beneath. The rainbow, '
              'matplotlib\'s jet, goes dark blue, bright cyan, green, yellow, red, dark red; its '
              'lightness rises to a peak in the middle at 0.92 and falls again, so the lowest and '
              'highest values both look dark. Viridis goes from dark purple to bright yellow, and '
              'its lightness climbs steadily from 0.29 to 0.92.',
        a='jet (a rainbow)', b='viridis', y='perceived lightness',
        cap='A rainbow is brightest in the middle, so values near the middle look important and '
            'the two ends look alike. Viridis gets lighter at every step, so lighter always means '
            'more.'),
        'pt': dict(
        label='Duas escalas de cor, cada uma com a luminosidade percebida desenhada embaixo. O '
              'arco-íris, o jet do matplotlib, vai do azul escuro ao ciano vivo, verde, amarelo, '
              'vermelho e vermelho escuro; a luminosidade dele sobe até um pico no meio, em 0,92, e '
              'cai de novo, então os menores e os maiores valores parecem os dois escuros. O viridis '
              'vai do roxo escuro ao amarelo vivo, e a luminosidade dele sobe constante de 0,29 a '
              '0,92.',
        a='jet (um arco-íris)', b='viridis', y='luminosidade percebida',
        cap='Um arco-íris é mais claro no meio, então valores perto do meio parecem importantes e '
            'as duas pontas parecem iguais. O viridis clareia a cada passo, então mais claro quer '
            'dizer mais, sempre.')}[lang]
    f = Fig('l12-rainbow', 620, 270, w['label'])
    for k, (title, cols, ls) in enumerate(((w['a'], JET, JET_L), (w['b'], VIRIDIS, VIRIDIS_L))):
        x0 = 40 + k * 300
        f.text(x0, 20, title, size=10.5, anchor='start', weight='600')
        swatch_row(f, x0, 32, cols, w=34, h=34, gap=4)
        p = Plot(f, x0, 96, x0 + 6 * 38 + 34, 230, -0.5, 6.5, 0.2, 1.0)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1)
        f.line(p.x0, p.y0, p.x0, p.y1, stroke='--paper-dim', width=1)
        pts = [(p.sx(i), p.sy(v)) for i, v in enumerate(ls)]
        f.poly(pts, stroke='--amber', width=2)
        for x, y in pts:
            f.circle(x, y, 3.5, fill='--amber')
    f.text(40, 252, w['y'], size=9.5, anchor='start', fill='--paper-dim')
    return f, w['cap']


@image('l12-palettes.svg', 12)
def l12_palettes_image():
    f = Fig('l12-palettes-image', 600, 300,
            'Four rows of colour swatches with no words, each row a different palette.')
    for k, cols in enumerate((JET, RDBU, OKABE_ITO[:7], VIRIDIS)):
        swatch_row(f, 120, 25 + k * 68, cols, w=46, h=40, gap=6)
    return f
