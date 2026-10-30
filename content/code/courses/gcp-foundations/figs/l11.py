"""Lesson 11: billing accounts."""
from figures import Fig, T, figure


@figure('l11-who-pays', 11)
def who_pays():
    f = Fig('l11-who-pays', 720, 270, T(
        'One billing account, beside the tree rather than in it, paying for three projects in two '
        'different folders: planner-prod, planner-dev and planner-network. Each project carries its own '
        'costs: planner-prod its machines and the traffic they send, planner-dev its topics, '
        'planner-network the Cloud NAT gateway that the other projects\' traffic goes through. Labels '
        'divide each project\'s costs by team inside the bill.',
        'Uma conta de faturamento, ao lado da árvore e não dentro dela, pagando três projetos em duas '
        'pastas diferentes: planner-prod, planner-dev e planner-network. Cada projeto leva os próprios '
        'custos: planner-prod as suas máquinas e o tráfego que elas mandam, planner-dev os seus tópicos, '
        'planner-network o gateway do Cloud NAT por onde passa o tráfego dos outros projetos. Rótulos '
        'dividem os custos de cada projeto por equipe dentro da fatura.'))
    f.rect(270, 16, 180, 48, stroke='--amber', fill='--panel', width=1.6)
    f.text(360, 32, T('billing account', 'conta de faturamento'), size=10, fill='--paper-dim')
    f.text(360, 50, '012345-6789AB-CDEF01', size=9.5, mono=True)
    projects = [(110, 'planner-prod', T('machines, and the', 'máquinas, e o tráfego'),
                 T('traffic they send', 'que elas mandam')),
                (360, 'planner-dev', T('topics', 'tópicos'), ''),
                (610, 'planner-network', T('the Cloud NAT', 'o gateway do'), T('gateway', 'Cloud NAT'))]
    for x, name, a, b in projects:
        f.line(360, 64, x, 116, stroke='--amber', width=1.4)
        f.rect(x - 90, 116, 180, 84, stroke='--phosphor', fill='--panel', width=1.4)
        f.text(x, 134, name, size=10.5, mono=True)
        f.text(x, 158, a, size=9.5, fill='--paper-dim')
        if b:
            f.text(x, 174, b, size=9.5, fill='--paper-dim')
    f.text(360, 98, T('each project linked to one account', 'cada projeto vinculado a uma conta'),
           size=9.5, fill='--amber')
    f.text(360, 228, T('inside each project, labels divide the costs by team',
                       'dentro de cada projeto, rótulos dividem os custos por equipe'), size=10.5)
    f.text(360, 250, T('the account sits beside the folders, not in them',
                       'a conta fica ao lado das pastas, não dentro delas'), size=9.5, fill='--paper-dim')
    return f, T('The project carries the cost; its link says which account pays.',
                'O projeto leva o custo; o vínculo dele diz que conta paga.')
