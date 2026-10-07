# Lesson 15 — labels, legends, titles and annotations.


def ne_south(f, p, m, lang, direct=True, legend=False):
    p.series(range(24), m['South'], stroke='--paper-dim', width=1.8)
    p.series(range(24), m['Northeast'], stroke='--phosphor', width=2.6)
    if direct:
        f.text(p.x1 + 6, p.sy(m['Northeast'][-1]), REGION[lang]['Northeast'], size=10,
               anchor='start', fill='--phosphor', weight='600')
        f.text(p.x1 + 6, p.sy(m['South'][-1]) + 4, REGION[lang]['South'], size=10,
               anchor='start', fill='--paper-dim')
    if legend:
        x, y = p.x1 + 20, p.y0
        f.rect(x, y, 96, 46, stroke='--wire', fill='--panel', rx=3, width=1)
        f.line(x + 8, y + 14, x + 26, y + 14, stroke='--phosphor', width=2.6)
        f.text(x + 32, y + 14, REGION[lang]['Northeast'], size=9.5, anchor='start')
        f.line(x + 8, y + 32, x + 26, y + 32, stroke='--paper-dim', width=1.8)
        f.text(x + 32, y + 32, REGION[lang]['South'], size=9.5, anchor='start')


@figure('l15-titles', 15)
def l15_titles(lang):
    m = monthly_by_region()
    w = {'en': dict(
        label='The same chart of Northeast and South monthly orders drawn twice, with two different '
              'titles. The first title says only what the chart contains: monthly orders by '
              'region, 2024 to 2025. The second says what it shows: Northeast overtook South in '
              'October 2024 and kept pulling away.',
        a='Monthly orders by region, 2024–2025',
        b='Northeast overtook South in October 2024',
        b2='and kept pulling away',
        cap='A label title names the data and leaves the reader to find the point. A claim title '
            'states the point, and the chart becomes the evidence for it.'),
        'pt': dict(
        label='O mesmo gráfico dos pedidos mensais de Nordeste e Sul desenhado duas vezes, com dois '
              'títulos diferentes. O primeiro título diz só o que o gráfico contém: pedidos mensais '
              'por região, 2024 a 2025. O segundo diz o que ele mostra: o Nordeste passou o Sul em '
              'outubro de 2024 e continuou se afastando.',
        a='Pedidos mensais por região, 2024–2025',
        b='O Nordeste passou o Sul em outubro de 2024',
        b2='e continuou se afastando',
        cap='Um título-rótulo dá nome ao dado e deixa o leitor achar o ponto. Um título que afirma '
            'diz o ponto, e o gráfico vira a prova dele.')}[lang]
    f = Fig('l15-titles', 660, 230, w['label'])
    for k in range(2):
        x0 = 20 + k * 330
        f.text(x0, 20, w['a'] if k == 0 else w['b'], size=11, anchor='start', weight='600')
        if k == 1:
            f.text(x0, 36, w['b2'], size=11, anchor='start', weight='600')
        p = Plot(f, x0, 60, x0 + 230, 210, 0, 23, 1500, 5200)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1)
        ne_south(f, p, m, lang)
    return f, w['cap']


@figure('l15-legend', 15)
def l15_legend(lang):
    m = monthly_by_region()
    w = {'en': dict(
        label='Two versions of the Northeast and South chart. On the left the lines are identified '
              'by a legend box placed to the right of the chart, so the eye has to travel from each '
              'line to the box and back. On the right each line is named at its own end, in its '
              'own colour.',
        a='a legend', b='direct labels',
        cap='A legend is a lookup table. A direct label is the answer, at the place the eye already '
            'is, and it works for a reader who cannot tell the colours apart.'),
        'pt': dict(
        label='Duas versões do gráfico de Nordeste e Sul. À esquerda as linhas são identificadas por '
              'uma caixa de legenda posta à direita do gráfico, então o olho tem de ir de cada linha '
              'até a caixa e voltar. À direita cada linha tem o nome na própria ponta, na própria '
              'cor.',
        a='uma legenda', b='rótulos diretos',
        cap='Uma legenda é uma tabela de consulta. Um rótulo direto é a resposta, no lugar onde o '
            'olho já está, e funciona para um leitor que não distingue as cores.')}[lang]
    f = Fig('l15-legend', 660, 210, w['label'])
    for k in range(2):
        x0 = 20 + k * 340
        f.text(x0, 18, w['a'] if k == 0 else w['b'], size=10.5, anchor='start', weight='600')
        p = Plot(f, x0, 40, x0 + 190, 190, 0, 23, 1500, 5200)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1)
        ne_south(f, p, m, lang, direct=k == 1, legend=k == 0)
    return f, w['cap']


