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
