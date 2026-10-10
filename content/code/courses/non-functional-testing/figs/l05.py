"""Lesson 5: k6, a load test as JavaScript."""
from figures import Fig, T, figure


@figure('l05-lifecycle', 5)
def lifecycle():
    f = Fig('l05-lifecycle', 720, 230, T(
        'The life of a k6 run, left to right. The init code runs once for every virtual user, '
        'before any load, and k6 refuses a request there. The setup function, if the script has '
        'one, runs once and may send requests. The default function then runs once per iteration, '
        'over and over, for as long as the scenario lasts. When the scenario ends, k6 gathers every '
        'sample into the summary and compares the thresholds. If all of them hold, k6 exits with 0; '
        'if any one is crossed, it exits with 99, and that code is what a terminal or a pipeline '
        'reads.',
        'A vida de uma execução do k6, da esquerda para a direita. O código de inicialização roda '
        'uma vez para cada usuário virtual, antes de qualquer carga, e o k6 recusa uma requisição '
        'ali. A função setup, se o script tiver uma, roda uma vez e pode mandar requisições. Depois '
        'a função padrão roda uma vez por iteração, de novo e de novo, enquanto o cenário durar. '
        'Quando o cenário termina, o k6 junta todas as amostras no resumo e compara os limites. Se '
        'todos se mantêm, o k6 sai com 0; se algum é ultrapassado, sai com 99, e esse código é o que '
        'um terminal ou um pipeline lê.'))
    boxes = [
        (20, 112, T('init code', 'inicialização'), [T('once per', 'uma vez por'), T('virtual user', 'usuário virtual')]),
        (146, 112, 'setup()', [T('once,', 'uma vez,'), T('before the load', 'antes da carga')]),
        (272, 150, T('default function', 'função padrão'), [T('once per iteration,', 'uma vez por iteração,'), T('the whole scenario', 'o cenário inteiro')]),
        (436, 110, T('summary', 'resumo'), [T('every sample', 'todas as amostras')]),
    ]
    for x, w, name, rows in boxes:
        f.rect(x, 70, w, 34, stroke='--phosphor', fill='--scan', width=1.4)
        f.text(x + w / 2, 87, name, size=11, weight='600', mono=name == 'setup()')
        f.rect(x, 112, w, 50, stroke='--wire', fill='--panel', width=1.1)
        f.lines(x + w / 2, 137, rows, size=10)
    for x0, x1 in ((132, 142), (258, 268), (422, 432), (546, 556)):
        f.arrow([(x0, 87), (x1, 87)])
    f.path('M312 70 C312 40, 382 40, 382 66', stroke='--paper-dim', width=1.2, arrow=True)
    f.text(347, 34, T('again, until the scenario ends', 'de novo, até o cenário acabar'), size=9.5, fill='--paper-dim')
    f.rect(560, 70, 140, 34, stroke='--amber', fill='--scan', width=1.4)
    f.text(630, 87, T('thresholds', 'limites'), size=11, weight='600')
    f.rect(560, 132, 64, 30, stroke='--phosphor', fill='--panel', width=1.2)
    f.text(592, 147, 'exit 0', size=10.5, mono=True)
    f.rect(636, 132, 64, 30, stroke='--amber', fill='--panel', width=1.2)
    f.text(668, 147, 'exit 99', size=10.5, mono=True)
    f.arrow([(592, 104), (592, 128)])
    f.arrow([(668, 104), (668, 128)], stroke='--amber')
    f.text(592, 180, T('all hold', 'todos valem'), size=9.5, fill='--paper-dim')
    f.text(668, 180, T('one crossed', 'um ultrapassado'), size=9.5, fill='--amber')
    f.text(76, 180, T('no requests here', 'sem requisições'), size=9.5, fill='--amber')
    f.text(360, 212, T('requests belong in setup() or in the default function; only the second is the load',
                       'requisições ficam no setup() ou na função padrão; só a segunda é a carga'),
           size=10.5, fill='--paper-dim')
    return f, T('Where each part of a k6 script runs, and how the run becomes an exit code.',
                'Onde cada parte de um script do k6 roda, e como a execução vira um código de saída.')


def _lane(f, y, label, sub):
    from figures import width
    f.text(20, y, label, size=11, weight='600', anchor='start')
    f.text(20 + width(label, 11, '600') + 10, y, sub, size=9.5, anchor='start', fill='--paper-dim', mono=True)


