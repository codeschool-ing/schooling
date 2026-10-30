"""Lesson 1: regions, availability zones and paired regions."""
from figures import Fig, T, figure


@figure('l01-zone-mapping', 1)
def zone_mapping():
    f = Fig('l01-zone-mapping', 720, 330, T(
        'An example of how two subscriptions see the zones of brazilsouth. The region holds three '
        'physical zones, brazilsouth-az1, az2 and az3. The subscription shop-prod maps its logical '
        'zone 1 to az2, zone 2 to az3 and zone 3 to az1; the subscription shop-staging maps its zone '
        '1 to az1, zone 2 to az2 and zone 3 to az3. So zone 1 in one and zone 1 in the other are '
        'different buildings. The mapping drawn is invented; a real one is read from '
        'availabilityZoneMappings.',
        'Um exemplo de como duas assinaturas enxergam as zonas de brazilsouth. A região tem três zonas '
        'físicas, brazilsouth-az1, az2 e az3. A assinatura shop-prod mapeia a zona lógica 1 para az2, '
        'a zona 2 para az3 e a zona 3 para az1; a assinatura shop-staging mapeia a zona 1 para az1, a '
        'zona 2 para az2 e a zona 3 para az3. Então a zona 1 de uma e a zona 1 da outra são prédios '
        'diferentes. O mapeamento desenhado é inventado; um real se lê em availabilityZoneMappings.'))
    # the two subscriptions, side by side
    subs = [(40, 'shop-prod', [2, 3, 1]), (390, 'shop-staging', [1, 2, 3])]
    phys_x = {1: 170, 2: 360, 3: 550}
    for x0, name, mapping in subs:
        f.rect(x0, 20, 290, 92, stroke='--amber', fill='--panel')
        f.text(x0 + 14, 38, T('subscription', 'assinatura'), size=9.5, anchor='start', fill='--paper-dim')
        f.text(x0 + 276, 38, name, size=10.5, anchor='end', mono=True)
        for i in range(3):
            cx = x0 + 52 + i * 93
            f.rect(cx - 34, 56, 68, 40, stroke='--wire', fill='--ink')
            f.text(cx, 70, T('zone', 'zona'), size=9, fill='--paper-dim')
            f.text(cx, 86, str(i + 1), size=12, weight='600', mono=True)
            px = phys_x[mapping[i]] + (-16 if x0 == 40 else 16)
            stroke = '--phosphor' if x0 == 40 else '--amber'
            f.arrow([(cx, 114), (cx, 140), (px, 190), (px, 213)], stroke=stroke, width=1.3)
    f.rect(40, 214, 640, 96, stroke='--paper-dim', fill='--ink', dash='5 4')
    f.text(56, 232, T('region', 'região'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(664, 232, 'brazilsouth', size=10.5, anchor='end', mono=True)
    for n, px in phys_x.items():
        f.rect(px - 72, 246, 144, 48, stroke='--wire', fill='--scan')
        f.text(px, 262, T('physical zone', 'zona física'), size=9, fill='--paper-dim')
        f.text(px, 280, f'brazilsouth-az{n}', size=10, mono=True)
    return f, T('An invented mapping, for the shape of it: zone 1 is a label each subscription maps on its own.',
                'Um mapeamento inventado, pela forma: a zona 1 é um rótulo que cada assinatura mapeia por conta própria.')


@figure('l01-pairs', 1)
def pairs():
    f = Fig('l01-pairs', 720, 230, T(
        'Four regions and the pairs Microsoft documents for them. brazilsoutheast, in Rio de Janeiro, '
        'is paired with brazilsouth, in São Paulo. brazilsouth is paired with southcentralus, in Texas, '
        'outside its own geography. southcentralus and northcentralus are paired with each other. The '
        'arrows from Rio to São Paulo and from São Paulo to Texas run one way only.',
        'Quatro regiões e os pares que a Microsoft documenta para elas. brazilsoutheast, no Rio de '
        'Janeiro, tem como par brazilsouth, em São Paulo. brazilsouth tem como par southcentralus, no '
        'Texas, fora da sua própria geografia. southcentralus e northcentralus são par uma da outra. As '
        'setas do Rio para São Paulo e de São Paulo para o Texas vão num sentido só.'))
    boxes = [(30, 'brazilsoutheast', T('Rio de Janeiro', 'Rio de Janeiro')),
             (205, 'brazilsouth', T('São Paulo', 'São Paulo')),
             (380, 'southcentralus', T('Texas', 'Texas')),
             (555, 'northcentralus', T('Illinois', 'Illinois'))]
    for x, name, place in boxes:
        f.rect(x, 70, 140, 58, stroke='--paper-dim', fill='--panel', dash='5 4')
        f.text(x + 70, 92, name, size=10.5, mono=True)
        f.text(x + 70, 111, place, size=9.5, fill='--paper-dim')
    f.text(117, 40, T('Brazil', 'Brasil'), size=10, weight='600', fill='--paper-dim')
    f.text(467, 40, T('United States', 'Estados Unidos'), size=10, weight='600', fill='--paper-dim')
    f.line(30, 52, 345, 52, stroke='--wire')
    f.line(380, 52, 695, 52, stroke='--wire')
    f.arrow([(171, 99), (204, 99)], stroke='--amber', width=1.5)
    f.arrow([(346, 99), (379, 99)], stroke='--amber', width=1.5)
    f.arrow([(521, 92), (554, 92)], stroke='--phosphor', width=1.5)
    f.arrow([(554, 106), (521, 106)], stroke='--phosphor', width=1.5)
    f.text(360, 168, T('one arrow: the pair runs one way, and the region it points at has another pair',
                       'uma seta: o par vale num sentido só, e a região apontada tem outro par'),
           size=10, fill='--amber')
    f.text(360, 192, T('two arrows: two regions that are each other\'s pair',
                       'duas setas: duas regiões que são par uma da outra'), size=10, fill='--phosphor')
    return f, T('São Paulo\'s pair is in Texas, and Texas\'s pair is not São Paulo.',
                'O par de São Paulo fica no Texas, e o par do Texas não é São Paulo.')
