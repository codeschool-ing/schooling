"""Lesson 3: SOLID, the first three."""
from figures import Fig, T, figure


@figure('l03-actors', 3)
def actors():
    f = Fig('l03-actors', 720, 270, T(
        'Two actors and one class. The fines office asks for changes to LoanDesk.fine; the '
        'statistics team asks for changes to LoanDesk.average_days_out. Both methods call the same '
        'helper, days_counted. The helper is edited for the fines office to skip Sundays, and the '
        'change travels through the shared helper into the statistics team\'s method, whose average '
        'drops from 16.0 to 14.0 without anybody on that team asking.',
        'Dois atores e uma classe. O setor de multas pede mudanças em LoanDesk.fine; o time de '
        'estatística pede mudanças em LoanDesk.average_days_out. Os dois métodos chamam o mesmo '
        'auxiliar, days_counted. O auxiliar é editado para o setor de multas, para pular os '
        'domingos, e a mudança atravessa o auxiliar compartilhado até o método do time de '
        'estatística, cuja média cai de 16.0 para 14.0 sem ninguém desse time ter pedido.'))
    f.box(90, 70, 140, 34, [T('fines office', 'setor de multas')], stroke='--paper-dim')
    f.box(90, 190, 140, 34, [T('statistics team', 'time de estatística')], stroke='--paper-dim')
    f.rect(225, 30, 230, 210, stroke='--wire', fill='--ink', dash='4 4')
    f.text(340, 46, 'LoanDesk', mono=True, size=10.5, weight='600')
    f.box(340, 90, 190, 30, ['fine()'], mono=True, stroke='--phosphor')
    f.box(340, 190, 190, 30, ['average_days_out()'], mono=True, stroke='--phosphor')
    f.arrow([(160, 70), (160, 90), (241, 90)], stroke='--paper-dim')
    f.arrow([(160, 190), (241, 190)], stroke='--paper-dim')
    f.text(200, 126, T('asks for changes', 'pede mudanças'), size=9.5, fill='--paper-dim', italic=True)
    f.box(600, 140, 160, 34, ['days_counted()'], mono=True, stroke='--amber')
    f.arrow([(435, 90), (600, 90), (600, 119)], stroke='--paper-dim')
    f.arrow([(435, 190), (600, 190), (600, 161)], stroke='--paper-dim')
    f.text(600, 34, T('edited to skip Sundays,', 'editado para pular domingos,'), size=10, fill='--amber', italic=True)
    f.text(600, 50, T('for the fines office', 'para o setor de multas'), size=10, fill='--amber', italic=True)
    f.text(340, 222, T('16.0 becomes 14.0, unasked', '16.0 vira 14.0, sem pedido'), size=10, fill='--amber', italic=True)
    return f, T('One helper serving two actors. A change one of them asked for reaches the other through the code they share.',
                'Um auxiliar servindo dois atores. Uma mudança que um deles pediu chega ao outro pelo código que compartilham.')


@figure('l03-contract', 3)
def contract():
    f = Fig('l03-contract', 720, 300, T(
        'Two panels about the promise of Item.lend. On the left, what a method accepts: the parent '
        'accepts any day, drawn as a box; a dashed box around it shows that a child may accept more. '
        'ReferenceBook accepts no day at all, drawn as an empty box inside the parent\'s, which breaks '
        'the rule. On the right, what a method returns: the parent promises a later day, drawn as a '
        'box; a smaller box inside it shows that a child may promise more, such as never a Sunday. '
        'Laptop returns the same day, drawn as a point outside the parent\'s box, which breaks the '
        'rule.',
        'Dois painéis sobre a promessa de Item.lend. À esquerda, o que um método aceita: o pai '
        'aceita qualquer dia, desenhado como uma caixa; uma caixa tracejada em volta mostra que um '
        'filho pode aceitar mais. ReferenceBook não aceita dia nenhum, desenhado como uma caixa vazia '
        'dentro da do pai, o que quebra a regra. À direita, o que um método devolve: o pai promete um '
        'dia posterior, desenhado como uma caixa; uma caixa menor dentro dela mostra que um filho '
        'pode prometer mais, como nunca um domingo. Laptop devolve o mesmo dia, desenhado como um '
        'ponto fora da caixa do pai, o que quebra a regra.'))
    f.text(175, 18, T('what lend accepts', 'o que lend aceita'), size=11, weight='600')
    f.rect(20, 34, 310, 230, stroke='--paper-dim', dash='5 4', fill='--ink')
    f.text(175, 52, T('a child may accept more', 'um filho pode aceitar mais'), size=10, fill='--paper-dim', italic=True)
    f.rect(55, 70, 240, 170, stroke='--phosphor', width=1.4)
    f.text(175, 90, T('Item: any day', 'Item: qualquer dia'), size=10.5, weight='600')
    f.rect(115, 150, 120, 46, stroke='--amber', dash='3 3', fill='--ink')
    f.text(175, 166, 'ReferenceBook', mono=True, size=9.5, fill='--amber')
    f.text(175, 182, T('no day: breaks it', 'nenhum dia: quebra'), size=9.5, fill='--amber', italic=True)
    f.text(175, 284, T('preconditions: never stronger', 'pré-condições: nunca mais fortes'), size=10, fill='--paper-dim')
    f.line(360, 20, 360, 290, stroke='--wire', width=1, dash='4 4')
    f.text(540, 18, T('what lend returns', 'o que lend devolve'), size=11, weight='600')
    f.rect(400, 50, 280, 190, stroke='--phosphor', width=1.4)
    f.text(540, 70, T('Item: a later day', 'Item: um dia posterior'), size=10.5, weight='600')
    f.rect(450, 110, 180, 60, stroke='--paper-dim', dash='5 4', fill='--ink')
    f.text(540, 132, T('a child may promise more:', 'um filho pode prometer mais:'), size=9.5, fill='--paper-dim', italic=True)
    f.text(540, 150, T('never a Sunday', 'nunca um domingo'), size=9.5, fill='--paper-dim', italic=True)
    f.circle(540, 258, 4, fill='--amber')
    f.text(552, 258, T('Laptop: the same day, outside', 'Laptop: o mesmo dia, fora'), size=9.5, fill='--amber',
           italic=True, anchor='start')
    f.text(540, 284, T('postconditions: never weaker', 'pós-condições: nunca mais fracas'), size=10, fill='--paper-dim')
    return f, T('A child may accept more than its parent and promise more. It may not accept less, as ReferenceBook does, or promise less, as Laptop does.',
                'Um filho pode aceitar mais que o pai e prometer mais. Não pode aceitar menos, como ReferenceBook, nem prometer menos, como Laptop.')
