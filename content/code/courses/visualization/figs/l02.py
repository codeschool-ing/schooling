# Lesson 2 — the hierarchy of accuracy.


def cat_sorted():
    return sorted(H.CATEGORIES.items(), key=lambda kv: kv[1], reverse=True)


@figure('l02-ranking', 2)
def l02_ranking(lang):
    rows = {'en': ['position on a common scale', 'position on separate scales',
                   'length, direction, angle', 'area', 'volume, curvature',
                   'shading, colour saturation'],
            'pt': ['posição numa escala comum', 'posição em escalas separadas',
                   'comprimento, direção, ângulo', 'área', 'volume, curvatura',
                   'sombreamento, saturação da cor']}[lang]
    w = {'en': dict(
        label='Six rungs of a ladder, from most accurate at the top to least accurate at the '
              'bottom, with a small example beside each: position on a common scale, position '
              'on separate scales, then length, direction and angle together, then area, then '
              'volume and curvature, then shading and colour saturation.',
        top='read most accurately', bot='read least accurately',
        cap='Cleveland and McGill\'s ranking of how accurately people judge a quantity from each '
            'channel. Design by going down the ladder only as far as you have to.'),
        'pt': dict(
        label='Seis degraus de uma escada, do mais preciso no alto ao menos preciso embaixo, com '
              'um pequeno exemplo ao lado de cada um: posição numa escala comum, posição em '
              'escalas separadas, depois comprimento, direção e ângulo juntos, depois área, '
              'depois volume e curvatura, depois sombreamento e saturação da cor.',
        top='lido com mais precisão', bot='lido com menos precisão',
        cap='O ranking de Cleveland e McGill de quão bem as pessoas julgam uma quantidade em cada '
            'canal. Projete descendo a escada só até onde for preciso.')}[lang]
    f = Fig('l02-ranking', 600, 330, w['label'])
    f.line(40, 40, 40, 300, stroke='--paper-dim', width=1.5, arrow=True)
    f.text(52, 24, w['top'], size=10, anchor='start', fill='--paper-dim')
    f.text(52, 316, w['bot'], size=10, anchor='start', fill='--paper-dim')
    for i, r in enumerate(rows):
        y = 52 + i * 44
        f.rect(70, y - 16, 520, 34, stroke='--wire', fill='--panel', rx=4)
        f.text(84, y + 1, f'{i + 1}', size=11, anchor='start', weight='600', fill='--amber')
        f.text(106, y + 1, r, size=10.5, anchor='start')
        x0 = 420
        if i == 0:
            f.line(x0, y + 10, x0 + 150, y + 10, stroke='--paper-dim', width=1)
            for v in (20, 60, 115):
                f.circle(x0 + v, y + 10, 4, fill='--phosphor')
        elif i == 1:
            for k, v in enumerate((30, 70)):
                bx = x0 + k * 80
                f.line(bx, y + 10, bx + 60, y + 10, stroke='--paper-dim', width=1)
                f.circle(bx + v * 0.6, y + 10, 4, fill='--phosphor')
        elif i == 2:
            f.bar(x0, y - 8, 60, 7, stroke='--phosphor', fill='--phosphor-dim', rx=1)
            f.bar(x0, y + 4, 38, 7, stroke='--phosphor', fill='--phosphor-dim', rx=1)
            f.wedge(x0 + 110, y + 1, 13, 0, 70, fill='--phosphor-dim', stroke='--phosphor', width=1)
        elif i == 3:
            f.circle(x0 + 15, y + 1, 12, fill='--phosphor-dim', stroke='--phosphor')
            f.circle(x0 + 50, y + 1, 7, fill='--phosphor-dim', stroke='--phosphor')
        elif i == 4:
            f.path(f'M{x0} {y + 10} L{x0} {y - 6} L{x0 + 16} {y - 6} L{x0 + 16} {y + 10} Z '
                   f'M{x0} {y - 6} L{x0 + 8} {y - 12} L{x0 + 24} {y - 12} L{x0 + 16} {y - 6} '
                   f'M{x0 + 16} {y + 10} L{x0 + 24} {y + 4} L{x0 + 24} {y - 12}',
                   stroke='--phosphor', fill='--phosphor-dim', width=1)
        else:
            for k, o in enumerate((0.2, 0.5, 0.9)):
                f.rect(x0 + k * 26, y - 8, 20, 18, stroke='--wire', fill='--phosphor', rx=2,
                       opacity=o)
    return f, w['cap']


