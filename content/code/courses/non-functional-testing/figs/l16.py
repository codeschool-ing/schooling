"""Lesson 16: security testing, QA's part and the penetration test's."""
from figures import Fig, T, figure


@figure('l16-cadence', 16)
def cadence():
    f = Fig('l16-cadence', 720, 270, T(
        'A year drawn as a line, months 1 to 12. The top row is the regression tests and scanners: '
        'a short mark for every change, all year. The bottom row is a penetration test: one block '
        'of two weeks in month 2, and the next one a year later. In month 5 a defence is removed. '
        'The very next run of the tests fails; the penetration test would not look again until the '
        'following year.',
        'Um ano desenhado como uma linha, meses 1 a 12. A linha de cima são os testes de regressão e '
        'os scanners: uma marca curta a cada mudança, o ano todo. A de baixo é um pentest: um bloco '
        'de duas semanas no mês 2, e o próximo um ano depois. No mês 5 uma defesa é removida. A '
        'execução seguinte dos testes falha; o pentest só olharia de novo no ano seguinte.'))
    x0, x1 = 190, 700
    month = (x1 - x0) / 12
    f.text(360, 22, T('two ways of looking, on one calendar', 'dois jeitos de olhar, num calendário só'),
           size=11, weight='600', fill='--paper-dim')
    # the axis
    f.line(x0, 222, x1, 222, stroke='--wire', width=1.2)
    for m in range(13):
        f.line(x0 + m * month, 218, x0 + m * month, 226, stroke='--wire', width=1)
    for m in range(12):
        f.text(x0 + (m + .5) * month, 238, str(m + 1), size=9.5, fill='--paper-dim', mono=True)
    f.text(x0 + 6 * month, 256, T('months', 'meses'), size=10, fill='--paper-dim')
    # row 1: every change
    f.text(176, 76, T('tests and scanners', 'testes e scanners'), size=10.5, anchor='end', weight='600')
    f.text(176, 92, T('on every change', 'a cada mudança'), size=9.5, anchor='end', fill='--paper-dim')
    removed = x0 + 4.4 * month
    xs = [x0 + 6 + i * 9.1 for i in range(56)]
    first_after = min(x for x in xs if x > removed)
    for x in xs:
        if x == first_after:
            f.line(x, 66, x, 102, stroke='--amber', width=2.4)
        else:
            f.line(x, 72, x, 96, stroke='--phosphor', width=1.4)
    f.text(first_after + 8, 116, T('red at the next run', 'vermelho na execução seguinte'),
           size=10, anchor='start', fill='--amber')
    # row 2: one penetration test
    f.text(176, 162, T('penetration test', 'pentest'), size=10.5, anchor='end', weight='600')
    f.text(176, 178, T('once, scoped, authorised', 'uma vez, com escopo e autorização'), size=9.5,
           anchor='end', fill='--paper-dim')
    f.rect(x0 + 1.2 * month, 152, month / 2, 34, stroke='--phosphor', fill='--scan', width=1.4, rx=3)
    f.arrow([(x1 - 70, 169), (x1 - 4, 169)], stroke='--paper-dim', width=1.2)
    f.text(x1 - 76, 169, T('the next: in a year', 'o próximo: daqui a um ano'), size=9.5,
           anchor='end', fill='--paper-dim')
    # the removal
    f.line(removed, 44, removed, 210, stroke='--amber', width=1.4, dash='5 4')
    f.text(removed, 36, T('a defence is removed', 'uma defesa é removida'), size=10, fill='--amber')
    return f, T('Regression tests look at every change and a penetration test looks once, more deeply. '
                'Only one of them is there the week a defence goes missing.',
                'Os testes de regressão olham cada mudança e um pentest olha uma vez, mais fundo. Só um '
                'deles está lá na semana em que uma defesa some.')


@figure('l16-views', 16)
def views():
    f = Fig('l16-views', 720, 300, T(
        'What each kind of scanner looks at. On the left, the repository: every past commit, the source '
        'code, and the list of dependencies. Secret scanning reads the past commits, SAST reads the '
        'source code, SCA reads the dependency list. On the right, the service running on 127.0.0.1. '
        'IAST is an agent inside the running process, watching which code each request reaches. DAST '
        'stands outside and sends HTTP requests, seeing only the answers.',
        'O que cada tipo de scanner olha. À esquerda, o repositório: todos os commits passados, o código '
        'fonte e a lista de dependências. A varredura de segredos lê os commits passados, o SAST lê o '
        'código fonte, o SCA lê a lista de dependências. À direita, o serviço rodando em 127.0.0.1. O '
        'IAST é um agente dentro do processo, que vê que código cada requisição alcança. O DAST fica do '
        'lado de fora e manda requisições HTTP, vendo só as respostas.'))
    f.text(360, 22, T('five scanners, five places to look', 'cinco scanners, cinco lugares para olhar'),
           size=11, weight='600', fill='--paper-dim')
    # the repository
    f.rect(170, 50, 200, 220, stroke='--wire', fill='--panel', width=1.2)
    f.text(270, 68, T('the repository', 'o repositório'), size=10.5, weight='600')
    rows = [(110, T('every past commit', 'todo commit passado'), T('secret scanning', 'segredos')),
            (170, T('the source code', 'o código fonte'), 'SAST'),
            (230, 'requirements.txt', 'SCA')]
    for y, what, tool in rows:
        mono = what == 'requirements.txt'
        f.rect(190, y - 18, 160, 36, stroke='--wire', fill='--ink', width=1.1)
        f.text(270, y, what, size=10, mono=mono)
        f.rect(18, y - 15, 118, 30, stroke='--phosphor', fill='--scan', width=1.4)
        f.text(77, y, tool, size=10.5, weight='600')
        f.arrow([(136, y), (186, y)], stroke='--phosphor', width=1.4)
    # the running service
    f.rect(420, 50, 190, 220, stroke='--wire', fill='--panel', width=1.2)
    f.text(515, 68, T('the running service', 'o serviço rodando'), size=10.5, weight='600')
    f.text(515, 84, '127.0.0.1:8001', size=9.5, fill='--paper-dim', mono=True)
    f.rect(440, 104, 150, 120, stroke='--wire', fill='--ink', width=1.1)
    f.text(515, 122, T('the process', 'o processo'), size=10)
    f.rect(465, 150, 100, 30, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(515, 165, 'IAST', size=10.5, weight='600')
    f.text(515, 202, T('sees the code reached', 'vê o código alcançado'), size=9.5, fill='--paper-dim')
    # outside
    f.rect(636, 150, 72, 30, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(672, 165, 'DAST', size=10.5, weight='600')
    f.arrow([(636, 158), (594, 158)], stroke='--phosphor', width=1.4)
    f.arrow([(594, 172), (636, 172)], stroke='--paper-dim', width=1.2)
    f.lines(672, 206, [T('HTTP only:', 'só HTTP:'), T('sees answers', 'vê respostas')], size=9.5,
            fill='--paper-dim')
    return f, T('Each scanner sees one place. The checks a scanner cannot reach, such as whose booking '
                'this is, are the tests you write.',
                'Cada scanner vê um lugar. O que nenhum scanner alcança, como de quem é esta reserva, '
                'fica com os testes que você escreve.')
