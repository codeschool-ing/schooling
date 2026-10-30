"""Lesson 2: tenant, management groups, subscriptions and resource groups."""
from figures import Fig, T, figure


@figure('l02-hierarchy', 2)
def hierarchy():
    f = Fig('l02-hierarchy', 720, 390, T(
        'The shop\'s hierarchy as four nested kinds of box. The tenant, shop.onmicrosoft.com, holds '
        'the root management group. Under it hangs mg-shop, and under that three management groups: '
        'mg-shop-prod, mg-shop-nonprod and mg-shop-platform. Each holds one subscription: shop-prod, '
        'shop-staging and shop-shared. Inside shop-prod sit two resource groups, rg-shop-prod-app and '
        'rg-shop-prod-data, and inside those the resources. A note says that identity lives in the '
        'tenant and money in the subscription.',
        'A hierarquia da loja como quatro tipos de caixa, uma dentro da outra. O tenant, '
        'shop.onmicrosoft.com, guarda o grupo de gerenciamento raiz. Debaixo dele fica mg-shop, e '
        'debaixo deste três grupos de gerenciamento: mg-shop-prod, mg-shop-nonprod e mg-shop-platform. '
        'Cada um guarda uma assinatura: shop-prod, shop-staging e shop-shared. Dentro de shop-prod ficam '
        'dois grupos de recursos, rg-shop-prod-app e rg-shop-prod-data, e dentro deles os recursos. Uma '
        'nota diz que a identidade mora no tenant e o dinheiro na assinatura.'))
    f.rect(20, 14, 680, 362, stroke='--phosphor', fill='--ink')
    f.text(36, 32, T('tenant', 'tenant'), size=9.5, anchor='start', fill='--phosphor')
    f.text(684, 32, 'shop.onmicrosoft.com', size=10, anchor='end', mono=True)
    # root and mg-shop
    f.rect(270, 46, 180, 34, stroke='--wire', fill='--scan')
    f.text(360, 63, T('root management group', 'grupo de gerenciamento raiz'), size=9.5)
    f.line(360, 80, 360, 96, stroke='--paper-dim')
    f.rect(290, 96, 140, 30, stroke='--wire', fill='--scan')
    f.text(360, 111, 'mg-shop', size=10.5, mono=True)
    cols = [(125, 'mg-shop-prod', 'shop-prod'), (360, 'mg-shop-nonprod', 'shop-staging'),
            (595, 'mg-shop-platform', 'shop-shared')]
    f.line(125, 142, 595, 142, stroke='--paper-dim')
    f.line(360, 126, 360, 142, stroke='--paper-dim')
    for x, mg, sub in cols:
        f.line(x, 142, x, 154, stroke='--paper-dim')
        f.rect(x - 80, 154, 160, 30, stroke='--wire', fill='--scan')
        f.text(x, 169, mg, size=10.5, mono=True)
        f.line(x, 184, x, 198, stroke='--paper-dim')
        f.rect(x - 98, 198, 196, 36 if x != 125 else 150, stroke='--amber', fill='--panel')
        f.text(x - 88, 214, T('subscription', 'assinatura'), size=9, anchor='start', fill='--paper-dim')
        f.text(x + 88, 214, sub, size=10.5, anchor='end', mono=True)
    for i, (rg, res) in enumerate([('rg-shop-prod-app', 'vnet-shop-prod'), ('rg-shop-prod-data', 'sql-shop-prod')]):
        y = 228 + i * 58
        f.rect(40, y, 170, 48, stroke='--wire', fill='--ink', dash='4 3')
        f.text(125, y + 14, rg, size=9.5, mono=True)
        f.text(125, y + 33, res, size=9.5, mono=True, fill='--paper-dim')
    f.text(470, 300, T('identity lives in the tenant', 'a identidade mora no tenant'),
           size=10.5, fill='--phosphor')
    f.text(470, 324, T('money lives in the subscription', 'o dinheiro mora na assinatura'),
           size=10.5, fill='--amber')
    f.text(470, 348, T('resource groups do not nest', 'grupos de recursos não se aninham'),
           size=10, fill='--paper-dim')
    return f, T('Four kinds of box. The tree in the middle can be six levels deep; the shop needs two.',
                'Quatro tipos de caixa. A árvore do meio pode ter seis níveis; a loja precisa de dois.')


@figure('l02-resource-id', 2)
def resource_id():
    segs = [('/subscriptions/', None), ('bbbbcccc-1111-dddd-2222-eeee3333ffff', 'sub'),
            ('/resourceGroups/', None), ('rg-shop-prod', 'rg'), ('/providers/', None),
            ('Microsoft.Network', 'ns'), ('/', None), ('virtualNetworks', 'type'), ('/', None),
            ('vnet-shop-prod', 'name'), ('/', None), ('subnets/snet-app', 'child')]
    f = Fig('l02-resource-id', 720, 250, T(
        'A subnet\'s resource id cut into its pieces, on two lines: the subscription id '
        'bbbbcccc-1111-dddd-2222-eeee3333ffff, the resource group rg-shop-prod, the provider namespace '
        'Microsoft.Network, the type virtualNetworks, the name vnet-shop-prod, and the child '
        'subnets/snet-app. The literal words subscriptions, resourceGroups and providers separate them.',
        'O id de recurso de uma sub-rede cortado nas suas peças, em duas linhas: o id da assinatura '
        'bbbbcccc-1111-dddd-2222-eeee3333ffff, o grupo de recursos rg-shop-prod, o namespace do provider '
        'Microsoft.Network, o tipo virtualNetworks, o nome vnet-shop-prod, e o filho subnets/snet-app. '
        'As palavras literais subscriptions, resourceGroups e providers os separam.'))
    labels = {'sub': T('subscription', 'assinatura'), 'rg': T('resource group', 'grupo de recursos'),
              'ns': T('provider namespace', 'namespace do provider'), 'type': T('type', 'tipo'),
              'name': T('name', 'nome'), 'child': T('child resource', 'recurso filho')}
    lines = [segs[:4], segs[4:]]
    cw = 7.3
    for li, line in enumerate(lines):
        y = 60 + li * 110
        total = sum(len(s) for s, _ in line) * cw
        x = (720 - total) / 2
        for s, k in line:
            w = len(s) * cw
            if k:
                fill = '--amber' if k == 'sub' else '--phosphor' if k == 'child' else '--wire'
                f.rect(x - 2, y - 13, w + 4, 26, stroke=fill, fill='--panel')
                f.text(x + w / 2, y + 34, labels[k], size=9.5, fill='--paper-dim')
            f.text(x + w / 2, y, s, size=11, mono=True, fill='--paper' if k else '--paper-dim')
            x += w
    return f, T('Read from the left, an id walks down the boxes: subscription, group, provider, type, name.',
                'Lido da esquerda, um id desce pelas caixas: assinatura, grupo, provider, tipo, nome.')
