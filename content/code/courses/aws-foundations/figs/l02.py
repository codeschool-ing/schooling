"""Lesson 2: the account as the unit of isolation."""
from figures import Fig, T, figure


@figure('l02-arn', 2)
def arn():
    f = Fig('l02-arn', 720, 270, T(
        'Three ARNs from the transcript, cut into their six fields: prefix, partition, service, '
        'region, account and resource. The topic arn:aws:sns:sa-east-1:123456789012:shop-alerts fills '
        'all six. The user arn:aws:iam::123456789012:user/bia leaves the region empty, because IAM is '
        'global inside an account. The bucket arn:aws:s3:::shop-assets leaves the region and the '
        'account empty, because a bucket name belongs to no account. The account column is '
        'highlighted: it says whose the resource is.',
        'Três ARNs da transcrição, cortados nos seus seis campos: prefixo, partição, serviço, região, '
        'conta e recurso. O tópico arn:aws:sns:sa-east-1:123456789012:shop-alerts preenche os seis. O '
        'usuário arn:aws:iam::123456789012:user/bia deixa a região vazia, porque o IAM é global dentro '
        'de uma conta. O bucket arn:aws:s3:::shop-assets deixa a região e a conta vazias, porque um '
        'nome de bucket não pertence a conta nenhuma. A coluna da conta está destacada: ela diz de '
        'quem é o recurso.'))
    widths = [44, 44, 56, 104, 124, 150]
    gap = 18
    xs = []
    x = 54
    for w in widths:
        xs.append(x)
        x += w + gap
    heads = [T('prefix', 'prefixo'), T('partition', 'partição'), T('service', 'serviço'),
             T('region', 'região'), T('account', 'conta'), T('resource', 'recurso')]
    for i, h in enumerate(heads):
        fill = '--amber' if i == 4 else '--paper-dim'
        f.text(xs[i] + widths[i] / 2, 34, h, size=10.5, weight='600', fill=fill)
    rows = [
        ['arn', 'aws', 'sns', 'sa-east-1', '123456789012', 'shop-alerts'],
        ['arn', 'aws', 'iam', None, '123456789012', 'user/bia'],
        ['arn', 'aws', 's3', None, None, 'shop-assets'],
    ]
    for r, row in enumerate(rows):
        y = 74 + r * 58
        for i, v in enumerate(row):
            stroke = '--amber' if i == 4 else '--wire'
            if v is None:
                f.rect(xs[i], y - 17, widths[i], 34, stroke='--paper-dim', fill='--ink', dash='4 3')
                f.text(xs[i] + widths[i] / 2, y, T('empty', 'vazio'), size=9.5, fill='--paper-dim',
                       italic=True)
            else:
                f.rect(xs[i], y - 17, widths[i], 34, stroke=stroke, fill='--panel')
                f.text(xs[i] + widths[i] / 2, y, v, size=10.5, mono=True)
            if i < 5:
                f.text(xs[i] + widths[i] + gap / 2, y, ':', size=12, mono=True, fill='--paper-dim')
    f.text(360, 228, T('IAM is global inside an account, so a user has no region',
                       'o IAM é global dentro da conta, então um usuário não tem região'),
           size=10, fill='--paper-dim')
    f.text(360, 250, T('a bucket name belongs to no account, so its ARN has none',
                       'um nome de bucket não pertence a conta nenhuma, então o ARN não tem conta'),
           size=10, fill='--amber')
    return f, T('Six fields, always in this order. The fifth says whose a resource is.',
                'Seis campos, sempre nesta ordem. O quinto diz de quem é o recurso.')


