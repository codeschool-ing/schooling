"""Lesson 11: performance budgets and the regression gate."""
import math

from figures import Fig, T, figure


@figure('l11-noise', 11)
def noise():
    f = Fig('l11-noise', 720, 345, T(
        'The 95th percentile of GET /shows/{id} in every k6 run of this lesson, one dot per run, '
        'on a logarithmic scale from 1 to 50 milliseconds. A dashed line marks the baseline at '
        '3.18 ms and a solid amber line the limit at 9.8 ms. With the index in place: the three '
        'baseline runs at 2.11, 3.18 and 3.38 ms; the gate on the fixed page at 3.1, 1.9 and 1.7 '
        'ms, all under the limit; the gate on the slow page at 2.1, 12.5 and 11.4 ms, two of them '
        'over the limit with no change to the code. With the index dropped: the single run at '
        '33.4 ms and the gate at 23.1, 16.8 and 21.9 ms, all far over the limit.',
        'O percentil 95 do GET /shows/{id} em cada execução do k6 desta aula, um ponto por '
        'execução, numa escala logarítmica de 1 a 50 milissegundos. Uma linha tracejada marca a '
        'linha de base em 3,18 ms e uma linha âmbar contínua o limite em 9,8 ms. Com o índice: as '
        'três execuções da linha de base em 2,11, 3,18 e 3,38 ms; o portão na página corrigida em '
        '3,1, 1,9 e 1,7 ms, todas abaixo do limite; o portão na página lenta em 2,1, 12,5 e 11,4 '
        'ms, duas acima do limite sem mudança nenhuma no código. Sem o índice: a execução avulsa '
        'em 33,4 ms e o portão em 23,1, 16,8 e 21,9 ms, todas bem acima do limite.'))
    x0, x1, lo, hi = 250, 690, 1.0, 50.0

    def X(ms):
        return x0 + (x1 - x0) * math.log(ms / lo) / math.log(hi / lo)
    rows = [
        (T('baseline, 3 runs', 'linha de base, 3 execuções'), [2.113, 3.177, 3.385], '--paper'),
        (T('gate on /fast.html', 'portão em /fast.html'), [3.1, 1.9, 1.7], '--paper'),
        (T('gate on /', 'portão em /'), [2.1, 12.5, 11.4], '--paper'),
        (T('one run', 'uma execução'), [33.4], '--amber'),
        (T('gate on /fast.html', 'portão em /fast.html'), [23.1, 16.8, 21.9], '--amber'),
    ]
    ys = [64, 100, 136, 202, 238]
    top, bottom = ys[0], ys[-1]
    f.text(30, 36, T('index in place', 'com índice'), size=10.5, anchor='start', weight='600',
           fill='--paper-dim')
    f.text(30, 174, T('index dropped', 'sem índice'), size=10.5, anchor='start',
           weight='600', fill='--paper-dim')
    for y, (label, values, fill) in zip(ys, rows):
        f.text(30, y, label, size=10.5, anchor='start')
        f.line(x0, y, x1, y, stroke='--wire', width=1)
        for v in values:
            f.circle(X(v), y, 5.5, fill=fill)
    f.line(X(3.177), top - 18, X(3.177), bottom + 14, stroke='--paper-dim', width=1.2, dash='4 3')
    f.line(X(9.8), top - 18, X(9.8), bottom + 14, stroke='--amber', width=1.8)
    f.text(X(3.177), bottom + 28, T('baseline 3.18 ms', 'linha de base 3,18 ms'), size=10,
           fill='--paper-dim')
    f.text(X(9.8) + 6, bottom + 28, T('limit 9.8 ms', 'limite 9,8 ms'), size=10, anchor='start',
           fill='--amber')
    axis = bottom + 52
    f.line(x0, axis, x1, axis, stroke='--paper-dim', width=1)
    for ms in (1, 2, 5, 10, 20, 50):
        f.line(X(ms), axis, X(ms), axis + 5, stroke='--paper-dim', width=1)
        f.text(X(ms), axis + 16, f'{ms} ms', size=9.5, mono=True, fill='--paper-dim')
    return f, T('Every run of the back end in this lesson. The two dots right of the limit in the '
                'third row are noise: the code was the baseline\'s.',
                'Todas as execuções do back-end nesta aula. Os dois pontos à direita do limite na '
                'terceira linha são ruído: o código era o da linha de base.')


@figure('l11-gate', 11)
def gate():
    f = Fig('l11-gate', 720, 250, T(
        'How gate.sh decides. On the front end, three Lighthouse runs of the page feed budget.py, '
        'which takes the median of each number and compares it with the budget, failing on any '
        'line over. On the back end, three k6 runs of GET /shows/{id}, each judged by its own '
        'thresholds, the 200 ms requirement and the baseline with its tolerance; the back end '
        'fails when two or more runs cross. The gate exits 0 only when both halves pass, and 1 '
        'otherwise, and the pipeline reads nothing but that exit code.',
        'Como o gate.sh decide. No front-end, três execuções do Lighthouse na página alimentam o '
        'budget.py, que tira a mediana de cada número e a compara com o orçamento, reprovando em '
        'qualquer linha acima. No back-end, três execuções do k6 no GET /shows/{id}, cada uma '
        'julgada pelos próprios limites, o requisito de 200 ms e a linha de base com a tolerância; '
        'o back-end reprova quando duas ou mais cruzam. O portão sai com 0 só quando as duas '
        'metades passam, e com 1 caso contrário, e o pipeline não lê nada além desse código de '
        'saída.'))
    lanes = [
        (70, T('front end', 'front-end'), 'lighthouse', T('median of each number', 'mediana de cada número'),
         T('over budget?', 'acima do orçamento?')),
        (170, T('back end', 'back-end'), 'k6', T('each run vs its thresholds', 'cada execução contra os limites'),
         T('2 of 3 crossed?', '2 de 3 cruzaram?')),
    ]
    for y, name, tool, middle, test in lanes:
        f.text(30, y, name, size=11, anchor='start', weight='600')
        for k in range(3):
            f.rect(114 + k * 8, y - 22 + k * 6, 112, 30, stroke='--wire', fill='--panel', width=1.1)
        f.text(186, y + 5, f'{tool} ×3', size=10.5, mono=True)
        f.arrow([(244, y + 5), (268, y)], stroke='--paper-dim')
        f.rect(272, y - 18, 170, 36, stroke='--wire', fill='--panel', width=1.1)
        f.text(357, y, middle, size=10.5)
        f.arrow([(442, y), (478, y)], stroke='--paper-dim')
        f.rect(482, y - 18, 110, 36, stroke='--amber', fill='--panel', width=1.3)
        f.text(537, y, test, size=10.5)
        f.arrow([(592, y), (622, 120 + (y - 120) * 0.3)], stroke='--paper-dim')
    f.rect(626, 96, 74, 48, stroke='--phosphor', fill='--scan', width=1.6)
    f.text(663, 112, 'exit 0', size=10.5, mono=True)
    f.text(663, 130, 'exit 1', size=10.5, mono=True, fill='--amber')
    f.text(360, 226, T('the pipeline reads the exit code and nothing else',
                       'o pipeline lê o código de saída e nada mais'), size=10.5, fill='--paper-dim')
    return f, T('The gate: medians against a budget on one side, a majority of runs against '
                'thresholds on the other, and one exit code for both.',
                'O portão: medianas contra um orçamento de um lado, a maioria das execuções contra '
                'limites do outro, e um código de saída para os dois.')
