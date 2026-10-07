"""Lesson 12: recording decisions and formal risk acceptance."""
from figures import Fig, T, figure


@figure('l12-lifecycle', 12)
def lifecycle():
    f = Fig('l12-lifecycle', 720, 260, T(
        'The life of a risk in the register. Identified, then estimated, then decided: mitigate, '
        'eliminate, transfer or accept. A mitigation is built and verified; a transfer is signed '
        'with a contract; an acceptance is signed by its owner with a review date. All of them '
        'arrive at review, and a review sends the risk back to be estimated again or closes it.',
        'A vida de um risco no registro. Identificado, depois estimado, depois decidido: mitigar, '
        'eliminar, transferir ou aceitar. Uma mitigação é construída e verificada; uma '
        'transferência é assinada num contrato; um aceite é assinado pelo dono com data de revisão. '
        'Todos chegam à revisão, e uma revisão manda o risco de volta para ser estimado de novo ou '
        'o fecha.'))
    def box(x, y, w, rows, c='--paper-dim'):
        f.rect(x, y, w, 40, stroke=c, fill='--panel', width=1.5)
        f.lines(x + w / 2, y + 20, rows, size=10)
    box(20, 30, 110, [T('identified', 'identificado')])
    box(160, 30, 110, [T('estimated', 'estimado')])
    box(300, 30, 110, [T('decided', 'decidido')], '--amber')
    box(450, 0 + 10, 250, [T('mitigate or eliminate: built, verified', 'mitigar ou eliminar: construído, verificado')], '--phosphor')
    box(450, 60, 250, [T('transfer: a contract signed', 'transferir: um contrato assinado')], '--phosphor')
    box(450, 110, 250, [T('accept: signed, with a review date', 'aceitar: assinado, com data de revisão')], '--amber')
    box(300, 190, 110, [T('reviewed', 'revisado')])
    box(160, 190, 110, [T('closed', 'fechado')])
    P = dict(stroke='--paper-dim', width=1.2)
    f.line(130, 50, 160, 50, arrow=True, **P)
    f.line(270, 50, 300, 50, arrow=True, **P)
    f.arrow([(410, 45), (430, 45), (430, 30), (450, 30)], **P)
    f.arrow([(410, 50), (450, 80)], **P)
    f.arrow([(410, 58), (430, 58), (430, 130), (450, 130)], **P)
    f.arrow([(575, 150), (575, 210), (410, 210)], **P)
    f.line(300, 210, 270, 210, arrow=True, **P)
    f.arrow([(355, 190), (355, 160), (215, 160), (215, 70)], stroke='--amber', width=1.2, dash='5 4')
    f.text(285, 152, T('estimate again', 'estimar de novo'), size=9.5, fill='--amber', italic=True)
    return f, T('Every path through the register ends at a review. A risk that reached "decided" and stopped there is a risk nobody is watching.',
                'Todo caminho pelo registro termina numa revisão. Um risco que chegou a "decidido" e parou ali é um risco que ninguém está olhando.')


@figure('l12-authority', 12)
def authority():
    f = Fig('l12-authority', 720, 250, T(
        'Who may accept a risk at Vereda, by its expected loss per year. Up to 10,000 reais: the '
        'team lead, ana. From 10,000 to 50,000: the operations director, daniel. Above 50,000, or '
        'any risk to patients’ health data that the LGPD calls high: the owners, together. T14, at '
        '9,000, sits in the first band, and daniel signed it anyway because its bad year is large.',
        'Quem pode aceitar um risco na Vereda, pela perda esperada por ano. Até 10.000 reais: a '
        'líder da equipe, ana. De 10.000 a 50.000: o diretor de operações, daniel. Acima de 50.000, '
        'ou qualquer risco a dado de saúde de pacientes que a LGPD chama de alto: os donos, juntos. '
        'A T14, com 9.000, fica na primeira faixa, e o daniel a assinou mesmo assim porque o ano '
        'ruim dela é grande.'))
    bands = [(T('up to R$ 10,000 a year', 'até R$ 10.000 por ano'), T('team lead (ana)', 'líder da equipe (ana)'), 140, '--phosphor-dim'),
             (T('R$ 10,000 to 50,000', 'R$ 10.000 a 50.000'), T('operations director (daniel)', 'diretor de operações (daniel)'), 240, '--phosphor'),
             (T('above R$ 50,000, or high LGPD risk', 'acima de R$ 50.000, ou risco alto na LGPD'), T('the owners, together', 'os donos, juntos'), 340, '--amber')]
    for i, (when, who, w, c) in enumerate(bands):
        y = 30 + i * 60
        f.rect(250, y, w, 44, stroke=None, fill=c, rx=3)
        f.text(240, y + 22, when, size=10, anchor='end', weight='600')
        f.text(250 + w + 10, y + 22, who, size=10, anchor='start', fill='--paper')
    f.circle(300, 52, 6, fill='--amber', stroke='--ink', width=1.5)
    f.text(250, 222, T('the dot: T14, R$ 9,000 a year, signed by daniel because of its bad year', 'o ponto: T14, R$ 9.000 por ano, assinada pelo daniel por causa do ano ruim'),
           size=9.5, anchor='start', fill='--paper-dim', italic=True)
    return f, T('The bigger the risk, the more senior the signature. A rule like this is what stops a developer from accepting, alone, a risk the business would never have agreed to.',
                'Quanto maior o risco, mais alta a assinatura. Uma regra assim é o que impede alguém do desenvolvimento de aceitar, sozinho, um risco com que o negócio nunca teria concordado.')


