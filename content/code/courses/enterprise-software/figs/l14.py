"""Lesson 14: Data migration: quality, reconciliation and rollback."""
from figures import Fig, T, figure


@figure('l14-pipeline', 14)
def pipeline():
    f = Fig('l14-pipeline', 720, 330, T(
        'The migration pipeline, left to right: Coleta, copied at the freeze; extract; transform; '
        'load; the new farm system. Above the transform step, the mapping specification, signed by '
        'the data owners, feeds the rules: translation tables, the merge table and units. Under '
        'extract, rows outside the period go to the archive. Under transform and under load, a '
        'reject file holds every refused row with its reason. Both reject files go to the owners, '
        'finance, Sebastião and Cláudia, who correct wrong facts in Coleta itself, shown by a dashed '
        'arrow back to Coleta, so the next run carries the fix.',
        'O pipeline da migração, da esquerda para a direita: o Coleta, copiado no congelamento; '
        'extração; transformação; carga; o novo sistema de fazendas. Acima da transformação, a '
        'especificação de mapeamento, assinada pelos donos dos dados, alimenta as regras: tabelas de '
        'tradução, a tabela de fusões e as unidades. Debaixo da extração, as linhas fora do período '
        'vão para o arquivo. Debaixo da transformação e da carga, um arquivo de rejeitos guarda cada '
        'linha recusada com o motivo. Os dois arquivos de rejeitos vão para os donos, o financeiro, '
        'Sebastião e Cláudia, que corrigem os fatos errados no próprio Coleta, numa seta tracejada '
        'de volta ao Coleta, e a execução seguinte já leva a correção.'))
    y = 130
    f.box(70, y, 112, 50, ['Coleta', T('copy at the freeze', 'cópia no congelamento')],
          stroke='--phosphor', size=10)
    steps = [(212, T('extract', 'extração')), (362, T('transform', 'transformação')),
             (512, T('load', 'carga'))]
    for x, label in steps:
        f.box(x, y, 112, 50, [label], size=11)
    f.box(656, y, 112, 50, [T('new farm', 'novo sistema'), T('system', 'de fazendas')],
          stroke='--phosphor', size=10)
    for a, b in [(126, 156), (268, 306), (418, 456), (568, 600)]:
        f.arrow([(a, y), (b - 2, y)], stroke='--phosphor', width=1.4)
    # the specification above the transform
    f.box(362, 40, 250, 46, [T('mapping specification', 'especificação de mapeamento'),
                             T('signed by the data owners', 'assinada pelos donos dos dados')],
          stroke='--paper-dim', size=10, dash='4 3')
    f.arrow([(362, 63), (362, 103)], stroke='--paper-dim', width=1.2)
    f.text(372, 92, T('rules, tables, merges', 'regras, tabelas, fusões'), size=9.5,
           fill='--paper-dim', anchor='start')
    # the archive under the extract
    f.arrow([(212, 155), (212, 193)], stroke='--paper-dim', width=1.2)
    f.box(212, 216, 132, 44, [T('archive', 'arquivo'), T('out of the period', 'fora do período')],
          size=10, fill='--ink')
    # the reject files
    for x in (362, 512):
        f.arrow([(x, 155), (x, 193)], stroke='--amber', width=1.2)
        f.box(x, 216, 132, 44, [T('reject file', 'arquivo de rejeitos'),
                                T('row + reason', 'linha + motivo')], stroke='--amber', size=10)
    # to the owners and back to the source
    f.arrow([(362, 238), (362, 270), (420, 270), (420, 280)], stroke='--amber', width=1.2)
    f.arrow([(512, 238), (512, 270), (454, 270), (454, 280)], stroke='--amber', width=1.2)
    f.box(437, 300, 250, 36, [T('owners: finance, Sebastião, Cláudia',
                                'donos: financeiro, Sebastião, Cláudia')], size=10)
    f.arrow([(312, 300), (70, 300), (70, 157)], stroke='--paper-dim', width=1.2, dash='5 3')
    f.text(186, 290, T('wrong facts corrected at the source', 'fatos errados corrigidos na origem'),
           size=9.5, fill='--paper-dim')
    return f, T('The pipeline and where its rejects go. A rejected row is work for the person who owns the rule it broke, and a wrong fact is corrected in Coleta, so every later run starts from cleaner data.',
                'O pipeline e para onde vão os rejeitos. Uma linha rejeitada é trabalho para quem é dono da regra que ela quebrou, e um fato errado é corrigido no Coleta, então cada execução seguinte parte de dados mais limpos.')


