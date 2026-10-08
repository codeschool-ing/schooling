# Lesson 17 — data-ink and visual noise.
#
# The pixel counts in l17-ratio are what `inkratio.py` printed in lesson 17's captures.
INK = {'cluttered': (94134, 45936), 'clean': (54780, 50295)}


def cat_bars(f, x0, y0, width, lang, step=26, bh=17, values=False, ticks=False, grid=None,
             fill='--phosphor-dim', stroke='--phosphor', names=True):
    cats = sorted(H.CATEGORIES.items(), key=lambda kv: -kv[1])
    p = Plot(f, x0, y0, x0 + width, y0 + step * len(cats), 0, 450, 0, len(cats))
    if grid:
        for v in range(0, 451, 100):
            f.line(p.sx(v), p.y0 - 2, p.sx(v), p.y1, stroke=grid[0], width=grid[1])
    for i, (n, v) in enumerate(cats):
        y = y0 + i * step + (step - bh) / 2
        f.bar(p.sx(0), y, p.sx(v) - p.sx(0), bh, stroke=stroke, fill=fill)
        if names:
            f.text(p.x0 - 6, y + bh / 2, CATEGORY[lang][n], size=9, anchor='end')
        if values:
            f.text(p.sx(v) + 4, y + bh / 2, str(v), size=8.5, anchor='start', mono=True)
    if ticks:
        for v in range(0, 451, 100):
            f.text(p.sx(v), p.y1 + 10, str(v), size=8, fill='--paper-dim')
    return p


@figure('l17-steps', 17)
def l17_steps(lang):
    w = {'en': dict(
        label='The same bar chart of revenue by category in four steps. First as a tool draws it: a '
              'grey background, a frame, heavy gridlines and a legend box for its single series. '
              'Second, the background and frame removed. Third, the gridlines made faint. Fourth, '
              'the gridlines and the axis numbers removed and each bar labelled with its value, '
              'with the unit in the title.',
        steps=('1  as the tool drew it', '2  no background, no frame', '3  a faint grid',
               '4  values on the bars'),
        leg='revenue', unit='Revenue, R$ thousand',
        cap='Each step removes ink that carried no data. Nothing the reader needs has gone; the '
            'bars have only become easier to see.'),
        'pt': dict(
        label='O mesmo gráfico de barras da receita por categoria em quatro passos. Primeiro como a '
              'ferramenta o desenha: fundo cinza, moldura, linhas de grade pesadas e uma caixa de '
              'legenda para a sua única série. Segundo, sem o fundo e a moldura. Terceiro, com as '
              'linhas de grade bem leves. Quarto, sem as linhas de grade e os números do eixo, com '
              'cada barra rotulada com o seu valor e a unidade no título.',
        steps=('1  como a ferramenta desenhou', '2  sem fundo, sem moldura', '3  uma grade leve',
               '4  valores nas barras'),
        leg='receita', unit='Receita, R$ mil',
        cap='Cada passo tira tinta que não carregava dado. Nada de que o leitor precisa saiu; as '
            'barras só ficaram mais fáceis de ver.')}[lang]
    f = Fig('l17-steps', 660, 452, w['label'])
    for k, title in enumerate(w['steps']):
        x0 = 100 + (k % 2) * 330
        y0 = 50 + (k // 2) * 222
        f.text(x0 - 80, y0 - 30, title, size=10.5, anchor='start', weight='600')
        if k == 0:
            f.rect(x0 - 4, y0 - 6, 214, 180, stroke='--paper', fill='--scan', rx=0, width=1.5)
        grid = [('--paper', 1.2), None, ('--wire', 0.8), None][k]
        if k == 1:
            grid = ('--paper', 1.2)
        p = cat_bars(f, x0, y0, 200, lang, ticks=k < 3, values=k == 3, grid=grid)
        if k < 3:
            f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1)
        if k == 0:
            f.bar(x0 + 120, y0 + 2, 82, 22, stroke='--paper-dim', fill='--panel', width=1)
            f.bar(x0 + 126, y0 + 8, 14, 10)
            f.text(x0 + 145, y0 + 13, w['leg'], size=9, anchor='start')
        if k == 3:
            f.text(x0 - 80, y0 - 12, w['unit'], size=9, anchor='start', fill='--paper-dim')
    return f, w['cap']


