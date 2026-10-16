"""Lesson 22: the three load balancers, and cross-zone load balancing."""
from figures import Fig, T, figure


@figure('l22-three-kinds', 22)
def three_kinds():
    f = Fig('l22-three-kinds', 720, 380, T(
        'The three load balancers side by side. On the left, the application load balancer, layer 7: '
        'it reads the host, the path and the headers of each request, and sends /api/* to the shop-api '
        'target group and everything else to shop-web-app. In the middle, the network load balancer, '
        'layer 4: it passes TCP, UDP and TLS connections from one fixed address per zone to one target '
        'group, and the target sees the caller\'s own address. On the right, the gateway load '
        'balancer, layer 3: traffic entering the VPC goes to a GWLB endpoint, the gateway load '
        'balancer sends each packet wrapped in GENEVE on port 6081 to a firewall appliance, and takes '
        'it back to continue to its destination.',
        'Os três balanceadores lado a lado. À esquerda, o application load balancer, camada 7: ele lê '
        'o host, o caminho e os cabeçalhos de cada requisição, e manda /api/* para o grupo de alvos '
        'shop-api e todo o resto para shop-web-app. No meio, o network load balancer, camada 4: ele '
        'repassa conexões TCP, UDP e TLS a partir de um endereço fixo por zona para um grupo de alvos, '
        'e o alvo vê o endereço do próprio chamador. À direita, o gateway load balancer, camada 3: o '
        'tráfego que entra na VPC vai para um endpoint de GWLB, o gateway load balancer manda cada '
        'pacote embrulhado em GENEVE na porta 6081 para um appliance de firewall, e o recebe de volta '
        'para seguir ao destino.'))
    cols = [120, 360, 600]
    heads = [(T('application', 'application'), T('layer 7', 'camada 7')),
             (T('network', 'network'), T('layer 4', 'camada 4')),
             (T('gateway', 'gateway'), T('layer 3', 'camada 3'))]
    callers = [T('a customer, over HTTPS', 'um cliente, por HTTPS'),
               T("a partner's terminal, raw TCP", 'o terminal de um parceiro, TCP puro'),
               T('traffic entering the VPC', 'o tráfego que entra na VPC')]
    reads = [T('reads host, path, headers', 'lê host, caminho, cabeçalhos'),
             T('reads addresses and ports', 'lê endereços e portas'),
             T('reads nothing, all ports', 'não lê nada, todas as portas')]
    for x, (name, layer), caller, read in zip(cols, heads, callers, reads):
        f.rect(x - 100, 20, 200, 34, stroke='--paper-dim', fill='--panel', rx=17)
        f.text(x, 37, caller, size=10)
        f.rect(x - 100, 92, 200, 66, stroke='--phosphor', fill='--scan', width=1.5)
        f.text(x, 110, name, size=12, weight='600')
        f.text(x, 128, layer, size=10, fill='--amber', weight='600')
        f.text(x, 145, read, size=9.5, fill='--paper-dim')
    # ALB: caller straight down; two target groups chosen by rule
    f.line(120, 56, 120, 88, stroke='--paper-dim', width=1.3, arrow=True)
    f.rect(25, 230, 90, 56, stroke='--wire', fill='--panel')
    f.text(70, 250, 'shop-api', size=10, mono=True)
    f.text(70, 268, T('target group', 'grupo de alvos'), size=9, fill='--paper-dim')
    f.rect(125, 230, 110, 56, stroke='--wire', fill='--panel')
    f.text(180, 250, 'shop-web-app', size=10, mono=True)
    f.text(180, 268, T('target group', 'grupo de alvos'), size=9, fill='--paper-dim')
    f.arrow([(95, 160), (72, 226)], stroke='--amber', width=1.3)
    f.arrow([(145, 160), (176, 226)], stroke='--phosphor', width=1.3)
    f.text(60, 190, '/api/*', size=9.5, mono=True, fill='--amber', anchor='end')
    f.text(170, 190, T('default', 'padrão'), size=9.5, fill='--phosphor', anchor='start')
    f.text(120, 312, T('rules choose the group', 'regras escolhem o grupo'), size=9.5,
           fill='--paper-dim', italic=True)
    # NLB: one fixed address per zone, one group, caller's address kept
    f.line(360, 56, 360, 88, stroke='--paper-dim', width=1.3, arrow=True)
    f.text(372, 74, T('one fixed IP per zone', 'um IP fixo por zona'), size=9, fill='--paper-dim',
           anchor='start')
    f.rect(300, 230, 120, 56, stroke='--wire', fill='--panel')
    f.text(360, 250, 'shop-tcp', size=10, mono=True)
    f.text(360, 268, T('target group', 'grupo de alvos'), size=9, fill='--paper-dim')
    f.line(360, 160, 360, 226, stroke='--phosphor', width=1.3, arrow=True)
    f.text(360, 312, T("the target sees the caller's IP", 'o alvo vê o IP de quem chamou'), size=9.5,
           fill='--paper-dim', italic=True)
    # GWLB: endpoint, appliance, and back
    f.rect(520, 64, 160, 22, stroke='--amber', fill='--ink', dash='3 3')
    f.text(600, 75, T('GWLB endpoint', 'endpoint de GWLB'), size=9, fill='--amber')
    f.line(600, 56, 600, 62, stroke='--paper-dim', width=1.3)
    f.line(600, 87, 600, 89, stroke='--paper-dim', width=1.3, arrow=True)
    f.rect(540, 230, 120, 56, stroke='--wire', fill='--panel')
    f.text(600, 250, T('firewall', 'firewall'), size=10, weight='600')
    f.text(600, 268, T('appliances', 'appliances'), size=9, fill='--paper-dim')
    f.arrow([(580, 160), (580, 226)], stroke='--amber', width=1.3)
    f.arrow([(620, 226), (620, 160)], stroke='--phosphor', width=1.3)
    f.text(574, 194, 'GENEVE', size=9, mono=True, fill='--amber', anchor='end')
    f.text(574, 207, '6081', size=9, mono=True, fill='--amber', anchor='end')
    f.text(628, 194, T('back', 'volta'), size=9.5, fill='--phosphor', anchor='start')
    f.text(600, 312, T('then on to its destination', 'depois segue ao destino'), size=9.5,
           fill='--paper-dim', italic=True)
    f.text(360, 340, T('the more a load balancer reads, the more it can decide',
                       'quanto mais um balanceador lê, mais ele pode decidir'),
           size=10.5, fill='--amber')
    f.text(360, 362, T('and the more of the request it has to understand',
                       'e mais da requisição ele tem de entender'),
           size=10, fill='--paper-dim')
    return f, T('Three products under one API. The question is how much of the traffic the thing in '
                'front of the machines needs to read.',
                'Três produtos sob uma API. A pergunta é quanto do tráfego a coisa na frente das '
                'máquinas precisa ler.')


