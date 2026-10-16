"""Lesson 18: concurrency and parallelism."""
from figures import Fig, T, figure


@figure('l18-lost-update', 18)
def lost_update():
    f = Fig('l18-lost-update', 640, 300, T(
        'A timeline of a lost update, read from top to bottom. Desk A is on the left, the shared '
        'counter in the middle and desk B on the right. First desk A reads the counter, 7. Then '
        'desk B reads it, also 7. Desk A writes 7 plus 1, so the counter becomes 8. Desk B writes '
        '7 plus 1 as well, and the counter is 8 again. Two loans were recorded and the counter '
        'moved by one.',
        'Uma linha do tempo de uma atualização perdida, lida de cima para baixo. O balcão A fica à '
        'esquerda, o contador compartilhado no meio e o balcão B à direita. Primeiro o balcão A lê '
        'o contador, 7. Depois o balcão B lê, também 7. O balcão A escreve 7 mais 1, e o contador '
        'vira 8. O balcão B também escreve 7 mais 1, e o contador é 8 de novo. Dois empréstimos '
        'foram registrados e o contador andou um.'))
    xa, xs, xb = 130, 320, 510
    f.box(xa, 30, 150, 28, [T('desk A', 'balcão A')], stroke='--phosphor', size=11)
    f.box(xs, 30, 130, 28, ['issued'], stroke='--amber', size=11, mono=True)
    f.box(xb, 30, 150, 28, [T('desk B', 'balcão B')], stroke='--phosphor', size=11)
    boxes = {xa: [78, 166], xs: [78, 122, 166, 210], xb: [122, 210]}
    for x, ys in boxes.items():
        top = 44
        for y in ys + [251]:
            if y - 13 > top + 2:
                f.line(x, top, x, y - 13, stroke='--wire', width=1, dash='3 4')
            top = y + 13
    f.arrow([(28, 60), (28, 236)], stroke='--paper-dim', width=1)
    f.text(40, 250, T('time', 'tempo'), size=10, fill='--paper-dim', italic=True, anchor='start')
    rows = [
        (78, 'A', T('read: seen = 7', 'lê: seen = 7'), '7', 'read'),
        (122, 'B', T('read: seen = 7', 'lê: seen = 7'), '7', 'read'),
        (166, 'A', T('write: 7 + 1', 'escreve: 7 + 1'), '8', 'write'),
        (210, 'B', T('write: 7 + 1', 'escreve: 7 + 1'), '8', 'write'),
    ]
    for y, who, label, value, kind in rows:
        x = xa if who == 'A' else xb
        f.box(x, y, 150, 26, [label], size=10)
        last = (who, kind) == ('B', 'write')
        f.box(xs, y, 46, 26, [value], size=11, mono=True,
              stroke='--amber' if last else '--wire', fillt='--amber' if last else '--paper')
        edge_l, edge_r = (x + 75, xs - 23) if who == 'A' else (x - 75, xs + 23)
        if kind == 'read':
            f.arrow([(edge_r, y), (edge_l, y)], stroke='--paper-dim', width=1.2)
        else:
            f.arrow([(edge_l, y), (edge_r, y)], stroke='--phosphor', width=1.4)
    f.text(xs, 262, T('two loans recorded, the counter moved by one',
                      'dois empréstimos registrados, o contador andou um'),
           size=11, fill='--amber', weight='600')
    f.text(xs, 284, T('B wrote over A: the update A made is lost',
                      'B escreveu por cima de A: a atualização de A se perdeu'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('A lost update. Both desks read before either writes, so the second write erases the first.',
                'Uma atualização perdida. Os dois balcões leem antes de qualquer um escrever, e a segunda escrita apaga a primeira.')


def _wait_graph(f, ox, title, cycle):
    f.text(ox + 170, 16, title, size=11, weight='600')
    top, bot = (ox + 170, 66), (ox + 170, 236)
    d1, d2 = (ox + 55, 151), (ox + 285, 151)
    f.box(*top, 130, 30, [T("Bia's lock, 17", 'trava de Bia, 17')], stroke='--amber', size=10)
    f.box(*bot, 130, 30, [T("Caio's lock, 42", 'trava de Caio, 42')], stroke='--amber', size=10)
    f.box(*d1, 90, 30, [T('desk 1', 'balcão 1')], stroke='--phosphor', size=10)
    f.box(*d2, 90, 30, [T('desk 2', 'balcão 2')], stroke='--phosphor', size=10)
    held, wait = dict(stroke='--phosphor', width=1.5), dict(stroke='--amber', width=1.5, dash='5 4')
    # desk 1 holds Bia's lock in both drawings
    f.arrow([(top[0] - 65, top[1] + 8), (d1[0], d1[1] - 15)], **held)
    if cycle:
        f.arrow([(d1[0], d1[1] + 15), (bot[0] - 65, bot[1] - 8)], **wait)
        f.arrow([(bot[0] + 65, bot[1] - 8), (d2[0], d2[1] + 15)], **held)
        f.arrow([(d2[0], d2[1] - 15), (top[0] + 65, top[1] + 8)], **wait)
        f.text(ox + 170, 151, T('a cycle: nobody moves', 'um ciclo: ninguém anda'),
               size=10.5, fill='--amber', weight='600')
    else:
        f.arrow([(bot[0] - 65, bot[1] - 8), (d1[0], d1[1] + 15)], **held)
        f.arrow([(d2[0], d2[1] - 15), (top[0] + 65, top[1] + 8)], **wait)
        f.lines(ox + 170, 151, [T('no cycle: desk 2 waits,', 'sem ciclo: o balcão 2 espera,'),
                                T('desk 1 finishes', 'o balcão 1 termina')],
                size=10.5, fill='--paper', weight='600')


@figure('l18-deadlock', 18)
def deadlock():
    f = Fig('l18-deadlock', 720, 300, T(
        "Two wait-for graphs side by side. On the left, each desk locks the giver first: desk 1 "
        "holds Bia's lock and waits for Caio's, while desk 2 holds Caio's lock and waits for "
        "Bia's. The arrows form a closed cycle, so neither desk can move. On the right, both desks "
        "take the lower-numbered lock first: desk 1 holds Bia's lock, number 17, and goes on to "
        "take Caio's, number 42, while desk 2 waits for lock 17. There is no cycle, so desk 1 "
        "finishes and then desk 2 runs.",
        "Dois grafos de espera lado a lado. À esquerda, cada balcão trava primeiro quem cede: o "
        "balcão 1 segura a trava de Bia e espera a de Caio, enquanto o balcão 2 segura a trava de "
        "Caio e espera a de Bia. As setas formam um ciclo fechado, e nenhum balcão consegue andar. "
        "À direita, os dois balcões pegam primeiro a trava de número menor: o balcão 1 segura a "
        "trava de Bia, número 17, e em seguida pega a de Caio, número 42, enquanto o balcão 2 "
        "espera a trava 17. Não há ciclo, então o balcão 1 termina e depois o balcão 2 roda."))
    _wait_graph(f, 0, T('each desk locks the giver first', 'cada balcão trava primeiro quem cede'), True)
    f.line(360, 10, 360, 262, stroke='--wire', width=1, dash='4 4')
    _wait_graph(f, 360, T('both lock the lower number first', 'os dois travam primeiro o número menor'), False)
    f.line(190, 284, 230, 284, stroke='--phosphor', width=1.5)
    f.text(238, 284, T('holds', 'segura'), size=10, anchor='start')
    f.line(420, 284, 460, 284, stroke='--amber', width=1.5, dash='5 4')
    f.text(468, 284, T('waits for', 'espera'), size=10, anchor='start')
    return f, T('A deadlock is a cycle of waiting. One agreed order for taking locks makes the cycle impossible.',
                'Um deadlock é um ciclo de espera. Uma ordem combinada para pegar as travas torna o ciclo impossível.')