@figure('l02-pie-vs-bar', 2)
def l02_pie_vs_bar(lang):
    cats = cat_sorted()
    total = sum(v for _, v in cats)
    w = {'en': dict(
        label='Horta\'s 2025 revenue by category drawn twice. On the left, a pie with six '
              'slices, which look nearly equal. On the right, the same six numbers as sorted '
              'bars, where the order and the gaps are plain: Vegetables 412, Fruit 386, Dairy '
              '351, Bakery 298, Drinks 274 and Pantry 239 thousand reais.',
        x='revenue in 2025 (R$ thousands)',
        cap='The same six numbers. In the pie, Vegetables and Fruit are hard to tell apart; '
            'in the bars, anybody can see that Vegetables is larger, and by about how much.'),
        'pt': dict(
        label='A receita de 2025 da Horta por categoria desenhada duas vezes. À esquerda, uma '
              'pizza com seis fatias, que parecem quase iguais. À direita, os mesmos seis números '
              'como barras ordenadas, em que a ordem e as diferenças ficam claras: Verduras 412, '
              'Frutas 386, Laticínios 351, Padaria 298, Bebidas 274 e Mercearia 239 mil reais.',
        x='receita em 2025 (R$ mil)',
        cap='Os mesmos seis números. Na pizza, Verduras e Frutas são difíceis de separar; nas '
            'barras, qualquer pessoa vê que Verduras é maior, e mais ou menos por quanto.')}[lang]
    f = Fig('l02-pie-vs-bar', 660, 280, w['label'])
    cx, cy, r = 165, 135, 88
    a = 0
    for name, v in cats:
        d = 360 * v / total
        f.wedge(cx, cy, r, a, a + d, fill='--phosphor-dim', stroke='--panel', width=2)
        mid = math.radians(a + d / 2 - 90)
        f.text(cx + (r + 18) * math.cos(mid), cy + (r + 18) * math.sin(mid),
               CATEGORY[lang][name], size=9.5, anchor='start' if math.cos(mid) > 0.2 else
               'end' if math.cos(mid) < -0.2 else 'middle')
        a += d
    p = Plot(f, 400, 30, 640, 220, 0, 450, 0, 6)
    for i, (name, v) in enumerate(cats):
        y = 34 + i * 31
        f.bar(p.sx(0), y, p.sx(v) - p.sx(0), 20, stroke='--phosphor', fill='--phosphor-dim', rx=1)
        f.text(p.x0 - 8, y + 10, CATEGORY[lang][name], size=10, anchor='end')
        f.text(p.sx(v) + 5, y + 10, str(v), size=9.5, anchor='start', mono=True,
               fill='--paper-dim')
    f.line(p.x0, 28, p.x0, p.y1, stroke='--paper-dim', width=1.2)
    p.xaxis(range(0, 451, 150), label=w['x'])
    return f, w['cap']


