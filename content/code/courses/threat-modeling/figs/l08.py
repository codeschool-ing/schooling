"""Lesson 8: from identified risk to security requirement."""
import csv
import os
from figures import Fig, T, figure, HERE


@figure('l08-chain', 8)
def chain():
    f = Fig('l08-chain', 720, 250, T(
        'The chain from a threat to evidence, using T07. The threat: a patient changes the exam '
        'number and downloads somebody else’s report. The decision: mitigate. The requirement, '
        'R10: the portal returns an exam only to the patient it belongs to, and answers any other '
        'request as if it did not exist. The verification: a test that asks for another '
        'patient’s exam and expects the same answer as for a missing one. Below the chain, the '
        'other three decisions: eliminate, transfer, accept, each of which ends somewhere else.',
        'A cadeia de uma ameaça até a evidência, usando a T07. A ameaça: um paciente muda o número '
        'do exame e baixa o laudo de outra pessoa. A decisão: mitigar. O requisito, R10: o portal '
        'devolve um exame só ao paciente a quem ele pertence, e responde a qualquer outro pedido '
        'como se o exame não existisse. A verificação: um teste que pede o exame de outro paciente '
        'e espera a mesma resposta de um exame inexistente. Embaixo da cadeia, as outras três '
        'decisões: eliminar, transferir, aceitar, cada uma terminando em outro lugar.'))
    steps = [
        (T('threat', 'ameaça'), 'T07', [T('a patient downloads', 'um paciente baixa'), T('another’s report', 'o laudo de outro')], '--amber'),
        (T('decision', 'decisão'), '', [T('mitigate', 'mitigar')], '--paper-dim'),
        (T('requirement', 'requisito'), 'R10', [T('exams only to', 'exame só para'), T('their owner', 'o dono')], '--phosphor'),
        (T('verification', 'verificação'), '', [T('a test asks for', 'um teste pede o'), T('another’s exam', 'exame de outro')], '--phosphor'),
    ]
    for i, (head, tid, rows, c) in enumerate(steps):
        x = 20 + i * 175
        f.text(x + 77, 24, head, size=10.5, weight='600', fill=c if c != '--paper-dim' else '--paper')
        f.rect(x, 38, 155, 70, stroke=c, fill='--panel', width=1.5)
        if tid:
            f.text(x + 10, 52, tid, size=9, anchor='start', weight='600', fill=c, mono=True)
        f.lines(x + 77, 78, rows, size=10)
        if i < 3:
            f.line(x + 155, 73, x + 175, 73, stroke='--paper-dim', width=1.2, arrow=True)
    others = [(T('eliminate', 'eliminar'), T('remove the feature or the data', 'remover a funcionalidade ou o dado')),
              (T('transfer', 'transferir'), T('a contract or insurance carries it', 'um contrato ou seguro carrega')),
              (T('accept', 'aceitar'), T('a signed decision, with a date', 'uma decisão assinada, com data'))]
    f.text(20, 145, T('the other decisions end elsewhere:', 'as outras decisões terminam em outro lugar:'), size=10, anchor='start', fill='--paper-dim', italic=True)
    for i, (d, what) in enumerate(others):
        x = 20 + i * 232
        f.rect(x, 160, 220, 56, stroke='--wire', fill='--panel', width=1.2)
        f.text(x + 110, 178, d, size=10.5, weight='600')
        f.text(x + 110, 198, what, size=9.5, fill='--paper-dim')
    f.text(362, 236, T('lesson 12', 'aula 12'), size=9, fill='--paper-dim')
    f.text(594, 236, T('lesson 12', 'aula 12'), size=9, fill='--paper-dim')
    return f, T('A threat is dealt with when the chain reaches evidence. A requirement nobody verifies is a wish written in the imperative.',
                'Uma ameaça está tratada quando a cadeia chega a uma evidência. Um requisito que ninguém verifica é um desejo escrito no imperativo.')


def rows(name):
    return list(csv.DictReader(open(os.path.join(HERE, 'lab', name))))


