"""Lesson 8: how a request is judged, and what a boundary does to it."""
from figures import Fig, T, figure


@figure('l08-evaluation', 8)
def evaluation():
    f = Fig('l08-evaluation', 720, 510, T(
        'How AWS judges a request inside one account, simplified from its documentation, with what '
        'moto checks marked on the left. The request starts denied. First: is there an explicit Deny '
        'in any policy? If yes, it is denied; moto checks this in identity policies only. Then: do the organisation\'s SCPs and '
        'RCPs allow it? If not, denied; moto ignores them. Then: does an identity-based or a '
        'resource-based policy allow it? If not, denied; moto checks identity policies and ignores '
        'resource policies. Then: does the permission boundary allow it, if one is set? Then: does '
        'the session policy allow it, if one was passed? moto ignores both. Only a request that '
        'passes every step is allowed.',
        'Como a AWS julga uma requisição dentro de uma conta, simplificado da documentação dela, com o '
        'que o moto verifica marcado à esquerda. A requisição começa negada. Primeiro: há um Deny '
        'explícito em alguma política? Se sim, é negada; o moto verifica isso só nas políticas de identidade. Depois: as SCPs e RCPs '
        'da organização a permitem? Se não, negada; o moto as ignora. Depois: uma política baseada em '
        'identidade ou em recurso a permite? Se não, negada; o moto verifica as de identidade e ignora '
        'as de recurso. Depois: o limite de permissões a permite, se houver um? Depois: a política de '
        'sessão a permite, se uma foi passada? O moto ignora as duas. Só uma requisição que passa por '
        'todos os passos é permitida.'))
    f.text(85, 22, 'moto', size=10, weight='600', fill='--paper-dim')
    f.rect(170, 30, 300, 40, stroke='--paper-dim', fill='--panel', rx=18)
    f.text(320, 50, T('the request starts denied', 'a requisição começa negada'), size=10.5)
    rows = [
        (120, T('an explicit Deny in any policy?', 'um Deny explícito em alguma política?'), None,
         [(T('identity: checks', 'identidade: verifica'), '--phosphor'),
          (T('resource: ignores', 'recurso: ignora'), '--amber')], T('yes', 'sim'), T('no', 'não')),
        (190, T('do the SCPs and RCPs allow it?', 'as SCPs e RCPs permitem?'),
         T('in a member account', 'numa conta membro'),
         [(T('ignores', 'ignora'), '--amber')], T('no', 'não'), T('yes', 'sim')),
        (260, T('does an identity or resource policy allow it?',
                'uma política de identidade ou de recurso permite?'), None,
         [(T('identity: checks', 'identidade: verifica'), '--phosphor'),
          (T('resource: ignores', 'recurso: ignora'), '--amber')], T('no', 'não'), T('yes', 'sim')),
        (330, T('does the permission boundary allow it?', 'o limite de permissões permite?'),
         T('if one is set', 'se houver um'),
         [(T('ignores', 'ignora'), '--amber')], T('no', 'não'), T('yes', 'sim')),
        (400, T('does the session policy allow it?', 'a política de sessão permite?'),
         T('if one was passed', 'se uma foi passada'),
         [(T('ignores', 'ignora'), '--amber')], T('no', 'não'), T('yes', 'sim')),
    ]
    f.rect(560, 98, 130, 324, stroke='--amber', fill='--panel', width=1.4)
    f.text(625, 260, T('denied', 'negada'), size=12, weight='600', fill='--amber')
    prev, label = 70, None
    for y, q, sub, tags, out, down in rows:
        f.line(320, prev + 2, 320, y - 24, stroke='--paper-dim', width=1.2, arrow=True)
        if label:
            f.text(330, (prev + y - 22) / 2, label, size=9.5, anchor='start', fill='--paper-dim')
        f.rect(170, y - 22, 300, 44, stroke='--wire', fill='--scan')
        if sub:
            f.text(320, y - 7, q, size=10.5)
            f.text(320, y + 10, sub, size=9, fill='--paper-dim', italic=True)
        else:
            f.text(320, y, q, size=10.5)
        f.arrow([(472, y), (558, y)], stroke='--amber', width=1.2)
        f.text(515, y - 9, out, size=9.5, fill='--amber')
        for i, (t, c) in enumerate(tags):
            f.text(85, y + (i - (len(tags) - 1) / 2) * 15, t, size=9.5, fill=c)
        prev, label = y + 22, down
    f.line(320, prev + 2, 320, 452, stroke='--phosphor', width=1.2, arrow=True)
    f.text(330, (prev + 452) / 2, label, size=9.5, anchor='start', fill='--paper-dim')
    f.rect(170, 454, 300, 40, stroke='--phosphor', fill='--panel', rx=18, width=1.4)
    f.text(320, 474, T('allowed', 'permitida'), size=11, weight='600', fill='--phosphor')
    return f, T('Every step can only refuse; a request is allowed by surviving all of them. Of all '
                'these layers, moto judges the identity policies alone.',
                'Todo passo só pode recusar; uma requisição é permitida sobrevivendo a todos eles. De '
                'todas essas camadas, o moto julga só as políticas de identidade.')


@figure('l08-boundary', 8)
def boundary():
    f = Fig('l08-boundary', 720, 250, T(
        'A permission boundary as an intersection. The identity policies of a role allow S3 and IAM; '
        'its permission boundary allows S3 and CloudWatch Logs. Only the overlap, S3, is allowed: '
        's3:GetObject works. iam:ListUsers is in the identity policies and not in the boundary, so it '
        'is denied. logs:PutLogEvents is in the boundary and in no policy, so it is denied too: a '
        'boundary grants nothing.',
        'Um limite de permissões como uma interseção. As políticas de identidade de uma role permitem '
        'S3 e IAM; o limite de permissões dela permite S3 e CloudWatch Logs. Só a sobreposição, o S3, '
        'é permitida: s3:GetObject funciona. iam:ListUsers está nas políticas de identidade e não no '
        'limite, então é negada. logs:PutLogEvents está no limite e em política nenhuma, então também '
        'é negada: um limite não concede nada.'))
    f.rect(60, 30, 360, 170, stroke='--paper', fill='--panel')
    f.rect(300, 60, 360, 170, stroke='--amber', fill='--panel', dash='6 4')
    f.rect(300, 60, 120, 140, stroke='--phosphor', fill='--scan', width=1.5)
    f.text(180, 50, T('identity policies', 'políticas de identidade'), size=10.5, weight='600')
    f.text(180, 68, T('allow S3 and IAM', 'permitem S3 e IAM'), size=9.5, fill='--paper-dim')
    f.text(180, 140, 'iam:ListUsers', size=10, mono=True)
    f.text(180, 158, T('denied: outside the boundary', 'negada: fora do limite'), size=9,
           fill='--amber')
    f.text(550, 192, T('permission boundary', 'limite de permissões'), size=10.5, weight='600',
           fill='--amber')
    f.text(550, 210, T('allows S3 and Logs', 'permite S3 e Logs'), size=9.5, fill='--paper-dim')
    f.text(550, 120, 'logs:PutLogEvents', size=10, mono=True)
    f.text(550, 138, T('denied: no policy grants it', 'negada: nada a concede'), size=9,
           fill='--amber')
    f.text(360, 112, T('allowed', 'permitida'), size=10.5, weight='600', fill='--phosphor')
    f.text(360, 136, 's3:GetObject', size=10, mono=True)
    return f, T('What a boundary leaves is the overlap. It removes what lies outside it and adds '
                'nothing.',
                'O que um limite deixa é a sobreposição. Ele tira o que fica fora dele e não acrescenta '
                'nada.')
