#!/usr/bin/env python3
"""The figures of lesson 6: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


@figure('l06-two-questions', 6)
def two_questions(lang):
    t = {
        'en': dict(
            boxes=[('the need', 'the theatre, its staff,', 'its audience'),
                   ('the requirements', 'R1 to R9', ''),
                   ('the product', 'boxoffice 1.0', '')],
            made=['written from', 'built from'],
            review=('review', 'nothing runs'),
            ver=('verification', 'are we building it right?'),
            val=('validation', 'are we building the right thing?'),
            label='Three boxes in a row: the need, meaning the theatre, its staff and its audience; the '
                  'requirements, R1 to R9; and the product, boxoffice 1.0. The requirements are written '
                  'from the need and the product is built from the requirements. A review checks the '
                  'requirements and runs nothing. Verification compares the product with the '
                  'requirements and asks whether it is built right. Validation compares the product with '
                  'the need and asks whether it is the right thing.',
            cap='What each activity compares. Verification and the review never leave the written '
                'requirements; validation is the only one that reaches past them to the need.'),
        'pt': dict(
            boxes=[('a necessidade', 'o teatro, sua equipe,', 'seu público'),
                   ('os requisitos', 'R1 a R9', ''),
                   ('o produto', 'boxoffice 1.0', '')],
            made=['dá origem', 'dão origem'],
            review=('revisão', 'nada roda'),
            ver=('verificação', 'estamos construindo certo?'),
            val=('validação', 'estamos construindo a coisa certa?'),
            label='Três caixas em fila: a necessidade, isto é, o teatro, sua equipe e seu público; os '
                  'requisitos, R1 a R9; e o produto, boxoffice 1.0. Os requisitos são escritos a partir '
                  'da necessidade e o produto é construído a partir dos requisitos. Uma revisão confere '
                  'os requisitos e não roda nada. A verificação compara o produto com os requisitos e '
                  'pergunta se ele está construído certo. A validação compara o produto com a '
                  'necessidade e pergunta se ele é a coisa certa.',
            cap='O que cada atividade compara. A verificação e a revisão nunca saem dos requisitos '
                'escritos; a validação é a única que passa por eles e chega à necessidade.'),
    }[lang]
    f = Fig('l06-two-questions', 700, 270, t['label'])
    xs = [20, 260, 500]
    w, y, h = 180, 70, 70
    for i, (x, (a, b, c)) in enumerate(zip(xs, t['boxes'])):
        lines = [a, b] + ([c] if c else [])
        box(f, x, y, w, h, lines, stroke='--amber' if i == 0 else '--wire',
            fills=['--paper'] + ['--paper-dim'] * (len(lines) - 1), weights=['600'] + [None] * 2,
            size=11)
    for i, word in enumerate(t['made']):
        x1, x2 = xs[i] + w + 4, xs[i + 1] - 4
        arrow(f, x1, y + h / 2, x2, y + h / 2, stroke='--paper-dim')
        f.text((x1 + x2) / 2, y + h / 2 - 12, word, size=9.5, fill='--paper-dim')
    # the review: a loop over the requirements box
    cx = xs[1] + w / 2
    f.path(f'M{cx - 40} {y - 4} C{cx - 40} {y - 44} {cx + 40} {y - 44} {cx + 40} {y - 4}',
           stroke='--phosphor', width=1.4, arrow=True)
    f.text(cx, y - 52, t['review'][0] + ': ' + t['review'][1], size=10, fill='--phosphor')
    # verification: product against requirements
    vy = y + h + 30
    a1, a2 = xs[2] + w / 2, xs[1] + w / 2
    f.path(f'M{a1} {y + h + 4} L{a1} {vy} L{a2} {vy} L{a2} {y + h + 4}', stroke='--phosphor',
           width=1.4, arrow=True)
    f.text((a1 + a2) / 2, vy + 13, t['ver'][0] + ': ' + t['ver'][1], size=10, fill='--phosphor')
    # validation: product against the need
    vy2 = vy + 50
    b1, b2 = xs[2] + w / 2 + 30, xs[0] + w / 2
    f.path(f'M{b1} {y + h + 4} L{b1} {vy2} L{b2} {vy2} L{b2} {y + h + 4}', stroke='--amber',
           width=1.4, arrow=True)
    f.text((b1 + b2) / 2, vy2 + 13, t['val'][0] + ': ' + t['val'][1], size=10, fill='--amber')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
