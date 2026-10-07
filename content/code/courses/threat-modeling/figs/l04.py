"""Lesson 4: PASTA."""
from figures import Fig, T, figure


@figure('l04-seven-stages', 4)
def seven_stages():
    f = Fig('l04-seven-stages', 720, 270, T(
        'The seven stages of PASTA in order, grouped by whose view they take. Stage 1, define the '
        'objectives, and stage 7, risk and impact analysis, take the business’s view and open and '
        'close the process. Stages 2 and 3, technical scope and decomposition, take the system’s '
        'view. Stages 4, 5 and 6, threat analysis, weakness analysis and attack modelling, take the '
        'attacker’s view. An arrow from stage 7 returns to stage 1.',
        'Os sete estágios do PASTA em ordem, agrupados pelo ponto de vista de cada um. O estágio 1, '
        'definir os objetivos, e o estágio 7, análise de risco e impacto, adotam a visão do negócio '
        'e abrem e fecham o processo. Os estágios 2 e 3, escopo técnico e decomposição, adotam a '
        'visão do sistema. Os estágios 4, 5 e 6, análise de ameaças, análise de fraquezas e '
        'modelagem de ataques, adotam a visão do atacante. Uma seta do estágio 7 volta ao '
        'estágio 1.'))
    stages = [
        ('1', [T('objectives', 'objetivos')], '--amber'),
        ('2', [T('technical', 'escopo'), T('scope', 'técnico')], '--phosphor'),
        ('3', [T('decomposition', 'decomposição')], '--phosphor'),
        ('4', [T('threat', 'análise de'), T('analysis', 'ameaças')], '--paper-dim'),
        ('5', [T('weakness', 'análise de'), T('analysis', 'fraquezas')], '--paper-dim'),
        ('6', [T('attack', 'modelagem'), T('modelling', 'de ataques')], '--paper-dim'),
        ('7', [T('risk and', 'análise de risco'), T('impact', 'e impacto')], '--amber'),
    ]
    w, gap, x0, y = 88, 13, 14, 90
    for i, (n, rows, c) in enumerate(stages):
        x = x0 + i * (w + gap)
        f.rect(x, y, w, 64, stroke=c, fill='--panel', width=1.6)
        f.text(x + 12, y + 13, n, size=11, weight='600', fill=c if c != '--paper-dim' else '--paper')
        f.lines(x + w / 2, y + 36, rows, size=10)
        if i < 6:
            f.line(x + w, y + 32, x + w + gap, y + 32, stroke='--paper-dim', width=1.2, arrow=True)
    groups = [(0, 0, T('the business', 'o negócio'), '--amber'), (1, 2, T('the system', 'o sistema'), '--phosphor'),
              (3, 5, T('the attacker', 'o atacante'), '--paper'), (6, 6, T('the business', 'o negócio'), '--amber')]
    for a, b, label, c in groups:
        xa, xb = x0 + a * (w + gap), x0 + b * (w + gap) + w
        f.line(xa, 72, xb, 72, stroke=c if c != '--paper' else '--paper-dim', width=1.6)
        f.text((xa + xb) / 2, 60, label, size=10.5, weight='600', fill=c)
    last = x0 + 6 * (w + gap) + w / 2
    first = x0 + w / 2
    f.arrow([(last, y + 64), (last, 200), (first, 200), (first, y + 64)], stroke='--amber', width=1.3)
    f.text(360, 216, T('what stage 7 learns changes the objectives of the next round',
                       'o que o estágio 7 aprende muda os objetivos da rodada seguinte'),
           size=10, fill='--amber')
    f.text(360, 250, T('Stages 1 and 7 are why PASTA is called risk-centric: it starts and ends with what the business stands to lose.',
                       'Os estágios 1 e 7 são o motivo de o PASTA ser chamado de centrado em risco: começa e termina no que o negócio pode perder.'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('Three views in seven steps. STRIDE lives mostly in the middle three; PASTA wraps them in the business.',
                'Três visões em sete passos. O STRIDE vive sobretudo nos três do meio; o PASTA os envolve no negócio.')


@figure('l04-objectives', 4)
def objectives():
    f = Fig('l04-objectives', 720, 300, T(
        'Stage 1 meets stage 4. On the left, Vereda’s four business objectives: patients book and '
        'pay; clinical data stays private; reminders reach patients; Vereda meets the LGPD. On the '
        'right, the threats that endanger each. Bookings and payment: T01, T02, T06, T10. Private '
        'clinical data: T03, T07, T09, T12, T13, T14. Reminders: T11. The LGPD: T05, T08, T09, T07. '
        'T09 and T07 reach two objectives each.',
        'O estágio 1 encontra o estágio 4. À esquerda, os quatro objetivos de negócio da Vereda: '
        'pacientes agendam e pagam; dado clínico continua privado; lembretes chegam aos pacientes; '
        'a Vereda cumpre a LGPD. À direita, as ameaças que põem cada um em risco. Agendamentos e '
        'pagamento: T01, T02, T06, T10. Dado clínico privado: T03, T07, T09, T12, T13, T14. '
        'Lembretes: T11. LGPD: T05, T08, T09, T07. T09 e T07 alcançam dois objetivos cada.'))
    objs = [T('patients book and pay', 'pacientes agendam e pagam'),
            T('clinical data stays private', 'dado clínico continua privado'),
            T('reminders reach patients', 'lembretes chegam aos pacientes'),
            T('Vereda meets the LGPD', 'a Vereda cumpre a LGPD')]
    links = [['T01', 'T02', 'T06', 'T10'], ['T03', 'T07', 'T09', 'T12', 'T13', 'T14'], ['T11'],
             ['T05', 'T07', 'T08', 'T09']]
    ids = ['T01', 'T02', 'T03', 'T05', 'T06', 'T07', 'T08', 'T09', 'T10', 'T11', 'T12', 'T13', 'T14']
    ys = {t: 22 + i * 21 for i, t in enumerate(ids)}
    for i, o in enumerate(objs):
        y = 40 + i * 66
        f.rect(20, y, 230, 40, stroke='--amber', fill='--panel', width=1.5)
        f.text(135, y + 20, o, size=10.5, weight='600')
        for t in links[i]:
            f.path(f'M250 {y + 20} C 400 {y + 20}, 450 {ys[t]}, 590 {ys[t]}', stroke='--wire', width=1.2)
    for t, y in ys.items():
        f.rect(590, y - 8, 44, 16, stroke='--paper-dim', fill='--ink', width=1, rx=3)
        f.text(612, y + 0.5, t, size=9, weight='600', mono=True)
    f.text(650, 30, T('stage 4', 'estágio 4'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(135, 22, T('stage 1', 'estágio 1'), size=9.5, fill='--paper-dim')
    return f, T('T04 is missing on the right because no objective written in stage 1 names the integrity of exams. That is a gap in the objectives, not in the threats.',
                'A T04 falta à direita porque nenhum objetivo escrito no estágio 1 fala da integridade dos exames. É uma lacuna nos objetivos, não nas ameaças.')


@figure('l04-attack-paths', 4)
def attack_paths():
    f = Fig('l04-attack-paths', 720, 300, T(
        'Stage 6 from the defender’s side: three paths to one goal, every patient’s clinical '
        'record. Path one: a phished staff password (T03), used from the internet because the '
        'console answers there (T12), with receptionists able to read notes (T09). Path two: a '
        'flaw in the reminder worker, which connects as the database owner (T13). Path three: a '
        'leaked patient password (T02) followed by changing exam numbers (T07), which reaches '
        'exams but not notes. Under each step, the control that breaks the path: a second factor, '
        'the console behind the clinic network, roles that hide notes, a least-privilege database '
        'account, and an ownership check on downloads.',
        'O estágio 6 pelo lado de quem defende: três caminhos para um objetivo, o prontuário de '
        'todos os pacientes. Caminho um: uma senha da equipe roubada por phishing (T03), usada pela '
        'internet porque o console responde lá (T12), com recepcionistas podendo ler anotações '
        '(T09). Caminho dois: uma falha no worker de lembretes, que se conecta como dono do banco '
        '(T13). Caminho três: uma senha de paciente vazada (T02) seguida da troca do número do '
        'exame (T07), que alcança exames mas não anotações. Sob cada passo, o controle que quebra o '
        'caminho: segundo fator, o console atrás da rede da clínica, papéis que escondem '
        'anotações, uma conta de banco com o mínimo de privilégio e uma verificação de dono nos '
        'downloads.'))
    f.rect(250, 14, 220, 40, stroke='--amber', fill='--panel', width=1.8)
    f.text(360, 34, T('every patient’s clinical record', 'o prontuário de todos os pacientes'), size=10.5, weight='600')
    paths = [
        (20, [('T03', T('staff password phished', 'senha da equipe roubada'), T('second factor', 'segundo fator')),
              ('T12', T('console from the internet', 'console pela internet'), T('clinic network only', 'só pela rede da clínica')),
              ('T09', T('receptionist reads notes', 'recepção lê anotações'), T('roles hide notes', 'papéis escondem notas'))]),
        (260, [('T13', T('flaw in the worker, as owner', 'falha no worker, como dono'), T('least-privilege account', 'conta com mínimo privilégio'))]),
        (500, [('T02', T('patient password leaked', 'senha de paciente vazada'), T('second factor, rate limit', 'segundo fator, limite')),
               ('T07', T('exam number changed', 'número do exame trocado'), T('ownership check', 'checagem de dono'))]),
    ]
    for x, steps in paths:
        n = len(steps)
        for i, (tid, what, ctl) in enumerate(steps):
            y = 240 - i * 62
            f.rect(x, y - 22, 200, 30, stroke='--paper-dim', fill='--panel', width=1.2)
            f.text(x + 8, y - 7, tid, size=9, anchor='start', weight='600', fill='--amber', mono=True)
            f.text(x + 112, y - 7, what, size=9.5)
            f.text(x + 8, y + 18, ctl, size=9, anchor='start', fill='--phosphor', italic=True)
            if i < n - 1:
                f.line(x + 185, y - 22, x + 185, y - 54, stroke='--paper-dim', width=1.2, arrow=True)
        top = 240 - (n - 1) * 62 - 22
        f.arrow([(x + 185, top), (x + 185, top - 14), (360 + (x - 260) * 0.4, 70), (360 + (x - 260) * 0.4, 54)],
                stroke='--amber', width=1.3)
    f.text(700, 290, T('reaches exams, not notes', 'alcança exames, não notas'), size=9, anchor='end', fill='--paper-dim', italic=True)
    return f, T('Each path is a chain of threats already on the list. Breaking any one step breaks the path, which is how stage 7 chooses where to spend.',
                'Cada caminho é uma cadeia de ameaças que já estão na lista. Quebrar qualquer passo quebra o caminho, e é assim que o estágio 7 escolhe onde gastar.')


@figure('l04-first-stages', 4)
def first_stages():
    f = Fig('l04-first-stages', 720, 230, T(
        'What PASTA’s first three stages produced at Vereda. Stage 1, objectives: about 60% of '
        'bookings come through the portal, and health data is sensitive under the LGPD. Stage 2, '
        'technical scope: what is modelled and what is not, such as the clinics’ Wi-Fi and laptops. Stage 3, '
        'decomposition: the DFD of lesson 2, with the use cases beside it.',
        'O que os três primeiros estágios do PASTA produziram na Vereda. Estágio 1, objetivos: cerca '
        'de 60% dos agendamentos passam pelo portal, e dado de saúde é sensível pela LGPD. Estágio 2, '
        'escopo técnico: o que é modelado e o que não é, como o Wi-Fi e os laptops das clínicas. Estágio 3, '
        'decomposição: o DFD da aula 2, com os casos de uso ao lado.'))
    cols = [(T('1 · objectives', '1 · objetivos'), [T('60% of bookings', '60% dos agendamentos'), T('via the portal', 'pelo portal'), T('health data is', 'dado de saúde é'), T('sensitive (LGPD)', 'sensível (LGPD)')]),
            (T('2 · technical scope', '2 · escopo técnico'), [T('what is modelled,', 'o que é modelado,'), T('and what is not:', 'e o que não é:'), T('the clinics’ Wi-Fi', 'o Wi-Fi e os laptops'), T('and laptops', 'das clínicas')]),
            (T('3 · decomposition', '3 · decomposição'), [T('the DFD of lesson 2', 'o DFD da aula 2'), T('and the use cases', 'e os casos de uso'), T('beside it', 'ao lado dele'), T('', '')])]
    for i, (head, rows) in enumerate(cols):
        x = 20 + i * 235
        f.rect(x, 20, 210, 180, stroke='--phosphor' if i == 0 else '--paper-dim', fill='--panel', width=1.4)
        f.text(x + 105, 42, head, size=11, weight='600')
        f.lines(x + 105, 120, [r for r in rows if r], size=10)
        if i < 2:
            f.line(x + 210, 110, x + 235, 110, arrow=True)
    f.text(360, 220, T('the business first, then the system', 'primeiro o negócio, depois o sistema'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('Stage 1 is the one STRIDE never asks for, and it is the one that later decides which threats are expensive.',
                'O estágio 1 é o que o STRIDE nunca pede, e é ele que depois decide quais ameaças são caras.')


@figure('l04-cwe-join', 4)
def cwe_join():
    rows = [('T01', T('forged webhook', 'webhook forjado'), 'CWE-345'), ('T07', T('other patients’ PDFs', 'PDFs de outros pacientes'), 'CWE-639'),
            ('T10', T('uploads with no limit', 'uploads sem limite'), 'CWE-770'), ('T13', T('worker as owner', 'worker como dono'), 'CWE-250')]
    f = Fig('l04-cwe-join', 720, 250, T(
        'Stage 5 names a weakness for each threat with a CWE id, so findings from different sources '
        'join. T01, the forged webhook, is CWE-345. T07, other patients’ PDFs, is CWE-639. T10, '
        'uploads with no limit, is CWE-770. T13, the worker as owner, is CWE-250. A scanner’s '
        'finding or a pentest report naming the same CWE lands on the same threat.',
        'O estágio 5 nomeia uma fraqueza para cada ameaça com um id CWE, para achados de fontes '
        'diferentes se juntarem. A T01, o webhook forjado, é CWE-345. A T07, PDFs de outros '
        'pacientes, é CWE-639. A T10, uploads sem limite, é CWE-770. A T13, o worker como dono, é '
        'CWE-250. Um achado de scanner ou um relatório de pentest que nomeie o mesmo CWE cai na '
        'mesma ameaça.'))
    for i, (tid, name, cwe) in enumerate(rows):
        y = 20 + i * 50
        f.rect(20, y, 260, 38, stroke='--paper-dim', fill='--panel', width=1.2)
        f.text(32, y + 19, tid, size=10.5, mono=True, weight='600', anchor='start')
        f.text(76, y + 19, name, size=10, anchor='start')
        f.rect(330, y, 120, 38, stroke='--phosphor', fill='--panel', width=1.4)
        f.text(390, y + 19, cwe, size=10.5, mono=True, weight='600')
        f.line(280, y + 19, 330, y + 19)
    for i, src in enumerate([T('a scanner’s finding', 'um achado de scanner'), T('a pentest report', 'um relatório de pentest')]):
        y = 60 + i * 80
        f.rect(530, y, 170, 40, stroke='--paper-dim', fill='--panel', width=1.2)
        f.text(615, y + 20, src, size=10)
        f.line(530, y + 20, 450, 39 + i * 100, arrow=True)
    f.text(360, 232, T('the CWE id is the join, as an opaque id is everywhere else', 'o id CWE é a junção, como um id opaco é em todo o resto'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('Three sources of findings, one vocabulary. Without the id, the same weakness found three ways is three tickets.',
                'Três fontes de achados, um vocabulário. Sem o id, a mesma fraqueza achada de três jeitos são três chamados.')


@figure('l04-kept', 4)
def kept():
    f = Fig('l04-kept', 720, 200, T(
        'The part of PASTA Vereda kept. Stage 1, the business objectives, revised once a year with '
        'daniel. STRIDE does the work of stages 3 to 5 on each change. Stage 7, the ranking by '
        'business impact, is applied to anything new on the list.',
        'A parte do PASTA que a Vereda manteve. O estágio 1, os objetivos de negócio, revisto uma vez '
        'por ano com o daniel. O STRIDE faz o trabalho dos estágios 3 a 5 a cada mudança. O estágio '
        '7, a ordenação por impacto no negócio, é aplicado a tudo o que for novo na lista.'))
    boxes = [(T('stage 1', 'estágio 1'), T('once a year, with daniel', 'uma vez por ano, com o daniel'), '--amber'),
             (T('stages 3 to 5', 'estágios 3 a 5'), T('STRIDE, on each change', 'STRIDE, a cada mudança'), '--phosphor'),
             (T('stage 7', 'estágio 7'), T('for anything new on the list', 'para o que for novo na lista'), '--amber')]
    for i, (head, sub, c) in enumerate(boxes):
        x = 20 + i * 235
        f.rect(x, 40, 210, 80, stroke=c, fill='--panel', width=1.5)
        f.text(x + 105, 66, head, size=11, weight='600')
        f.text(x + 105, 94, sub, size=10)
        if i < 2:
            f.line(x + 210, 80, x + 235, 80, arrow=True)
    f.text(360, 160, T('STRIDE inside a PASTA frame', 'STRIDE dentro de uma moldura PASTA'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('The business stages are the cheap ones to keep and the expensive ones to lose.',
                'Os estágios do negócio são os baratos de manter e os caros de perder.')
