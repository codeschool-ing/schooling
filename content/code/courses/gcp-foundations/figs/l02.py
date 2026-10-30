"""Lesson 2: the resource hierarchy."""
from figures import Fig, T, figure


@figure('l02-estate', 2)
def estate():
    f = Fig('l02-estate', 720, 330, T(
        'The estate of the company in this course, as a tree. At the top, the organisation '
        'example.com. Below it, three folders: production, non-production and shared. Under '
        'production, the project planner-prod. Under non-production, planner-staging and planner-dev, '
        'the project the lab uses, which is highlighted. Under shared, planner-network and '
        'planner-logs. Under planner-dev, two resources: the topic orders and a network. An arrow '
        'down the left side says that IAM allow policies and organisation policies are inherited '
        'downwards; a note says that billing is linked per project and is not inherited.',
        'O ambiente da empresa deste curso, como uma árvore. No topo, a organização example.com. '
        'Abaixo dela, três pastas: production, non-production e shared. Sob production, o projeto '
        'planner-prod. Sob non-production, planner-staging e planner-dev, o projeto que o laboratório '
        'usa, que está destacado. Sob shared, planner-network e planner-logs. Sob planner-dev, dois '
        'recursos: o tópico orders e uma rede. Uma seta pelo lado esquerdo diz que as políticas de '
        'permissão do IAM e as políticas da organização são herdadas para baixo; uma nota diz que o '
        'faturamento é vinculado por projeto e não é herdado.'))
    # organisation
    f.rect(290, 18, 220, 40, stroke='--amber', fill='--panel', width=1.6)
    f.text(400, 32, T('organisation', 'organização'), size=9.5, fill='--paper-dim')
    f.text(400, 47, 'example.com', size=11, mono=True)
    folders = [(150, 'production'), (400, 'non-production'), (630, 'shared')]
    for x, name in folders:
        f.line(400, 58, x, 92, stroke='--paper-dim', width=1.2)
        f.rect(x - 70, 92, 140, 36, stroke='--amber', fill='--ink', dash='5 3')
        f.text(x, 110, name, size=10.5, mono=True)
    projects = [(150, 'planner-prod', False), (335, 'planner-staging', False), (475, 'planner-dev', True),
                (585, 'planner-network', False), (680, 'planner-logs', False)]
    parents = {150: 150, 335: 400, 475: 400, 585: 630, 680: 630}
    for x, name, here in projects:
        f.line(parents[x], 128, x, 168, stroke='--paper-dim', width=1.2)
        w = 118 if len(name) > 13 else 100
        if x == 680:
            w = 82
        f.rect(x - w / 2, 168, w, 36, stroke='--phosphor', fill='--scan' if here else '--panel',
               width=2.2 if here else 1.4)
        f.text(x, 186, name, size=9.5 if len(name) > 12 else 10.5, mono=True)
    f.text(475, 218, T('the lab', 'o laboratório'), size=9.5, fill='--phosphor', weight='600')
    for x, name in ((430, 'topics/orders'), (540, 'networks/planner')):
        f.line(475, 204 if x == 430 else 204, x, 248, stroke='--paper-dim', width=1)
        f.rect(x - 52, 248, 104, 30, stroke='--wire', fill='--panel')
        f.text(x, 263, name, size=9, mono=True)
    f.text(485, 300, T('resources', 'recursos'), size=9.5, fill='--paper-dim')
    # inheritance
    f.arrow([(30, 40), (30, 290)], stroke='--amber', width=2)
    f.text(42, 220, T('inherited downwards:', 'herdado para baixo:'), size=9.5, anchor='start',
           fill='--amber')
    f.text(42, 236, T('IAM allow policies', 'políticas de permissão do IAM'), size=9.5,
           anchor='start', fill='--amber')
    f.text(42, 252, T('organisation policies', 'políticas da organização'), size=9.5,
           anchor='start', fill='--amber')
    f.text(42, 290, T('billing: per project, not inherited', 'faturamento: por projeto, sem herança'),
           size=9.5, anchor='start', fill='--paper-dim')
    return f, T('One tree per company. Rules go in at the folders and flow down to every project.',
                'Uma árvore por empresa. As regras entram nas pastas e descem para todo projeto.')
