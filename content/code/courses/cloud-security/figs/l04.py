"""Lesson 4: what crosses a seam, and a token exchanged instead of a key."""
from figures import Fig, T, figure


@figure('l04-seams', 4)
def seams():
    f = Fig('l04-seams', 720, 360, T(
        'Two environments, AWS on the left and Google Cloud on the right, with the seam between them '
        'drawn as a dashed line. Four things cross it. An identity: an AWS access key, copied into a '
        'job on the Google Cloud side, which neither side owns. A route: a link between the networks, '
        'after which each side counts the other as inside. A record: CloudTrail on one side and Cloud '
        'Audit Logs on the other, each holding half of one action, joined only by the time. A policy: '
        'a guardrail written on the AWS side, with nothing matching it on the other.',
        'Dois ambientes, a AWS à esquerda e o Google Cloud à direita, com a emenda entre eles '
        'desenhada como uma linha tracejada. Quatro coisas a atravessam. Uma identidade: uma chave de '
        'acesso da AWS, copiada para um job do lado do Google Cloud, que nenhum dos lados possui. Uma '
        'rota: um link entre as redes, depois do qual cada lado conta o outro como de dentro. Um '
        'registro: o CloudTrail de um lado e o Cloud Audit Logs do outro, cada um com metade de uma '
        'ação, ligados só pela hora. Uma política: uma proteção escrita do lado da AWS, sem nada que '
        'corresponda a ela do outro.'))
    f.rect(20, 40, 250, 300, stroke='--phosphor', fill='--panel')
    f.rect(450, 40, 250, 300, stroke='--phosphor', fill='--panel')
    f.text(145, 24, 'AWS', size=12, weight='600')
    f.text(575, 24, 'Google Cloud', size=12, weight='600')
    for a, b in ((30, 100), (120, 170), (190, 240), (260, 310), (330, 350)):
        f.line(360, a, 360, b, stroke='--amber', dash='5 4', width=1.4)
    f.text(360, 18, T('the seam', 'a emenda'), size=10, fill='--amber', weight='600')
    rows = [
        (90, T('an identity', 'uma identidade'), 'reports-sync  AKIA…', T('the key, pasted into a job', 'a chave, colada num job'),
         T('owned by neither side', 'de nenhum dos lados')),
        (160, T('a route', 'uma rota'), 'VPC  10.20.0.0/16', T('the other network', 'a outra rede'),
         T('each side becomes inside', 'cada lado vira de dentro')),
        (230, T('a record', 'um registro'), 'CloudTrail', 'Cloud Audit Logs',
         T('joined by the time only', 'ligados só pela hora')),
        (300, T('a policy', 'uma política'), T('a guardrail', 'uma proteção'), T('nothing matching', 'nada equivalente'),
         T('enforced on one side', 'aplicada de um lado')),
    ]
    for y, what, left, right, note in rows:
        f.text(40, y - 20, what, size=9.5, anchor='start', fill='--paper-dim', italic=True)
        f.rect(40, y - 10, 210, 26, stroke='--wire', fill='--scan')
        mono = '…' in left or left in ('CloudTrail', 'VPC  10.20.0.0/16')
        f.text(145, y + 3, left, size=10, mono=mono)
        f.rect(470, y - 10, 210, 26, stroke='--wire', fill='--scan')
        f.text(575, y + 3, right, size=10, mono=(right == 'Cloud Audit Logs'))
        f.arrow([(252, y + 3), (468, y + 3)], stroke='--paper-dim', start=True)
        f.text(360, y + 20, note, size=9.5, fill='--amber')
    return f, T('Each side passes its own provider\'s review. What crosses between them is reviewed by '
                'whoever remembered it.',
                'Cada lado passa na revisão do próprio provedor. O que atravessa entre eles é revisado '
                'por quem se lembrou.')


