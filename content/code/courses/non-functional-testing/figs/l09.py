"""Lesson 9: finding the bottleneck. The timings are the lesson's own captures."""
from figures import Fig, T, figure


@figure('l09-layers', 9)
def layers():
    f = Fig('l09-layers', 720, 330, T(
        'One request for GET /shows/990 traced through four layers, left to right. The client, '
        'curl, measured 11.5 ms from start to finish. Inside that, the network: the connection, '
        'the kernel queue of connections waiting to be accepted, and the packets of the answer. '
        'Inside that, the application, whose Server-Timing header said 10.7 ms in total. Inside '
        'that, the database, which took 10.2 ms counting the bookings. Under all four runs the '
        'infrastructure: processors, memory and disk, shared by the server and the load '
        'generator. Each layer is named with the tool that sees it: curl -w and nstat for the '
        'network, Server-Timing for the application, EXPLAIN QUERY PLAN for the database, top, '
        'vmstat and free for the infrastructure.',
        'Uma requisição GET /shows/990 seguida por quatro camadas, da esquerda para a direita. O '
        'cliente, o curl, mediu 11.5 ms do começo ao fim. Dentro disso, a rede: a conexão, a fila '
        'do kernel de conexões esperando para serem aceitas, e os pacotes da resposta. Dentro '
        'disso, a aplicação, cujo cabeçalho Server-Timing disse 10.7 ms no total. Dentro disso, o '
        'banco de dados, que levou 10.2 ms contando as reservas. Debaixo das quatro fica a '
        'infraestrutura: processadores, memória e disco, divididos entre o servidor e o gerador de '
        'carga. Cada camada aparece com a ferramenta que a enxerga: curl -w e nstat para a rede, '
        'Server-Timing para a aplicação, EXPLAIN QUERY PLAN para o banco, top, vmstat e free para '
        'a infraestrutura.'))
    rows = [
        (20, 680, T('client', 'cliente'), 'curl: 11.5 ms', 'curl -w'),
        (60, 600, T('network', 'rede'), T('connection, accept queue, packets', 'conexão, fila de aceite, pacotes'), 'nstat'),
        (100, 520, T('application', 'aplicação'), 'Server-Timing total: 10.7 ms', 'Server-Timing'),
        (140, 440, T('database', 'banco de dados'), 'db: 10.2 ms', 'EXPLAIN QUERY PLAN'),
    ]
    for i, (x, w, name, what, tool) in enumerate(rows):
        y = 30 + i * 52
        h = 230 - i * 52 - 10 * i
        f.rect(x, y, w, h, stroke='--phosphor' if i == 0 else '--wire', fill='--panel' if i % 2 == 0 else '--scan',
               width=1.3)
        f.text(x + 12, y + 16, name, size=11, anchor='start', weight='600')
        f.text(x + 12, y + 32, what, size=10, anchor='start', mono=i != 1, fill='--paper-dim' if i == 1 else '--paper')
        f.text(x + w - 12, y + 16, tool, size=10, anchor='end', mono=True, fill='--amber')
    f.rect(20, 268, 680, 46, stroke='--amber', fill='--scan', width=1.3, dash='5 3')
    f.text(32, 284, T('infrastructure, under every layer', 'infraestrutura, debaixo de todas as camadas'), size=11,
           anchor='start', weight='600')
    f.text(32, 300, T('processors, memory, disk, shared with the load generator',
                      'processadores, memória, disco, divididos com o gerador de carga'), size=10, anchor='start',
           fill='--paper-dim')
    f.text(688, 284, 'top  vmstat  free', size=10, anchor='end', mono=True, fill='--amber')
    return f, T('Each layer holds the one inside it, so each layer\'s time includes the time of the layers within. The difference between two of them is the time spent in between.',
                'Cada camada contém a de dentro, então o tempo de cada camada inclui o das camadas internas. A diferença entre duas delas é o tempo gasto no meio.')


@figure('l09-lock', 9)
def lock():
    f = Fig('l09-lock', 720, 300, T(
        'Four workers booking at once, drawn on a time axis of 200 milliseconds. Above, app.py: '
        'the lock lets one booking in at a time, and each holds it for its 40 ms payment, so the '
        'four payments run one after another and the fourth worker waits for three payments '
        'before its own. Below, app_fixed.py: each booking writes its row, which the unique index '
        'settles at once, then pays with no lock held, so the four payments run side by side and '
        'all four finish after about 40 ms.',
        'Quatro workers reservando ao mesmo tempo, desenhados num eixo de 200 milissegundos. Em '
        'cima, o app.py: a trava deixa entrar uma reserva por vez, e cada uma a segura durante o '
        'pagamento de 40 ms, então os quatro pagamentos acontecem um depois do outro e o quarto '
        'worker espera três pagamentos antes do seu. Embaixo, o app_fixed.py: cada reserva grava '
        'a sua linha, que o índice único resolve na hora, e depois paga sem trava nenhuma, então os '
        'quatro pagamentos acontecem lado a lado e os quatro terminam depois de uns 40 ms.'))
    x0, sx = 150, 2.6       # 2.6 px per ms
    for k, (title, file, serial) in enumerate(((T('one lock', 'uma trava'), 'app.py', True),
                                               (T('no lock', 'sem trava'), 'app_fixed.py', False))):
        top = 40 + k * 130
        f.text(20, top + 6, title, size=11, anchor='start', weight='600')
        f.text(20, top + 22, file, size=10, anchor='start', mono=True, fill='--paper-dim')
        for w in range(4):
            y = top + w * 22
            f.text(x0 - 10, y + 8, T(f'worker {w + 1}', f'worker {w + 1}'), size=9.5, anchor='end', fill='--paper-dim')
            start = w * 44 if serial else 2
            if serial and w:
                f.rect(x0, y + 2, start * sx, 12, stroke='--paper-dim', fill='--panel', width=1, rx=2, dash='3 3')
            f.rect(x0 + start * sx, y + 2, 40 * sx, 12, stroke='--amber',
                   fill='--scan', width=1.2, rx=2)
        f.line(x0, top + 92, x0 + 200 * sx, top + 92, stroke='--paper-dim', width=0.8)
        for ms in range(0, 201, 40):
            f.text(x0 + ms * sx, top + 104, str(ms), size=9, mono=True, fill='--paper-dim')
    f.rect(x0 + 140 * sx, 40, 14, 10, stroke='--paper-dim', fill='--panel', width=1, rx=2, dash='3 3')
    f.text(x0 + 140 * sx + 20, 45, T('waiting for the lock', 'esperando a trava'), size=9.5, anchor='start',
           fill='--paper-dim')
    f.rect(x0 + 140 * sx, 58, 14, 10, stroke='--amber', fill='--scan', width=1.2, rx=2)
    f.text(x0 + 140 * sx + 20, 63, T('paying, 40 ms', 'pagando, 40 ms'), size=9.5, anchor='start',
           fill='--paper-dim')
    f.text(x0 + 200 * sx, 292, 'ms', size=9.5, anchor='end', fill='--paper-dim')
    return f, T('With the payment inside the lock, four workers take four payments\' time. Outside it, they take one.',
                'Com o pagamento dentro da trava, quatro workers levam o tempo de quatro pagamentos. Fora dela, levam o de um.')
