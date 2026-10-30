"""Lesson 15: the VPC network."""
from figures import Fig, T, figure


@figure('l15-global', 15)
def global_network():
    f = Fig('l15-global', 720, 300, T(
        'The planner network drawn as one box that spans two regions. Inside it, the region '
        'southamerica-east1, São Paulo, holds the subnet planner-sao-paulo with range 10.10.0.0/20, and '
        'the subnet stretches across the three zones a, b and c. The region southamerica-west1, Santiago, '
        'holds planner-santiago with range 10.11.0.0/20, across its zones. A line between a machine in '
        'each subnet is labelled internal addresses, nothing to build in between, billed per crossing. '
        'Along the bottom: the network, its routes and its firewall rules are global; a subnet is '
        'regional; a machine is zonal.',
        'A rede planner desenhada como uma caixa que abrange duas regiões. Dentro dela, a região '
        'southamerica-east1, São Paulo, tem a sub-rede planner-sao-paulo com a faixa 10.10.0.0/20, e a '
        'sub-rede se estende pelas três zonas a, b e c. A região southamerica-west1, Santiago, tem '
        'planner-santiago com a faixa 10.11.0.0/20, pelas suas zonas. Uma linha entre uma máquina em cada '
        'sub-rede diz endereços internos, nada a construir no meio, cobrado por travessia. Embaixo: a rede, '
        'as rotas e as regras de firewall são globais; uma sub-rede é regional; uma máquina é zonal.'))
    f.rect(20, 16, 680, 226, stroke='--amber', fill='--ink', width=1.6)
    f.text(40, 32, T('network planner: global', 'rede planner: global'), size=10.5, anchor='start',
           fill='--amber')
    for x, region, city, subnet, rng in ((40, 'southamerica-east1', 'São Paulo', 'planner-sao-paulo', '10.10.0.0/20'),
                                         (380, 'southamerica-west1', 'Santiago', 'planner-santiago', '10.11.0.0/20')):
        f.text(x + 150, 56, region, size=10, mono=True)
        f.text(x + 150, 72, city, size=9.5, fill='--paper-dim')
        f.rect(x, 84, 300, 52, stroke='--phosphor', fill='--scan', width=1.6)
        f.text(x + 150, 102, subnet, size=10, mono=True)
        f.text(x + 150, 120, rng, size=9.5, mono=True, fill='--phosphor')
        for i, z in enumerate('abc'):
            zx = x + i * 104
            f.rect(zx, 150, 92, 40, stroke='--wire', fill='--panel', width=1, dash='3 3')
            f.text(zx + 46, 170, T(f'zone {z}', f'zona {z}'), size=9, fill='--paper-dim')
        f.text(x + 150, 206, T('the subnet covers all three', 'a sub-rede cobre as três'), size=9,
               fill='--paper-dim')
    f.arrow([(342, 110), (378, 110)], stroke='--phosphor')
    f.text(360, 262, T('global: the network, its routes, its firewall rules', 'global: a rede, as rotas, as regras de firewall'),
           size=10)
    f.text(360, 282, T('regional: a subnet, across every zone of its region · zonal: a machine',
                       'regional: uma sub-rede, por todas as zonas da região · zonal: uma máquina'),
           size=9.5, fill='--paper-dim')
    return f, T('One network across regions; a subnet across the zones of one.',
                'Uma rede entre regiões; uma sub-rede entre as zonas de uma.')