@figure('l12-timeline', 12)
def timeline():
    f = Fig('l12-timeline', 720, 210, T(
        'A timeline from April 2026 to October 2027. RA-002, accepting T06, decided on 2 April 2026, '
        'review due 2 October 2026, overdue on 7 October. RA-001, accepting T14, decided 1 October '
        '2026, review due 1 April 2027. DR-001, the second factor, decided 30 September 2026, review '
        'due 30 September 2027.',
        'Uma linha do tempo de abril de 2026 a outubro de 2027. RA-002, aceitando a T06, decidido em '
        '2 de abril de 2026, revisão para 2 de outubro de 2026, atrasada em 7 de outubro. RA-001, '
        'aceitando a T14, decidido em 1º de outubro de 2026, revisão para 1º de abril de 2027. '
        'DR-001, o segundo fator, decidido em 30 de setembro de 2026, revisão para 30 de setembro de '
        '2027.'))
    x0, x1 = 60, 690
    m = lambda y, mo, d=1: x0 + ((y - 2026) * 12 + (mo - 4) + (d - 1) / 30) / 18 * (x1 - x0)
    f.line(x0, 170, x1, 170, stroke='--paper-dim')
    for (y, mo) in ((2026, 4), (2026, 7), (2026, 10), (2027, 1), (2027, 4), (2027, 7), (2027, 10)):
        f.line(m(y, mo), 170, m(y, mo), 175, stroke='--paper-dim')
        names = {1: T('Jan', 'jan'), 4: T('Apr', 'abr'), 7: T('Jul', 'jul'), 10: T('Oct', 'out')}
        f.text(m(y, mo), 188, f'{names[mo]} {y}', size=9, fill='--paper-dim')
    rows = [('RA-002', (2026, 4, 2), (2026, 10, 2), '--amber', 40), ('DR-001', (2026, 9, 30), (2027, 9, 30), '--phosphor', 80),
            ('RA-001', (2026, 10, 1), (2027, 4, 1), '--phosphor', 120)]
    for rid, a, b, c, y in rows:
        f.rect(m(*a), y - 8, m(*b) - m(*a), 16, stroke=None, fill=c if c == '--amber' else '--phosphor-dim', rx=3)
        f.text(m(*a) - 8, y, rid, size=9.5, anchor='end', weight='600', mono=True)
        f.circle(m(*b), y, 5, fill=c)
    today = m(2026, 10, 7)
    for ya, yb in ((24, 70), (90, 110), (130, 170)):
        f.line(today, ya, today, yb, stroke='--amber', width=1.5, dash='4 3')
    f.text(today + 6, 18, T('7 Oct 2026: RA-002 overdue', '7 out 2026: RA-002 atrasado'), size=9.5, anchor='start', fill='--amber', weight='600')
    return f, T('Each bar is a decision from the day it was made to the day it must be looked at again. The dashed line is the day acceptances.py was run.',
                'Cada barra é uma decisão do dia em que foi tomada ao dia em que precisa ser revista. A linha tracejada é o dia em que o acceptances.py rodou.')


