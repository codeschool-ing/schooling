"""Lesson 24: the two tunnels of a VPN, and the doubled roads in from the office."""
from figures import Fig, T, figure


@figure('l24-tunnels', 24)
def tunnels():
    f = Fig('l24-tunnels', 720, 330, T(
        'A Site-to-Site VPN. On the left, the office, 192.168.0.0/16, with its router at the public '
        'address 203.0.113.12, BGP AS 65000. In the middle, the internet. On the right, the region '
        'sa-east-1, where AWS runs two tunnel endpoints on separate equipment, and behind them the '
        'virtual private gateway, AS 64512, attached to the VPC 10.20.0.0/16. Two tunnels join the '
        'router to the two endpoints, each with its own BGP session. When AWS maintains one endpoint, '
        'the routes learnt over that tunnel are withdrawn and the other tunnel carries the traffic.',
        'Uma VPN Site-to-Site. À esquerda, o escritório, 192.168.0.0/16, com o roteador no endereço '
        'público 203.0.113.12, AS BGP 65000. No meio, a internet. À direita, a região sa-east-1, onde a '
        'AWS roda duas pontas de túnel em equipamentos separados, e atrás delas o virtual private '
        'gateway, AS 64512, preso à VPC 10.20.0.0/16. Dois túneis ligam o roteador às duas pontas, cada '
        'um com a sua sessão BGP. Quando a AWS faz manutenção numa ponta, as rotas aprendidas por aquele '
        'túnel são retiradas e o outro túnel carrega o tráfego.'))
    # the office
    f.rect(20, 50, 170, 220, stroke='--wire', fill='--scan')
    f.text(105, 70, T('the office', 'o escritório'), size=11, weight='600')
    f.text(105, 88, '192.168.0.0/16', size=10, mono=True, fill='--paper-dim')
    f.rect(45, 130, 120, 60, stroke='--paper-dim', fill='--panel')
    f.text(105, 150, T('router', 'roteador'), size=10.5, weight='600')
    f.text(105, 168, '203.0.113.12', size=9.5, mono=True, fill='--paper-dim')
    f.text(105, 216, 'AS 65000', size=10, mono=True, fill='--paper-dim')
    # the internet
    f.rect(240, 120, 120, 80, stroke='--paper-dim', fill='--panel', rx=36)
    f.text(300, 160, T('the internet', 'a internet'), size=10.5, weight='600')
    # the region
    f.rect(410, 30, 290, 260, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(424, 48, 'sa-east-1', size=11, mono=True, anchor='start', fill='--paper-dim')
    ends = [(95, T('tunnel endpoint 1', 'ponta do túnel 1')), (225, T('tunnel endpoint 2', 'ponta do túnel 2'))]
    for y, label in ends:
        f.rect(430, y - 22, 120, 44, stroke='--phosphor', fill='--panel')
        f.text(490, y - 5, label, size=9.5, weight='600')
        f.text(490, y + 11, T('separate equipment', 'equipamento separado'), size=8.5,
               fill='--paper-dim')
    f.rect(580, 100, 110, 120, stroke='--phosphor', fill='--scan', width=1.5)
    f.text(635, 128, T('virtual', 'virtual'), size=10, weight='600')
    f.text(635, 142, T('private gateway', 'private gateway'), size=10, weight='600')
    f.text(635, 160, 'AS 64512', size=9.5, mono=True, fill='--paper-dim')
    f.text(635, 186, T('attached to', 'presa à'), size=9, fill='--paper-dim')
    f.text(635, 202, '10.20.0.0/16', size=9.5, mono=True)
    f.line(552, 95, 578, 130, stroke='--phosphor', width=1.2)
    f.line(552, 225, 578, 190, stroke='--phosphor', width=1.2)
    # the two tunnels, each in two pieces around the internet's edge
    f.line(167, 150, 260, 138, stroke='--amber', width=2.0)
    f.line(340, 132, 428, 100, stroke='--amber', width=2.0)
    f.line(167, 170, 260, 182, stroke='--amber', width=2.0, dash='6 4')
    f.line(340, 188, 428, 222, stroke='--amber', width=2.0, dash='6 4')
    f.text(212, 128, T('tunnel 1', 'túnel 1'), size=9.5, fill='--amber', weight='600')
    f.text(212, 194, T('tunnel 2', 'túnel 2'), size=9.5, fill='--amber', weight='600')
    f.text(360, 312, T('two tunnels, two BGP sessions: maintenance on one end moves the routes to the other',
                       'dois túneis, duas sessões BGP: manutenção numa ponta move as rotas para a outra'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('A VPN connection is always two tunnels. A design that keeps one of them down loses the '
                'office during AWS\'s maintenance.',
                'Uma conexão VPN são sempre dois túneis. Um projeto que deixa um deles desligado perde o '
                'escritório durante a manutenção da AWS.')


@figure('l24-resilience', 24)
def resilience():
    f = Fig('l24-resilience', 720, 340, T(
        'Two ways to double the road from the office to the VPC. The office router has a Direct '
        'Connect connection to the location Equinix SP4, code TNDB, and from there a private virtual '
        'interface to the virtual private gateway of the VPC in sa-east-1. Drawn dashed, the second '
        'road: either a second Direct Connect connection at the location Tivit, which survives a whole '
        'building going dark, or a Site-to-Site VPN over the internet, the cheaper backup. With BGP on '
        'both, AWS prefers the Direct Connect path while it is up.',
        'Dois jeitos de dobrar o caminho do escritório até a VPC. O roteador do escritório tem uma '
        'conexão Direct Connect até o local Equinix SP4, código TNDB, e dali uma interface virtual '
        'privada até o virtual private gateway da VPC em sa-east-1. Tracejado, o segundo caminho: ou uma '
        'segunda conexão Direct Connect no local Tivit, que sobrevive a um prédio inteiro apagar, ou '
        'uma VPN Site-to-Site pela internet, o reserva mais barato. Com BGP nos dois, a AWS prefere o '
        'caminho do Direct Connect enquanto ele está de pé.'))
    f.rect(20, 110, 140, 110, stroke='--wire', fill='--scan')
    f.text(90, 140, T('the office', 'o escritório'), size=11, weight='600')
    f.text(90, 160, T('router', 'roteador'), size=10, fill='--paper-dim')
    f.text(90, 180, 'AS 65000', size=9.5, mono=True, fill='--paper-dim')
    locs = [(70, 'Equinix SP4', 'TNDB', False), (170, 'Tivit', 'TIVIT', True)]
    for y, name, code, dashed in locs:
        f.rect(250, y - 30, 160, 60, stroke='--paper-dim', fill='--panel', dash='4 3' if dashed else None)
        f.text(330, y - 9, name, size=10.5, weight='600')
        f.text(330, y + 11, T('location ', 'local ') + code, size=9.5, fill='--paper-dim')
    f.rect(250, 250, 160, 50, stroke='--paper-dim', fill='--panel', rx=24, dash='4 3')
    f.text(330, 275, T('the internet', 'a internet'), size=10.5, weight='600')
    # the region
    f.rect(480, 30, 220, 280, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(494, 48, 'sa-east-1', size=11, mono=True, anchor='start', fill='--paper-dim')
    f.rect(520, 120, 150, 90, stroke='--phosphor', fill='--scan', width=1.5)
    f.text(595, 150, T('virtual private', 'virtual private'), size=10, weight='600')
    f.text(595, 165, T('gateway', 'gateway'), size=10, weight='600')
    f.text(595, 188, '10.20.0.0/16', size=9.5, mono=True)
    # the primary path
    f.line(162, 140, 246, 80, stroke='--phosphor', width=2.2)
    f.arrow([(412, 75), (516, 140)], stroke='--phosphor', width=2.2)
    f.text(200, 96, T('Direct Connect', 'Direct Connect'), size=9.5, fill='--phosphor', weight='600',
           anchor='end')
    f.text(444, 118, T('private VIF', 'VIF privada'), size=9.5, fill='--phosphor', anchor='middle')
    # the second DX
    f.line(162, 170, 246, 170, stroke='--amber', width=1.6, dash='6 4')
    f.arrow([(412, 170), (516, 168)], stroke='--amber', width=1.6, dash='6 4')
    f.text(205, 160, T('or a second', 'ou uma segunda'), size=9, fill='--amber')
    # the VPN
    f.line(162, 200, 246, 268, stroke='--amber', width=1.6, dash='2 3')
    f.arrow([(412, 270), (516, 200)], stroke='--amber', width=1.6, dash='2 3')
    f.text(195, 258, T('or a VPN', 'ou uma VPN'), size=9, fill='--amber', anchor='end')
    f.text(360, 330, T('with BGP on both, AWS prefers Direct Connect while it is up',
                       'com BGP nos dois, a AWS prefere o Direct Connect enquanto ele está de pé'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('One connection is one building and one fibre. The second road is either another '
                'building or the internet.',
                'Uma conexão é um prédio e uma fibra. O segundo caminho é outro prédio ou a internet.')
