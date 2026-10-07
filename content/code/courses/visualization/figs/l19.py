# Lesson 19 — the dashboard on a phone.


def phone(f, x, y, w=150, h=290):
    f.rect(x, y, w, h, stroke='--paper-dim', fill='--panel', rx=16, width=2)
    f.rect(x + w / 2 - 18, y + 8, 36, 5, stroke='--wire', fill='--wire', rx=2, width=1)


def totals():
    m = monthly_by_region()
    return [sum(m[r][i] for r in H.REGIONS) for i in range(24)]


def spark(f, x, y, w, h, vals, stroke='--phosphor', width=1.6):
    lo, hi = min(vals), max(vals)
    f.poly([(x + w * i / (len(vals) - 1), y + h - h * (v - lo) / (hi - lo))
            for i, v in enumerate(vals)], stroke=stroke, width=width)


@figure('l19-shrunk', 19)
def l19_shrunk(lang):
    tot = totals()
    w = {'en': dict(
        label='Two phones, each 360 pixels wide. In the first, the desktop dashboard, designed 960 '
              'pixels wide, is shrunk to fit: everything is scaled to 0.375 of its size, so text '
              'drawn at 10 pixels becomes 3.75 and cannot be read. In the second, the same content is '
              'reflowed into one column: the two numbers stacked at the top, then the trend at full '
              'width, then growth by region, all at readable sizes.',
        a='shrunk to fit', b='reflowed', note='10 px text → 3.75 px',
        k=('orders in 2025', 'orders in December'), t='Orders per month', g='Growth by region',
        cap='Shrinking keeps the layout and loses the reader: at 360 pixels, a 960-pixel design is '
            'drawn at three-eighths of its size. Reflowing keeps the sizes and changes the layout.'),
        'pt': dict(
        label='Dois celulares, cada um com 360 pixels de largura. No primeiro, o painel de '
              'computador, desenhado com 960 pixels de largura, é encolhido para caber: tudo fica com '
              '0,375 do tamanho, então um texto desenhado com 10 pixels vira 3,75 e não se lê. No '
              'segundo, o mesmo conteúdo é refluído numa coluna: os dois números empilhados no topo, '
              'depois a tendência na largura toda, depois o crescimento por região, tudo em tamanhos '
              'legíveis.',
        a='encolhido para caber', b='refluído', note='texto de 10 px → 3,75 px',
        k=('pedidos em 2025', 'pedidos em dezembro'), t='Pedidos por mês', g='Alta por região',
        cap='Encolher mantém o layout e perde o leitor: em 360 pixels, um desenho de 960 fica com '
            'três oitavos do tamanho. Refluir mantém os tamanhos e muda o layout.')}[lang]
    f = Fig('l19-shrunk', 560, 340, w['label'])
    f.text(60, 18, w['a'], size=10.5, weight='600', anchor='start')
    phone(f, 50, 32)
    s = 0.375 * 0.36
    x0, y0 = 58, 130
    for i in range(3):
        f.bar(x0 + i * 46, y0, 43, 24, stroke='--wire', fill='--scan', width=0.6)
        f.text(x0 + i * 46 + 4, y0 + 6, w['k'][0] if i == 0 else '', size=3, anchor='start')
        f.text(x0 + i * 46 + 4, y0 + 15, '180,682' if lang == 'en' else '180.682', size=5,
               anchor='start', weight='600')
    f.bar(x0, y0 + 28, 89, 56, stroke='--wire', fill='--scan', width=0.6)
    spark(f, x0 + 4, y0 + 36, 80, 40, tot, width=0.8)
    f.bar(x0 + 92, y0 + 28, 43, 56, stroke='--wire', fill='--scan', width=0.6)
    f.text(125, 236, w['note'], size=9.5, fill='--amber', weight='600')
    X = 330
    f.text(X + 10, 18, w['b'], size=10.5, weight='600', anchor='start')
    phone(f, X, 32)
    for i, (lab, v) in enumerate(zip(w['k'], (('180,682', '20,586') if lang == 'en' else
                                              ('180.682', '20.586')))):
        y = 52 + i * 52
        f.bar(X + 10, y, 130, 46, stroke='--wire', fill='--scan', width=1)
        f.text(X + 18, y + 12, lab, size=8.5, anchor='start', fill='--paper-dim')
        f.text(X + 18, y + 31, v, size=15, anchor='start', weight='600')
    f.bar(X + 10, 160, 130, 80, stroke='--wire', fill='--scan', width=1)
    f.text(X + 18, 172, w['t'], size=8.5, anchor='start', fill='--paper-dim')
    spark(f, X + 18, 182, 114, 50, tot)
    f.bar(X + 10, 246, 130, 66, stroke='--wire', fill='--scan', width=1)
    f.text(X + 18, 258, w['g'], size=8.5, anchor='start', fill='--paper-dim')
    for i, v in enumerate((60.5, 44.8, 30.0, 23.5)):
        f.bar(X + 18, 266 + i * 10, 110 * v / 62, 7, stroke='--paper-dim', fill='--paper-dim')
    return f, w['cap']


