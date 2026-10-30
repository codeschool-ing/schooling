"""Lesson 10: Privileged Identity Management and just-in-time elevation."""
from figures import Fig, T, figure


@figure('l10-activation', 10)
def activation():
    f = Fig('l10-activation', 720, 300, T(
        'One activation of an eligible role, as a timeline. ana is eligible for Owner on shop-prod. At '
        'the first step ana asks for four hours, with a second factor, a justification and a ticket '
        'number. At the second step another engineer approves. From then the role is active, for the '
        'four hours asked. At the end it switches itself off and ana is eligible again. Below the line, '
        'every step is written to the audit history.',
        'Uma ativação de um papel elegível, como linha do tempo. ana é elegível a Owner na shop-prod. No '
        'primeiro passo ana pede quatro horas, com segundo fator, justificativa e número de chamado. No '
        'segundo passo outro engenheiro aprova. Daí em diante o papel está ativo, pelas quatro horas '
        'pedidas. No fim ele se desliga sozinho e ana volta a ser elegível. Abaixo da linha, cada passo '
        'é gravado no histórico de auditoria.'))
    y = 120
    f.line(171, y, 449, y, stroke='--paper-dim')
    f.line(621, y, 690, y, stroke='--paper-dim')
    f.rect(40, y - 24, 130, 48, stroke='--wire', fill='--panel')
    f.text(105, y - 8, T('eligible', 'elegível'), size=10.5, weight='600')
    f.text(105, y + 10, T('no power yet', 'nenhum poder ainda'), size=9.5, fill='--paper-dim')
    steps = [(250, T('request', 'pedido'), [T('second factor', 'segundo fator'), T('justification, ticket', 'justificativa, chamado')]),
             (400, T('approval', 'aprovação'), [T('another engineer', 'outro engenheiro')])]
    for x, title, notes in steps:
        f.circle(x, y, 7, fill='--amber')
        f.text(x, y - 26, title, size=10.5, weight='600')
        f.lines(x, y + 34, notes, size=9.5, fill='--paper-dim')
    f.rect(450, y - 24, 170, 48, stroke='--amber', fill='--panel', width=2)
    f.text(535, y - 8, T('active', 'ativo'), size=10.5, weight='600', fill='--amber')
    f.text(535, y + 10, T('4 hours at most', 'no máximo 4 horas'), size=9.5)
    f.circle(650, y, 7, fill='--paper-dim')
    f.text(650, y - 26, T('expires', 'expira'), size=10.5, weight='600')
    f.text(650, y + 34, T('eligible again', 'elegível de novo'), size=9.5, fill='--paper-dim')
    f.rect(40, 210, 650, 56, stroke='--wire', fill='--ink', dash='4 3')
    f.text(56, 228, T('audit history', 'histórico de auditoria'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(365, 248, T('who · which role · where · how long · why', 'quem · qual papel · onde · por quanto tempo · por quê'),
           size=10.5)
    return f, T('The role is held for the hours asked, and every step leaves a line behind.',
                'O papel fica ativo pelas horas pedidas, e cada passo deixa uma linha para trás.')
