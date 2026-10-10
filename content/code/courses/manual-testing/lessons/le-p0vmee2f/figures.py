#!/usr/bin/env python3
"""The figures of lesson 13: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


@figure('l13-reach', 13)
def reach(lang):
    t = {
        'en': dict(
            pieces=[('browser', None), ('HTTP server', None), ('book', 'reads the form'),
                    ('discount', 'the percentage'), ('order page', None)],
            unit='unit test', integ='integration test', system='system test',
            person='a person in a browser',
            label='Five boxes in a row, in the order a booking travels: browser, HTTP server, book, '
                  'which reads the form, discount, which gives the percentage, and the order page. '
                  'Below them three brackets. The unit test, test_discount.py, covers discount alone. '
                  'The integration test, test_booking.py, covers everything from the HTTP server to '
                  'the order page. The system test, a person in a browser, covers all five.',
            cap='What each layer of test reaches in boxoffice. The lower the layer, the less it '
                'crosses, the faster it runs and the more exactly a failure points at its cause.'),
        'pt': dict(
            pieces=[('navegador', None), ('servidor HTTP', None), ('book', 'lê o formulário'),
                    ('discount', 'a porcentagem'), ('página do pedido', None)],
            unit='teste de unidade', integ='teste de integração', system='teste de sistema',
            person='uma pessoa num navegador',
            label='Cinco caixas em fila, na ordem em que uma reserva passa: navegador, servidor HTTP, '
                  'book, que lê o formulário, discount, que dá a porcentagem, e a página do pedido. '
                  'Abaixo, três chaves. O teste de unidade, test_discount.py, cobre só discount. O '
                  'teste de integração, test_booking.py, cobre tudo do servidor HTTP até a página do '
                  'pedido. O teste de sistema, uma pessoa num navegador, cobre as cinco.',
            cap='O que cada camada de teste alcança no boxoffice. Quanto mais baixa a camada, menos '
                'ela atravessa, mais rápido roda e mais exatamente uma falha aponta a causa.'),
    }[lang]
    f = Fig('l13-reach', 700, 250, t['label'])
    w, gap, x0, y0, h = 116, 22, 20, 24, 56
    xs = [x0 + i * (w + gap) for i in range(5)]
    for i, (name, sub) in enumerate(t['pieces']):
        code = name in ('book', 'discount')
        stroke = '--amber' if name == 'discount' else '--wire'
        if sub:
            f.rect(xs[i], y0, w, h, stroke=stroke, fill='--panel')
            f.text(xs[i] + w / 2, y0 + 20, name, size=11, mono=code, weight='600')
            f.text(xs[i] + w / 2, y0 + 38, sub, size=9.5, fill='--paper-dim')
        else:
            box(f, xs[i], y0, w, h, [name], stroke=stroke, size=11, weights=['600'])
        if i < 4:
            arrow(f, xs[i] + w + 2, y0 + h / 2, xs[i + 1] - 3, y0 + h / 2)

    def bracket(a, b, y, colour, name, what):
        left, right = xs[a] + 4, xs[b] + w - 4
        f.path(f'M{left:.1f} {y - 10:.1f} L{left:.1f} {y:.1f} L{right:.1f} {y:.1f} '
               f'L{right:.1f} {y - 10:.1f}', stroke=colour, width=1.6)
        mid = (left + right) / 2
        f.text(mid, y + 14, name, size=10.5, weight='600', fill=colour)
        f.text(mid, y + 29, what, size=9.5, mono=what.endswith('.py'), fill='--paper-dim')

    bracket(3, 3, 104, '--amber', t['unit'], 'test_discount.py')
    bracket(1, 4, 156, '--phosphor', t['integ'], 'test_booking.py')
    bracket(0, 4, 208, '--paper', t['system'], t['person'])
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
