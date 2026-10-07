"""Lesson 1: what threat modelling is and when to do it."""
from figures import Fig, T, figure


@figure('l01-four-questions', 1)
def four_questions():
    f = Fig('l01-four-questions', 720, 300, T(
        'The four questions as a loop. One: what are we working on, answered with a model of the '
        'system. Two: what can go wrong, answered with a list of threats. Three: what are we going '
        'to do about it, answered with mitigations and decisions. Four: did we do a good enough '
        'job, answered with a review. An arrow from the fourth returns to the first when the '
        'system changes.',
        'As quatro perguntas em ciclo. Um: no que estamos trabalhando, respondida com um modelo do '
        'sistema. Dois: o que pode dar errado, respondida com uma lista de ameaças. Três: o que '
        'vamos fazer a respeito, respondida com mitigações e decisões. Quatro: fizemos um trabalho '
        'bom o bastante, respondida com uma revisão. Uma seta da quarta volta à primeira quando o '
        'sistema muda.'))
    boxes = [
        (20, T('1  What are we', '1  No que estamos'), T('working on?', 'trabalhando?'),
         T('a model of the system', 'um modelo do sistema')),
        (195, T('2  What can', '2  O que pode'), T('go wrong?', 'dar errado?'),
         T('a list of threats', 'uma lista de ameaças')),
        (370, T('3  What are we going', '3  O que vamos'), T('to do about it?', 'fazer a respeito?'),
         T('mitigations, decisions', 'mitigações, decisões')),
        (545, T('4  Did we do a good', '4  Fizemos um trabalho'), T('enough job?', 'bom o bastante?'),
         T('a review', 'uma revisão')),
    ]
    for x, a, b, out in boxes:
        f.rect(x, 50, 155, 70, stroke='--phosphor', fill='--panel', width=1.5)
        f.lines(x + 77.5, 85, [a, b], size=11, weight='600')
        f.rect(x + 10, 150, 135, 34, stroke='--wire', fill='--scan', width=1)
        f.text(x + 77.5, 167, out, size=10)
        f.line(x + 77.5, 120, x + 77.5, 150, stroke='--paper-dim', width=1.2, arrow=True)
    for x in (175, 350, 525):
        f.line(x, 85, x + 20, 85, stroke='--phosphor', width=1.4, arrow=True)
    f.arrow([(622, 184), (622, 240), (97, 240), (97, 184)], stroke='--amber', width=1.4)
    f.text(360, 256, T('when the system changes, start again', 'quando o sistema muda, recomece'),
           size=10, fill='--amber')
    f.text(360, 26, T('Shostack’s four questions', 'As quatro perguntas de Shostack'),
           size=11, weight='600', fill='--paper-dim')
    return f, T('Each question has an answer you can hold in your hand. The fourth one is the one teams skip.',
                'Cada pergunta tem uma resposta que dá para segurar na mão. A quarta é a que as equipes pulam.')


@figure('l01-where-found', 1)
def where_found():
    f = Fig('l01-where-found', 720, 250, T(
        'One design flaw, found at five moments. At the requirement or in design, fixing it means '
        'changing a drawing in a meeting. In code, it means rewriting the module that was built on '
        'it. In testing, the rewrite plus the tests built around the old shape. In production, the '
        'rewrite, migrating the data already stored the wrong way, and possibly an incident to '
        'answer for.',
        'Uma falha de projeto, encontrada em cinco momentos. No requisito ou no projeto, corrigir é '
        'mudar um desenho numa reunião. No código, é reescrever o módulo construído em cima dela. '
        'No teste, a reescrita mais os testes feitos para a forma antiga. Em produção, a reescrita, '
        'a migração dos dados já guardados do jeito errado e, talvez, um incidente para responder.'))
    stages = [T('requirement', 'requisito'), T('design', 'projeto'), T('code', 'código'),
              T('testing', 'teste'), T('production', 'produção')]
    costs = [
        [T('change a sentence', 'mudar uma frase')],
        [T('change a drawing', 'mudar um desenho'), T('in a meeting', 'numa reunião')],
        [T('rewrite the module', 'reescrever o módulo'), T('built on it', 'construído em cima')],
        [T('the rewrite, and', 'a reescrita, e'), T('the tests around it', 'os testes em volta')],
        [T('the rewrite, a data', 'a reescrita, migrar'), T('migration, an incident', 'dados, um incidente')],
    ]
    x0, w, gap = 20, 128, 10
    for i, (s, c) in enumerate(zip(stages, costs)):
        x = x0 + i * (w + gap)
        hot = i >= 3
        f.rect(x, 40, w, 36, stroke='--amber' if hot else '--phosphor', fill='--panel', width=1.5)
        f.text(x + w / 2, 58, s, size=11, weight='600')
        h = 30 + i * 22
        f.rect(x + 14, 205 - h, w - 28, h, stroke=None, fill='--amber' if hot else '--phosphor-dim', rx=2)
        f.lines(x + w / 2, 225, c, size=9.5, gap=12)
        if i < 4:
            f.line(x + w, 58, x + w + gap, 58, stroke='--paper-dim', width=1.2, arrow=True)
    f.text(20, 100, T('what fixing it involves', 'o que corrigir envolve'), size=10, anchor='start',
           fill='--paper-dim', italic=True)
    return f, T('No percentage, because the honest number depends on the flaw. What grows is the list of things that have to change.',
                'Nenhuma porcentagem, porque o número honesto depende da falha. O que cresce é a lista de coisas que precisam mudar.')


