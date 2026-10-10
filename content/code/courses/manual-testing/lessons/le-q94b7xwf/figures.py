#!/usr/bin/env python3
"""The figures of lesson 16: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


@figure('l16-lifecycle', 16)
def lifecycle(lang):
    t = {
        'en': dict(
            new='new', tri='triaged (open)', prog='in progress', fixed='fixed',
            ready='ready for retest', reo='reopened', ver='verified', closed='closed',
            dup='duplicate', rej='rejected', defer='deferred',
            passes='retest passes', fails='retest fails', build='build delivered',
            exits='exits at triage', tester='moved by the tester', other='moved by others',
            label='A state diagram of a defect report. New leads to triaged, also called open, then in '
                  'progress, then fixed. A delivered build moves fixed to ready for retest. From ready '
                  'for retest, a passing retest leads to verified and then closed; a failing retest '
                  'leads to reopened, which goes back to in progress. From triaged, three exits lead '
                  'out of the path: duplicate, rejected and deferred. The tester moves a report into '
                  'new, and out of ready for retest in either direction.',
            cap='The states a defect report passes through, and the moves between them. The tester\'s '
                'moves are drawn in a colour of their own: filing the report, and deciding the retest.'),
        'pt': dict(
            new='novo', tri='triado (aberto)', prog='em andamento', fixed='corrigido',
            ready='pronto para reteste', reo='reaberto', ver='verificado', closed='fechado',
            dup='duplicado', rej='rejeitado', defer='adiado',
            passes='reteste passa', fails='reteste falha', build='build entregue',
            exits='saídas na triagem', tester='movido por quem testa', other='movido por outros',
            label='Um diagrama de estados de um relato de defeito. Novo leva a triado, também chamado '
                  'aberto, depois a em andamento, depois a corrigido. Um build entregue move corrigido '
                  'para pronto para reteste. De pronto para reteste, um reteste que passa leva a '
                  'verificado e depois a fechado; um reteste que falha leva a reaberto, que volta para '
                  'em andamento. De triado, três saídas deixam o caminho: duplicado, rejeitado e '
                  'adiado. Quem testa coloca o relato em novo, e o tira de pronto para reteste nas duas '
                  'direções.',
            cap='Os estados por que passa um relato de defeito, e os movimentos entre eles. Os movimentos '
                'de quem testa têm uma cor própria: abrir o relato e decidir o reteste.'),
    }[lang]
    f = Fig('l16-lifecycle', 700, 300, t['label'])
    W, H = 140, 38
    pos = {
        'new': (20, 40), 'tri': (190, 40), 'prog': (360, 40), 'fixed': (540, 40),
        'ready': (540, 140), 'reo': (360, 140), 'ver': (540, 240), 'closed': (360, 240),
    }
    for k, (x, y) in pos.items():
        main_path = k in ('new', 'tri', 'prog', 'fixed', 'ready', 'ver', 'closed')
        stroke = '--phosphor' if k == 'closed' else '--amber' if k == 'reo' else '--wire'
        box(f, x, y, W, H, [t[k]], stroke=stroke, fill='--scan' if k == 'closed' else '--panel',
            size=11, weights=['600' if main_path else None])
    # filing the report: the tester's first move
    f.line(20 + W / 2, 14, 20 + W / 2, 40, stroke='--amber', width=1.6, arrow=True)
    # main path
    arrow(f, 160, 59, 190, 59)
    arrow(f, 330, 59, 360, 59)
    arrow(f, 500, 59, 540, 59)
    arrow(f, 610, 78, 610, 140)
    f.text(618, 109, t['build'], size=9.5, anchor='start', fill='--paper-dim')
    # the retest, both ways
    f.line(610, 178, 610, 240, stroke='--amber', width=1.6, arrow=True)
    f.text(618, 209, t['passes'], size=9.5, anchor='start', fill='--amber')
    f.line(540, 159, 500, 159, stroke='--amber', width=1.6, arrow=True)
    f.text(520, 132, t['fails'], size=9.5, fill='--amber')
    arrow(f, 430, 140, 430, 78)
    arrow(f, 540, 259, 500, 259)
    # exits at triage
    ex = [('dup', 120), ('rej', 175), ('defer', 230)]
    f.line(205, 78, 205, 247, stroke='--paper-dim', width=1.2, dash='3 3')
    for k, y in ex:
        f.line(205, y + 17, 222, y + 17, stroke='--paper-dim', width=1.2, dash='3 3', arrow=True)
        box(f, 224, y, 106, 34, [t[k]], stroke='--wire', fill='--panel', size=10.5, dash='4 3')
    f.text(20, 120, t['exits'], size=10, anchor='start', fill='--paper-dim', weight='600')
    # legend
    f.line(20, 236, 48, 236, stroke='--amber', width=1.6)
    f.text(56, 236, t['tester'], size=9.5, anchor='start', fill='--paper-dim')
    f.line(20, 258, 48, 258, stroke='--paper-dim', width=1.4)
    f.text(56, 258, t['other'], size=9.5, anchor='start', fill='--paper-dim')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
