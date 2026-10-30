"""Lesson 14: the billing export."""
from figures import Fig, T, figure


@figure('l14-row', 14)
def row():
    f = Fig('l14-row', 720, 300, T(
        'One row of the invented export, from 8 October, drawn as its fields. On the left, plain fields and groups of '
        'fields read with a dot: service.description is Compute Engine, sku.description is N2 Instance '
        'Core running in Sao Paulo, project.id is planner-prod, cost is 3.965359 as a floating-point number. '
        'On the right, two lists that belong to the same row: labels, holding one entry with key team and '
        'value planner, and credits, holding one entry named Sustained Usage Discount with a negative '
        'amount. A note says a list can be empty, and that a label is found by looking inside the list, '
        'not by naming a column.',
        'Uma linha da exportação inventada, de 8 de outubro, desenhada como os seus campos. À esquerda, campos simples e '
        'grupos de campos lidos com um ponto: service.description é Compute Engine, sku.description é N2 '
        'Instance Core running in Sao Paulo, project.id é planner-prod, cost é 3.965359 como número de ponto '
        'flutuante. À direita, duas listas que pertencem à mesma linha: labels, com uma entrada de chave '
        'team e valor planner, e credits, com uma entrada chamada Sustained Usage Discount e um valor '
        'negativo. Uma nota diz que uma lista pode estar vazia, e que um rótulo é achado olhando dentro '
        'da lista, não nomeando uma coluna.'))
    f.rect(20, 20, 680, 230, stroke='--wire', fill='--ink', width=1.2)
    f.text(360, 38, T('one row', 'uma linha'), size=10, fill='--paper-dim')
    fields = [('service.description', 'Compute Engine'),
              ('sku.description', 'N2 Instance Core running in Sao Paulo'),
              ('project.id', 'planner-prod'),
              ('usage.amount', '88.1191 hour'),
              ('cost', '3.965359')]
    for i, (k, v) in enumerate(fields):
        y = 66 + i * 34
        f.text(40, y, k, size=9.5, mono=True, anchor='start', fill='--phosphor')
        f.text(40, y + 15, v, size=9.5, mono=True, anchor='start')
    f.text(40, 236, T('groups of fields, read with a dot', 'grupos de campos, lidos com um ponto'),
           size=9.5, anchor='start', fill='--paper-dim')
    f.rect(420, 56, 260, 66, stroke='--amber', fill='--panel', width=1.4)
    f.text(432, 72, T('labels: a list', 'labels: uma lista'), size=9.5, anchor='start', fill='--amber')
    f.text(432, 96, 'key team, value planner', size=9.5, mono=True, anchor='start')
    f.rect(420, 136, 260, 82, stroke='--amber', fill='--panel', width=1.4)
    f.text(432, 152, T('credits: a list', 'credits: uma lista'), size=9.5, anchor='start', fill='--amber')
    f.text(432, 176, 'Sustained Usage Discount', size=9.5, mono=True, anchor='start')
    f.text(432, 196, 'amount -0.793072', size=9.5, mono=True, anchor='start')
    f.text(550, 236, T('either list may be empty', 'qualquer lista pode estar vazia'), size=9.5,
           fill='--paper-dim')
    f.text(360, 278, T('a label is found inside the list, never as a column',
                       'um rótulo é achado dentro da lista, nunca como coluna'), size=10.5)
    return f, T('Fields are read with a dot; labels and credits are lists inside the row.',
                'Campos se leem com um ponto; rótulos e créditos são listas dentro da linha.')
