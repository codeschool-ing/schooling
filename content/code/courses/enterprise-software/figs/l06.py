"""Lesson 6: IBM BPM and process automation tools."""
from figures import Fig, T, figure


@figure('l06-suite', 6)
def suite():
    f = Fig('l06-suite', 720, 340, T(
        'The parts of a BPM suite, with the name each part has in IBM BPM. On the left, the '
        'modeller (Process Designer) where the process is drawn, saving into a repository of '
        'versions (Process Center). A version is deployed as a snapshot to the engine in the '
        'centre (Process Server), which runs the instances, waits, calls other systems and routes '
        'work. Below it, the engine\'s own database holds the state, the variables and the history '
        'of every instance. On the right, the engine hands tasks to people through a task list and '
        'forms (Process Portal and Coaches), calls SAP, Salesforce and the ESB through integration '
        'services, and is watched through monitoring and administration (Process Admin Console).',
        'As partes de uma suíte de BPM, com o nome que cada parte tem no IBM BPM. À esquerda, o '
        'modelador (Process Designer), onde o processo é desenhado, salvando num repositório de '
        'versões (Process Center). Uma versão é implantada como snapshot no motor, ao centro '
        '(Process Server), que executa as instâncias, espera, chama outros sistemas e distribui o '
        'trabalho. Abaixo dele, o banco de dados próprio do motor guarda o estado, as variáveis e o '
        'histórico de cada instância. À direita, o motor entrega tarefas às pessoas por uma lista '
        'de tarefas e formulários (Process Portal e Coaches), chama o SAP, o Salesforce e o ESB por '
        'serviços de integração, e é acompanhado pelo monitoramento e pela administração (Process '
        'Admin Console).'))

    def part(x, y, w, h, rows, ibm, stroke='--wire'):
        f.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill='--panel', width=1.4)
        n = len(rows) + 1
        gap = 14
        top = y - gap * (n - 1) / 2
        for i, r in enumerate(rows):
            f.text(x, top + i * gap, r, size=11)
        f.text(x, top + len(rows) * gap, ibm, size=10, fill='--paper-dim', italic=True)

    part(106, 70, 188, 54, [T('modeller: the process drawn', 'modelador: o processo desenhado')],
         'Process Designer')
    part(106, 175, 188, 54, [T('repository of versions', 'repositório de versões')], 'Process Center')
    part(362, 175, 190, 84, [T('engine: runs instances,', 'motor: executa instâncias,'),
                             T('waits, calls, routes work', 'espera, chama, distribui')],
         'Process Server', stroke='--phosphor')
    f.box(360, 292, 210, 48, [T('its own database: state,', 'banco próprio: estado,'),
                              T('variables, history', 'variáveis, histórico')], size=11, stroke='--amber')
    part(608, 70, 200, 54, [T('task list and forms', 'lista de tarefas e formulários')],
         'Process Portal, Coaches')
    part(608, 175, 200, 54, [T('integration services:', 'serviços de integração:'),
                             T('SAP, Salesforce, the ESB', 'SAP, Salesforce, o ESB')], '')
    part(608, 292, 200, 54, [T('monitoring and admin', 'monitoramento e administração')],
         'Process Admin Console')

    f.text(608, 20, T('people claim and complete tasks', 'pessoas pegam e concluem tarefas'),
           size=10, fill='--paper-dim')
    f.arrow([(608, 42), (608, 30)], stroke='--paper-dim', start=True)
    f.arrow([(106, 97), (106, 146)], stroke='--paper-dim')
    f.arrow([(202, 175), (265, 175)], stroke='--phosphor', width=1.4)
    f.text(232, 160, T('deploy', 'implanta'), size=10, fill='--paper-dim')
    f.text(232, 191, 'snapshot', size=9.5, fill='--paper-dim', mono=True)
    f.arrow([(440, 135), (506, 82)], stroke='--paper-dim', start=True)
    f.text(458, 100, T('tasks', 'tarefas'), size=10, fill='--paper-dim', anchor='end')
    f.arrow([(458, 175), (506, 175)], stroke='--paper-dim')
    f.text(482, 162, T('calls', 'chama'), size=10, fill='--paper-dim')
    f.arrow([(360, 217), (360, 266)], stroke='--paper-dim', start=True)
    f.arrow([(440, 215), (506, 280)], stroke='--paper-dim', dash='4 3', start=True)
    return f, T('A BPM suite is several products sold as one. The engine sits in the middle, and the '
                'database under it holds every instance that has ever run.',
                'Uma suíte de BPM são vários produtos vendidos como um. O motor fica no meio, e o banco '
                'de dados embaixo dele guarda cada instância que já rodou.')


