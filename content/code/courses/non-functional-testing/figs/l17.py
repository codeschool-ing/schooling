"""Lesson 17: privilege escalation, and the life of a session."""
from figures import Fig, T, figure


@figure('l17-escalation', 17)
def escalation():
    f = Fig('l17-escalation', 720, 280, T(
        'Two roles drawn as two levels. On the lower level, two customers, ana and bia, each with '
        'her own booking. On the upper level, staff, with the list of every booking. An arrow '
        'sideways from bia to ana\'s booking is horizontal escalation: the same role, somebody '
        'else\'s data, tested by account.py\'s owner check. An arrow upwards from ana to the staff '
        'list is vertical escalation: a role she does not have, tested by the role check. Both '
        'arrows must end in a refusal.',
        'Dois papéis desenhados como dois níveis. No de baixo, duas clientes, ana e bia, cada uma com '
        'a sua reserva. No de cima, a equipe, com a lista de todas as reservas. Uma seta para o lado, '
        'de bia até a reserva de ana, é escalonamento horizontal: o mesmo papel, dados de outra '
        'pessoa, testado pela verificação de dono do account.py. Uma seta para cima, de ana até a '
        'lista da equipe, é escalonamento vertical: um papel que ela não tem, testado pela '
        'verificação de papel. As duas setas têm de terminar numa recusa.'))
    f.text(360, 22, T('two directions, one rule: the answer is a refusal',
                      'duas direções, uma regra: a resposta é uma recusa'),
           size=11, weight='600', fill='--paper-dim')
    # levels
    f.rect(40, 50, 640, 70, stroke='--wire', fill='--panel', width=1.1)
    f.text(56, 64, T('staff', 'equipe'), size=10, anchor='start', fill='--paper-dim', italic=True)
    f.rect(40, 160, 640, 90, stroke='--wire', fill='--panel', width=1.1)
    f.text(56, 174, T('customer', 'cliente'), size=10, anchor='start', fill='--paper-dim', italic=True)
    # staff list
    f.rect(140, 70, 170, 34, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(225, 87, '/staff/bookings', size=10, mono=True)
    # customers
    f.rect(110, 190, 90, 34, stroke='--paper-dim', fill='--ink', width=1.3)
    f.text(155, 207, 'ana', size=10.5, weight='600', mono=True)
    f.rect(220, 190, 110, 34, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(275, 207, T('booking 1', 'reserva 1'), size=10)
    f.rect(500, 190, 90, 34, stroke='--paper-dim', fill='--ink', width=1.3)
    f.text(545, 207, 'bia', size=10.5, weight='600', mono=True)
    # horizontal arrow bia -> booking 1
    f.arrow([(500, 207), (334, 207)], stroke='--amber', width=1.6, dash='6 4')
    f.text(417, 196, T('horizontal', 'horizontal'), size=10, weight='600', fill='--amber')
    f.text(417, 238, T('owner check: 404', 'dono: 404'), size=9.5, fill='--paper-dim')
    # vertical arrow ana -> staff list
    f.arrow([(155, 190), (155, 108)], stroke='--amber', width=1.6, dash='6 4')
    f.text(166, 140, T('vertical', 'vertical'), size=10, weight='600', anchor='start', fill='--amber')
    f.text(236, 140, T('role check: 403', 'papel: 403'), size=9.5, anchor='start', fill='--paper-dim')
    return f, T('Horizontal escalation reaches another customer\'s data; vertical escalation reaches a '
                'role. Each is a probe with two accounts.',
                'O escalonamento horizontal alcança os dados de outro cliente; o vertical alcança um '
                'papel. Cada um é uma sonda com duas contas.')


@figure('l17-session', 17)
def session():
    f = Fig('l17-session', 720, 230, T(
        'A session drawn as a bar along time. It starts at sign-in, when a random token is issued, '
        'and every request in between is accepted. It ends in one of two ways: at logout, when its '
        'row is deleted, or at expiry, 1800 seconds after sign-in. After the end, the same token is '
        'answered with 401. Below the bar, the database row holds the SHA-256 of the token, not the '
        'token, so a copy of the database opens nothing.',
        'Uma sessão desenhada como uma barra ao longo do tempo. Ela começa no login, quando um token '
        'aleatório é emitido, e toda requisição no meio é aceita. Termina de um de dois jeitos: no '
        'logout, quando a linha é apagada, ou na expiração, 1800 segundos depois do login. Depois do '
        'fim, o mesmo token recebe 401. Abaixo da barra, a linha do banco guarda o SHA-256 do token, '
        'e não o token, então uma cópia do banco não abre nada.'))
    f.text(360, 22, T('a token is a password with an end', 'um token é uma senha com fim'),
           size=11, weight='600', fill='--paper-dim')
    x0, xl, xe, x1 = 80, 430, 560, 690
    f.line(40, 120, x1, 120, stroke='--wire', width=1.1, arrow=True)
    f.rect(x0, 98, xe - x0, 44, stroke='--phosphor', fill='--scan', width=1.4)
    for x in (130, 190, 250, 310, 370):
        f.line(x, 104, x, 136, stroke='--phosphor', width=1.2)
    f.text(250, 84, T('every request accepted', 'toda requisição aceita'), size=10)
    f.text(x0, 160, T('sign-in', 'login'), size=10, weight='600')
    f.line(xl, 92, xl, 148, stroke='--amber', width=1.6, dash='5 4')
    f.text(xl, 160, T('logout', 'logout'), size=10, weight='600', fill='--amber')
    f.text(xl, 174, T('row deleted', 'linha apagada'), size=9.5, fill='--paper-dim')
    f.line(xe, 92, xe, 148, stroke='--amber', width=1.6)
    f.text(xe, 160, T('expiry', 'expiração'), size=10, weight='600', fill='--amber')
    f.text(xe, 174, T('1800 s after sign-in', '1800 s após o login'), size=9.5, fill='--paper-dim')
    f.text(626, 104, '401', size=10.5, weight='600', mono=True, fill='--amber')
    f.rect(80, 192, 330, 26, stroke='--wire', fill='--panel', width=1.1)
    f.text(245, 205, T('the database keeps sha256(token), not the token',
                       'o banco guarda sha256(token), e não o token'), size=9.5)
    return f, T('Whichever comes first ends the session: logout or expiry. Either way the token stops '
                'opening anything.',
                'O que vier primeiro encerra a sessão: logout ou expiração. Nos dois casos o token para '
                'de abrir qualquer coisa.')
