# Lesson 5 — histograms and the bin.


def minutes():
    return [r['minutes'] for r in H.deliveries()]


def counts_for(xs, edges):
    out = [0] * (len(edges) - 1)
    for x in xs:
        for i in range(len(edges) - 1):
            if edges[i] <= x < edges[i + 1]:
                out[i] += 1
                break
    return out


def draw_hist(f, p, edges, counts, fill='--phosphor-dim', stroke='--phosphor', density=False):
    for i, c in enumerate(counts):
        if c <= 0:
            continue
        h = c / (edges[i + 1] - edges[i]) if density else c
        x0, x1 = p.sx(edges[i]), p.sx(edges[i + 1])
        f.bar(x0, p.sy(h), x1 - x0, p.y1 - p.sy(h), stroke=stroke, fill=fill, width=1)


@figure('l05-anatomy', 5)
def l05_anatomy(lang):
    xs = minutes()
    edges = list(range(0, 106, 5))
    c = counts_for(xs, edges)
    w = {'en': dict(
        label='A histogram of 400 delivery times in bins of 5 minutes, from 0 to 105. The bars '
              'touch. Most deliveries take between 25 and 40 minutes, the tallest bar is 30 to 35 '
              f'minutes with {max(c)} deliveries, and a long thin tail runs to the right as far as '
              '101 minutes.',
        x='delivery time (minutes)', y='deliveries', peak='the bulk: 25 to 40 minutes',
        tail='a long tail to the right',
        cap='Each bar counts the deliveries whose time fell in its interval. The bars touch '
            'because the intervals do: one ends where the next begins.'),
        'pt': dict(
        label='Um histograma de 400 tempos de entrega em intervalos de 5 minutos, de 0 a 105. As '
              'barras se tocam. A maioria das entregas leva entre 25 e 40 minutos, a barra mais '
              f'alta é a de 30 a 35 minutos com {max(c)} entregas, e uma cauda longa e fina corre '
              'para a direita até 101 minutos.',
        x='tempo de entrega (minutos)', y='entregas', peak='o grosso: 25 a 40 minutos',
        tail='uma cauda longa à direita',
        cap='Cada barra conta as entregas cujo tempo caiu no seu intervalo. As barras se tocam '
            'porque os intervalos se tocam: um termina onde o próximo começa.')}[lang]
    f = Fig('l05-anatomy', 620, 290, w['label'])
    p = Plot(f, 60, 40, 600, 230, 0, 105, 0, 100)
    p.yaxis(range(0, 101, 25), label=w['y'])
    p.xaxis(range(0, 106, 15), label=w['x'])
    draw_hist(f, p, edges, c)
    f.text(p.sx(32), p.sy(max(c)) - 14, w['peak'], size=10, fill='--amber', weight='600')
    f.text(p.sx(78), p.sy(20), w['tail'], size=10, fill='--amber', weight='600')
    f.line(p.sx(70), p.sy(16), p.sx(62), p.sy(5), stroke='--amber', width=1.2, arrow=True)
    return f, w['cap']


@figure('l05-three-widths', 5)
def l05_three_widths(lang):
    xs = minutes()
    w = {'en': dict(
        label='The same 400 delivery times as three histograms. With bins of 2 minutes the shape '
              'is ragged, with many small spikes and gaps that are noise. With bins of 5 minutes '
              'one peak and a long right tail are clear. With bins of 15 minutes there are seven '
              'blocks and the tail has almost disappeared into them.',
        t='bins of {} minutes',
        cap='Too narrow, and the noise of 400 deliveries looks like structure. Too wide, and the '
            'structure disappears into a few blocks. The middle one is the only one that shows '
            'the shape.'),
        'pt': dict(
        label='Os mesmos 400 tempos de entrega em três histogramas. Com intervalos de 2 minutos a '
              'forma fica irregular, com muitos picos e buracos pequenos que são ruído. Com '
              'intervalos de 5 minutos um pico e uma cauda longa à direita ficam claros. Com '
              'intervalos de 15 minutos sobram sete blocos e a cauda quase some dentro deles.',
        t='intervalos de {} minutos',
        cap='Estreito demais, e o ruído de 400 entregas parece estrutura. Largo demais, e a '
            'estrutura some em poucos blocos. O do meio é o único que mostra a forma.')}[lang]
    f = Fig('l05-three-widths', 660, 210, w['label'])
    for k, width in enumerate((2, 5, 15)):
        x0 = 20 + k * 215
        edges = list(range(0, 106, width))
        c = counts_for(xs, edges)
        p = Plot(f, x0, 40, x0 + 195, 170, 0, 105, 0, max(c) * 1.05)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
        draw_hist(f, p, edges, c)
        f.text(x0 + 97, 22, w['t'].format(width), size=10.5, weight='600')
        for t in (0, 30, 60, 90):
            f.text(p.sx(t), p.y1 + 12, str(t), size=9, fill='--paper-dim')
    return f, w['cap']


