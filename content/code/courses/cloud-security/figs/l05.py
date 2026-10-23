"""Lesson 5: the three hierarchies, and what flows down them."""
from figures import Fig, T, figure


@figure('l05-hierarchy', 5)
def hierarchy():
    f = Fig('l05-hierarchy', 720, 375, T(
        'The three hierarchies side by side, top to bottom. AWS: an organisation, organisational units, '
        'accounts, resources; the management account sits apart at the top. Azure: a tenant with its root '
        'management group, management groups, subscriptions, resource groups, resources. Google Cloud: an '
        'organisation, folders, projects, resources. Guardrails flow down at all three: SCPs, Azure '
        'Policy and Organization Policy. Grants flow down at Azure and Google Cloud, where a role given '
        'high up reaches everything below it. At AWS an identity policy stays inside its own account, and '
        'an SCP never applies to the management account.',
        'As três hierarquias lado a lado, de cima para baixo. AWS: uma organização, unidades '
        'organizacionais, contas, recursos; a conta de gerenciamento fica à parte no topo. Azure: um '
        'tenant com o grupo de gerenciamento raiz, grupos de gerenciamento, assinaturas, grupos de '
        'recursos, recursos. Google Cloud: uma organização, pastas, projetos, recursos. As proteções '
        'descem nos três: SCPs, Azure Policy e Organization Policy. As concessões descem no Azure e no '
        'Google Cloud, onde um papel dado no alto alcança tudo abaixo dele. Na AWS uma política de '
        'identidade fica dentro da própria conta, e uma SCP nunca se aplica à conta de gerenciamento.'))
    cols = [
        (20, 'AWS', [T('organisation', 'organização'), 'OU', T('account', 'conta'), T('resource', 'recurso')],
         T('SCPs', 'SCPs'), T('grants stay in the account', 'concessões ficam na conta'), 2),
        (260, 'Azure', [T('tenant, root group', 'tenant, grupo raiz'), T('management group', 'grupo de gerenciamento'),
                        T('subscription', 'assinatura'), T('resource group', 'grupo de recursos'), T('resource', 'recurso')],
         'Azure Policy', T('role assignments flow down', 'atribuições de papel descem'), 0),
        (500, 'Google Cloud', [T('organisation', 'organização'), T('folder', 'pasta'), T('project', 'projeto'),
                               T('resource', 'recurso')],
         'Organization Policy', T('allow policies flow down', 'políticas de permissão descem'), 0),
    ]
    for x, name, levels, guard, grants, grant_from in cols:
        f.text(x + 100, 22, name, size=12, weight='600')
        y = 48
        for i, lv in enumerate(levels):
            ind = i * 10
            mono = lv == 'OU'
            f.rect(x + 30 + ind, y, 170 - ind, 34, stroke='--phosphor' if i == len(levels) - 1 else '--paper-dim',
                   fill='--scan' if i == len(levels) - 1 else '--panel')
            f.text(x + 30 + ind + (170 - ind) / 2, y + 17, lv, size=10, mono=mono)
            y += 46
        bottom = y - 12
        f.arrow([(x + 12, 52), (x + 12, bottom)], stroke='--amber', width=1.6)
        f.text(x + 4, bottom + 18, guard, size=9.5, anchor='start', fill='--amber', weight='600',
               mono=(guard == 'SCPs'))
        f.text(x + 4, bottom + 34, T('flow down', 'descem'), size=9.5, anchor='start', fill='--amber')
        top = 52 + grant_from * 46
        f.arrow([(x + 22, top), (x + 22, bottom)], stroke='--phosphor', width=1.6)
        f.text(x + 4, bottom + 52, grants, size=9.5, anchor='start', fill='--phosphor')
    f.rect(36, 330, 180, 30, stroke='--amber', fill='--panel', dash='4 3')
    f.text(126, 345, T('management account: no SCP', 'conta de gerenciamento: sem SCP'), size=9.5, fill='--paper')
    return f, T('Guardrails flow down at all three. Grants flow down at two of them, which is why a role '
                'given high up for convenience reaches everything below it.',
                'As proteções descem nos três. As concessões descem em dois deles, e é por isso que um papel '
                'dado no alto por conveniência alcança tudo abaixo dele.')
