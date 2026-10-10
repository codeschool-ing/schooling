#!/usr/bin/env python3
"""The figures of lesson 1: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, box, figure, main  # noqa: E402


@figure('l01-plan-questions', 1)
def plan_questions(lang):
    t = {
        'en': dict(
            title='a test plan',
            qs=[('What, and what not?', 'scope'), ('Where could it hurt?', 'risks'),
                ('How?', 'approach'), ('Who, and with what?', 'people, environment'),
                ('When?', 'schedule'), ('When are we done?', 'exit criteria'),
                ('What makes us stop?', 'suspension criteria')],
            label='Seven boxes around the words a test plan. Each box holds a question and the part of '
                  'the plan that answers it: what and what not, scope; where could it hurt, risks; how, '
                  'approach; who and with what, people and environment; when, schedule; when are we '
                  'done, exit criteria; what makes us stop, suspension criteria.',
            cap='The seven questions inside a test plan, and the name each answer goes by. The risks box '
                'is drawn in another colour because the others follow from it.'),
        'pt': dict(
            title='um plano de teste',
            qs=[('O quê, e o que não?', 'escopo'), ('Onde pode doer?', 'riscos'),
                ('Como?', 'abordagem'), ('Quem, e com o quê?', 'pessoas, ambiente'),
                ('Quando?', 'cronograma'), ('Quando terminamos?', 'critérios de saída'),
                ('O que nos faz parar?', 'critérios de suspensão')],
            label='Sete caixas em volta das palavras um plano de teste. Cada caixa traz uma pergunta e a '
                  'parte do plano que a responde: o quê e o que não, escopo; onde pode doer, riscos; como, '
                  'abordagem; quem e com o quê, pessoas e ambiente; quando, cronograma; quando terminamos, '
                  'critérios de saída; o que nos faz parar, critérios de suspensão.',
            cap='As sete perguntas dentro de um plano de teste, e o nome que cada resposta recebe. A caixa '
                'dos riscos tem outra cor porque as outras decorrem dela.'),
    }[lang]
    f = Fig('l01-plan-questions', 700, 250, t['label'])
    box(f, 280, 105, 140, 40, [t['title']], stroke='--phosphor', fill='--scan', size=12)
    # the risks box sits beside the title, the other six around them
    place = [(20, 20), (20, 102), (250, 20), (480, 20), (480, 102), (20, 185), (250, 185)]
    for i, (q, a) in enumerate(t['qs']):
        x, y = place[i]
        risky = i == 1
        box(f, x, y, 200, 48, [q, a], stroke='--amber' if risky else '--wire',
            fills=['--paper', '--amber' if risky else '--phosphor'], weights=['600', None], size=10.5)
    return f, t['cap']


@figure('l01-risk-matrix', 1)
def risk_matrix(lang):
    t = {
        'en': dict(lv=['low', 'medium', 'high'], like='likelihood', imp='impact',
                   zones=['test first, deepest', 'test next', 'test last, lightest'],
                   names=['price', 'overselling', 'refunds', 'confirmation e-mail', 'phone layout'],
                   label='A three by three grid with likelihood up the side and impact along the bottom, '
                         'each low, medium and high. A, price, sits at high likelihood and high impact. B, '
                         'overselling, and C, refunds, sit at medium likelihood and high impact. D, '
                         'confirmation e-mail, sits at low likelihood and medium impact. E, phone layout, '
                         'sits at medium likelihood and low impact. The top right cells are marked test '
                         'first, the middle band test next, the bottom left test last.',
                   cap='The five risks of boxoffice on a likelihood and impact grid. The position of each '
                       'letter is a judgement; the order the grid puts them in is what the plan uses.'),
        'pt': dict(lv=['baixa', 'média', 'alta'], like='probabilidade', imp='impacto',
                   zones=['testar primeiro, mais fundo', 'testar em seguida', 'testar por último, mais leve'],
                   names=['preço', 'venda além da lotação', 'reembolsos', 'e-mail de confirmação',
                          'layout no celular'],
                   label='Uma grade de três por três com probabilidade subindo pela lateral e impacto ao '
                         'longo da base, cada um baixo, médio e alto. A, preço, fica em probabilidade alta e '
                         'impacto alto. B, venda além da lotação, e C, reembolsos, ficam em probabilidade '
                         'média e impacto alto. D, e-mail de confirmação, fica em probabilidade baixa e '
                         'impacto médio. E, layout no celular, fica em probabilidade média e impacto baixo. '
                         'As células do canto superior direito estão marcadas testar primeiro, a faixa do '
                         'meio testar em seguida, o canto inferior esquerdo testar por último.',
                   cap='Os cinco riscos do boxoffice numa grade de probabilidade e impacto. A posição de '
                       'cada letra é um julgamento; a ordem em que a grade as coloca é o que o plano usa.'),
    }[lang]
    if lang == 'pt':
        t['lvi'] = ['baixo', 'médio', 'alto']
    else:
        t['lvi'] = t['lv']
    f = Fig('l01-risk-matrix', 680, 330, t['label'])
    x0, y0, c = 120, 20, 82
    for row in range(3):            # row 0 is high likelihood
        for col in range(3):
            score = (3 - row) + (col + 1)
            stroke = '--amber' if score >= 5 else '--phosphor' if score == 4 else '--wire'
            fill = '--scan' if score >= 5 else '--panel'
            f.rect(x0 + col * c, y0 + row * c, c - 6, c - 6, stroke=stroke, fill=fill, rx=3)
    for k in range(3):
        f.text(x0 - 10, y0 + (2 - k) * c + c / 2 - 3, t['lv'][k], size=9.5, anchor='end',
               fill='--paper-dim')
        f.text(x0 + k * c + c / 2 - 3, y0 + 3 * c + 8, t['lvi'][k], size=9.5, fill='--paper-dim')
    f.text(x0 + 1.5 * c - 3, y0 + 3 * c + 28, t['imp'], size=10.5, weight='600')
    f.text(20, y0 + 1.5 * c - 52, t['like'], size=10.5, anchor='start', weight='600')
    spots = {'A': (2, 2, 0), 'B': (1, 2, -16), 'C': (1, 2, 16), 'D': (0, 1, 0), 'E': (1, 0, 0)}
    for letter, (li, ii, dx) in spots.items():
        cx = x0 + ii * c + (c - 6) / 2 + dx
        cy = y0 + (2 - li) * c + (c - 6) / 2
        f.circle(cx, cy, 12, fill='--panel', stroke='--paper', width=1.4)
        f.text(cx, cy, letter, size=10.5, weight='600', mono=True)
    lx = x0 + 3 * c + 30
    for k, name in enumerate(t['names']):
        y = 34 + k * 24
        f.text(lx, y, 'ABCDE'[k], size=10.5, anchor='start', weight='600', mono=True)
        f.text(lx + 18, y, name, size=10, anchor='start')
    for k, (z, col) in enumerate(zip(t['zones'], ['--amber', '--phosphor', '--paper-dim'])):
        y = 186 + k * 26
        f.rect(lx, y - 8, 14, 14, stroke=col, fill='--scan' if k == 0 else '--panel', rx=2)
        f.text(lx + 22, y - 1, z, size=10, anchor='start', fill=col if k < 2 else '--paper-dim')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