@figure('l05-offset', 5)
def l05_offset(lang):
    xs = minutes()
    w = {'en': dict(
        label='Two histograms of the same delivery times with the same bin width, 10 minutes. On '
              'the left the bins start at 0, so they run 30 to 40, 40 to 50; on the right they '
              'start at 5, so they run 25 to 35, 35 to 45. The peak moves and the heights of the '
              'bars change, though nothing in the data did.',
        a='bins start at 0', b='bins start at 5',
        cap='The width is one choice; where the bins start is another. Moving the edges by half a '
            'bin reshapes the picture, which is a reason to try a few before believing one.'),
        'pt': dict(
        label='Dois histogramas dos mesmos tempos de entrega com a mesma largura de intervalo, 10 '
              'minutos. À esquerda os intervalos começam no 0, então vão de 30 a 40, de 40 a 50; à '
              'direita começam no 5, então vão de 25 a 35, de 35 a 45. O pico se move e as alturas '
              'das barras mudam, embora nada no dado tenha mudado.',
        a='intervalos a partir do 0', b='intervalos a partir do 5',
        cap='A largura é uma escolha; onde os intervalos começam é outra. Mover as bordas em meio '
            'intervalo muda a figura, o que é motivo para testar algumas antes de acreditar numa.')}[lang]
    f = Fig('l05-offset', 640, 230, w['label'])
    for k, start in enumerate((0, 5)):
        x0 = 50 + k * 310
        edges = list(range(start, 111, 10))
        c = counts_for(xs, edges)
        p = Plot(f, x0, 40, x0 + 250, 190, 0, 110, 0, 180)
        p.yaxis(range(0, 181, 60), size=9)
        draw_hist(f, p, edges, c)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
        for t in range(start, 111, 20):
            f.text(p.sx(t), p.y1 + 12, str(t), size=9, fill='--paper-dim')
        f.text(x0 + 125, 20, w['a'] if start == 0 else w['b'], size=10.5, weight='600')
    return f, w['cap']


@figure('l05-density', 5)
def l05_density(lang):
    xs = minutes()
    edges = [10, 20, 25, 30, 35, 40, 50, 105]
    c = counts_for(xs, edges)
    w = {'en': dict(
        label='Two histograms of the same delivery times with unequal bins: 10 to 20, then four '
              'bins of 5 minutes, then 40 to 50 and finally 50 to 105. On the left the height is '
              'the count, and the last wide bin, 50 to 105, becomes a block covering more of the '
              'picture than any other bar. On the right the height is deliveries per minute, so the area of each bar is '
              'its count, and the last bin becomes the low, long tail it really is.',
        a='height = count (misleading)', b='height = count per minute',
        cap='With unequal bins the eye reads area, so the height must be the count divided by '
            'the width. Drawn by count, a wide bin looks like a crowd.'),
        'pt': dict(
        label='Dois histogramas dos mesmos tempos de entrega com intervalos desiguais: de 10 a 20, '
              'depois quatro intervalos de 5 minutos, depois de 40 a 50 e por fim de 50 a 105. À '
              'esquerda a altura é a contagem, e o último intervalo largo, de 50 a 105, vira um '
              'bloco que cobre mais da figura que qualquer outra barra. À direita a altura é entregas por minuto, '
              'então a área de cada barra é a sua contagem, e o último intervalo vira a cauda '
              'baixa e longa que ele é de fato.',
        a='altura = contagem (engana)', b='altura = contagem por minuto',
        cap='Com intervalos desiguais o olho lê a área, então a altura tem de ser a contagem '
            'dividida pela largura. Desenhado pela contagem, um intervalo largo parece uma '
            'multidão.')}[lang]
    f = Fig('l05-density', 640, 240, w['label'])
    for k in range(2):
        x0 = 50 + k * 310
        dens = k == 1
        top = max(c) * 1.1 if not dens else max(ci / (edges[i + 1] - edges[i]) for i, ci in enumerate(c)) * 1.1
        p = Plot(f, x0, 40, x0 + 250, 200, 0, 110, 0, top)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
        f.line(p.x0, p.y0, p.x0, p.y1, stroke='--paper-dim', width=1.2)
        draw_hist(f, p, edges, c, density=dens, fill='--amber' if not dens else '--phosphor-dim',
                  stroke='--amber' if not dens else '--phosphor')
        for t in (10, 30, 50, 105):
            f.text(p.sx(t), p.y1 + 12, str(t), size=9, fill='--paper-dim')
        f.text(x0 + 125, 20, w['b'] if dens else w['a'], size=10.5, weight='600')
    return f, w['cap']


