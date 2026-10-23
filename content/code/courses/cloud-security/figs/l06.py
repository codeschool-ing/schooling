"""Lesson 6: the escalation path, and the three places to cut it."""
from figures import Fig, T, figure


@figure('l06-path', 6)
def path():
    f = Fig('l06-path', 720, 262, T(
        'The escalation path in this lesson, left to right. A user nobody removed when dani left in '
        'March; an access key on it nobody deactivated; an inline policy allowing '
        'iam:AttachUserPolicy on every resource. Together they let the key attach AdministratorAccess '
        'to its own user, and from then on it may do everything in the account. Under each of the first '
        'three links, the fix that cuts it: remove the user, delete the key, or name the one policy that '
        'may be attached. Cutting any one closes the path.',
        'O caminho de escalada desta aula, da esquerda para a direita. Um usuário que ninguém removeu '
        'quando a dani saiu em março; uma chave de acesso nele que ninguém desativou; uma política inline '
        'que permite iam:AttachUserPolicy em todo recurso. Juntos, eles deixam a chave anexar a '
        'AdministratorAccess ao próprio usuário, e daí em diante ela pode tudo na conta. Debaixo de cada '
        'um dos três primeiros elos, a correção que o corta: remover o usuário, apagar a chave, ou nomear '
        'a única política que pode ser anexada. Cortar qualquer um fecha o caminho.'))
    links = [
        (T('a user nobody', 'um usuário que'), T('removed', 'ninguém removeu'), None),
        (T('a key nobody', 'uma chave que'), T('deactivated', 'ninguém desativou'), None),
        (T('an inline policy', 'uma política inline'), None, 'iam:AttachUserPolicy'),
    ]
    fixes = [T('remove the user', 'remover o usuário'), T('delete the key', 'apagar a chave'),
             T('name the one policy', 'nomear a única política')]
    x, w, gap = 20, 124, 16
    for i, (a, b, code) in enumerate(links):
        f.rect(x, 40, w, 74, stroke='--amber', fill='--scan', width=1.3)
        if code:
            f.text(x + w / 2, 58, a, size=10.5)
            f.text(x + w / 2, 80, code, size=8.5, mono=True)
            f.text(x + w / 2, 96, '"Resource": "*"', size=8.5, mono=True)
        else:
            f.lines(x + w / 2, 77, [a, b], size=10.5)
        f.arrow([(x + w + 2, 77), (x + w + gap - 2, 77)], stroke='--paper-dim')
        f.line(x + w / 2, 118, x + w / 2, 168, stroke='--phosphor', dash='3 3')
        f.rect(x + 6, 170, w - 12, 44, stroke='--phosphor', fill='--panel')
        f.text(x + w / 2, 192, fixes[i], size=10, fill='--phosphor')
        x += w + gap
    f.rect(x, 40, w, 74, stroke='--amber', fill='--scan', width=1.3)
    f.lines(x + w / 2, 77, [T('attach', 'anexar'), 'AdministratorAccess', T('to itself', 'a si mesma')],
            size=10.5)
    f.arrow([(x + w + 2, 77), (x + w + gap - 2, 77)], stroke='--amber')
    x += w + gap
    f.rect(x, 40, 700 - x, 74, stroke='--amber', fill='--panel', width=1.6)
    f.lines(x + (700 - x) / 2, 77, [T('everything', 'tudo'), T('in the account', 'na conta')], size=11,
            weight='600', fill='--amber')
    f.text(222, 240, T('cut any one link and the path is closed', 'corte qualquer elo e o caminho se fecha'),
           size=11, fill='--phosphor')
    return f, T('Three ordinary things in a row make the path, and each has its own fix. A review that '
                'finds only one of them has still found enough to close it.',
                'Três coisas comuns em sequência fazem o caminho, e cada uma tem a sua correção. Uma revisão '
                'que encontra só uma delas já encontrou o bastante para fechá-lo.')
