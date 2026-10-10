#!/usr/bin/env python3
"""The figures of lesson 8: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


@figure('l08-smoke-gate', 8)
def smoke_gate(lang):
    t = {
        'en': dict(
            build='a new build', smoke=['smoke', 'five checks, a minute'],
            go=['restart, then the planned testing', 'cases, sanity, regression'],
            which='your lab, or the build?', lab=['your lab: fix it', 'and run smoke again'],
            stop=['suspend, and tell', 'the developer once'], wait='wait for the next build',
            passed='all pass', failed='any fails', lab_w='the lab', build_w='the build',
            label='A flow. A new build goes to smoke, five checks taking a minute. If all pass, the '
                  'application is restarted and the planned testing starts: cases, sanity, regression. '
                  'If any check fails, the first question is whether the cause is your lab or the build. '
                  'If it is the lab, fix it and run smoke again. If it is the build, suspend testing and '
                  'tell the developer once, then wait for the next build, which goes to smoke again.',
            cap='Smoke as a gate. Nothing after it starts on a build that has not passed it, and a new '
                'build goes through it from the beginning.'),
        'pt': dict(
            build='uma versão nova', smoke=['fumaça', 'cinco checagens, um minuto'],
            go=['reiniciar, e então o teste planejado', 'casos, sanidade, regressão'],
            which='seu laboratório, ou a versão?', lab=['seu laboratório: conserte', 'e rode a fumaça de novo'],
            stop=['suspender, e avisar', 'o desenvolvedor uma vez'], wait='esperar a próxima versão',
            passed='todas passam', failed='alguma falha', lab_w='o laboratório', build_w='a versão',
            label='Um fluxo. Uma versão nova vai para a fumaça, cinco checagens que levam um minuto. Se '
                  'todas passam, a aplicação é reiniciada e o teste planejado começa: casos, sanidade, '
                  'regressão. Se alguma falha, a primeira pergunta é se a causa é o seu laboratório ou a '
                  'versão. Se for o laboratório, conserte e rode a fumaça de novo. Se for a versão, '
                  'suspenda o teste e avise o desenvolvedor uma vez, e então espere a próxima versão, '
                  'que vai de novo para a fumaça.',
            cap='A fumaça como portão. Nada depois dela começa numa versão que não passou por ela, e uma '
                'versão nova passa por ela desde o início.'),
    }[lang]
    f = Fig('l08-smoke-gate', 700, 300, t['label'])
    # row 1
    box(f, 20, 30, 140, 46, [t['build']], size=11)
    box(f, 220, 26, 170, 54, t['smoke'], stroke='--phosphor', fill='--scan',
        fills=['--paper', '--paper-dim'], weights=['600', None], size=11)
    box(f, 450, 26, 230, 54, t['go'], stroke='--phosphor', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10.5)
    arrow(f, 162, 53, 216, 53)
    arrow(f, 392, 53, 446, 53, stroke='--phosphor')
    f.text(419, 43, t['passed'], size=9.5, fill='--phosphor')
    # row 2
    box(f, 220, 130, 170, 42, [t['which']], stroke='--amber', size=10.5)
    arrow(f, 305, 82, 305, 126, stroke='--amber')
    f.text(298, 104, t['failed'], size=9.5, anchor='end', fill='--amber')
    box(f, 450, 126, 230, 50, t['lab'], fills=['--paper', '--paper-dim'], weights=['600', None],
        size=10.5)
    arrow(f, 392, 151, 446, 151)
    f.text(419, 141, t['lab_w'], size=9.5, fill='--paper-dim')
    # back from the lab box to smoke
    f.path('M565 124 L565 104 L360 104 L360 84', stroke='--paper-dim', width=1.4, dash='4 3',
           arrow=True)
    # row 3
    box(f, 220, 226, 170, 50, t['stop'], stroke='--amber', fills=['--paper', '--paper'],
        weights=['600', None], size=10.5)
    arrow(f, 305, 174, 305, 222, stroke='--amber')
    f.text(312, 198, t['build_w'], size=9.5, anchor='start', fill='--amber')
    box(f, 20, 230, 140, 42, [t['wait']], size=10)
    arrow(f, 218, 251, 164, 251)
    arrow(f, 90, 228, 90, 80)
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
