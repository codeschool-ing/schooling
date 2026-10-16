"""Lesson 4: service control policies."""
from figures import Fig, T, figure


@figure('l04-filter', 4)
def scp_filter():
    f = Fig('l04-filter', 720, 320, T(
        'Two overlapping circles. The left one is what the role\'s IAM policies allow: ec2, s3 and '
        'rds. The right one is what the SCPs above the account allow: ec2, s3 and lambda. Only the '
        'overlap, ec2 and s3, is what the role can do. rds is granted by IAM and cut by the SCPs; '
        'lambda is allowed by the SCPs and granted by nobody, so it is refused as well.',
        'Dois círculos que se sobrepõem. O da esquerda é o que as políticas do IAM da role permitem: '
        'ec2, s3 e rds. O da direita é o que as SCPs acima da conta permitem: ec2, s3 e lambda. Só a '
        'sobreposição, ec2 e s3, é o que a role pode fazer. rds é concedido pelo IAM e cortado pelas '
        'SCPs; lambda é permitido pelas SCPs e não é concedido por ninguém, então também é recusado.'))
    f.circle(285, 160, 120, fill=None, stroke='--phosphor', width=1.6)
    f.circle(435, 160, 120, fill=None, stroke='--amber', width=1.6)
    f.text(215, 26, T("what the role's IAM allows", 'o que o IAM da role permite'), size=11,
           weight='600', fill='--phosphor')
    f.text(505, 26, T('what the SCPs allow', 'o que as SCPs permitem'), size=11, weight='600',
           fill='--amber')
    f.text(225, 160, 'rds:*', size=11, mono=True)
    f.text(225, 180, T('cut by an SCP', 'cortado por uma SCP'), size=9.5, fill='--paper-dim',
           italic=True)
    f.text(495, 160, 'lambda:*', size=11, mono=True)
    f.text(495, 180, T('granted by nobody', 'ninguém concedeu'), size=9.5, fill='--paper-dim',
           italic=True)
    f.text(360, 145, 'ec2:*', size=11, mono=True, weight='600')
    f.text(360, 170, 's3:*', size=11, mono=True, weight='600')
    f.text(360, 300, T('only the overlap reaches the account; a Deny in either takes an action out of it',
                       'só a sobreposição chega à conta; um Deny em qualquer um tira uma ação dela'),
           size=10, fill='--paper')
    return f, T('IAM grants, the SCPs set the ceiling, and the role gets what is in both.',
                'O IAM concede, as SCPs põem o teto, e a role fica com o que está nos dois.')


def level(f, x, y, w, name, policies, stroke='--paper-dim', fill='--ink', rx=10):
    h = 26 + 15 * len(policies)
    f.rect(x - w / 2, y, w, h, stroke=stroke, fill=fill, width=1.4, rx=rx)
    f.text(x, y + 14, name, size=10.5, mono=True, weight='600')
    for i, p in enumerate(policies):
        fill_t = '--amber' if p.startswith(('deny', 'sa-east', 'protect', 'sandbox')) else '--paper-dim'
        f.text(x, y + 31 + 15 * i, p, size=9.5, mono=True, fill=fill_t)
    return y + h


@figure('l04-inheritance', 4)
def inheritance():
    f = Fig('l04-inheritance', 720, 400, T(
        'The SCPs on the two paths of the shop\'s tree after this lesson. The root carries '
        'FullAWSAccess, deny-leaving, sa-east-1-only and protect-security-services. On the left path, '
        'Workloads carries FullAWSAccess and protect-deployer, Prod and the account shop-prod carry '
        'FullAWSAccess. On the right path, Sandbox carries only sandbox-allow-list, and the account '
        'sandbox carries FullAWSAccess. A request for EC2 in us-east-1 from shop-prod is denied at the '
        'root. A request for RDS in sa-east-1 from sandbox passes the root and is not allowed at '
        'Sandbox, so it is refused there.',
        'As SCPs nos dois caminhos da árvore da loja depois desta lição. A raiz carrega FullAWSAccess, '
        'deny-leaving, sa-east-1-only e protect-security-services. No caminho da esquerda, Workloads '
        'carrega FullAWSAccess e protect-deployer, Prod e a conta shop-prod carregam FullAWSAccess. No '
        'caminho da direita, Sandbox carrega só sandbox-allow-list, e a conta sandbox carrega '
        'FullAWSAccess. Um pedido de EC2 em us-east-1 vindo da shop-prod é negado na raiz. Um pedido '
        'de RDS em sa-east-1 vindo da sandbox passa pela raiz e não é permitido em Sandbox, então é '
        'recusado lá.'))
    bottom = level(f, 360, 16, 260, 'Root',
                   ['FullAWSAccess', 'deny-leaving', 'sa-east-1-only', 'protect-security-services'])
    # left path
    b1 = level(f, 190, 140, 220, 'Workloads', ['FullAWSAccess', 'protect-deployer'])
    b2 = level(f, 190, b1 + 30, 220, 'Prod', ['FullAWSAccess'])
    b3 = level(f, 190, b2 + 30, 220, 'shop-prod', ['FullAWSAccess'], stroke='--phosphor',
               fill='--scan', rx=4)
    # right path
    c1 = level(f, 530, 140, 220, 'Sandbox', ['sandbox-allow-list'])
    c2 = level(f, 530, c1 + 30, 220, 'sandbox', ['FullAWSAccess'], stroke='--phosphor',
               fill='--scan', rx=4)
    for x1, x2, y1, y2 in ((300, 190, bottom, 137), (420, 530, bottom, 137),
                           (190, 190, b1, b1 + 27), (190, 190, b2, b2 + 27),
                           (530, 530, c1, c1 + 27)):
        mid = (y1 + y2) / 2
        f.arrow([(x1, y1), (x1, mid), (x2, mid), (x2, y2)], stroke='--paper-dim', width=1.2)
    f.text(190, b3 + 26, T('EC2 in us-east-1: denied at the root', 'EC2 em us-east-1: negado na raiz'),
           size=10, fill='--amber')
    f.text(530, c2 + 26, T('RDS in sa-east-1: not allowed at Sandbox',
                           'RDS em sa-east-1: não permitido em Sandbox'), size=10, fill='--amber')
    f.text(530, c2 + 44, T('EC2 in sa-east-1: allowed at every level',
                           'EC2 em sa-east-1: permitido em todo nível'), size=10, fill='--phosphor')
    f.text(360, 390, T('the highlighted policies are the shop\'s; FullAWSAccess is AWS\'s',
                       'as políticas destacadas são da loja; FullAWSAccess é da AWS'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('Every level on the path is a filter. A deny at any of them, or a missing allow, refuses the request.',
                'Cada nível do caminho é um filtro. Um deny em qualquer um deles, ou um allow que falta, recusa o pedido.')
