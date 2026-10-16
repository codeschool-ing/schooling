"""Lesson 20: peering is a pair, a Transit Gateway is a hub."""
import math
from figures import Fig, T, figure


def _vpc(f, x, y, w, name, cidr, region):
    f.rect(x, y, w, 64, stroke='--paper', fill='--panel', width=1.4)
    f.text(x + w / 2, y + 18, name, size=11, mono=True, weight='600')
    f.text(x + w / 2, y + 36, cidr, size=10, mono=True)
    f.text(x + w / 2, y + 52, region, size=9.5, mono=True, fill='--paper-dim')


@figure('l20-not-transitive', 20)
def not_transitive():
    f = Fig('l20-not-transitive', 720, 330, T(
        'Three VPCs. At the top, shop-prod, 10.20.0.0/16 in sa-east-1. At the bottom left, '
        'shop-staging, 10.30.0.0/16 in sa-east-1; at the bottom right, the disaster-recovery copy, '
        '10.40.0.0/16 in us-east-1. Production is peered with staging and, across regions, with the '
        'copy. Between staging and the copy there is no peering, and a packet from one to the other '
        'cannot pass through production: a peering carries only traffic between its own two VPCs.',
        'Três VPCs. Em cima, shop-prod, 10.20.0.0/16 em sa-east-1. Embaixo à esquerda, '
        'shop-staging, 10.30.0.0/16 em sa-east-1; embaixo à direita, a cópia de recuperação de '
        'desastre, 10.40.0.0/16 em us-east-1. A produção tem peering com o staging e, entre '
        'regiões, com a cópia. Entre o staging e a cópia não há peering, e um pacote de um para o '
        'outro não passa pela produção: um peering só carrega tráfego entre as suas duas VPCs.'))
    _vpc(f, 260, 30, 200, 'shop-prod', '10.20.0.0/16', 'sa-east-1')
    _vpc(f, 40, 210, 200, 'shop-staging', '10.30.0.0/16', 'sa-east-1')
    _vpc(f, 480, 210, 200, T('dr copy', 'cópia dr'), '10.40.0.0/16', 'us-east-1')
    f.line(280, 96, 160, 208, stroke='--phosphor', width=1.8)
    f.text(168, 140, T('peering', 'peering'), size=10.5, weight='600', fill='--phosphor', anchor='end')
    f.line(440, 96, 560, 208, stroke='--phosphor', width=1.8)
    f.text(552, 140, T('peering, across regions', 'peering, entre regiões'), size=10.5,
           weight='600', fill='--phosphor', anchor='start')
    f.line(242, 242, 478, 242, stroke='--amber', width=1.6, dash='6 5')
    f.text(360, 230, T('no path', 'sem caminho'), size=10.5, weight='600', fill='--amber')
    f.text(360, 258, T('not through production either', 'nem passando pela produção'),
           size=10, fill='--amber')
    f.text(360, 312, T('each pair that must talk needs a peering of its own',
                       'cada par que precisa conversar precisa de um peering próprio'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('A peering is a pair. Two of them that share a VPC do not make a path between the other '
                'two.',
                'Um peering é um par. Dois deles que dividem uma VPC não fazem um caminho entre as outras '
                'duas.')


@figure('l20-hub', 20)
def hub():
    f = Fig('l20-hub', 720, 360, T(
        'The Transit Gateway shop-hub in the middle, with two VPC attachments: shop-prod, '
        '10.20.0.0/16, through its three app subnets, and shop-staging, 10.30.0.0/16, through one '
        'subnet. Below the hub, its default route table, with a route for 10.20.0.0/16 to the '
        'production attachment and one for 10.30.0.0/16 to the staging attachment. Association '
        'says which hub table an attachment\'s traffic is looked up in; propagation says which '
        'tables learn the attachment\'s range. Each VPC\'s own route table still needs a route '
        'pointing at the hub.',
        'O Transit Gateway shop-hub no meio, com dois attachments de VPC: shop-prod, '
        '10.20.0.0/16, pelas três sub-redes app, e shop-staging, 10.30.0.0/16, por uma sub-rede. '
        'Abaixo do hub, a tabela de rotas padrão dele, com uma rota para 10.20.0.0/16 até o '
        'attachment da produção e uma para 10.30.0.0/16 até o do staging. Associação diz em que '
        'tabela do hub o tráfego de um attachment é procurado; propagação diz que tabelas aprendem '
        'o intervalo do attachment. A tabela de rotas de cada VPC ainda precisa de uma rota '
        'apontando para o hub.'))
    _vpc(f, 20, 40, 200, 'shop-prod', '10.20.0.0/16', T('3 app subnets', '3 sub-redes app'))
    _vpc(f, 500, 40, 200, 'shop-staging', '10.30.0.0/16', T('1 subnet', '1 sub-rede'))
    f.rect(290, 44, 140, 56, stroke='--phosphor', fill='--scan', width=1.6, rx=12)
    f.text(360, 64, 'shop-hub', size=11, mono=True, weight='600')
    f.text(360, 82, 'Transit Gateway', size=10, fill='--paper-dim')
    f.line(222, 72, 288, 72, stroke='--phosphor', width=1.6, start=True, arrow=True)
    f.line(432, 72, 498, 72, stroke='--phosphor', width=1.6, start=True, arrow=True)
    f.text(255, 60, T('attachment', 'attachment'), size=9.5, fill='--phosphor')
    f.text(465, 60, T('attachment', 'attachment'), size=9.5, fill='--phosphor')
    f.line(360, 102, 360, 150, stroke='--paper-dim', width=1.3, arrow=True)
    f.rect(200, 154, 320, 92, stroke='--paper-dim', fill='--panel')
    f.text(360, 172, T('hub route table (default)', 'tabela de rotas do hub (padrão)'), size=10.5,
           weight='600')
    f.text(360, 198, '10.20.0.0/16  →  attach shop-prod', size=10, mono=True)
    f.text(360, 222, '10.30.0.0/16  →  attach shop-staging', size=10, mono=True)
    f.text(120, 280, T('association:', 'associação:'), size=10, weight='600', fill='--paper')
    f.text(120, 298, T('which table an attachment\'s', 'em que tabela o tráfego de'), size=10,
           fill='--paper-dim')
    f.text(120, 314, T('traffic is looked up in', 'um attachment é procurado'), size=10,
           fill='--paper-dim')
    f.text(600, 280, T('propagation:', 'propagação:'), size=10, weight='600', fill='--paper')
    f.text(600, 298, T('which tables learn', 'que tabelas aprendem'), size=10, fill='--paper-dim')
    f.text(600, 314, T('an attachment\'s range', 'o intervalo de um attachment'), size=10,
           fill='--paper-dim')
    f.text(360, 344, T('each VPC\'s own table still points the other range at the hub',
                       'a tabela de cada VPC ainda aponta o outro intervalo para o hub'),
           size=10, fill='--amber', italic=True)
    return f, T('The hub routes between attachments, by tables of its own. The VPCs still have to send '
                'their packets to it.',
                'O hub roteia entre attachments, por tabelas próprias. As VPCs ainda precisam mandar os '
                'pacotes para ele.')


@figure('l20-mesh-or-hub', 20)
def mesh_or_hub():
    f = Fig('l20-mesh-or-hub', 720, 330, T(
        'Five VPCs joined two ways. On the left, every pair peered: ten lines between five VPCs. On '
        'the right, the same five VPCs each attached once to a Transit Gateway in the middle: five '
        'lines. With n VPCs, a full mesh of peerings needs n times n minus one over two '
        'connections; the hub needs n attachments, each charged by the hour.',
        'Cinco VPCs ligadas de duas maneiras. À esquerda, todo par com peering: dez linhas entre '
        'cinco VPCs. À direita, as mesmas cinco VPCs, cada uma ligada uma vez a um Transit Gateway '
        'no meio: cinco linhas. Com n VPCs, uma malha completa de peerings precisa de n vezes n '
        'menos um sobre dois conexões; o hub precisa de n attachments, cada um cobrado por hora.'))
    r, nr = 100, 20
    for cx, hub in ((180, False), (540, True)):
        pts = [(cx + r * math.sin(2 * math.pi * k / 5), 160 - r * math.cos(2 * math.pi * k / 5))
               for k in range(5)]

        def edge(a, b):
            dx, dy = b[0] - a[0], b[1] - a[1]
            d = math.hypot(dx, dy)
            return (a[0] + dx * (nr + 2) / d, a[1] + dy * (nr + 2) / d), \
                   (b[0] - dx * (nr + 2) / d, b[1] - dy * (nr + 2) / d)
        if hub:
            for p in pts:
                s, e = edge(p, (cx, 160))
                e = (cx + (p[0] - cx) * 30 / r, 160 + (p[1] - 160) * 30 / r)
                f.line(s[0], s[1], e[0], e[1], stroke='--phosphor', width=1.5)
            f.circle(cx, 160, 28, fill='--scan', stroke='--phosphor', width=1.6)
            f.text(cx, 160, 'TGW', size=10.5, mono=True, weight='600')
        else:
            for i in range(5):
                for j in range(i + 1, 5):
                    s, e = edge(pts[i], pts[j])
                    f.line(s[0], s[1], e[0], e[1], stroke='--amber', width=1.3)
        for k, p in enumerate(pts):
            f.circle(p[0], p[1], nr, fill='--panel', stroke='--paper', width=1.4)
            f.text(p[0], p[1], f'v{k + 1}', size=10, mono=True)
    f.text(180, 292, T('peering: 10 connections', 'peering: 10 conexões'), size=11, weight='600',
           fill='--amber')
    f.text(180, 310, T('nothing by the hour', 'nada por hora'), size=10, fill='--paper-dim')
    f.text(540, 292, T('Transit Gateway: 5 attachments', 'Transit Gateway: 5 attachments'),
           size=11, weight='600', fill='--phosphor')
    f.text(540, 310, T('5 × 65.70 = 328.50 a month', '5 × 65,70 = 328,50 por mês'), size=10,
           fill='--paper-dim')
    return f, T('Pairs grow as n(n-1)/2, attachments as n. Ten VPCs are 45 peerings or 10 attachments.',
                'Pares crescem como n(n-1)/2, attachments como n. Dez VPCs são 45 peerings ou 10 '
                'attachments.')
