#!/usr/bin/env python3
"""The figures of lesson 2: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, box, figure, main  # noqa: E402


@figure('l02-case-anatomy', 2)
def case_anatomy(lang):
    t = {
        'en': dict(
            rows=[('id', 'TC-BOOK-01', True), ('title', 'what the case checks, in one line', False),
                  ('requirement', 'R4, R5', True), ('precondition', 'the state before step 1', False),
                  ('test data', 'the values typed and chosen', False),
                  ('steps', 'one action each, numbered', False),
                  ('expected result', 'worked out from the requirement', False),
                  ('actual result', 'what really happened', False),
                  ('status', 'passed, failed, blocked, not run', False)],
            before=['written before the run,', 'with the application stopped'],
            during=['filled in when', 'the case runs'],
            label='A test case drawn as a form of nine rows. Seven are written before the run: id, '
                  'title, requirement, precondition, test data, steps and expected result, and of '
                  'those, precondition, steps and expected result are highlighted. Two are filled in '
                  'when the case runs: actual result and status.',
            cap='The fields of a test case. The three highlighted rows carry the weight; the last two '
                'stay empty until somebody runs it.'),
        'pt': dict(
            rows=[('id', 'TC-BOOK-01', True), ('título', 'o que o caso confere, numa linha', False),
                  ('requisito', 'R4, R5', True), ('pré-condição', 'o estado antes do passo 1', False),
                  ('dados de teste', 'os valores digitados e escolhidos', False),
                  ('passos', 'uma ação cada, numerados', False),
                  ('resultado esperado', 'deduzido do requisito', False),
                  ('resultado obtido', 'o que de fato aconteceu', False),
                  ('status', 'passou, falhou, bloqueado, não executado', False)],
            before=['escrito antes da execução,', 'com a aplicação parada'],
            during=['preenchido quando', 'o caso roda'],
            label='Um caso de teste desenhado como um formulário de nove linhas. Sete são escritas antes '
                  'da execução: id, título, requisito, pré-condição, dados de teste, passos e resultado '
                  'esperado, e dessas, pré-condição, passos e resultado esperado estão em destaque. Duas '
                  'são preenchidas quando o caso roda: resultado obtido e status.',
            cap='Os campos de um caso de teste. As três linhas em destaque carregam o peso; as duas '
                'últimas ficam vazias até alguém executar o caso.'),
    }[lang]
    f = Fig('l02-case-anatomy', 700, 326, t['label'])
    x, w, lw, h = 20, 480, 150, 26
    ys = []
    for i, (name, value, mono) in enumerate(t['rows']):
        y = 20 + i * (h + 4) + (14 if i >= 7 else 0)
        ys.append(y)
        key = i in (3, 5, 6)
        filled = i >= 7
        f.rect(x, y, w, h, stroke='--amber' if key else '--wire', fill='--scan' if key else '--panel',
               rx=3, dash='4 3' if filled else None)
        f.text(x + 12, y + h / 2, name, size=10.5, anchor='start', weight='600',
               fill='--amber' if key else '--paper')
        f.text(x + lw + 10, y + h / 2, value, size=10, anchor='start', mono=mono,
               fill='--paper-dim' if filled else '--paper')
    bx = x + w + 16

    def bracket(y0, y1, lines, colour):
        f.path(f'M{bx:.1f} {y0:.1f} L{bx + 8:.1f} {y0:.1f} L{bx + 8:.1f} {y1:.1f} L{bx:.1f} {y1:.1f}',
               stroke=colour, width=1.4)
        mid = (y0 + y1) / 2
        for k, line in enumerate(lines):
            f.text(bx + 18, mid + (k - (len(lines) - 1) / 2) * 14, line, size=10, anchor='start',
                   fill=colour)

    bracket(ys[0], ys[6] + h, t['before'], '--phosphor')
    bracket(ys[7], ys[8] + h, t['during'], '--paper-dim')
    return f, t['cap']


REQS = {
    'en': ['the shows list', 'sign-up', 'confirmation e-mail', 'booking', 'prices and discounts',
           'order states', 'error messages', 'phones and browsers', 'keyboard, screen reader'],
    'pt': ['a lista de espetáculos', 'cadastro', 'e-mail de confirmação', 'reserva',
           'preços e descontos', 'estados do pedido', 'mensagens de erro', 'celulares e navegadores',
           'teclado, leitor de tela'],
}
CASES = [('TC-SIGNUP-01', [2, 3]), ('TC-SIGNUP-02', [2, 7]), ('TC-CONFIRM-01', [3]),
         ('TC-CONFIRM-02', [3, 7]), ('TC-BOOK-01', [4, 5]), ('TC-BOOK-02', [4, 7]),
         ('TC-BOOK-03', [3, 4, 5])]


@figure('l02-trace', 2)
def trace(lang):
    t = {
        'en': dict(
            reqs='requirements', cases='cases', none='no case yet',
            label='A traceability matrix drawn as two columns joined by lines. On the left the nine '
                  'requirements R1 to R9, on the right the seven cases of this lesson. TC-SIGNUP-01 '
                  'joins R2 and R3; TC-SIGNUP-02 joins R2 and R7; TC-CONFIRM-01 joins R3; TC-CONFIRM-02 '
                  'joins R3 and R7; TC-BOOK-01 joins R4 and R5; TC-BOOK-02 joins R4 and R7; TC-BOOK-03 '
                  'joins R3, R4 and R5. R1, R6, R8 and R9 have no line and are drawn dashed.',
            cap='The traceability matrix of this lesson\'s cases. Read from the left it is coverage; '
                'read from the right, every case is evidence about a requirement. The dashed boxes are '
                'what nobody has tested yet.'),
        'pt': dict(
            reqs='requisitos', cases='casos', none='sem caso ainda',
            label='Uma matriz de rastreabilidade desenhada como duas colunas ligadas por linhas. À '
                  'esquerda os nove requisitos, de R1 a R9; à direita os sete casos desta aula. '
                  'TC-SIGNUP-01 liga R2 e R3; TC-SIGNUP-02 liga R2 e R7; TC-CONFIRM-01 liga R3; '
                  'TC-CONFIRM-02 liga R3 e R7; TC-BOOK-01 liga R4 e R5; TC-BOOK-02 liga R4 e R7; '
                  'TC-BOOK-03 liga R3, R4 e R5. R1, R6, R8 e R9 não têm linha e aparecem tracejados.',
            cap='A matriz de rastreabilidade dos casos desta aula. Lida da esquerda, é cobertura; lida '
                'da direita, todo caso é evidência sobre um requisito. As caixas tracejadas são o que '
                'ninguém testou ainda.'),
    }[lang]
    f = Fig('l02-trace', 700, 350, t['label'])
    lx, lw, rx, rw = 20, 250, 480, 150
    used = {r for _, rs in CASES for r in rs}
    ry = {r: 44 + (r - 1) * 32 for r in range(1, 10)}
    cy = {i: 60 + i * 38 for i in range(len(CASES))}
    f.text(lx, 22, t['reqs'], size=10.5, anchor='start', weight='600')
    f.text(rx, 22, t['cases'], size=10.5, anchor='start', weight='600')
    for i, (_, rs) in enumerate(CASES):
        for r in rs:
            y0, y1 = ry[r] + 12, cy[i] + 12
            f.path(f'M{lx + lw:.1f} {y0:.1f} C{lx + lw + 100:.1f} {y0:.1f} {rx - 100:.1f} {y1:.1f} '
                   f'{rx:.1f} {y1:.1f}', stroke='--phosphor-dim', width=1.4)
    for r in range(1, 10):
        on = r in used
        y = ry[r]
        f.rect(lx, y, lw, 24, stroke='--phosphor' if on else '--wire', fill='--panel', rx=3,
               dash=None if on else '4 3')
        f.text(lx + 10, y + 12, f'R{r}', size=10.5, anchor='start', weight='600', mono=True,
               fill='--paper' if on else '--paper-dim')
        f.text(lx + 42, y + 12, REQS[lang][r - 1], size=10, anchor='start',
               fill='--paper' if on else '--paper-dim')
    for i, (name, _) in enumerate(CASES):
        box(f, rx, cy[i], rw, 24, [name], stroke='--phosphor', fill='--scan', size=10.5, mono=True,
            rx=3)
    f.rect(rx, 334 - 12, 22, 12, stroke='--wire', fill='--panel', rx=2, dash='4 3')
    f.text(rx + 30, 334 - 6, t['none'], size=10, anchor='start', fill='--paper-dim')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