@figure('l15-annotated', 15)
def l15_annotated(lang):
    m = monthly_by_region()
    tot = [sum(m[r][i] for r in H.REGIONS) for i in range(24)]
    first = next(i for i, v in enumerate(tot) if v >= 15000 and i % 12 != 11)
    w = {'en': dict(
        label=f'Horta\'s total monthly orders with three annotations. A dashed reference line at '
              f'15,000 orders, crossed outside a December for the first time in June 2025. '
              f'A marked point and its value at each December peak, 16,663 and 20,586. A note under the January dips '
              f'saying each December falls back.',
        ref='15,000 a month', first=f'first ordinary month above: {MONTH_SHORT["en"][first % 12]} 2025',
        dec='December peaks', back='and falls back each January',
        y='orders per month',
        title='Orders nearly doubled in two years, with a December spike each year',
        cap='Annotations put the reading on the chart: a reference line to measure against, labels '
            'on the points that matter, a short note where the reader would otherwise wonder.'),
        'pt': dict(
        label=f'Os pedidos mensais totais da Horta com três anotações. Uma linha de referência '
              f'tracejada em 15.000 pedidos, cruzada fora de um dezembro pela primeira vez em '
              f'junho de 2025. Um ponto marcado com o valor em cada pico de dezembro, 16.663 e '
              f'20.586. Uma nota sob as quedas de janeiro dizendo que cada dezembro volta.',
        ref='15.000 por mês', first=f'primeiro mês comum acima: {MONTH_SHORT["pt"][first % 12]} de 2025',
        dec='picos de dezembro', back='e a volta em cada janeiro',
        y='pedidos por mês',
        title='Os pedidos quase dobraram em dois anos, com um pico em todo dezembro',
        cap='As anotações põem a leitura no gráfico: uma linha de referência para medir, rótulos nos '
            'pontos que importam, uma nota curta onde o leitor ficaria em dúvida.')}[lang]
    f = Fig('l15-annotated', 640, 300, w['label'])
    f.text(20, 18, w['title'], size=11.5, anchor='start', weight='600')
    p = Plot(f, 70, 60, 600, 250, 0, 23, 8000, 22000)
    p.yaxis(range(8000, 22001, 4000), fmt=lambda v: num(lang, v), label=w['y'], size=9)
    ticks, names = month_ticks(lang)
    p.xaxis(ticks, fmt=lambda t: names[t], size=9)
    f.line(p.x0, p.sy(15000), p.x1, p.sy(15000), stroke='--paper-dim', width=1.2, dash='5 4')
    f.text(p.x0 + 6, p.sy(15000) - 9, w['ref'], size=9.5, anchor='start', fill='--paper-dim')
    p.series(range(24), tot, width=2.2)
    f.circle(p.sx(first), p.sy(tot[first]), 4, fill='--phosphor')
    f.line(p.sx(first), p.sy(tot[first]) + 6, p.sx(first), p.sy(12300), stroke='--phosphor', width=1)
    f.text(p.sx(first), p.sy(11900), w['first'], size=9.5)
    for i in (11, 23):
        f.circle(p.sx(i), p.sy(tot[i]), 4, fill='--amber')
        f.text(p.sx(i) - 8, p.sy(tot[i]) - 2, num(lang, tot[i]), size=9.5, anchor='end',
               fill='--amber', mono=True)
    f.text(p.sx(14), p.sy(19500), w['dec'], size=10, fill='--amber', weight='600')
    f.text(p.sx(14), p.sy(18500), w['back'], size=9.5, fill='--paper-dim')
    return f, w['cap']


@image('l15-parts.svg', 15)
def l15_parts_image():
    m = monthly_by_region()
    tot = [sum(m[r][i] for r in H.REGIONS) for i in range(24)]
    f = Fig('l15-parts-image', 600, 340,
            'A line chart with no words, where every piece of text is a grey stroke: a thick dark '
            'stroke at the top left, a thinner pale one beneath it, a rising line with a dashed '
            'horizontal line across it, a stroke at the right-hand end of the line, an arrow '
            'pointing at a peak with a stroke beside it, and a small stroke at the bottom left.')
    f.rect(20, 18, 320, 14, stroke='--paper', fill='--paper', rx=3, width=1)
    f.rect(20, 42, 220, 8, stroke='--wire', fill='--wire', rx=2, width=1)
    p = Plot(f, 40, 80, 470, 280, 0, 23, 8000, 22000)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.5)
    f.line(p.x0, p.sy(15000), p.x1, p.sy(15000), stroke='--paper-dim', width=1.4, dash='6 4')
    p.series(range(24), tot, width=2.6)
    f.rect(p.x1 + 10, p.sy(tot[-1]) - 6, 70, 12, stroke='--phosphor', fill='--phosphor', rx=2,
           width=1)
    f.line(p.sx(8), p.sy(18500), p.sx(10.6), p.sy(16900), stroke='--amber', width=1.6, arrow=True)
    f.rect(p.sx(2), p.sy(18500) - 6, 90, 12, stroke='--amber', fill='--amber', rx=2, width=1)
    f.rect(20, 314, 150, 8, stroke='--wire', fill='--wire', rx=2, width=1)
    return f
