"""Lesson 17: route tables, NAT gateways, and one gateway per zone or one for all."""
from figures import Fig, T, figure


@figure('l17-packet-walk', 17)
def packet_walk():
    f = Fig('l17-packet-walk', 720, 430, T(
        'Three packets from a machine in app-a, read against the route table private-a. The table '
        'holds four routes: 10.20.0.0/16 to local, 192.168.0.0/16 to the virtual private gateway, '
        '0.0.0.0/0 to nat-a, and ::/0 to the egress-only internet gateway. The packet for '
        '10.20.97.10 matches the /16 and the /0; the /16 is longer, so it stays local and reaches '
        'data-a. The packet for 192.168.4.20 matches 192.168.0.0/16 and the /0; the /16 wins and '
        'it goes to the virtual private gateway, towards the office. The packet for 198.51.100.7 '
        'matches only the /0, so it goes to nat-a in public-a, and there the public route table '
        'sends 0.0.0.0/0 to the internet gateway and out to the internet.',
        'Três pacotes de uma máquina em app-a, lidos contra a tabela de rotas private-a. A tabela '
        'tem quatro rotas: 10.20.0.0/16 para local, 192.168.0.0/16 para o virtual private gateway, '
        '0.0.0.0/0 para nat-a, e ::/0 para o egress-only internet gateway. O pacote para '
        '10.20.97.10 casa com o /16 e com o /0; o /16 é mais longo, então ele fica local e chega a '
        'data-a. O pacote para 192.168.4.20 casa com 192.168.0.0/16 e com o /0; o /16 vence e ele '
        'vai para o virtual private gateway, rumo ao escritório. O pacote para 198.51.100.7 só casa '
        'com o /0, então vai para nat-a em public-a, e ali a tabela pública manda 0.0.0.0/0 para o '
        'internet gateway e para fora, à internet.'))
    # the machine and the table
    f.rect(20, 46, 160, 56, stroke='--wire', fill='--panel')
    f.text(100, 64, T('a machine in app-a', 'uma máquina em app-a'), size=10.5)
    f.text(100, 84, '10.20.48.10', size=10, mono=True, fill='--paper-dim')
    f.arrow([(182, 74), (236, 74)], stroke='--paper-dim', width=1.3)
    f.rect(240, 16, 300, 138, stroke='--paper-dim', fill='--panel')
    f.text(390, 34, T('route table private-a', 'tabela de rotas private-a'), size=10.5, weight='600')
    rows = [('10.20.0.0/16', 'local'), ('192.168.0.0/16', 'vgw'), ('0.0.0.0/0', 'nat-a'),
            ('::/0', 'eigw')]
    for i, (d, t) in enumerate(rows):
        y = 60 + i * 23
        f.text(262, y, d, size=10.5, anchor='start', mono=True)
        f.text(420, y, '→', size=10.5, mono=True, fill='--paper-dim')
        f.text(446, y, t, size=10.5, anchor='start', mono=True)
    f.text(630, 74, T('read three times,', 'lida três vezes,'), size=10, fill='--paper-dim',
           italic=True)
    f.text(630, 90, T('once per packet', 'uma por pacote'), size=10, fill='--paper-dim', italic=True)
    f.text(85, 190, T('packet for', 'pacote para'), size=10, weight='600', fill='--paper-dim')
    lanes = [(230, '10.20.97.10', '--phosphor', T('/16 beats /0', '/16 vence /0')),
             (310, '192.168.4.20', '--paper-dim', T('/16 beats /0', '/16 vence /0')),
             (390, '198.51.100.7', '--amber', T('only /0 matches', 'só /0 casa'))]
    for y, dest, c, why in lanes:
        f.rect(20, y - 18, 130, 36, stroke='--wire', fill='--panel')
        f.text(85, y, dest, size=10.5, mono=True)
        f.arrow([(152, y), (241, y)], stroke=c, width=1.4)
        f.text(197, y - 12, why, size=9.5, fill=c)
    # lane 1: local
    f.rect(245, 212, 150, 36, stroke='--phosphor', fill='--panel')
    f.text(320, 230, T('local: data-a', 'local: data-a'), size=10.5)
    # lane 2: the virtual private gateway, towards the office
    f.rect(245, 292, 150, 36, stroke='--paper-dim', fill='--panel')
    f.text(320, 310, T('virtual private gw', 'virtual private gw'), size=10.5)
    f.arrow([(397, 310), (496, 310)], stroke='--paper-dim', width=1.4)
    f.rect(500, 292, 200, 36, stroke='--paper-dim', fill='--panel', dash='4 3')
    f.text(600, 310, T('the office (lesson 24)', 'o escritório (lição 24)'), size=10.5)
    # lane 3: two hops
    f.rect(245, 372, 150, 36, stroke='--amber', fill='--panel', width=1.5)
    f.text(320, 390, T('nat-a in public-a', 'nat-a em public-a'), size=10.5)
    f.arrow([(397, 390), (496, 390)], stroke='--amber', width=1.4)
    f.text(446, 378, T('public: /0 → igw', 'public: /0 → igw'), size=9.5, fill='--amber')
    f.rect(500, 372, 70, 36, stroke='--amber', fill='--panel')
    f.text(535, 390, 'igw', size=10.5, mono=True)
    f.arrow([(572, 390), (606, 390)], stroke='--amber', width=1.4)
    f.rect(610, 372, 90, 36, stroke='--paper-dim', fill='--panel', rx=16)
    f.text(655, 390, T('internet', 'internet'), size=10.5, weight='600')
    return f, T('The longest prefix that contains the address wins. The third packet is routed twice: '
                'by private-a to the NAT gateway, then by public-a to the internet gateway.',
                'Vence o prefixo mais longo que contém o endereço. O terceiro pacote é roteado duas '
                'vezes: pela private-a até o NAT gateway, depois pela public-a até o internet gateway.')


