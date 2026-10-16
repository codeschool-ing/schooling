"""Lesson 17: the actor model."""
from figures import Fig, T, figure


@figure('l17-anatomy', 17)
def anatomy():
    f = Fig('l17-anatomy', 700, 250, T(
        'An actor and the code that talks to it. On the left, three senders, the north desk, the '
        'south desk and the website, each send a message with tell, which returns at once. The '
        'messages wait in the mailbox, a queue drawn as three slots: GiveBack, Lend and Lend, with '
        'the oldest on the right, next to be handled. The mailbox, the behaviour receive and the '
        'private state, a dictionary of copies, are inside one dashed boundary, the shelf actor. '
        'One message at a time goes from the mailbox to receive, which alone reads and writes the '
        'state. Nothing outside the boundary can reach the state.',
        'Um ator e o código que fala com ele. À esquerda, três remetentes, o balcão norte, o balcão '
        'sul e o site, mandam cada um uma mensagem com tell, que retorna na hora. As mensagens '
        'esperam na caixa de correio, uma fila desenhada como três espaços: GiveBack, Lend e Lend, '
        'com a mais antiga à direita, a próxima a ser tratada. A caixa de correio, o comportamento '
        'receive e o estado privado, um dicionário de exemplares, ficam dentro de uma fronteira '
        'tracejada, o ator da estante. Uma mensagem de cada vez vai da caixa de correio para o '
        'receive, que é o único a ler e escrever o estado. Nada fora da fronteira alcança o estado.'))
    senders = [(60, T('north desk', 'balcão norte')), (125, T('south desk', 'balcão sul')),
               (190, T('website', 'site'))]
    for y, name in senders:
        f.box(80, y, 120, 30, [name], size=10)
        f.arrow([(140, y), (205, 130 + (y - 125) * 0.25), (240, 130)], stroke='--paper-dim')
    f.text(80, 230, T('tell returns at once', 'tell retorna na hora'), size=9.5, fill='--paper-dim', italic=True)
    f.rect(225, 25, 460, 210, stroke='--phosphor', fill='--ink', width=1.2, rx=6, dash='5 4')
    f.text(240, 42, T('the shelf actor', 'o ator da estante'), size=10.5, anchor='start', weight='600')
    f.text(345, 92, T('mailbox', 'caixa de correio'), size=10, fill='--paper-dim')
    for i, m in enumerate(['GiveBack', 'Lend', 'Lend']):
        f.rect(250 + i * 66, 117, 60, 26, stroke='--paper-dim', fill='--panel', width=1.2, rx=2)
        f.text(280 + i * 66, 130, m, size=9.5, mono=True)
    f.text(412, 158, T('next', 'próxima'), size=9, fill='--amber', italic=True)
    f.arrow([(448, 130), (520, 100)], stroke='--paper')
    f.text(480, 190, T('one at a time', 'uma de cada vez'), size=9.5, fill='--amber', italic=True)
    f.rect(520, 72, 150, 44, stroke='--phosphor', fill='--panel', width=1.4, rx=3)
    f.text(595, 94, 'receive(message)', size=10, mono=True)
    f.rect(520, 150, 150, 50, stroke='--phosphor', fill='--panel', width=1.4, rx=3)
    f.text(595, 166, '_copies', size=10, mono=True, weight='600')
    f.text(595, 184, "{'Iracema': 1}", size=9.5, mono=True)
    f.arrow([(595, 116), (595, 150)], stroke='--paper-dim', start=True)
    f.text(595, 220, T('private: no reference outside', 'privado: nenhuma referência fora'), size=9, fill='--paper-dim', italic=True)
    return f, T('Senders only ever reach the mailbox. Behind it, one piece of code handles one message at a time and is the only one that touches the state.',
                'Os remetentes só alcançam a caixa de correio. Atrás dela, um único trecho de código trata uma mensagem de cada vez e é o único que toca o estado.')


