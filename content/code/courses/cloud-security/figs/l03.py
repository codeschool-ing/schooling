"""Lesson 3: the booking system's security to-do list on IaaS, PaaS and SaaS."""
from figures import Fig, T, figure


@figure('l03-lists', 3)
def lists():
    f = Fig('l03-lists', 720, 330, T(
        'The clinic\'s booking system, and what a security engineer has to check if it runs on each '
        'model. On IaaS, a virtual machine: the image and its patches, the ports open to the internet, '
        'the metadata service and the machine\'s role, the runtime and the application, then the data '
        'and the access. On PaaS, a function: the runtime version, the code and its libraries, the '
        'function\'s role, who may invoke it, then the data and the access. On SaaS, a rented product: '
        'the accounts, the sharing settings, the connected applications, retention and the audit log, '
        'then the data and the access. The items change from one model to the next, and all three '
        'lists end with the same two.',
        'O sistema de agendamento da clínica, e o que um engenheiro de segurança precisa conferir se ele '
        'rodar em cada modelo. No IaaS, uma máquina virtual: a imagem e as correções, as portas abertas '
        'para a internet, o serviço de metadados e o papel da máquina, o runtime e a aplicação, e então '
        'os dados e o acesso. No PaaS, uma função: a versão do runtime, o código e as bibliotecas, o '
        'papel da função, quem pode invocá-la, e então os dados e o acesso. No SaaS, um produto alugado: '
        'as contas, as configurações de compartilhamento, as aplicações conectadas, a retenção e o log '
        'de auditoria, e então os dados e o acesso. Os itens mudam de um modelo para o outro, e as três '
        'listas terminam com os mesmos dois.'))
    cols = [
        ('IaaS', T('a virtual machine', 'uma máquina virtual'), [
            T('the image and its patches', 'a imagem e as correções'),
            T('ports open to the internet', 'portas abertas para a internet'),
            T("metadata service, machine's role", 'serviço de metadados, papel'),
            T('runtime and application', 'runtime e aplicação')]),
        ('PaaS', T('a function', 'uma função'), [
            T('the runtime version', 'a versão do runtime'),
            T('code and its libraries', 'código e bibliotecas'),
            T("the function's role", 'o papel da função'),
            T('who may invoke it', 'quem pode invocá-la')]),
        ('SaaS', T('a rented product', 'um produto alugado'), [
            T('accounts and sign-in', 'contas e login'),
            T('sharing settings', 'configurações de compartilhamento'),
            T('connected applications', 'aplicações conectadas'),
            T('retention and audit log', 'retenção e log de auditoria')]),
    ]
    for i, (name, what, items) in enumerate(cols):
        x = 30 + i * 230
        f.text(x + 100, 22, name, size=12.5, weight='600')
        f.text(x + 100, 42, what, size=10, fill='--paper-dim', italic=True)
        y = 60
        for it in items:
            f.rect(x, y, 200, 30, stroke='--phosphor', fill='--panel')
            f.text(x + 12, y + 15, it, size=10, anchor='start')
            y += 36
        for k, it in enumerate([T('the data', 'os dados'), T('who can reach it', 'quem os alcança')]):
            yy = 220 + k * 36
            f.rect(x, yy, 200, 30, stroke='--amber', fill='--scan', width=1.4)
            f.text(x + 12, yy + 15, it, size=10, anchor='start', weight='600')
    f.text(360, 310, T('the same last two items on every list', 'os mesmos dois últimos itens em toda lista'),
           size=10.5, fill='--amber')
    return f, T('Each model swaps the items above for others of a different shape; none of them takes away '
                'the last two.',
                'Cada modelo troca os itens de cima por outros de outro formato; nenhum tira os dois últimos.')
