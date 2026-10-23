"""Lesson 1: operating system hardening."""
from figures import Fig, T, figure


def machine(f, x, y, w, h, name, sub=None, stroke='--wire'):
    f.rect(x, y, w, h, stroke=stroke, fill='--panel', width=1.5, rx=3)
    f.text(x + 12, y + 18, name, size=12, anchor='start', mono=True, weight='600')
    if sub:
        f.text(x + 12, y + 36, sub, size=9.5, anchor='start', fill='--paper-dim')


@figure('l01-surface', 1)
def surface():
    f = Fig('l01-surface', 720, 300, T(
        'The portal server web drawn twice. On the left, as it was handed over: eight listeners on '
        'its edge, TCP 21 ftp, 22 ssh, 23 telnet, 80 http and 111 rpcbind, and UDP 111 rpcbind, '
        '161 snmp and 5353 mdns. Six of them are marked as not needed by the job. On the '
        'right, after the lesson: only TCP 22 ssh and TCP 80 http, and the portal '
        'itself on 127.0.0.1:8080 inside the box, reachable only from the machine.',
        'O servidor do portal, web, desenhado duas vezes. À esquerda, como foi entregue: oito '
        'listeners na borda, TCP 21 ftp, 22 ssh, 23 telnet, 80 http e 111 rpcbind, e UDP 111 '
        'rpcbind, 161 snmp e 5353 mdns. Seis deles marcados como desnecessários para o trabalho. À '
        'direita, depois da aula: só TCP 22 ssh e TCP 80 http, e o próprio '
        'portal em 127.0.0.1:8080 dentro da caixa, alcançável só a partir da máquina.'))
    f.text(180, 22, T('as handed over', 'como foi entregue'), size=11, weight='600', fill='--paper-dim')
    f.text(540, 22, T('after lesson 1', 'depois da aula 1'), size=11, weight='600', fill='--paper-dim')
    before = [('tcp 21', 'ftp', 0), ('tcp 22', 'ssh', 1), ('tcp 23', 'telnet', 0), ('tcp 80', 'http', 1),
              ('tcp 111', 'rpcbind', 0), ('udp 111', 'rpcbind', 0), ('udp 161', 'snmp', 0),
              ('udp 5353', 'mdns', 0)]
    machine(f, 40, 50, 150, 220, 'web')
    f.text(52, 252, '127.0.0.1:8080', size=9.5, anchor='start', mono=True, fill='--paper-dim')
    for i, (port, name, keep) in enumerate(before):
        y = 60 + i * 25
        c = '--phosphor' if keep else '--amber'
        f.rect(190, y, 130, 21, stroke=c, fill='--scan', width=1.2, rx=2)
        f.text(198, y + 10.5, port, size=9.5, anchor='start', mono=True, fill=c)
        f.text(312, y + 10.5, name, size=9.5, anchor='end', mono=True)
    machine(f, 400, 50, 150, 220, 'web')
    f.text(412, 252, '127.0.0.1:8080', size=9.5, anchor='start', mono=True, fill='--paper-dim')
    for i, (port, name) in enumerate([('tcp 22', 'ssh'), ('tcp 80', 'http')]):
        y = 85 + i * 50
        f.rect(550, y, 130, 21, stroke='--phosphor', fill='--scan', width=1.2, rx=2)
        f.text(558, y + 10.5, port, size=9.5, anchor='start', mono=True, fill='--phosphor')
        f.text(672, y + 10.5, name, size=9.5, anchor='end', mono=True)
    f.text(615, 210, T('the job, and nothing else', 'o trabalho, e mais nada'), size=10, fill='--phosphor')
    f.rect(250, 280, 22, 12, stroke='--amber', fill='--scan', width=1.2, rx=2)
    f.text(280, 286, T('a listener the job does not need', 'um listener de que o trabalho não precisa'),
           size=9.5, anchor='start', fill='--amber')
    return f, T('Eight listeners where the job needs two. Every marked tab is a program a stranger can talk to.',
                'Oito listeners onde o trabalho precisa de dois. Cada aba marcada é um programa com que um estranho conversa.')


@figure('l01-socket', 1)
def socket():
    f = Fig('l01-socket', 720, 260, T(
        'Socket activation in three steps. One: systemd, process 1, listens on port 111 on behalf of '
        'rpcbind.socket, while rpcbind.service is not running. Two: a client connects to port 111. '
        'Three: systemd starts rpcbind.service and hands it the socket. Disabling only the service '
        'leaves step one in place, so the next client starts it again.',
        'Ativação por socket em três passos. Um: o systemd, processo 1, escuta na porta 111 em nome '
        'do rpcbind.socket, enquanto o rpcbind.service não está rodando. Dois: um cliente conecta na '
        'porta 111. Três: o systemd inicia o rpcbind.service e entrega o socket a ele. Desabilitar só '
        'o serviço deixa o passo um no lugar, então o próximo cliente o inicia de novo.'))
    f.rect(250, 40, 220, 60, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(360, 60, 'systemd (pid 1)', size=11, mono=True, weight='600')
    f.text(360, 82, T('listens on :111 for rpcbind.socket', 'escuta na :111 pelo rpcbind.socket'), size=9.5,
           fill='--paper-dim')
    f.rect(250, 170, 220, 50, stroke='--amber', fill='--panel', width=1.5, rx=3, dash='5 3')
    f.text(360, 190, 'rpcbind.service', size=11, mono=True, weight='600')
    f.text(360, 207, T('disabled, not running', 'desabilitado, parado'), size=9.5, fill='--paper-dim')
    f.rect(30, 50, 130, 40, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(95, 70, T('a client', 'um cliente'), size=10.5)
    f.line(160, 70, 250, 70, stroke='--paper-dim', width=1.4, arrow=True)
    f.text(205, 58, T('2 connects', '2 conecta'), size=9.5, fill='--paper-dim')
    f.line(360, 100, 360, 170, stroke='--amber', width=1.4, arrow=True)
    f.text(372, 128, T('3 starts it again,', '3 inicia de novo,'), size=9.5, anchor='start', fill='--amber')
    f.text(372, 143, T('and hands over the socket', 'e entrega o socket'), size=9.5, anchor='start', fill='--amber')
    f.text(500, 62, T('1 still enabled:', '1 ainda habilitado:'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(500, 78, 'rpcbind.socket', size=9.5, anchor='start', mono=True)
    return f, T('Disabling the service left systemd holding the port. The socket has to go too.',
                'Desabilitar o serviço deixou o systemd segurando a porta. O socket tem de sair também.')
