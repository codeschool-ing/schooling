#!/usr/bin/env python3
"""The figures of lesson 11: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, arrow, box, figure, main  # noqa: E402


@figure('l11-session-loop', 11)
def session_loop(lang):
    t = {
        'en': dict(
            charter=['charter', 'a mission, written first'],
            session=['session', '60 to 120 minutes, notes kept'],
            debrief=['debrief', 'PROOF, 10 to 15 minutes'],
            outs=['defect reports', 'regression cases', 'new charters'],
            back='the next session',
            label='A loop of three boxes, left to right: a charter, written first; a session of 60 to 120 '
                  'minutes with notes kept; a debrief using PROOF. The debrief points to three outputs: '
                  'defect reports, regression cases and new charters. An arrow runs from new charters '
                  'back to the charter box, labelled the next session.',
            cap='Session-based test management. Each session has one charter, and its debrief turns the '
                'notes into reports, cases and the charters of the sessions after it.'),
        'pt': dict(
            charter=['missão', 'escrita antes'],
            session=['sessão', '60 a 120 minutos, com notas'],
            debrief=['conversa final', 'PROOF, 10 a 15 minutos'],
            outs=['relatórios de defeito', 'casos de regressão', 'novas missões'],
            back='a próxima sessão',
            label='Um ciclo de três caixas, da esquerda para a direita: uma missão, escrita antes; uma '
                  'sessão de 60 a 120 minutos com notas; uma conversa final usando PROOF. A conversa final '
                  'aponta para três saídas: relatórios de defeito, casos de regressão e novas missões. Uma '
                  'seta vai de novas missões de volta à caixa da missão, com o rótulo a próxima sessão.',
            cap='Gestão de teste baseada em sessões. Cada sessão tem uma missão, e a conversa final '
                'transforma as notas em relatórios, casos e as missões das sessões seguintes.'),
    }[lang]
    f = Fig('l11-session-loop', 700, 240, t['label'])
    y, h = 82, 58
    box(f, 20, y, 140, h, t['charter'], stroke='--phosphor', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10.5)
    box(f, 200, y, 180, h, t['session'], stroke='--wire', fill='--scan', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10.5)
    box(f, 404, y, 140, h, t['debrief'], stroke='--amber', fills=['--paper', '--paper-dim'],
        weights=['600', None], size=10.5)
    arrow(f, 160, y + h / 2, 198, y + h / 2)
    arrow(f, 380, y + h / 2, 402, y + h / 2)
    for k, o in enumerate(t['outs']):
        oy = 22 + k * 64
        box(f, 574, oy, 118, 40, [o], stroke='--phosphor' if k == 2 else '--wire', size=9.5)
        arrow(f, 544, y + h / 2, 572, oy + 20)
    f.path('M633 190 L633 218 L90 218 L90 142', stroke='--phosphor', width=1.4, arrow=True)
    f.text(365, 208, t['back'], size=10, fill='--phosphor')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