@figure('l14-rehearsals', 14)
def rehearsals():
    f = Fig('l14-rehearsals', 720, 270, T(
        'A time chart of the two dress rehearsals against the cutover window, which runs from '
        'Saturday 20:00 to Sunday 10:00, fourteen hours. Vertical lines mark the budget for the '
        'decision at 05:00, the latest decision at 08:00 and the end of the window at 10:00. Dress '
        'rehearsal 1: the run from freeze to decision took 11 hours 20 minutes, reaching 07:20, and '
        'its rollback took 3 hours 5 minutes more, ending at 10:25, past the window. Dress rehearsal '
        '2: the run took 5 hours 50 minutes, reaching 01:50, and its rollback 1 hour 55 minutes, '
        'ending at 03:45.',
        'Um gráfico de tempo dos dois ensaios gerais contra a janela de cutover, que vai de sábado '
        '20:00 a domingo 10:00, catorze horas. Linhas verticais marcam o orçamento para a decisão às '
        '05:00, a decisão mais tardia às 08:00 e o fim da janela às 10:00. Ensaio geral 1: a '
        'execução do congelamento até a decisão levou 11 horas e 20 minutos, chegando às 07:20, e o '
        'rollback levou mais 3 horas e 5 minutos, terminando às 10:25, depois da janela. Ensaio '
        'geral 2: a execução levou 5 horas e 50 minutos, chegando à 01:50, e o rollback 1 hora e 55 '
        'minutos, terminando às 03:45.'))
    x0, k = 160, 37.0

    def X(h):
        return x0 + h * k

    top, bottom = 52, 196
    clocks = ['20:00', '22:00', '00:00', '02:00', '04:00', '06:00', '08:00', '10:00']
    f.line(X(0), bottom, X(14), bottom, stroke='--wire', width=1)
    for i, c in enumerate(clocks):
        f.line(X(2 * i), bottom, X(2 * i), bottom + 5, stroke='--wire', width=1)
        f.text(X(2 * i), bottom + 16, c, size=10, fill='--paper-dim', mono=True)
    f.text(X(7), bottom + 36, T('hours after the freeze, Saturday night into Sunday',
                                'horas depois do congelamento, de sábado para domingo'),
           size=10, fill='--paper-dim')
    marks = [(9, T('budget', 'orçamento'), '--paper-dim', '4 3'),
             (12, T('latest decision', 'decisão mais tardia'), '--amber', None),
             (14, T('window ends', 'fim da janela'), '--paper', None)]
    for h, label, stroke, dash in marks:
        for y1, y2 in ((top - 8, 66), (98, 134), (166, bottom)):
            f.line(X(h), y1, X(h), y2, stroke=stroke, width=1.3, dash=dash)
    f.text(X(9) - 4, top - 18, marks[0][1], size=10, fill='--paper-dim', anchor='end')
    f.text(X(12), top - 18, marks[1][1], size=10, fill='--amber')
    f.text(X(14), top - 32, marks[2][1], size=10, fill='--paper')
    rows = [(T('dress rehearsal 1', 'ensaio geral 1'), 11 + 20 / 60, 3 + 5 / 60, '--amber', 82),
            (T('dress rehearsal 2', 'ensaio geral 2'), 5 + 50 / 60, 1 + 55 / 60, '--phosphor', 150)]
    for label, run, back, stroke, y in rows:
        f.text(x0 - 10, y, label, size=10.5, anchor='end')
        f.rect(X(0), y - 13, run * k, 26, stroke=stroke, fill='--panel', width=1.4, rx=2)
        f.rect(X(run), y - 13, back * k, 26, stroke=stroke, fill='--ink', width=1.2, rx=2,
               dash='4 3')
    f.text(X(11.33) / 2 + X(0) / 2, 82, '11 h 20', size=10)
    f.text((X(12) + X(14)) / 2, 82, '3 h 05', size=10, fill='--amber')
    f.text((X(0) + X(5.83)) / 2, 150, '5 h 50', size=10)
    f.text((X(5.83) + X(7.75)) / 2, 150, '1 h 55', size=10)
    f.rect(16, 14, 26, 14, stroke='--paper-dim', fill='--panel', width=1.2, rx=2)
    f.text(48, 21, T('run, freeze to decision', 'execução, do congelamento à decisão'), size=10,
           anchor='start')
    f.rect(16, 36, 26, 14, stroke='--paper-dim', fill='--ink', width=1.2, rx=2, dash='4 3')
    f.text(48, 43, T('rollback, timed', 'rollback, cronometrado'), size=10, anchor='start')
    return f, T('The two dress rehearsals against the window. The first would have reached its decision with forty minutes in reserve and could not have rolled back before the window closed; the second fits with room for both.',
                'Os dois ensaios gerais contra a janela. O primeiro chegaria à decisão com quarenta minutos de folga e não conseguiria fazer o rollback antes de a janela fechar; o segundo cabe com espaço para os dois.')


