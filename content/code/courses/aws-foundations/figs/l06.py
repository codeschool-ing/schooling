"""Lesson 6: the principals, and what each one signs with."""
from figures import Fig, T, figure


@figure('l06-principals', 6)
def principals():
    f = Fig('l06-principals', 720, 330, T(
        'The principals of the shop and what each signs its requests with. The root user signs with '
        'the e-mail address, password and MFA, and holds every permission. The IAM user bia sits '
        'inside the group developers; she signs with a password or an AKIA access key, which lasts '
        'until somebody deletes it. The group itself signs nothing. bia, and GitHub Actions with an '
        'OIDC token, can assume the role deployer, which has no credentials of its own; the session '
        'it gives signs with an ASIA key and a token that expire after an hour.',
        'Os principals da loja e com o que cada um assina as requisições. O usuário root assina com '
        'o e-mail, a senha e o MFA, e tem todas as permissões. A usuária do IAM bia está dentro do '
        'grupo developers; ela assina com uma senha ou uma chave de acesso AKIA, que dura até alguém '
        'apagá-la. O grupo em si não assina nada. A bia, e o GitHub Actions com um token OIDC, podem '
        'assumir a role deployer, que não tem credenciais próprias; a sessão que ela dá assina com '
        'uma chave ASIA e um token que expiram depois de uma hora.'))
    # the API, on the right
    f.rect(580, 36, 120, 278, stroke='--paper-dim', fill='--panel')
    f.text(640, 175, T('AWS API', 'API da AWS'), size=11, weight='600')
    # root
    f.rect(45, 36, 180, 48, stroke='--phosphor', fill='--panel')
    f.text(135, 52, T('root user', 'usuário root'), size=11, weight='600')
    f.text(135, 70, T('e-mail, password, MFA', 'e-mail, senha, MFA'), size=9.5, fill='--paper-dim')
    f.line(227, 60, 577, 60, stroke='--paper-dim', width=1.3, arrow=True)
    f.text(408, 50, T('every permission, always', 'todas as permissões, sempre'), size=10,
           fill='--paper-dim')
    # the group, and bia inside it
    f.rect(30, 104, 210, 122, stroke='--paper-dim', fill='--ink', dash='5 3')
    f.text(135, 118, 'group/developers', size=10, mono=True, fill='--paper-dim')
    f.rect(45, 130, 180, 60, stroke='--phosphor', fill='--panel')
    f.text(135, 150, T('IAM user bia', 'usuária do IAM bia'), size=11, weight='600')
    f.text(135, 170, T('password, AKIA key', 'senha, chave AKIA'), size=9.5, fill='--paper-dim')
    f.text(135, 210, T('the group signs nothing', 'o grupo não assina nada'), size=9.5,
           fill='--paper-dim', italic=True)
    # bia straight to the API, in two pieces at the group's edge
    f.line(227, 150, 240, 150, stroke='--amber', width=1.3)
    f.arrow([(240, 150), (577, 150)], stroke='--amber', width=1.3)
    f.text(408, 140, T('AKIA key: until somebody deletes it', 'chave AKIA: até alguém apagá-la'),
           size=10, fill='--amber')
    # bia to the role
    f.line(227, 178, 240, 187.9, stroke='--paper', width=1.3)
    f.arrow([(240, 187.9), (298, 232)], stroke='--paper', width=1.3)
    f.text(300, 198, 'sts:AssumeRole', size=9.5, mono=True, anchor='start')
    # GitHub
    f.rect(45, 262, 180, 52, stroke='--phosphor', fill='--panel')
    f.text(135, 280, 'GitHub Actions', size=11, weight='600')
    f.text(135, 298, T('OIDC token', 'token OIDC'), size=9.5, fill='--paper-dim')
    f.arrow([(227, 286), (298, 262)], stroke='--paper', width=1.3)
    f.text(300, 300, 'AssumeRoleWithWebIdentity', size=9.5, mono=True, anchor='start')
    # the role
    f.rect(300, 214, 160, 64, stroke='--amber', fill='--scan', width=1.5)
    f.text(380, 236, T('role deployer', 'role deployer'), size=11, weight='600')
    f.text(380, 256, T('no credentials of its own', 'sem credenciais próprias'), size=9.5,
           fill='--paper-dim')
    f.arrow([(462, 246), (577, 246)], stroke='--phosphor', width=1.4)
    f.text(520, 228, T('ASIA key + token', 'chave ASIA + token'), size=10, fill='--phosphor')
    f.text(520, 264, T('expires in an hour', 'expira em uma hora'), size=10, fill='--phosphor')
    return f, T('Four ways a request gets signed, and a group that signs none. Only the role session '
                'expires on its own.',
                'Quatro jeitos de uma requisição ser assinada, e um grupo que não assina nenhuma. Só a '
                'sessão da role expira sozinha.')