@figure('l02-one-slice', 2)
def l02_one_slice(lang):
    cats = cat_sorted()
    total = sum(v for _, v in cats)
    veg = H.CATEGORIES['Vegetables']
    share = 100 * veg / total
    w = {'en': dict(
        label=f'A pie with two slices: Vegetables, {share:.0f}% of 2025 revenue, highlighted, and '
              f'everything else, {100 - share:.0f}%, in grey. A reader sees at once that it is about a '
              f'fifth.',
        a=f'Vegetables, {share:.0f}%', b='everything else',
        cap='A pie can do one thing well: show one part against the whole. With two slices, and '
            'one of them near a fifth, a quarter or a half, the eye reads the angle easily.'),
        'pt': dict(
        label=f'Uma pizza com duas fatias: Verduras, {share:.0f}% da receita de 2025, destacada, e '
              f'todo o resto, {100 - share:.0f}%, em cinza. O leitor vê na hora que é cerca de um '
              f'quinto.',
        a=f'Verduras, {share:.0f}%', b='todo o resto',
        cap='Uma pizza faz uma coisa bem: mostrar uma parte contra o todo. Com duas fatias, e uma '
            'delas perto de um quinto, um quarto ou metade, o olho lê o ângulo com facilidade.')}[lang]
    f = Fig('l02-one-slice', 520, 230, w['label'])
    cx, cy, r = 160, 115, 90
    d = 360 * veg / total
    f.wedge(cx, cy, r, d, 360, fill='--scan', stroke='--paper-dim', width=1)
    f.wedge(cx, cy, r, 0, d, fill='--amber', stroke='--panel', width=2)
    f.text(280, 60, w['a'], size=11, anchor='start', weight='600', fill='--amber')
    f.line(276, 60, cx + 50, cy - 62, stroke='--amber', width=1.2)
    f.text(280, 175, w['b'], size=11, anchor='start', fill='--paper-dim')
    return f, w['cap']


@figure('l02-stevens', 2)
def l02_stevens(lang):
    w = {'en': dict(
        label='Two curves of perceived size against real size, both starting at 1. Length rises '
              'in a straight line, so ten times the length looks ten times as long. Area bends '
              'below it: with an exponent of 0.7, ten times the area looks only about five times '
              'as large, and 6.5 times looks like 3.7.',
        x='real ratio', y='ratio the eye reports', len='length (exponent 1.0)',
        area='area (exponent 0.7)',
        cap='Stevens\'s power law: perceived size grows as the real size raised to an exponent. '
            'For length the exponent is close to 1; for area it is lower, so big areas are '
            'read as smaller than they are.'),
        'pt': dict(
        label='Duas curvas do tamanho percebido contra o tamanho real, as duas começando em 1. O '
              'comprimento sobe em linha reta, então dez vezes o comprimento parece dez vezes '
              'mais longo. A área se curva abaixo dela: com expoente 0,7, dez vezes a área parece '
              'só umas cinco vezes maior, e 6,5 vezes parece 3,7.',
        x='razão real', y='razão que o olho relata', len='comprimento (expoente 1,0)',
        area='área (expoente 0,7)',
        cap='A lei de potência de Stevens: o tamanho percebido cresce como o tamanho real elevado '
            'a um expoente. Para comprimento o expoente é perto de 1; para área é menor, então '
            'áreas grandes são lidas como menores do que são.')}[lang]
    f = Fig('l02-stevens', 560, 300, w['label'])
    p = Plot(f, 70, 40, 520, 240, 1, 10, 0, 10)
    p.yaxis(range(0, 11, 2), label=w['y'])
    p.xaxis(range(1, 11), label=w['x'])
    xs = [1 + 9 * i / 80 for i in range(81)]
    p.series(xs, xs, stroke='--phosphor', width=2.2)
    p.series(xs, [x ** 0.7 for x in xs], stroke='--amber', width=2.2, dash='6 4')
    f.text(p.sx(7.4), p.sy(8.6), w['len'], size=10, anchor='end', fill='--phosphor')
    f.text(p.sx(9.9), p.sy(3.9), w['area'], size=10, anchor='end', fill='--amber')
    x, y = p.sx(6.5), p.sy(6.5 ** 0.7)
    f.circle(x, y, 4, fill='--amber')
    f.line(x, y, x, p.y1, stroke='--paper-dim', width=1, dash='3 3')
    f.line(p.x0, y, x, y, stroke='--paper-dim', width=1, dash='3 3')
    f.text(x - 8, y - 12, num(lang, 6.5, 1) + ' → ' + num(lang, 6.5 ** 0.7, 1), size=9.5,
           anchor='end', mono=True)
    return f, w['cap']
