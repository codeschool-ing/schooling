"""Lesson 3: STRIDE."""
from figures import Fig, T, figure
from figs.l02 import portal_dfd


@figure('l03-per-element', 3)
def per_element():
    f = Fig('l03-per-element', 720, 250, T(
        'STRIDE per element, as a grid. External entities: spoofing and repudiation. Processes: all '
        'six. Data stores: tampering, information disclosure and denial of service, plus '
        'repudiation when the store is a log. Data flows: tampering, information disclosure and '
        'denial of service.',
        'STRIDE por elemento, como uma grade. Entidades externas: falsificação e repúdio. '
        'Processos: as seis. Repositórios de dados: adulteração, divulgação de informação e negação '
        'de serviço, mais repúdio quando o repositório é um log. Fluxos de dados: adulteração, '
        'divulgação de informação e negação de serviço.'))
    letters = ['S', 'T', 'R', 'I', 'D', 'E']
    names = [T('spoofing', 'falsificação'), T('tampering', 'adulteração'), T('repudiation', 'repúdio'),
             T('disclosure', 'divulgação'), T('denial', 'negação'), T('elevation', 'elevação')]
    rows = [(T('external entity', 'entidade externa'), 'SR', ''),
            (T('process', 'processo'), 'STRIDE', ''),
            (T('data store', 'repositório de dados'), 'TID', 'R'),
            (T('data flow', 'fluxo de dados'), 'TID', '')]
    x0, cw, y0, rh = 230, 75, 70, 38
    for j, (l, n) in enumerate(zip(letters, names)):
        x = x0 + j * cw + cw / 2
        f.text(x, 30, l, size=14, weight='600', fill='--phosphor')
        f.text(x, 50, n, size=9, fill='--paper-dim')
    for i, (name, yes, maybe) in enumerate(rows):
        y = y0 + i * rh
        f.rect(20, y, x0 + 6 * cw - 20, rh - 4, stroke='--wire', fill='--panel', width=1, rx=2)
        f.text(36, y + rh / 2 - 2, name, size=10.5, anchor='start', weight='600')
        for j, l in enumerate(letters):
            x = x0 + j * cw + cw / 2
            if l in yes:
                f.circle(x, y + rh / 2 - 2, 8, fill='--phosphor')
            elif l in maybe:
                f.circle(x, y + rh / 2 - 2, 8, fill=None, stroke='--amber', width=1.6)
    f.circle(250, 236, 6, fill=None, stroke='--amber', width=1.6)
    f.text(262, 236, T('repudiation applies to a store that is a log: tampering with it erases the record',
                       'repúdio vale para um repositório que é log: adulterá-lo apaga o registro'),
           size=9.5, anchor='start', fill='--paper-dim')
    return f, T('A process is exposed to all six because it is where code runs. A flow cannot be spoofed by itself: its source can.',
                'Um processo está exposto às seis porque é onde o código roda. Um fluxo não se falsifica sozinho: a origem dele, sim.')


TAGS = [  # threat id, x, y: beside the element or flow it is filed against
    ('T01', 450, 140), ('T02', 205, 77), ('T03', 84, 410), ('T04', 520, 230), ('T05', 400, 340),
    ('T06', 240, 77), ('T07', 205, 143), ('T08', 545, 410), ('T09', 435, 340), ('T10', 240, 143),
    ('T11', 580, 410), ('T12', 270, 430), ('T13', 460, 440), ('T14', 300, 254),
]


@figure('l03-portal-stride', 3)
def portal_stride():
    f = Fig('l03-portal-stride', 720, 465, T(
        'The portal’s level 1 diagram with the fourteen threats of this lesson filed against what '
        'they threaten. T01 sits on the payment webhook. T02 and T06 sit on the sign-in flow, T07 '
        'and T10 on the flows between patient and portal. T03 is on the clinic staff. T04 is on '
        'the exam files. T05 and T09 are on the flow from the console to the records database. T08 '
        'and T11 are on the reminder sent to the SMS provider. T12 is on the staff console, T13 on '
        'the reminder worker, and T14 on the flow that opens an exam PDF in the console.',
        'O diagrama de nível 1 do portal com as catorze ameaças desta aula anexadas ao que '
        'ameaçam. T01 está no webhook de pagamento. T02 e T06 estão no fluxo de login, T07 e T10 '
        'nos fluxos entre paciente e portal. T03 está na equipe da clínica. T04 está nos arquivos '
        'de exames. T05 e T09 estão no fluxo do console para o banco de prontuários. T08 e T11 '
        'estão no lembrete mandado ao provedor de SMS. T12 está no console da equipe, T13 no worker '
        'de lembretes e T14 no fluxo que abre um PDF de exame no console.'))
    portal_dfd(f, numbers=False)
    for tid, x, y in TAGS:
        f.rect(x - 15, y - 8, 30, 16, stroke='--amber', fill='--ink', width=1.2, rx=3)
        f.text(x, y + 0.5, tid, size=9, weight='600', fill='--amber', mono=True)
    return f, T('Ten of the fourteen sit on a flow, and every one of those flows crosses a boundary.',
                'Dez das catorze estão num fluxo, e todos esses fluxos cruzam uma fronteira.')