@figure('l06-credit', 6)
def credit():
    f = Fig('l06-credit', 720, 320, T(
        'One credit approval at Serra Alta drawn against time, from day 0 to day 4, in three lanes: '
        'the engine, the credit analysts and the CFO. On day 0 at 09:12 a request from Salesforce '
        'starts the instance and the engine fetches a bureau score and the open items in SAP in '
        'three seconds. The analysts\' task then waits unclaimed for a day and six hours; the '
        'review takes 25 minutes. The limit asked for is R$ 240,000, above R$ 150,000, so a task '
        'goes to the CFO and waits a day and twenty hours; he approves in four minutes. The engine '
        'writes the limit into SAP through the ESB and tells the sales rep. The instance lived '
        'three days and three hours; people worked on it for under half an hour.',
        'Uma aprovação de crédito da Serra Alta desenhada contra o tempo, do dia 0 ao dia 4, em três '
        'raias: o motor, os analistas de crédito e o CFO. No dia 0 às 09:12 um pedido vindo do '
        'Salesforce inicia a instância, e o motor busca um score de birô e os títulos em aberto no '
        'SAP em três segundos. A tarefa dos analistas fica então esperando, sem dono, por um dia e '
        'seis horas; a análise leva 25 minutos. O limite pedido é de R$ 240.000, acima de '
        'R$ 150.000, então uma tarefa vai para o CFO e espera um dia e vinte horas; ele aprova em '
        'quatro minutos. O motor grava o limite no SAP pelo ESB e avisa o vendedor. A instância '
        'viveu três dias e três horas; pessoas trabalharam nela menos de meia hora.'))
    x0, day = 150, 132

    def at(d):
        return x0 + d * day

    lanes = [(70, T('engine', 'motor')), (150, T('credit analysts', 'analistas de crédito')),
             (230, T('CFO', 'CFO'))]
    gaps = {70: [], 150: [(0, 1.25 + 0.06)], 230: [(1.32 - 0.02, 3.15 + 0.06)]}
    for y, name in lanes:
        f.text(x0 - 12, y, name, size=11, anchor='end')
        start = 0
        for a, b in gaps[y] + [(4, 4)]:
            if a > start:
                f.line(at(start), y, at(a), y, stroke='--wire', width=1, dash='2 4')
            start = b
    f.line(x0, 268, at(4), 268, stroke='--paper-dim', width=1)
    for d in range(5):
        f.line(at(d), 264, at(d), 272, stroke='--paper-dim', width=1)
        f.text(at(d), 284, T(f'day {d}', f'dia {d}'), size=10, fill='--paper-dim')

    # system steps on the engine lane
    f.circle(at(0), 70, 6, fill='--phosphor')
    f.text(at(0) + 12, 50, T('09:12 request from Salesforce', '09:12 pedido do Salesforce'),
           size=10, anchor='start')
    f.text(at(0) + 12, 92, T('bureau score + SAP open items, 3 s', 'score de birô + títulos no SAP, 3 s'),
           size=10, anchor='start', fill='--paper-dim')
    # waiting for the analysts
    f.rect(at(0), 140, at(1.25) - at(0), 20, stroke='--amber', fill='--ink', dash='4 3')
    f.text((at(0) + at(1.25)) / 2, 150, T('unclaimed: 1 day 6 h', 'sem dono: 1 dia 6 h'), size=10)
    f.rect(at(1.25), 136, 6, 28, stroke='--phosphor', fill='--phosphor')
    f.text(at(1.25) + 10, 124, T('review, 25 min', 'análise, 25 min'), size=10, anchor='start')
    f.arrow([(at(1.25) + 6, 164), (at(1.32), 218)], stroke='--paper-dim')
    f.text(at(1.32) + 6, 190, T('R$ 240,000 > R$ 150,000', 'R$ 240.000 > R$ 150.000'), size=10,
           anchor='start', fill='--paper-dim')
    # waiting for the CFO
    f.rect(at(1.32), 220, at(3.15) - at(1.32), 20, stroke='--amber', fill='--ink', dash='4 3')
    f.text((at(1.32) + at(3.15)) / 2, 230, T('unclaimed: 1 day 20 h', 'sem dono: 1 dia 20 h'), size=10)
    f.rect(at(3.15), 216, 6, 28, stroke='--phosphor', fill='--phosphor')
    f.text(at(3.15) - 4, 252, T('approves, 4 min', 'aprova, 4 min'), size=10, anchor='end')
    f.arrow([(at(3.15) + 6, 216), (at(3.2), 76)], stroke='--paper-dim')
    f.circle(at(3.2), 70, 6, fill='--phosphor')
    f.text(at(3.2) - 10, 38, T('limit into SAP via the ESB;', 'limite no SAP pelo ESB;'), size=10,
           anchor='middle')
    f.text(at(3.2) - 10, 52, T('rep told. Done: 3 days 3 h', 'vendedor avisado. Fim: 3 dias 3 h'),
           size=10, anchor='middle')
    f.text(360, 306, T('people worked on it for under half an hour; the engine kept it for three days',
                       'pessoas trabalharam nela menos de meia hora; o motor a guardou por três dias'),
           size=10.5, fill='--amber', italic=True)
    return f, T('One credit approval against the clock. Almost all of its life is waiting in somebody\'s '
                'task list, and keeping track of the waiting is the engine\'s job.',
                'Uma aprovação de crédito contra o relógio. Quase toda a vida dela é espera na lista de '
                'tarefas de alguém, e acompanhar a espera é o trabalho do motor.')


