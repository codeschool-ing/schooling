"""Lesson 5: principals."""
from figures import Fig, T, figure


@figure('l05-principals', 5)
def principals():
    f = Fig('l05-principals', 720, 280, T(
        'Where each kind of principal comes from, in three columns. From the company\'s Google '
        'directory, Cloud Identity or Workspace: user, group and domain. Made in Google Cloud: '
        'service accounts you create, default service accounts and service agents. From somebody '
        'else\'s directory, through federation: principal and principalSet, from a workforce pool for '
        'people or a workload pool for programs. Below all three, one rule: a role is granted to any '
        'of them the same way, on a resource. Apart, the two that mean everybody: allAuthenticatedUsers '
        'and allUsers.',
        'De onde vem cada tipo de principal, em três colunas. Do diretório Google da empresa, Cloud '
        'Identity ou Workspace: user, group e domain. Feitos no Google Cloud: contas de serviço que você '
        'cria, contas de serviço padrão e agentes de serviço. Do diretório de outra pessoa, por '
        'federação: principal e principalSet, de um pool de workforce para pessoas ou de um pool de '
        'workload para programas. Embaixo das três, uma regra: um papel é concedido a qualquer um deles '
        'do mesmo jeito, num recurso. À parte, os dois que querem dizer todo mundo: '
        'allAuthenticatedUsers e allUsers.'))
    cols = [(20, T('the Google directory', 'o diretório Google'), ['user:', 'group:', 'domain:'], '--phosphor'),
            (260, T('made in Google Cloud', 'feitos no Google Cloud'),
             ['serviceAccount:', T('default accounts', 'contas padrão'), T('service agents', 'agentes de serviço')], '--amber'),
            (500, T('another directory', 'outro diretório'), ['principal://', 'principalSet://',
                                                            T('workforce / workload', 'workforce / workload')], '--wire')]
    for x, head, rows, edge in cols:
        f.rect(x, 20, 200, 160, stroke=edge, fill='--panel', width=1.5)
        f.text(x + 100, 40, head, size=10.5, weight='600')
        for i, r in enumerate(rows):
            mono = r.endswith(':') or r.endswith('//')
            f.rect(x + 20, 60 + i * 38, 160, 28, stroke='--paper-dim', fill='--ink')
            f.text(x + 100, 74 + i * 38, r, size=10, mono=mono)
    for x in (120, 360, 600):
        f.arrow([(x, 182), (x, 206)], stroke='--paper-dim', width=1.2)
    f.rect(20, 208, 680, 30, stroke='--phosphor', fill='--scan')
    f.text(360, 223, T('a role is granted to any of them the same way, on a resource',
                       'um papel é concedido a qualquer um deles do mesmo jeito, num recurso'), size=10.5)
    f.text(360, 262, T('apart: allAuthenticatedUsers and allUsers, which mean everybody',
                       'à parte: allAuthenticatedUsers e allUsers, que querem dizer todo mundo'),
           size=10, fill='--amber')
    return f, T('Three origins, one way of granting.', 'Três origens, um jeito só de conceder.')
