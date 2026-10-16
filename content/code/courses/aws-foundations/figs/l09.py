"""Lesson 9: assuming a role from both ends, and the confused deputy."""
from figures import Fig, T, figure


@figure('l09-two-sides', 9)
def two_sides():
    f = Fig('l09-two-sides', 720, 290, T(
        'An AssumeRole request judged from both ends. On the left, the user bia, whose own policy '
        'allows her to assume deployer, and the user caio, whose AdministratorAccess allows '
        'everything. In the middle, STS. On the right, the role deployer, with a trust policy naming '
        'bia only and the permissions policy AmazonS3FullAccess. bia\'s request passes both checks and '
        'returns the session assumed-role/deployer/bia-deploy, which can use S3 and not IAM. caio\'s '
        'request is refused, because the trust policy does not name him.',
        'Uma requisição AssumeRole julgada pelas duas pontas. À esquerda, a usuária bia, cuja própria '
        'política permite que ela assuma a deployer, e o usuário caio, cujo AdministratorAccess '
        'permite tudo. No meio, o STS. À direita, a role deployer, com uma política de confiança que '
        'nomeia só a bia e a política de permissões AmazonS3FullAccess. A requisição da bia passa nas '
        'duas verificações e devolve a sessão assumed-role/deployer/bia-deploy, que pode usar S3 e não '
        'IAM. A requisição do caio é recusada, porque a política de confiança não o nomeia.'))
    f.rect(20, 40, 200, 70, stroke='--phosphor', fill='--panel')
    f.text(120, 60, 'user/bia', size=10.5, mono=True)
    f.text(120, 86, T('her policy: may assume deployer', 'a política dela: pode assumir a deployer'),
           size=9.5, fill='--paper-dim')
    f.rect(20, 170, 200, 70, stroke='--phosphor', fill='--panel')
    f.text(120, 190, 'user/caio', size=10.5, mono=True)
    f.text(120, 216, T('his policy: allows everything', 'a política dele: permite tudo'), size=9.5,
           fill='--paper-dim')
    f.rect(290, 95, 140, 90, stroke='--paper', fill='--panel')
    f.text(360, 128, 'STS', size=11, weight='600')
    f.text(360, 152, 'AssumeRole', size=10, mono=True)
    f.rect(500, 30, 200, 124, stroke='--amber', fill='--scan', width=1.4)
    f.text(600, 48, 'role/deployer', size=10.5, mono=True)
    f.rect(515, 62, 170, 36, stroke='--paper-dim', fill='--panel', dash='4 3')
    f.text(600, 80, T('trust: names bia only', 'confiança: só a bia'), size=9.5)
    f.rect(515, 106, 170, 36, stroke='--paper-dim', fill='--panel')
    f.text(600, 124, 'AmazonS3FullAccess', size=9.5, mono=True)
    f.rect(500, 196, 200, 74, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(600, 214, 'assumed-role/deployer/', size=9.5, mono=True)
    f.text(600, 230, 'bia-deploy', size=9.5, mono=True)
    f.text(600, 254, T('S3 yes, IAM no', 'S3 sim, IAM não'), size=9.5, fill='--phosphor')
    f.arrow([(222, 80), (288, 118)], stroke='--phosphor', width=1.3)
    f.arrow([(222, 202), (288, 166)], stroke='--amber', width=1.3)
    f.text(300, 214, T('caio: refused,', 'caio: recusado,'), size=9.5, anchor='start', fill='--amber')
    f.text(300, 230, T('not in the trust', 'fora da confiança'), size=9.5, anchor='start',
           fill='--amber')
    f.arrow([(432, 118), (498, 92)], stroke='--paper-dim', width=1.2, dash='4 3')
    f.arrow([(432, 165), (498, 222)], stroke='--phosphor', width=1.3)
    return f, T('The caller\'s policy lets them ask; the role\'s trust policy decides who is answered.',
                'A política de quem chama permite pedir; a política de confiança da role decide quem é '
                'atendido.')


@figure('l09-confused-deputy', 9)
def confused_deputy():
    f = Fig('l09-confused-deputy', 720, 300, T(
        'The confused deputy, and the external id that stops it. On the left, another customer of the '
        'monitoring company. In the middle, the monitoring company\'s account 444455556666. On the '
        'right, the shop\'s account 123456789012 with the role monitoring, which accepts the company '
        'only with the external id shop-7f3k92. Step 1: the other customer gives the company the '
        'shop\'s role ARN as if it were theirs. Step 2: the company assumes that role sending the other '
        'customer\'s own external id, and is refused. Step 3: when the shop is the one configured, the '
        'company sends shop-7f3k92 and is allowed.',
        'O confused deputy, e o external id que o impede. À esquerda, outro cliente da empresa de '
        'monitoramento. No meio, a conta da empresa de monitoramento 444455556666. À direita, a conta '
        'da loja 123456789012 com a role monitoring, que só aceita a empresa com o external id '
        'shop-7f3k92. Passo 1: o outro cliente dá à empresa o ARN da role da loja como se fosse dele. '
        'Passo 2: a empresa assume essa role enviando o external id do próprio outro cliente, e é '
        'recusada. Passo 3: quando quem configurou é a loja, a empresa envia shop-7f3k92 e é '
        'permitida.'))
    f.rect(20, 40, 150, 110, stroke='--phosphor', fill='--ink')
    f.text(95, 62, T('another customer', 'outro cliente'), size=10.5, weight='600')
    f.text(95, 100, T('types in the', 'digita o ARN'), size=9.5, fill='--paper-dim')
    f.text(95, 116, T("shop's role ARN", 'da role da loja'), size=9.5, fill='--paper-dim')
    f.rect(290, 40, 130, 230, stroke='--phosphor', fill='--ink')
    f.text(355, 62, T('monitoring', 'empresa de'), size=10.5, weight='600')
    f.text(355, 78, T('company', 'monitoramento'), size=10.5, weight='600')
    f.text(355, 96, '444455556666', size=9.5, mono=True, fill='--paper-dim')
    f.rect(560, 40, 140, 230, stroke='--phosphor', fill='--ink')
    f.text(630, 62, T('the shop', 'a loja'), size=10.5, weight='600')
    f.text(630, 78, '123456789012', size=9.5, mono=True, fill='--paper-dim')
    f.rect(572, 100, 116, 64, stroke='--amber', fill='--scan', width=1.4)
    f.text(630, 118, 'role/monitoring', size=9.5, mono=True)
    f.text(630, 138, T('needs the id', 'exige o id'), size=9, fill='--paper-dim')
    f.text(630, 152, 'shop-7f3k92', size=9, mono=True, fill='--amber')
    f.arrow([(172, 100), (288, 100)], stroke='--amber', width=1.3)
    f.text(230, 90, T("1 · the shop's ARN", '1 · o ARN da loja'), size=9.5, fill='--amber')
    f.arrow([(422, 125), (570, 125)], stroke='--amber', width=1.3)
    f.text(496, 113, T('2 · their own id', '2 · o id deles'), size=9.5, fill='--amber')
    f.text(496, 139, T('refused', 'recusado'), size=9.5, weight='600', fill='--amber')
    f.line(422, 220, 560, 187, stroke='--phosphor', width=1.3)
    f.arrow([(560, 187), (600, 166)], stroke='--phosphor', width=1.3)
    f.text(491, 238, '3 · shop-7f3k92', size=9.5, mono=True, fill='--phosphor')
    f.text(491, 254, T('when the shop set it up', 'quando a loja configurou'), size=9.5,
           fill='--phosphor')
    return f, T('The company has the permission. The external id makes sure the shop is the one '
                'choosing how it is used.',
                'A empresa tem a permissão. O external id garante que é a loja quem escolhe como ela é '
                'usada.')
