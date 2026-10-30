"""Lesson 5: Blueprints, landing zones and the Cloud Adoption Framework."""
from figures import Fig, T, figure


@figure('l05-platform-workload', 5)
def platform_workload():
    f = Fig('l05-platform-workload', 720, 260, T(
        'A landing zone in two halves. At the top, the platform landing zone, built once by the platform '
        'team: the management group tree and its policies, identity, the hub network connected to the '
        'office, and central logs. Below it, two workload landing zones, the subscriptions shop-prod '
        'and shop-staging, each handed to the shop\'s team inside the platform\'s guardrails.',
        'Uma landing zone em duas metades. Em cima, a platform landing zone, construída uma vez pela '
        'equipe de plataforma: a árvore de grupos de gerenciamento e as políticas dela, identidade, a '
        'rede hub ligada ao escritório, e os logs centrais. Embaixo, duas workload landing zones, as '
        'assinaturas shop-prod e shop-staging, cada uma entregue à equipe da loja dentro das barreiras '
        'da plataforma.'))
    f.rect(20, 20, 680, 110, stroke='--phosphor', fill='--panel')
    f.text(360, 40, T('platform landing zone: built once, for everybody', 'platform landing zone: construída uma vez, para todos'),
           size=10.5, weight='600')
    items = [T('tree and policies', 'árvore e políticas'), T('identity', 'identidade'),
             T('hub network', 'rede hub'), T('central logs', 'logs centrais')]
    for i, it in enumerate(items):
        x = 40 + i * 165
        f.rect(x, 60, 150, 50, stroke='--wire', fill='--ink')
        f.text(x + 75, 85, it, size=10)
    for i, (sub, who) in enumerate([('shop-prod', T('workload landing zone', 'workload landing zone')),
                                     ('shop-staging', T('workload landing zone', 'workload landing zone'))]):
        x = 110 + i * 280
        f.arrow([(x + 110, 132), (x + 110, 158)], stroke='--paper-dim')
        f.rect(x, 160, 220, 80, stroke='--amber', fill='--panel')
        f.text(x + 110, 185, who, size=10, fill='--paper-dim')
        f.text(x + 110, 210, sub, size=11, mono=True)
    return f, T('The platform is decided once; each workload gets a subscription that arrives inside it.',
                'A plataforma é decidida uma vez; cada carga de trabalho ganha uma assinatura que já chega dentro dela.')


@figure('l05-alz-tree', 5)
def alz_tree():
    f = Fig('l05-alz-tree', 720, 330, T(
        'The Cloud Adoption Framework\'s management group tree, with the shop\'s names. Under the tenant '
        'root group sits the intermediate root, shop. Under it: shop-platform, with shop-security, '
        'shop-management, shop-connectivity and shop-identity; shop-landingzones, with shop-corp and '
        'shop-online; shop-sandbox; and shop-decommissioned. The subscription shop-shared sits under '
        'shop-connectivity; shop-prod and shop-staging sit side by side under shop-online.',
        'A árvore de grupos de gerenciamento do Cloud Adoption Framework, com os nomes da loja. Debaixo '
        'do grupo raiz do tenant fica a raiz intermediária, shop. Debaixo dela: shop-platform, com '
        'shop-security, shop-management, shop-connectivity e shop-identity; shop-landingzones, com '
        'shop-corp e shop-online; shop-sandbox; e shop-decommissioned. A assinatura shop-shared fica '
        'debaixo de shop-connectivity; shop-prod e shop-staging ficam lado a lado debaixo de shop-online.'))
    f.rect(280, 14, 160, 28, stroke='--wire', fill='--scan')
    f.text(360, 28, T('tenant root group', 'grupo raiz do tenant'), size=9.5)
    f.line(360, 42, 360, 54, stroke='--paper-dim')
    f.rect(310, 54, 100, 28, stroke='--wire', fill='--scan')
    f.text(360, 68, 'shop', size=10.5, mono=True)
    tops = [(110, 'shop-platform'), (330, 'shop-landingzones'), (510, 'shop-sandbox'), (640, 'shop-decommissioned')]
    f.line(360, 82, 360, 96, stroke='--paper-dim')
    f.line(110, 96, 640, 96, stroke='--paper-dim')
    for x, n in tops:
        w = 9.5 * 0.6 * len(n) + 20
        f.line(x, 96, x, 108, stroke='--paper-dim')
        f.rect(x - w / 2, 108, w, 28, stroke='--wire', fill='--scan')
        f.text(x, 122, n, size=9.5, mono=True)
    plat = ['shop-security', 'shop-management', 'shop-connectivity', 'shop-identity']
    f.line(40, 150, 40, 150 + 3 * 38 + 14, stroke='--paper-dim')
    f.line(110, 136, 110, 150, stroke='--paper-dim')
    f.line(40, 150, 110, 150, stroke='--paper-dim')
    for i, n in enumerate(plat):
        y = 164 + i * 38
        f.line(40, y, 56, y, stroke='--paper-dim')
        f.rect(56, y - 13, 130, 26, stroke='--wire', fill='--scan')
        f.text(121, y, n, size=9.5, mono=True)
    f.rect(196, 227, 100, 26, stroke='--amber', fill='--panel')
    f.text(246, 240, 'shop-shared', size=9.5, mono=True)
    f.line(187, 240, 195, 240, stroke='--amber')
    for i, n in enumerate(['shop-corp', 'shop-online']):
        x = 290 + i * 100
        f.line(330, 136, 330, 150, stroke='--paper-dim')
        f.line(290, 150, 390, 150, stroke='--paper-dim')
        f.line(x, 150, x, 164, stroke='--paper-dim')
        f.rect(x - 45, 164, 90, 26, stroke='--wire', fill='--scan')
        f.text(x, 177, n, size=9.5, mono=True)
    f.line(390, 190, 390, 216, stroke='--paper-dim')
    f.rect(320, 216, 140, 64, stroke='--wire', fill='--ink', dash='4 3')
    f.rect(330, 224, 120, 22, stroke='--amber', fill='--panel')
    f.text(390, 235, 'shop-prod', size=9.5, mono=True)
    f.rect(330, 250, 120, 22, stroke='--amber', fill='--panel')
    f.text(390, 261, 'shop-staging', size=9.5, mono=True)
    f.text(590, 240, T('production and staging:', 'produção e staging:'), size=10, fill='--paper')
    f.text(590, 260, T('one group, the same rules', 'um grupo, as mesmas regras'), size=10, fill='--amber')
    return f, T('Split by what a workload needs from the platform, never by environment.',
                'Dividida pelo que uma carga de trabalho precisa da plataforma, nunca por ambiente.')
