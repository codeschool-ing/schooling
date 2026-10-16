#!/usr/bin/env python3
"""The figures of lesson 3: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, figure, main  # noqa: E402


@figure('l03-questions', 3)
def questions(lang):
    t = {
        'en': dict(
            head='TC-BOOK-04, first draft',
            rows=[('title', ['Booking works'], []),
                  ('precondition', ['Logged in as a member'], [1, 2, 8]),
                  ('steps', ['Book some tickets for a show', 'and check the total.'], [3, 4, 5]),
                  ('expected', ['Booking successful and', 'the price is correct.'], [6, 7])],
            qhead='what the stranger has to ask',
            qs=['Log in where? There is no log-in page.', 'Which member account?', 'Which show?',
                'How many is some?', 'Is Student ticked or not?', 'Which total is correct?',
                'What does successful look like?', 'Starting from what state?'],
            label='A first draft of a test case with four rows. Title: Booking works. Precondition: '
                  'logged in as a member. Steps: book some tickets for a show and check the total. '
                  'Expected: booking successful and the price is correct. Numbered markers beside the '
                  'rows point to eight questions a stranger has to ask. Beside the precondition: 1, log '
                  'in where, there is no log-in page; 2, which member account; 8, starting from what '
                  'state. Beside the steps: 3, which show; 4, how many is some; 5, is Student ticked '
                  'or not. Beside the expected result: 6, which total is correct; 7, what does '
                  'successful look like.',
            cap='Ana\'s first draft, read by somebody who has never seen boxoffice. Four lines raise '
                'eight questions, and the expected result raises the two that decide the verdict.'),
        'pt': dict(
            head='TC-BOOK-04, primeiro rascunho',
            rows=[('título', ['A reserva funciona'], []),
                  ('pré-condição', ['Logado como membro'], [1, 2, 8]),
                  ('passos', ['Reservar alguns ingressos para', 'um espetáculo e conferir o total.'],
                   [3, 4, 5]),
                  ('esperado', ['Reserva bem-sucedida e', 'o preço está correto.'], [6, 7])],
            qhead='o que o estranho precisa perguntar',
            qs=['Logar onde? Não há página de login.', 'Qual conta de membro?', 'Qual espetáculo?',
                'Quantos são alguns?', 'Estudante marcado ou não?', 'Qual total é o correto?',
                'Como é bem-sucedida?', 'A partir de que estado?'],
            label='Um primeiro rascunho de caso de teste com quatro linhas. Título: a reserva funciona. '
                  'Pré-condição: logado como membro. Passos: reservar alguns ingressos para um '
                  'espetáculo e conferir o total. Esperado: reserva bem-sucedida e o preço está correto. '
                  'Marcadores numerados ao lado das linhas apontam oito perguntas que um estranho '
                  'precisa fazer. Ao lado da pré-condição: 1, logar onde, não há página de login; 2, '
                  'qual conta de membro; 8, a partir de que estado. Ao lado dos passos: 3, qual '
                  'espetáculo; 4, quantos são alguns; 5, estudante marcado ou não. Ao lado do '
                  'resultado esperado: 6, qual total é o correto; 7, como é bem-sucedida.',
            cap='O primeiro rascunho da Ana, lido por alguém que nunca viu o boxoffice. Quatro linhas '
                'levantam oito perguntas, e o resultado esperado levanta as duas que decidem o '
                'veredito.'),
    }[lang]
    f = Fig('l03-questions', 720, 300, t['label'])
    x, w, lw = 20, 340, 104
    f.text(x, 22, t['head'], size=10.5, anchor='start', weight='600')
    y = 38
    for name, lines, marks in t['rows']:
        h = 26 + 15 * (len(lines) - 1)
        expected = name in ('expected', 'esperado')
        f.rect(x, y, w, h, stroke='--amber' if expected else '--wire', fill='--panel', rx=3)
        f.text(x + 10, y + h / 2, name, size=10.5, anchor='start', weight='600',
               fill='--paper-dim')
        for k, line in enumerate(lines):
            f.text(x + lw, y + h / 2 + (k - (len(lines) - 1) / 2) * 15, line, size=10.5,
                   anchor='start')
        for k, m in enumerate(marks):
            cx = x + w + 18 + k * 24
            f.circle(cx, y + h / 2, 10, fill='--scan', stroke='--amber', width=1.3)
            f.text(cx, y + h / 2, str(m), size=10, weight='600', mono=True, fill='--amber')
        y += h + 10
    qx = 456
    f.text(qx, 22, t['qhead'], size=10.5, anchor='start', weight='600')
    for i, q in enumerate(t['qs']):
        qy = 52 + i * 30
        f.circle(qx + 10, qy, 10, fill='--scan', stroke='--amber', width=1.3)
        f.text(qx + 10, qy, str(i + 1), size=10, weight='600', mono=True, fill='--amber')
        f.text(qx + 28, qy, q, size=10, anchor='start')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