@figure('l08-trace', 8)
def trace():
    threats = rows('threats.csv') + [dict(zip(('id', 'element', 'stride', 'threat'), r)) for r in
                                     csv.reader(open(os.path.join(HERE, 'lab', 'threats-from-abuse-cases.csv')))]
    reqs = rows('requirements.csv')
    f = Fig('l08-trace', 720, 400, T(
        'Every threat on the left joined to the requirements on the right that cover it. Seventeen '
        'threats, nineteen requirements. T14 has no line: no requirement covers it. R14 and R17 '
        'are drawn dashed: they exist and nothing verifies them. T01, T02, T16 and T17 have two '
        'requirements each; R18 covers two threats.',
        'Cada ameaça à esquerda ligada aos requisitos à direita que a cobrem. Dezessete ameaças, '
        'dezenove requisitos. A T14 não tem linha: nenhum requisito a cobre. R14 e R17 estão '
        'tracejados: existem e nada os verifica. T01, T02, T16 e T17 têm dois requisitos cada; o '
        'R18 cobre duas ameaças.'))
    ty = {t['id']: 20 + i * 22 for i, t in enumerate(threats)}
    ry = {r['id']: 15 + i * 20 for i, r in enumerate(reqs)}
    for r in reqs:
        for tid in r['threats'].split():
            dash = '4 3' if not r['verified by'] else None
            f.path(f'M262 {ty[tid]} C 360 {ty[tid]}, 380 {ry[r["id"]]}, 470 {ry[r["id"]]}',
                   stroke='--wire' if not dash else '--amber', width=1.2, dash=dash)
    for t in threats:
        y = ty[t['id']]
        bare = t['id'] == 'T14'
        f.rect(218, y - 8, 44, 16, stroke='--amber' if bare else '--paper-dim', fill='--ink', width=1.2, rx=3)
        f.text(240, y + 0.5, t['id'], size=9, weight='600', mono=True, fill='--amber' if bare else '--paper')
        f.text(208, y + 0.5, t['stride'], size=9, anchor='end', fill='--paper-dim', mono=True)
    for r in reqs:
        y = ry[r['id']]
        loose = not r['verified by']
        f.rect(470, y - 8, 44, 16, stroke='--amber' if loose else '--phosphor', fill='--ink', width=1.2, rx=3)
        f.text(492, y + 0.5, r['id'], size=9, weight='600', mono=True)
        f.text(522, y + 0.5, r['verified by'] or T('not verified', 'não verificado'), size=9, anchor='start',
               fill='--amber' if loose else '--paper-dim', mono=not loose)
    f.text(80, 140, T('T14: no requirement', 'T14: sem requisito'), size=10, fill='--amber', weight='600')
    f.text(80, 158, T('decided in lesson 12', 'decidida na aula 12'), size=9.5, fill='--paper-dim', italic=True)
    return f, T('The picture is trace.py’s output drawn. The two things it exists to show are a threat with no line and a line that ends in nothing.',
                'A figura é a saída do trace.py desenhada. As duas coisas que ela existe para mostrar são uma ameaça sem linha e uma linha que termina em nada.')


