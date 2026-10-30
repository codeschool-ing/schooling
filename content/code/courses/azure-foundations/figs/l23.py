"""Lesson 23: ExpressRoute and VPN Gateway."""
from figures import Fig, T, figure


@figure('l23-active-active', 23)
def active_active():
    f = Fig('l23-active-active', 720, 300, T(
        'Dual redundancy for a site-to-site VPN. On the left, the office network 192.168.0.0/16 with '
        'two firewalls. On the right, in the hub network\'s GatewaySubnet 10.0.255.0/27, the VPN '
        'gateway vpng-shop with two active instances, each with its own public address. Each firewall '
        'builds a tunnel to each instance, four tunnels in all, crossing the internet in the middle. '
        'Losing any one firewall or any one instance leaves two or more tunnels up.',
        'Redundância dupla numa VPN site a site. À esquerda, a rede do escritório 192.168.0.0/16 com dois '
        'firewalls. À direita, na GatewaySubnet 10.0.255.0/27 da rede hub, o VPN gateway vpng-shop com '
        'duas instâncias ativas, cada uma com o seu endereço público. Cada firewall monta um túnel até '
        'cada instância, quatro túneis ao todo, atravessando a internet no meio. Perder qualquer firewall '
        'ou qualquer instância deixa dois ou mais túneis de pé.'))
    f.text(115, 50, T('office', 'escritório'), size=10.5, weight='600', fill='--paper-dim')
    f.text(115, 68, '192.168.0.0/16', size=9.5, mono=True, fill='--paper-dim')
    f.text(600, 50, 'GatewaySubnet', size=10.5, mono=True, fill='--paper-dim')
    f.text(600, 68, '10.0.255.0/27', size=9.5, mono=True, fill='--paper-dim')
    left = [(50, 100, T('firewall 1', 'firewall 1')), (50, 190, T('firewall 2', 'firewall 2'))]
    right = [(530, 100, T('instance 1', 'instância 1'), 'pip-vpng-shop-1'),
             (530, 190, T('instance 2', 'instância 2'), 'pip-vpng-shop-2')]
    for x, y, name in left:
        f.rect(x, y, 130, 50, stroke='--wire', fill='--panel')
        f.text(x + 65, y + 25, name, size=10.5)
    for x, y, name, pip in right:
        f.rect(x, y, 140, 50, stroke='--phosphor', fill='--panel')
        f.text(x + 70, y + 18, name, size=10.5)
        f.text(x + 70, y + 36, pip, size=9, mono=True, fill='--paper-dim')
    f.text(360, 60, T('across the internet', 'pela internet'), size=10.5, weight='600', fill='--paper-dim')
    for ly in (115, 215):
        for ry in (115, 215):
            dy = 6 if ry > ly else -6 if ry < ly else 0
            f.line(181, ly + dy * 0.5, 529, ry - dy * 0.5, stroke='--amber', width=1.3)
    f.text(360, 288, T('four tunnels: any one device can fail', 'quatro túneis: qualquer aparelho pode falhar'),
           size=10, fill='--amber')
    return f, T('Two firewalls and two active instances make four tunnels, and BGP keeps track of which are up.',
                'Dois firewalls e duas instâncias ativas fazem quatro túneis, e o BGP acompanha quais estão de pé.')


@figure('l23-expressroute', 23)
def expressroute():
    f = Fig('l23-expressroute', 720, 290, T(
        'The parts of an ExpressRoute circuit, from left to right. The office router connects through '
        'the connectivity provider\'s network to a peering location, such as Sao Paulo, where two '
        'Microsoft edge routers, primary and secondary, sit. From there Microsoft\'s network carries '
        'private peering to an ExpressRoute gateway in the hub\'s GatewaySubnet, beside the VPN gateway, '
        'and Microsoft peering to Microsoft\'s public services. Nothing in the path crosses the internet.',
        'As partes de um circuito ExpressRoute, da esquerda para a direita. O roteador do escritório se '
        'liga pela rede do provedor de conectividade a uma localidade de peering, como Sao Paulo, onde '
        'ficam dois roteadores de borda da Microsoft, primário e secundário. Dali a rede da Microsoft leva '
        'o private peering a um ExpressRoute gateway na GatewaySubnet do hub, ao lado do VPN gateway, e o '
        'Microsoft peering aos serviços públicos da Microsoft. Nada no caminho atravessa a internet.'))
    f.rect(16, 115, 110, 56, stroke='--wire', fill='--panel')
    f.text(71, 136, T('office router', 'roteador'), size=10)
    f.text(71, 154, T('the company', 'a empresa'), size=9, fill='--paper-dim')
    f.rect(150, 105, 130, 76, stroke='--paper-dim', fill='--panel', dash='5 4')
    f.text(215, 132, T('provider', 'provedor'), size=10.5)
    f.text(215, 152, T('the carrier\'s network', 'a rede da operadora'), size=9, fill='--paper-dim')
    f.rect(304, 60, 150, 170, stroke='--amber', fill='--ink')
    f.text(379, 78, T('peering location', 'localidade de peering'), size=9.5, fill='--paper-dim')
    f.text(379, 96, 'Sao Paulo', size=10, mono=True)
    f.rect(320, 112, 118, 42, stroke='--wire', fill='--panel')
    f.text(379, 133, T('primary router', 'roteador primário'), size=9.5)
    f.rect(320, 170, 118, 42, stroke='--wire', fill='--panel')
    f.text(379, 191, T('secondary router', 'roteador secundário'), size=9.5)
    f.rect(500, 40, 204, 134, stroke='--wire', fill='--ink', dash='5 4')
    f.text(602, 58, 'GatewaySubnet', size=10, mono=True, fill='--paper-dim')
    f.rect(516, 72, 172, 40, stroke='--phosphor', fill='--panel')
    f.text(602, 86, T('ExpressRoute gateway', 'ExpressRoute gateway'), size=10)
    f.text(602, 102, T('private peering', 'private peering'), size=9, fill='--paper-dim')
    f.rect(516, 122, 172, 40, stroke='--wire', fill='--panel')
    f.text(602, 142, T('VPN gateway, as backup', 'VPN gateway, de reserva'), size=10)
    f.rect(500, 196, 204, 54, stroke='--paper-dim', fill='--panel')
    f.text(602, 216, T('Microsoft\'s public services', 'serviços públicos da Microsoft'), size=10)
    f.text(602, 234, T('Microsoft peering', 'Microsoft peering'), size=9, fill='--paper-dim')
    f.arrow([(127, 143), (149, 143)], stroke='--paper-dim')
    f.arrow([(281, 133), (319, 133)], stroke='--paper-dim')
    f.arrow([(281, 153), (300, 153), (300, 191), (319, 191)], stroke='--paper-dim')
    f.line(439, 133, 472, 133, stroke='--paper-dim')
    f.line(439, 191, 472, 191, stroke='--paper-dim')
    f.line(472, 92, 472, 223, stroke='--paper-dim')
    f.arrow([(472, 92), (515, 92)], stroke='--phosphor')
    f.arrow([(472, 223), (499, 223)], stroke='--paper-dim')
    f.text(360, 274, T('both peerings ride both connections; no path crosses the internet',
                       'os dois peerings usam as duas conexões; nenhum caminho passa pela internet'),
           size=9.5, fill='--paper-dim')
    return f, T('One circuit is two connections to two routers, in one building, which is why one circuit is not enough.',
                'Um circuito são duas conexões a dois roteadores, num prédio só, e é por isso que um circuito não basta.')