@figure('l05-other-views', 5)
def l05_other_views(lang):
    xs = sorted(minutes())
    n = len(xs)
    w = {'en': dict(
        label='Two other views of the 400 delivery times. Above, a strip of 400 small dots along '
              'a line, each dot one delivery, dense between 25 and 40 minutes and thinning to the '
              'right. Below, a cumulative curve that rises from 0% to 100%: it crosses 50% at the '
              'median, 33 minutes, and 90% at about 48 minutes.',
        a='every delivery, one dot', b='share of deliveries at or under each time',
        x='delivery time (minutes)', med='half: 33 min',
        cap='A strip shows every value with no bins at all; a cumulative curve answers "what '
            'share took less than this?" by reading across. Neither has a width to choose.'),
        'pt': dict(
        label='Duas outras vistas dos 400 tempos de entrega. Em cima, uma faixa de 400 pontinhos '
              'ao longo de uma linha, cada ponto uma entrega, densa entre 25 e 40 minutos e '
              'rareando para a direita. Embaixo, uma curva acumulada que sobe de 0% a 100%: ela '
              'cruza 50% na mediana, 33 minutos, e 90% em uns 48 minutos.',
        a='cada entrega, um ponto', b='fração das entregas até cada tempo',
        x='tempo de entrega (minutos)', med='metade: 33 min',
        cap='Uma faixa mostra todo valor sem intervalo nenhum; uma curva acumulada responde "que '
            'fração levou menos que isto?" lendo na horizontal. Nenhuma das duas tem largura a '
            'escolher.')}[lang]
    f = Fig('l05-other-views', 620, 330, w['label'])
    p = Plot(f, 60, 30, 590, 80, 0, 105, 0, 1)
    f.text(60, 20, w['a'], size=10.5, anchor='start', weight='600')
    for i, x in enumerate(xs):
        jitter = ((i * 2654435761) % 4294967296) / 4294967296
        f.circle(p.sx(x), 40 + jitter * 36, 1.6, fill='--phosphor', opacity=0.6)
    q = Plot(f, 60, 130, 590, 280, 0, 105, 0, 100)
    f.text(60, 112, w['b'], size=10.5, anchor='start', weight='600')
    q.yaxis(range(0, 101, 25), fmt=lambda v: f'{v}%', size=9)
    q.xaxis(range(0, 106, 15), label=w['x'])
    pts = []
    for i, x in enumerate(xs):
        pts.append((q.sx(x), q.sy(100 * i / n)))
        pts.append((q.sx(x), q.sy(100 * (i + 1) / n)))
    f.poly(pts, stroke='--phosphor', width=1.8)
    med = (xs[n // 2 - 1] + xs[n // 2]) / 2
    f.line(q.x0, q.sy(50), q.sx(med), q.sy(50), stroke='--amber', width=1.2, dash='4 3')
    f.line(q.sx(med), q.sy(50), q.sx(med), q.y1, stroke='--amber', width=1.2, dash='4 3')
    f.text(q.sx(med) + 8, q.sy(50) + 14, w['med'], size=10, anchor='start', fill='--amber')
    return f, w['cap']


@image('l05-hist.svg', 5)
def l05_hist_image():
    xs = minutes()
    edges = list(range(0, 106, 5))
    c = counts_for(xs, edges)
    f = Fig('l05-hist', 600, 340,
            'A histogram with no words: touching bars over a horizontal axis numbered 0 to 105, '
            'rising to one tall bar a little left of the middle and thinning to a long low tail on '
            'the right, with one short bar standing alone at the far right.')
    p = Plot(f, 50, 30, 570, 290, 0, 105, 0, 95)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.5)
    for t in range(0, 106, 15):
        f.line(p.sx(t), p.y1, p.sx(t), p.y1 + 5, stroke='--paper-dim', width=1.2)
        f.text(p.sx(t), p.y1 + 17, str(t), size=11, fill='--paper-dim', mono=True)
    draw_hist(f, p, edges, c)
    return f
