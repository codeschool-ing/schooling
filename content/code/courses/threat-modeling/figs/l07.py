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
    fill = {H: '--amber', M: '--panel', L: '--panel'}
    for i, (name, *vals) in enumerate(rows):
        y = y0 + i * rh
        f.text(x0 - 12, y + rh / 2 - 2, name, size=10.5, anchor='end')
        for j, v in enumerate(vals):
            x = x0 + j * cw
            f.rect(x + 6, y, cw - 12, rh - 6, stroke='--phosphor' if v == M else '--wire', fill=fill[v], width=1.6 if v == M else 1, rx=3)
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


@figure('l07-crossing', 7)
def crossing():
    uses = [T('book a session', 'agendar sessão'), T('view my exams', 'ver meus exames'), T('upload an exam', 'enviar exame'),
            T('receive a reminder', 'receber lembrete'), T('manage the agenda', 'gerenciar agenda'), T('view my bookings', 'ver agendamentos'),
            T('change my phone', 'mudar telefone'), T('pay for a session', 'pagar sessão')]
    actors = [T('password-list runner', 'quem testa senhas vazadas'), T('any patient', 'qualquer paciente'), T('signed-in patient', 'paciente logado'),
              T('someone close to a patient', 'alguém próximo do paciente'), T('curious receptionist', 'recepcionista curiosa'), T('former employee', 'quem saiu da equipe')]
    cells = [(0, 0, 'A1', 0), (0, 1, 'A2', 0), (1, 2, 'A3', 0), (2, 2, 'A4', 0), (3, 3, 'A5', 0), (4, 4, 'A6', 0),
             (4, 5, 'A7', 1), (5, 3, 'A8', 1), (6, 3, 'A9', 1), (7, 1, 'A10', 0)]
    f = Fig('l07-crossing', 720, 330, T(
        'The portal’s use cases crossed with the actors, and the ten abuse cases found in the '
        'crossings. Three of them, A7, A8 and A9, found threats nobody had listed: a former employee '
        'still signing in to manage the agenda; someone close to a patient viewing their bookings '
        'with the patient’s password; and the same person changing the phone number.',
        'Os casos de uso do portal cruzados com os atores, e os dez casos de abuso achados nos '
        'cruzamentos. Três deles, A7, A8 e A9, acharam ameaças que ninguém tinha listado: um '
        'ex-funcionário ainda entrando para gerenciar a agenda; alguém próximo de um paciente vendo '
        'os agendamentos dele com a senha do paciente; e a mesma pessoa mudando o telefone.'))
    x0, y0, cw, ch = 180, 120, 88, 24
    for j, a in enumerate(actors):
        x = x0 + j * cw + cw / 2
        words = a.split()
        half = (len(words) + 1) // 2
        f.lines(x, 80, [r for r in (' '.join(words[:half]), ' '.join(words[half:])) if r], size=9, fill='--paper-dim')
    for i, u in enumerate(uses):
        y = y0 + i * ch + ch / 2
        f.text(x0 - 8, y, u, size=9.5, anchor='end')
        f.line(x0, y0 + i * ch, x0 + 6 * cw, y0 + i * ch, stroke='--wire', width=0.6)
    f.line(x0, y0 + 8 * ch, x0 + 6 * cw, y0 + 8 * ch, stroke='--wire', width=0.6)
    for i, j, label, new in cells:
        x = x0 + j * cw + cw / 2
        y = y0 + i * ch + ch / 2
        f.rect(x - 20, y - 9, 40, 18, stroke=None if new else '--phosphor', fill='--amber' if new else '--panel', width=1.3, rx=3)
        f.text(x, y, label, size=9, weight='600', mono=True, fill='--ink' if new else '--paper')
    f.text(360, 320, T('amber: a crossing that found a threat nobody had listed', 'âmbar: um cruzamento que achou uma ameaça que ninguém tinha listado'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('Most crossings are empty, and a few retell a known threat. The ones worth the hour are the three that told a new one.',
                'A maioria dos cruzamentos é vazia, e alguns recontam uma ameaça conhecida. Os que valem a hora são os três que contaram uma nova.')


@figure('l07-refusal', 7)
def refusal():
    f = Fig('l07-refusal', 720, 220, T(
        'The refusal an abuse-case test demands. Patient P1 asks for exam E2, which belongs to '
        'patient P2, and separately for an exam that does not exist. The portal gives the same '
        'answer to both, so the asker learns nothing about whether E2 exists, and the first attempt '
        'is recorded with P1’s account and the time.',
        'A recusa que um teste de caso de abuso exige. A paciente P1 pede o exame E2, que é da '
        'paciente P2, e, separadamente, um exame que não existe. O portal dá a mesma resposta aos '
        'dois, então quem pede não descobre se o E2 existe, e a primeira tentativa é registrada com '
        'a conta de P1 e a hora.'))
    reqs = [(50, T('P1 asks for E2 (P2’s exam)', 'P1 pede o E2 (exame de P2)')), (130, T('P1 asks for an exam that does not exist', 'P1 pede um exame que não existe'))]
    for y, lab in reqs:
        f.rect(20, y - 22, 280, 44, stroke='--paper-dim', fill='--panel', width=1.2)
        f.text(160, y, lab, size=10)
        f.line(300, y, 400, 90, arrow=True)
    f.rect(400, 65, 160, 50, stroke='--phosphor', fill='--panel', width=1.5)
    f.text(480, 90, T('the same answer', 'a mesma resposta'), size=10.5, weight='600')
    f.rect(400, 150, 300, 40, stroke='--amber', fill='--panel', width=1.2)
    f.text(550, 170, T('recorded: P1’s account and the time', 'registrado: a conta de P1 e a hora'), size=10)
    f.line(330, 62, 400, 165, arrow=True, stroke='--amber')
    f.text(630, 90, T('nothing learnt', 'nada se aprende'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('A “forbidden” would confirm that E2 exists. Answering as for a missing exam turns the refusal into nothing an asker can use.',
                'Um “proibido” confirmaria que o E2 existe. Responder como para um exame inexistente faz da recusa nada que quem pede possa usar.')


@figure('l07-by-letter', 7)
def by_letter():
    counts = [('S', 5), ('T', 1), ('R', 2), ('I', 4), ('D', 2), ('E', 3)]
    f = Fig('l07-by-letter', 720, 220, T(
        'Threats in threats.csv by STRIDE letter after the abuse cases: S 5, T 1, R 2, I 4, D 2, '
        'E 3. Spoofing went from three to five, both new ones about who holds an account.',
        'Ameaças em threats.csv por letra do STRIDE depois dos casos de abuso: S 5, T 1, R 2, I 4, '
        'D 2, E 3. Falsificação foi de três para cinco, as duas novas sobre quem está com uma '
        'conta.'))
    for i, (letter, n) in enumerate(counts):
        x = 80 + i * 100
        h = n * 28
        f.rect(x, 170 - h, 60, h, stroke=None, fill='--amber' if letter == 'S' else '--phosphor-dim', rx=2)
        f.text(x + 30, 170 - h - 12, str(n), size=11, weight='600')
        f.text(x + 30, 188, letter, size=12, mono=True, weight='600')
    f.text(360, 210, T('S was 3 before the abuse cases; T15 and T17 made it 5', 'S era 3 antes dos casos de abuso; T15 e T17 o fizeram 5'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('STRIDE asked who an element talks to; the abuse cases asked who the people are, and the S column grew.',
                'O STRIDE perguntou com quem um elemento conversa; os casos de abuso perguntaram quem são as pessoas, e a coluna S cresceu.')
