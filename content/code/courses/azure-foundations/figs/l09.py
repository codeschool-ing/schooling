"""Lesson 9: RBAC, built-in roles, custom roles, scope and inheritance."""
from figures import Fig, T, figure


@figure('l09-additive', 9)
def additive():
    f = Fig('l09-additive', 720, 300, T(
        'Two role assignments held by the same person, added together. Contributor allows every '
        'operation except those under Microsoft.Authorization, which its notActions remove. User Access '
        'Administrator allows Microsoft.Authorization operations. The person\'s effective permissions '
        'are the union: everything, including writing role assignments. The notActions of Contributor '
        'removed the operation from Contributor only, not from the person.',
        'Duas atribuições de papel da mesma pessoa, somadas. Contributor permite toda operação menos as '
        'de Microsoft.Authorization, que os notActions dele removem. User Access Administrator permite as '
        'operações de Microsoft.Authorization. As permissões efetivas da pessoa são a união: tudo, '
        'inclusive escrever atribuições de papel. Os notActions do Contributor removeram a operação só '
        'do Contributor, não da pessoa.'))
    def role(x, title, allows, minus, wide):
        f.rect(x, 30, 200, 150, stroke='--wire', fill='--panel')
        f.text(x + 100, 50, title, size=11, weight='600')
        f.text(x + 16, 80, T('allows', 'permite'), size=9.5, anchor='start', fill='--paper-dim')
        f.text(x + 100, 100, allows, size=10.5, mono=True)
        f.text(x + 16, 130, T('removes', 'remove'), size=9.5, anchor='start', fill='--paper-dim')
        f.text(x + 100, 150, minus, size=10, mono=True)
    role(30, 'Contributor', '*', 'Microsoft.Authorization/*/Write', True)
    f.text(255, 105, '+', size=22, weight='600', fill='--paper-dim')
    role(280, 'User Access Administrator', 'Microsoft.Authorization/*', T('nothing', 'nada'), False)
    f.text(505, 105, '=', size=22, weight='600', fill='--paper-dim')
    f.rect(530, 30, 160, 150, stroke='--amber', fill='--panel')
    f.text(610, 50, T('effective', 'efetivo'), size=11, weight='600', fill='--amber')
    f.lines(610, 105, [T('every operation,', 'toda operação,'), T('role assignments', 'atribuições de'),
                       T('included', 'papel incluídas')], size=10.5)
    f.text(360, 225, T('notActions takes away from its own role, not from the person',
                       'notActions tira do próprio papel, não da pessoa'), size=10.5, fill='--amber')
    f.text(360, 252, T('only a deny assignment takes away from everything',
                       'só uma deny assignment tira de tudo'), size=10, fill='--paper-dim')
    return f, T('Roles are added together. A not-action narrows its own role and nothing else.',
                'Papéis se somam. Um not-action estreita o próprio papel e nada mais.')


@figure('l09-scope', 9)
def scope():
    f = Fig('l09-scope', 720, 330, T(
        'Inheritance of a role assignment down lesson 2\'s boxes. Reader is assigned to a group at the '
        'subscription shop-prod. It reaches the resource groups rg-shop-prod-app and rg-shop-prod-data '
        'and every resource in them, but not the management group mg-shop-prod above the subscription, '
        'nor the subscription shop-staging beside it.',
        'Herança de uma atribuição de papel pelas caixas da lição 2. Reader é atribuído a um grupo na '
        'assinatura shop-prod. Ele alcança os grupos de recursos rg-shop-prod-app e rg-shop-prod-data e '
        'todo recurso dentro deles, mas não o grupo de gerenciamento mg-shop-prod acima da assinatura, '
        'nem a assinatura shop-staging ao lado.'))
    f.rect(220, 20, 200, 36, stroke='--wire', fill='--scan')
    f.text(320, 38, 'mg-shop-prod', size=10.5, mono=True)
    f.text(440, 38, T('not reached', 'não alcançado'), size=9.5, anchor='start', fill='--paper-dim')
    f.line(320, 56, 320, 84, stroke='--paper-dim')
    f.rect(200, 84, 240, 44, stroke='--amber', fill='--panel', width=2)
    f.text(320, 99, 'shop-prod', size=10.5, mono=True)
    f.text(320, 116, T('Reader assigned here', 'Reader atribuído aqui'), size=9.5, fill='--amber')
    f.rect(500, 84, 190, 44, stroke='--wire', fill='--panel', dash='4 3')
    f.text(595, 99, 'shop-staging', size=10.5, mono=True)
    f.text(595, 116, T('not reached', 'não alcançado'), size=9.5, fill='--paper-dim')
    for i, (rg, res) in enumerate([('rg-shop-prod-app', 'vnet-shop-prod'), ('rg-shop-prod-data', 'sql-shop-prod')]):
        x = 110 + i * 240
        f.arrow([(320, 129), (320, 150), (x + 90, 150), (x + 90, 172)], stroke='--amber', width=1.4)
        f.rect(x, 172, 180, 40, stroke='--wire', fill='--ink', dash='4 3')
        f.text(x + 90, 192, rg, size=10, mono=True)
        f.arrow([(x + 90, 213), (x + 90, 240)], stroke='--amber', width=1.4)
        f.rect(x + 10, 240, 160, 36, stroke='--wire', fill='--panel')
        f.text(x + 90, 258, res, size=10, mono=True)
    f.text(360, 306, T('an assignment reaches down, never up and never sideways',
                       'uma atribuição alcança para baixo, nunca para cima nem para o lado'),
           size=10.5, fill='--paper-dim')
    return f, T('Reader on the subscription is Reader on everything inside it, and on nothing else.',
                'Reader na assinatura é Reader em tudo dentro dela, e em nada mais.')