@figure('l05-executors', 5)
def executors():
    X0, S = 130, 66.0          # x of t=0 and pixels per second, 0 to 8.5 s
    slow = (3.0, 6.0)          # the server answers slowly in this window
    req = lambda t: 1.2 if slow[0] <= t < slow[1] else 0.25
    think = 1.0
    f = Fig('l05-executors', 720, 330, T(
        'Two ways k6 decides when an iteration starts, over eight seconds in which the server is '
        'slow from the third second to the sixth. Above, three looping virtual users: each starts '
        'its next iteration only when its request and its think time are over, so while the server '
        'is slow the starts thin out, and the load falls when the system struggles. Below, an '
        'arrival rate of two iterations a second: they start on the clock whatever the server does, '
        'and k6 takes another virtual user from the pool when every busy one is still waiting, so '
        'more of them are in use during the slow stretch.',
        'Dois jeitos de o k6 decidir quando uma iteração começa, em oito segundos nos quais o '
        'servidor fica lento do terceiro ao sexto. Em cima, três usuários virtuais em laço: cada um '
        'começa a próxima iteração só quando a requisição e o tempo de reflexão terminam, então '
        'enquanto o servidor está lento os inícios rareiam, e a carga cai quando o sistema sofre. '
        'Embaixo, uma taxa de chegada de duas iterações por segundo: elas começam no relógio, faça o '
        'servidor o que fizer, e o k6 pega outro usuário virtual do conjunto quando todos os ocupados '
        'ainda esperam, então mais deles ficam em uso no trecho lento.'))
    x = lambda t: X0 + t * S
    end = 8.0
    # the slow window, across both lanes
    x1, x2 = x(slow[0]), x(slow[1])
    f.path(f'M{x1:.1f} 40 L{x2:.1f} 40 L{x2:.1f} 302 L{x1:.1f} 302 Z', stroke=None, fill='--scan')
    f.text(x((slow[0] + slow[1]) / 2), 30, T('server slow', 'servidor lento'), size=10, fill='--amber', weight='600')

    def bar(t, row_y, colour='--phosphor'):
        r = min(req(t), end - t)
        f.rect(x(t), row_y, r * S, 10, stroke=None, fill=colour, rx=1)
        w = min(think, end - t - r) * S
        if w > 0:
            f.rect(x(t + r), row_y + 3, w, 4, stroke=None, fill='--paper-dim', rx=1)
        return t + r + think

    # looping VUs
    _lane(f, 50, T('looping virtual users', 'usuários virtuais em laço'), 'constant-vus')
    starts = []
    for i in range(3):
        y = 66 + i * 16
        f.text(122, y + 5, f'VU {i + 1}', size=9, anchor='end', mono=True, fill='--paper-dim')
        t = i * 0.4
        while t < end - 0.3:
            starts.append(t)
            t = bar(t, y)
    for t in starts:
        f.line(x(t), 116, x(t), 124, stroke='--amber', width=1.4)
    f.text(x(end) + 4, 120, T('starts', 'inícios'), size=9, anchor='start', fill='--amber')

    # arrival rate
    _lane(f, 152, T('arrival rate, 2 a second', 'taxa de chegada, 2 por segundo'), 'constant-arrival-rate')
    free = []
    rows_used = 0
    t = 0.0
    arrivals = []
    while t < end - 0.3:
        arrivals.append(t)
        r = next((i for i, until in enumerate(free) if until <= t + 1e-9), None)
        if r is None:
            free.append(0)
            r = len(free) - 1
        y = 166 + r * 14
        free[r] = bar(t, y)
        t += 0.5
    rows_used = len(free)
    for i in range(rows_used):
        f.text(122, 166 + i * 14 + 5, f'VU {i + 1}', size=9, anchor='end', mono=True, fill='--paper-dim')
    base = 166 + rows_used * 14 + 4
    for t in arrivals:
        f.line(x(t), base, x(t), base + 8, stroke='--amber', width=1.4)
    f.text(x(end) + 4, base + 4, T('starts', 'inícios'), size=9, anchor='start', fill='--amber')

    # time axis
    ay = 312
    f.line(X0, ay, x(end), ay, stroke='--paper-dim', width=1)
    for s in range(0, 9):
        f.line(x(s), ay, x(s), ay + 4, stroke='--paper-dim', width=1)
        f.text(x(s), ay + 12, f'{s} s', size=9, mono=True, fill='--paper-dim')
    # key
    f.rect(20, 262, 16, 10, stroke=None, fill='--phosphor', rx=1)
    f.text(42, 267, T('request', 'requisição'), size=9.5, anchor='start')
    f.rect(20, 281, 16, 4, stroke=None, fill='--paper-dim', rx=1)
    f.text(42, 283, T('think time', 'reflexão'), size=9.5, anchor='start')
    return f, T('Looping virtual users let the server set the pace; an arrival rate keeps to the clock.',
                'Usuários em laço deixam o servidor ditar o ritmo; uma taxa de chegada segue o relógio.')
