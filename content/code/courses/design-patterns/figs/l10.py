"""Lesson 10: ACID and the CAP theorem."""
from figures import Fig, T, figure


@figure('l10-lost-update', 10)
def lost_update():
    f = Fig('l10-lost-update', 700, 330, T(
        'A timeline of the lost update in desks.py, read from top to bottom. Desk A on the left, '
        'the items row in the middle, desk B on the right. First desk A reads available 1. Then '
        'desk B reads available 1. Then desk A writes 0 and records a loan for Bia. Then desk B '
        'writes 0, computed from the 1 it read earlier, and records a loan for Caio. The row ends '
        'at available 0 with two loans for one copy, and no step raised an error.',
        'Uma linha do tempo da atualização perdida em desks.py, lida de cima para baixo. O balcão A '
        'à esquerda, a linha de items no meio, o balcão B à direita. Primeiro o balcão A lê '
        'available 1. Depois o balcão B lê available 1. Depois o balcão A grava 0 e registra um '
        'empréstimo para Bia. Depois o balcão B grava 0, calculado a partir do 1 que leu antes, e '
        'registra um empréstimo para Caio. A linha termina com available 0 e dois empréstimos para '
        'um exemplar, e nenhum passo levantou erro.'))
    xa, xd, xb = 130, 350, 570
    f.box(xa, 30, 150, 30, [T('desk A (Bia)', 'balcão A (Bia)')], stroke='--phosphor')
    f.box(xd, 30, 170, 30, [T('items row', 'linha de items')], stroke='--amber')
    f.box(xb, 30, 150, 30, [T('desk B (Caio)', 'balcão B (Caio)')], stroke='--phosphor')
    # lifelines, drawn in the gaps between the boxes that sit on them
    occupied = {xa: [(45, 45), (74, 96), (184, 206)], xb: [(45, 45), (129, 151), (239, 261)],
                xd: [(45, 45), (74, 96), (129, 151), (178, 212), (233, 267)]}
    for x, spans in occupied.items():
        spans = spans + [(290, 290)]
        for (_, end), (start, _) in zip(spans, spans[1:]):
            if start - end > 6:
                f.line(x, end + 2, x, start - 2, stroke='--wire', width=1, dash='3 4')
    f.arrow([(28, 66), (28, 290)], stroke='--paper-dim', width=1)
    f.text(28, 56, T('time', 'tempo'), size=10, fill='--paper-dim', anchor='middle')
    steps = [
        (85, 'read', 'a', 'available = 1', T('reads 1', 'lê 1')),
        (140, 'read', 'b', 'available = 1', T('reads 1', 'lê 1')),
        (195, 'write', 'a', 'available = 0', T('writes 1 - 1', 'grava 1 - 1')),
        (250, 'write', 'b', 'available = 0', T('writes 1 - 1', 'grava 1 - 1')),
    ]
    loans = 0
    for y, kind, who, val, label in steps:
        x = xa if who == 'a' else xb
        inner = x + 70 if who == 'a' else x - 70
        edge = xd - 72 if who == 'a' else xd + 72
        if kind == 'read':
            f.arrow([(edge, y), (inner, y)], stroke='--paper-dim', width=1.2)
        else:
            loans += 1
            f.arrow([(inner, y), (edge, y)], stroke='--phosphor', width=1.4)
        f.text((inner + edge) / 2, y - 9, label, size=9.5, fill='--paper')
        rows = [val] if kind == 'read' else [val, T(f'loans: {loans}', f'empréstimos: {loans}')]
        f.box(xd, y, 140, 34 if kind == 'write' else 22, rows, size=9, mono=True,
              stroke='--amber' if kind == 'write' else '--wire')
        f.box(x, y, 136, 22, [T('SELECT', 'SELECT') if kind == 'read' else T('UPDATE + INSERT', 'UPDATE + INSERT')],
              size=9, mono=True)
    f.text(xd, 310, T('one copy, two loans, no error', 'um exemplar, dois empréstimos, nenhum erro'),
           size=10.5, fill='--amber', italic=True)
    return f, T('The lost update. Desk B writes a number it computed from a value that desk A had already changed.',
                'A atualização perdida. O balcão B grava um número calculado a partir de um valor que o balcão A já tinha mudado.')


@figure('l10-pacelc', 10)
def pacelc():
    f = Fig('l10-pacelc', 700, 300, T(
        'PACELC as a decision tree. At the top, the question: is the network partitioned? The yes '
        'branch, which is the CAP theorem, splits into two leaves: A, stay available and accept '
        'that branches may disagree, or C, refuse on the side that cannot be sure. The no branch, '
        'the everyday case, also splits in two: L, answer fast from the nearest copy and accept '
        'stale reads, or C, wait for the replicas before saying done. A system is described by '
        'one choice on each side, such as PA/EL or PC/EC.',
        'PACELC como árvore de decisão. No alto, a pergunta: a rede está particionada? O ramo do '
        'sim, que é o teorema CAP, se divide em duas folhas: A, continuar disponível e aceitar que '
        'as filiais discordem, ou C, recusar do lado que não tem certeza. O ramo do não, o caso '
        'de todo dia, também se divide em dois: L, responder rápido da cópia mais próxima e '
        'aceitar leituras velhas, ou C, esperar as réplicas antes de dizer pronto. Um sistema é '
        'descrito por uma escolha de cada lado, como PA/EL ou PC/EC.'))
    f.box(350, 34, 230, 34, [T('is the network partitioned?', 'a rede está particionada?')], stroke='--amber')
    f.arrow([(300, 51), (300, 70), (180, 70), (180, 98)], stroke='--paper-dim')
    f.arrow([(400, 51), (400, 70), (520, 70), (520, 98)], stroke='--paper-dim')
    f.text(232, 62, T('yes: CAP', 'sim: CAP'), size=10, fill='--paper', weight='600')
    f.text(470, 62, T('no: Else', 'não: Else'), size=10, fill='--paper', weight='600')
    f.box(180, 116, 200, 34, [T('rare, and not yours to pick', 'raro, e não é você quem escolhe')], size=9.5)
    f.box(520, 116, 200, 34, [T('every other moment', 'todo o resto do tempo')], size=9.5)
    leaves = [
        (95, 'A', T('stay available;', 'continuar disponível;'), T('branches may disagree', 'as filiais podem discordar')),
        (265, 'C', T('refuse where', 'recusar onde'), T('it cannot be sure', 'não há certeza')),
        (435, 'L', T('answer fast;', 'responder rápido;'), T('reads may be stale', 'leituras podem ser velhas')),
        (605, 'C', T('wait for replicas;', 'esperar as réplicas;'), T('every read is current', 'toda leitura é atual')),
    ]
    for x, letter, l1, l2 in leaves:
        parent = 180 if x < 350 else 520
        f.arrow([(parent, 133), (parent, 150), (x, 150), (x, 178)], stroke='--paper-dim')
        f.rect(x - 78, 180, 156, 76, stroke='--phosphor', width=1.4)
        f.text(x, 198, letter, size=15, weight='700', fill='--amber', mono=True)
        f.text(x, 220, l1, size=9.5)
        f.text(x, 236, l2, size=9.5)
    f.text(350, 284, T('a system is named by one choice on each side: PA/EL, PC/EC, PA/EC',
                       'um sistema é nomeado por uma escolha de cada lado: PA/EL, PC/EC, PA/EC'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('CAP is the left half of the tree. PACELC adds the right half, the trade made when nothing is broken.',
                'O CAP é a metade esquerda da árvore. O PACELC acrescenta a metade direita, a troca feita quando nada está quebrado.')
