#!/usr/bin/env python3
"""The figures of lesson 18: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


@figure('l18-trace', 18)
def trace(lang):
    t = {
        'en': dict(
            req=('requirement R5', 'students pay half'),
            case=('case TC-10', 'Student pays half'),
            runs=[('run on 1.0', 'passed'), ('run on 1.1', 'failed')],
            bug=('defect report', 'student discount lost'),
            notes=['written once', 'one result per run', 'cited by the failure'],
            way='traceability: the same links, walked in either direction',
            label='Four kinds of box joined by arrows. Requirement R5, students pay half, points to case '
                  'TC-10, Student pays half, written once. The case points to two runs, each holding one '
                  'result: the run on 1.0 passed, the run on 1.1 failed. The failed result points to a '
                  'defect report, student discount lost. A line underneath says the same links can be '
                  'walked in either direction.',
            cap='One case, written once, and its results in two runs. The links from the requirement to '
                'the defect are what lets a tool answer both "is R5 tested?" and "what does this defect '
                'threaten?".'),
        'pt': dict(
            req=('requisito R5', 'estudante paga meia'),
            case=('caso TC-10', 'Student pays half'),
            runs=[('execução na 1.0', 'passou'), ('execução na 1.1', 'falhou')],
            bug=('relato de defeito', 'desconto de estudante perdido'),
            notes=['escrito uma vez', 'um resultado por execução', 'citado pela falha'],
            way='rastreabilidade: os mesmos vínculos, percorridos nos dois sentidos',
            label='Quatro tipos de caixa ligados por setas. O requisito R5, estudante paga meia, aponta '
                  'para o caso TC-10, Student pays half, escrito uma vez. O caso aponta para duas '
                  'execuções, cada uma com um resultado: a execução na 1.0 passou, a execução na 1.1 '
                  'falhou. O resultado que falhou aponta para um relato de defeito, desconto de estudante '
                  'perdido. Uma linha embaixo diz que os mesmos vínculos podem ser percorridos nos dois '
                  'sentidos.',
            cap='Um caso, escrito uma vez, e seus resultados em duas execuções. Os vínculos do requisito '
                'até o defeito são o que deixa uma ferramenta responder tanto "o R5 está testado?" quanto '
                '"o que este defeito ameaça?".'),
    }[lang]
    f = Fig('l18-trace', 720, 230, t['label'])
    w, h = 150, 52
    box(f, 15, 60, w, h, list(t['req']), stroke='--wire', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10.5)
    box(f, 200, 60, w, h, list(t['case']), stroke='--phosphor', fill='--scan',
        fills=['--paper', '--phosphor'], weights=['600', None], size=10.5)
    ys = [20, 100]
    for (name, res), y in zip(t['runs'], ys):
        bad = y == 100
        box(f, 385, y, w, h, [name, res], stroke='--amber' if bad else '--phosphor',
            fills=['--paper', '--amber' if bad else '--phosphor'], weights=['600', '600'], size=10.5)
    box(f, 560, 100, w, h, list(t['bug']), stroke='--amber', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10.5)
    arrow(f, 165, 86, 197, 86)
    arrow(f, 350, 78, 382, 50)
    arrow(f, 350, 94, 382, 122)
    arrow(f, 535, 126, 557, 126, stroke='--amber')
    f.text(275, 128, t['notes'][0], size=9.5, fill='--paper-dim')
    f.text(460, 168, t['notes'][1], size=9.5, fill='--paper-dim')
    f.text(635, 168, t['notes'][2], size=9.5, fill='--paper-dim')
    f.line(15, 196, 710, 196, stroke='--wire', width=1.2, dash='4 3')
    f.text(362, 214, t['way'], size=10, fill='--paper')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
