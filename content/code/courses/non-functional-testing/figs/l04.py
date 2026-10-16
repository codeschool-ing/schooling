"""Lesson 4: JMeter."""
from figures import Fig, T, figure


@figure('l04-tree', 4)
def tree():
    f = Fig('l04-tree', 720, 330, T(
        'The test plan of this lesson drawn as the tree JMeter keeps. At the root, the test plan. Under '
        'it, three children: HTTP Request Defaults and the CSV Data Set Config, which are config '
        'elements, and the thread group called visitors. Under the thread group: the sampler GET /shows, '
        'the sampler GET /shows/{id} with a response assertion inside it, and the uniform random timer. '
        'A bracket marks the timer\'s scope as both samplers; another marks the assertion\'s scope as '
        'the second sampler only.',
        'O plano de teste desta aula desenhado como a árvore que o JMeter guarda. Na raiz, o plano de '
        'teste. Abaixo dele, três filhos: HTTP Request Defaults e o CSV Data Set Config, que são '
        'elementos de configuração, e o thread group chamado visitors. Abaixo do thread group: o sampler '
        'GET /shows, o sampler GET /shows/{id} com uma response assertion dentro dele, e o uniform random '
        'timer. Um colchete marca o escopo do timer como os dois samplers; outro marca o escopo da '
        'asserção como só o segundo sampler.'))
    rows = [
        (0, 'TestPlan', 'boxoffice', T('root', 'raiz'), '--paper-dim'),
        (1, 'HTTP Request Defaults', T('the box office', 'a bilheteria'), T('config element', 'configuração'), '--paper-dim'),
        (1, 'CSV Data Set Config', 'show ids', T('config element', 'configuração'), '--paper-dim'),
        (1, 'Thread Group', 'visitors', T('the users', 'os usuários'), '--phosphor'),
        (2, 'HTTP Request', 'GET /shows', T('sampler', 'sampler'), '--phosphor'),
        (2, 'HTTP Request', 'GET /shows/{id}', T('sampler', 'sampler'), '--phosphor'),
        (3, 'Response Assertion', T('says how many seats are left', 'says how many seats are left'), T('assertion: checks its parent only', 'asserção: confere só o seu pai'), '--amber'),
        (2, 'Uniform Random Timer', T('think 1 to 2 s', 'think 1 to 2 s'), T('timer: before every sampler beside it', 'timer: antes de cada sampler ao seu lado'), '--amber'),
    ]
    top, rh = 22, 38
    for i, (lvl, kind, name, fam, col) in enumerate(rows):
        y = top + i * rh
        x = 30 + lvl * 40
        if lvl:
            f.path(f'M{x - 26:.1f} {y - 10:.1f} L{x - 26:.1f} {y + 14:.1f} L{x:.1f} {y + 14:.1f}',
                   stroke='--wire', width=1.2)
        f.rect(x, y, 300, 28, stroke=col, fill='--panel', width=1.3)
        f.text(x + 10, y + 14, kind, size=10, anchor='start', mono=True)
        f.text(x + 290, y + 14, name, size=10, anchor='end', fill='--paper-dim')
        f.text(480, y + 14, fam, size=10, anchor='start', fill='--paper-dim')
    return f, T('Scope is the tree. An element applies to the samplers at its own level and below it.',
                'O escopo é a árvore. Um elemento vale para os samplers no seu nível e abaixo dele.')


@figure('l04-distributed', 4)
def distributed():
    f = Fig('l04-distributed', 720, 300, T(
        'Distributed execution. On the left, the controller, which runs jmeter with -R. It sends the '
        'test plan and the -G properties to two workers, each running jmeter-server and each with its '
        'own copy of shows.csv. Both workers run the whole plan and send their requests to the system '
        'under test on the right. The samples travel back from each worker to the controller, which '
        'writes one results file. Ten users a worker on two workers is twenty users in all.',
        'Execução distribuída. À esquerda, o controlador, que roda o jmeter com -R. Ele envia o plano '
        'de teste e as propriedades -G para dois workers, cada um rodando o jmeter-server e cada um com '
        'a sua própria cópia de shows.csv. Os dois workers rodam o plano inteiro e enviam as suas '
        'requisições para o sistema sob teste à direita. As amostras voltam de cada worker para o '
        'controlador, que grava um arquivo de resultados. Dez usuários por worker em dois workers são '
        'vinte usuários ao todo.'))
    f.rect(20, 105, 150, 90, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(95, 128, T('controller', 'controlador'), size=11.5, weight='600')
    f.text(95, 152, 'jmeter -n -R …', size=9.5, mono=True)
    f.text(95, 174, 'dist.jtl', size=9.5, mono=True, fill='--paper-dim')
    for k, (y, port) in enumerate([(40, '1099'), (200, '1100')]):
        f.rect(285, y, 160, 70, stroke='--paper-dim', fill='--panel', width=1.3)
        f.text(365, y + 18, T(f'worker {k + 1}', f'worker {k + 1}'), size=11, weight='600')
        f.text(365, y + 38, f'jmeter-server :{port}', size=9.5, mono=True)
        f.text(365, y + 56, 'shows.csv', size=9.5, mono=True, fill='--paper-dim')
        ya = y + 25
        f.arrow([(172, 140 if k == 0 else 160), (283, ya)], stroke='--paper', width=1.3)
        f.arrow([(283, ya + 22), (172, 150 if k == 0 else 170)], stroke='--phosphor', width=1.3, dash='4 3')
        f.arrow([(447, y + 35), (553, 150 + (k * 2 - 1) * 12)], stroke='--amber', width=1.5)
    f.text(95, 90, T('sends the plan, -G', 'envia o plano, -G'), size=9.5)
    f.text(95, 212, T('samples come back', 'amostras voltam'), size=9.5, fill='--phosphor')
    f.rect(555, 115, 145, 70, stroke='--amber', fill='--panel', width=1.4)
    f.lines(627, 150, [T('system under test', 'sistema sob teste'), '127.0.0.1:8000'], size=10)
    f.text(500, 278, T('each worker runs the whole plan: 10 users each, 20 in all',
                       'cada worker roda o plano inteiro: 10 usuários cada, 20 ao todo'),
           size=9.5, fill='--paper-dim')
    return f, T('One controller, several workers. The plan travels to the workers; the files it reads do not.',
                'Um controlador, vários workers. O plano viaja até os workers; os arquivos que ele lê, não.')
