#!/usr/bin/env python3
"""The figures of lesson 20: python3 figures.py redraws them in both languages."""
import hashlib
import hmac
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


def pseudonym(key, email):
    """The same computation as pseudonymise.py in section `anonymising`."""
    digest = hmac.new(key.encode(), email.lower().encode(), hashlib.sha256).hexdigest()
    return f"user-{digest[:12]}@example.org"


def mask(name):
    return " ".join(word[0] + "*" * (len(word) - 1) for word in name.split())


@figure('l20-join', 20)
def join(lang):
    email, name = 'test002@example.org', 'Débora Barbosa'
    code, other = pseudonym('vila-test-key', email), pseudonym('another-key', email)
    t = {
        'en': dict(prod='the original', copy='the test copy', acc='accounts', ord='orders',
                   hash=['keyed hash', 'the key stays with', 'the data\'s owner'],
                   same='same code in both: the tables still join',
                   other='with another key, the same address becomes',
                   label=f'On the left, the original: an accounts row for {name}, {email}, and an orders row, '
                         f'order 1003 for Hamlet, with the same address. Both pass through a keyed hash whose '
                         f'key stays with the data\'s owner. On the right, the test copy: the name masked as '
                         f'{mask(name)}, and the address replaced by {code} in both tables, so they still '
                         f'join. Underneath, the same address with another key becomes {other}.',
                   cap='Pseudonymising each table separately keeps the join, because the same address and the '
                       'same key give the same code. A different key gives a different code, which is why the '
                       'key is never sent with the copy.'),
        'pt': dict(prod='o original', copy='a cópia de teste', acc='contas', ord='pedidos',
                   hash=['hash com chave', 'a chave fica com', 'o dono dos dados'],
                   same='mesmo código nas duas: as tabelas ainda se ligam',
                   other='com outra chave, o mesmo endereço vira',
                   label=f'À esquerda, o original: uma linha de contas para {name}, {email}, e uma linha de '
                         f'pedidos, pedido 1003 para Hamlet, com o mesmo endereço. As duas passam por um hash com '
                         f'chave, e a chave fica com o dono dos dados. À direita, a cópia de teste: o nome '
                         f'mascarado como {mask(name)}, e o endereço trocado por {code} nas duas tabelas, que '
                         f'ainda se ligam. Embaixo, o mesmo endereço com outra chave vira {other}.',
                   cap='Pseudonimizar cada tabela separadamente mantém a ligação, porque o mesmo endereço e a '
                       'mesma chave dão o mesmo código. Outra chave dá outro código, e é por isso que a chave '
                       'nunca vai junto com a cópia.'),
    }[lang]
    f = Fig('l20-join', 720, 262, t['label'])
    M = 9.5

    def row(x, y, cells):
        cx = x
        for w, s, colour in cells:
            f.rect(cx, y, w, 26, stroke='--wire', fill='--panel', rx=2)
            f.text(cx + 8, y + 13, s, size=M, anchor='start', mono=True, fill=colour)
            cx += w

    f.text(10, 16, t['prod'], size=11, anchor='start', weight='600')
    f.text(440, 16, t['copy'], size=11, anchor='start', weight='600')
    for x in (10, 440):
        f.text(x, 42, t['acc'], size=10, anchor='start', fill='--paper-dim')
        f.text(x, 118, t['ord'], size=10, anchor='start', fill='--paper-dim')
    row(10, 52, [(92, name, '--paper'), (136, email, '--paper')])
    row(10, 128, [(40, '1003', '--paper'), (136, email, '--paper'), (52, 'Hamlet', '--paper')])
    row(440, 52, [(92, mask(name), '--paper'), (180, code, '--phosphor')])
    row(440, 128, [(40, '1003', '--paper'), (180, code, '--phosphor'), (52, 'Hamlet', '--paper')])
    box(f, 285, 72, 128, 64, t['hash'], stroke='--amber', fill='--scan',
        fills=['--paper', '--paper-dim', '--paper-dim'], weights=['600', None, None], size=10, lh=15)
    arrow(f, 238, 65, 282, 92)
    arrow(f, 238, 141, 282, 118)
    arrow(f, 416, 92, 437, 66)
    arrow(f, 416, 118, 437, 140)
    f.line(600, 79, 600, 127, stroke='--phosphor', width=1.4, dash='3 3')
    f.text(716, 174, t['same'], size=10, anchor='end', fill='--phosphor')
    f.line(10, 200, 710, 200, stroke='--wire', width=1, dash='4 3')
    f.text(10, 222, t['other'], size=10, anchor='start', fill='--paper-dim')
    f.text(10, 242, other, size=M, anchor='start', mono=True, fill='--amber')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