@figure('l22-cross-zone', 22)
def cross_zone():
    f = Fig('l22-cross-zone', 720, 330, T(
        'Cross-zone load balancing, with two targets in sa-east-1a and eight in sa-east-1b. Each zone '
        'has a load balancer node, and each node receives half the traffic. On the left, cross-zone '
        'off: each node sends only to its own zone, so the two targets in sa-east-1a carry 25% each '
        'and the eight in sa-east-1b 6.25% each. On the right, cross-zone on: each node sends to every '
        'target, and all ten carry 10% each.',
        'Balanceamento entre zonas, com dois alvos em sa-east-1a e oito em sa-east-1b. Cada zona tem um '
        'nó do balanceador, e cada nó recebe metade do tráfego. À esquerda, entre zonas desligado: cada '
        'nó manda só para a própria zona, então os dois alvos em sa-east-1a carregam 25% cada e os oito '
        'em sa-east-1b 6,25% cada. À direita, entre zonas ligado: cada nó manda para todo alvo, e os dez '
        'carregam 10% cada.'))
    panels = [(20, T('cross-zone off', 'entre zonas desligado'), False),
              (370, T('cross-zone on', 'entre zonas ligado'), True)]
    for x0, title, on in panels:
        f.text(x0 + 165, 22, title, size=11.5, weight='600', fill='--amber' if not on else '--phosphor')
        for zx, zone, n in ((x0, 'sa-east-1a', 2), (x0 + 130, 'sa-east-1b', 8)):
            w = 110 if n == 2 else 200
            if n == 8:
                zx = x0 + 130
            f.rect(zx, 44, w, 236, stroke='--wire', fill='--scan')
            f.text(zx + w / 2, 60, zone, size=10, mono=True, fill='--paper-dim')
            # the node
            f.rect(zx + w / 2 - 34, 76, 68, 28, stroke='--phosphor', fill='--panel')
            f.text(zx + w / 2, 90, T('node: 50%', 'nó: 50%'), size=9.5)
            # targets
            per = '10%' if on else ('25%' if n == 2 else '6.25%')
            per = per if T('a', 'b') == 'a' else per.replace('.', ',')
            cols = 2 if n == 2 else 4
            for i in range(n):
                r, c = divmod(i, cols)
                tx = zx + (w - cols * 40 - (cols - 1) * 8) / 2 + c * 48
                ty = 170 + r * 52
                f.rect(tx, ty, 40, 36, stroke='--paper-dim', fill='--panel')
                f.text(tx + 20, ty + 18, per, size=9, fill='--phosphor' if on else
                       ('--amber' if n == 2 else '--paper'))
        if not on:
            f.line(x0 + 55, 106, x0 + 55, 166, stroke='--amber', width=2.2, arrow=True)
            f.line(x0 + 230, 106, x0 + 230, 166, stroke='--paper-dim', width=1.4, arrow=True)
        else:
            f.line(x0 + 55, 106, x0 + 55, 166, stroke='--phosphor', width=1.4, arrow=True)
            f.line(x0 + 230, 106, x0 + 230, 166, stroke='--phosphor', width=1.4, arrow=True)
            # each node also reaches across, drawn in pieces so no line crosses a box
            f.line(x0 + 80, 104, x0 + 120, 134, stroke='--phosphor', width=1.2, dash='4 3')
            f.arrow([(x0 + 120, 134), (x0 + 168, 166)], stroke='--phosphor', width=1.2, dash='4 3')
            f.line(x0 + 196, 104, x0 + 120, 140, stroke='--phosphor', width=1.2, dash='4 3')
            f.arrow([(x0 + 120, 140), (x0 + 72, 166)], stroke='--phosphor', width=1.2, dash='4 3')
    f.text(360, 312, T('each node gets half the traffic; the setting decides where it may send it',
                       'cada nó recebe metade do tráfego; a configuração decide para onde ele pode mandar'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('Off, a zone carries half the load however few targets it holds. On, the load follows '
                'the targets.',
                'Desligado, uma zona carrega metade da carga por menos alvos que tenha. Ligado, a carga '
                'segue os alvos.')