@figure('l17-ratio', 17)
def l17_ratio(lang):
    w = {'en': dict(
        label='Two stacked bars measuring the pixels of ink in the cluttered and the clean chart. '
              'Cluttered: 94,134 pixels of ink, of which 45,936 are bars, a data-ink ratio of 0.49. '
              'Clean: 54,780 pixels, of which 50,295 are bars, a ratio of 0.92.',
        names=('cluttered', 'clean'), data='bars', other='everything else', px='pixels of ink',
        cap='Measured on the two charts inkratio.py draws. The clean one uses 42% less ink, and its '
            'bars have more pixels, not fewer: the legend no longer covers the longest one.'),
        'pt': dict(
        label='Duas barras empilhadas medindo os pixels de tinta do gráfico poluído e do limpo. '
              'Poluído: 94.134 pixels de tinta, dos quais 45.936 são barras, uma razão dado-tinta de '
              '0,49. Limpo: 54.780 pixels, dos quais 50.295 são barras, uma razão de 0,92.',
        names=('poluído', 'limpo'), data='barras', other='todo o resto', px='pixels de tinta',
        cap='Medido nos dois gráficos que o inkratio.py desenha. O limpo usa 42% menos tinta, e as '
            'barras dele têm mais pixels, não menos: a legenda não cobre mais a mais longa.')}[lang]
    f = Fig('l17-ratio', 600, 190, w['label'])
    p = Plot(f, 110, 30, 520, 130, 0, 100000, 0, 2)
    for i, key in enumerate(('cluttered', 'clean')):
        ink, data = INK[key]
        y = 36 + i * 46
        f.bar(p.sx(0), y, p.sx(data) - p.sx(0), 28)
        f.bar(p.sx(data), y, p.sx(ink) - p.sx(data), 28, stroke='--paper-dim', fill='--scan')
        f.text(p.x0 - 8, y + 14, w['names'][i], size=10, anchor='end')
        f.text(p.sx(ink) + 6, y + 14, num(lang, data / ink, 2), size=10, anchor='start', mono=True,
               weight='600')
    p.xaxis(range(0, 100001, 25000), fmt=lambda v: num(lang, v), label=w['px'], size=9)
    f.bar(110, 172, 14, 10)
    f.text(130, 177, w['data'], size=9.5, anchor='start')
    f.bar(220, 172, 14, 10, stroke='--paper-dim', fill='--scan')
    f.text(240, 177, w['other'], size=9.5, anchor='start')
    return f, w['cap']


@figure('l17-grids', 17)
def l17_grids(lang):
    m = monthly_by_region()
    se = m['Southeast']
    w = {'en': dict(
        label='Southeast\'s monthly orders drawn three times. First with heavy dark gridlines every '
              '500 orders, which compete with the line. Second with faint gridlines every 1,000, '
              'which the eye can use when it wants a value and ignore otherwise. Third with no grid '
              'and only the first, last and peak values written on the line.',
        a='a heavy grid', b='a faint grid', c='no grid, a few values',
        cap='A grid is for looking values up. Drawn heavy, it competes with the data; drawn faint, '
            'it is there when wanted. When only a few values matter, writing them is better still.'),
        'pt': dict(
        label='Os pedidos mensais do Sudeste desenhados três vezes. Primeiro com linhas de grade '
              'pesadas e fortes a cada 500 pedidos, que competem com a linha. Segundo com linhas de '
              'grade leves a cada 1.000, que o olho usa quando quer um valor e ignora no resto do '
              'tempo. Terceiro sem grade e só com o primeiro, o último e o maior valor escritos na '
              'linha.',
        a='uma grade pesada', b='uma grade leve', c='sem grade, poucos valores',
        cap='Uma grade serve para consultar valores. Pesada, ela compete com o dado; leve, está lá '
            'quando é preciso. Quando só alguns valores importam, escrevê-los é melhor ainda.')}[lang]
    f = Fig('l17-grids', 660, 220, w['label'])
    for k, title in enumerate((w['a'], w['b'], w['c'])):
        x0 = 30 + k * 215
        p = Plot(f, x0, 40, x0 + 170, 190, 0, 23, 4500, 8500)
        f.text(x0, 18, title, size=10.5, anchor='start', weight='600')
        if k == 0:
            for v in range(4500, 8501, 500):
                f.line(p.x0, p.sy(v), p.x1, p.sy(v), stroke='--paper', width=1.3)
            for i in range(0, 24, 3):
                f.line(p.sx(i), p.y0, p.sx(i), p.y1, stroke='--paper', width=1.3)
        if k == 1:
            for v in range(5000, 8001, 1000):
                f.line(p.x0, p.sy(v), p.x1, p.sy(v), stroke='--wire', width=0.8)
        p.series(range(24), se, width=2.2)
        if k == 2:
            for i in (0, 23):
                f.circle(p.sx(i), p.sy(se[i]), 3, fill='--phosphor')
            f.text(p.sx(0), p.sy(se[0]) + 14, num(lang, se[0]), size=9, mono=True)
            f.text(p.sx(23) - 6, p.sy(se[23]), num(lang, se[23]), size=9, anchor='end', mono=True)
            f.circle(p.sx(11), p.sy(se[11]), 3, fill='--phosphor')
            f.text(p.sx(11), p.sy(se[11]) - 12, num(lang, se[11]), size=9, mono=True)
        else:
            for v in range(5000, 8001, 1000):
                f.text(p.x0 - 4, p.sy(v), num(lang, v), size=8, anchor='end', fill='--paper-dim')
    return f, w['cap']


