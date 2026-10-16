"""Lesson 11: IAM Identity Center and an external identity provider."""
from figures import Fig, T, figure


@figure('l11-federation', 11)
def federation():
    f = Fig('l11-federation', 720, 330, T(
        'How a person reaches an account through Identity Center. Caio signs in, with his second '
        'factor, at the identity provider, Google Workspace. The provider talks to IAM Identity '
        'Center in two ways: SAML says who is signing in at that moment, and SCIM says ahead of time '
        'which users and groups exist. Identity Center provisions a role into each account an '
        'assignment names: AWSReservedSSO_ReadOnly in shop-prod, AWSReservedSSO_Developer in '
        'shop-staging, and so on. No account holds a user for him.',
        'Como uma pessoa chega a uma conta pelo Identity Center. O Caio faz login, com o segundo '
        'fator, no provedor de identidade, o Google Workspace. O provedor fala com o IAM Identity '
        'Center de dois jeitos: o SAML diz quem está entrando naquele momento, e o SCIM diz de '
        'antemão quais usuários e grupos existem. O Identity Center provisiona uma role em cada conta '
        'que uma atribuição nomeia: AWSReservedSSO_ReadOnly em shop-prod, AWSReservedSSO_Developer em '
        'shop-staging, e assim por diante. Nenhuma conta guarda um usuário para ele.'))
    f.rect(30, 30, 150, 44, stroke='--paper-dim', fill='--panel', rx=20)
    f.text(105, 52, T('caio, in a browser', 'caio, num navegador'), size=10.5, weight='600')
    f.line(105, 76, 105, 148, stroke='--phosphor', width=1.4, arrow=True)
    f.text(115, 112, T('signs in, with MFA', 'faz login, com MFA'), size=10, anchor='start',
           fill='--phosphor')
    f.rect(30, 150, 150, 74, stroke='--wire', fill='--scan')
    f.text(105, 176, T('identity provider', 'provedor de identidade'), size=10.5, weight='600')
    f.text(105, 198, 'Google Workspace', size=10, fill='--paper-dim')
    f.rect(280, 140, 170, 94, stroke='--phosphor', fill='--scan', width=1.5)
    f.text(365, 172, 'IAM Identity Center', size=11, weight='600')
    f.lines(365, 202, [T('permission sets', 'permission sets'), T('and assignments', 'e atribuições')],
            size=9.5, fill='--paper-dim')
    f.arrow([(182, 166), (278, 166)], stroke='--phosphor', width=1.4)
    f.text(230, 155, T('SAML: who, now', 'SAML: quem, agora'), size=9.5, fill='--phosphor')
    f.arrow([(182, 210), (278, 210)], stroke='--amber', width=1.4)
    f.lines(230, 228, [T('SCIM: who', 'SCIM: quem'), T('exists', 'existe')], size=9.5, fill='--amber')
    accounts = [(60, 'shop-prod', 'AWSReservedSSO_ReadOnly_…'),
                (160, 'shop-staging', 'AWSReservedSSO_Developer_…'),
                (260, 'sandbox', 'AWSReservedSSO_…')]
    for y, name, role in accounts:
        f.rect(530, y - 32, 170, 64, stroke='--phosphor', fill='--panel')
        f.text(615, y - 12, name, size=10.5, mono=True, weight='600')
        f.text(615, y + 10, role, size=8.5, mono=True, fill='--paper-dim')
        f.arrow([(452, 187 + (y - 160) / 6), (527, y)], stroke='--paper-dim', width=1.2)
    f.text(365, 262, T('provisions one role per', 'provisiona uma role por'), size=9.5,
           fill='--paper-dim', italic=True)
    f.text(365, 277, T('assigned account', 'conta atribuída'), size=9.5, fill='--paper-dim',
           italic=True)
    f.text(360, 316, T('no account holds a user for a person', 'nenhuma conta guarda um usuário para uma pessoa'),
           size=10, fill='--amber')
    return f, T('The person lives at the identity provider; the accounts hold only roles that '
                'Identity Center manages.',
                'A pessoa mora no provedor de identidade; as contas guardam só roles que o Identity '
                'Center gerencia.')


@figure('l11-assignments', 11)
def assignments():
    f = Fig('l11-assignments', 720, 270, T(
        'The three assignments as a grid of groups against accounts. Developers, with Bia in it: '
        'ReadOnly in shop-prod and Developer in shop-staging. Data, with Caio in it: ReadOnly in '
        'shop-prod and nothing in shop-staging. Each filled cell is one assignment, and one role '
        'Identity Center creates in that account.',
        'As três atribuições como uma grade de grupos contra contas. Developers, com a Bia: ReadOnly '
        'em shop-prod e Developer em shop-staging. Data, com o Caio: ReadOnly em shop-prod e nada em '
        'shop-staging. Cada célula preenchida é uma atribuição, e uma role que o Identity Center '
        'cria naquela conta.'))
    cols = [(360, 'shop-prod'), (580, 'shop-staging')]
    rows = [(110, 'developers', 'bia'), (190, 'data', 'caio')]
    f.text(140, 40, T('group', 'grupo'), size=10, fill='--paper-dim', italic=True)
    for x, name in cols:
        f.rect(x - 95, 24, 190, 34, stroke='--phosphor', fill='--panel')
        f.text(x, 41, name, size=10.5, mono=True, weight='600')
    for y, g, who in rows:
        f.rect(40, y - 28, 200, 56, stroke='--wire', fill='--scan')
        f.text(140, y - 9, g, size=11, mono=True, weight='600')
        f.text(140, y + 12, who, size=9.5, mono=True, fill='--paper-dim')
    cells = {(110, 360): 'ReadOnly', (110, 580): 'Developer', (190, 360): 'ReadOnly'}
    for y, *_ in rows:
        for x, _ in cols:
            ps = cells.get((y, x))
            if ps:
                f.rect(x - 95, y - 28, 190, 56, stroke='--phosphor', fill='--panel', width=1.4)
                f.text(x, y - 7, ps, size=11, mono=True)
                f.text(x, y + 13, T('one assignment', 'uma atribuição'), size=9, fill='--paper-dim')
            else:
                f.rect(x - 95, y - 28, 190, 56, stroke='--wire', fill='--ink', dash='4 3')
                f.text(x, y, T('no access', 'sem acesso'), size=10, fill='--paper-dim', italic=True)
    f.text(360, 250, T('each filled cell: a group, a permission set, an account, and one role there',
                       'cada célula preenchida: um grupo, um permission set, uma conta, e uma role lá'),
           size=10, fill='--amber')
    return f, T('An assignment is a cell of this grid. A new developer joins a row, and gets every '
                'cell in it.',
                'Uma atribuição é uma célula desta grade. Um novo desenvolvedor entra numa linha, e '
                'recebe todas as células dela.')
