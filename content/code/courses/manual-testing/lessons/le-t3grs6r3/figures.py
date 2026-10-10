#!/usr/bin/env python3
"""The figures of lesson 9: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, figure, main  # noqa: E402


@figure('l09-depth-breadth', 9)
def depth_breadth(lang):
    t = {
        'en': dict(
            x='breadth: how much of the application', y='depth: how hard each part is pressed',
            smoke='smoke', smoke2='does the build come up at all?',
            reg='regression', reg2='does what worked before still work?',
            san='sanity', san2='did this change work?', change='the change',
            label='Two axes, breadth along the bottom and depth up the side. Smoke is a thin band '
                  'across the whole width at the bottom: everything, lightly. Regression is a wide '
                  'block of middle height over the same width. Sanity is a narrow, tall column '
                  'standing on the place where the change was made.',
            cap='Three checks on one new build. Smoke and regression cover the whole application at '
                'different depths; sanity covers one change and its neighbours, more deeply than '
                'either.'),
        'pt': dict(
            x='abrangência: quanto da aplicação', y='profundidade: quanto se pressiona cada parte',
            smoke='fumaça', smoke2='a versão ao menos sobe?',
            reg='regressão', reg2='o que funcionava ainda funciona?',
            san='sanidade', san2='essa mudança funcionou?', change='a mudança',
            label='Dois eixos, abrangência na base e profundidade na lateral. A fumaça é uma faixa '
                  'fina por toda a largura, embaixo: tudo, de leve. A regressão é um bloco largo de '
                  'altura média sobre a mesma largura. A sanidade é uma coluna estreita e alta, em pé '
                  'sobre o lugar onde a mudança foi feita.',
            cap='Três verificações sobre uma mesma versão nova. Fumaça e regressão cobrem a aplicação '
                'inteira em profundidades diferentes; a sanidade cobre uma mudança e seus vizinhos, '
                'mais fundo que as duas.'),
    }[lang]
    f = Fig('l09-depth-breadth', 700, 300, t['label'])
    x0, x1, top, base = 90, 650, 40, 240
    f.line(x0, base, x1, base, stroke='--paper-dim', width=1.2)
    f.line(x0, base, x0, top - 6, stroke='--paper-dim', width=1.2)
    f.text(x0, top - 18, t['y'], size=10, anchor='start', weight='600')
    f.text((x0 + x1) / 2, base + 40, t['x'], size=10, weight='600')
    # regression: wide, middle depth
    f.rect(100, 125, 540, base - 125, stroke='--phosphor', fill='--panel', rx=3)
    f.text(112, 142, t['reg'], size=10.5, anchor='start', weight='600', fill='--phosphor')
    f.text(112, 158, t['reg2'], size=10, anchor='start')
    # smoke: wide, shallow, drawn over the bottom of regression
    f.rect(100, 206, 540, base - 206, stroke='--wire', fill='--scan', rx=3)
    f.text(112, 223, t['smoke'], size=10.5, anchor='start', weight='600')
    f.text(170, 223, t['smoke2'], size=10, anchor='start', fill='--paper-dim')
    # sanity: narrow, deep, on the change
    sx, sw = 440, 50
    f.rect(sx, 52, sw, base - 52, stroke='--amber', fill='--scan', rx=3, width=1.6)
    f.text(sx + sw + 12, 66, t['san'], size=10.5, anchor='start', weight='600', fill='--amber')
    f.text(sx + sw + 12, 82, t['san2'], size=10, anchor='start')
    arrow(f, sx + sw / 2, base + 20, sx + sw / 2, base + 3, stroke='--amber')
    f.text(sx + sw / 2 + 8, base + 20, t['change'], size=9.5, anchor='start', fill='--amber')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
