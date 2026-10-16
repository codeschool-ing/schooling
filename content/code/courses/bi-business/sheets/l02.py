"""Lesson 2: the store ranking. Sales against sales per square metre, the
chain's average, and the two orderings drawn side by side."""
import book as B

LESSON = 'le-g14gffv2'


def ranking():
    rows = [['Store', 'Sales', 'Floor', 'Per m2']]
    for name, floor, sales in B.STORES:
        rows.append([name, sales, floor])
    n = len(rows)                                   # last store row (10)
    for k in range(2, n + 1):
        rows[k - 1].append(f'=ROUND(B{k}*1000/C{k},0)')
    t = n + 1
    rows.append(['Total', f'=SUM(B2:B{n})', f'=SUM(C2:C{n})', f'=ROUND(B{t}*1000/C{t},0)'])
    cells = [f'D{k}' for k in range(2, n + 1)] + [f'B{t}', f'C{t}', f'D{t}']
    got = B.report('lesson 2 — sales per square metre, nine stores', rows, cells,
                   ['=ROUND(D4/D2*100,0)',            # Contagem as a share of Savassi's density
                    '=ROUND(C4/C2,1)',                # Contagem's floor against Savassi's
                    '=ROUND(B4/B2,2)',                # and its sales against Savassi's
                    f'=ROUND(C4/C{t}*100,1)',         # Contagem's share of the floor
                    f'=ROUND(B4/B{t}*100,1)'])        # and of the stores' sales
    by_sales = sorted(B.STORES, key=lambda s: -s[2])
    by_density = sorted(B.STORES, key=lambda s: (-round(s[2] * 1000 / s[1]), -s[2]))
    print('  by sales:  ', ', '.join(s[0] for s in by_sales))
    print('  by per m2: ', ', '.join(f'{s[0]} {round(s[2] * 1000 / s[1])}' for s in by_density))
    return got, by_sales, by_density


def figure(by_sales, by_density):
    f = B.Fig('l02-ranking', 720, 430, (
        'Two ranked lists of the nine stores joined by lines. Left, by 2025 sales: Contagem first, '
        'then Savassi, Pampulha, Nova Lima, Juiz de Fora, Betim, Ipatinga, Sete Lagoas, Divinópolis. '
        'Right, by sales per square metre: Savassi 6,600, Nova Lima 6,300, Pampulha 4,400, '
        'Contagem 3,900, Betim and Divinópolis 3,400, Juiz de Fora, Ipatinga and Sete Lagoas 3,200. '
        'The line from Contagem falls from first to fourth; the line from Nova Lima rises from '
        'fourth to second.',
        'Duas listas ordenadas das nove lojas ligadas por linhas. À esquerda, por vendas de 2025: '
        'Contagem primeiro, depois Savassi, Pampulha, Nova Lima, Juiz de Fora, Betim, Ipatinga, '
        'Sete Lagoas, Divinópolis. À direita, por vendas por metro quadrado: Savassi 6.600, Nova '
        'Lima 6.300, Pampulha 4.400, Contagem 3.900, Betim e Divinópolis 3.400, Juiz de Fora, '
        'Ipatinga e Sete Lagoas 3.200. A linha de Contagem cai de primeiro para quarto; a de Nova '
        'Lima sobe de quarto para segundo.'))
    top, step = 78, 36
    lx, rx = 40, 440                     # left column box x, right column box x
    bw, bh = 240, 28
    f.text(lx, 40, ('by sales, R$ thousand', 'por vendas, R$ mil'), size=13, weight=600)
    f.text(rx, 40, ('by sales per m², R$', 'por vendas por m², R$'), size=13, weight=600)
    pos_r = {s[0]: i for i, s in enumerate(by_density)}
    hi = {'Contagem', 'Nova Lima'}
    for i, (name, floor, sales) in enumerate(by_sales):
        y = top + i * step
        j = pos_r[name]
        y2 = top + j * step
        strong = name in hi
        f.line(lx + bw + 2, y + bh / 2, rx - 2, y2 + bh / 2,
               stroke='--amber' if strong else '--wire', sw=2.5 if strong else 1.2)
    for i, (name, floor, sales) in enumerate(by_sales):
        y = top + i * step
        strong = name in hi
        f.rect(lx, y, bw, bh, fill='--panel', stroke='--amber' if strong else '--wire')
        f.text(lx + 10, y + 19, f'{i + 1}', size=12, fill='--paper-dim', mono=True)
        f.text(lx + 34, y + 19, name, size=13, weight=600 if strong else None)
        f.text(lx + bw - 10, y + 19, (B.fmt(sales), B.fmt(sales, 'pt')), size=12, anchor='end',
               mono=True, fill='--paper-dim')
    for j, (name, floor, sales) in enumerate(by_density):
        y = top + j * step
        strong = name in hi
        d = round(sales * 1000 / floor)
        f.rect(rx, y, bw, bh, fill='--panel', stroke='--amber' if strong else '--wire')
        f.text(rx + 10, y + 19, f'{j + 1}', size=12, fill='--paper-dim', mono=True)
        f.text(rx + 34, y + 19, name, size=13, weight=600 if strong else None)
        f.text(rx + bw - 10, y + 19, (B.fmt(d), B.fmt(d, 'pt')), size=12, anchor='end',
               mono=True, fill='--paper-dim')
    f.text(360, 418, ('same stores, same year: the question decides the order',
                      'mesmas lojas, mesmo ano: a pergunta decide a ordem'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'The nine stores ranked twice. Contagem sells the most because it is the largest; per '
        'square metre it is fourth, selling 59% of what Savassi sells on each metre.',
        'As nove lojas ordenadas duas vezes. Contagem vende mais porque é a maior; por metro '
        'quadrado ela é a quarta, vendendo 59% do que a Savassi vende em cada metro.'))


ENLARGEMENT = 4000     # thousands of reais: the order of cost of enlarging one store

# Caio's belief about Juiz de Fora against the delivery records of 2025.
JF_DELIVERIES, JF_LATE = 1120, 76
ALL_DELIVERIES, ALL_LATE = 14600, 949


def late():
    rows = [['Route', 'Deliveries', 'Late', 'Late %'],
            ['Juiz de Fora', JF_DELIVERIES, JF_LATE, '=ROUND(C2/B2*100,1)'],
            ['All routes', ALL_DELIVERIES, ALL_LATE, '=ROUND(C3/B3*100,1)']]
    return B.report('lesson 2 — the late rate Caio remembered (given data)', rows, ['D2', 'D3'])


def main():
    print(f'  given: enlarging a store costs about R$ {ENLARGEMENT // 1000} million')
    late()
    got, by_sales, by_density = ranking()
    figure(by_sales, by_density)


if __name__ == '__main__':
    main()
