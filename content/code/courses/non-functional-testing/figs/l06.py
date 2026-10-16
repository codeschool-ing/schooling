"""Lesson 6: Gatling and Locust."""
from figures import Fig, T, figure, width


@figure('l06-users', 6)
def users():
    X0, S, END = 140, 54.0, 10.0
    x = lambda t: X0 + t * S
    f = Fig('l06-users', 720, 300, T(
        'What one user is, over ten seconds of a test. Above, Gatling with an open injection of one '
        'user a second: each user arrives, looks at a show, pauses, books, and leaves, so a new short '
        'bar starts every second and about three are inside at any moment. Below, Locust with three '
        'users: each one stays for the whole test, and runs one task after another with a wait '
        'between them. In Gatling the number set is arrivals a second; in Locust it is how many '
        'users are inside at once.',
        'O que é um usuário, em dez segundos de teste. Em cima, o Gatling com uma injeção aberta de um '
        'usuário por segundo: cada usuário chega, olha um espetáculo, pausa, reserva e vai embora, então '
        'uma barra curta nova começa a cada segundo e há uns três dentro a qualquer momento. Embaixo, o '
        'Locust com três usuários: cada um fica o teste inteiro e roda uma tarefa atrás da outra, com uma '
        'espera entre elas. No Gatling o número definido é chegadas por segundo; no Locust é quantos '
        'usuários estão dentro ao mesmo tempo.'))

    def lane(y, title, sub):
        f.text(20, y, title, size=11, weight='600', anchor='start')
        f.text(20 + width(title, 11, '600') + 10, y, sub, size=9.5, anchor='start', fill='--paper-dim', mono=True)

    lane(30, 'Gatling', 'constantUsersPerSec(1)')
    pauses = [2.0, 1.4, 2.6, 1.8, 1.2, 2.2, 2.8, 1.6]
    for i, p in enumerate(pauses):
        t0, y = float(i), 46 + (i % 4) * 16
        t1 = t0 + 0.2
        t2 = t1 + p
        t3 = t2 + 0.25
        if t3 > END:
            continue
        f.rect(x(t0), y, 0.2 * S, 10, stroke=None, fill='--phosphor', rx=1)
        f.rect(x(t1), y + 3, p * S, 4, stroke=None, fill='--paper-dim', rx=1)
        f.rect(x(t2), y, 0.25 * S, 10, stroke=None, fill='--amber', rx=1)
        f.circle(x(t3) + 5, y + 5, 2.5, fill='--paper')
    f.text(X0 - 8, 70, T('one bar,', 'uma barra,'), size=9.5, anchor='end', fill='--paper-dim')
    f.text(X0 - 8, 83, T('one user', 'um usuário'), size=9.5, anchor='end', fill='--paper-dim')

    lane(150, 'Locust', '-u 3, between(1, 3)')
    waits = [[1.2, 2.5, 1.8, 2.9, 1.1], [2.2, 1.3, 2.7, 1.5, 2.0], [1.6, 2.8, 1.2, 2.3, 1.9]]
    kinds = [['s', 's', 'b', 's', 's', 's'], ['s', 'b', 's', 's', 'b', 's'], ['s', 's', 's', 'b', 's', 's']]
    for u in range(3):
        y = 168 + u * 18
        f.text(X0 - 8, y + 5, f'user {u + 1}', size=9, anchor='end', mono=True, fill='--paper-dim')
        t = u * 0.5
        for k, kind in enumerate(kinds[u]):
            d = 0.2 if kind == 's' else 0.25
            if t + d > END:
                break
            f.rect(x(t), y, d * S, 10, stroke=None, fill='--phosphor' if kind == 's' else '--amber', rx=1)
            t += d
            if k < len(waits[u]):
                w = min(waits[u][k], END - t)
                if w > 0:
                    f.rect(x(t), y + 3, w * S, 4, stroke=None, fill='--paper-dim', rx=1)
                t += waits[u][k]
            if t >= END:
                break

    ay = 238
    f.line(X0, ay, x(END), ay, stroke='--paper-dim', width=1)
    for s in range(0, 11, 2):
        f.line(x(s), ay, x(s), ay + 4, stroke='--paper-dim', width=1)
        f.text(x(s), ay + 13, f'{s} s', size=9, mono=True, fill='--paper-dim')
    ky = 272
    f.rect(140, ky - 5, 16, 10, stroke=None, fill='--phosphor', rx=1)
    f.text(162, ky, T('look at a show', 'olhar um espetáculo'), size=9.5, anchor='start')
    f.rect(290, ky - 5, 16, 10, stroke=None, fill='--amber', rx=1)
    f.text(312, ky, T('book a seat', 'reservar um assento'), size=9.5, anchor='start')
    f.rect(440, ky - 2, 16, 4, stroke=None, fill='--paper-dim', rx=1)
    f.text(462, ky, T('pause or wait', 'pausa ou espera'), size=9.5, anchor='start')
    f.circle(590, ky, 2.5, fill='--paper')
    f.text(600, ky, T('leaves', 'vai embora'), size=9.5, anchor='start')
    return f, T('A Gatling user arrives, does the journey once and leaves; a Locust user stays and loops.',
                'Um usuário do Gatling chega, faz a jornada uma vez e vai embora; um do Locust fica e repete.')
