"""Lesson 16: reactive programming."""
from figures import Fig, T, figure


@figure('l16-marbles', 16)
def marbles():
    f = Fig('l16-marbles', 700, 400, T(
        'A marble diagram of operators.py. Four horizontal timelines, one under the other, with time '
        'running to the right. The top line, the returns, carries four marbles: Dom Casmurro 0 days '
        'late, Vidas Secas 3, Iracema 0 and O Cortiço 5, then a bar for completion. Under it, '
        'filter_ keeps only the late ones, so the second line has two marbles, 3 and 5, at the same '
        'moments as before. map_ turns them into 150 and 250 cents on the third line, and scan adds '
        'them up into 150 and 400 on the bottom line. Every line ends with the same completion bar.',
        'Um diagrama de bolinhas de operators.py. Quatro linhas do tempo horizontais, uma embaixo da '
        'outra, com o tempo correndo para a direita. A linha de cima, as devoluções, tem quatro '
        'bolinhas: Dom Casmurro com 0 dias de atraso, Vidas Secas 3, Iracema 0 e O Cortiço 5, e '
        'depois uma barra de conclusão. Abaixo, filter_ deixa passar só as atrasadas, então a segunda '
        'linha tem duas bolinhas, 3 e 5, nos mesmos instantes de antes. map_ as transforma em 150 e '
        '250 centavos na terceira linha, e scan soma tudo em 150 e 400 na linha de baixo. Toda linha '
        'termina com a mesma barra de conclusão.'))
    xs = [200, 320, 440, 560]
    rows = [
        (50, T('returns', 'devoluções'), ['0', '3', '0', '5']),
        (150, T('late only', 'só atrasadas'), [None, '3', None, '5']),
        (250, T('in cents', 'em centavos'), [None, '150', None, '250']),
        (350, T('running total', 'total acumulado'), [None, '150', None, '400']),
    ]
    titles = ['Dom Casmurro', 'Vidas Secas', 'Iracema', 'O Cortiço']
    for y, label, vals in rows:
        f.text(20, y, label, size=10.5, anchor='start', weight='600')
        f.arrow([(140, y), (670, y)], stroke='--paper-dim', width=1.2)
        f.line(620, y - 14, 620, y + 14, stroke='--paper', width=2)
        for x, v in zip(xs, vals):
            if v is None:
                continue
            f.circle(x, y, 17, fill='--panel', stroke='--phosphor', width=1.6)
            f.text(x, y, v, size=10.5, mono=True, weight='600')
    for x, t in zip(xs, titles):
        f.text(x, 80, t, size=8.5, mono=True, fill='--paper-dim')
    ops = [(100, 'filter_(days late > 0)'), (200, 'map_(days × 50)'), (300, 'scan(+, seed 0)')]
    for y, s in ops:
        f.box(380, y, 230, 22, [s], size=9.5, mono=True, stroke='--amber')
    f.text(670, 30, T('time →', 'tempo →'), size=9.5, anchor='end', fill='--paper-dim', italic=True)
    f.text(620, 382, T('complete', 'fim'), size=9, fill='--paper-dim', italic=True)
    return f, T('Each value goes down the whole chain at the moment it arrives. A value filter_ holds back leaves a gap in time, not a None.',
                'Cada valor desce a cadeia inteira no instante em que chega. Um valor que o filter_ segura deixa um vão no tempo, não um None.')


@figure('l16-strategies', 16)
def strategies():
    f = Fig('l16-strategies', 760, 260, T(
        'A grid with one row per strategy and one column per scan, 1 to 12. A scan the catalogue '
        'handled has a solid box; a lost scan has a dashed one. Buffer handles all twelve, lost 0, '
        'its queue reached 9, scanner done at tick 12. Drop handles 1, 2, 4, 7 and 10, lost 7, '
        'queue 2, scanner done at tick 12. Latest handles 3, 6, 9 and 12, lost 8, queue 1, scanner '
        'done at tick 12. Block handles all twelve, lost 0, queue 2, but the scanner finished at '
        'tick 31.',
        'Uma grade com uma linha por estratégia e uma coluna por leitura, de 1 a 12. Uma leitura '
        'que o catálogo tratou tem caixa cheia; uma leitura perdida tem caixa tracejada. Buffer trata '
        'as doze, perde 0, a fila chegou a 9, o leitor terminou no tick 12. Drop trata 1, 2, 4, 7 e '
        '10, perde 7, fila 2, leitor no tick 12. Latest trata 3, 6, 9 e 12, perde 8, fila 1, leitor '
        'no tick 12. Block trata as doze, perde 0, fila 2, mas o leitor só terminou no tick 31.'))
    x0, cw, ch = 110, 32, 26
    rows = [
        ('buffer', set(range(1, 13)), '0', '9', '12'),
        ('drop', {1, 2, 4, 7, 10}, '7', '2', '12'),
        ('latest', {3, 6, 9, 12}, '8', '1', '12'),
        ('block', set(range(1, 13)), '0', '2', '31'),
    ]
    f.text(20, 30, T('scan', 'leitura'), size=10, anchor='start', fill='--paper-dim')
    for i in range(12):
        f.text(x0 + i * cw + cw / 2, 30, str(i + 1), size=9.5, mono=True, fill='--paper-dim')
    heads = [(550, T('lost', 'perdidas')), (625, T('largest queue', 'maior fila')),
             (708, T('scanner done', 'leitor terminou'))]
    for x, h in heads:
        f.text(x, 30, h, size=9.5, fill='--paper-dim')
    for r, (name, handled, lost, largest, done) in enumerate(rows):
        y = 50 + r * 40
        f.text(20, y + ch / 2, name, size=10.5, anchor='start', mono=True, weight='600')
        for i in range(12):
            n = i + 1
            x = x0 + i * cw + 2
            if n in handled:
                f.rect(x, y, cw - 4, ch, stroke='--phosphor', fill='--panel', width=1.6, rx=2)
                f.text(x + (cw - 4) / 2, y + ch / 2, str(n), size=9.5, mono=True)
            else:
                f.rect(x, y, cw - 4, ch, stroke='--paper-dim', fill='--ink', width=1, rx=2, dash='3 3')
        costly = {(550, lost) if lost != '0' else None, (625, largest) if int(largest) > 2 else None,
                  (708, done) if done != '12' else None}
        for x, v in [(550, lost), (625, largest), (708, done)]:
            f.text(x, y + ch / 2, v, size=10.5, mono=True, weight='600',
                   fill='--amber' if (x, v) in costly else '--paper')
    ly = 228
    f.rect(110, ly - 9, 28, 18, stroke='--phosphor', fill='--panel', width=1.6, rx=2)
    f.text(146, ly, T('handled by the catalogue', 'tratada pelo catálogo'), size=9.5, anchor='start')
    f.rect(330, ly - 9, 28, 18, stroke='--paper-dim', fill='--ink', width=1, rx=2, dash='3 3')
    f.text(366, ly, T('lost', 'perdida'), size=9.5, anchor='start')
    return f, T('The same twelve scans under four strategies. Two lose nothing and pay in memory or in the producer\'s time; two keep the queue short and pay in scans.',
                'As mesmas doze leituras sob quatro estratégias. Duas não perdem nada e pagam em memória ou no tempo do produtor; duas mantêm a fila curta e pagam em leituras.')
