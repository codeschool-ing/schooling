"""Lesson 17: network security groups and application security groups."""
from figures import Fig, T, figure


@figure('l17-order', 17)
def order():
    f = Fig('l17-order', 720, 250, T(
        'The order in which two network security groups judge a packet when one is attached to the '
        'subnet and one to the network interface. Inbound, a packet from the network passes the '
        'subnet\'s NSG first and the interface\'s NSG second before reaching the machine. Outbound, a '
        'packet from the machine passes the interface\'s NSG first and the subnet\'s NSG second. A deny '
        'in either stops it.',
        'A ordem em que dois network security groups julgam um pacote quando um está preso à sub-rede '
        'e outro à interface de rede. Na entrada, um pacote vindo da rede passa primeiro pelo NSG da '
        'sub-rede e depois pelo NSG da interface antes de chegar à máquina. Na saída, um pacote da '
        'máquina passa primeiro pelo NSG da interface e depois pelo NSG da sub-rede. Um deny em '
        'qualquer um dos dois o para.'))
    lanes = [(70, T('inbound', 'entrada'), [T('the network', 'a rede'), T('subnet NSG', 'NSG da sub-rede'),
                                           T('interface NSG', 'NSG da interface'), T('the machine', 'a máquina')]),
             (170, T('outbound', 'saída'), [T('the machine', 'a máquina'), T('interface NSG', 'NSG da interface'),
                                           T('subnet NSG', 'NSG da sub-rede'), T('the network', 'a rede')])]
    for y, label, steps in lanes:
        f.text(20, y, label, size=10.5, anchor='start', weight='600', fill='--paper-dim')
        for i, s in enumerate(steps):
            x = 110 + i * 150
            nsg = 'NSG' in s
            f.rect(x, y - 22, 124, 44, stroke='--amber' if nsg else '--wire',
                   fill='--panel' if nsg else '--ink')
            f.text(x + 62, y, s, size=10)
            if i < 3:
                f.arrow([(x + 126, y), (x + 148, y)], stroke='--paper-dim', width=1.3)
    f.text(360, 228, T('both must allow; a deny in either one stops the packet',
                       'os dois precisam permitir; um deny em qualquer um para o pacote'),
           size=10, fill='--amber')
    return f, T('Inbound the subnet is read first; outbound the interface is.',
                'Na entrada a sub-rede é lida primeiro; na saída, a interface.')
