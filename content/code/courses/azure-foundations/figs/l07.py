"""Lesson 7: service principals and app registrations."""
from figures import Fig, T, figure


@figure('l07-app-and-sp', 7)
def app_and_sp():
    f = Fig('l07-app-and-sp', 720, 290, T(
        'One application registered in its home tenant, with one client id, and a service principal '
        'for it in each tenant that uses it: one in the home tenant and one in a customer\'s tenant. '
        'Each service principal has its own object id and receives its own roles; the client id is the '
        'same everywhere.',
        'Uma aplicação registrada no seu tenant de origem, com um client id, e um service principal '
        'dela em cada tenant que a usa: um no tenant de origem e um no tenant de um cliente. Cada '
        'service principal tem o seu próprio object id e recebe os seus próprios papéis; o client id '
        'é o mesmo em todo lugar.'))
    # home tenant
    f.rect(20, 20, 330, 250, stroke='--phosphor', fill='--ink')
    f.text(36, 38, T('home tenant', 'tenant de origem'), size=9.5, anchor='start', fill='--phosphor')
    f.rect(50, 60, 270, 70, stroke='--amber', fill='--panel')
    f.text(185, 78, T('application (registration)', 'aplicação (registro)'), size=10.5, weight='600')
    f.text(185, 98, 'client id 00001111-…', size=9.5, mono=True)
    f.text(185, 116, T('one, wherever it is used', 'um só, onde quer que seja usada'), size=9, fill='--paper-dim')
    f.rect(50, 170, 270, 76, stroke='--wire', fill='--panel')
    f.text(185, 188, T('service principal', 'service principal'), size=10.5, weight='600')
    f.text(185, 208, T('its own object id', 'o seu próprio object id'), size=9.5, fill='--paper-dim')
    f.text(185, 228, T('roles in this tenant', 'papéis neste tenant'), size=9.5, fill='--paper-dim')
    f.arrow([(185, 131), (185, 169)], stroke='--paper-dim')
    # customer tenant
    f.rect(370, 20, 330, 250, stroke='--phosphor', fill='--ink')
    f.text(386, 38, T('a customer\'s tenant', 'o tenant de um cliente'), size=9.5, anchor='start', fill='--phosphor')
    f.rect(400, 170, 270, 76, stroke='--wire', fill='--panel')
    f.text(535, 188, T('service principal', 'service principal'), size=10.5, weight='600')
    f.text(535, 208, T('another object id', 'outro object id'), size=9.5, fill='--paper-dim')
    f.text(535, 228, T('roles the customer gives', 'papéis que o cliente dá'), size=9.5, fill='--paper-dim')
    f.arrow([(321, 95), (535, 95), (535, 169)], stroke='--paper-dim', dash='4 3')
    f.text(535, 82, T('instantiated on consent', 'criado com o consentimento'), size=9, fill='--paper-dim')
    return f, T('The registration says what the program is; each service principal says what it may do in one tenant.',
                'O registro diz o que o programa é; cada service principal diz o que ele pode fazer num tenant.')


@figure('l07-federation', 7)
def federation():
    f = Fig('l07-federation', 720, 300, T(
        'The token exchange in four steps between three parties. 1: GitHub issues the job a token for '
        'repository shop-example/storefront on branch main. 2: the job sends that token and the client '
        'id of shop-deploy to Entra ID\'s token endpoint. 3: Entra ID compares issuer, subject and '
        'audience with the federated credential on the registration. 4: Entra ID returns an access '
        'token, which the job uses with Resource Manager.',
        'A troca de tokens em quatro passos entre três partes. 1: o GitHub emite para o job um token do '
        'repositório shop-example/storefront no branch main. 2: o job manda esse token e o client id do '
        'shop-deploy ao token endpoint do Entra ID. 3: o Entra ID compara issuer, subject e audience com '
        'a credencial federada do registro. 4: o Entra ID devolve um access token, que o job usa com o '
        'Resource Manager.'))
    cols = [(110, 'GitHub'), (360, T('the job', 'o job')), (610, 'Entra ID')]
    for x, name in cols:
        f.rect(x - 80, 16, 160, 34, stroke='--wire', fill='--panel')
        f.text(x, 33, name, size=10.5, weight='600')
        f.line(x, 51, x, 280, stroke='--wire', dash='3 4')
    steps = [
        (110, 360, 80, T('1  a token for repo and branch', '1  um token do repo e do branch')),
        (360, 610, 135, T('2  that token, with the client id', '2  esse token, com o client id')),
        (610, 610, 185, T('3  issuer, subject, audience match?', '3  issuer, subject e audience batem?')),
        (610, 360, 240, T('4  an access token, about an hour', '4  um access token, cerca de uma hora')),
    ]
    for a, b, y, label in steps:
        if a == b:
            f.circle(a, y, 5, fill='--amber')
            f.text(a - 14, y, label, size=9.5, anchor='end', fill='--amber')
        else:
            d = 1 if b > a else -1
            f.arrow([(a + 4 * d, y + 9), (b - 4 * d, y + 9)], stroke='--phosphor' if y != 240 else '--amber', width=1.4)
            f.text((a + b) / 2, y - 4, label, size=9.5)
    return f, T('Nothing in the exchange is stored anywhere, so nothing in it can leak later.',
                'Nada na troca fica guardado em lugar nenhum, então nada nela pode vazar depois.')