@figure('l17-too-far', 17)
def l17_too_far(lang):
    w = {'en': dict(
        label='Two versions of the category chart. On the left, everything but the bars has been '
              'removed: no names, no values, no axis, so the reader sees six bars and cannot say '
              'what any of them is. On the right, the bars keep their names and values, and nothing '
              'else.',
        a='too far: only the bars', b='enough: names and values',
        cap='The aim is not the least ink possible. Names, units and values are not data in '
            'Tufte\'s sense, but a chart without them cannot be read.'),
        'pt': dict(
        label='Duas versões do gráfico de categorias. À esquerda, tudo menos as barras foi removido: '
              'sem nomes, sem valores, sem eixo, então o leitor vê seis barras e não sabe dizer o que '
              'é cada uma. À direita, as barras mantêm nomes e valores, e mais nada.',
        a='longe demais: só as barras', b='o bastante: nomes e valores',
        cap='O objetivo não é a menor tinta possível. Nomes, unidades e valores não são dado no '
            'sentido de Tufte, mas um gráfico sem eles não se lê.')}[lang]
    f = Fig('l17-too-far', 620, 210, w['label'])
    f.text(20, 18, w['a'], size=10.5, anchor='start', weight='600')
    cat_bars(f, 30, 40, 220, lang, names=False)
    f.text(320, 18, w['b'], size=10.5, anchor='start', weight='600')
    cat_bars(f, 400, 40, 180, lang, values=True)
    return f, w['cap']


@image('l17-junk.svg', 17)
def l17_junk_image():
    f = Fig('l17-junk-image', 600, 320,
            'A bar chart with no words: a thick frame around it, a grey background, heavy dark '
            'gridlines, a soft shadow offset behind each bar, and a legend box with one swatch.')
    f.rect(20, 20, 560, 280, stroke='--paper', fill='--scan', rx=0, width=3)
    p = Plot(f, 120, 60, 520, 260, 0, 450, 0, 6)
    for v in range(0, 451, 75):
        f.line(p.sx(v), 50, p.sx(v), 266, stroke='--paper', width=1.6)
    cats = sorted(H.CATEGORIES.values(), reverse=True)
    for i, v in enumerate(cats):
        y = 66 + i * 33
        f.bar(p.sx(0) + 5, y + 5, p.sx(v) - p.sx(0), 22, stroke='--paper-dim', fill='--paper-dim',
              opacity=0.5)
        f.bar(p.sx(0), y, p.sx(v) - p.sx(0), 22)
        f.rect(40, y + 6, 66, 10, stroke='--wire', fill='--wire', rx=2, width=1)
    f.rect(420, 34, 140, 30, stroke='--paper-dim', fill='--panel', rx=2, width=1)
    f.bar(430, 42, 16, 14)
    f.rect(454, 44, 90, 10, stroke='--wire', fill='--wire', rx=2, width=1)
    return f