def _panel(f, x0, shared):
    """Three zones, a public and a private subnet in each, and the way out."""
    f.rect(x0, 56, 330, 210, stroke='--paper-dim', fill='--ink', dash='6 4')
    xs = [x0 + 12, x0 + 120, x0 + 228]
    for k, x in enumerate(xs):
        z = 'abc'[k]
        f.rect(x, 70, 92, 184, stroke='--wire', fill='--scan')
        f.text(x + 46, 84, f'sa-east-1{z}', size=9.5, mono=True)
        f.rect(x + 8, 96, 76, 40, stroke='--wire', fill='--panel')
        f.text(x + 46, 116, f'app-{z}', size=10, mono=True)
        f.rect(x + 8, 196, 76, 46, stroke='--amber', fill='--panel', width=1.4)
        f.text(x + 46, 210, f'public-{z}', size=9.5, mono=True, fill='--amber')
        if not shared:
            f.rect(x + 20, 218, 52, 18, stroke='--phosphor', fill='--scan', rx=3)
            f.text(x + 46, 227, f'nat-{z}', size=9, mono=True)
        elif k == 0:
            # off centre, so the line coming in from the right has room
            f.rect(x + 12, 218, 52, 18, stroke='--phosphor', fill='--scan', rx=3)
            f.text(x + 38, 227, f'nat-{z}', size=9, mono=True)
        if not shared or k == 0:
            f.arrow([(x + 46, 138), (x + 46, 192)] if not shared else [(x + 38, 138), (x + 38, 192)],
                    stroke='--phosphor', width=1.4)
    if shared:
        # zone b and zone c reach nat-a along the corridor between the rows,
        # one piece per box crossed, so that no line runs through a box
        y = 166
        for k in (1, 2):
            x = xs[k]
            c = x + 46
            f.line(c, 138, c, y, stroke='--amber', width=1.4)
            f.line(c, y, x, y, stroke='--amber', width=1.4)
        f.line(xs[2], y, xs[1] + 92, y, stroke='--amber', width=1.4)
        f.line(xs[1] + 92, y, xs[1] + 46, y, stroke='--amber', width=1.4)
        f.line(xs[1], y, xs[0] + 92, y, stroke='--amber', width=1.4)
        f.line(xs[0] + 92, y, xs[0] + 78, y, stroke='--amber', width=1.4)
        f.line(xs[0] + 78, y, xs[0] + 78, 196, stroke='--amber', width=1.4)
        f.arrow([(xs[0] + 78, 196), (xs[0] + 78, 227), (xs[0] + 67, 227)], stroke='--amber',
                width=1.4)


