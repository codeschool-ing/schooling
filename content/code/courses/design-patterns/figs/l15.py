"""Lesson 15: functional programming."""
from figures import Fig, T, figure


@figure('l15-shell', 15)
def shell():
    f = Fig('l15-shell', 720, 300, T(
        'A functional core inside an imperative shell. The outer box, the shell, holds the effects: '
        'on the left, loading the loans and reading the date from the command line or the clock; '
        'on the right, writing outbox.txt and printing a summary. Arrows carry the loans and the '
        'date into the inner box, the core, which holds the pure functions notices and days_late and '
        'returns a list of Notice values. An arrow carries the notices back out to the shell, which '
        'writes them. Beneath the shell: effects, few decisions. Beneath the core: decisions, no '
        'effects.',
        'Um núcleo funcional dentro de uma casca imperativa. A caixa de fora, a casca, guarda os '
        'efeitos: à esquerda, carregar os empréstimos e ler a data da linha de comando ou do '
        'relógio; à direita, gravar outbox.txt e imprimir um resumo. Setas levam os empréstimos e a '
        'data para a caixa de dentro, o núcleo, que guarda as funções puras notices e days_late e '
        'devolve uma lista de valores Notice. Uma seta leva os avisos de volta para a casca, que os '
        'grava. Embaixo da casca: efeitos, poucas decisões. Embaixo do núcleo: decisões, nenhum '
        'efeito.'))
    f.rect(20, 20, 680, 262, stroke='--amber', fill='--ink', width=1.6, rx=8, dash='6 4')
    f.text(40, 40, T('imperative shell: shell.py', 'casca imperativa: shell.py'), size=11, weight='600', anchor='start')
    f.rect(250, 70, 220, 150, stroke='--phosphor', fill='--panel', width=1.8, rx=6)
    f.text(360, 90, T('functional core: core.py', 'núcleo funcional: core.py'), size=11, weight='600')
    f.text(360, 122, 'notices(loans, today)', size=10, mono=True)
    f.text(360, 142, 'days_late(loan, today)', size=10, mono=True)
    f.text(360, 172, '→ list[Notice]', size=10, mono=True)
    f.text(360, 204, T('decisions, no effects', 'decisões, nenhum efeito'), size=10, fill='--paper-dim', italic=True)
    f.box(130, 105, 170, 36, [T('load the loans', 'carregar os empréstimos')], size=10)
    f.box(130, 175, 170, 36, [T('date: argv or the clock', 'data: argv ou relógio')], size=10)
    f.arrow([(215, 105), (250, 120)], stroke='--paper-dim', width=1.3)
    f.arrow([(215, 175), (250, 160)], stroke='--paper-dim', width=1.3)
    f.box(590, 105, 170, 36, [T('write outbox.txt', 'gravar outbox.txt')], size=10)
    f.box(590, 175, 170, 36, [T('print a summary', 'imprimir um resumo')], size=10)
    f.arrow([(470, 140), (505, 110)], stroke='--paper-dim', width=1.3)
    f.arrow([(470, 150), (505, 172)], stroke='--paper-dim', width=1.3)
    f.text(360, 258, T('effects, few decisions', 'efeitos, poucas decisões'), size=10, fill='--amber', italic=True)
    return f, T('The core is tested with plain values; the shell is thin enough to check by running it once.',
                'O núcleo é testado com valores simples; a casca é fina o bastante para ser conferida rodando uma vez.')


@figure('l15-pipeline', 15)
def pipeline():
    f = Fig('l15-pipeline', 720, 250, T(
        'The fines of March as a pipeline, left to right. Four loans go into filter, which keeps the '
        'ones more than zero days late: Bia\'s first book, Caio\'s film and Duda\'s film; Bia\'s second '
        'book, returned early, is dropped. Map turns each of the three into a fine: 200, 750 and 200 '
        'cents. Reduce adds them into one value, 1150.',
        'As multas de março como um encadeamento, da esquerda para a direita. Quatro empréstimos '
        'entram em filter, que mantém os que têm mais de zero dias de atraso: o primeiro livro da '
        'Bia, o filme do Caio e o filme da Duda; o segundo livro da Bia, devolvido antes, cai fora. '
        'Map transforma cada um dos três numa multa: 200, 750 e 200 centavos. Reduce soma tudo num '
        'valor só, 1150.'))
    loans = [T('Bia, 4 days', 'Bia, 4 dias'), T('Caio, 15 days', 'Caio, 15 dias'),
             T('Bia, 0 days', 'Bia, 0 dias'), T('Duda, 4 days', 'Duda, 4 dias')]
    ys = [55, 100, 145, 190]
    for y, s in zip(ys, loans):
        f.box(80, y, 120, 30, [s], size=10)
    f.text(80, 22, T('4 loans', '4 empréstimos'), size=10, fill='--paper-dim', weight='600')

    def stage(x, top, bottom):
        f.rect(x - 52, 40, 104, 165, stroke='--scan', fill='--panel', rx=6)
        f.text(x, 110, top, size=11, weight='600', mono=True)
        f.text(x, 132, bottom, size=9.5, fill='--paper-dim', mono=True)

    stage(225, 'filter', 'days > 0')
    for y in ys:
        f.arrow([(140, y), (173, y)], stroke='--paper-dim', width=1)
    kept = [ys[0], ys[1], ys[3]]
    for y, s in zip(kept, [loans[0], loans[1], loans[3]]):
        f.arrow([(277, y), (305, y)], stroke='--paper-dim', width=1)
        f.box(363, y, 112, 30, [s], size=10)
    f.text(225, 222, T('the early return is dropped', 'a devolução antecipada cai fora'), size=9.5, fill='--paper-dim',
           italic=True)
    stage(490, 'map', 'days * 50')
    for y in kept:
        f.arrow([(419, y), (438, y)], stroke='--paper-dim', width=1)
    for y, v in zip(kept, ['200', '750', '200']):
        f.arrow([(542, y), (560, y)], stroke='--paper-dim', width=1)
        f.box(585, y, 46, 26, [v], size=10, mono=True, stroke='--phosphor')
    f.arrow([(608, 122), (628, 122)], stroke='--paper-dim', width=1)
    f.text(580, 22, T('3 fines, in cents', '3 multas, em centavos'), size=10, fill='--paper-dim', weight='600')
    f.box(668, 122, 76, 54, ['reduce +', '1150'], size=10.5, mono=True, stroke='--amber')
    f.line(608, 55, 608, 190, stroke='--paper-dim', width=1)
    return f, T('Each stage is a pure function of what the previous one produced, and each can be read and tested alone.',
                'Cada etapa é uma função pura do que a anterior produziu, e cada uma pode ser lida e testada sozinha.')