@figure('l01-portal', 1)
def portal():
    f = Fig('l01-portal', 720, 330, T(
        'A sketch of Vereda’s patient portal, before any notation. Patients reach the portal over '
        'the internet; clinic staff reach a separate staff console from the clinics. Both read and '
        'write the records database, and both reach the exam files where uploaded PDFs are kept. A '
        'reminder worker reads tomorrow’s bookings from the database and asks an SMS provider to '
        'send a message. The portal charges sessions through a payment gateway, which calls back '
        'with a webhook.',
        'Um esboço do portal do paciente da Vereda, antes de qualquer notação. Pacientes chegam ao '
        'portal pela internet; a equipe das clínicas usa um console separado, de dentro das '
        'clínicas. Os dois leem e escrevem no banco de prontuários, e os dois chegam aos arquivos '
        'de exames, onde ficam os PDFs enviados. Um worker de lembretes lê do banco as consultas de '
        'amanhã e pede a um provedor de SMS que mande uma mensagem. O portal cobra as sessões por '
        'um gateway de pagamento, que responde com um webhook.'))
    def box(x, y, w, rows, stroke='--wire', bold=False):
        f.rect(x, y, w, 44, stroke=stroke, fill='--panel', width=1.4)
        f.lines(x + w / 2, y + 22, rows, size=10, weight='600' if bold else None)
    box(20, 40, 130, [T('patients', 'pacientes'), T('(browser, phone)', '(navegador, celular)')])
    box(20, 240, 130, [T('clinic staff', 'equipe da clínica'), T('(reception, physios)', '(recepção, fisios)')])
    box(250, 40, 140, [T('portal', 'portal'), 'portal.vereda.example'], stroke='--phosphor', bold=True)
    box(250, 240, 140, [T('staff console', 'console da equipe')], stroke='--phosphor', bold=True)
    box(470, 140, 120, [T('records', 'banco de'), T('database', 'prontuários')], stroke='--amber')
    box(470, 240, 120, [T('exam files', 'arquivos'), T('(PDFs)', 'de exames')], stroke='--amber')
    box(470, 40, 120, [T('reminder', 'worker de'), T('worker', 'lembretes')], stroke='--phosphor', bold=True)
    box(610, 40, 100, [T('SMS', 'provedor'), T('provider', 'de SMS')])
    box(250, 140, 140, [T('payment gateway', 'gateway de'), T('(Pix, card)', 'pagamento')])
    L = dict(stroke='--paper-dim', width=1.2)
    f.line(150, 62, 250, 62, **L)
    f.line(150, 262, 250, 262, **L)
    f.line(320, 84, 320, 140, **L)
    f.path('M390 62 L430 62 L430 150 L470 150', **L)
    f.path('M390 262 L430 262 L430 172 L470 172', **L)
    f.line(390, 252, 470, 252, **L)
    f.path('M390 74 L415 74 L415 280 L470 280', **L)
    f.line(530, 84, 530, 140, **L)
    f.line(590, 62, 610, 62, **L)
    f.text(360, 316, T('Lesson 2 turns this sketch into a data flow diagram.',
                       'A aula 2 transforma este esboço num diagrama de fluxo de dados.'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('Vereda’s portal as somebody would draw it on a whiteboard. Every lesson of the course models this system.',
                'O portal da Vereda como alguém o desenharia num quadro branco. Todas as aulas do curso modelam este sistema.')
