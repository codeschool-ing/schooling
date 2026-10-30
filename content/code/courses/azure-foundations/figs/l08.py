"""Lesson 8: managed identities."""
from figures import Fig, T, figure


@figure('l08-two-kinds', 8)
def two_kinds():
    f = Fig('l08-two-kinds', 720, 280, T(
        'Two kinds of managed identity compared by lifetime. On the left, the web app app-shop-prod '
        'contains its system-assigned identity inside its own box: deleting the app deletes the identity '
        'and its roles. On the right, the user-assigned identity id-shop-app is a box of its own, attached '
        'to two web apps by lines; deleting either app leaves the identity and its roles in place.',
        'Dois tipos de identidade gerenciada comparados pelo tempo de vida. À esquerda, o web app '
        'app-shop-prod contém a sua identidade atribuída pelo sistema dentro da própria caixa: apagar o '
        'app apaga a identidade e os papéis dela. À direita, a identidade atribuída pelo usuário '
        'id-shop-app é uma caixa própria, ligada a dois web apps por linhas; apagar qualquer um dos apps '
        'deixa a identidade e os papéis dela no lugar.'))
    f.text(175, 26, T('system-assigned', 'atribuída pelo sistema'), size=11, weight='600')
    f.rect(40, 50, 270, 150, stroke='--wire', fill='--panel')
    f.text(175, 70, 'app-shop-prod', size=10.5, mono=True)
    f.rect(75, 96, 200, 74, stroke='--amber', fill='--scan')
    f.text(175, 118, T('its identity', 'a identidade dele'), size=10)
    f.text(175, 142, T('and its roles', 'e os papéis dela'), size=10, fill='--paper-dim')
    f.text(175, 236, T('delete the app: both go', 'apague o app: os dois vão embora'), size=10, fill='--amber')
    f.text(530, 26, T('user-assigned', 'atribuída pelo usuário'), size=11, weight='600')
    f.rect(430, 50, 200, 60, stroke='--amber', fill='--scan')
    f.text(530, 72, 'id-shop-app', size=10.5, mono=True)
    f.text(530, 92, T('and its roles', 'e os papéis dela'), size=10, fill='--paper-dim')
    for x, name in [(380, 'app-shop-prod'), (580, 'app-shop-prod-2')]:
        f.rect(x - 15, 150, 150 if x == 380 else 125, 50, stroke='--wire', fill='--panel')
        f.text(x + (60 if x == 380 else 47), 175, name, size=9.5, mono=True)
    f.line(470, 111, 445, 149, stroke='--paper-dim', dash='4 3')
    f.line(590, 111, 615, 149, stroke='--paper-dim', dash='4 3')
    f.text(530, 236, T('delete an app: the identity stays', 'apague um app: a identidade fica'), size=10,
           fill='--phosphor')
    return f, T('The question is whose lifetime the identity follows: one resource\'s, or its own.',
                'A pergunta é de quem é o tempo de vida que a identidade segue: o de um recurso, ou o seu próprio.')


@figure('l08-imds', 8)
def imds():
    f = Fig('l08-imds', 720, 270, T(
        'How code on an Azure virtual machine gets a token without holding a credential. Inside the '
        'virtual machine, the application asks the Instance Metadata Service at 169.254.169.254, which '
        'only that machine can reach. The platform, outside the machine, obtains a token from Entra ID '
        'for the machine\'s managed identity and hands it back. The application then calls the storage '
        'account with the token. No credential ever enters the machine.',
        'Como o código numa máquina virtual do Azure obtém um token sem guardar credencial. Dentro da '
        'máquina virtual, a aplicação pergunta ao Instance Metadata Service em 169.254.169.254, que só '
        'aquela máquina alcança. A plataforma, fora da máquina, obtém do Entra ID um token para a '
        'identidade gerenciada da máquina e o devolve. A aplicação então chama a storage account com o '
        'token. Nenhuma credencial entra na máquina.'))
    f.text(135, 56, T('on the virtual machine', 'na máquina virtual'), size=9.5, fill='--paper-dim')
    f.text(605, 56, T('outside it', 'fora dela'), size=9.5, fill='--paper-dim')
    f.rect(50, 70, 170, 50, stroke='--wire', fill='--panel')
    f.text(135, 95, T('the application', 'a aplicação'), size=10.5)
    f.rect(290, 70, 170, 50, stroke='--amber', fill='--scan')
    f.text(375, 88, T('metadata service', 'serviço de metadados'), size=10)
    f.text(375, 106, '169.254.169.254', size=9.5, mono=True)
    f.rect(520, 70, 170, 50, stroke='--phosphor', fill='--panel')
    f.text(605, 95, 'Entra ID', size=10.5, weight='600')
    f.rect(520, 180, 170, 50, stroke='--wire', fill='--panel')
    f.text(605, 205, 'stshopassetsprod', size=10, mono=True)
    f.arrow([(221, 88), (289, 88)], stroke='--amber', width=1.4)
    f.arrow([(461, 88), (519, 88)], stroke='--paper-dim', width=1.2)
    f.arrow([(519, 104), (461, 104)], stroke='--paper-dim', width=1.2)
    f.arrow([(289, 104), (221, 104)], stroke='--amber', width=1.4)
    f.text(255, 140, T('1 ask, 4 token', '1 pede, 4 token'), size=9.5, fill='--amber')
    f.text(490, 140, T('2, 3 the platform signs in', '2, 3 a plataforma faz login'), size=9.5, fill='--paper-dim')
    f.arrow([(135, 121), (135, 205), (519, 205)], stroke='--phosphor', width=1.4)
    f.text(330, 196, T('5 the call, with the token', '5 a chamada, com o token'), size=9.5, fill='--phosphor')
    return f, T('The credential stays with the platform; only a token reaches the application.',
                'A credencial fica com a plataforma; só um token chega à aplicação.')