@figure('l06-landscape', 6)
def landscape():
    f = Fig('l06-landscape', 720, 340, T(
        'A map of process automation tools on two axes. Across: what is automated, from a screen, '
        'through a task between applications, to a process with people that lasts days. Down: who '
        'builds it, from a business user at the top to a professional developer at the bottom. RPA '
        'tools such as UiPath and Power Automate desktop flows sit at the screen, built by both. '
        'Low-code flows, Power Automate cloud flows, sit at a task between applications, built by '
        'business users. Integration code and the ESB sit at a task between applications, built by '
        'developers. BPM suites such as IBM Business Automation Workflow, Pega and Appian sit at the '
        'long process, built by specialists in the product. Open engines such as Camunda, Flowable '
        'and jBPM sit at the long process, built by developers.',
        'Um mapa das ferramentas de automação de processos em dois eixos. Na horizontal: o que é '
        'automatizado, de uma tela, passando por uma tarefa entre aplicações, até um processo com '
        'pessoas que dura dias. Na vertical: quem constrói, de um usuário de negócio em cima a um '
        'desenvolvedor profissional embaixo. Ferramentas de RPA, como UiPath e os fluxos de desktop '
        'do Power Automate, ficam na tela, construídas pelos dois. Fluxos low-code, os fluxos de '
        'nuvem do Power Automate, ficam numa tarefa entre aplicações, construídos por usuários de '
        'negócio. Código de integração e o ESB ficam numa tarefa entre aplicações, construídos por '
        'desenvolvedores. Suítes de BPM, como IBM Business Automation Workflow, Pega e Appian, ficam '
        'no processo longo, construídas por especialistas no produto. Motores abertos, como '
        'Camunda, Flowable e jBPM, ficam no processo longo, construídos por desenvolvedores.'))
    left, right, top, bottom = 110, 705, 40, 270
    f.line(left, bottom, right, bottom, stroke='--paper-dim', width=1)
    f.line(left, top, left, bottom, stroke='--paper-dim', width=1)
    cols = [(210, T('a screen', 'uma tela')), (410, T('a task between apps', 'uma tarefa entre apps')),
            (610, T('a process with people, days', 'um processo com pessoas, dias'))]
    for x, s in cols:
        f.text(x, bottom + 16, s, size=10.5, fill='--paper-dim')
    f.text((left + right) / 2, bottom + 40, T('what is automated →', 'o que é automatizado →'),
           size=11, weight='600')
    f.lines(55, 60, [T('business', 'usuário de'), T('user', 'negócio')], size=10, fill='--paper-dim')
    f.lines(55, 250, [T('professional', 'desenvolvedor'), T('developer', 'profissional')], size=10,
            fill='--paper-dim')
    f.lines(55, 155, [T('built', 'construído'), T('by ↕', 'por ↕')], size=11, weight='600')

    def tool(x, y, head, names, stroke):
        f.rect(x - 92, y - 30, 184, 60, stroke=stroke, fill='--panel', width=1.4)
        f.text(x, y - 13, head, size=11, weight='600')
        f.text(x, y + 3, names[0], size=10, fill='--paper-dim')
        f.text(x, y + 17, names[1], size=10, fill='--paper-dim')

    tool(210, 155, 'RPA', ['UiPath, Automation Anywhere,',
                           T('Power Automate desktop', 'Power Automate desktop')], '--amber')
    tool(410, 75, T('low-code flows', 'fluxos low-code'),
         [T('Power Automate cloud', 'fluxos de nuvem do'), T('flows (lesson 3)', 'Power Automate (aula 3)')],
         '--wire')
    tool(410, 225, T('integration code', 'código de integração'),
         [T('the ESB (lesson 8),', 'o ESB (aula 8),'), T('services you write', 'serviços que você escreve')],
         '--wire')
    tool(610, 120, T('BPM suites', 'suítes de BPM'),
         ['IBM Business Automation', 'Workflow, Pega, Appian'], '--phosphor')
    tool(610, 225, T('open engines', 'motores abertos'),
         ['Camunda, Flowable, jBPM', T('in your own code', 'no seu próprio código')], '--phosphor')
    return f, T('The question is what the tool automates before it is who sells it. RPA drives a screen; '
                'a BPM suite or an engine keeps a long process with people in it.',
                'A pergunta é o que a ferramenta automatiza, antes de quem a vende. O RPA opera uma tela; '
                'uma suíte de BPM ou um motor guarda um processo longo com pessoas dentro.')


