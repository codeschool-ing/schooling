"""Lesson 8: service accounts."""
from figures import Fig, T, figure


@figure('l08-act-as', 8)
def act_as():
    f = Fig('l08-act-as', 720, 260, T(
        'How a narrow grant leaks. On the left, a developer with no role on production. In the middle, '
        'the service account prod-runner, which holds Editor on planner-prod. The developer holds '
        'serviceAccountUser on that account, drawn as an arrow to it. So the developer can create a '
        'machine that runs as prod-runner, and through it do anything Editor allows in production, drawn '
        'as a dashed arrow from the developer, through the account, to the project.',
        'Como uma concessão estreita vaza. À esquerda, um desenvolvedor sem papel nenhum na produção. No '
        'meio, a conta de serviço prod-runner, que tem Editor no planner-prod. O desenvolvedor tem '
        'serviceAccountUser nessa conta, desenhado como uma seta até ela. Então o desenvolvedor consegue '
        'criar uma máquina que roda como prod-runner, e por ela fazer tudo que o Editor permite na '
        'produção, desenhado como uma seta tracejada do desenvolvedor, pela conta, até o projeto.'))
    f.rect(20, 80, 160, 70, stroke='--wire', fill='--panel')
    f.text(100, 104, T('a developer', 'um desenvolvedor'), size=10.5)
    f.text(100, 124, T('no role on production', 'nenhum papel na produção'), size=9.5, fill='--paper-dim')
    f.rect(270, 80, 180, 70, stroke='--amber', fill='--scan', width=1.6)
    f.text(360, 104, 'prod-runner@', size=10, mono=True)
    f.text(360, 124, T('a service account', 'uma conta de serviço'), size=9.5, fill='--paper-dim')
    f.rect(540, 70, 160, 90, stroke='--phosphor', fill='--panel', width=1.6)
    f.text(620, 98, 'planner-prod', size=10.5, mono=True)
    f.text(620, 120, T('everything Editor', 'tudo que o Editor'), size=9.5, fill='--paper-dim')
    f.text(620, 136, T('may do', 'pode fazer'), size=9.5, fill='--paper-dim')
    f.arrow([(182, 115), (266, 115)], stroke='--amber', width=1.8)
    f.text(224, 102, 'serviceAccountUser', size=8.5, mono=True, fill='--amber')
    f.arrow([(452, 115), (536, 115)], stroke='--phosphor', width=1.8)
    f.text(494, 102, 'roles/editor', size=8.5, mono=True, fill='--phosphor')
    f.path('M100 152 C 100 220, 620 220, 620 164', stroke='--amber', width=1.6, dash='5 4', arrow=True)
    f.text(360, 238, T('acting as the account is holding every role it holds',
                       'agir como a conta é ter todo papel que ela tem'), size=10.5, fill='--amber')
    f.text(360, 40, T('read the policies on service accounts, not only on projects',
                      'leia as políticas das contas de serviço, não só as dos projetos'),
           size=10, fill='--paper-dim')
    return f, T('A role on a service account is a path to every role the account holds.',
                'Um papel numa conta de serviço é um caminho para todo papel que a conta tem.')