@figure('l17-nat-choice', 17)
def nat_choice():
    f = Fig('l17-nat-choice', 720, 370, T(
        'Two ways to give the shop\'s private subnets a way out, drawn side by side across the '
        'three zones of sa-east-1. On the left, one NAT gateway per zone: app-a uses nat-a in '
        'public-a, app-b uses nat-b, app-c uses nat-c, and nothing crosses a zone. It costs 214.62 '
        'dollars a month before traffic, and losing zone a costs only zone a\'s way out. On the '
        'right, one shared NAT gateway, nat-a in public-a: app-b and app-c reach it across the '
        'zone boundaries, at 0.01 dollars per gigabyte each way. It costs 71.54 dollars a month '
        'plus the crossing, and losing zone a cuts zones b and c off from the internet too.',
        'Duas maneiras de dar uma saída às sub-redes privadas da loja, desenhadas lado a lado nas '
        'três zonas de sa-east-1. À esquerda, um NAT gateway por zona: app-a usa nat-a em '
        'public-a, app-b usa nat-b, app-c usa nat-c, e nada atravessa uma zona. Custa 214,62 '
        'dólares por mês antes do tráfego, e perder a zona a custa só a saída da zona a. À '
        'direita, um NAT gateway compartilhado, nat-a em public-a: app-b e app-c chegam a ele '
        'atravessando as fronteiras de zona, a 0,01 dólar por gigabyte em cada sentido. Custa '
        '71,54 dólares por mês mais a travessia, e perder a zona a corta as zonas b e c da '
        'internet também.'))
    f.text(195, 22, T('one per zone', 'um por zona'), size=11.5, weight='600')
    f.text(195, 40, T('214.62 a month', '214,62 por mês'), size=10.5, fill='--phosphor')
    f.text(535, 22, T('one shared', 'um compartilhado'), size=11.5, weight='600')
    f.text(535, 40, T('71.54 a month, plus 0.02 per GB crossing',
                      '71,54 por mês, mais 0,02 por GB que atravessa'), size=10.5, fill='--amber')
    _panel(f, 30, False)
    _panel(f, 370, True)
    f.text(535, 280, T('each crossing of a zone: 0.01 per GB each way',
                       'cada travessia de zona: 0,01 por GB em cada sentido'), size=9.5, fill='--amber')
    f.text(195, 300, T('zone a lost: zone a\'s machines', 'zona a perdida: as máquinas da zona a'),
           size=10, fill='--paper-dim')
    f.text(195, 316, T('lose the way out, and nobody else', 'perdem a saída, e mais ninguém'),
           size=10, fill='--paper-dim')
    f.text(535, 300, T('zone a lost: zones b and c lose', 'zona a perdida: as zonas b e c perdem'),
           size=10, fill='--amber')
    f.text(535, 316, T('the way out as well', 'a saída também'), size=10, fill='--amber')
    f.text(360, 352, T('NAT prices: EC2 offer of 25 September 2026; 730 hours a month, with one '
                       'Elastic IP each', 'preços de NAT: oferta EC2 de 25 de setembro de 2026; 730 '
                       'horas por mês, com um Elastic IP cada'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('Three gateways cost 143.08 dollars a month more than one. One gateway turns a zone\'s '
                'failure into everybody\'s.',
                'Três gateways custam 143,08 dólares por mês a mais que um. Um gateway só transforma a '
                'falha de uma zona na falha de todos.')
