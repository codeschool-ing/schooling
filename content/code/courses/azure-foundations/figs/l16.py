"""Lesson 16: VNet, address space, subnets and delegation."""
from figures import Fig, T, figure


@figure('l16-subnets', 16)
def subnets():
    f = Fig('l16-subnets', 720, 360, T(
        'The virtual network vnet-shop-prod, 10.20.0.0/16, in the region brazilsouth, drawn over the '
        'region\'s three availability zones. Four subnets run across all three zones: snet-web '
        '10.20.1.0/24, snet-app 10.20.2.0/24, snet-data 10.20.3.0/24, delegated to PostgreSQL, and '
        'snet-pe 10.20.4.0/24, for private endpoints. Each offers 251 usable addresses. The rest of the '
        'range is left free.',
        'A rede virtual vnet-shop-prod, 10.20.0.0/16, na região brazilsouth, desenhada sobre as três '
        'zonas de disponibilidade da região. Quatro sub-redes atravessam as três zonas: snet-web '
        '10.20.1.0/24, snet-app 10.20.2.0/24, snet-data 10.20.3.0/24, delegada ao PostgreSQL, e snet-pe '
        '10.20.4.0/24, para private endpoints. Cada uma oferece 251 endereços utilizáveis. O resto do '
        'intervalo fica livre.'))
    f.rect(16, 14, 688, 332, stroke='--paper-dim', fill='--ink', dash='5 4')
    f.text(32, 32, T('region', 'região'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(688, 32, 'brazilsouth', size=10.5, anchor='end', mono=True)
    for i in range(3):
        x = 200 + i * 168
        f.rect(x, 46, 156, 286, stroke=None, fill='--scan')
        f.text(x + 78, 62, T(f'zone {i + 1}', f'zona {i + 1}'), size=9.5, fill='--paper-dim')
    f.text(36, 92, 'vnet-shop-prod', size=10.5, anchor='start', mono=True)
    f.text(36, 110, '10.20.0.0/16', size=10.5, anchor='start', mono=True, fill='--paper-dim')
    rows = [('snet-web', '10.20.1.0/24', T('the web tier', 'a camada web')),
            ('snet-app', '10.20.2.0/24', T('the application', 'a aplicação')),
            ('snet-data', '10.20.3.0/24', T('delegated to PostgreSQL', 'delegada ao PostgreSQL')),
            ('snet-pe', '10.20.4.0/24', T('private endpoints, lesson 19', 'private endpoints, lição 19'))]
    for j, (name, rng, what) in enumerate(rows):
        y = 128 + j * 46
        stroke = '--amber' if name == 'snet-data' else '--wire'
        f.rect(36, y, 650, 34, stroke=stroke, fill='--panel')
        f.text(48, y + 17, name, size=10.5, anchor='start', mono=True)
        f.text(150, y + 17, rng, size=10, anchor='start', mono=True, fill='--paper-dim')
        f.text(440, y + 17, what, size=10)
        f.text(674, y + 17, T('251 usable', '251 utilizáveis'), size=9.5, anchor='end', fill='--paper-dim')
    f.text(360, 322, T('the rest of the range stays free for what nobody has planned yet',
                       'o resto do intervalo fica livre para o que ninguém planejou ainda'),
           size=10, fill='--phosphor')
    return f, T('One network, four subnets, and every subnet in all three zones at once.',
                'Uma rede, quatro sub-redes, e cada sub-rede nas três zonas ao mesmo tempo.')