@figure('l19-order', 19)
def l19_order(lang):
    w = {'en': dict(
        label='A desktop layout of four numbered blocks, two cards across the top, a wide trend '
              'below them and a breakdown beside it, and a phone layout where the same four blocks '
              'are stacked in one column in the same order: 1, 2, 3, 4.',
        names=('main number', 'second number', 'trend', 'breakdown'), a='desktop', b='phone',
        cap='The stacking order is the importance order. Writing the layout in that order in the '
            'first place means the phone version is what the page does when nothing tells it '
            'otherwise.'),
        'pt': dict(
        label='Um layout de computador com quatro blocos numerados, dois cartões no topo, uma '
              'tendência larga embaixo e um detalhamento ao lado, e um layout de celular em que os '
              'mesmos quatro blocos ficam empilhados numa coluna na mesma ordem: 1, 2, 3, 4.',
        names=('número principal', 'segundo número', 'tendência', 'detalhamento'),
        a='computador', b='celular',
        cap='A ordem de empilhar é a ordem de importância. Escrever o layout nessa ordem desde o '
            'começo faz da versão de celular o que a página faz quando nada manda outra coisa.')}[lang]
    f = Fig('l19-order', 560, 290, w['label'])
    f.text(20, 18, w['a'], size=10.5, weight='600', anchor='start')
    boxes = [(20, 34, 150, 50), (176, 34, 150, 50), (20, 90, 226, 170), (252, 90, 74, 170)]
    for k, (x, y, bw, bh) in enumerate(boxes):
        f.rect(x, y, bw, bh, stroke='--wire', fill='--scan', rx=4, width=1)
        f.circle(x + 16, y + 16, 10, fill='--phosphor')
        f.text(x + 16, y + 16, str(k + 1), size=10, weight='600', fill='#ffffff')
        if k < 3:
            f.text(x + 32, y + 16, w['names'][k], size=9, anchor='start')
    f.text(289, 190, w['names'][3], size=9, rotate=90)
    X = 390
    f.text(X, 18, w['b'], size=10.5, weight='600', anchor='start')
    phone(f, X, 30, 150, 254)
    for k, h in enumerate((36, 36, 70, 56)):
        y = 48 + sum((36, 36, 70, 56)[:k]) + k * 6
        f.rect(X + 10, y, 130, h, stroke='--wire', fill='--scan', rx=4, width=1)
        f.circle(X + 26, y + 14, 10, fill='--phosphor')
        f.text(X + 26, y + 14, str(k + 1), size=10, weight='600', fill='#ffffff')
        f.text(X + 42, y + 14, w['names'][k], size=9, anchor='start')
    return f, w['cap']


