"""Lesson 1: regions, zones, the backbone, and what crossing them costs."""
from figures import Fig, T, figure


@figure('l01-backbone', 1)
def backbone():
    f = Fig('l01-backbone', 720, 330, T(
        'Two ways a request from a user in Recife reaches a service in São Paulo. Above, Premium '
        'Tier: the request enters Google\'s network at a point of presence near Recife and travels on '
        'Google\'s own backbone to the region southamerica-east1, which holds three zones, a, b and c. '
        'Below, Standard Tier: the request crosses the public internet all the way and enters '
        'Google\'s network only at the region. Between southamerica-east1 and southamerica-west1, '
        'Santiago, traffic always travels on the backbone.',
        'Dois caminhos para um pedido de um usuário em Recife chegar a um serviço em São Paulo. Em '
        'cima, o Premium Tier: o pedido entra na rede do Google num ponto de presença perto de Recife '
        'e viaja pela rede própria do Google até a região southamerica-east1, que tem três zonas, a, '
        'b e c. Embaixo, o Standard Tier: o pedido atravessa a internet pública até o fim e só entra '
        'na rede do Google na região. Entre southamerica-east1 e southamerica-west1, Santiago, o '
        'tráfego anda sempre pela rede do Google.'))
    # the user
    f.rect(20, 130, 110, 60, stroke='--wire', fill='--panel')
    f.lines(75, 160, [T('a user', 'um usuário'), T('in Recife', 'em Recife')], size=10.5)
    # the region
    f.rect(430, 70, 270, 180, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(565, 88, 'southamerica-east1', size=10.5, mono=True)
    for i, z in enumerate('abc'):
        x = 448 + i * 84
        f.rect(x, 108, 74, 54, stroke='--wire', fill='--scan')
        f.text(x + 37, 135, z, size=12, mono=True)
    f.text(565, 186, T('three zones: separate power,', 'três zonas: energia, refrigeração'),
           size=9.5, fill='--paper-dim')
    f.text(565, 202, T('cooling and network', 'e rede separadas'), size=9.5, fill='--paper-dim')
    # Santiago
    f.rect(560, 278, 140, 40, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(630, 298, 'southamerica-west1', size=9.5, mono=True)
    f.arrow([(630, 252), (630, 274)], stroke='--phosphor', width=2, start=True)
    f.text(548, 264, T('always the backbone', 'sempre a rede do Google'), size=9.5, anchor='end',
           fill='--phosphor')
    # premium
    f.rect(170, 40, 92, 40, stroke='--phosphor', fill='--panel')
    f.text(216, 60, T('point of presence', 'ponto de presença'), size=9)
    f.arrow([(130, 145), (168, 72)], stroke='--paper-dim', width=1.3)
    f.arrow([(264, 60), (426, 100)], stroke='--phosphor', width=2.4)
    f.text(330, 46, 'Premium Tier', size=11, weight='600', fill='--phosphor')
    f.text(340, 112, T("Google's fibre", 'fibra do Google'), size=9.5, fill='--phosphor')
    # standard
    f.path('M130 178 C 200 240, 260 200, 300 236 S 380 250, 426 222', stroke='--amber',
           width=2, dash='5 4', arrow=True)
    f.text(250, 280, 'Standard Tier', size=11, weight='600', fill='--amber')
    f.text(250, 298, T('the public internet, to the region', 'a internet pública, até a região'),
           size=9.5, fill='--amber')
    return f, T('Premium Tier is the default: the request joins Google\'s network near the user.',
                'O Premium Tier é o padrão: o pedido entra na rede do Google perto do usuário.')


@figure('l01-crossings', 1)
def crossings():
    f = Fig('l01-crossings', 720, 300, T(
        'What crossing each boundary costs, read off Google\'s network pricing page on 30 October '
        '2026, in dollars per GiB. Inside southamerica-east1, two zones. Between two machines in the '
        'same zone, over internal addresses: free. Between the two zones: 0.01. From São Paulo to '
        'Santiago, southamerica-west1: 0.14. From São Paulo to Iowa, us-central1: also 0.14. From '
        'Iowa to South Carolina, us-east1, for comparison: 0.02. In from the internet: free.',
        'Quanto custa atravessar cada fronteira, lido na página de preços de rede do Google em 30 de '
        'outubro de 2026, em dólares por GiB. Dentro de southamerica-east1, duas zonas. Entre duas '
        'máquinas na mesma zona, por endereço interno: grátis. Entre as duas zonas: 0,01. De São '
        'Paulo para Santiago, southamerica-west1: 0,14. De São Paulo para Iowa, us-central1: também '
        '0,14. De Iowa para a Carolina do Sul, us-east1, para comparar: 0,02. Da internet para '
        'dentro: grátis.'))
    f.rect(20, 40, 300, 200, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(170, 58, 'southamerica-east1', size=10.5, mono=True)
    f.rect(40, 78, 120, 140, stroke='--wire', fill='--scan')
    f.text(100, 94, 'zone a', size=10, mono=True)
    f.rect(180, 78, 120, 140, stroke='--wire', fill='--scan')
    f.text(240, 94, 'zone b', size=10, mono=True)
    for x, y in ((70, 140), (130, 140), (210, 140)):
        f.rect(x - 18, y - 14, 36, 28, stroke='--paper-dim', fill='--panel')
        f.text(x, y, 'VM', size=9.5, mono=True)
    f.line(88, 140, 112, 140, stroke='--phosphor', width=1.6)
    f.text(100, 172, T('free', 'grátis'), size=10, fill='--phosphor')
    f.arrow([(148, 150), (192, 150)], stroke='--amber', width=1.6, start=True)
    f.text(170, 196, '0.01', size=10.5, mono=True, fill='--amber')
    # the other regions
    f.rect(470, 40, 230, 44, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(585, 62, T('southamerica-west1 (Santiago)', 'southamerica-west1 (Santiago)'), size=9.5)
    f.rect(470, 120, 230, 44, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(585, 142, T('us-central1 (Iowa)', 'us-central1 (Iowa)'), size=9.5)
    f.arrow([(322, 100), (466, 62)], stroke='--amber', width=1.8)
    f.text(394, 66, '0.14', size=10.5, mono=True, fill='--amber')
    f.arrow([(322, 140), (466, 142)], stroke='--amber', width=1.8)
    f.text(394, 130, '0.14', size=10.5, mono=True, fill='--amber')
    f.rect(470, 200, 230, 44, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(585, 222, T('us-east1 (South Carolina)', 'us-east1 (Carolina do Sul)'), size=9.5)
    f.arrow([(600, 166), (600, 196)], stroke='--paper-dim', width=1.4)
    f.text(612, 182, '0.02', size=10.5, mono=True, anchor='start', fill='--paper-dim')
    f.text(170, 266, T('in from the internet: free', 'da internet para dentro: grátis'), size=10,
           fill='--phosphor')
    f.text(585, 270, T('USD per GiB, read 30 October 2026', 'USD por GiB, lido em 30 de outubro de 2026'),
           size=9.5, fill='--paper-dim')
    return f, T('From São Paulo, the next region costs as much as the next continent.',
                'De São Paulo, a região vizinha custa o mesmo que outro continente.')
