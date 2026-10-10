#!/usr/bin/env python3
"""The figures of lesson 5: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


@figure('l05-discount-table', 5)
def discount_table(lang):
    t = {
        'en': dict(
            rows=['rule', 'student?', 'member?', '5 tickets or more?', 'discount (R5)'],
            yes='Y', no='N', group='a student: 50%, whatever else is true',
            note='rule 5: 10% and 15% both apply; the larger one wins',
            label='A decision table with eight rule columns. Conditions: student, Y for rules 1 to 4 and '
                  'N for 5 to 8; member, Y Y N N Y Y N N; 5 tickets or more, alternating Y and N. Action, '
                  'the discount: 50, 50, 50, 50, 15, 10, 15 and 0 percent. Rules 1 to 4 are bracketed as a '
                  'student, 50% whatever else is true. Rule 5 is outlined: 10% and 15% both apply, and the '
                  'larger one wins.',
            cap='R5 as a full decision table: three conditions, eight rules, and the discount the '
                'requirement asks for in each. Rule 5 is the column where the sentence "the largest one '
                'applies" decides the answer.'),
        'pt': dict(
            rows=['regra', 'estudante?', 'membro?', '5 ingressos ou mais?', 'desconto (R5)'],
            yes='S', no='N', group='estudante: 50%, não importa o resto',
            note='regra 5: 10% e 15% valem; o maior vence',
            label='Uma tabela de decisão com oito colunas de regras. Condições: estudante, S nas regras 1 '
                  'a 4 e N de 5 a 8; membro, S S N N S S N N; 5 ingressos ou mais, alternando S e N. Ação, '
                  'o desconto: 50, 50, 50, 50, 15, 10, 15 e 0 por cento. As regras 1 a 4 têm uma chave: '
                  'estudante, 50% não importa o resto. A regra 5 tem contorno: 10% e 15% valem, e o maior '
                  'vence.',
            cap='O R5 como tabela de decisão completa: três condições, oito regras e o desconto que o '
                'requisito pede em cada uma. A regra 5 é a coluna em que a frase "vale o maior" decide a '
                'resposta.'),
    }[lang]
    f = Fig('l05-discount-table', 720, 245, t['label'])
    left, cw, top, rh = 210, 58, 50, 30
    right = left + 8 * cw
    student = [1, 1, 1, 1, 0, 0, 0, 0]
    member = [1, 1, 0, 0, 1, 1, 0, 0]
    many = [1, 0, 1, 0, 1, 0, 1, 0]
    off = ['50%', '50%', '50%', '50%', '15%', '10%', '15%', '0%']
    # the bracket over rules 1 to 4
    f.path(f'M{left + 4} {top - 8} L{left + 4} {top - 16} L{left + 4 * cw - 4} {top - 16} '
           f'L{left + 4 * cw - 4} {top - 8}', stroke='--phosphor', width=1.2)
    f.text(left + 2 * cw, top - 28, t['group'], size=10, fill='--phosphor')
    for r, name in enumerate(t['rows']):
        y = top + r * rh
        action = r == 4
        f.rect(20, y + 2, right - 20, rh - 4, stroke='--wire', fill='--scan' if r == 0 else '--panel',
               rx=2, width=1)
        # rule 5's cell, outlined in every row
        f.rect(left + 4 * cw + 3, y + 5, cw - 6, rh - 10, stroke='--amber',
               fill='--scan' if r == 0 else '--panel', rx=3, width=1.6)
        f.text(30, y + rh / 2, name, size=10.5, anchor='start', weight='600' if r in (0, 4) else None,
               fill='--amber' if action else '--paper')
        for c in range(8):
            x = left + c * cw + cw / 2
            if r == 0:
                f.text(x, y + rh / 2, str(c + 1), size=10.5, weight='600', mono=True)
            elif action:
                f.text(x, y + rh / 2, off[c], size=10.5, weight='600', mono=True, fill='--amber')
            else:
                v = [student, member, many][r - 1][c]
                f.text(x, y + rh / 2, t['yes'] if v else t['no'], size=10.5, mono=True,
                       fill='--phosphor' if v else '--paper-dim')
    # the rule between conditions and action, and rule 5's cells outlined
    x5 = left + 4 * cw
    f.line(20, top + 4 * rh, right, top + 4 * rh, stroke='--paper-dim', width=2)
    f.text(x5 + cw / 2, top + 5 * rh + 22, t['note'], size=10, fill='--amber')
    return f, t['cap']


@figure('l05-order-states', 5)
def order_states(lang):
    t = {
        'en': dict(
            states=dict(reserved='reserved', paid='paid', used='used', cancelled='cancelled',
                        refunded='refunded'),
            pay='pay', cancel='cancel', use='use', refund='refund', back='/ seats back',
            guard='[before the show starts]', start='new order', final='double border: final state',
            label='A state diagram of an order. A new order enters reserved. From reserved, pay leads to '
                  'paid and cancel leads to cancelled, giving the seats back. From paid, use leads to used, '
                  'and refund, guarded by before the show starts, leads to refunded, giving the seats '
                  'back. Used, cancelled and refunded have double borders: they are final states, with no '
                  'way out.',
            cap='R6 as a state machine: five states, four transitions, one guard and the action two of '
                'the transitions carry. What the diagram does not draw, a button pressed in a state with '
                'no arrow for it, is the other half of the testing.'),
        'pt': dict(
            states=dict(reserved='reservado', paid='pago', used='usado', cancelled='cancelado',
                        refunded='reembolsado'),
            pay='pagar', cancel='cancelar', use='usar', refund='reembolsar', back='/ devolve lugares',
            guard='[antes de o espetáculo começar]', start='novo pedido',
            final='borda dupla: estado final',
            label='Um diagrama de estados de um pedido. Um pedido novo entra em reservado. De reservado, '
                  'pagar leva a pago e cancelar leva a cancelado, devolvendo os lugares. De pago, usar leva '
                  'a usado, e reembolsar, com a guarda antes de o espetáculo começar, leva a reembolsado, '
                  'devolvendo os lugares. Usado, cancelado e reembolsado têm borda dupla: são estados '
                  'finais, sem saída.',
            cap='O R6 como máquina de estados: cinco estados, quatro transições, uma guarda e a ação que '
                'duas das transições carregam. O que o diagrama não desenha, um botão apertado num estado '
                'sem seta para ele, é a outra metade do teste.'),
    }[lang]
    s = t['states']
    f = Fig('l05-order-states', 720, 310, t['label'])
    W, H = 130, 40
    pos = dict(reserved=(80, 120), paid=(320, 120), used=(570, 30), refunded=(570, 210),
               cancelled=(320, 245))
    for k, (x, y) in pos.items():
        final = k in ('used', 'cancelled', 'refunded')
        if final:
            f.rect(x - 4, y - 4, W + 8, H + 8, stroke='--paper-dim', fill='--panel', rx=6, width=1)
        box(f, x, y, W, H, [s[k]], stroke='--phosphor' if k == 'reserved' else '--wire',
            fill='--scan' if k == 'reserved' else '--panel', size=11.5, weights=['600'])
    # the initial state
    f.circle(24, 140, 6, fill='--paper')
    arrow(f, 30, 140, 78, 140)
    f.text(24, 120, t['start'], size=10, anchor='start', fill='--paper-dim')
    # reserved -> paid
    arrow(f, 210, 140, 318, 140, stroke='--paper')
    f.text(264, 130, t['pay'], size=10.5, weight='600', mono=False)
    # reserved -> cancelled
    arrow(f, 145, 160, 316, 262, stroke='--paper')
    f.text(222, 228, t['cancel'], size=10.5, weight='600', anchor='end')
    f.text(222, 243, t['back'], size=10, anchor='end', fill='--phosphor')
    # paid -> used
    arrow(f, 450, 128, 566, 58, stroke='--paper')
    f.text(498, 82, t['use'], size=10.5, weight='600', anchor='end')
    # paid -> refunded
    arrow(f, 450, 152, 566, 222, stroke='--paper')
    f.text(500, 196, t['refund'], size=10.5, weight='600', anchor='end')
    f.text(500, 211, t['back'], size=10, anchor='end', fill='--phosphor')
    f.text(500, 226, t['guard'], size=10, anchor='end', fill='--amber')
    f.rect(560, 281, 22, 14, stroke='--paper-dim', fill='--panel', rx=3, width=1)
    f.rect(563, 284, 16, 8, stroke='--wire', fill='--panel', rx=2, width=1)
    f.text(590, 288, t['final'], size=10, anchor='start', fill='--paper-dim')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
