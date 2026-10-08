# Lesson 14 — accessibility. The simulation uses the same matrix as access.py in the lesson's
# captures: Machado, Oliveira and Fernandes (2009), full deuteranopia, on linear RGB.

DEUTAN = [[0.367322, 0.860646, -0.227968],
          [0.280085, 0.672501, 0.047413],
          [-0.011820, 0.042940, 0.968881]]
TAB_RED, TAB_GREEN, TAB_BLUE = '#d62728', '#2ca02c', '#1f77b4'


def deutan(hx):
    rgb = [lin(int(hx[i:i + 2], 16) / 255) for i in (1, 3, 5)]
    out = [sum(m * c for m, c in zip(row, rgb)) for row in DEUTAN]
    return to_hex(*[unlin(c) for c in out])


def contrast(a, b):
    la, lb = sorted([luminance(a), luminance(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)


def two_lines(f, p, m, ca, cb, dashed=False, labels=None, markers=False):
    p.series(range(24), m['South'], stroke=ca, width=2.2)
    p.series(range(24), m['Northeast'], stroke=cb, width=2.2, dash='6 4' if dashed else None)
    if markers:
        for i in range(0, 24, 3):
            f.circle(p.sx(i), p.sy(m['Northeast'][i]), 3.2, fill=cb)
    if labels:
        f.text(p.x1 + 6, p.sy(m['South'][-1]) + 5, labels[0], size=9.5, anchor='start')
        f.text(p.x1 + 6, p.sy(m['Northeast'][-1]) - 3, labels[1], size=9.5, anchor='start')


@figure('l14-simulated', 14)
def l14_simulated(lang):
    m = monthly_by_region()
    w = {'en': dict(
        label='The same line chart of South and Northeast drawn twice. On the left, South is red '
              'and Northeast green, the default colours of many tools, with a legend. On the right, '
              'the same chart as a person with deuteranopia sees it: both lines become a similar '
              'olive brown, and where they cross in 2024 there is no way to tell which is which.',
        a='as drawn', b='as deuteranopia sees it',
        cap='Red and green, the pair most charts reach for first, become two olives for about one '
            'man in twelve. The crossing, the one thing the chart is for, disappears.'),
        'pt': dict(
        label='O mesmo gráfico de linhas de Sul e Nordeste desenhado duas vezes. À esquerda, o Sul é '
              'vermelho e o Nordeste verde, as cores padrão de muitas ferramentas, com legenda. À '
              'direita, o mesmo gráfico como uma pessoa com deuteranopia o vê: as duas linhas viram '
              'um marrom-oliva parecido, e onde elas se cruzam em 2024 não há como saber qual é '
              'qual.',
        a='como desenhado', b='como a deuteranopia vê',
        cap='Vermelho e verde, o par que a maioria dos gráficos escolhe primeiro, viram dois tons de '
            'oliva para cerca de um homem em cada doze. O cruzamento, a única coisa para que o '
            'gráfico serve, some.')}[lang]
    f = Fig('l14-simulated', 640, 240, w['label'])
    for k, (title, ca, cb) in enumerate(((w['a'], TAB_RED, TAB_GREEN),
                                         (w['b'], deutan(TAB_RED), deutan(TAB_GREEN)))):
        x0 = 30 + k * 320
        f.rect(x0, 30, 290, 190, stroke='--wire', fill='#ffffff', rx=4, width=1)
        p = Plot(f, x0 + 20, 50, x0 + 270, 200, 0, 23, 1500, 5300)
        two_lines(f, p, m, ca, cb)
        f.text(x0 + 145, 16, title, size=10.5, weight='600')
        for i, (c, r) in enumerate(((ca, 'South'), (cb, 'Northeast'))):
            f.line(x0 + 30, 62 + i * 16, x0 + 50, 62 + i * 16, stroke=c, width=2.2)
            f.text(x0 + 56, 62 + i * 16, REGION[lang][r], size=9.5, anchor='start',
                   fill='#20263c')
    return f, w['cap']


@figure('l14-contrast', 14)
def l14_contrast(lang):
    pairs = [('#767676', '#ffffff'), ('#c8ccd4', '#ffffff'), ('#2b52c9', '#ffffff'),
             (TAB_RED, TAB_GREEN)]
    w = {'en': dict(
        label='Four pairs of colours with their contrast ratios, against two thresholds marked on '
              'a scale: 3 to 1 for graphics and 4.5 to 1 for text. Mid grey on white, 4.54, passes '
              'both. Light grey on white, 1.61, fails both. This course\'s blue on white, 6.66, '
              'passes both. Red against green, 1.48, fails both.',
        g='graphics need 3:1', t='text needs 4.5:1',
        cap='Contrast is a ratio of luminances, from 1:1 for identical colours to 21:1 for black on '
            'white. WCAG 2.2 asks 4.5:1 for text and 3:1 for the parts of a chart a reader needs.'),
        'pt': dict(
        label='Quatro pares de cores com as suas razões de contraste, contra dois limites marcados '
              'numa escala: 3 para 1 para gráficos e 4,5 para 1 para texto. Cinza médio no branco, '
              '4,54, passa nos dois. Cinza claro no branco, 1,61, falha nos dois. O azul deste curso '
              'no branco, 6,66, passa nos dois. Vermelho contra verde, 1,48, falha nos dois.',
        g='gráficos pedem 3:1', t='texto pede 4,5:1',
        cap='Contraste é uma razão de luminâncias, de 1:1 para cores idênticas a 21:1 para preto no '
            'branco. A WCAG 2.2 pede 4,5:1 para texto e 3:1 para as partes de um gráfico de que o '
            'leitor precisa.')}[lang]
    f = Fig('l14-contrast', 600, 250, w['label'])
    p = Plot(f, 250, 30, 580, 220, 1, 8, 0, 4)
    for k, (a, b) in enumerate(pairs):
        y = 40 + k * 46
        f.rect(30, y, 60, 34, stroke='--wire', fill=b, rx=2, width=1)
        f.rect(46, y + 8, 28, 18, stroke=a, fill=a, rx=1, width=1)
        f.text(110, y + 17, f'{a} / {b}', size=9, anchor='start', mono=True, fill='--paper-dim')
        r = contrast(a, b)
        f.bar(p.x0, y + 7, p.sx(min(r, 8)) - p.x0, 20, stroke='--phosphor', fill='--phosphor-dim')
        f.text(p.sx(min(r, 8)) + 6, y + 17, num(lang, r, 2), size=9.5, anchor='start', mono=True)
    for v, label, dy in ((3, w['g'], 0), (4.5, w['t'], 12)):
        f.line(p.sx(v), 34, p.sx(v), 226, stroke='--amber', width=1.4, dash='4 3')
        f.text(p.sx(v) + 4, 236 - dy, label, size=9.5, anchor='start', fill='--amber')
    return f, w['cap']


@figure('l14-redundant', 14)
def l14_redundant(lang):
    m = monthly_by_region()
    ca, cb = deutan(TAB_RED), deutan(TAB_BLUE)
    w = {'en': dict(
        label='The South and Northeast chart redrawn for everyone and shown as deuteranopia sees '
              'it. South is a solid line and Northeast a dashed line with dots on it; Northeast is '
              'blue rather than green, so the two still differ in hue; and each line is named at its '
              'right-hand end, so no legend is needed.',
        cap='Three cues instead of one: the hue differs, the line style differs, and the name sits '
            'on the line. Any one of them can fail and the chart still reads.'),
        'pt': dict(
        label='O gráfico de Sul e Nordeste redesenhado para todos e mostrado como a deuteranopia o '
              'vê. O Sul é uma linha contínua e o Nordeste uma linha tracejada com pontos; o '
              'Nordeste é azul e não verde, então os dois ainda diferem no matiz; e cada linha tem o '
              'nome na ponta direita, então nenhuma legenda é necessária.',
        cap='Três pistas em vez de uma: o matiz difere, o estilo da linha difere, e o nome fica na '
            'linha. Qualquer uma pode falhar e o gráfico ainda se lê.')}[lang]
    f = Fig('l14-redundant', 460, 230, w['label'])
    f.rect(20, 20, 420, 190, stroke='--wire', fill='#ffffff', rx=4, width=1)
    p = Plot(f, 40, 40, 330, 190, 0, 23, 1500, 5300)
    two_lines(f, p, m, ca, cb, dashed=True, markers=True)
    f.text(p.x1 + 8, p.sy(m['South'][-1]) + 6, REGION[lang]['South'], size=10, anchor='start',
           fill='#20263c')
    f.text(p.x1 + 8, p.sy(m['Northeast'][-1]) - 4, REGION[lang]['Northeast'], size=10,
           anchor='start', fill='#20263c')
    return f, w['cap']


@image('l14-faults.svg', 14)
def l14_faults_image():
    m = monthly_by_region()
    f = Fig('l14-faults-image', 600, 320,
            'A line chart with no words: a very faint grey stroke across the top where a title '
            'would be, a red line and a green line that cross, a dashed blue line lower down with a '
            'dark stroke at its right-hand end where its name would be, and a legend box with a red '
            'and a green swatch.')
    f.rect(30, 22, 300, 14, stroke='#e4e7ee', fill='#e4e7ee', rx=3, width=1)
    p = Plot(f, 40, 60, 460, 290, 0, 23, 500, 5300)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.5)
    p.series(range(24), m['South'], stroke=TAB_RED, width=2.6)
    p.series(range(24), m['Northeast'], stroke=TAB_GREEN, width=2.6)
    p.series(range(24), m['Centre-West'], stroke=TAB_BLUE, width=2.6, dash='7 4')
    f.rect(p.x1 + 8, p.sy(m['Centre-West'][-1]) - 6, 70, 12, stroke='#20263c', fill='#20263c', rx=2,
           width=1)
    f.rect(480, 70, 100, 56, stroke='--paper-dim', fill='--panel', rx=3, width=1)
    f.rect(492, 82, 14, 12, stroke=TAB_RED, fill=TAB_RED, rx=1, width=1)
    f.rect(512, 84, 54, 8, stroke='--wire', fill='--wire', rx=2, width=1)
    f.rect(492, 104, 14, 12, stroke=TAB_GREEN, fill=TAB_GREEN, rx=1, width=1)
    f.rect(512, 106, 54, 8, stroke='--wire', fill='--wire', rx=2, width=1)
    return f