@figure('l19-bars', 19)
def l19_bars(lang):
    w = {'en': dict(
        label='Growth by region drawn twice inside a phone-width frame. On the left as columns: the '
              'five region names do not fit beneath them and are turned sideways. On the right as '
              'horizontal bars: each name sits on its own line, level, with its value at the end '
              'of the bar.',
        a='columns', b='bars',
        cap='On a narrow screen, width is the scarce dimension and height is free, because the page '
            'scrolls. Horizontal bars spend the free one on the labels.'),
        'pt': dict(
        label='O crescimento por região desenhado duas vezes dentro de um quadro da largura de um '
              'celular. À esquerda como colunas: os cinco nomes de região não cabem embaixo delas e '
              'ficam de lado. À direita como barras horizontais: cada nome fica na própria linha, '
              'na horizontal, com o valor na ponta da barra.',
        a='colunas', b='barras',
        cap='Numa tela estreita, a largura é a dimensão escassa e a altura é livre, porque a página '
            'rola. Barras horizontais gastam a livre com os rótulos.')}[lang]
    vals = [('North', 60.5), ('Northeast', 44.8), ('Centre-West', 30.0), ('South', 23.5),
            ('Southeast', 14.6)]
    f = Fig('l19-bars', 520, 260, w['label'])
    f.text(20, 18, w['a'], size=10.5, weight='600', anchor='start')
    f.rect(20, 30, 200, 220, stroke='--wire', fill='--panel', rx=6, width=1)
    for i, (r, v) in enumerate(vals):
        x = 40 + i * 36
        f.bar(x, 160 - 1.9 * v, 26, 1.9 * v)
        f.text(x + 13, 168, REGION[lang][r], size=9, anchor='end', rotate=-60)
    f.text(280, 18, w['b'], size=10.5, weight='600', anchor='start')
    f.rect(280, 30, 200, 220, stroke='--wire', fill='--panel', rx=6, width=1)
    for i, (r, v) in enumerate(vals):
        y = 44 + i * 40
        f.text(292, y + 6, REGION[lang][r], size=9.5, anchor='start')
        f.bar(292, y + 14, 2.4 * v, 14)
        f.text(298 + 2.4 * v, y + 21, num(lang, v, 1) + '%', size=9, anchor='start', mono=True)
    return f, w['cap']


@figure('l19-ticks', 19)
def l19_ticks(lang):
    tot = totals()
    ticks, names = month_ticks(lang)
    w = {'en': dict(
        label='Orders per month drawn twice at phone width. On the left with the desktop\'s five '
              'date labels, which run into each other. On the right with only the first and last '
              'months labelled and the last value written at the end of the line.',
        a='desktop ticks', b='first, last, and the value',
        cap='A narrow chart has room for two or three labels on an axis. Keep the ones that '
            'frame the period, and write the number the reader came for on the line itself.'),
        'pt': dict(
        label='Os pedidos por mês desenhados duas vezes na largura de um celular. À esquerda com os '
              'cinco rótulos de data do computador, que se atropelam. À direita só com o primeiro e '
              'o último mês rotulados e o último valor escrito na ponta da linha.',
        a='marcas do computador', b='primeiro, último e o valor',
        cap='Um gráfico estreito tem lugar para dois ou três rótulos num eixo. Mantenha os que '
            'enquadram o período, e escreva na própria linha o número que o leitor veio buscar.')}[lang]
    long = {'en': ['Jan 2024', 'Jul 2024', 'Jan 2025', 'Jul 2025', 'Dec 2025'],
            'pt': ['jan 2024', 'jul 2024', 'jan 2025', 'jul 2025', 'dez 2025']}[lang]
    f = Fig('l19-ticks', 520, 230, w['label'])
    for k, title in enumerate((w['a'], w['b'])):
        x0 = 30 + k * 260
        f.text(x0, 18, title, size=10.5, weight='600', anchor='start')
        p = Plot(f, x0, 40, x0 + 150, 180, 0, 23, 9000, 22000)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1)
        p.series(range(24), tot, width=2)
        if k == 0:
            for t, s in zip((0, 6, 12, 18, 23), long):
                f.text(p.sx(t), p.y1 + 14, s, size=9, fill='--paper-dim')
        else:
            f.text(p.sx(0), p.y1 + 14, long[0], size=9, fill='--paper-dim', anchor='start')
            f.text(p.sx(23), p.y1 + 14, long[4], size=9, fill='--paper-dim', anchor='end')
            f.circle(p.sx(23), p.sy(tot[23]), 3.5, fill='--phosphor')
            f.text(p.sx(23) - 6, p.sy(tot[23]), num(lang, tot[23]), size=9.5, anchor='end',
                   mono=True, weight='600')
    return f, w['cap']


