"""Lesson 10: instance profiles, the metadata service and IRSA."""
from figures import Fig, T, figure


@figure('l10-imds', 10)
def imds():
    f = Fig('l10-imds', 720, 370, T(
        'Who gets an answer from the instance metadata service under IMDSv2. Inside an EC2 '
        'instance, the application sends a PUT for a token and the answer arrives, one hop away. A '
        'container behind a Docker bridge, also on the instance, asks too; with a hop limit of 1 '
        'the answer stops at the bridge, and with 2 it reaches the container. Outside the instance, '
        'a forged request from the internet makes the application send a plain GET, which carries '
        'no token and is refused with 401.',
        'Quem recebe resposta do serviço de metadados da instância no IMDSv2. Dentro de uma '
        'instância EC2, a aplicação manda um PUT pedindo um token e a resposta chega, a um salto. '
        'Um contêiner atrás de uma bridge do Docker, também na instância, pede também; com limite '
        'de saltos 1 a resposta para na bridge, e com 2 chega ao contêiner. Fora da instância, uma '
        'requisição forjada vinda da internet faz a aplicação mandar um GET simples, que não leva '
        'token e é recusado com 401.'))
    f.rect(20, 40, 450, 230, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(36, 58, T('an EC2 instance', 'uma instância EC2'), size=11, anchor='start',
           fill='--paper-dim')
    f.rect(50, 80, 170, 50, stroke='--phosphor', fill='--panel')
    f.text(135, 105, T('the application', 'a aplicação'), size=11, weight='600')
    f.rect(250, 150, 200, 105, stroke='--wire', fill='--scan', dash='4 3')
    f.text(266, 166, T('Docker bridge', 'bridge do Docker'), size=10, anchor='start',
           fill='--paper-dim')
    f.rect(275, 188, 150, 48, stroke='--phosphor', fill='--panel')
    f.text(350, 212, T('a container', 'um contêiner'), size=11, weight='600')
    f.rect(580, 80, 120, 175, stroke='--phosphor', fill='--scan', width=1.5)
    f.lines(640, 150, [T('metadata', 'serviço de'), T('service', 'metadados')], size=11,
            weight='600')
    f.text(640, 185, '169.254.169.254', size=9.5, mono=True)
    # the instance's own process: a token, one hop
    f.arrow([(222, 97), (577, 97)], stroke='--phosphor', width=1.4, start=True)
    f.text(345, 86, T('PUT for a token: answered, one hop', 'PUT pedindo token: respondido, um salto'),
           size=10, fill='--phosphor')
    # the container: the answer stops at the bridge
    f.arrow([(577, 212), (453, 212)], stroke='--amber', width=1.4)
    f.lines(515, 192, [T('hop limit 1:', 'limite 1:'), T('stops here', 'para aqui')], size=10,
            fill='--amber')
    f.text(515, 232, T('limit 2: through', 'limite 2: passa'), size=9.5, fill='--paper-dim',
           italic=True)
    # the forged request
    f.rect(50, 305, 170, 46, stroke='--paper-dim', fill='--panel', rx=22)
    f.text(135, 328, T('a forged request', 'uma requisição forjada'), size=10.5, weight='600')
    f.arrow([(135, 303), (135, 133)], stroke='--amber', width=1.3)
    f.text(145, 290, T('from the internet', 'vinda da internet'), size=9.5, anchor='start',
           fill='--paper-dim', italic=True)
    f.arrow([(222, 118), (577, 118)], stroke='--amber', width=1.3, dash='5 3')
    f.text(345, 132, T('a plain GET, no token: 401', 'um GET simples, sem token: 401'), size=10,
           fill='--amber')
    return f, T('IMDSv2 answers the instance\'s own processes, and nothing a hop further away or '
                'without the PUT.',
                'O IMDSv2 responde aos processos da própria instância, e a nada que esteja um salto '
                'além ou que não faça o PUT.')


@figure('l10-irsa', 10)
def irsa():
    f = Fig('l10-irsa', 720, 380, T(
        'IRSA as a sequence, between four parties: the EKS cluster, the pod, STS and S3. One: the '
        'cluster gives the pod a signed token in a file. Two: the pod sends AssumeRoleWithWebIdentity '
        'to STS with the token and no signature. Three: STS fetches the keys the cluster publishes '
        'and verifies the signature. Four: STS evaluates the trust policy, where sub and aud must '
        'match. Five: STS returns credentials for an hour. Six: the pod calls S3, signed with them. '
        'moto skips steps three and four.',
        'O IRSA como sequência, entre quatro partes: o cluster EKS, o pod, o STS e o S3. Um: o '
        'cluster dá ao pod um token assinado num arquivo. Dois: o pod manda AssumeRoleWithWebIdentity '
        'ao STS com o token e sem assinatura. Três: o STS busca as chaves que o cluster publica e '
        'verifica a assinatura. Quatro: o STS avalia a política de confiança, onde sub e aud precisam '
        'bater. Cinco: o STS devolve credenciais por uma hora. Seis: o pod chama o S3, assinando com '
        'elas. O moto pula os passos três e quatro.'))
    cols = [(90, T('the cluster', 'o cluster'), 'EKS'), (270, T('the pod', 'o pod'), 'checkout'),
            (450, 'STS', None), (630, 'S3', None)]
    for x, name, sub in cols:
        f.rect(x - 70, 24, 140, 44, stroke='--phosphor', fill='--panel')
        if sub:
            f.text(x, 39, name, size=11, weight='600')
            f.text(x, 56, sub, size=9.5, mono=True, fill='--paper-dim')
        else:
            f.text(x, 46, name, size=11, weight='600', mono=True)
        f.line(x, 70, x, 360, stroke='--wire', width=1, dash='3 4')
    steps = [
        (100, 90, 268, '--phosphor', T('1  a signed token, in a file', '1  um token assinado, num arquivo')),
        (150, 270, 448, '--phosphor', T('2  token, no signature', '2  token, sem assinatura')),
        (200, 450, 92, '--amber', T('3  fetch its keys, verify the signature', '3  busca as chaves, verifica a assinatura')),
        (290, 450, 272, '--phosphor', T('5  credentials for an hour', '5  credenciais por uma hora')),
        (340, 270, 628, '--phosphor', T('6  a call signed with them', '6  uma chamada assinada com elas')),
    ]
    for y, x1, x2, colour, label in steps:
        f.arrow([(x1 + (2 if x2 > x1 else -2), y), (x2, y)], stroke=colour, width=1.4)
        f.text((x1 + x2) / 2, y - 11, label, size=10, fill=colour)
    f.text(460, 245, T('4  trust policy: sub, aud', '4  política de confiança: sub, aud'), size=10,
           anchor='start', fill='--amber')
    f.text(160, 245, T('moto skips 3 and 4', 'o moto pula 3 e 4'), size=10, fill='--amber',
           weight='600', italic=True)
    return f, T('The pod needs no AWS credential to get its first one: the token is the proof, and STS '
                'is the one that checks it.',
                'O pod não precisa de credencial da AWS para conseguir a primeira: o token é a prova, '
                'e quem a confere é o STS.')
