"""Lesson 15: continuous modelling, in refinement, in design review and in CI."""
from figures import Fig, T, figure


@figure('l15-drift', 15)
def drift():
    f = Fig('l15-drift', 720, 250, T(
        'The system and its model drifting apart. Along the top, what happens to the system: '
        'features ship, a vendor changes its API, a new integration is added, staff come and go. '
        'Along the bottom, changes to the model. A model updated only once, at the start, describes '
        'a system further from the real one with every event above it. A living model changes '
        'whenever one of those events changes what it draws.',
        'O sistema e o seu modelo se afastando. Em cima, o que acontece com o sistema: '
        'funcionalidades saem, um fornecedor muda a API, uma integração nova entra, pessoas entram e '
        'saem. Embaixo, mudanças no modelo. Um modelo atualizado uma vez só, no começo, descreve um '
        'sistema cada vez mais longe do real a cada evento lá em cima. Um modelo vivo muda sempre que '
        'um desses eventos muda o que ele desenha.'))
    f.text(20, 40, T('system', 'sistema'), size=10.5, anchor='start', weight='600')
    f.text(20, 130, T('dead model', 'modelo morto'), size=10.5, anchor='start', weight='600', fill='--amber')
    f.text(20, 200, T('living model', 'modelo vivo'), size=10.5, anchor='start', weight='600', fill='--phosphor')
    for y in (40, 130, 200):
        f.line(130, y, 700, y, stroke='--paper-dim')
    events = [170, 260, 330, 430, 520, 610, 680]
    for x in events:
        f.circle(x, 40, 6, fill='--paper')
    f.circle(170, 130, 6, fill='--amber')
    for x in (170, 260, 430, 520, 680):
        f.circle(x, 200, 6, fill='--phosphor')
    f.path('M170 112 L700 64', stroke='--amber', width=1.2, dash='5 4')
    f.text(560, 104, T('the gap grows with every change', 'a distância cresce a cada mudança'), size=9.5, fill='--amber', italic=True)
    f.text(415, 235, T('not every change moves the model: only those that change what it draws', 'nem toda mudança mexe no modelo: só as que mudam o que ele desenha'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('Nobody decides to let a model die. It dies one unrecorded change at a time.',
                'Ninguém decide deixar um modelo morrer. Ele morre uma mudança não registrada de cada vez.')


@figure('l15-triggers', 15)
def triggers():
    cards = [(T('a new entry point', 'uma entrada nova'), T('a page, an API, an upload', 'uma página, uma API, um upload')),
             (T('a new kind of data', 'um tipo novo de dado'), T('above all, personal or health data', 'sobretudo dado pessoal ou de saúde')),
             (T('a new dependency', 'uma dependência nova'), T('a vendor, a library, a service', 'fornecedor, biblioteca, serviço')),
             (T('a boundary that moves', 'uma fronteira que muda'), T('something exposed, or moved inside', 'algo exposto, ou trazido para dentro')),
             (T('an incident or near miss', 'um incidente ou quase'), T('what happened, what the model said', 'o que houve, e o que o modelo dizia')),
             (T('a finding or a report', 'um achado ou um relatório'), T('an audit, a pentest, a SOC 2', 'uma auditoria, um pentest, um SOC 2')),
             (T('a review date', 'uma data de revisão'), T('from decisions/', 'de decisions/')),
             (T('a new threat in the world', 'uma ameaça nova no mundo'), T('a flaw published in something you use', 'falha publicada em algo usado'))]
    f = Fig('l15-triggers', 720, 250, T(
        'Eight events that should reopen the model. A new entry point; a new kind of data, above all '
        'personal or health data; a new dependency; a trust boundary that moves; an incident or a '
        'near miss; an audit finding, a pentest or a vendor’s report; a review date from the '
        'decision records; and a new threat in the world, such as a flaw published in something the '
        'system uses.',
        'Oito eventos que devem reabrir o modelo. Uma entrada nova; um tipo novo de dado, sobretudo '
        'dado pessoal ou de saúde; uma dependência nova; uma fronteira de confiança que muda; um '
        'incidente ou um quase incidente; um achado de auditoria, um pentest ou o relatório de um '
        'fornecedor; uma data de revisão dos registros de decisão; e uma ameaça nova no mundo, como '
        'uma falha publicada em algo que o sistema usa.'))
    for i, (head, sub) in enumerate(cards):
        x = 20 + (i % 4) * 172
        y = 20 + (i // 4) * 110
        f.rect(x, y, 162, 90, stroke='--phosphor' if i < 4 else '--amber', fill='--panel', width=1.3)
        f.text(x + 81, y + 30, head, size=10.5, weight='600')
        f.text(x + 81, y + 58, sub, size=9)
    f.text(360, 238, T('top row: found in refinement and design review · bottom row: arrive from outside', 'em cima: achados no refinamento e na revisão de projeto · embaixo: chegam de fora'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('The first four are visible in a story before it is built. The last four arrive on their own, and need somebody whose job is to notice.',
                'Os quatro primeiros são visíveis numa história antes de ela ser construída. Os quatro últimos chegam sozinhos, e precisam de alguém cujo trabalho é perceber.')


@figure('l15-story', 15)
def story():
    f = Fig('l15-story', 720, 270, T(
        'A story in refinement, with the threat questions beside it. The story: as a patient, I can '
        'download the invoice for each session I paid. Does it add an entry point? Yes, a download. '
        'New data? Yes, the patient’s tax number and amounts. A new dependency? Yes, the city’s '
        'invoice service. Does a boundary move? No. The first answer recalls T07, an exam '
        'downloaded by someone else, so R10’s rule is added to the story’s acceptance criteria.',
        'Uma história no refinamento, com as perguntas de ameaça ao lado. A história: como '
        'paciente, posso baixar a nota fiscal de cada sessão que paguei. Ela acrescenta uma entrada? '
        'Sim, um download. Dado novo? Sim, o CPF do paciente e valores. Uma dependência nova? Sim, o '
        'serviço de nota fiscal da prefeitura. Alguma fronteira muda? Não. A primeira resposta '
        'lembra a T07, um exame baixado por outra pessoa, então a regra do R10 entra nos critérios de '
        'aceite da história.'))
    f.rect(20, 20, 270, 230, stroke='--paper-dim', fill='--panel', width=1.4)
    f.text(36, 42, T('story', 'história'), size=9.5, anchor='start', fill='--paper-dim')
    f.lines(155, 90, [T('As a patient, I can', 'Como paciente, posso'), T('download the invoice', 'baixar a nota fiscal'),
                      T('for each session I paid.', 'de cada sessão que paguei.')], size=11)
    f.line(36, 140, 274, 140, stroke='--wire')
    f.text(36, 160, T('acceptance criteria', 'critérios de aceite'), size=9.5, anchor='start', fill='--paper-dim')
    f.lines(155, 202, [T('…', '…'), T('+ only the patient who paid', '+ só o paciente que pagou'), T('gets the invoice (R10)', 'recebe a nota (R10)')],
            size=10, fill='--phosphor')
    qs = [(T('a new entry point?', 'uma entrada nova?'), T('yes: a download, like T07', 'sim: um download, como a T07'), '--amber'),
          (T('new data?', 'dado novo?'), T('yes: tax number, amounts', 'sim: CPF, valores'), '--amber'),
          (T('a new dependency?', 'uma dependência nova?'), T('yes: the invoice service', 'sim: o serviço de nota'), '--amber'),
          (T('a boundary moves?', 'uma fronteira muda?'), T('no', 'não'), '--paper-dim')]
    for i, (q, a, c) in enumerate(qs):
        y = 25 + i * 58
        f.rect(320, y, 380, 48, stroke=c, fill='--panel', width=1.2)
        f.text(334, y + 16, q, size=10, anchor='start', weight='600')
        f.text(334, y + 34, a, size=10, anchor='start', fill='--amber' if c == '--amber' else '--paper-dim')
    return f, T('Four questions, a few minutes, and one requirement the story would otherwise have shipped without.',
                'Quatro perguntas, poucos minutos, e um requisito sem o qual a história teria saído.')


@figure('l15-review', 15)
def review():
    steps = [T('the change, as a DFD diff', 'a mudança, como diff de DFD'), T('STRIDE on what changed', 'STRIDE no que mudou'),
             T('threats and requirements', 'ameaças e requisitos'), T('one pull request', 'um pull request')]
    f = Fig('l15-review', 720, 170, T(
        'A design review in four steps. The change is shown as a difference to the DFD. STRIDE is '
        'applied to the elements and flows that changed, not to the whole system. The threats and '
        'requirements that result are written into the model. The model change and the code change '
        'go in the same pull request.',
        'Uma revisão de projeto em quatro passos. A mudança é mostrada como uma diferença no DFD. O '
        'STRIDE é aplicado aos elementos e fluxos que mudaram, não ao sistema inteiro. As ameaças e '
        'requisitos que resultam são escritos no modelo. A mudança do modelo e a do código vão no '
        'mesmo pull request.'))
    for i, s in enumerate(steps):
        x = 20 + i * 175
        f.rect(x, 40, 150, 60, stroke='--phosphor' if i == 3 else '--paper-dim', fill='--panel', width=1.4)
        f.text(x + 75, 70, s, size=9.5)
        if i < 3:
            f.line(x + 150, 70, x + 175, 70, arrow=True)
    f.text(360, 140, T('thirty minutes, the people who will build it, and the model open on the screen', 'trinta minutos, as pessoas que vão construir, e o modelo aberto na tela'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('A review that only looks at what changed is short enough to happen every time, which is the only frequency that keeps a model alive.',
                'Uma revisão que só olha o que mudou é curta o bastante para acontecer toda vez, que é a única frequência que mantém um modelo vivo.')


@figure('l15-ci', 15)
def ci():
    f = Fig('l15-ci', 720, 230, T(
        'The model’s check in CI. Two things start it: a pull request that changes the model, and a '
        'weekly schedule. check.sh first builds the model with pytm, so a broken model.py fails; then '
        'check_model.py compares the problems it finds with baseline.txt. A new problem or a stale '
        'baseline line fails the check and stops the merge; known problems are reported and pass.',
        'A checagem do modelo no CI. Duas coisas a disparam: um pull request que muda o modelo, e uma '
        'agenda semanal. O check.sh primeiro constrói o modelo com o pytm, então um model.py quebrado '
        'falha; depois o check_model.py compara os problemas que acha com o baseline.txt. Um problema '
        'novo ou uma linha velha do baseline falha a checagem e impede o merge; problemas conhecidos '
        'são relatados e passam.'))
    f.rect(20, 30, 150, 44, stroke='--paper-dim', fill='--panel', width=1.2)
    f.text(95, 52, T('a pull request', 'um pull request'), size=10)
    f.rect(20, 110, 150, 44, stroke='--paper-dim', fill='--panel', width=1.2)
    f.text(95, 132, T('every Monday', 'toda segunda-feira'), size=10)
    f.rect(220, 30, 160, 124, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(300, 50, 'check.sh', size=10.5, mono=True, weight='600')
    f.lines(300, 92, [T('1. model.py builds', '1. model.py constrói'), T('2. check_model.py', '2. check_model.py'), T('against baseline.txt', 'contra baseline.txt')], size=9.5)
    f.line(170, 52, 220, 70, arrow=True)
    f.line(170, 132, 220, 115, arrow=True)
    outs = [(T('known only', 'só conhecidos'), T('reported, passes', 'relatado, passa'), '--phosphor', 30),
            (T('a new problem', 'um problema novo'), T('fails: fix, decide or baseline', 'falha: corrigir, decidir ou baseline'), '--amber', 80),
            (T('a stale line', 'uma linha velha'), T('fails: remove it', 'falha: remover'), '--amber', 130)]
    for head, sub, c, y in outs:
        f.rect(440, y, 260, 40, stroke=c, fill='--panel', width=1.3)
        f.text(452, y + 13, head, size=10, anchor='start', weight='600')
        f.text(452, y + 29, sub, size=9.5, anchor='start', fill='--paper-dim')
        f.line(380, 92, 440, y + 20, arrow=True)
    f.text(360, 205, T('the schedule is what catches a date passing when nothing changed', 'a agenda é o que pega uma data passando quando nada mudou'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('A change can break the model, and so can the calendar. The check has to run for both.',
                'Uma mudança pode quebrar o modelo, e o calendário também. A checagem precisa rodar pelas duas.')


@figure('l15-measures', 15)
def measures():
    rows = [(T('open threats: no requirement, no decision', 'ameaças abertas: sem requisito, sem decisão'), '0', T('after R20 and R21', 'depois do R20 e do R21')),
            (T('known exceptions in the baseline', 'exceções conhecidas no baseline'), '3', T('R14, R17, R21 unverified', 'R14, R17, R21 sem verificação')),
            (T('current acceptances', 'aceites vigentes'), '2', T('RA-001 and RA-003', 'RA-001 e RA-003')),
            (T('acceptances overdue', 'aceites atrasados'), '0', T('on 12 October; 1 on 16 December', 'em 12 de outubro; 1 em 16 de dezembro')),
            (T('threats found from outside the model', 'ameaças achadas fora do modelo'), '2', T('T18, T19, from a SOC 2 report', 'T18, T19, de um relatório SOC 2'))]
    f = Fig('l15-measures', 720, 270, T(
        'Five measures of the model on 12 October 2026. Open threats with no requirement and no '
        'decision: 0, after R20 and R21. Known exceptions in the baseline: 3, R14, R17 and R21 '
        'unverified. Current acceptances: 2, RA-001 and RA-003. Acceptances overdue: 0 on 12 '
        'October, and 1 on 16 December. Threats found from outside the model: 2, T18 and T19, from '
        'a SOC 2 report.',
        'Cinco medidas do modelo em 12 de outubro de 2026. Ameaças abertas sem requisito e sem '
        'decisão: 0, depois do R20 e do R21. Exceções conhecidas no baseline: 3, R14, R17 e R21 sem '
        'verificação. Aceites vigentes: 2, RA-001 e RA-003. Aceites atrasados: 0 em 12 de outubro, e '
        '1 em 16 de dezembro. Ameaças achadas fora do modelo: 2, T18 e T19, de um relatório SOC 2.'))
    for i, (what, n, note) in enumerate(rows):
        y = 15 + i * 50
        f.rect(20, y, 340, 40, stroke='--wire', fill='--panel', width=1)
        f.text(32, y + 20, what, size=10, anchor='start')
        f.rect(370, y, 60, 40, stroke='--phosphor' if i < 4 else '--amber', fill='--panel', width=1.4)
        f.text(400, y + 20, n, size=13, weight='600', mono=True)
        f.text(442, y + 20, note, size=9.5, anchor='start', fill='--paper-dim')
    return f, T('Every number here comes from a file or a git log, and none of them needs anybody to remember to count.',
                'Todo número aqui vem de um arquivo ou de um git log, e nenhum precisa de alguém lembrar de contar.')