@figure('l03-tool-and-hand', 3)
def tool_and_hand():
    f = Fig('l03-tool-and-hand', 720, 260, T(
        'Where the findings land, by kind of element. pytm’s 196 findings: 128 on the three '
        'processes, 60 on the twelve flows, 8 on the two data stores and none on the external '
        'entities. The 14 threats written by hand: 2 on processes, 10 on flows, 1 on a data store '
        'and 1 on an external entity.',
        'Onde os achados caem, por tipo de elemento. Os 196 achados do pytm: 128 nos três '
        'processos, 60 nos doze fluxos, 8 nos dois repositórios e nenhum nas entidades externas. As '
        '14 ameaças escritas à mão: 2 em processos, 10 em fluxos, 1 num repositório e 1 numa '
        'entidade externa.'))
    kinds = [T('processes', 'processos'), T('data flows', 'fluxos de dados'), T('data stores', 'repositórios'),
             T('external entities', 'entidades externas')]
    tool, hand = [128, 60, 8, 0], [2, 10, 1, 1]
    for col, (title, vals, total, fill) in enumerate((
            (T('pytm: 196 findings', 'pytm: 196 achados'), tool, 196, '--phosphor-dim'),
            (T('by hand: 14 threats', 'à mão: 14 ameaças'), hand, 14, '--amber'))):
        ox = 20 + col * 360
        f.text(ox + 170, 22, title, size=11, weight='600')
        for i, (k, v) in enumerate(zip(kinds, vals)):
            y = 48 + i * 48
            f.text(ox + 120, y + 14, k, size=10, anchor='end')
            w = 200 * v / total
            f.rect(ox + 130, y, 200, 28, stroke='--wire', fill='--panel', width=1, rx=2)
            if v:
                f.rect(ox + 130, y, w, 28, stroke=None, fill=fill, rx=2)
            pct = round(100 * v / total)
            f.text(ox + 136 + (w if w < 150 else 0), y + 14, f'{v}  ({pct}%)', size=9.5, anchor='start',
                   weight='600', fill='--paper')
    return f, T('Both lists are about the same drawing. The tool counts what each element could suffer; the people counted where trust changes.',
                'As duas listas são sobre o mesmo desenho. A ferramenta conta o que cada elemento poderia sofrer; as pessoas contaram onde a confiança muda.')


@figure('l03-threat-anatomy', 3)
def anatomy():
    f = Fig('l03-threat-anatomy', 720, 200, T(
        'A threat statement in four parts, using T07. Who: a signed-in patient. Does what: changes '
        'the exam number in the address. To what: another patient’s exam PDF. With what result: '
        'downloads it, which discloses health data. Under it, the STRIDE letter I and the element, '
        'flow 2.',
        'Uma ameaça escrita em quatro partes, usando a T07. Quem: um paciente logado. Faz o quê: '
        'muda o número do exame no endereço. Em quê: o PDF do exame de outro paciente. Com que '
        'resultado: baixa o arquivo, o que divulga dado de saúde. Embaixo, a letra I do STRIDE e o '
        'elemento, o fluxo 2.'))
    parts = [(T('who', 'quem'), [T('a signed-in', 'um paciente'), T('patient', 'logado')]),
             (T('does what', 'faz o quê'), [T('changes the exam', 'muda o número do'), T('number in the address', 'exame no endereço')]),
             (T('to what', 'em quê'), [T('another patient’s', 'o PDF do exame'), T('exam PDF', 'de outro paciente')]),
             (T('with what result', 'com que resultado'), [T('downloads it: health', 'baixa: dado de saúde'), T('data disclosed', 'divulgado')])]
    for i, (h, rows) in enumerate(parts):
        x = 20 + i * 172
        f.text(x + 80, 24, h, size=10, weight='600', fill='--phosphor')
        f.rect(x, 38, 160, 60, stroke='--phosphor', fill='--panel', width=1.4)
        f.lines(x + 80, 68, rows, size=10)
        if i < 3:
            f.line(x + 160, 68, x + 172, 68, stroke='--paper-dim', width=1.2, arrow=True)
    f.rect(20, 125, 160, 40, stroke='--amber', fill='--panel', width=1.4)
    f.text(100, 145, T('STRIDE: I', 'STRIDE: I'), size=10.5, weight='600', fill='--amber')
    f.rect(192, 125, 160, 40, stroke='--amber', fill='--panel', width=1.4)
    f.text(272, 145, T('element: flow 2', 'elemento: fluxo 2'), size=10.5, weight='600', fill='--amber')
    f.text(370, 145, T('filed as T07', 'registrada como T07'), size=10.5, anchor='start', fill='--paper-dim')
    f.text(360, 188, T('If one part is missing, nobody can tell whether the threat has been dealt with.',
                       'Se faltar uma parte, ninguém consegue dizer se a ameaça foi tratada.'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('A threat names somebody doing something to something, and what happens then. The letter and the element say where it lives.',
                'Uma ameaça nomeia alguém fazendo algo com alguma coisa, e o que acontece então. A letra e o elemento dizem onde ela mora.')
