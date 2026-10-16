"""Lesson 16: the VPC, its subnets, and the addresses AWS keeps."""
from figures import Fig, T, figure


@figure('l16-reserved', 16)
def reserved():
    f = Fig('l16-reserved', 720, 250, T(
        'The sixteen addresses of a /28, 10.20.0.0 to 10.20.0.15, drawn as a row of cells. The '
        'first four and the last are reserved by AWS: .0 is the network address, .1 the VPC '
        'router, .2 the DNS resolver, .3 is kept for future use and .15 is the broadcast address. '
        'The eleven between .4 and .14 are the ones a machine can be given. A /20 keeps the same '
        'five, so 4,096 addresses leave 4,091.',
        'Os dezesseis endereços de um /28, de 10.20.0.0 a 10.20.0.15, desenhados como uma fileira '
        'de células. Os quatro primeiros e o último são reservados pela AWS: .0 é o endereço da '
        'rede, .1 o roteador da VPC, .2 o resolvedor de DNS, .3 fica guardado para uso futuro e .15 '
        'é o endereço de broadcast. Os onze entre .4 e .14 são os que uma máquina pode receber. Um '
        '/20 guarda os mesmos cinco, então 4.096 endereços deixam 4.091.'))
    f.text(360, 24, T('a /28, the smallest subnet AWS accepts: 16 addresses',
                      'um /28, a menor sub-rede que a AWS aceita: 16 endereços'),
           size=11, weight='600', fill='--paper-dim')
    x0, w, y, h = 24, 42, 92, 44
    names = {0: T('network', 'rede'), 1: T('router', 'roteador'), 2: 'DNS',
             3: T('future', 'futuro'), 15: 'broadcast'}
    for i in range(16):
        x = x0 + i * w
        kept = i in names
        f.rect(x + 1, y, w - 2, h, stroke='--amber' if kept else '--phosphor',
               fill='--panel' if kept else '--scan', width=1.4 if kept else 1.2)
        f.text(x + w / 2, y + h / 2, f'.{i}', size=10.5, mono=True)
        if kept:
            low = i in (1, 3)
            ly = y + h + (40 if low else 18)
            f.line(x + w / 2, y + h + 2, x + w / 2, ly - 8, stroke='--amber', width=1)
            f.text(x + w / 2, ly, names[i], size=10, fill='--amber')
    # the usable run, bracketed above
    a, b = x0 + 4 * w + 2, x0 + 15 * w - 2
    f.path(f'M{a:.1f} {y - 6:.1f} L{a:.1f} {y - 14:.1f} L{b:.1f} {y - 14:.1f} L{b:.1f} {y - 6:.1f}',
           stroke='--phosphor', width=1.2)
    f.text((a + b) / 2, y - 26, T('11 a machine can be given', '11 que uma máquina pode receber'),
           size=10.5, fill='--phosphor', weight='600')
    f.text(24, 56, '10.20.0.0/28', size=10.5, anchor='start', mono=True, fill='--paper-dim')
    f.text(360, 222, T('every subnet keeps the same five: a /24 leaves 251, a /20 leaves 4,091',
                       'toda sub-rede guarda os mesmos cinco: um /24 deixa 251, um /20 deixa 4.091'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('Five addresses of every subnet belong to AWS, whatever its size.',
                'Cinco endereços de toda sub-rede pertencem à AWS, seja qual for o tamanho dela.')


@figure('l16-shop-vpc', 16)
def shop_vpc():
    f = Fig('l16-shop-vpc', 720, 470, T(
        'The shop\'s production VPC, shop-prod, 10.20.0.0/16, inside the region sa-east-1. It '
        'spans three Availability Zones, sa-east-1a, b and c, whose zone ids are sae1-az1, az2 and '
        'az3. Each zone holds three subnets, one per tier: public, app and data. Zone a has '
        'public-a 10.20.0.0/20, app-a 10.20.48.0/20 and data-a 10.20.96.0/20; zone b has '
        'public-b 10.20.16.0/20, app-b 10.20.64.0/20 and data-b 10.20.112.0/20; zone c has '
        'public-c 10.20.32.0/20, app-c 10.20.80.0/20 and data-c 10.20.128.0/20. Below them, the '
        'main route table, which all nine use for now, holds one route: 10.20.0.0/16 to local. '
        'The public tier is drawn with an amber edge because lesson 17 makes it public; today its '
        'route table is the same as everybody else\'s.',
        'A VPC de produção da loja, shop-prod, 10.20.0.0/16, dentro da região sa-east-1. Ela se '
        'estende por três Availability Zones, sa-east-1a, b e c, cujos ids de zona são sae1-az1, '
        'az2 e az3. Cada zona tem três sub-redes, uma por camada: public, app e data. A zona a tem '
        'public-a 10.20.0.0/20, app-a 10.20.48.0/20 e data-a 10.20.96.0/20; a zona b tem public-b '
        '10.20.16.0/20, app-b 10.20.64.0/20 e data-b 10.20.112.0/20; a zona c tem public-c '
        '10.20.32.0/20, app-c 10.20.80.0/20 e data-c 10.20.128.0/20. Abaixo delas, a tabela de rotas '
        'principal, que as nove usam por enquanto, com uma rota: 10.20.0.0/16 para local. A camada '
        'pública tem borda âmbar porque a lição 17 a torna pública; hoje a tabela de rotas dela é a '
        'mesma de todas as outras.'))
    f.rect(16, 16, 688, 404, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(32, 34, 'sa-east-1', size=11, anchor='start', mono=True, fill='--paper-dim')
    f.rect(36, 48, 648, 356, stroke='--paper', fill='--ink', width=1.4)
    f.text(52, 66, 'shop-prod  10.20.0.0/16', size=11, anchor='start', mono=True)
    zones = [('sa-east-1a', 'sae1-az1', 'a', 0), ('sa-east-1b', 'sae1-az2', 'b', 16),
             ('sa-east-1c', 'sae1-az3', 'c', 32)]
    for k, (zone, zid, letter, base) in enumerate(zones):
        x = 56 + k * 206
        f.rect(x, 82, 192, 222, stroke='--wire', fill='--scan')
        f.text(x + 96, 98, zone, size=10.5, mono=True)
        f.text(x + 96, 113, zid, size=9.5, mono=True, fill='--paper-dim')
        for j, (tier, off) in enumerate((('public', 0), ('app', 48), ('data', 96))):
            y = 126 + j * 58
            pub = tier == 'public'
            f.rect(x + 14, y, 164, 48, stroke='--amber' if pub else '--wire', fill='--panel',
                   width=1.5 if pub else 1.2)
            f.text(x + 96, y + 16, f'{tier}-{letter}', size=10.5, mono=True,
                   fill='--amber' if pub else '--paper')
            f.text(x + 96, y + 33, f'10.20.{base + off}.0/20', size=9.5, mono=True,
                   fill='--paper-dim')
    f.rect(56, 320, 604, 66, stroke='--wire', fill='--panel')
    f.text(358, 340, T('main route table, used by all nine until lesson 17',
                       'tabela de rotas principal, usada pelas nove até a lição 17'),
           size=10.5, weight='600')
    f.text(358, 364, '10.20.0.0/16  →  local', size=10.5, mono=True)
    f.rect(140, 436, 22, 14, stroke='--amber', fill='--panel', width=1.5, rx=2)
    f.text(170, 443, T('public tier, once lesson 17 routes it', 'camada pública, quando a lição 17 a rotear'),
           size=10, anchor='start', fill='--paper-dim')
    f.rect(430, 436, 22, 14, stroke='--wire', fill='--panel', rx=2)
    f.text(460, 443, T('private tiers', 'camadas privadas'), size=10, anchor='start',
           fill='--paper-dim')
    return f, T('Nine subnets, three to a zone. Their names say what they are for; for now one route '
                'table says the same thing to all of them.',
                'Nove sub-redes, três por zona. Os nomes dizem para que servem; por enquanto uma '
                'tabela de rotas diz a mesma coisa para todas.')
