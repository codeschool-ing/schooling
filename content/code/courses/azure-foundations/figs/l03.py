"""Lesson 3: which resources move between resource groups, and which never do."""
from figures import Fig, T, figure


@figure('l03-three-moves', 3)
def three_moves():
    f = Fig('l03-three-moves', 720, 300, T(
        'Three kinds of move compared in three columns. A resource moved to another resource group: '
        'its id changes, its region does not, and both groups are locked while it moves. A resource '
        'moved to another subscription: its id changes, its region does not, both subscriptions must '
        'trust the same tenant, and its dependencies move with it. A subscription moved to another '
        'management group: no id changes and nothing is locked, but what it inherits changes at once.',
        'Três tipos de movimento comparados em três colunas. Um recurso movido para outro grupo de '
        'recursos: o id muda, a região não, e os dois grupos ficam travados enquanto ele se move. Um '
        'recurso movido para outra assinatura: o id muda, a região não, as duas assinaturas precisam '
        'confiar no mesmo tenant, e as dependências vão junto. Uma assinatura movida para outro grupo '
        'de gerenciamento: nenhum id muda e nada é travado, mas o que ela herda muda na hora.'))
    cols = [
        (T('a resource, to another group', 'um recurso, para outro grupo'), '--wire',
         [(T('id changes', 'o id muda'), '--amber'), (T('region stays', 'a região fica'), '--paper'),
          (T('both groups locked', 'os dois grupos travados'), '--paper'),
          (T('own role assignments lost', 'atribuições próprias perdidas'), '--paper')]),
        (T('a resource, to another subscription', 'um recurso, para outra assinatura'), '--amber',
         [(T('id changes', 'o id muda'), '--amber'), (T('region stays', 'a região fica'), '--paper'),
          (T('same tenant required', 'mesmo tenant exigido'), '--paper'),
          (T('dependencies go together', 'dependências vão juntas'), '--paper')]),
        (T('a subscription, to another group', 'uma assinatura, para outro grupo'), '--phosphor',
         [(T('no id changes', 'nenhum id muda'), '--paper'), (T('nothing locked', 'nada travado'), '--paper'),
          (T('inheritance changes', 'a herança muda'), '--amber'),
          (T('at once, for everything in it', 'na hora, para tudo dentro dela'), '--paper')]),
    ]
    for i, (title, edge, rows) in enumerate(cols):
        x = 20 + i * 232
        f.rect(x, 20, 216, 260, stroke=edge, fill='--panel')
        f.lines(x + 108, 52, [title], size=10.5, weight='600')
        f.line(x + 16, 78, x + 200, 78, stroke='--wire')
        for j, (label, fill) in enumerate(rows):
            f.text(x + 108, 110 + j * 44, label, size=10, fill=fill)
    return f, T('Two kinds of move rename a resource; the third renames nothing and changes the rules.',
                'Dois tipos de movimento renomeiam um recurso; o terceiro não renomeia nada e muda as regras.')


@figure('l03-cross-subscription', 3)
def cross_subscription():
    f = Fig('l03-cross-subscription', 720, 300, T(
        'Moving a virtual machine to another subscription in three steps. Before: the machine is in '
        'rg-shop-prod-app and its network in rg-shop-prod-network, both in shop-prod. Step 1, gather: '
        'the network is moved into rg-shop-prod-app, inside shop-prod. Step 2, move: the whole group\'s '
        'worth, machine, disk, interface and network, moves to shop-shared in one request. Step 3, '
        'spread: at the destination they may be split into groups again.',
        'Mover uma máquina virtual para outra assinatura em três passos. Antes: a máquina está em '
        'rg-shop-prod-app e a rede em rg-shop-prod-network, os dois em shop-prod. Passo 1, juntar: a '
        'rede é movida para rg-shop-prod-app, dentro de shop-prod. Passo 2, mover: tudo o que está no '
        'grupo, máquina, disco, interface e rede, vai para shop-shared num pedido só. Passo 3, '
        'espalhar: no destino eles podem ser divididos em grupos de novo.'))
    steps = [T('before', 'antes'), T('1  gathered', '1  juntados'), T('2  moved, 3  spread', '2  movidos, 3  espalhados')]
    xs = [20, 260, 500]
    for i, x in enumerate(xs):
        sub = 'shop-prod' if i < 2 else 'shop-shared'
        f.text(x + 100, 26, steps[i], size=11, weight='600', fill='--amber' if i == 2 else '--paper')
        f.rect(x, 44, 200, 236, stroke='--amber', fill='--panel')
        f.text(x + 186, 62, sub, size=10, anchor='end', mono=True)
        f.text(x + 14, 62, T('subscription', 'assinatura'), size=9, anchor='start', fill='--paper-dim')
        if i == 0:
            groups = [('rg-shop-prod-app', ['vm-shop-1', 'disk', 'nic']), ('rg-shop-prod-network', ['vnet-shop-prod'])]
        elif i == 1:
            groups = [('rg-shop-prod-app', ['vm-shop-1', 'disk', 'nic', 'vnet-shop-prod'])]
        else:
            groups = [('rg-shop-app', ['vm-shop-1', 'disk', 'nic']), ('rg-shop-network', ['vnet-shop-prod'])]
        y = 80
        for name, items in groups:
            h = 30 + len(items) * 20
            f.rect(x + 12, y, 176, h, stroke='--wire', fill='--ink', dash='4 3')
            f.text(x + 100, y + 15, name, size=9.5, mono=True)
            for k, it in enumerate(items):
                f.text(x + 100, y + 36 + k * 20, it, size=9.5, mono=True, fill='--paper-dim')
            y += h + 12
    f.arrow([(222, 160), (258, 160)], stroke='--paper-dim')
    f.arrow([(462, 160), (498, 160)], stroke='--amber', width=1.6)
    return f, T('Across subscriptions a machine travels with its disk, its interface and its network, in one request.',
                'Entre assinaturas, uma máquina viaja com o disco, a interface e a rede, num pedido só.')
