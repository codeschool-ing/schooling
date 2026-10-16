"""Lesson 13: test-driven development."""
from figures import Fig, T, figure


@figure('l13-cycle', 13)
def cycle():
    f = Fig('l13-cycle', 720, 330, T(
        'The red-green-refactor cycle as three boxes joined by arrows in a loop. Red: write one test '
        'for the next behaviour and run it; it must fail, for the reason you expect. An arrow labelled '
        '"one test fails" leads to green: write the least code that passes; a constant or a copied '
        'line is allowed. An arrow labelled "every test passes" leads to refactor: improve names and '
        'structure, add no behaviour, run the tests after every move. An arrow labelled "next line of '
        'the list" leads back to red. In the middle: one turn takes a minute or two.',
        'O ciclo vermelho-verde-refatorar como três caixas ligadas por setas em laço. Vermelho: '
        'escreva um teste para o próximo comportamento e rode; ele precisa falhar, pelo motivo que '
        'você espera. Uma seta com o rótulo "um teste falha" leva ao verde: escreva o mínimo de '
        'código que passa; uma constante ou uma linha copiada é permitida. Uma seta com o rótulo '
        '"todos os testes passam" leva a refatorar: melhore nomes e estrutura, não acrescente '
        'comportamento, rode os testes depois de cada movimento. Uma seta com o rótulo "próxima '
        'linha da lista" volta ao vermelho. No meio: uma volta leva um ou dois minutos.'))

    def step(cx, cy, stroke, head, rows):
        w, h = 272, 92
        f.rect(cx - w / 2, cy - h / 2, w, h, stroke=stroke, width=2, rx=6)
        f.text(cx, cy - 26, head, size=13, weight='600')
        f.lines(cx, cy + 12, rows, size=10, gap=15)

    step(150, 70, '--amber', T('red', 'vermelho'),
         [T('write one test for the next behaviour', 'escreva um teste para o próximo comportamento'),
          T('run it: it fails, for the reason expected', 'rode: ele falha, pelo motivo esperado')])
    step(570, 70, '--phosphor', T('green', 'verde'),
         [T('write the least code that passes', 'escreva o mínimo de código que passa'),
          T('a constant or a copied line is allowed', 'vale uma constante ou uma linha copiada')])
    step(360, 262, '--scan', T('refactor', 'refatorar'),
         [T('improve names and structure, no new behaviour', 'melhore nomes e estrutura, sem comportamento novo'),
          T('run the tests after every move', 'rode os testes depois de cada movimento')])
    # red -> green
    f.arrow([(289, 70), (431, 70)], stroke='--paper-dim', width=1.4)
    f.text(360, 58, T('one test fails', 'um teste falha'), size=10, fill='--paper-dim', italic=True)
    # green -> refactor
    f.arrow([(570, 118), (570, 262), (499, 262)], stroke='--paper-dim', width=1.4)
    f.text(578, 190, T('every test passes', 'todos os testes passam'), size=10, fill='--paper-dim',
           italic=True, anchor='start')
    # refactor -> red
    f.arrow([(221, 262), (150, 262), (150, 118)], stroke='--paper-dim', width=1.4)
    f.text(142, 190, T('next line of the list', 'próxima linha da lista'), size=10, fill='--paper-dim',
           italic=True, anchor='end')
    f.text(360, 160, T('one turn: a minute or two', 'uma volta: um ou dois minutos'), size=11,
           fill='--amber', italic=True)
    return f, T('The loop never changes order. Only the green step may be sloppy, and only the refactor step may change structure.',
                'O laço nunca muda de ordem. Só o passo verde pode ser desleixado, e só o passo de refatorar pode mudar a estrutura.')


@figure('l13-steps', 13)
def steps():
    f = Fig('l13-steps', 720, 270, T(
        'Three turns of the cycle for the fine calculator, left to right in time. Turn 1: the test '
        'added is three days late costs 150; the red run said No module named fines; the code that '
        'passed was return 150. Turn 2: one day late costs 50; the red run said 150 != 50; the code '
        'became the days between the dates times 50. Turn 3: two days early costs nothing; the red '
        'run said -100 != 0; the code became max of the days and zero, times 50. Each turn adds one '
        'test and changes the code only as far as that test demands.',
        'Três voltas do ciclo para a calculadora de multas, da esquerda para a direita no tempo. '
        'Volta 1: o teste acrescentado é três dias de atraso custam 150; a execução vermelha disse '
        'No module named fines; o código que passou foi return 150. Volta 2: um dia de atraso custa '
        '50; a execução vermelha disse 150 != 50; o código virou os dias entre as datas vezes 50. '
        'Volta 3: dois dias adiantado não custa nada; a execução vermelha disse -100 != 0; o código '
        'virou o máximo entre os dias e zero, vezes 50. Cada volta acrescenta um teste e muda o '
        'código só até onde esse teste exige.'))
    rows = [(78, T('test added', 'teste acrescentado')),
            (138, T('the red run said', 'o vermelho disse')),
            (204, T('code that passes', 'código que passa'))]
    for y, label in rows:
        f.text(112, y, label, size=10, fill='--paper-dim', anchor='end', weight='600')
    turns = [
        (T('turn 1', 'volta 1'), T('3 days late → 150', '3 dias de atraso → 150'),
         ["No module named 'fines'"], ['return 150']),
        (T('turn 2', 'volta 2'), T('1 day late → 50', '1 dia de atraso → 50'),
         ['150 != 50'], ['return (returned - due)', '    .days * 50']),
        (T('turn 3', 'volta 3'), T('2 days early → 0', '2 dias adiantado → 0'),
         ['-100 != 0'], ['return max((returned - due)', '    .days, 0) * 50']),
    ]
    for i, (head, test, red, code) in enumerate(turns):
        cx = 228 + i * 196
        f.text(cx, 34, head, size=11, weight='600')
        f.box(cx, 78, 180, 30, [test], size=10, stroke='--wire')
        f.box(cx, 138, 180, 30, red, size=9.5, stroke='--amber', mono=True)
        f.rect(cx - 90, 182, 180, 44, stroke='--phosphor', fill='--panel', rx=4)
        for j, line in enumerate(code):
            f.text(cx - 80 + (16 if j else 0), 204 + (j * 15 - 7.5 if len(code) == 2 else 0),
                   line.strip(), size=9.5, mono=True, anchor='start')
        f.line(cx, 93, cx, 123, stroke='--paper-dim', width=1, arrow=True)
        f.line(cx, 153, cx, 182, stroke='--paper-dim', width=1, arrow=True)
    f.arrow([(140, 252), (700, 252)], stroke='--paper-dim', width=1.2)
    f.text(420, 242, T('time: one test per turn', 'tempo: um teste por volta'), size=10, fill='--paper-dim',
           italic=True)
    return f, T('The formula was never designed in one go. Each example removed one thing the previous code got wrong.',
                'A fórmula nunca foi projetada de uma vez. Cada exemplo tirou uma coisa que o código anterior errava.')
