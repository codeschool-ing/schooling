"""Lesson 10: front-end performance, Core Web Vitals and the lab against the field."""
from figures import Fig, T, figure


@figure('l10-vitals', 10)
def vitals():
    f = Fig('l10-vitals', 720, 300, T(
        'The three Core Web Vitals, each drawn as a scale cut into three bands. Largest Contentful '
        'Paint, which measures loading: good up to 2.5 seconds, needs improvement up to 4 seconds, '
        'poor beyond. Interaction to Next Paint, which measures responsiveness: good up to 200 '
        'milliseconds, needs improvement up to 500, poor beyond. Cumulative Layout Shift, which '
        'measures visual stability: good up to 0.1, needs improvement up to 0.25, poor beyond. A '
        'page passes when the 75th percentile of its real visits falls in the good band for all '
        'three.',
        'As três Core Web Vitals, cada uma desenhada como uma escala cortada em três faixas. '
        'Largest Contentful Paint, que mede o carregamento: bom até 2,5 segundos, precisa melhorar '
        'até 4 segundos, ruim além disso. Interaction to Next Paint, que mede a resposta: bom até '
        '200 milissegundos, precisa melhorar até 500, ruim além disso. Cumulative Layout Shift, que '
        'mede a estabilidade visual: bom até 0,1, precisa melhorar até 0,25, ruim além disso. Uma '
        'página passa quando o percentil 75 das visitas reais cai na faixa boa nas três.'))
    x0, x1 = 250, 690
    rows = [
        ('LCP', T('loading', 'carregamento'), 6.0, [(2.5, '2.5 s'), (4.0, '4.0 s')]),
        ('INP', T('responsiveness', 'resposta'), 800, [(200, '200 ms'), (500, '500 ms')]),
        ('CLS', T('visual stability', 'estabilidade visual'), 0.4, [(0.1, '0.1'), (0.25, '0.25')]),
    ]
    legend = [(T('good', 'bom'), '--phosphor', None), (T('needs improvement', 'precisa melhorar'), '--amber', None),
              (T('poor', 'ruim'), '--panel', '--wire')]
    lx = x0
    for label, fill, stroke in legend:
        f.rect(lx, 26, 14, 14, stroke=stroke, fill=fill, rx=2)
        f.text(lx + 20, 33, label, size=10.5, anchor='start', fill='--paper-dim')
        lx += 34 + len(label) * 6
    for i, (name, what, top, cuts) in enumerate(rows):
        y = 70 + i * 72
        f.text(30, y + 9, name, size=13, anchor='start', weight='600', mono=True)
        f.text(80, y + 9, what, size=10.5, anchor='start', fill='--paper-dim')
        a = x0 + (x1 - x0) * cuts[0][0] / top
        b = x0 + (x1 - x0) * cuts[1][0] / top
        f.rect(x0, y, a - x0, 18, stroke=None, fill='--phosphor', rx=2)
        f.rect(a, y, b - a, 18, stroke=None, fill='--amber', rx=0)
        f.rect(b, y, x1 - b, 18, stroke='--wire', fill='--panel', rx=2)
        for x, label in ((a, cuts[0][1]), (b, cuts[1][1])):
            f.line(x, y - 4, x, y + 24, stroke='--paper', width=1.2)
            f.text(x, y + 36, label, size=10, mono=True)
    f.text(360, 282, T('judged at the 75th percentile of real visits, phone and desktop apart',
                       'julgadas no percentil 75 das visitas reais, celular e desktop separados'),
           size=10.5, fill='--amber')
    return f, T('The three Core Web Vitals and their bands. Lighthouse cannot measure the middle '
                'one, because a lab run has nobody tapping.',
                'As três Core Web Vitals e suas faixas. O Lighthouse não consegue medir a do meio, '
                'porque numa execução de laboratório ninguém toca na tela.')


@figure('l10-field', 10)
def field():
    f = Fig("l10-field", 720, 300, T(
        'An illustration, not a measurement. Above, the field: a histogram of the Largest '
        'Contentful Paint of many real visits, most between one and three seconds, with a long '
        'tail of slow visits stretching to eight seconds. A line marks the 75th percentile at 2.3 '
        'seconds, inside the good band, which ends at 2.5. Below, the lab: one dot, one run of '
        'Lighthouse on one emulated phone and one simulated network, at 3.1 seconds. The lab '
        'number is not a point of the field distribution; it answers a different question.',
        'Uma ilustração, não uma medição. Em cima, o campo: um histograma do Largest Contentful '
        'Paint de muitas visitas reais, a maioria entre um e três segundos, com uma cauda longa '
        'de visitas lentas que chega a oito segundos. Uma linha marca o percentil 75 em 2,3 '
        'segundos, dentro da faixa boa, que termina em 2,5. Embaixo, o laboratório: um ponto, uma '
        'execução do Lighthouse num celular emulado e numa rede simulada, em 3,1 segundos. O '
        'número do laboratório não é um ponto da distribuição do campo; ele responde a outra '
        'pergunta.'))
    x0, x1, top = 110, 690, 8.0

    def X(s):
        return x0 + (x1 - x0) * s / top
    heights = [2, 9, 22, 34, 38, 33, 26, 19, 14, 11, 9, 7, 6, 5, 4, 3, 3, 2, 2, 2, 1, 1, 1, 1,
               1, 1, 0.6, 0.6, 0.5, 0.4, 0.3, 0.3]
    base = 170
    step = top / len(heights)
    for i, h in enumerate(heights):
        f.rect(X(i * step) + 1, base - h * 3, X(step) - X(0) - 2, h * 3, stroke=None,
               fill='--phosphor', rx=1)
    f.line(X(0), base, X(top), base, stroke='--paper-dim', width=1.2)
    for s in range(0, 9):
        f.line(X(s), base, X(s), base + 5, stroke='--paper-dim', width=1)
        f.text(X(s), base + 16, f'{s} s', size=9.5, mono=True, fill='--paper-dim')
    f.line(X(2.3), 44, X(2.3), 132, stroke='--amber', width=1.6, dash='5 3')
    f.text(X(2.3) + 8, 50, T('75th percentile: 2.3 s', 'percentil 75: 2,3 s'), size=10.5,
           anchor='start', fill='--amber')
    f.rect(X(0), base + 26, X(2.5) - X(0), 6, stroke=None, fill='--phosphor', rx=2)
    f.text(X(2.5) + 8, base + 29, T('good: up to 2.5 s', 'bom: até 2,5 s'), size=10, anchor='start', fill='--paper-dim')
    f.text(30, 110, T('field', 'campo'), size=11, anchor='start', weight='600')
    f.text(X(5.5), 120, T('the slow visits: old phones, bad signal',
                          'as visitas lentas: celulares antigos, sinal ruim'),
           size=10, fill='--paper-dim')
    f.text(30, 236, T('lab', 'laboratório'), size=11, anchor='start', weight='600')
    f.line(X(0), 236, X(top), 236, stroke='--wire', width=1)
    f.circle(X(3.1), 236, 6, fill='--paper')
    f.text(X(3.1) + 12, 236, T('one Lighthouse run: 3.1 s', 'uma execução do Lighthouse: 3,1 s'),
           size=10.5, anchor='start')
    f.text(360, 272, T('an illustration, not a measurement', 'uma ilustração, não uma medição'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('Field data is a distribution of real visits, judged at its 75th percentile; a '
                'lab run is one visit under conditions somebody chose.',
                'Dados de campo são uma distribuição de visitas reais, julgada no percentil 75; '
                'uma execução de laboratório é uma visita em condições que alguém escolheu.')
