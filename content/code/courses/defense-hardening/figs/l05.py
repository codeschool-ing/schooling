"""Lesson 5: blocking ports and removable devices."""
from figures import Fig, T, figure


@figure('l05-two-layers', 5)
def two_layers():
    f = Fig('l05-two-layers', 720, 290, T(
        'Packets from desk arrive at web and meet two layers. The first is the input chain of the '
        'firewall, with policy drop: port 80 is accepted for anybody, port 22 only from admin and '
        'jump, and everything else stops there. The second layer is the listeners on the machine. '
        'FTP, telnet and rpcbind are still listening behind the firewall, unreachable; lesson 1 '
        'removed them as well, so that neither layer depends on the other.',
        'Pacotes do desk chegam ao web e encontram duas camadas. A primeira é a chain de entrada do '
        'firewall, com policy drop: a porta 80 é aceita para qualquer um, a 22 só a partir do admin e '
        'do jump, e todo o resto para ali. A segunda camada são os listeners da máquina. FTP, telnet '
        'e rpcbind continuam escutando atrás do firewall, inalcançáveis; a aula 1 também os removeu, '
        'para que nenhuma camada dependa da outra.'))
    f.rect(20, 110, 110, 60, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(75, 140, 'desk', size=11, mono=True, weight='600')
    f.rect(190, 30, 170, 230, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(275, 50, T('input chain', 'chain de entrada'), size=10.5, weight='600')
    f.text(275, 68, 'policy drop', size=9.5, mono=True, fill='--paper-dim')
    rows = [('tcp 80', T('anybody', 'qualquer um'), '--phosphor'),
            ('tcp 22', T('admin, jump', 'admin, jump'), '--phosphor'),
            ('tcp 21', T('dropped', 'descartada'), '--amber'),
            ('tcp 23', T('dropped', 'descartada'), '--amber'),
            ('tcp 111', T('dropped', 'descartada'), '--amber')]
    for i, (p, w, c) in enumerate(rows):
        y = 90 + i * 32
        f.rect(205, y, 140, 24, stroke=c, fill='--scan', width=1.2, rx=2)
        f.text(213, y + 12, p, size=9.5, anchor='start', mono=True, fill=c)
        f.text(337, y + 12, w, size=9.5, anchor='end')
    f.line(130, 140, 190, 140, stroke='--paper-dim', width=1.4, arrow=True)
    f.rect(430, 30, 270, 230, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(565, 50, T('listeners on web', 'listeners no web'), size=10.5, weight='600')
    lst = [('nginx :80', '--phosphor'), ('sshd :22', '--phosphor'), ('vsftpd :21', '--amber'),
           ('inetd :23', '--amber'), ('rpcbind :111', '--amber')]
    for i, (n, c) in enumerate(lst):
        y = 90 + i * 32
        f.rect(445, y, 240, 24, stroke=c, fill='--scan', width=1.2, rx=2)
        f.text(457, y + 12, n, size=9.5, anchor='start', mono=True, fill=c)
    f.line(345, 102, 445, 102, stroke='--phosphor', width=1.2, arrow=True)
    f.line(345, 134, 445, 134, stroke='--phosphor', width=1.2, arrow=True)
    f.text(565, 252, T('still listening, unreachable', 'ainda escutando, inalcançáveis'), size=9.5, fill='--amber')
    return f, T('The filter hides what is still running. Removing it, as lesson 1 did, is the other layer.',
                'O filtro esconde o que continua rodando. Removê-lo, como a aula 1 fez, é a outra camada.')


@figure('l05-drop-reject', 5)
def drop_reject():
    f = Fig('l05-drop-reject', 720, 250, T(
        'The same connection attempt to port 21, answered two ways, on a time line. With drop, desk '
        'sends a connection request, hears nothing, sends it again after a second and gives up '
        'when its own three-second timeout runs out. With reject, desk sends one request, web '
        'answers at once with port unreachable, and desk reports connection refused within '
        'milliseconds.',
        'A mesma tentativa de conexão na porta 21, respondida de dois jeitos, numa linha do tempo. '
        'Com drop, o desk manda um pedido de conexão, não ouve nada, manda de novo depois de um '
        'segundo e desiste quando acaba o próprio tempo limite de três segundos. Com reject, o desk '
        'manda um pedido, o web responde na hora com porta inalcançável, e o desk informa conexão '
        'recusada em milissegundos.'))
    x0, x3 = 120, 680
    for y, lab in [(80, 'drop'), (180, 'reject')]:
        f.text(20, y, lab, size=11, anchor='start', mono=True, weight='600')
        f.line(x0, y, x3, y, stroke='--wire', width=1.2)
    for s in range(4):
        x = x0 + s * (x3 - x0) / 3
        f.line(x, 205, x, 212, stroke='--paper-dim', width=1)
        f.text(x, 226, f'{s} s', size=9.5, fill='--paper-dim')
    for s in (0, 1):
        x = x0 + s * (x3 - x0) / 3
        f.line(x, 80, x, 55, stroke='--paper-dim', width=1.3, arrow=True)
        f.text(x + 4, 48, 'SYN', size=9, anchor='start', mono=True)
    f.text(x3 - 4, 60, T('timed out', 'tempo esgotado'), size=10, anchor='end', fill='--amber')
    f.text((x0 + x3) / 2 + 60, 100, T('silence', 'silêncio'), size=9.5, fill='--paper-dim')
    f.line(x0, 180, x0, 155, stroke='--paper-dim', width=1.3, arrow=True)
    f.text(x0 + 4, 148, 'SYN', size=9, anchor='start', mono=True)
    f.line(x0 + 14, 150, x0 + 14, 175, stroke='--phosphor', width=1.3, arrow=True)
    f.text(x0 + 24, 166, T('port unreachable: refused at once', 'porta inalcançável: recusada na hora'),
           size=10, anchor='start', fill='--phosphor')
    return f, T('Drop makes the client wait out its own timeout. Reject answers it.',
                'O drop faz o cliente esperar o próprio tempo limite. O reject responde.')
