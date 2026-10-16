"""Lesson 7: where each kind of policy lives."""
from figures import Fig, T, figure


@figure('l07-three-kinds', 7)
def three_kinds():
    f = Fig('l07-three-kinds', 720, 320, T(
        'Where each kind of policy lives. On the left, outside the shop\'s account, AWS\'s library: '
        'the AWS-managed policy ReadOnlyAccess, at version v188 and edited by AWS, attached to the '
        'user caio inside the shop\'s account. Inside the account 123456789012, the customer-managed '
        'policy shop-assets-rw, with up to five versions and one default, attached at once to the '
        'user bia, the group developers and the role deployer. At the bottom right, the user edu '
        'with an inline policy embedded in it, which has no ARN and is deleted with edu.',
        'Onde mora cada tipo de política. À esquerda, fora da conta da loja, a biblioteca da AWS: a '
        'política gerenciada pela AWS ReadOnlyAccess, na versão v188 e editada pela AWS, anexada ao '
        'usuário caio dentro da conta da loja. Dentro da conta 123456789012, a política gerenciada '
        'pelo cliente shop-assets-rw, com até cinco versões e uma padrão, anexada ao mesmo tempo à '
        'usuária bia, ao grupo developers e à role deployer. Embaixo à direita, o usuário edu com uma '
        'política inline embutida nele, que não tem ARN e é apagada junto com o edu.'))
    # AWS's library
    f.rect(20, 40, 200, 120, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(120, 56, T('AWS-managed', 'gerenciada pela AWS'), size=10.5, weight='600',
           fill='--paper-dim')
    f.rect(40, 70, 160, 56, stroke='--paper-dim', fill='--panel')
    f.text(120, 88, 'ReadOnlyAccess', size=10.5, mono=True)
    f.text(120, 108, T('v188, edited by AWS', 'v188, editada pela AWS'), size=9.5, fill='--paper-dim')
    f.text(120, 146, T('the same in every account', 'a mesma em toda conta'), size=9.5,
           fill='--paper-dim', italic=True)
    # the shop's account
    f.rect(250, 20, 450, 290, stroke='--phosphor', fill='--ink')
    f.text(266, 36, 'account 123456789012', size=10, mono=True, anchor='start', fill='--paper-dim')
    # customer-managed
    f.text(365, 60, T('customer-managed', 'gerenciada pelo cliente'), size=10.5, weight='600',
           fill='--amber')
    f.rect(280, 72, 170, 66, stroke='--amber', fill='--panel', width=1.4)
    f.text(365, 92, 'shop-assets-rw', size=10.5, mono=True)
    f.text(365, 116, T('5 versions at most, 1 default', 'até 5 versões, 1 padrão'), size=9.5,
           fill='--paper-dim')
    for y, who in ((70, 'user/bia'), (110, 'group/developers'), (150, 'role/deployer')):
        f.rect(530, y - 15, 150, 30, stroke='--wire', fill='--panel')
        f.text(605, y, who, size=10, mono=True)
        f.arrow([(452, 105), (528, y)], stroke='--amber', width=1.2)
    # the AWS-managed one attached to caio, in pieces at each edge it crosses
    f.rect(280, 175, 170, 30, stroke='--wire', fill='--panel')
    f.text(365, 190, 'user/caio', size=10, mono=True)
    f.line(120, 127, 120, 160, stroke='--paper-dim', width=1.2)
    f.path('M120.0 160.0 L120.0 190.0 L250.0 190.0', stroke='--paper-dim', width=1.2)
    f.arrow([(250, 190), (278, 190)], stroke='--paper-dim', width=1.2)
    f.text(185, 180, T('attached', 'anexada'), size=9.5, fill='--paper-dim')
    # inline
    f.rect(470, 205, 210, 90, stroke='--phosphor', fill='--panel')
    f.text(575, 222, 'user/edu', size=10.5, mono=True)
    f.rect(490, 236, 170, 46, stroke='--amber', fill='--scan', dash='4 3')
    f.text(575, 252, T('inline policy, no ARN', 'política inline, sem ARN'), size=9.5)
    f.text(575, 268, T('deleted with edu', 'apagada junto com o edu'), size=9.5, fill='--amber')
    return f, T('An AWS-managed policy is shared by every account, a customer-managed one by '
                'everything it is attached to, and an inline one by nothing.',
                'Uma política gerenciada pela AWS é compartilhada por toda conta, uma gerenciada pelo '
                'cliente por tudo a que está anexada, e uma inline por nada.')