@figure('l19-targets', 19)
def l19_targets(lang):
    w = {'en': dict(
        label='Four squares compared at the same scale: 16 CSS pixels, the size of a small filter '
              'arrow; 24, the minimum WCAG 2.2 asks for at level AA; 44 points, Apple\'s '
              'recommendation; and 48 density-independent pixels, Google\'s Material '
              'recommendation.',
        labs=('16 px: a small arrow', '24 px: WCAG 2.2 minimum', '44 pt: Apple', '48 dp: Material'),
        cap='A finger is not a mouse pointer. The WCAG floor is 24 by 24 CSS pixels; the platform '
            'guidelines ask for nearly twice that, and a dashboard\'s filters should follow them.'),
        'pt': dict(
        label='Quatro quadrados comparados na mesma escala: 16 pixels CSS, o tamanho de uma setinha '
              'de filtro; 24, o mínimo que a WCAG 2.2 pede no nível AA; 44 pontos, a recomendação da '
              'Apple; e 48 pixels independentes de densidade, a recomendação do Material, do '
              'Google.',
        labs=('16 px: uma setinha', '24 px: mínimo da WCAG 2.2', '44 pt: Apple',
              '48 dp: Material'),
        cap='Um dedo não é um ponteiro de mouse. O piso da WCAG é 24 por 24 pixels CSS; os guias das '
            'plataformas pedem quase o dobro, e os filtros de um painel devem segui-los.')}[lang]
    f = Fig('l19-targets', 560, 170, w['label'])
    x = 30
    for k, (sz, lab) in enumerate(zip((16, 24, 44, 48), w['labs'])):
        s = sz * 2
        f.rect(x, 120 - s, s, s, stroke='--amber' if k == 0 else '--phosphor',
               fill='--scan', rx=3, width=1.5)
        f.text(x, 140, lab, size=9.5, anchor='start')
        x += max(s, 120) + 16
    return f, w['cap']


@image('l19-phone.svg', 19)
def l19_phone_image():
    tot = totals()
    f = Fig('l19-phone-image', 600, 360,
            'A phone with no words on its screen: a tiny downward triangle at the top right, a row of '
            'columns whose labels are short strokes turned sideways, a line chart whose five axis '
            'labels overlap, and a wide grey table that runs past the right edge of the screen.')
    # The phone is drawn as a mark, not a box: the table is meant to run out of it.
    f.path('M210 10 H390 A20 20 0 0 1 410 30 V330 A20 20 0 0 1 390 350 H210 A20 20 0 0 1 190 330 '
           'V30 A20 20 0 0 1 210 10 Z', stroke='--paper-dim', fill='--panel', width=2.5)
    f.path('M384 30 L392 30 L388 35 Z', stroke='--paper-dim', fill='--paper-dim', width=1)
    for i, v in enumerate((60.5, 44.8, 30.0, 23.5, 14.6)):
        x = 214 + i * 34
        f.bar(x, 120 - 1.1 * v, 22, 1.1 * v)
        f.path(f'M{x + 6:.1f} {150:.1f} L{x + 20:.1f} {126:.1f}', stroke='--wire', width=6, cap='round')
    spark(f, 210, 170, 180, 70, tot)
    f.line(210, 246, 390, 246, stroke='--paper-dim', width=1)
    for i in range(5):
        f.rect(204 + i * 38, 252, 46, 8, stroke='--paper-dim', fill='--paper-dim', rx=2, width=1)
    for r in range(3):
        f.bar(204, 280 + r * 18, 300, 14, stroke='--wire', fill='--scan', width=1)
    return f