@figure('l04-exchange', 4)
def exchange():
    f = Fig('l04-exchange', 720, 380, T(
        'Workload identity federation, step by step, with four participants: the job in Google Cloud, '
        'Google, AWS STS and the S3 bucket. One: the job asks Google for an identity token, and Google '
        'returns one it has signed. Two: the job sends the token to AWS STS, calling '
        'AssumeRoleWithWebIdentity. Three: STS checks the signature against the keys Google publishes, '
        'the expiry, and the trust policy\'s condition naming one service account; moto checks none of '
        'this. Four: STS returns a temporary key starting ASIA, with a session token, that expires in '
        'one hour. Five: the job reads the bucket with it. No secret is stored on either side.',
        'Federação de identidade de workload, passo a passo, com quatro participantes: o job no Google '
        'Cloud, o Google, o AWS STS e o bucket S3. Um: o job pede ao Google um token de identidade, e o '
        'Google devolve um assinado por ele. Dois: o job manda o token ao AWS STS, chamando '
        'AssumeRoleWithWebIdentity. Três: o STS confere a assinatura com as chaves que o Google publica, '
        'a validade, e a condição da política de confiança que nomeia uma conta de serviço; o moto não '
        'confere nada disso. Quatro: o STS devolve uma chave temporária começando com ASIA, com um token '
        'de sessão, que vence em uma hora. Cinco: o job lê o bucket com ela. Nenhum segredo fica '
        'guardado em nenhum dos lados.'))
    cols = [(90, T('the job', 'o job'), T('in Google Cloud', 'no Google Cloud')),
            (270, 'Google', T('signs tokens', 'assina tokens')),
            (450, 'AWS STS', T('trades tokens', 'troca tokens')),
            (630, 'S3', 'clinic-exports')]
    for x, name, sub in cols:
        f.rect(x - 70, 20, 140, 44, stroke='--phosphor', fill='--panel')
        f.text(x, 36, name, size=11, weight='600')
        f.text(x, 53, sub, size=9, fill='--paper-dim', italic=True, mono=(sub == 'clinic-exports'))
        if x == 450:  # the check sits on STS's own line: break it around the box
            f.line(x, 66, x, 212, stroke='--wire', dash='3 4')
            f.line(x, 270, x, 360, stroke='--wire', dash='3 4')
        else:
            f.line(x, 66, x, 360, stroke='--wire', dash='3 4')
    steps = [
        (100, 90, 270, T('1  ask for an identity token', '1  pede um token de identidade'), '--paper-dim'),
        (140, 270, 90, T('a token Google signed', 'um token assinado pelo Google'), '--paper-dim'),
        (190, 90, 450, '2  AssumeRoleWithWebIdentity', '--paper-dim'),
        (290, 450, 90, T('4  ASIA key + session token, 1 hour', '4  chave ASIA + token de sessão, 1 hora'), '--phosphor'),
        (340, 90, 630, T('5  read the bucket', '5  lê o bucket'), '--phosphor'),
    ]
    for y, x1, x2, label, colour in steps:
        d = 1 if x2 > x1 else -1
        f.arrow([(x1 + d * 4, y), (x2 - d * 4, y)], stroke=colour)
        mono = label.endswith('WithWebIdentity')
        f.text((x1 + x2) / 2, y - 10, label, size=9.5, mono=mono, fill='--paper')
    f.rect(330, 214, 240, 54, stroke='--amber', fill='--scan')
    f.text(450, 228, T('3  check the signature, the expiry', '3  confere a assinatura, a validade'), size=9.5)
    f.text(450, 243, T('and the condition naming one account', 'e a condição que nomeia uma conta'), size=9.5)
    f.text(450, 258, T('moto checks none of this', 'o moto não confere nada disso'), size=9, fill='--amber',
           italic=True)
    return f, T('A token proves who the job is; the credentials it buys expire on their own. Nothing '
                'copied from one side would still work tomorrow.',
                'Um token prova quem o job é; as credenciais que ele compra vencem sozinhas. Nada copiado '
                'de um lado ainda funcionaria amanhã.')
