# Lesson 10 — small multiples.


def regions_by_last():
    m = monthly_by_region()
    return m, sorted(H.REGIONS, key=lambda r: m[r][-1], reverse=True)


@figure('l10-spaghetti', 10)
def l10_spaghetti(lang):
    m, order = regions_by_last()
    hues = {'Southeast': '#4f81bd', 'South': '#c0504d', 'Northeast': '#9bbb59',
            'Centre-West': '#8064a2', 'North': '#f79646'}
    w = {'en': dict(
        label='Five lines of monthly orders, one per region, all in different colours on one '
              'chart. Southeast runs along the top on its own. South and Northeast tangle and '
              'cross during 2025. Centre-West and North run close together near the bottom, and '
              'their shape is hard to see at this scale.',
        y='orders per month',
        cap='Five series on one chart. The top line is clear; the crossings in the middle and '
            'the two small regions at the bottom take work to read.'),
        'pt': dict(
        label='Cinco linhas de pedidos mensais, uma por região, todas em cores diferentes num '
              'gráfico só. O Sudeste corre sozinho no alto. Sul e Nordeste se embaraçam e se '
              'cruzam durante 2025. Centro-Oeste e Norte correm juntos perto do chão, e a forma '
              'deles é difícil de ver nessa escala.',
        y='pedidos por mês',
        cap='Cinco séries num gráfico. A linha de cima é clara; os cruzamentos do meio e as duas '
            'regiões pequenas embaixo dão trabalho para ler.')}[lang]
    f = Fig('l10-spaghetti', 600, 260, w['label'])
    p = Plot(f, 60, 40, 470, 220, 0, 23, 0, 9000)
    p.yaxis(range(0, 9001, 3000), fmt=lambda v: num(lang, v), label=w['y'], size=9)
    for r in order:
        p.series(range(24), m[r], stroke=hues[r], width=1.8)
    for r in order:
        f.text(p.x1 + 6, p.sy(m[r][-1]) + (6 if r == 'South' else -4 if r == 'Northeast' else 0),
               REGION[lang][r], size=9.5, anchor='start')
    return f, w['cap']


def multiples(f, m, order, lang, x0, y0, pw, ph, gap, shared=True, context=True):
    top = max(max(v) for v in m.values()) * 1.05
    for k, r in enumerate(order):
        px = x0 + k * (pw + gap)
        if shared:
            p = Plot(f, px, y0, px + pw, y0 + ph, 0, 23, 0, top)
        else:
            lo, hi = min(m[r]) * 0.95, max(m[r]) * 1.05
            p = Plot(f, px, y0, px + pw, y0 + ph, 0, 23, lo, hi)
        f.rect(px, y0, pw, ph, stroke='--wire', fill='--panel', rx=2, width=1)
        if context and shared:
            for o in order:
                if o != r:
                    p.series(range(24), m[o], stroke='--paper-dim', width=0.7)
        p.series(range(24), m[r], stroke='--phosphor', width=2)
        f.text(px + pw / 2, y0 - 10, REGION[lang][r], size=10, weight='600')
        if shared and k == 0 or not shared:
            lo_v = 0 if shared else round(min(m[r]) * 0.95, -2)
            hi_v = round(top, -3) - 1000 if shared else round(max(m[r]) * 1.05, -2)
            f.text(px - 4, p.sy(hi_v), num(lang, hi_v), size=8.5, anchor='end', fill='--paper-dim')
            f.text(px - 4, p.sy(lo_v), num(lang, lo_v), size=8.5, anchor='end', fill='--paper-dim')


@figure('l10-multiples', 10)
def l10_multiples(lang):
    m, order = regions_by_last()
    w = {'en': dict(
        label='The same five series as five small charts in a row, sorted by December 2025 '
              'orders from Southeast to North, all on one vertical scale from 0 to 9,000. In each '
              'panel one region is drawn in a strong line and the other four in faint grey behind '
              'it. Southeast sits high in its panel, Northeast climbs past the grey line of South, '
              'and North is a low line near the floor.',
        cap='One chart per region, one scale for all, and the other regions in grey behind each. '
            'Every line can be read on its own, and every comparison is still possible.'),
        'pt': dict(
        label='As mesmas cinco séries como cinco gráficos pequenos em fila, ordenados pelos pedidos '
              'de dezembro de 2025 do Sudeste ao Norte, todos numa escala vertical só, de 0 a 9.000. '
              'Em cada painel uma região é desenhada numa linha forte e as outras quatro em cinza '
              'fraco atrás. O Sudeste fica alto no seu painel, o Nordeste sobe passando a linha '
              'cinza do Sul, e o Norte é uma linha baixa perto do chão.',
        cap='Um gráfico por região, uma escala para todos, e as outras regiões em cinza atrás de '
            'cada um. Toda linha se lê sozinha, e toda comparação continua possível.')}[lang]
    f = Fig('l10-multiples', 660, 180, w['label'])
    multiples(f, m, order, lang, 50, 40, 112, 120, 9)
    return f, w['cap']


@figure('l10-free', 10)
def l10_free(lang):
    m, order = regions_by_last()
    w = {'en': dict(
        label='The five regional series again as five small charts, but each panel now has its '
              'own vertical scale fitted to its own data, from about 4,900 to 8,600 for Southeast '
              'down to about 400 to 1,500 for North. Every line fills its panel, and the five look '
              'almost the same size.',
        cap='Each panel scaled to itself. The shapes are easier to compare, and the sizes have '
            'disappeared: North looks as big as Southeast.'),
        'pt': dict(
        label='As cinco séries regionais de novo como cinco gráficos pequenos, mas agora cada '
              'painel tem a sua escala vertical ajustada ao próprio dado, de uns 4.900 a 8.600 no '
              'Sudeste até uns 400 a 1.500 no Norte. Toda linha enche o seu painel, e as cinco '
              'parecem quase do mesmo tamanho.',
        cap='Cada painel na sua escala. As formas ficam mais fáceis de comparar, e os tamanhos '
            'sumiram: o Norte parece tão grande quanto o Sudeste.')}[lang]
    f = Fig('l10-free', 680, 180, w['label'])
    multiples(f, m, order, lang, 50, 40, 100, 120, 28, shared=False)
    return f, w['cap']


@image('l10-grid.svg', 10)
def l10_grid_image():
    m, order = regions_by_last()
    f = Fig('l10-grid-image', 640, 200,
            'Five small line charts in a row with no words, all on the same scale. In each, one '
            'line is strong and four are faint grey behind it. The strong line sits high in the '
            'first panel and lower in each panel after it.')
    top = max(max(v) for v in m.values()) * 1.05
    for k, r in enumerate(order):
        px = 20 + k * 124
        p = Plot(f, px, 30, px + 112, 170, 0, 23, 0, top)
        f.rect(px, 30, 112, 140, stroke='--paper-dim', fill='--panel', rx=2, width=1)
        for o in order:
            if o != r:
                p.series(range(24), m[o], stroke='--wire', width=1.4)
        p.series(range(24), m[r], stroke='--phosphor', width=2.4)
    return f
