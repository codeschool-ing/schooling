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
    f.text(20, 14, T('stored: the events', 'guardado: os eventos'), size=11, weight='600', anchor='start')
    f.lines(14, 140, [T('worked out:', 'calculado:'), T('the state', 'o estado')], size=11, weight='600', anchor='start')
    f.arrow([(70, 82), (710, 82)], stroke='--paper-dim', width=1.2)
    events = [('MemberJoined', ''), ('CopyLent', 'C3'), ('CopyLent', 'C1'),
              ('CopyReturned', 'C3, fine 150'), ('FinePaid', '150')]
    states = [('()', '0'), ("('C3',)", '0'), ("('C3', 'C1')", '0'), ("('C1',)", '150'), ("('C1',)", '0')]
    xs = [137, 263, 389, 515, 641]
    for i, (x, (name, arg), (loans, owed)) in enumerate(zip(xs, events, states)):
        f.box(x, 54, 116, 36, [name, arg] if arg else [name], mono=True, stroke='--phosphor', size=9.5)
        f.text(x, 96, f'v{i + 1}', size=9.5, fill='--paper-dim', mono=True)
        f.line(x, 72, x, 82, stroke='--phosphor', width=1.2)
        f.box(x, 200, 116, 44, [f'loans {loans}', f'owed {owed}'], mono=True, stroke='--wire', size=9.5)
        f.arrow([(x, 104), (x, 176)], stroke='--amber', width=1.2, dash='4 3')
        if i:
            f.arrow([(xs[i - 1] + 58, 200), (x - 60, 200)], stroke='--paper-dim', width=1.2)
    f.text(200, 128, 'evolve', size=9.5, mono=True, fill='--amber')
    f.path('M78 228 L78 234 L322 234 L322 228', stroke='--amber', width=1.3)
    f.text(200, 250, T('stop here: the state at version 2', 'pare aqui: o estado na versão 2'),
           size=10, fill='--amber', italic=True)
    return f, T('Each state is the one before it with one event applied. Nothing below the line is stored, so any of it can be worked out again, up to any version.',
                'Cada estado é o anterior com um evento aplicado. Nada abaixo da linha é guardado, então qualquer parte pode ser calculada de novo, até qualquer versão.')


@figure('l09-snapshot', 9)
def snapshot():
    f = Fig('l09-snapshot', 720, 250, T(
        'Bia\'s stream drawn as a long bar of 10,003 events, from version 1 on the left to version '
        '10,003 on the right. Above it, the rebuild without a snapshot: an arrow along the whole bar, '
        'applying 10,002 events. A snapshot marks the state saved at version 10,002, near the right '
        'end. Below the bar, the rebuild with the snapshot: it loads the saved state and applies only '
        'the one event after it, FinePaid. The events are all still in the store either way.',
        'O stream da Bia desenhado como uma barra longa de 10.003 eventos, da versão 1 à esquerda à '
        'versão 10.003 à direita. Acima, a reconstrução sem snapshot: uma seta ao longo da barra '
        'inteira, aplicando 10.002 eventos. Um snapshot marca o estado salvo na versão 10.002, perto '
        'da ponta direita. Abaixo da barra, a reconstrução com o snapshot: ela carrega o estado salvo '
        'e aplica só o evento seguinte, FinePaid. Os eventos continuam todos no store de qualquer jeito.'))
    f.text(40, 30, T('without a snapshot: fold from version 1, 10,002 events',
                     'sem snapshot: dobrar desde a versão 1, 10.002 eventos'),
           size=10.5, anchor='start')
    f.arrow([(40, 48), (640, 48)], stroke='--paper-dim', width=1.4)
    f.rect(40, 100, 640, 34, stroke='--phosphor', fill='--panel', rx=2)
    for i in range(1, 40):
        x = 40 + i * 16
        if x < 640:
            f.line(x, 100, x, 134, stroke='--wire', width=0.8)
    f.text(40, 150, 'v1', size=9.5, mono=True, anchor='start', fill='--paper-dim')
    f.text(680, 150, 'v10003', size=9.5, mono=True, anchor='end', fill='--paper-dim')
    f.rect(642, 64, 30, 26, stroke='--amber', fill='--panel', rx=2)
    f.text(657, 77, 'S', size=10, mono=True, fill='--amber', weight='600')
    f.line(657, 90, 657, 100, stroke='--amber', width=1.3)
    f.text(630, 77, T('snapshot at v10002', 'snapshot na v10002'), size=10, fill='--amber', anchor='end')
    f.arrow([(657, 176), (676, 176)], stroke='--amber', width=1.4)
    f.text(640, 200, T('with the snapshot: load the state, fold 1 event', 'com o snapshot: carregar o estado, dobrar 1 evento'),
           size=10.5, anchor='end', fill='--amber')
    f.text(360, 232, T('the events are all still there; the snapshot is a cache of a fold',
                       'os eventos continuam todos lá; o snapshot é um cache de uma dobra'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('A snapshot saves the folded state at a version, so a rebuild starts there and applies only what came after.',
                'Um snapshot salva o estado dobrado numa versão, para a reconstrução começar dali e aplicar só o que veio depois.')
