"""Lesson 2: data flow diagrams and trust boundaries."""
import math
from figures import Fig, T, figure, picture


def edge_x(cx, r, y, side):
    """Where a horizontal line at y meets a circle at cx with radius r."""
    d = math.sqrt(max(r * r - (y - cx[1]) ** 2, 0))
    return cx[0] + d if side > 0 else cx[0] - d


def num(f, x, y, n):
    f.circle(x, y, 8, fill='--ink', stroke='--paper-dim', width=1)
    f.text(x, y + 0.5, str(n), size=9, weight='600')


@figure('l02-shapes', 2)
def shapes():
    f = Fig('l02-shapes', 720, 250, T(
        'The notation. An external entity is a rectangle: somebody or something outside the system, '
        'such as a patient. A process is a circle: code that transforms data, such as the portal. A '
        'data store is two parallel lines: data at rest, such as the records database. A data flow '
        'is an arrow with a label: data moving, such as an uploaded exam. A trust boundary is a '
        'dashed line: where the level of trust changes, such as between the internet and the cloud.',
        'A notação. Uma entidade externa é um retângulo: alguém ou algo fora do sistema, como um '
        'paciente. Um processo é um círculo: código que transforma dados, como o portal. Um '
        'repositório de dados são duas linhas paralelas: dados em repouso, como o banco de '
        'prontuários. Um fluxo de dados é uma seta com rótulo: dados em movimento, como um exame '
        'enviado. Uma fronteira de confiança é uma linha tracejada: onde o nível de confiança muda, '
        'como entre a internet e a nuvem.'))
    cols = [72, 216, 360, 504, 648]
    f.entity(cols[0], 80, 100, 40, [T('Patient', 'Paciente')])
    f.process(cols[1], 80, 36, [T('Portal', 'Portal')])
    f.store(cols[2], 80, 110, [T('Records', 'Prontuários')])
    f.arrow([(cols[3] - 52, 80), (cols[3] + 52, 80)], stroke='--paper', width=1.5)
    f.text(cols[3], 68, T('exam PDF', 'PDF do exame'), size=9.5)
    f.boundary([(cols[4], 40), (cols[4], 120)])
    names = [T('external entity', 'entidade externa'), T('process', 'processo'),
             T('data store', 'repositório de dados'), T('data flow', 'fluxo de dados'),
             T('trust boundary', 'fronteira de confiança')]
    what = [[T('outside the system;', 'fora do sistema;'), T('you do not control it', 'você não controla')],
            [T('code that does', 'código que faz'), T('something to data', 'algo com dados')],
            [T('data at rest:', 'dados em repouso:'), T('a table, a bucket', 'uma tabela, um bucket')],
            [T('data in motion,', 'dados em movimento,'), T('always labelled', 'sempre com rótulo')],
            [T('where the level', 'onde o nível de'), T('of trust changes', 'confiança muda')]]
    for x, n, w in zip(cols, names, what):
        f.text(x, 152, n, size=11, weight='600')
        f.lines(x, 182, w, size=9.5, fill='--paper-dim')
    f.text(360, 228, T('A flow has a process at one end at least. Data does not move by itself.',
                       'Um fluxo tem um processo em pelo menos uma das pontas. Dado não se move sozinho.'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('Five shapes are the whole notation. The boundary is the one that makes a data flow diagram a threat model.',
                'Cinco formas são a notação inteira. A fronteira é a que transforma um diagrama de fluxo de dados num modelo de ameaças.')


@figure('l02-boundaries-redrawn', 2)
def boundaries_redrawn():
    f = Fig('l02-boundaries-redrawn', 720, 300, T(
        'The same five parts drawn twice. On the left, one boundary around everything Vereda runs, '
        'the firewall view: patient outside, portal, worker and database inside together. On the '
        'right, boundaries wherever trust changes: the portal answers the internet, so it sits in '
        'its own zone; the database and the worker sit in a private network; the SMS provider is '
        'another company. The flow from the worker to the database now crosses nothing, and the '
        'flow from the portal to the database crosses a boundary that the left drawing hid.',
        'As mesmas cinco partes desenhadas duas vezes. À esquerda, uma fronteira em volta de tudo o '
        'que a Vereda roda, a visão do firewall: o paciente fora, portal, worker e banco dentro, '
        'juntos. À direita, fronteiras onde quer que a confiança mude: o portal responde à internet, '
        'então fica numa zona própria; o banco e o worker ficam numa rede privada; o provedor de SMS '
        'é outra empresa. O fluxo do worker para o banco agora não cruza nada, e o fluxo do portal '
        'para o banco cruza uma fronteira que o desenho da esquerda escondia.'))
    for ox, title in ((0, T('one boundary: inside and outside', 'uma fronteira: dentro e fora')),
                      (370, T('a boundary wherever trust changes', 'uma fronteira onde a confiança muda'))):
        f.text(ox + 175, 20, title, size=11, weight='600')
        f.entity(ox + 50, 90, 80, 34, [T('Patient', 'Paciente')], size=9.5)
        f.process(ox + 165, 90, 30, [T('Portal', 'Portal')], size=9.5)
        f.store(ox + 165, 220, 90, [T('Database', 'Banco')], size=9.5)
        f.process(ox + 290, 220, 30, [T('Worker', 'Worker')], size=9.5)
        f.entity(ox + 290, 90, 70, 34, ['SMS'], size=9.5)
        f.arrow([(ox + 90, 90), (ox + 135, 90)], stroke='--paper-dim')
        f.arrow([(ox + 165, 120), (ox + 165, 205)], stroke='--paper-dim')
        f.arrow([(ox + 260, 220), (ox + 210, 220)], stroke='--paper-dim')
        f.arrow([(ox + 290, 190), (ox + 290, 107)], stroke='--paper-dim')
    f.zone(115, 45, 220, 220)
    f.zone(115 + 370 - 2, 45, 100, 85)
    f.zone(115 + 370 - 2, 165, 222, 100)
    f.zone(625, 45, 70, 85)
    f.text(175, 282, T('1 boundary, 2 flows cross it', '1 fronteira, 2 fluxos a cruzam'), size=10, fill='--amber')
    f.text(545, 282, T('3 boundaries, 3 flows cross one', '3 fronteiras, 3 fluxos cruzam uma'), size=10, fill='--amber')
    return f, T('The left drawing is not wrong about the firewall. It is silent about everything behind it, which is where the portal’s worst threats live.',
                'O desenho da esquerda não está errado sobre o firewall. Ele se cala sobre tudo o que está atrás dele, que é onde moram as piores ameaças do portal.')


@figure('l02-context', 2)
def context():
    f = Fig('l02-context', 720, 280, T(
        'The context diagram of the portal: the whole system as one process in the middle, called '
        'Vereda patient portal, and the four external entities around it. Patients send bookings, '
        'payments and exams and receive pages. Clinic staff manage the agenda and records. The '
        'payment gateway receives charges and sends confirmations. The SMS provider receives '
        'reminders.',
        'O diagrama de contexto do portal: o sistema inteiro como um processo só no meio, chamado '
        'portal do paciente da Vereda, e as quatro entidades externas em volta. Pacientes mandam '
        'agendamentos, pagamentos e exames e recebem páginas. A equipe da clínica cuida da agenda e '
        'dos prontuários. O gateway de pagamento recebe cobranças e manda confirmações. O provedor '
        'de SMS recebe lembretes.'))
    c = (360, 140)
    f.process(c[0], c[1], 62, [T('Vereda', 'Portal do'), T('patient portal', 'paciente Vereda')], size=10.5)
    f.entity(90, 70, 130, 40, [T('Patient', 'Paciente')])
    f.entity(90, 215, 130, 40, [T('Clinic staff', 'Equipe da clínica')])
    f.entity(630, 70, 130, 40, [T('Payment gateway', 'Gateway de pagamento')])
    f.entity(630, 215, 130, 40, [T('SMS provider', 'Provedor de SMS')])
    P = dict(stroke='--paper-dim', width=1.3)
    f.arrow([(155, 62), (305, 112)], **P)
    f.arrow([(303, 128), (155, 80)], **P)
    f.text(212, 58, T('bookings, exams', 'agendamentos, exames'), size=9.5, anchor='start')
    f.text(236, 118, T('pages', 'páginas'), size=9.5)
    f.arrow([(155, 215), (305, 168)], **P)
    f.text(212, 216, T('agenda, notes', 'agenda, anotações'), size=9.5, anchor='start')
    f.arrow([(418, 118), (565, 66)], **P)
    f.arrow([(565, 80), (420, 130)], **P)
    f.text(480, 62, T('charges', 'cobranças'), size=9.5, anchor='end')
    f.text(500, 118, T('webhook', 'webhook'), size=9.5)
    f.arrow([(418, 165), (565, 212)], **P)
    f.text(500, 205, T('reminders', 'lembretes'), size=9.5, anchor='end')
    f.text(360, 262, T('Level 0: one process, every outsider, every flow that crosses into the system.',
                       'Nível 0: um processo, todos os de fora, todo fluxo que entra no sistema.'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('The context diagram answers one question: what does the system talk to? It is the first drawing and the one an executive reads.',
                'O diagrama de contexto responde a uma pergunta: com o que o sistema conversa? É o primeiro desenho e o que um executivo lê.')


def portal_dfd(f, numbers=True, words=True):
    """The level-1 diagram of the portal, shared by the figure and the labelling picture."""
    W = (lambda en, pt: [T(en, pt)] if words else None)
    W2 = (lambda a, b: [T(*a), T(*b)] if words else None)
    f.zone(8, 30, 152, 175, T('Internet', 'Internet') if words else None)
    f.zone(8, 290, 152, 165, T('Clinic network', 'Rede da clínica') if words else None)
    f.zone(180, 30, 392, 425, T('Vereda cloud', 'Nuvem da Vereda') if words else None)
    f.zone(358, 160, 204, 285, T('Private network', 'Rede privada') if words else None, anchor='end')
    f.zone(586, 30, 126, 425, T('Vendors', 'Fornecedores') if words else None)
    pat, por, con = (84, 110), (270, 110), (270, 370)
    f.entity(pat[0], pat[1], 110, 40, W('Patient', 'Paciente'))
    f.entity(84, 370, 110, 40, W('Clinic staff', 'Equipe'))
    f.process(por[0], por[1], 44, W('Portal', 'Portal'))
    f.process(con[0], con[1], 44, W2(('Staff', 'Console'), ('console', 'da equipe')), size=9.5)
    f.store(460, 205, 130, W('Exam files', 'Arquivos de exames'), size=9.5)
    f.store(460, 290, 130, W('Records database', 'Prontuários'), size=9.5)
    f.process(460, 392, 34, W2(('Reminder', 'Worker de'), ('worker', 'lembretes')), size=9)
    f.entity(649, 110, 110, 40, W2(('Payment', 'Gateway de'), ('gateway', 'pagamento')), size=9.5)
    f.entity(649, 392, 110, 40, W2(('SMS', 'Provedor'), ('provider', 'de SMS')), size=9.5)
    A = dict(stroke='--paper', width=1.3)
    # 1, 2, 3: patient and portal
    for y, n, d in ((95, 1, 1), (110, 2, -1), (125, 3, 1)):
        x2 = edge_x(por, 44, y, -1)
        pts = [(139, y), (x2, y)] if d > 0 else [(x2, y), (139, y)]
        f.arrow(pts, **A)
    # 4: portal -> exam files ; 5: portal -> records
    f.arrow([(edge_x(por, 44, 116, 1), 116), (380, 116), (380, 200), (395, 200)], **A)
    f.arrow([(301, 141), (345, 141), (345, 285), (395, 285)], **A)
    # 6, 7: portal and the gateway
    f.arrow([(edge_x(por, 44, 96, 1), 96), (594, 96)], **A)
    f.arrow([(594, 126), (edge_x(por, 44, 126, 1) + 2, 126)], **A)
    # 8: staff -> console ; 9: console -> records ; 10: console -> exam files
    f.arrow([(139, 370), (edge_x(con, 44, 370, -1), 370)], **A)
    f.arrow([(edge_x(con, 44, 352, 1), 352), (372, 352), (372, 296), (395, 296)], **A)
    f.arrow([(270, 326), (270, 236), (330, 236), (330, 212), (395, 212)], **A)
    # 11: worker -> records ; 12: worker -> SMS
    f.arrow([(460, 358), (460, 306)], **A)
    f.arrow([(494, 392), (594, 392)], **A)
    if numbers:
        for x, y, n in ((192, 95, 1), (210, 110, 2), (192, 125, 3), (380, 158, 4), (345, 230, 5),
                        (450, 96, 6), (450, 126, 7), (180, 370, 8), (372, 324, 9), (300, 236, 10),
                        (460, 332, 11), (545, 392, 12)):
            num(f, x, y, n)


@figure('l02-portal-dfd', 2)
def portal_level1():
    f = Fig('l02-portal-dfd', 720, 465, T(
        'The level 1 data flow diagram of Vereda’s portal. Five trust boundaries: the internet, '
        'holding the patient; the clinic network, holding clinic staff; Vereda’s cloud, holding the '
        'portal and the staff console, with a private network inside it holding the exam files, the '
        'records database and the reminder worker; and the vendors, holding the payment gateway and '
        'the SMS provider. Twelve numbered flows: 1 patient to portal, sign in and book; 2 portal to '
        'patient, pages; 3 patient to portal, upload exam; 4 portal to exam files; 5 portal to '
        'records; 6 portal to gateway, charge; 7 gateway to portal, webhook; 8 staff to console; 9 '
        'console to records; 10 console to exam files; 11 worker to records; 12 worker to SMS '
        'provider.',
        'O diagrama de fluxo de dados de nível 1 do portal da Vereda. Cinco fronteiras de '
        'confiança: a internet, com o paciente; a rede da clínica, com a equipe; a nuvem da Vereda, '
        'com o portal e o console da equipe, e dentro dela uma rede privada com os arquivos de '
        'exames, o banco de prontuários e o worker de lembretes; e os fornecedores, com o gateway de '
        'pagamento e o provedor de SMS. Doze fluxos numerados: 1 paciente para portal, entrar e '
        'agendar; 2 portal para paciente, páginas; 3 paciente para portal, enviar exame; 4 portal '
        'para arquivos de exames; 5 portal para prontuários; 6 portal para gateway, cobrança; 7 '
        'gateway para portal, webhook; 8 equipe para console; 9 console para prontuários; 10 console '
        'para arquivos de exames; 11 worker para prontuários; 12 worker para provedor de SMS.'))
    portal_dfd(f)
    return f, T('Twelve flows, and eleven of them cross a boundary. The numbers are the order the model in the last section gives them.',
                'Doze fluxos, e onze cruzam uma fronteira. Os números são a ordem que o modelo da última seção dá a eles.')


@picture('portal-dfd')
def portal_picture():
    f = Fig('portal-dfd', 720, 465, (
        'The level 1 data flow diagram of a patient portal with no lettering: two rectangles on the '
        'left, each in its own dashed zone; two circles in a large dashed zone in the middle; inside '
        'that zone, a smaller dashed zone holding two pairs of parallel lines and a small circle; '
        'two rectangles in a dashed zone on the right; twelve arrows joining them.'))
    portal_dfd(f, numbers=False, words=False)
    return f


@figure('l02-mistakes', 2)
def mistakes():
    f = Fig('l02-mistakes', 720, 270, T(
        'Three mistakes, each drawn wrong on top and right below. One: an arrow from a data store '
        'straight to another data store; data does not move by itself, so a process has to be drawn '
        'between them, such as a backup job. Two: an arrow with no label; every flow says what '
        'moves, such as exam PDF. Three: an arrow between two external entities, the patient and '
        'the gateway; what happens between two outsiders is outside the model, so the flow is drawn '
        'through the process that is in it.',
        'Três erros, cada um desenhado errado em cima e certo embaixo. Um: uma seta de um '
        'repositório de dados direto para outro; dado não se move sozinho, então é preciso desenhar '
        'um processo entre eles, como um job de backup. Dois: uma seta sem rótulo; todo fluxo diz o '
        'que se move, como PDF do exame. Três: uma seta entre duas entidades externas, o paciente e '
        'o gateway; o que acontece entre dois de fora está fora do modelo, então o fluxo é desenhado '
        'passando pelo processo que está nele.'))
    P = dict(stroke='--paper-dim', width=1.3)
    heads = [T('store to store', 'repositório para repositório'), T('a flow with no name', 'um fluxo sem nome'),
             T('outsider to outsider', 'de fora para de fora')]
    for i, h in enumerate(heads):
        x = 20 + i * 235
        f.text(x + 105, 20, h, size=11, weight='600')
        f.text(x + 4, 45, T('wrong', 'errado'), size=9.5, anchor='start', fill='--amber', weight='600')
        f.text(x + 4, 150, T('right', 'certo'), size=9.5, anchor='start', fill='--phosphor', weight='600')
    # 1
    f.store(70, 85, 70, [T('Records', 'Banco')], size=9.5)
    f.store(185, 85, 70, [T('Backup', 'Backup')], size=9.5)
    f.arrow([(105, 85), (150, 85)], **P)
    f.store(55, 200, 60, [T('Records', 'Banco')], size=9)
    f.process(127, 200, 26, [T('Backup', 'Job de'), T('job', 'backup')], size=8.5)
    f.store(200, 200, 60, [T('Copy', 'Cópia')], size=9)
    f.arrow([(85, 200), (101, 200)], **P)
    f.arrow([(153, 200), (170, 200)], **P)
    # 2
    f.entity(285, 85, 64, 34, [T('Patient', 'Paciente')], size=9.5)
    f.process(420, 85, 26, [T('Portal', 'Portal')], size=9.5)
    f.arrow([(317, 85), (394, 85)], **P)
    f.entity(285, 200, 64, 34, [T('Patient', 'Paciente')], size=9.5)
    f.process(420, 200, 26, [T('Portal', 'Portal')], size=9.5)
    f.arrow([(317, 200), (394, 200)], **P)
    f.text(355, 188, T('exam PDF', 'PDF do exame'), size=9, fill='--phosphor')
    # 3
    f.entity(530, 85, 70, 34, [T('Patient', 'Paciente')], size=9.5)
    f.entity(650, 85, 70, 34, ['Gateway'], size=9.5)
    f.arrow([(565, 85), (615, 85)], **P)
    f.entity(520, 230, 64, 30, [T('Patient', 'Paciente')], size=9)
    f.process(590, 185, 24, [T('Portal', 'Portal')], size=9)
    f.entity(660, 230, 64, 30, ['Gateway'], size=9)
    f.arrow([(530, 215), (571, 200)], **P)
    f.arrow([(609, 200), (650, 215)], **P)
    return f, T('Each of these is a sign that the drawing stopped describing how data moves and started describing something else.',
                'Cada um destes é sinal de que o desenho parou de descrever como o dado se move e começou a descrever outra coisa.')


@picture('dfd-shapes')
def shapes_picture():
    f = Fig('dfd-shapes', 720, 260, (
        'A small data flow diagram with no lettering: a rectangle on the left, a dashed vertical '
        'line, a circle in the middle, an arrow from the rectangle to the circle crossing the dashed '
        'line, and a pair of parallel horizontal lines on the right with an arrow from the circle '
        'to them.'))
    f.entity(110, 130, 130, 50, None)
    f.boundary([(250, 30), (250, 230)])
    f.process(380, 130, 55, None)
    f.store(600, 130, 150, None, h=40)
    f.arrow([(175, 130), (325, 130)], stroke='--paper', width=1.6)
    f.arrow([(435, 130), (525, 130)], stroke='--paper', width=1.6)
    return f


@figure('l02-as-code', 2)
def as_code():
    f = Fig('l02-as-code', 720, 220, T(
        'The diagram as code. model.py describes the elements, flows and boundaries in Python. '
        'Running it with --json writes model.json. Small programs read model.json: flows.py lists '
        'the flows and which boundaries they cross, and lesson 3’s findings.py summarises what '
        'pytm finds. model.py lives in git, so the drawing changes in the same commits as the '
        'system it describes.',
        'O diagrama como código. O model.py descreve elementos, fluxos e fronteiras em Python. '
        'Rodá-lo com --json escreve o model.json. Programas pequenos leem o model.json: o flows.py '
        'lista os fluxos e as fronteiras que eles cruzam, e o findings.py da aula 3 resume o que o '
        'pytm acha. O model.py mora no git, então o desenho muda nos mesmos commits que o sistema '
        'que ele descreve.'))
    f.rect(20, 70, 150, 60, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(95, 92, 'model.py', size=11, mono=True, weight='600')
    f.text(95, 112, T('elements, flows', 'elementos, fluxos'), size=9.5, fill='--paper-dim')
    f.rect(250, 70, 150, 60, stroke='--paper-dim', fill='--panel', width=1.2)
    f.text(325, 92, 'model.json', size=11, mono=True, weight='600')
    f.text(325, 112, T('written by pytm', 'escrito pelo pytm'), size=9.5, fill='--paper-dim')
    f.line(170, 100, 250, 100, arrow=True)
    f.text(210, 88, '--json', size=9.5, mono=True, fill='--paper-dim')
    for i, (name, what) in enumerate([('flows.py', T('flows and boundaries', 'fluxos e fronteiras')),
                                      ('findings.py', T('what pytm finds (lesson 3)', 'o que o pytm acha (aula 3)'))]):
        y = 40 + i * 80
        f.rect(480, y, 220, 50, stroke='--paper-dim', fill='--panel', width=1.2)
        f.text(494, y + 18, name, size=10.5, mono=True, weight='600', anchor='start')
        f.text(494, y + 36, what, size=9.5, anchor='start', fill='--paper-dim')
        f.line(400, 100, 480, y + 25, arrow=True)
    f.text(95, 160, T('in git, beside the code', 'no git, ao lado do código'), size=9.5, italic=True, fill='--phosphor')
    f.text(360, 205, T('the drawing becomes something a program can check', 'o desenho vira algo que um programa consegue conferir'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('A picture only a person can read is checked when a person remembers to. A file a program reads is checked on every run.',
                'Um desenho que só uma pessoa lê é conferido quando alguém lembra. Um arquivo que um programa lê é conferido a cada execução.')