@figure('l12-two-readers', 12)
def two_readers():
    f = Fig('l12-two-readers', 720, 260, T(
        'A decision record has two readers. Its front matter, the lines between the two --- '
        'markers with id, threat, decision, owner, decided and review by, is read by a program, '
        'acceptances.py, which lists what is due. Its prose, the risk, why it is accepted, what is '
        'in place instead and when it is looked at again, is read by a person a year later who was '
        'not in the room.',
        'Um registro de decisão tem dois leitores. O front matter, as linhas entre os dois '
        'marcadores --- com id, threat, decision, owner, decided e review by, é lido por um '
        'programa, o acceptances.py, que lista o que está vencendo. A prosa, o risco, por que é '
        'aceito, o que está no lugar e quando vai ser revisto, é lida por uma pessoa um ano depois '
        'que não estava na sala.'))
    f.rect(240, 20, 240, 220, stroke='--paper-dim', fill='--panel', width=1.4)
    f.text(252, 36, 'RA-001-crafted-pdf.md', size=9.5, mono=True, anchor='start', fill='--paper-dim')
    fm = ['---', 'id: RA-001', 'threat: T14', 'decision: accept', 'owner: daniel', 'review by: 2027-04-01', '---']
    for i, line in enumerate(fm):
        f.text(256, 56 + i * 14, line, size=9.5, mono=True, anchor='start', fill='--phosphor')
    prose = [T('## The risk', '## O risco'), T('## Why it is accepted', '## Por que é aceito'), T('## What is in place instead', '## O que está no lugar'), T('## When this is looked at again', '## Quando é revisto')]
    for i, line in enumerate(prose):
        f.text(256, 168 + i * 16, line, size=9.5, anchor='start')
    f.rect(20, 60, 170, 50, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(105, 78, 'acceptances.py', size=10, mono=True, weight='600')
    f.text(105, 96, T('what is due, and when', 'o que vence, e quando'), size=9.5, fill='--paper-dim')
    f.line(240, 85, 190, 85, arrow=True, stroke='--phosphor')
    f.rect(530, 160, 170, 50, stroke='--paper-dim', fill='--panel', width=1.2)
    f.text(615, 178, T('a person, a year later', 'uma pessoa, um ano depois'), size=10, weight='600')
    f.text(615, 196, T('who was not in the room', 'que não estava na sala'), size=9.5, fill='--paper-dim')
    f.line(480, 185, 530, 185, arrow=True)
    return f, T('The machine reads the dates so nobody has to remember them; the person reads the reasons so nobody has to reconstruct them.',
                'A máquina lê as datas para ninguém precisar lembrá-las; a pessoa lê os motivos para ninguém precisar reconstruí-los.')


@figure('l12-supersede', 12)
def supersede():
    f = Fig('l12-supersede', 720, 200, T(
        'A changed decision is a new record. The old record, say RA-001 as daniel signed it, stays '
        'exactly as it was. The new record says, in its front matter, that it supersedes RA-001, '
        'and carries the new decision, owner and review date. The only field a team may change in '
        'place is a status, because it describes the present.',
        'Uma decisão que muda é um registro novo. O registro antigo, digamos o RA-001 como o daniel '
        'assinou, fica exatamente como era. O registro novo diz, no front matter, que substitui o '
        'RA-001, e traz a decisão, o dono e a data de revisão novos. O único campo que uma equipe '
        'pode mudar no lugar é uma situação, porque ela descreve o presente.'))
    f.rect(40, 50, 240, 90, stroke='--paper-dim', fill='--panel', width=1.2)
    f.text(160, 72, 'RA-001', size=11, mono=True, weight='600')
    f.text(160, 96, T('as signed, never edited', 'como assinado, nunca editado'), size=10)
    f.text(160, 118, T('status: superseded', 'situação: substituído'), size=9.5, mono=True, fill='--paper-dim')
    f.rect(440, 50, 240, 90, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(560, 72, T('the new record', 'o registro novo'), size=11, weight='600')
    f.text(560, 96, 'supersedes: RA-001', size=10, mono=True, fill='--phosphor')
    f.text(560, 118, T('new decision, owner, date', 'decisão, dono, data novos'), size=9.5, fill='--paper-dim')
    f.line(440, 95, 280, 95, arrow=True, stroke='--phosphor')
    f.text(360, 172, T('git log shows that the old file was never touched after its commit', 'o git log mostra que o arquivo antigo nunca foi tocado depois do commit'), size=9.5, italic=True, fill='--paper-dim')
    return f, T('The history stays true: anybody can still read what was decided in October, and with what was known then.',
                'A história continua verdadeira: qualquer um ainda lê o que foi decidido em outubro, e com o que se sabia então.')
