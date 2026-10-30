"""Lesson 21: Cloud VPN and Cloud Interconnect."""
from figures import Fig, T, figure


@figure('l21-ha-vpn', 21)
def ha_vpn():
    f = Fig('l21-ha-vpn', 720, 280, T(
        'The planner\'s HA VPN. On the left, in southamerica-east1, an HA VPN gateway with two interfaces, '
        '0 and 1, and a Cloud Router with ASN 64514. On the right, the office router with two public '
        'addresses, 198.51.100.10 and 198.51.100.11, and ASN 65010. Two encrypted tunnels cross the '
        'internet, one from each interface to one address. Inside each tunnel runs a BGP session on '
        'link-local addresses, 169.254.0.1 to .2 and 169.254.1.1 to .2. Over BGP, the Cloud Router announces '
        'the planner\'s subnets, 10.10.0.0/16 and 10.11.0.0/16, and learns the office\'s 192.168.0.0/16.',
        'O HA VPN do planner. À esquerda, em southamerica-east1, um gateway HA VPN com duas interfaces, 0 e 1, '
        'e um Cloud Router com ASN 64514. À direita, o roteador do escritório com dois endereços públicos, '
        '198.51.100.10 e 198.51.100.11, e ASN 65010. Dois túneis criptografados atravessam a internet, um de '
        'cada interface para um endereço. Dentro de cada túnel roda uma sessão BGP em endereços link-local, '
        '169.254.0.1 a .2 e 169.254.1.1 a .2. Pelo BGP, o Cloud Router anuncia as sub-redes do planner, '
        '10.10.0.0/16 e 10.11.0.0/16, e aprende o 192.168.0.0/16 do escritório.'))
    f.rect(20, 30, 220, 190, stroke='--phosphor', fill='--ink', width=1.4)
    f.text(130, 48, 'southamerica-east1', size=9.5, mono=True, fill='--paper-dim')
    f.rect(40, 64, 180, 70, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(130, 82, T('HA VPN gateway', 'gateway HA VPN'), size=10)
    f.text(70, 112, T('if 0', 'if 0'), size=9, mono=True)
    f.text(190, 112, T('if 1', 'if 1'), size=9, mono=True)
    f.rect(40, 150, 180, 52, stroke='--amber', fill='--panel', width=1.4)
    f.text(130, 168, 'Cloud Router', size=10)
    f.text(130, 186, 'ASN 64514', size=9, mono=True, fill='--amber')
    f.rect(480, 64, 220, 138, stroke='--wire', fill='--panel', width=1.2)
    f.text(590, 84, T('office router', 'roteador do escritório'), size=10)
    f.text(590, 108, '198.51.100.10', size=9, mono=True)
    f.text(590, 126, '198.51.100.11', size=9, mono=True)
    f.text(590, 150, 'ASN 65010', size=9, mono=True, fill='--amber')
    f.text(590, 176, '192.168.0.0/16', size=9, mono=True, fill='--paper-dim')
    f.line(242, 90, 478, 104, stroke='--phosphor', width=2)
    f.line(242, 120, 478, 122, stroke='--phosphor', width=2)
    f.text(360, 70, T('tunnel 0: BGP 169.254.0.1 – .2', 'túnel 0: BGP 169.254.0.1 – .2'), size=9, fill='--phosphor')
    f.text(360, 144, T('tunnel 1: BGP 169.254.1.1 – .2', 'túnel 1: BGP 169.254.1.1 – .2'), size=9, fill='--phosphor')
    f.text(360, 240, T('announced: 10.10.0.0/16, 10.11.0.0/16 · learned: 192.168.0.0/16',
                       'anunciado: 10.10.0.0/16, 10.11.0.0/16 · aprendido: 192.168.0.0/16'), size=10)
    f.text(360, 262, T('either tunnel can carry everything; that is the 99.99%',
                       'qualquer túnel carrega tudo; isso é o 99,99%'), size=9.5, fill='--paper-dim')
    return f, T('Two interfaces, two tunnels, BGP in each: no route written by hand.',
                'Duas interfaces, dois túneis, BGP em cada: nenhuma rota escrita à mão.')