@figure('l14-levels', 14)
def levels():
    f = Fig('l14-levels', 720, 300, T(
        'A grid of four checks against five faults. The checks, one per row: count, control total, '
        'record by fingerprint, and a sample read by the data owner. The faults, one per column: a '
        'row dropped, one value changed, two values swapped, a farm loaded under the wrong code, and '
        'a wrong rule in the specification. The count catches only the dropped row. The control '
        'total catches the dropped row and the changed value. The record check catches the first '
        'four faults. Only the owner’s sample catches the wrong rule, because every check written '
        'from the same specification agrees with it.',
        'Uma grade de quatro verificações contra cinco falhas. As verificações, uma por linha: '
        'contagem, total de controle, registro por impressão digital, e uma amostra lida pelo dono '
        'dos dados. As falhas, uma por coluna: uma linha perdida, um valor alterado, dois valores '
        'trocados, uma fazenda carregada com o código errado, e uma regra errada na especificação. '
        'A contagem pega só a linha perdida. O total de controle pega a linha perdida e o valor '
        'alterado. A verificação por registro pega as quatro primeiras falhas. Só a amostra do dono '
        'pega a regra errada, porque toda verificação escrita a partir da mesma especificação '
        'concorda com ela.'))
    cols = [T(['a row', 'dropped'], ['uma linha', 'perdida']),
            T(['one value', 'changed'], ['um valor', 'alterado']),
            T(['two values', 'swapped'], ['dois valores', 'trocados']),
            T(['a farm under', 'the wrong code'], ['fazenda com o', 'código errado']),
            T(['a wrong rule in', 'the specification'], ['regra errada na', 'especificação'])]
    rows = [(T('count', 'contagem'), [1, 0, 0, 0, 0]),
            (T('control total', 'total de controle'), [1, 1, 0, 0, 0]),
            (T('record, by fingerprint', 'registro, por impressão digital'), [1, 1, 1, 1, 0]),
            (T('the owner’s sample', 'amostra lida pelo dono'), [0, 0, 0, 0, 1])]
    x0, cw = 214, 100
    for i, c in enumerate(cols):
        f.lines(x0 + cw * i + cw / 2, 40, c, size=10, fill='--paper-dim')
    y0, rh = 86, 42
    for j, (label, hits) in enumerate(rows):
        y = y0 + rh * j
        if j == 3:
            f.line(16, y - rh / 2, x0 + cw * 5, y - rh / 2, stroke='--wire', width=1, dash='4 3')
        f.text(16, y, label, size=10.5, anchor='start')
        for i, hit in enumerate(hits):
            cx = x0 + cw * i + cw / 2
            if hit:
                f.circle(cx, y, 8, fill='--phosphor' if j < 3 else '--amber')
            else:
                f.circle(cx, y, 8, fill=None, stroke='--wire', width=1.2, dash='2 2')
    f.circle(232, 268, 7, fill='--phosphor')
    f.text(246, 268, T('caught', 'pega'), size=10, anchor='start')
    f.circle(330, 268, 7, fill=None, stroke='--wire', width=1.2, dash='2 2')
    f.text(344, 268, T('passes unseen', 'passa despercebida'), size=10, anchor='start')
    return f, T('What each level of reconciliation can see. Each level down catches what the one above lets through; the last row is a person, because a check built from the specification cannot doubt it.',
                'O que cada nível da reconciliação consegue ver. Cada nível abaixo pega o que o de cima deixa passar; a última linha é uma pessoa, porque uma verificação feita a partir da especificação não consegue duvidar dela.')


