"""Lesson 7: assets, actors and abuse cases."""
from figures import Fig, T, figure

H, M, L = 3, 2, 1


@figure('l07-assets', 7)
def assets():
    rows = [
        (T('clinical notes', 'anotações clínicas'), H, H, M),
        (T('exam PDFs', 'PDFs de exames'), H, H, M),
        (T('the agenda', 'a agenda'), L, M, H),
        (T('payment status', 'situação de pagamento'), L, H, M),
        (T('patient contact data', 'contato dos pacientes'), M, M, L),
        (T('staff credentials', 'credenciais da equipe'), H, H, M),
        (T('the portal answering', 'o portal respondendo'), L, L, H),
    ]
    f = Fig('l07-assets', 720, 330, T(
        'Vereda’s assets against the three properties, each marked high, medium or low. Clinical '
        'notes: confidentiality high, integrity high, availability medium. Exam PDFs: high, high, '
        'medium. The agenda: low, medium, high. Payment status: low, high, medium. Patient contact '
        'data: medium, medium, low. Staff credentials: high, high, medium. The portal answering: '
        'low, low, high.',
        'Os ativos da Vereda contra as três propriedades, cada um marcado alto, médio ou baixo. '
        'Anotações clínicas: confidencialidade alta, integridade alta, disponibilidade média. PDFs '
        'de exames: alta, alta, média. A agenda: baixa, média, alta. Situação de pagamento: baixa, '
        'alta, média. Contato dos pacientes: média, média, baixa. Credenciais da equipe: alta, '
        'alta, média. O portal respondendo: baixa, baixa, alta.'))
    cols = [T('confidentiality', 'confidencialidade'), T('integrity', 'integridade'), T('availability', 'disponibilidade')]
    x0, cw, y0, rh = 230, 150, 50, 36
    for j, c in enumerate(cols):
        f.text(x0 + j * cw + cw / 2, 30, c, size=10.5, weight='600')
    word = {H: T('high', 'alta'), M: T('medium', 'média'), L: T('low', 'baixa')}
    fill = {H: '--amber', M: '--phosphor-dim', L: '--panel'}
    for i, (name, *vals) in enumerate(rows):
        y = y0 + i * rh
        f.text(x0 - 12, y + rh / 2 - 2, name, size=10.5, anchor='end')
        for j, v in enumerate(vals):
            x = x0 + j * cw
            f.rect(x + 6, y, cw - 12, rh - 6, stroke='--wire', fill=fill[v], width=1, rx=3)
            f.text(x + cw / 2, y + rh / 2 - 3, word[v], size=10, weight='600' if v == H else None,
                   fill='--ink' if v == H else '--paper')
    return f, T('Two assets are high on both confidentiality and integrity, and they are the two the LGPD calls sensitive. The portal itself is an asset too, and only its availability matters.',
                'Dois ativos são altos em confidencialidade e em integridade, e são os dois que a LGPD chama de sensíveis. O próprio portal também é um ativo, e só a disponibilidade dele importa.')


@figure('l07-actors', 7)
def actors():
    f = Fig('l07-actors', 720, 340, T(
        'Actors placed on two axes: how much access they start with, from none to staff, and how '
        'much capability they bring, from little to a lot. With no access and little capability: a '
        'curious stranger. With no access and some capability: someone running leaked passwords '
        'against sign-in pages. With no access and a lot of capability: an extortion group. With a '
        'patient’s access: somebody close to a patient, who knows their password or holds their '
        'phone. With staff access and little capability: a curious receptionist and a careless '
        'physiotherapist. With staff access, gone stale: a former employee whose account still '
        'works. With vendor access: an employee of the SMS provider.',
        'Atores posicionados em dois eixos: quanto acesso têm de partida, de nenhum até o da '
        'equipe, e quanta capacidade trazem, de pouca a muita. Sem acesso e com pouca capacidade: '
        'um desconhecido curioso. Sem acesso e com alguma capacidade: alguém testando senhas '
        'vazadas contra páginas de login. Sem acesso e com muita capacidade: um grupo de '
        'extorsão. Com o acesso de um paciente: alguém próximo de um paciente, que sabe a senha '
        'dele ou segura o celular dele. Com acesso de equipe e pouca capacidade: uma recepcionista '
        'curiosa e um fisioterapeuta descuidado. Com acesso de equipe, vencido: um ex-funcionário '
        'cuja conta ainda funciona. Com acesso de fornecedor: um funcionário do provedor de SMS.'))
    x0, x1, y0, y1 = 90, 700, 30, 280
    f.line(x0, y1, x1, y1, stroke='--paper-dim', width=1.2, arrow=True)
    f.line(x0, y1, x0, y0, stroke='--paper-dim', width=1.2, arrow=True)
    cols = [T('none', 'nenhum'), T('a patient’s', 'de paciente'), T('a vendor’s', 'de fornecedor'), T('staff', 'de equipe')]
    for i, c in enumerate(cols):
        f.text(x0 + 75 + i * 150, y1 + 16, c, size=9.5, fill='--paper-dim')
    f.text((x0 + x1) / 2, y1 + 36, T('access they start with', 'acesso de partida'), size=10, weight='600')
    for v, label in ((250, T('little', 'pouca')), (150, T('some', 'alguma')), (55, T('a lot', 'muita'))):
        f.text(x0 - 8, v, label, size=9.5, anchor='end', fill='--paper-dim')
    f.text(14, 20, T('capability', 'capacidade'), size=10, anchor='start', weight='600')
    pts = [
        (165, 250, T('curious stranger', 'desconhecido curioso'), '--paper-dim'),
        (165, 150, T('password-list runner', 'testador de senhas vazadas'), '--amber'),
        (165, 55, T('extortion group', 'grupo de extorsão'), '--amber'),
        (315, 210, T('someone close to a patient', 'alguém próximo de um paciente'), '--paper-dim'),
        (465, 190, T('SMS provider employee', 'funcionário do provedor de SMS'), '--paper-dim'),
        (615, 250, T('curious receptionist', 'recepcionista curiosa'), '--amber'),
        (615, 215, T('careless physio', 'fisio descuidado'), '--paper-dim'),
        (615, 120, T('former employee', 'ex-funcionário'), '--paper-dim'),
    ]
    for x, y, label, c in pts:
        f.circle(x, y, 6, fill=c)
        f.text(x, y - 13, label, size=9.5)
    f.circle(110, 312, 5, fill='--amber')
    f.text(120, 312, T('named in lesson 4’s stage 4 as active now', 'apontado no estágio 4 da aula 4 como ativo agora'), size=9.5, anchor='start')
    return f, T('Of the three actors carla’s stage 4 named, one is already inside and needs no skill at all. The grey ones were found by asking who else.',
                'Dos três atores que o estágio 4 da carla apontou, um já está dentro e não precisa de habilidade nenhuma. Os cinzas foram achados perguntando quem mais.')


