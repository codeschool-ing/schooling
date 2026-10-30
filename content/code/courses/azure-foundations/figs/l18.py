"""Lesson 18: Azure Firewall, route tables and forced tunnelling."""
from figures import Fig, T, figure


@figure('l18-hub', 18)
def hub():
    f = Fig('l18-hub', 720, 330, T(
        'The shop\'s routing. The production network vnet-shop-prod, 10.20.0.0/16, holds snet-web, '
        'snet-app and snet-data; traffic between them stays local. Its route table rt-shop-prod sends '
        'three prefixes to the firewall at 10.0.1.4 in AzureFirewallSubnet of the hub network '
        'vnet-shop-hub, 10.0.0.0/16: 0.0.0.0/0 for the internet, 10.30.0.0/16 for staging and '
        '192.168.0.0/16 for the office. From the firewall, traffic continues to the internet, to '
        'staging and to the office.',
        'O roteamento da loja. A rede de produção vnet-shop-prod, 10.20.0.0/16, tem snet-web, snet-app '
        'e snet-data; o tráfego entre elas fica local. A tabela de rotas rt-shop-prod manda três '
        'prefixos para o firewall em 10.0.1.4 na AzureFirewallSubnet da rede hub vnet-shop-hub, '
        '10.0.0.0/16: 0.0.0.0/0 para a internet, 10.30.0.0/16 para o staging e 192.168.0.0/16 para o '
        'escritório. Do firewall, o tráfego segue para a internet, para o staging e para o escritório.'))
    # production
    f.rect(20, 20, 250, 290, stroke='--wire', fill='--ink')
    f.text(36, 38, 'vnet-shop-prod', size=10.5, anchor='start', mono=True)
    f.text(36, 56, '10.20.0.0/16', size=10, anchor='start', mono=True, fill='--paper-dim')
    for i, s in enumerate(['snet-web', 'snet-app', 'snet-data']):
        f.rect(40, 74 + i * 52, 140, 38, stroke='--wire', fill='--panel')
        f.text(110, 93 + i * 52, s, size=10.5, mono=True)
    f.text(110, 246, T('local between subnets', 'local entre sub-redes'), size=9.5, fill='--paper-dim')
    f.rect(40, 262, 210, 34, stroke='--amber', fill='--panel')
    f.text(145, 279, 'rt-shop-prod', size=10.5, mono=True)
    # hub
    f.rect(330, 90, 170, 150, stroke='--wire', fill='--ink')
    f.text(346, 108, 'vnet-shop-hub', size=10.5, anchor='start', mono=True)
    f.rect(346, 140, 138, 70, stroke='--amber', fill='--scan')
    f.text(415, 160, 'Azure Firewall', size=10.5)
    f.text(415, 182, '10.0.1.4', size=10.5, mono=True)
    f.text(415, 225, 'AzureFirewallSubnet', size=9, mono=True, fill='--paper-dim')
    # arrows prod -> fw
    labels = [('0.0.0.0/0', 130), ('10.30.0.0/16', 175), ('192.168.0.0/16', 220)]
    for txt, y in labels:
        f.arrow([(272, y), (328, y)], stroke='--amber', width=1.3)
    f.text(300, 82, T('three routes', 'três rotas'), size=9.5, fill='--paper-dim')
    # destinations
    dests = [(T('the internet', 'a internet'), 60), (T('staging', 'staging'), 165),
             (T('the office', 'o escritório'), 270)]
    for (name, y) in dests:
        f.rect(570, y - 20, 130, 40, stroke='--paper-dim', fill='--panel', dash='4 3')
        f.text(635, y, name, size=10.5)
        f.arrow([(502, 165 + (y - 165) * 0.4), (568, y)], stroke='--paper-dim', width=1.2)
    f.text(300, 322, T('0.0.0.0/0, 10.30.0.0/16 and 192.168.0.0/16 all point at the firewall',
                       '0.0.0.0/0, 10.30.0.0/16 e 192.168.0.0/16 apontam todos para o firewall'),
           size=9.5, fill='--amber')
    return f, T('Production\'s three boundaries all cross the hub\'s firewall; traffic inside production does not.',
                'As três fronteiras da produção passam pelo firewall do hub; o tráfego dentro da produção não.')
