"""Lesson 18: Shared VPC and peering."""
from figures import Fig, T, figure


@figure('l18-shared', 18)
def shared():
    f = Fig('l18-shared', 720, 300, T(
        'The host project planner-network holds the network planner, with two subnets: '
        'planner-prod-sao-paulo and planner-staging-sao-paulo, and the firewall rules. The network team runs '
        'it. Below, two service projects, planner-prod and planner-staging, each holding its own machines, '
        'which sit in the host\'s subnets: production machines in the prod subnet, staging machines in the '
        'staging subnet. The developers group holds Network User on the staging subnet only. Each service '
        'project is billed for its own machines and their traffic.',
        'O projeto host planner-network guarda a rede planner, com duas sub-redes: planner-prod-sao-paulo e '
        'planner-staging-sao-paulo, e as regras de firewall. A equipe de rede a opera. Embaixo, dois projetos '
        'de serviço, planner-prod e planner-staging, cada um com as próprias máquinas, que ficam nas sub-redes '
        'do host: máquinas de produção na sub-rede de prod, máquinas de staging na de staging. O grupo de '
        'desenvolvedores tem Network User só na sub-rede de staging. Cada projeto de serviço paga pelas '
        'próprias máquinas e pelo tráfego delas.'))
    f.rect(20, 16, 680, 120, stroke='--amber', fill='--ink', width=1.6)
    f.text(40, 34, T('host project planner-network', 'projeto host planner-network'), size=10.5, anchor='start',
           fill='--amber')
    f.text(680, 34, T('run by the network team', 'operado pela equipe de rede'), size=9, anchor='end',
           fill='--paper-dim')
    for x, name in ((60, 'planner-prod-sao-paulo'), (380, 'planner-staging-sao-paulo')):
        f.rect(x, 52, 280, 40, stroke='--phosphor', fill='--scan', width=1.4)
        f.text(x + 140, 72, name, size=9.5, mono=True)
    f.text(360, 116, T('network planner: subnets, routes, firewall rules', 'rede planner: sub-redes, rotas, regras de firewall'),
           size=9.5, fill='--paper-dim')
    for x, name, machines in ((60, 'planner-prod', T('production machines', 'máquinas de produção')),
                              (380, 'planner-staging', T('staging machines', 'máquinas de staging'))):
        f.rect(x, 180, 280, 70, stroke='--wire', fill='--panel', width=1.2)
        f.text(x + 140, 198, T(f'service project {name}', f'projeto de serviço {name}'), size=10)
        f.text(x + 140, 218, machines, size=9.5, fill='--paper-dim')
        f.text(x + 140, 236, T('billed here', 'cobradas aqui'), size=9, fill='--paper-dim')
        f.arrow([(x + 140, 178), (x + 140, 140)], stroke='--phosphor', width=1.4)
    f.text(530, 160, T('planner-devs: Network User', 'planner-devs: Network User'), size=9, anchor='start',
           fill='--phosphor')
    f.text(360, 278, T('one network, run in one place; machines and bills stay with their teams',
                       'uma rede, operada num lugar; máquinas e contas ficam com as equipes'), size=10)
    return f, T('The host owns the network; service projects own what runs in it.',
                'O host é dono da rede; os projetos de serviço, do que roda nela.')
