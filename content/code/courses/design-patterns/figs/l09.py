"""Lesson 9: event sourcing."""
from figures import Fig, T, figure


@figure('l09-fold', 9)
def fold():
    f = Fig('l09-fold', 720, 280, T(
        'Bia\'s stream as a timeline of five events, left to right: MemberJoined, CopyLent C3, '
        'CopyLent C1, CopyReturned C3 with a fine of 150, and FinePaid 150. Below the line, the '
        'state after each event, each one computed from the state before it and the event above it '
        'by evolve: no loans and nothing owed; C3; C3 and C1; C1 and 150 owed; C1 and nothing owed. '
        'Only the events are stored; the states are worked out, and stopping after the second event '
        'gives the state at version 2.',
        'O stream da Bia como uma linha do tempo de cinco eventos, da esquerda para a direita: '
        'MemberJoined, CopyLent C3, CopyLent C1, CopyReturned C3 com multa de 150, e FinePaid 150. '
        'Abaixo da linha, o estado depois de cada evento, cada um calculado a partir do estado '
        'anterior e do evento acima dele por evolve: nenhum empréstimo e nada devido; C3; C3 e C1; '
        'C1 e 150 devidos; C1 e nada devido. Só os eventos são guardados; os estados são calculados, '
        'e parar depois do segundo evento dá o estado na versão 2.'))
    f.text(20, 24, T('stored: the events', 'guardado: os eventos'), size=11, weight='600', anchor='start')
    f.text(20, 158, T('worked out: the state', 'calculado: o estado'), size=11, weight='600', anchor='start')
    f.arrow([(30, 82), (705, 82)], stroke='--paper-dim', width=1.2)
    events = [('MemberJoined', ''), ('CopyLent', 'C3'), ('CopyLent', 'C1'),
              ('CopyReturned', 'C3, fine 150'), ('FinePaid', '150')]
    states = [('()', '0'), ("('C3',)", '0'), ("('C3', 'C1')", '0'), ("('C1',)", '150'), ("('C1',)", '0')]
    xs = [95, 225, 355, 485, 615]
    for i, (x, (name, arg), (loans, owed)) in enumerate(zip(xs, events, states)):
        f.box(x, 50, 118, 38, [name, arg] if arg else [name], mono=True, stroke='--phosphor', size=9.5)
        f.text(x, 96, f'v{i + 1}', size=9.5, fill='--paper-dim', mono=True)
        f.line(x, 69, x, 82, stroke='--phosphor', width=1.2)
        f.box(x, 200, 118, 44, [f'loans {loans}', f'owed {owed}'], mono=True, stroke='--wire', size=9.5)
        f.arrow([(x, 104), (x, 176)], stroke='--amber', width=1.2, dash='4 3')
        if i:
            f.arrow([(xs[i - 1] + 59, 200), (x - 61, 200)], stroke='--paper-dim', width=1.2)
    f.text(160, 128, 'evolve', size=9.5, mono=True, fill='--amber')
    f.rect(30, 172, 260, 56, stroke='--amber', fill='--ink', rx=3, dash='5 4')
    f.text(160, 246, T('stop here: the state at version 2', 'pare aqui: o estado na versão 2'),
           size=10, fill='--amber', italic=True)
    return f, T('Each state is the one before it with one event applied. Nothing below the line is stored, so any of it can be worked out again, up to any version.',
                'Cada estado é o anterior com um evento aplicado. Nada abaixo da linha é guardado, então qualquer parte pode ser calculada de novo, até qualquer versão.')
