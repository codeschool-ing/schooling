# lesson 15

@figure('l15-cycle', 15)
def l15_cycle(lang):
    t = {
        'en': dict(steps=[('red', 'write a test that fails'), ('green', 'the least code that passes'),
                          ('refactor', 'tidy, tests still green')],
                   centre=['one cycle:', 'minutes'],
                   label='The TDD cycle as three boxes in a loop. Red: write a test that fails. Green: the least code '
                         'that passes. Refactor: tidy, tests still green. An arrow from refactor goes back to red for '
                         'the next test. In the middle: one cycle takes minutes.',
                   cap='Red, green, refactor, and round again. A feature is dozens of these.'),
        'pt': dict(steps=[('vermelho', 'escreva um teste que falha'), ('verde', 'o mínimo de código que passa'),
                          ('refatorar', 'arrumar, testes ainda verdes')],
                   centre=['um ciclo:', 'minutos'],
                   label='O ciclo do TDD como três caixas em laço. Vermelho: escreva um teste que falha. Verde: o mínimo '
                         'de código que passa. Refatorar: arrumar, com os testes ainda verdes. Uma seta sai de refatorar e '
                         'volta ao vermelho para o próximo teste. No meio: um ciclo leva minutos.',
                   cap='Vermelho, verde, refatorar, e de novo. Uma funcionalidade é dezenas destes.'),
    }[lang]
    f = Fig('l15-cycle', 600, 250, t['label'])
    pos = [(225, 12), (400, 150), (50, 150)]
    strokes = ['--amber', '--phosphor', '--wire']
    for (x, y), (name, what), st in zip(pos, t['steps'], strokes):
        box(f, x, y, 160, 56, [name, what], size=10, weights=['600', None],
            fills=['--amber' if st == '--amber' else '--phosphor' if st == '--phosphor' else '--paper', '--paper'],
            stroke=st)
    arrow(f, 385, 50, 470, 148)
    arrow(f, 398, 190, 212, 190)
    arrow(f, 130, 148, 223, 50)
    box(f, 245, 100, 120, 40, t['centre'], size=9.5, stroke='--wire', fill='--ink', fills=['--paper-dim', '--paper'])
    return f, t['cap']