@figure('l17-restarts', 17)
def restarts():
    f = Fig('l17-restarts', 720, 230, T(
        'A timeline of supervision.py. Six messages arrive left to right: Lend Iracema, GiveBack '
        'Macunaíma, Lend Iracema, GiveBack O Cortiço, GiveBack Macunaíma, Lend Vidas Secas. Below '
        'them, the life of each shelf instance is a bar. Shelf 1 handles the first message and '
        'crashes on the second; restart 1 starts shelf 2, which handles the third and crashes on '
        'the fourth; restart 2 starts shelf 3, which crashes on the fifth, and the supervisor gives '
        'up, so the sixth is not handled. Underneath, the copies of Iracema after each loan: 1 after '
        'the first, and 1 again after the second, because the fresh shelf forgot the first loan.',
        'Uma linha do tempo de supervision.py. Seis mensagens chegam da esquerda para a direita: Lend '
        'Iracema, GiveBack Macunaíma, Lend Iracema, GiveBack O Cortiço, GiveBack Macunaíma, Lend Vidas '
        'Secas. Abaixo, a vida de cada instância da estante é uma barra. A estante 1 trata a primeira '
        'mensagem e cai na segunda; o reinício 1 cria a estante 2, que trata a terceira e cai na '
        'quarta; o reinício 2 cria a estante 3, que cai na quinta, e o supervisor desiste, então a '
        'sexta não é tratada. Embaixo, os exemplares de Iracema depois de cada empréstimo: 1 depois '
        'do primeiro, e 1 de novo depois do segundo, porque a estante nova esqueceu o primeiro '
        'empréstimo.'))
    xs = [190, 285, 380, 475, 570, 665]
    msgs = [('Lend', 'Iracema'), ('GiveBack', 'Macunaíma'), ('Lend', 'Iracema'),
            ('GiveBack', 'O Cortiço'), ('GiveBack', 'Macunaíma'), ('Lend', 'Vidas Secas')]
    f.text(10, 34, T('message', 'mensagem'), size=10, anchor='start', weight='600')
    f.text(10, 110, T('instance', 'instância'), size=10, anchor='start', weight='600')
    f.text(10, 185, T('Iracema', 'Iracema'), size=10, anchor='start', weight='600')
    for x, (a, b) in zip(xs, msgs):
        f.lines(x, 34, [a, b], size=9, mono=True)
        f.line(x, 56, x, 66, stroke='--paper-dim', width=1)
    bars = [(140, 285, T('shelf 1', 'estante 1')), (285, 475, T('shelf 2', 'estante 2')),
            (475, 570, T('shelf 3', 'estante 3'))]
    for x1, x2, name in bars:
        f.rect(x1, 98, x2 - x1, 24, stroke='--phosphor', fill='--panel', width=1.4, rx=2)
        f.text((x1 + x2) / 2, 110, name, size=9.5)
    f.rect(570, 98, 140, 24, stroke='--paper-dim', fill='--ink', width=1, rx=2, dash='4 3')
    f.text(640, 110, T('down', 'fora do ar'), size=9.5, fill='--paper-dim')
    for x in (285, 475, 570):
        f.text(x, 84, T('crash', 'queda'), size=9, fill='--amber', italic=True)
    f.text(285, 140, T('restart 1', 'reinício 1'), size=9, fill='--paper-dim')
    f.text(475, 140, T('restart 2', 'reinício 2'), size=9, fill='--paper-dim')
    f.text(570, 140, T('gives up', 'desiste'), size=9, fill='--amber')
    f.text(665, 140, T('refused', 'recusada'), size=9, fill='--paper-dim')
    f.text(190, 185, '1', size=11, mono=True, weight='600')
    f.text(380, 185, '1', size=11, mono=True, weight='600', fill='--amber')
    f.text(380, 210, T('not 0: the first loan was forgotten', 'não 0: o primeiro empréstimo foi esquecido'),
           size=9.5, fill='--amber', italic=True)
    return f, T('Each restart starts from the catalogue. The supervisor restarts the shelf twice and gives up at the third crash, and the second loan shows the price: the fresh shelf knows nothing of the first.',
                'Cada reinício parte do catálogo. O supervisor reinicia a estante duas vezes e desiste na terceira queda, e o segundo empréstimo mostra o preço: a estante nova não sabe nada do primeiro.')