@figure('l02-two-accounts', 2)
def two_accounts():
    f = Fig('l02-two-accounts', 720, 400, T(
        'Two accounts side by side, with what the transcripts showed inside each. The management '
        'account, 123456789012, holds the user bia, the topic shop-alerts, a default VPC '
        '172.31.0.0/16 and six VPCs in sa-east-1. The member account shop-prod, 218935875641, holds '
        'no user, no topic, its own default VPC with the same range 172.31.0.0/16, and one VPC. Above '
        'both, one namespace for all of AWS: the bucket name shop-assets belongs to the management '
        'account, so shop-prod was refused it with BucketAlreadyExists, and took '
        '218935875641-shop-assets instead.',
        'Duas contas lado a lado, com o que as transcrições mostraram dentro de cada uma. A conta de '
        'gerenciamento, 123456789012, guarda o usuário bia, o tópico shop-alerts, uma VPC padrão '
        '172.31.0.0/16 e seis VPCs em sa-east-1. A conta-membro shop-prod, 218935875641, não tem '
        'usuário nem tópico, tem a sua própria VPC padrão com a mesma faixa 172.31.0.0/16, e uma VPC. '
        'Acima das duas, um só espaço de nomes para toda a AWS: o nome de bucket shop-assets pertence '
        'à conta de gerenciamento, então a shop-prod o teve recusado com BucketAlreadyExists, e ficou '
        'com 218935875641-shop-assets.'))
    # the shared namespace
    f.rect(20, 20, 680, 100, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(36, 38, T('S3 bucket names: one namespace for every account of AWS',
                     'nomes de bucket do S3: um só espaço de nomes para toda conta da AWS'),
           size=10.5, anchor='start', weight='600', fill='--paper-dim')
    f.rect(70, 62, 180, 36, stroke='--phosphor', fill='--panel', rx=17)
    f.text(160, 80, 'shop-assets', size=10.5, mono=True)
    f.rect(430, 62, 240, 36, stroke='--phosphor', fill='--panel', rx=17)
    f.text(550, 80, '218935875641-shop-assets', size=10.5, mono=True)
    # the accounts
    accts = [
        (20, '123456789012', T('management account', 'conta de gerenciamento'),
         ['bia', 'shop-alerts', '172.31.0.0/16', '6']),
        (380, '218935875641', 'shop-prod', [None, None, '172.31.0.0/16', '1']),
    ]
    labels = [T('IAM users', 'usuários do IAM'), T('SNS topics', 'tópicos do SNS'),
              T('default VPC', 'VPC padrão'), T('VPCs in sa-east-1', 'VPCs em sa-east-1')]
    for x, num, name, vals in accts:
        f.rect(x, 160, 320, 222, stroke='--phosphor', fill='--scan', width=1.5)
        f.text(x + 16, 180, num, size=11, anchor='start', mono=True)
        if name == 'shop-prod':
            f.text(x + 304, 180, name, size=11, anchor='end', mono=True, fill='--paper-dim')
        else:
            f.text(x + 304, 180, name, size=10.5, anchor='end', fill='--paper-dim')
        for i, (lab, v) in enumerate(zip(labels, vals)):
            y = 220 + i * 44
            f.rect(x + 14, y - 16, 292, 32, stroke='--wire', fill='--panel')
            f.text(x + 26, y, lab, size=10, anchor='start')
            if v is None:
                f.text(x + 294, y, T('none', 'nenhum'), size=10, anchor='end', fill='--paper-dim',
                       italic=True)
            else:
                f.text(x + 294, y, v, size=10.5, anchor='end', mono=True)
    # who owns which name: each arrow in two pieces, inside the band and below it
    f.line(160, 100, 160, 120, stroke='--phosphor', width=1.4)
    f.arrow([(160, 120), (160, 157)], stroke='--phosphor', width=1.4)
    f.line(550, 100, 550, 120, stroke='--phosphor', width=1.4)
    f.arrow([(550, 120), (550, 157)], stroke='--phosphor', width=1.4)
    # the refusal
    f.line(470, 158, 435, 122, stroke='--amber', width=1.4, dash='5 3')
    f.arrow([(435, 120), (254, 90)], stroke='--amber', width=1.4, dash='5 3')
    f.text(330, 140, 'BucketAlreadyExists', size=10, mono=True, fill='--amber')
    return f, T('Inside its walls an account sees only its own. A bucket name is the exception.',
                'Dentro das suas paredes, uma conta só vê o que é seu. Um nome de bucket é a exceção.')