@figure('l07-misuse', 7)
def misuse():
    f = Fig('l07-misuse', 720, 320, T(
        'A use case diagram with misuse cases. The patient performs book a session and receive a '
        'reminder. A misuser performs two misuse cases, drawn dark: book and cancel in a loop, '
        'which threatens receive a reminder by flooding SMS, and read another patient’s exam, '
        'which threatens view my exams. Two mitigating use cases, drawn with a green border: limit '
        'bookings per account per hour, which mitigates the loop, and check the exam belongs to '
        'the signed-in patient, which mitigates the second.',
        'Um diagrama de casos de uso com casos de abuso. O paciente executa agendar uma sessão e '
        'receber lembrete. Um abusador executa dois casos de abuso, desenhados escuros: agendar e '
        'cancelar em sequência, que ameaça receber lembrete inundando de SMS, e ler o exame de '
        'outro paciente, que ameaça ver os meus exames. Dois casos de uso de mitigação, desenhados '
        'com borda verde: limitar agendamentos por conta por hora, que mitiga a sequência, e '
        'conferir que o exame pertence ao paciente logado, que mitiga o segundo.'))
    def oval(x, y, rows, kind):
        stroke, fill, text = {'use': ('--paper-dim', '--panel', '--paper'),
                              'mis': ('--amber', '--ink', '--amber'),
                              'mit': ('--phosphor', '--panel', '--paper')}[kind]
        f.parts.append(f'<ellipse cx="{x}" cy="{y}" rx="88" ry="24" fill="var({fill})" stroke="var({stroke})" stroke-width="1.6"></ellipse>')
        f.lines(x, y, rows, size=9.5, fill=text)
    f.entity(60, 100, 90, 34, [T('Patient', 'Paciente')], size=10)
    f.entity(660, 160, 90, 34, [T('Misuser', 'Abusador')], size=10, stroke='--amber')
    oval(250, 60, [T('book a session', 'agendar uma sessão')], 'use')
    oval(250, 140, [T('receive a reminder', 'receber lembrete')], 'use')
    oval(250, 220, [T('view my exams', 'ver os meus exames')], 'use')
    oval(480, 110, [T('book and cancel', 'agendar e cancelar'), T('in a loop', 'em sequência')], 'mis')
    oval(480, 230, [T('read another', 'ler o exame de'), T('patient’s exam', 'outro paciente')], 'mis')
    oval(480, 30, [T('limit bookings per', 'limitar agendamentos'), T('account per hour', 'por conta por hora')], 'mit')
    oval(250, 280, [T('check the exam belongs', 'conferir que o exame é'), T('to the signed-in patient', 'do paciente logado')], 'mit')
    P = dict(stroke='--paper-dim', width=1.2)
    f.line(105, 95, 162, 64, **P)
    f.line(105, 105, 162, 136, **P)
    f.line(100, 117, 165, 210, **P)
    f.line(615, 155, 568, 120, stroke='--amber', width=1.2)
    f.line(615, 168, 568, 222, stroke='--amber', width=1.2)
    f.arrow([(392, 118), (338, 134)], stroke='--amber', width=1.2, dash='4 3')
    f.text(372, 150, T('threatens', 'ameaça'), size=9, fill='--amber', italic=True)
    f.arrow([(392, 228), (338, 222)], stroke='--amber', width=1.2, dash='4 3')
    f.text(366, 210, T('threatens', 'ameaça'), size=9, fill='--amber', italic=True)
    f.arrow([(480, 54), (480, 86)], stroke='--phosphor', width=1.2, dash='4 3')
    f.text(488, 70, T('mitigates', 'mitiga'), size=9, anchor='start', fill='--phosphor', italic=True)
    f.arrow([(338, 268), (420, 248)], stroke='--phosphor', width=1.2, dash='4 3')
    f.text(392, 272, T('mitigates', 'mitiga'), size=9, anchor='start', fill='--phosphor', italic=True)
    return f, T('A misuse case sits in the same picture as the feature it attacks, so the people who own the feature see it.',
                'Um caso de abuso fica na mesma figura que a funcionalidade que ele ataca, para quem é dono da funcionalidade enxergá-lo.')
