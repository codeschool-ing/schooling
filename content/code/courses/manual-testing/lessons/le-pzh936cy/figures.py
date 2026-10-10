#!/usr/bin/env python3
"""The figures of lesson 15: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, figure, main  # noqa: E402


@figure('l15-severity-priority', 15)
def severity_priority(lang):
    t = {
        'en': dict(
            sev=['trivial', 'minor', 'major', 'critical'],
            pri=['P1', 'P2', 'P3'],
            pri_note=['next build', 'this release', 'when convenient'],
            xl='severity: how much harm', yl='priority: how soon',
            names=['student discount ignored', 'a used order refunded', 'traceback on a word',
                   'shows table 760 px wide', '"cannot be useed"'],
            label='A grid with severity along the bottom, trivial, minor, major and critical, and '
                  'priority up the side, P3 at the bottom to P1 at the top. A, the student discount '
                  'ignored, and B, a used order refunded, sit at critical and P1. C, the traceback on '
                  'a word, sits at major and P2. D, the shows table 760 pixels wide, sits at minor and '
                  'P1. E, cannot be useed, sits at trivial and P3.',
            cap='Five defects of boxoffice 1.1, rated twice. The tester measures the column; the '
                'triage decides the row. D is the one that surprises: minor, and first in line.'),
        'pt': dict(
            sev=['trivial', 'menor', 'maior', 'crítica'],
            pri=['P1', 'P2', 'P3'],
            pri_note=['próximo build', 'nesta versão', 'quando der'],
            xl='severidade: quanto estrago', yl='prioridade: quando',
            names=['desconto de estudante ignorado', 'pedido usado reembolsado', 'traceback com uma palavra',
                   'tabela com 760 px de largura', '"cannot be useed"'],
            label='Uma grade com a severidade ao longo da base, trivial, menor, maior e crítica, e a '
                  'prioridade subindo pela lateral, P3 embaixo até P1 no alto. A, o desconto de '
                  'estudante ignorado, e B, o pedido usado reembolsado, ficam em crítica e P1. C, o '
                  'traceback com uma palavra, fica em maior e P2. D, a tabela de espetáculos com 760 '
                  'pixels de largura, fica em menor e P1. E, cannot be useed, fica em trivial e P3.',
            cap='Cinco defeitos do boxoffice 1.1, avaliados duas vezes. Quem testa mede a coluna; a '
                'triagem decide a linha. D é o que surpreende: menor, e primeiro da fila.'),
    }[lang]
    f = Fig('l15-severity-priority', 700, 300, t['label'])
    x0, y0, cw, ch = 110, 24, 92, 66
    for row in range(3):
        for col in range(4):
            hot = row == 0
            f.rect(x0 + col * cw, y0 + row * ch, cw - 6, ch - 6,
                   stroke='--amber' if hot and col >= 2 else '--wire',
                   fill='--scan' if hot else '--panel', rx=3)
    for r in range(3):
        y = y0 + r * ch + (ch - 6) / 2
        f.text(x0 - 12, y - 7, t['pri'][r], size=11, anchor='end', weight='600', mono=True)
        f.text(x0 - 12, y + 8, t['pri_note'][r], size=9, anchor='end', fill='--paper-dim')
    for c in range(4):
        f.text(x0 + c * cw + (cw - 6) / 2, y0 + 3 * ch + 8, t['sev'][c], size=10, fill='--paper-dim')
    f.text(x0 + 2 * cw - 3, y0 + 3 * ch + 30, t['xl'], size=10.5, weight='600')
    f.text(14, 12, t['yl'], size=10.5, anchor='start', weight='600')
    # letter: (row, col, dx)
    spots = {'A': (0, 3, -16), 'B': (0, 3, 16), 'C': (1, 2, 0), 'D': (0, 1, 0), 'E': (2, 0, 0)}
    for letter, (r, c, dx) in spots.items():
        cx = x0 + c * cw + (cw - 6) / 2 + dx
        cy = y0 + r * ch + (ch - 6) / 2
        stroke = '--amber' if letter == 'D' else '--paper'
        f.circle(cx, cy, 12, fill='--panel', stroke=stroke, width=1.4)
        f.text(cx, cy, letter, size=10.5, weight='600', mono=True)
    lx = x0 + 4 * cw + 24
    for k, name in enumerate(t['names']):
        y = 40 + k * 26
        f.text(lx, y, 'ABCDE'[k], size=10.5, anchor='start', weight='600', mono=True,
               fill='--amber' if k == 3 else '--paper')
        f.text(lx + 18, y, name, size=10, anchor='start')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
