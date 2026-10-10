#!/usr/bin/env python3
"""The figures of lesson 7: python3 figures.py redraws them in both languages.

The columns' edges are the ones Chromium 141 reported at a window 360 pixels wide (captures.sh,
block "widths"): Show 18-221, When 223-442, Price 444-565, Seats left 567-697, Book 699-774, and a
page 776 wide.
"""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, figure, main  # noqa: E402

COLS = [('Show', 18, 221), ('When', 223, 442), ('Price', 444, 565), ('Seats left', 567, 697),
        ('', 699, 774)]
ROWS = [['The Seagull', '2026-10-10 20:00', 'R$ 60,00', '120', 'Book'],
        ['Hamlet', '2026-10-17 20:00', 'R$ 80,00', '80', 'Book']]


@figure('l07-narrow-screen', 7)
def narrow_screen(lang):
    t = {
        'en': dict(window='the window: 360', page='the page: 776', off='off the screen',
                   off2='a sideways scroll away',
                   label='The home page of boxoffice drawn to scale at a window 360 pixels wide. The page '
                         'is 776 pixels wide. Inside the window are the heading Shows and the first two '
                         'columns of the table, Show and When. The columns Price, Seats left and the Book '
                         'links lie outside the window, to the right, a sideways scroll away.',
                   cap='The home page at 360 pixels, drawn to the widths Chromium measured. The window shows '
                       'the name and the date; the price, the seats and the Book link are on the part of '
                       'the page outside it.'),
        'pt': dict(window='a janela: 360', page='a página: 776', off='fora da tela',
                   off2='a uma rolagem para o lado',
                   label='A página inicial do boxoffice desenhada em escala numa janela de 360 pixels de '
                         'largura. A página tem 776 pixels de largura. Dentro da janela ficam o título Shows '
                         'e as duas primeiras colunas da tabela, Show e When. As colunas Price, Seats left e '
                         'os links Book ficam fora da janela, à direita, a uma rolagem para o lado.',
                   cap='A página inicial a 360 pixels, desenhada nas larguras que o Chromium mediu. A janela '
                       'mostra o nome e a data; o preço, os lugares e o link Book ficam na parte da página '
                       'fora dela.'),
    }[lang]
    f = Fig('l07-narrow-screen', 700, 250, t['label'])
    s, x0 = 0.8, 30

    def X(c):
        return x0 + c * s

    top, bottom = 34, 168
    # the whole page, dashed, and the window over its left part
    f.rect(X(0), top, 776 * s, bottom - top, stroke='--wire', fill='--ink', dash='4 3', rx=2)
    f.rect(X(360), top + 1, (776 - 360) * s - 1, bottom - top - 2, stroke='--ink', fill='--scan', rx=0,
           width=0)
    f.rect(X(0) - 6, top - 14, 360 * s + 12, bottom - top + 28, stroke='--phosphor', fill='--panel',
           width=2.2, rx=14)
    f.text(X(16), top + 18, 'Shows', size=13, anchor='start', weight='700', mono=True)
    for j, (name, a, b) in enumerate(COLS):
        y = top + 44
        f.text(X(a) + 4, y, name, size=9, anchor='start', weight='600', mono=True,
               fill='--paper' if b <= 360 else '--paper-dim')
        for i, row in enumerate(ROWS):
            yy = y + 20 * (i + 1)
            inside = b <= 360
            f.text(X(a) + 4, yy, row[j], size=9, anchor='start', mono=True,
                   fill=('--phosphor' if j == 4 else '--paper') if inside else
                   ('--amber' if j == 4 else '--paper-dim'))
    f.text(X(16), top + 112, 'Shows · Sign up · Outbox', size=9, anchor='start', mono=True,
           fill='--phosphor')
    f.text(X(568), top + 112, t['off'], size=11, weight='600', fill='--amber')
    f.text(X(568), top + 127, t['off2'], size=9.5, fill='--amber')
    # dimension lines
    for y, a, b, lab, col in ((bottom + 40, 0, 360, t['window'], '--phosphor'),
                              (bottom + 66, 0, 776, t['page'], '--paper-dim')):
        f.line(X(a), y, X(b), y, stroke=col, width=1.2)
        f.line(X(a), y - 5, X(a), y + 5, stroke=col, width=1.2)
        f.line(X(b), y - 5, X(b), y + 5, stroke=col, width=1.2)
        f.text((X(a) + X(b)) / 2, y - 9, lab, size=10, fill=col)
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
