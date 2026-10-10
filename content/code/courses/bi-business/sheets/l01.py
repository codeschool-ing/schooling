"""Lesson 1: the first sheet (each store's share of 2025), the five ways it goes
wrong, and the BI cycle drawn as a loop."""
import book as B

LESSON = 'le-q0tn03dt'


def shares():
    rows = [['Store', 'Sales']]
    for name, _, sales in B.STORES:
        rows.append([name, sales])
    rows.append(['Online', B.ONLINE_2025])
    n = len(rows)                               # last data row
    rows.append(['Total', f'=SUM(B2:B{n})'])
    t = n + 1                                   # the total's row
    for k in range(2, n + 1):
        rows[k - 1].append(f'=ROUND(B{k}/B${t}*100,1)')
    rows[0].append('Share')
    cells = [f'B{t}', 'C2', 'C4', f'C{n}']
    return B.report('lesson 1 — each store\'s share of 2025', rows, cells,
                    ['=1+1', f'=SUM(C2:C{n})'])


def trouble():
    """The same sheet with each mistake the trouble section makes, made on purpose."""
    base = [['Store', 'Sales'], ['Savassi', 11880], ['Pampulha', 10560], ['Contagem', 12480]]
    right = B.report('lesson 1 trouble — the three stores as they should be', base, [],
                     ['=SUM(B2:B4)'])
    text = [r[:] for r in base]
    text[2][1] = "'10560"                       # pasted, so it arrives as text
    got_text = B.report('lesson 1 trouble — Pampulha arrives as text', text, [],
                        ['=SUM(B2:B4)', '=B2+B3+B4', '=IF(ISTEXT(B3),"text","number")'])
    dots = [r[:] for r in base]
    dots[3][1] = '12.480'                       # typed the Portuguese way into an English sheet
    got_dots = B.report('lesson 1 trouble — 12.480 typed into an English sheet', dots, ['B4'],
                        ['=SUM(B2:B4)'])
    other = B.report('lesson 1 trouble — a function from the other language', base, [],
                     ['=SOMA(B2:B4)', '=B2/0'])
    return right, got_text, got_dots, other


def cycle():
    f = B.Fig('l01-cycle', 720, 330, (
        'Six boxes in a loop. Top row, left to right: a question, the data, the analysis. Then '
        'down to the bottom row, right to left: the answer, shown; a decision; an action. An '
        'arrow from the action back up to the question is labelled: measure, did it work?',
        'Seis caixas em ciclo. Linha de cima, da esquerda para a direita: uma pergunta, os dados, '
        'a análise. Depois desce para a linha de baixo, da direita para a esquerda: a resposta, '
        'mostrada; uma decisão; uma ação. Uma seta da ação de volta à pergunta diz: medir, '
        'funcionou?'))
    boxes = [
        (20, 30, ('a question', 'uma pergunta'), ('which store do we enlarge?', 'que loja ampliamos?')),
        (265, 30, ('the data', 'os dados'), ('sales and floor area, 9 stores', 'vendas e área, 9 lojas')),
        (510, 30, ('the analysis', 'a análise'), ('sales per square metre', 'vendas por metro quadrado')),
        (510, 200, ('the answer, shown', 'a resposta, mostrada'), ('one ranking on one page', 'um ranking numa página')),
        (265, 200, ('a decision', 'uma decisão'), ('Helena picks a store', 'Helena escolhe a loja')),
        (20, 200, ('an action', 'uma ação'), ('the works, then sales after', 'a obra, e as vendas depois')),
    ]
    W, H = 190, 74
    for x, y, title, detail in boxes:
        f.rect(x, y, W, H, fill='--panel', stroke='--phosphor')
        f.text(x + W / 2, y + 30, title, size=14, anchor='middle', weight=600)
        f.text(x + W / 2, y + 52, detail, size=11, anchor='middle', fill='--paper-dim')
    # top row, left to right
    f.arrow(212, 67, 263, 67)
    f.arrow(457, 67, 508, 67)
    # down the right-hand side
    f.arrow(605, 106, 605, 198)
    # bottom row, right to left
    f.arrow(508, 237, 457, 237)
    f.arrow(263, 237, 212, 237)
    # back up the left-hand side
    f.arrow(115, 198, 115, 106)
    f.text(127, 150, ('measure: did it work?', 'medir: funcionou?'), size=12, anchor='start')
    f.text(360, 312, ('and the measurement is the next question', 'e a medição é a próxima pergunta'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'The BI cycle with the example of lesson 2. Starting at the data instead of the question, '
        'and stopping at the answer instead of the action, are the two ways it is usually broken.',
        'O ciclo de BI com o exemplo da aula 2. Começar pelos dados em vez da pergunta, e parar na '
        'resposta em vez da ação, são os dois jeitos mais comuns de quebrá-lo.'))


def growth():
    rows = [['Year', 'Sales'], [2024, sum(B.SALES_2024)], [2025, sum(B.SALES_2025)]]
    return B.report('lesson 1 — the example answer in what-bi-is', rows, ['B2', 'B3'],
                    ['=ROUND((B3/B2-1)*100,1)'])


def main():
    growth()
    shares()
    trouble()
    cycle()


if __name__ == '__main__':
    main()
