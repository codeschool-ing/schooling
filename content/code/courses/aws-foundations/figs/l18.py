"""Lesson 18: three packets through the network ACL and the security groups."""
from figures import Fig, T, figure


@figure('l18-walks', 18)
def walks():
    f = Fig('l18-walks', 720, 430, T(
        'Three packets, each meeting the network ACL at the edge of the subnet and then the security '
        'group on the interface. First: a customer at 203.0.113.50 sends to port 443. The public '
        'network ACL skips rule 90, which names another address, and rule 100 allows 443; alb-sg '
        'allows 443 from anywhere; the packet reaches the load balancer. Second: 198.51.100.7 '
        'sends to port 443. Rule 90 of the network ACL denies it, and alb-sg never sees it, though '
        'it would have allowed it. Third: the load balancer sends to the database on port 5432. '
        'The public network ACL allows it out under rule 120 and the default network ACL of data-a '
        'lets it in, but db-sg allows 5432 only from app-sg, and the load balancer carries alb-sg, '
        'so the security group refuses it.',
        'Três pacotes, cada um encontrando a network ACL na borda da sub-rede e depois o security '
        'group na interface. Primeiro: um cliente em 203.0.113.50 manda para a porta 443. A '
        'network ACL pública pula a regra 90, que nomeia outro endereço, e a regra 100 permite a '
        '443; o alb-sg permite 443 de qualquer lugar; o pacote chega ao load balancer. Segundo: '
        '198.51.100.7 manda para a porta 443. A regra 90 da network ACL o nega, e o alb-sg nunca o '
        'vê, embora o fosse permitir. Terceiro: o load balancer manda para o banco de dados na '
        'porta 5432. A network ACL pública o deixa sair pela regra 120 e a network ACL padrão de '
        'data-a o deixa entrar, mas o db-sg só permite 5432 vindo do app-sg, e o load balancer '
        'carrega o alb-sg, então o security group o recusa.'))
    cols = [(20, 125), (175, 170), (375, 170), (575, 125)]
    heads = [T('from', 'de'), T('network ACL, at the subnet', 'network ACL, na sub-rede'),
             T('security group, on the interface', 'security group, na interface'), T('to', 'para')]
    for (x, w), h in zip(cols, heads):
        f.text(x + w / 2, 22, h, size=10, weight='600', fill='--paper-dim')
    f.line(20, 36, 700, 36, stroke='--wire', width=1)

    def box(col, y, rows, stroke, dash=None, dim=False):
        x, w = cols[col]
        f.rect(x, y - 26, w, 52, stroke=stroke, fill='--panel', dash=dash,
               width=1.5 if stroke in ('--amber', '--phosphor') else 1.2)
        top = y - 8 if len(rows) == 2 else y
        for i, (s, mono) in enumerate(rows):
            f.text(x + w / 2, top + i * 17, s, size=9.5 if mono else 10, mono=mono,
                   fill='--paper-dim' if dim else '--paper')

    def link(c1, c2, y, stroke, dash=None):
        a = cols[c1][0] + cols[c1][1] + 2
        b = cols[c2][0] - 3
        f.arrow([(a, y), (b, y)], stroke=stroke, width=1.4, dash=dash)

    # 1: the customer
    y = 88
    box(0, y, [(T('a customer', 'um cliente'), False), ('203.0.113.50', True)], '--wire')
    box(1, y, [('90: no match', True), ('100: allow 443', True)], '--phosphor')
    box(2, y, [('alb-sg:', True), ('443 from 0.0.0.0/0', True)], '--phosphor')
    box(3, y, [(T('load balancer', 'load balancer'), False), ('public-a', True)], '--phosphor')
    for c in range(3):
        link(c, c + 1, y, '--phosphor')
    f.text(360, y + 40, T('allowed twice in, and the reply leaves on rule 100 outbound',
                          'permitido duas vezes na entrada, e a resposta sai pela regra 100 de saída'),
           size=9.5, fill='--phosphor', italic=True)

    # 2: the address the shop refuses
    y = 208
    box(0, y, [(T('the refused one', 'o recusado'), False), ('198.51.100.7', True)], '--wire')
    box(1, y, [('90: deny', True), ('198.51.100.7/32', True)], '--amber')
    box(2, y, [(T('would allow it,', 'o permitiria,'), False), (T('never sees it', 'nunca o vê'), False)],
        '--wire', dash='4 3', dim=True)
    box(3, y, [(T('load balancer', 'load balancer'), False), ('public-a', True)], '--wire',
        dash='4 3', dim=True)
    link(0, 1, y, '--amber')
    f.text(360, y + 40, T('dropped at the edge of the subnet: a security group cannot deny',
                          'descartado na borda da sub-rede: um security group não sabe negar'),
           size=9.5, fill='--amber', italic=True)

    # 3: the load balancer, straight to the database
    y = 328
    box(0, y, [(T('load balancer', 'load balancer'), False), (T('carries alb-sg', 'carrega alb-sg'), False)],
        '--wire')
    box(1, y, [('public out 120', True), ('data-a in: 100', True)], '--phosphor')
    box(2, y, [('db-sg: 5432', True), (T('from app-sg only', 'só do app-sg'), False)], '--amber')
    box(3, y, [(T('database', 'banco de dados'), False), ('10.20.97.10', True)], '--wire',
        dash='4 3', dim=True)
    link(0, 1, y, '--phosphor')
    link(1, 2, y, '--phosphor')
    f.text(360, y + 40, T('every address and subnet rule allowed it; the group it carries did not',
                          'todo endereço e regra de sub-rede permitiu; o grupo que ele carrega, não'),
           size=9.5, fill='--amber', italic=True)
    f.text(360, 412, T('the same request from a machine carrying app-sg would pass',
                       'o mesmo pedido de uma máquina com app-sg passaria'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('The network ACL can refuse an address. Only the security group can refuse an identity.',
                'A network ACL sabe recusar um endereço. Só o security group sabe recusar uma identidade.')
