# lesson 5

@figure('l05-gate-or-loop', 5)
def l05_gate_or_loop(lang):
    t = {
        'en': dict(gate='a gate at the end', loop='a tester in every step',
                   steps=['rule', 'code', 'finished', 'release'],
                   wall='the wall', g='QA approves?', back='defects, sent back',
                   asks=['asks', 'pairs', 'explores', 'informs'], dec='Joana decides',
                   label='Two arrangements. Top: a gate at the end. Rule, code and finished run left to right; then a '
                         'wall, then a box marked QA approves, then release; an arrow labelled defects, sent back returns '
                         'from the gate to code. Bottom: a tester in every step. Rule, code, finished and release run left '
                         'to right, and under each one the tester does something: asks, pairs, explores, informs; at '
                         'release, Joana decides.',
                   cap='Above, everything reaches the tester at once, at the end, across a wall. Below, the tester is in '
                       'each step, and the release is the product owner’s decision with the tester’s information in it.'),
        'pt': dict(gate='um portão no fim', loop='quem testa em cada passo',
                   steps=['regra', 'código', 'pronto', 'entrega'],
                   wall='o muro', g='QA aprova?', back='defeitos, devolvidos',
                   asks=['pergunta', 'pareia', 'explora', 'informa'], dec='a Joana decide',
                   label='Dois arranjos. Em cima: um portão no fim. Regra, código e pronto vão da esquerda para a direita; '
                         'depois um muro, depois uma caixa marcada QA aprova, depois entrega; uma seta com o rótulo defeitos, '
                         'devolvidos volta do portão para o código. Embaixo: quem testa em cada passo. Regra, código, pronto e '
                         'entrega vão da esquerda para a direita, e sob cada um quem testa faz algo: pergunta, pareia, '
                         'explora, informa; na entrega, a Joana decide.',
                   cap='Em cima, tudo chega a quem testa de uma vez, no fim, por cima de um muro. Embaixo, quem testa está '
                       'em cada passo, e a entrega é decisão da dona do produto com a informação de quem testa dentro.'),
    }[lang]
    f = Fig('l05-gate-or-loop', 680, 330, t['label'])
    # top: gate
    f.text(20, 22, t['gate'], size=11, anchor='start', weight='600')
    xs = [20, 130, 240]
    for x, s in zip(xs, t['steps'][:3]):
        box(f, x, 40, 90, 36, [s], size=10.5)
    arrow(f, 111, 58, 129, 58)
    arrow(f, 221, 58, 239, 58)
    f.line(352, 32, 352, 84, stroke='--amber', width=4)
    f.text(352, 100, t['wall'], size=9.5, fill='--amber')
    arrow(f, 331, 58, 380, 58)
    box(f, 382, 40, 110, 36, [t['g']], stroke='--amber', size=10.5, weights=['600'])
    arrow(f, 493, 58, 539, 58)
    box(f, 541, 40, 100, 36, [t['steps'][3]], size=10.5)
    f.path('M437 77 L437 118 L175 118 L175 78', stroke='--amber', width=1.4, arrow=True, dash='4 3')
    f.text(306, 132, t['back'], size=9.5, fill='--amber')
    # bottom: loop
    f.text(20, 176, t['loop'], size=11, anchor='start', weight='600')
    xs2 = [20, 185, 350, 515]
    for i, (x, s) in enumerate(zip(xs2, t['steps'])):
        box(f, x, 194, 125, 36, [s], size=10.5)
        if i:
            arrow(f, x - 39, 212, x - 1, 212)
        f.line(x + 62, 231, x + 62, 256, stroke='--phosphor', width=1.4, dash='3 3')
        box(f, x + 12, 258, 101, 30, [t['asks'][i]], stroke='--phosphor', size=10, fills=['--phosphor'])
    f.text(515 + 62, 306, t['dec'], size=9.5, fill='--paper-dim', weight='600')
    return f, t['cap']