@figure('l06-versions', 6)
def versions():
    f = Fig('l06-versions', 720, 330, T(
        'Farm onboarding instances drawn as bars across six months, January to June. Version 1 of '
        'the process, the 2014 model, runs every instance started before 1 March. On 1 March '
        'version 2 is deployed, and every instance started after that runs on it. Three version 1 '
        'instances started in January and February simply finish on version 1, side by side with '
        'version 2 instances. A fourth is migrated to version 2 on 1 March, and the question at the '
        'migration is where its current step is in the new model; if version 2 deleted the step it '
        'was waiting on, the instance has nowhere to stand.',
        'Instâncias de cadastro de fazenda desenhadas como barras ao longo de seis meses, de janeiro '
        'a junho. A versão 1 do processo, o modelo de 2014, executa toda instância iniciada antes de '
        '1º de março. Em 1º de março a versão 2 é implantada, e toda instância iniciada depois disso '
        'roda nela. Três instâncias da versão 1, iniciadas em janeiro e fevereiro, simplesmente '
        'terminam na versão 1, lado a lado com as da versão 2. Uma quarta é migrada para a versão 2 '
        'em 1º de março, e a pergunta na migração é onde fica o passo em que ela está no modelo '
        'novo; se a versão 2 apagou o passo em que ela esperava, a instância fica sem onde pisar.'))
    x0, month = 150, 92

    def at(m):
        return x0 + m * month

    months = [T('Jan', 'jan'), T('Feb', 'fev'), T('Mar', 'mar'), T('Apr', 'abr'), T('May', 'mai'),
              T('Jun', 'jun')]
    f.line(x0, 268, at(6), 268, stroke='--paper-dim', width=1)
    for i, m in enumerate(months):
        f.line(at(i), 264, at(i), 272, stroke='--paper-dim', width=1)
        f.text(at(i) + month / 2, 284, m, size=10, fill='--paper-dim')
    f.lines(70, 105, [T('version 1', 'versão 1'), T('(2014 model)', '(modelo de 2014)')], size=11)
    f.lines(70, 222, [T('version 2', 'versão 2')], size=11)
    for y1, y2 in [(30, 74), (96, 99), (121, 189), (211, 264)]:
        f.line(at(2), y1, at(2), y2, stroke='--phosphor', width=1.4, dash='5 4')
    f.text(at(2), 20, T('1 March: version 2 deployed', '1º de março: versão 2 implantada'), size=10.5)

    def bar(a, b, y, stroke='--paper-dim'):
        f.rect(at(a), y - 8, at(b) - at(a), 16, stroke=stroke, fill='--panel', width=1.3)

    bar(0.3, 1.4, 60)
    bar(1.1, 2.25, 85)
    bar(1.65, 2.8, 110)
    bar(1.85, 2.0, 140, stroke='--amber')
    f.text(at(2.8) + 8, 85, T('started on version 1,', 'começaram na versão 1,'), size=10, anchor='start',
           fill='--paper-dim')
    f.text(at(2.8) + 8, 99, T('finish on version 1', 'terminam na versão 1'), size=10, anchor='start',
           fill='--paper-dim')
    bar(2.0, 2.95, 200, stroke='--amber')
    f.arrow([(at(2.0) + 2, 148), (at(2.0) + 2, 190)], stroke='--amber', width=1.4)
    f.text(at(2.0) + 10, 165, T('migrated: which step of version 2 is it on now?',
                                'migrada: em que passo da versão 2 ela está agora?'),
           size=10, anchor='start')
    bar(2.15, 3.2, 225, stroke='--phosphor')
    bar(3.4, 4.5, 225, stroke='--phosphor')
    bar(4.4, 5.6, 245, stroke='--phosphor')
    f.text(360, 312, T('both versions run at once for as long as the oldest instance lives',
                       'as duas versões rodam juntas enquanto a instância mais antiga viver'),
           size=10.5, fill='--amber', italic=True)
    return f, T('Deploying a new version does not move the instances already running. They finish on the '
                'model they started on, unless somebody migrates them and answers the question on the arrow.',
                'Implantar uma versão nova não move as instâncias que já estão rodando. Elas terminam no '
                'modelo em que começaram, a não ser que alguém as migre e responda à pergunta da seta.')