@figure('l14-cutover', 14)
def cutover():
    f = Fig('l14-cutover', 720, 340, T(
        'A timeline of the cutover with the cost of going back drawn above it. The left part of the '
        'axis is the night, from the freeze at Saturday 20:00 through the planned go/no-go at 05:00 '
        'and the latest decision at 08:00 to the end of the window at 10:00. After a break, the '
        'right part is the following weeks, to the 9th, when the bank file for the first payment '
        'from the new system is sent: the point of no return. Above the axis, the cost of going back '
        'rises in steps: before the go, a rehearsed two-hour rollback with nothing lost; after the '
        'go, carrying every day of readings back into Coleta, growing each day; after the bank '
        'file, reversing payments to about 1,900 farms, which nobody would do.',
        'Uma linha do tempo do cutover com o custo de voltar atrás desenhado acima dela. A parte '
        'esquerda do eixo é a noite, do congelamento no sábado às 20:00, passando pelo go/no-go '
        'planejado às 05:00 e pela decisão mais tardia às 08:00, até o fim da janela às 10:00. '
        'Depois de um corte, a parte direita são as semanas seguintes, até o dia 9, quando sai o '
        'arquivo do banco do primeiro pagamento feito pelo novo sistema: o ponto sem volta. Acima do '
        'eixo, o custo de voltar sobe em degraus: antes do go, um rollback ensaiado de duas horas sem '
        'perder nada; depois do go, levar cada dia de leituras de volta ao Coleta, crescendo a cada '
        'dia; depois do arquivo do banco, estornar pagamentos de cerca de 1.900 fazendas, o que '
        'ninguém faria.'))
    ax = 214
    nx0, nk = 48, 20.0          # the night: 14 hours

    def N(h):
        return nx0 + h * nk

    mx0, mk = 356, 10.0         # the month: days after the Sunday
    f.line(N(0), ax, N(14) + 6, ax, stroke='--paper-dim', width=1.4)
    f.line(N(14) + 14, ax - 7, N(14) + 6, ax + 7, stroke='--paper-dim', width=1.2)
    f.line(N(14) + 22, ax - 7, N(14) + 14, ax + 7, stroke='--paper-dim', width=1.2)
    f.arrow([(N(14) + 20, ax), (712, ax)], stroke='--paper-dim', width=1.4)
    # cost of going back, drawn above the axis
    f.rect(N(0), ax - 34, N(9) - N(0), 34, stroke='--phosphor', fill='--panel', rx=1)
    f.lines((N(0) + N(9)) / 2, ax - 17, [T('rollback: 2 h, rehearsed', 'rollback: 2 h, ensaiado')],
            size=10)
    pts = [(N(9), ax), (N(9), ax - 60), (mx0 + 24 * mk, ax - 120), (mx0 + 24 * mk, ax)]
    f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + ' Z', stroke='--paper-dim',
           fill='--panel', width=1.2)
    f.lines(470, ax - 52, [T('carry the readings back to Coleta:', 'levar as leituras de volta ao Coleta:'),
                           T('about 4 h per day of readings', 'cerca de 4 h por dia de leituras')],
            size=10)
    f.rect(mx0 + 24 * mk, ax - 172, 712 - (mx0 + 24 * mk), 172, stroke='--amber', fill='--ink',
           rx=1)
    f.lines((mx0 + 24 * mk + 712) / 2, ax - 130,
            [T('reverse', 'estornar'), T('payments', 'pagamentos'), T('to ~1,900', 'de ~1.900'),
             T('farms', 'fazendas')], size=10, fill='--amber')
    f.text(24, 22, T('cost of going back', 'custo de voltar atrás'), size=10.5, fill='--paper-dim',
           anchor='start')
    # marks under the axis
    marks = [(N(0), T('Sat 20:00', 'sáb 20:00'), T('freeze', 'congelamento'), 0, '--paper'),
             (N(9), '05:00', T('go/no-go', 'go/no-go'), 0, '--phosphor'),
             (N(12), '08:00', T('latest decision', 'decisão mais tardia'), 1, '--amber'),
             (N(14), '10:00', T('window ends', 'fim da janela'), 2, '--paper'),
             (mx0 + 24 * mk, T('the 9th', 'dia 9'), T('bank file sent', 'arquivo ao banco'), 0,
              '--amber')]
    for x, when, what, tier, fill in marks:
        f.line(x, ax - 4, x, ax + 8 + 34 * tier, stroke='--wire', width=1)
        y = ax + 20 + 34 * tier
        f.text(x, y, when, size=10, fill='--paper-dim', mono=when[0].isdigit())
        f.text(x, y + 14, what, size=10, fill=fill)
    f.text(mx0 + 24 * mk, ax + 82, T('point of no return', 'ponto sem volta'), size=10.5,
           fill='--amber', weight='600')
    f.text(470, ax + 20, T('weeks of hypercare', 'semanas de hypercare'), size=10,
           fill='--paper-dim')
    return f, T('The cost of going back grows after every step of the cutover. The night’s rollback is cheap and rehearsed; once the first payment from the new system has left, there is no going back, only fixing forward.',
                'O custo de voltar cresce a cada passo do cutover. O rollback da noite é barato e ensaiado; depois que sai o primeiro pagamento do novo sistema, não há volta, só correção para a frente.')
