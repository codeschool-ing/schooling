"""Lesson 7: Artillery and Vegeta."""
from figures import Fig, T, figure


@figure('l07-pipeline', 7)
def pipeline():
    f = Fig('l07-pipeline', 720, 230, T(
        'Vegeta as a pipeline, left to right. echo writes one target, a line saying GET and an '
        'address. vegeta attack reads targets and sends them at the rate it was given, for the '
        'duration it was given, and writes one binary result per request. tee copies those results '
        'into results.bin on the way. vegeta report reads results and prints them as text, as a '
        'histogram or as JSON, and can read results.bin again later without sending anything.',
        'O Vegeta como um pipeline, da esquerda para a direita. O echo escreve um alvo, uma linha '
        'com GET e um endereço. O vegeta attack lê alvos e os manda na taxa que recebeu, pela duração '
        'que recebeu, e escreve um resultado binário por requisição. O tee copia esses resultados em '
        'results.bin no caminho. O vegeta report lê resultados e os imprime como texto, como '
        'histograma ou como JSON, e consegue ler results.bin de novo depois, sem mandar nada.'))
    boxes = [
        (20, 120, 'echo', [T('one target', 'um alvo'), T('per line', 'por linha')]),
        (172, 150, 'vegeta attack', ['-rate=50', '-duration=10s']),
        (354, 100, 'tee', [T('a copy on', 'uma cópia'), T('the way', 'no caminho')]),
        (486, 214, 'vegeta report', ['-type=text', "-type='hist[...]'", '-type=json']),
    ]
    for x, w, name, rows in boxes:
        f.rect(x, 50, w, 34, stroke='--phosphor', fill='--scan', width=1.4)
        f.text(x + w / 2, 67, name, size=11, weight='600', mono=True)
        f.rect(x, 92, w, 56, stroke='--wire', fill='--panel', width=1.1)
        f.lines(x + w / 2, 120, rows, size=10, mono=name not in ('echo', 'tee'))
    for x0, x1 in ((140, 168), (322, 350), (454, 482)):
        f.arrow([(x0, 67), (x1, 67)])
    f.text(156, 38, T('targets', 'alvos'), size=9.5, fill='--paper-dim')
    f.text(338, 38, T('results', 'resultados'), size=9.5, fill='--paper-dim')
    f.text(470, 38, T('results', 'resultados'), size=9.5, fill='--paper-dim')
    f.rect(354, 176, 100, 30, stroke='--amber', fill='--panel', width=1.2)
    f.text(404, 191, 'results.bin', size=10, mono=True)
    f.arrow([(404, 148), (404, 172)], stroke='--amber')
    f.arrow([(454, 191), (593, 191), (593, 152)], stroke='--amber')
    f.text(600, 210, T('report again, sending nothing', 'relatar de novo, sem mandar nada'),
           size=9.5, fill='--amber', anchor='middle')
    return f, T('Three commands joined by pipes: what to send, sending it, and reading what came back.',
                'Três comandos ligados por pipes: o que mandar, mandar, e ler o que voltou.')


@figure('l07-backlog', 7)
def backlog():
    X0, Y0, W, H = 90, 200, 560, 150      # plot origin (bottom left) and size
    x = lambda t: X0 + t / 10 * W
    y = lambda r: Y0 - r / 320 * H
    f = Fig('l07-backlog', 720, 260, T(
        'Requests a second against time, over the ten seconds of the run at 300 a second, drawn '
        'from its totals rather than sampled. Vegeta sends 300 a second for five seconds and then '
        'stops. The box office answers about 135 a second throughout, until 9.86 seconds. The gap '
        'between the two lines during the attack is the backlog: requests sent and waiting for an '
        'answer. After the attack, the box office spends nearly five more seconds working through '
        'it, and the requests that waited longer than the five-second timeout get no answer.',
        'Requisições por segundo ao longo do tempo, nos dez segundos da execução a 300 por segundo, '
        'desenhadas a partir dos totais e não amostradas. O Vegeta manda 300 por segundo por cinco '
        'segundos e para. A bilheteria responde umas 135 por segundo o tempo todo, até 9,86 segundos. '
        'A distância entre as duas linhas durante o ataque é a fila: requisições mandadas e esperando '
        'resposta. Depois do ataque, a bilheteria passa quase mais cinco segundos atendendo a fila, e '
        'as requisições que esperaram mais que o timeout de cinco segundos ficam sem resposta.'))
    # axes
    f.line(X0, Y0, X0 + W, Y0, stroke='--paper-dim', width=1)
    f.line(X0, Y0, X0, Y0 - H - 10, stroke='--paper-dim', width=1)
    for s in range(0, 11, 2):
        f.line(x(s), Y0, x(s), Y0 + 4, stroke='--paper-dim', width=1)
        f.text(x(s), Y0 + 14, f'{s} s', size=9, mono=True, fill='--paper-dim')
    for r in (0, 135, 300):
        f.line(X0 - 4, y(r), X0, y(r), stroke='--paper-dim', width=1)
        f.text(X0 - 8, y(r), str(r), size=9, mono=True, fill='--paper-dim', anchor='end')
    f.text(X0 - 8, y(320) - 8, T('requests/s', 'requisições/s'), size=9.5, fill='--paper-dim', anchor='start')
    # the backlog wedge
    f.path(f'M{x(0):.1f} {y(300):.1f} L{x(5):.1f} {y(300):.1f} L{x(5):.1f} {y(135):.1f} L{x(0):.1f} {y(135):.1f} Z',
           stroke=None, fill='--scan')
    f.text(x(2.5), (y(300) + y(135)) / 2, T('the backlog grows', 'a fila cresce'), size=10, fill='--amber', weight='600')
    # sent
    f.path(f'M{x(0):.1f} {y(300):.1f} L{x(5):.1f} {y(300):.1f} L{x(5):.1f} {y(0):.1f}', stroke='--amber', width=2)
    f.text(x(5) + 8, y(300), T('sent: 300 a second, then stop', 'mandadas: 300 por segundo, e para'),
           size=10, fill='--amber', anchor='start')
    # answered
    f.path(f'M{x(0):.1f} {y(135):.1f} L{x(9.86):.1f} {y(135):.1f} L{x(9.86):.1f} {y(0):.1f}', stroke='--phosphor', width=2)
    f.text(x(7.4), y(135) - 12, T('answered: about 135 a second', 'respondidas: umas 135 por segundo'),
           size=10, fill='--paper', anchor='middle')
    f.text(x(7.4), y(60), T('the backlog drains', 'a fila esvazia'), size=10, fill='--paper-dim', anchor='middle')
    f.text(360, 244, T('an open generator keeps sending, so the waiting shows up in the times it reports',
                       'um gerador aberto continua mandando, então a espera aparece nos tempos que ele informa'),
           size=10.5, fill='--paper-dim')
    return f, T('The run at 300 a second: the box office cannot keep up, and the requests it has not answered wait in line.',
                'A execução a 300 por segundo: a bilheteria não acompanha, e as requisições ainda sem resposta esperam na fila.')