@figure('l08-verified-by', 8)
def verified_by():
    import csv
    import os
    from figures import HERE
    with open(os.path.join(HERE, 'lab', 'requirements.csv')) as fh:
        rows = list(csv.DictReader(fh))
    groups = [('test', T('a test', 'um teste'), '--phosphor'), ('review', T('a review', 'uma revisão'), '--phosphor-dim'), ('', T('not yet', 'ainda não'), '--amber')]
    n = {k: [r['id'] for r in rows if r['verified by'] == k] for k, _, _ in groups}
    f = Fig('l08-verified-by', 720, 210, T(
        f'How the {len(rows)} requirements are verified. By a test: {len(n["test"])}. By a review: '
        f'{len(n["review"])}, {", ".join(n["review"])}. Not yet: {len(n[""])}, {" and ".join(n[""])}.',
        f'Como os {len(rows)} requisitos são verificados. Por teste: {len(n["test"])}. Por revisão: '
        f'{len(n["review"])}, {", ".join(n["review"])}. Ainda não: {len(n[""])}, {" e ".join(n[""])}.'))
    x = 40
    for k, name, c in groups:
        w = len(n[k]) * 34
        f.rect(x, 50, w, 50, stroke=None, fill=c, rx=2)
        f.text(x + w / 2, 36, f'{name}: {len(n[k])}', size=10.5, weight='600')
        f.text(x + w / 2, 122, ' '.join(n[k]) if k != 'test' else T('R01, R10, R13 …', 'R01, R10, R13 …'), size=9.5, mono=True, fill='--paper-dim')
        x += w + 8
    f.text(360, 170, T('“not yet” written down is the honest state; a blank would be read as done', '“ainda não” escrito é o estado honesto; um branco seria lido como feito'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('Most requirements can be tested on every change. The ones about networks and cloud permissions need a person, and two need nobody yet.',
                'A maioria dos requisitos pode ser testada a cada mudança. Os de redes e permissões de nuvem precisam de uma pessoa, e dois ainda não precisam de ninguém.')


@figure('l08-hope', 8)
def hope():
    pairs = [(T('“attackers must not be able to read exams”', '“atacantes não podem conseguir ler exames”'), T('the portal returns an exam only to its patient', 'o portal devolve um exame só ao paciente dele'), T('a hope', 'uma esperança')),
             (T('“uploads must be limited in size”', '“uploads precisam ter tamanho limitado”'), T('an upload over 20 MB or not a PDF is refused', 'upload acima de 20 MB ou não PDF é recusado'), T('no number', 'sem número')),
             (T('“passwords must be strong”', '“senhas precisam ser fortes”'), T('sign-up refuses passwords in breach lists', 'o cadastro recusa senhas de listas vazadas'), T('not testable', 'não testável'))]
    f = Fig('l08-hope', 720, 230, T(
        'Three requirements as first written and as rewritten. Attackers must not be able to read '
        'exams, a hope, becomes: the portal returns an exam only to its patient. Uploads must be '
        'limited in size, with no number, becomes: an upload over 20 MB or not a PDF is refused. '
        'Passwords must be strong, not testable, becomes: sign-up refuses passwords found in breach '
        'lists.',
        'Três requisitos como foram escritos e como foram reescritos. Atacantes não podem conseguir '
        'ler exames, uma esperança, vira: o portal devolve um exame só ao paciente dele. Uploads '
        'precisam ter tamanho limitado, sem número, vira: upload acima de 20 MB ou que não seja PDF '
        'é recusado. Senhas precisam ser fortes, não testável, vira: o cadastro recusa senhas '
        'achadas em listas vazadas.'))
    for i, (bad, good, why) in enumerate(pairs):
        y = 20 + i * 65
        f.rect(20, y, 300, 48, stroke='--amber', fill='--panel', width=1.2, dash='4 3')
        f.text(170, y + 17, bad, size=9.5)
        f.text(170, y + 35, why, size=9.5, italic=True, fill='--amber')
        f.line(320, y + 24, 370, y + 24, arrow=True)
        f.rect(370, y, 330, 48, stroke='--phosphor', fill='--panel', width=1.4)
        f.text(535, y + 24, good, size=10)
    return f, T('The rewrite names a part, a behaviour and, where there is one, a number. A person who was not in the room can then check it.',
                'A reescrita nomeia uma parte, um comportamento e, quando há, um número. Alguém que não estava na sala consegue conferir.')


@figure('l08-backlog-shapes', 8)
def backlog_shapes():
    f = Fig('l08-backlog-shapes', 720, 240, T(
        'Three shapes a requirement takes in the backlog. A story of its own, for a feature somebody '
        'uses: R17, patients see and end their open sessions. Acceptance criteria on a story being '
        'built anyway: R13 on the story that redesigns the upload page. A rule in the definition of '
        'done, applied to every story of a kind: R10’s ownership check on every story that returns '
        'a patient’s data.',
        'Três formas que um requisito toma no backlog. Uma história própria, para uma funcionalidade '
        'que alguém usa: o R17, pacientes veem e encerram as sessões abertas. Critérios de aceite '
        'numa história que vai ser construída de qualquer jeito: o R13 na história que refaz a '
        'página de upload. Uma regra na definição de pronto, aplicada a toda história de um tipo: a '
        'verificação de dono do R10 em toda história que devolve dado de paciente.'))
    f.rect(20, 30, 200, 150, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(120, 52, T('a story of its own', 'uma história própria'), size=10.5, weight='600')
    f.lines(120, 110, [T('R17: see and end', 'R17: ver e encerrar'), T('open sessions', 'sessões abertas')], size=10)
    f.rect(260, 30, 200, 150, stroke='--paper-dim', fill='--panel', width=1.2)
    f.text(360, 52, T('the upload page story', 'a história da página'), size=10, weight='600')
    f.rect(275, 110, 170, 50, stroke='--phosphor', fill='--panel', width=1.4)
    f.lines(360, 135, [T('criteria: R13,', 'critérios: R13,'), T('20 MB, PDF only', '20 MB, só PDF')], size=9.5)
    f.text(360, 90, T('acceptance criteria', 'critérios de aceite'), size=9.5, italic=True, fill='--paper-dim')
    for k in range(3):
        f.rect(510 + k * 64, 60, 56, 70, stroke='--paper-dim', fill='--panel', width=1)
    f.rect(500, 140, 200, 40, stroke='--amber', fill='--panel', width=1.4)
    f.text(600, 160, T('done: R10 on each', 'pronto: R10 em cada'), size=10)
    f.text(600, 46, T('definition of done', 'definição de pronto'), size=10.5, weight='600')
    f.text(360, 222, T('the third shape is checked on every story, without anybody remembering the threat', 'a terceira forma é conferida em toda história, sem ninguém lembrar a ameaça'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('One requirement becomes work; one rides on work already planned; one becomes a habit of the team.',
                'Um requisito vira trabalho; um vai junto de um trabalho já planejado; um vira hábito da equipe.')
