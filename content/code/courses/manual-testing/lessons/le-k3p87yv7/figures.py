#!/usr/bin/env python3
"""The figures of lesson 12: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


@figure('l12-signoff-loop', 12)
def signoff_loop(lang):
    t = {
        'en': dict(
            uat=('UAT session', 'the client drives'), decide=('the client decides', 'and signs, or not'),
            live=('goes live', 'with its conditions'), fix=('Rui fixes it', 'a new build, 1.2'),
            check=('sanity, then regression', 'lessons 9 and 10'),
            change=('change request', 'own criteria, a later release'),
            accept='accept', reject='reject', back='rerun the failed', back2='criteria',
            label='A loop of boxes. UAT session, the client drives, leads to the client decides, and '
                  'signs, or not. Accept leads right to goes live, with its conditions. Reject leads '
                  'down to Rui fixes it, a new build, 1.2, then left to sanity, then regression, '
                  'lessons 9 and 10, then back up to the UAT session to rerun the failed criteria. A '
                  'dashed arrow from the decision leads to a separate box, change request, own '
                  'criteria, a later release.',
            cap='What follows a rejected release. The fix goes round the loop and returns to the '
                'client; a change request leaves it and starts its own.'),
        'pt': dict(
            uat=('sessão de UAT', 'o cliente conduz'), decide=('o cliente decide', 'e assina, ou não'),
            live=('vai ao ar', 'com suas condições'), fix=('Rui corrige', 'uma nova build, 1.2'),
            check=('sanidade, depois regressão', 'aulas 9 e 10'),
            change=('pedido de mudança', 'critérios próprios, outra versão'),
            accept='aceita', reject='rejeita', back='refaz os critérios', back2='que falharam',
            label='Um ciclo de caixas. Sessão de UAT, o cliente conduz, leva a o cliente decide, e '
                  'assina, ou não. Aceita leva à direita para vai ao ar, com suas condições. Rejeita '
                  'leva para baixo a Rui corrige, uma nova build, 1.2, depois à esquerda a sanidade, '
                  'depois regressão, aulas 9 e 10, e de volta para cima à sessão de UAT, para refazer '
                  'os critérios que falharam. Uma seta tracejada sai da decisão para uma caixa à '
                  'parte, pedido de mudança, critérios próprios, outra versão.',
            cap='O que vem depois de uma versão rejeitada. A correção dá a volta no ciclo e retorna '
                'ao cliente; um pedido de mudança sai dele e começa o seu.'),
    }[lang]
    f = Fig('l12-signoff-loop', 700, 250, t['label'])
    w, h, top, bot = 170, 52, 30, 168
    xa, xb, xc = 20, 265, 510
    fills = ['--paper', '--paper-dim']
    box(f, xa, top, w, h, list(t['uat']), stroke='--phosphor', fills=fills, weights=['600', None])
    box(f, xb, top, w, h, list(t['decide']), stroke='--amber', fill='--scan', fills=fills,
        weights=['600', None])
    box(f, xc, top, w, h, list(t['live']), fills=fills, weights=['600', None])
    box(f, xb, bot, w, h, list(t['fix']), fills=fills, weights=['600', None])
    box(f, xa, bot, w, h, list(t['check']), fills=fills, weights=['600', None])
    box(f, xc, bot, w, h, list(t['change']), dash='4 3', fills=fills, weights=['600', None])
    mid = top + h / 2
    arrow(f, xa + w + 2, mid, xb - 3, mid)
    arrow(f, xb + w + 2, mid, xc - 3, mid, stroke='--phosphor')
    f.text((xb + w + xc) / 2, mid - 11, t['accept'], size=10, fill='--phosphor')
    arrow(f, xb + w / 2, top + h + 2, xb + w / 2, bot - 3, stroke='--amber')
    f.text(xb + w / 2 + 8, (top + h + bot) / 2, t['reject'], size=10, anchor='start', fill='--amber')
    arrow(f, xb - 2, bot + h / 2, xa + w + 3, bot + h / 2)
    arrow(f, xa + w / 2, bot - 2, xa + w / 2, top + h + 3, stroke='--phosphor')
    f.text(xa + w / 2 + 8, (top + h + bot) / 2 - 7, t['back'], size=9.5, anchor='start',
           fill='--phosphor')
    f.text(xa + w / 2 + 8, (top + h + bot) / 2 + 7, t['back2'], size=9.5, anchor='start',
           fill='--phosphor')
    arrow(f, xb + w - 10, top + h + 2, xc + 20, bot - 3, dash='4 3')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
