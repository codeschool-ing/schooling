"""Lesson 20: VNet peering and hub-and-spoke topology."""
from figures import Fig, T, figure


def vnet(f, x, y, w, h, name, cidr, sub, stroke='--wire'):
    f.rect(x, y, w, h, stroke=stroke, fill='--panel')
    f.text(x + w / 2, y + 20, name, size=10.5, mono=True)
    f.text(x + w / 2, y + 40, cidr, size=10, mono=True, fill='--paper-dim')
    f.text(x + w / 2, y + 60, sub, size=9.5, fill='--paper-dim')


@figure('l20-transitive', 20)
def transitive():
    f = Fig('l20-transitive', 720, 290, T(
        'Three networks. The hub vnet-shop-hub, 10.0.0.0/16, sits at the top. vnet-shop-prod, '
        '10.20.0.0/16, and vnet-shop-staging, 10.30.0.0/16, sit below it, each joined to the hub by a '
        'peering drawn as a solid line with two arrowheads. Between production and staging a dashed '
        'line says there is no route: each spoke learns the hub\'s range and not the other spoke\'s.',
        'Três redes. O hub vnet-shop-hub, 10.0.0.0/16, fica em cima. vnet-shop-prod, 10.20.0.0/16, e '
        'vnet-shop-staging, 10.30.0.0/16, ficam abaixo dele, cada uma ligada ao hub por um peering '
        'desenhado como linha cheia com duas pontas de seta. Entre produção e staging uma linha '
        'tracejada diz que não há rota: cada spoke aprende o intervalo do hub e não o da outra spoke.'))
    vnet(f, 270, 16, 180, 72, 'vnet-shop-hub', '10.0.0.0/16', 'shop-shared', stroke='--phosphor')
    vnet(f, 40, 190, 180, 72, 'vnet-shop-prod', '10.20.0.0/16', 'shop-prod')
    vnet(f, 500, 190, 180, 72, 'vnet-shop-staging', '10.30.0.0/16', 'shop-staging')
    f.arrow([(200, 189), (290, 89)], stroke='--phosphor', width=1.5, start=True)
    f.arrow([(520, 189), (430, 89)], stroke='--phosphor', width=1.5, start=True)
    f.text(205, 130, T('peering', 'peering'), size=10, anchor='end', fill='--phosphor')
    f.text(515, 130, T('peering', 'peering'), size=10, anchor='start', fill='--phosphor')
    f.line(222, 226, 498, 226, stroke='--amber', dash='6 5', width=1.5)
    f.text(360, 214, T('no route', 'sem rota'), size=10.5, weight='600', fill='--amber')
    f.text(360, 244, T('a peering passes nothing on', 'um peering não repassa nada'), size=10,
           fill='--paper-dim')
    return f, T('Each spoke learns the hub\'s range. Neither learns the other\'s.',
                'Cada spoke aprende o intervalo do hub. Nenhuma aprende o da outra.')


@figure('l20-hub', 20)
def hub():
    f = Fig('l20-hub', 720, 330, T(
        'The shop\'s hub and spokes. The hub vnet-shop-hub, 10.0.0.0/16 in shop-shared, holds three '
        'subnets: AzureFirewallSubnet with the firewall, GatewaySubnet with the gateway to the office, '
        'and a subnet for DNS. The office, 192.168.0.0/16, connects to the gateway. Two spokes, '
        'vnet-shop-prod and vnet-shop-staging, are peered to the hub; traffic from one spoke to the '
        'other goes up to the firewall and down again.',
        'O hub e as spokes da loja. O hub vnet-shop-hub, 10.0.0.0/16 em shop-shared, guarda três '
        'sub-redes: AzureFirewallSubnet com o firewall, GatewaySubnet com o gateway para o escritório, e '
        'uma sub-rede para o DNS. O escritório, 192.168.0.0/16, se liga ao gateway. Duas spokes, '
        'vnet-shop-prod e vnet-shop-staging, têm peering com o hub; o tráfego de uma spoke para a outra '
        'sobe até o firewall e desce de novo.'))
    f.path('M190 20 H530 V170 H190 Z', stroke='--phosphor')
    f.text(206, 38, 'vnet-shop-hub', size=10.5, anchor='start', mono=True)
    f.text(514, 38, '10.0.0.0/16', size=10, anchor='end', mono=True, fill='--paper-dim')
    subs = [(206, 'AzureFirewallSubnet', T('firewall', 'firewall')),
            (316, 'snet-dns', T('DNS resolver', 'resolvedor DNS')),
            (426, 'GatewaySubnet', T('gateway', 'gateway'))]
    for x, name, what in subs:
        f.rect(x, 60, 98, 90, stroke='--wire', fill='--scan')
        f.text(x + 49, 78, name, size=8.5, mono=True)
        f.text(x + 49, 112, what, size=9.5)
    # office
    f.rect(560, 60, 140, 60, stroke='--paper-dim', fill='--ink', dash='5 4')
    f.text(630, 80, T('the office', 'o escritório'), size=10)
    f.text(630, 100, '192.168.0.0/16', size=9.5, mono=True, fill='--paper-dim')
    f.arrow([(559, 92), (531, 105)], stroke='--paper-dim', start=True)
    # spokes
    vnet(f, 40, 230, 200, 72, 'vnet-shop-prod', '10.20.0.0/16', 'shop-prod')
    vnet(f, 480, 230, 200, 72, 'vnet-shop-staging', '10.30.0.0/16', 'shop-staging')
    f.arrow([(140, 229), (140, 200), (250, 200), (250, 171)], stroke='--amber', width=1.5)
    f.arrow([(270, 171), (270, 196), (590, 196), (590, 229)], stroke='--amber', width=1.5)
    f.text(360, 214, T('spoke to spoke: up to the firewall, and down again',
                       'de spoke para spoke: sobe até o firewall, e desce de novo'),
           size=10, fill='--amber')
    return f, T('A spoke owns its workload and borrows everything else from the hub.',
                'Uma spoke é dona da sua carga e pega emprestado todo o resto do hub.')
