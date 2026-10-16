"""Lesson 19: three ways out of a private subnet, and PrivateLink between two accounts."""
from figures import Fig, T, figure


@figure('l19-three-ways', 19)
def three_ways():
    f = Fig('l19-three-ways', 720, 400, T(
        'Three ways an application machine in the private subnet app-a reaches something outside '
        'the VPC shop-prod, 10.20.0.0/16. To S3, its packet matches the S3 prefix list in the route '
        'table and goes to the gateway endpoint: a route, and free. To STS, it goes to the interface '
        'endpoint, a network interface inside app-a itself: 0.021 dollars an hour per zone and 0.01 '
        'a gigabyte. To the payment provider on the internet, it matches 0.0.0.0/0 and goes to '
        'nat-a in public-a, then through the internet gateway: 0.093 dollars a gigabyte and 0.093 '
        'an hour.',
        'Três maneiras de uma máquina da aplicação na sub-rede privada app-a alcançar algo fora da '
        'VPC shop-prod, 10.20.0.0/16. Para o S3, o pacote casa com a prefix list do S3 na tabela de '
        'rotas e vai para o gateway endpoint: uma rota, e de graça. Para o STS, vai para o interface '
        'endpoint, uma interface de rede dentro da própria app-a: 0,021 dólar por hora por zona e '
        '0,01 por gigabyte. Para o provedor de pagamentos na internet, casa com 0.0.0.0/0 e vai '
        'para nat-a em public-a, depois pelo internet gateway: 0,093 dólar por gigabyte e 0,093 por '
        'hora.'))
    f.rect(10, 30, 480, 350, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(26, 46, 'sa-east-1', size=11, anchor='start', mono=True, fill='--paper-dim')
    f.rect(25, 58, 450, 310, stroke='--paper', fill='--ink', width=1.4)
    f.text(41, 76, 'shop-prod  10.20.0.0/16', size=10.5, anchor='start', mono=True)
    # app-a, with the machine and the interface endpoint inside it
    f.rect(45, 90, 230, 160, stroke='--wire', fill='--scan')
    f.text(60, 106, 'app-a', size=10, anchor='start', mono=True)
    f.rect(60, 120, 100, 44, stroke='--wire', fill='--panel')
    f.text(110, 142, T('app machine', 'máquina da app'), size=10.5)
    f.rect(150, 190, 110, 44, stroke='--phosphor', fill='--panel', width=1.5)
    f.lines(205, 212, [T('interface', 'interface'), 'endpoint'], size=10)
    # public-a with the NAT gateway
    f.rect(45, 270, 230, 84, stroke='--amber', fill='--scan', width=1.4)
    f.text(60, 286, 'public-a', size=10, anchor='start', mono=True, fill='--amber')
    f.rect(150, 300, 110, 40, stroke='--amber', fill='--panel', width=1.4)
    f.text(205, 320, 'nat-a', size=10.5, mono=True)
    # the three destinations
    f.rect(560, 108, 140, 40, stroke='--paper-dim', fill='--panel')
    f.text(630, 128, 'S3', size=11, weight='600')
    f.rect(560, 192, 140, 40, stroke='--paper-dim', fill='--panel')
    f.text(630, 212, 'STS', size=11, weight='600')
    f.rect(560, 300, 140, 40, stroke='--paper-dim', fill='--panel', rx=16)
    f.text(630, 320, T('payment provider', 'provedor de pagamentos'), size=10.5, weight='600')
    # 1: S3 through the gateway endpoint, one piece per box crossed
    f.line(162, 128, 275, 128, stroke='--phosphor', width=1.5)
    f.line(275, 128, 475, 128, stroke='--phosphor', width=1.5)
    f.line(475, 128, 490, 128, stroke='--phosphor', width=1.5)
    f.arrow([(490, 128), (556, 128)], stroke='--phosphor', width=1.5)
    f.text(375, 116, T('gateway endpoint: a route, free', 'gateway endpoint: uma rota, grátis'),
           size=9.5, fill='--phosphor')
    # 2: STS through the interface endpoint
    f.arrow([(110, 166), (110, 212), (146, 212)], stroke='--phosphor', width=1.4)
    f.line(262, 212, 275, 212, stroke='--phosphor', width=1.4)
    f.line(275, 212, 475, 212, stroke='--phosphor', width=1.4)
    f.line(475, 212, 490, 212, stroke='--phosphor', width=1.4)
    f.arrow([(490, 212), (556, 212)], stroke='--phosphor', width=1.4)
    f.text(375, 200, T('0.021/h per zone + 0.01/GB', '0,021/h por zona + 0,01/GB'), size=9.5,
           fill='--phosphor')
    # 3: the internet through nat-a
    f.line(80, 166, 80, 250, stroke='--amber', width=1.4)
    f.line(80, 250, 80, 270, stroke='--amber', width=1.4)
    f.arrow([(80, 270), (80, 320), (146, 320)], stroke='--amber', width=1.4)
    f.line(262, 320, 275, 320, stroke='--amber', width=1.4)
    f.line(275, 320, 475, 320, stroke='--amber', width=1.4)
    f.line(475, 320, 490, 320, stroke='--amber', width=1.4)
    f.arrow([(490, 320), (556, 320)], stroke='--amber', width=1.4)
    f.text(375, 308, T('NAT: 0.093/GB + 0.093/h', 'NAT: 0,093/GB + 0,093/h'), size=9.5,
           fill='--amber')
    f.text(375, 338, T('then the internet gateway', 'depois o internet gateway'), size=9.5,
           fill='--amber')
    f.text(600, 380, T('VPC and EC2 offers, September 2026', 'ofertas VPC e EC2, setembro de 2026'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('The same machine, three destinations, three prices. Only the gateway endpoint is free, '
                'and only S3 and DynamoDB have one.',
                'A mesma máquina, três destinos, três preços. Só o gateway endpoint é grátis, e só o S3 '
                'e o DynamoDB têm um.')


@figure('l19-privatelink', 19)
def privatelink():
    f = Fig('l19-privatelink', 720, 330, T(
        'PrivateLink between two accounts. On the left, the account shop-staging with its VPC '
        '10.30.0.0/16, a test machine and an interface endpoint in one of its subnets. On the '
        'right, the account shop-prod with its VPC 10.20.0.0/16, the internal Network Load '
        'Balancer stock-api in the app subnets, and the application machines behind it. One arrow '
        'goes from the interface endpoint to the load balancer: PrivateLink, one way, accepted by '
        'the provider. Between the two VPCs there is no route, so their ranges could even overlap.',
        'PrivateLink entre duas contas. À esquerda, a conta shop-staging com a VPC 10.30.0.0/16, '
        'uma máquina de teste e um interface endpoint numa das sub-redes. À direita, a conta '
        'shop-prod com a VPC 10.20.0.0/16, o Network Load Balancer interno stock-api nas sub-redes '
        'app, e as máquinas da aplicação atrás dele. Uma seta vai do interface endpoint ao load '
        'balancer: PrivateLink, num sentido só, aceito pelo provedor. Entre as duas VPCs não há '
        'rota, então os intervalos poderiam até se sobrepor.'))
    for x, name, cidr in ((20, 'shop-staging', '10.30.0.0/16'), (400, 'shop-prod', '10.20.0.0/16')):
        f.rect(x, 30, 300, 250, stroke='--phosphor', fill='--ink', width=1.5)
        f.text(x + 16, 48, name, size=11, anchor='start', mono=True, weight='600')
        f.rect(x + 16, 62, 268, 202, stroke='--paper', fill='--ink', width=1.2)
        f.text(x + 30, 80, f'VPC {cidr}', size=10, anchor='start', mono=True)
        f.rect(x + 30, 94, 240, 156, stroke='--wire', fill='--scan')
    # consumer
    f.rect(52, 112, 110, 40, stroke='--wire', fill='--panel')
    f.text(107, 132, T('test machine', 'máquina de teste'), size=10)
    f.rect(170, 176, 110, 48, stroke='--phosphor', fill='--panel', width=1.5)
    f.lines(225, 200, [T('interface', 'interface'), 'endpoint'], size=10)
    f.arrow([(140, 154), (140, 200), (166, 200)], stroke='--phosphor', width=1.4)
    # provider
    f.rect(444, 176, 110, 48, stroke='--phosphor', fill='--panel', width=1.5)
    f.lines(499, 200, ['stock-api', T('(internal NLB)', '(NLB interno)')], size=10)
    f.rect(566, 112, 96, 40, stroke='--wire', fill='--panel')
    f.text(614, 132, T('app machines', 'máquinas da app'), size=10)
    f.arrow([(556, 192), (604, 192), (604, 156)], stroke='--phosphor', width=1.4)
    # PrivateLink, in pieces at every box edge it crosses
    f.line(282, 200, 290, 200, stroke='--phosphor', width=1.6)
    f.line(290, 200, 304, 200, stroke='--phosphor', width=1.6)
    f.line(304, 200, 320, 200, stroke='--phosphor', width=1.6)
    f.line(320, 200, 400, 200, stroke='--phosphor', width=1.6)
    f.line(400, 200, 416, 200, stroke='--phosphor', width=1.6)
    f.line(416, 200, 430, 200, stroke='--phosphor', width=1.6)
    f.arrow([(430, 200), (440, 200)], stroke='--phosphor', width=1.6)
    f.text(360, 186, 'PrivateLink', size=10.5, weight='600', fill='--phosphor')
    f.text(360, 216, T('one way', 'num sentido só'), size=9.5, fill='--phosphor')
    f.text(360, 300, T('no route between 10.30.0.0/16 and 10.20.0.0/16: the ranges could overlap',
                       'nenhuma rota entre 10.30.0.0/16 e 10.20.0.0/16: os intervalos poderiam se sobrepor'),
           size=10, fill='--paper-dim')
    f.text(360, 318, T('acceptance required; allowed principal: shop-staging',
                       'aceite obrigatório; principal permitido: shop-staging'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('The consumer sees one interface in its own subnet; the provider sees connections at its '
                'load balancer. Nothing else of either VPC is visible to the other.',
                'O consumidor vê uma interface na própria sub-rede; o provedor vê conexões no load '
                'balancer dele. Nada mais de uma VPC é visível para a outra.')
