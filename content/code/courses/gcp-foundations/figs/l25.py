"""Lesson 25: Cloud Asset Inventory."""
from figures import Fig, T, figure


@figure('l25-difference', 25)
def difference():
    f = Fig('l25-difference', 720, 250, T(
        'Two lists side by side. On the left, what Terraform declares, read from its state: orders and '
        'invoices. On the right, what exists, read from the inventory or, in the lab, from gcloud: orders, '
        'invoices and scratch-2025. An arrow from the two lists to a third box gives the difference, what '
        'exists and nobody declared: scratch-2025. Its two possible endings are written under it: imported '
        'into Terraform, or deleted. A note says that a declared resource changed by hand appears in both '
        'lists, and is the next lesson\'s drift.',
        'Duas listas lado a lado. À esquerda, o que o Terraform declara, lido do estado dele: orders e '
        'invoices. À direita, o que existe, lido do inventário ou, no laboratório, do gcloud: orders, '
        'invoices e scratch-2025. Uma seta das duas listas para uma terceira caixa dá a diferença, o que '
        'existe e ninguém declarou: scratch-2025. Os dois fins possíveis estão escritos embaixo: importado '
        'para o Terraform, ou apagado. Uma nota diz que um recurso declarado e mudado à mão aparece nas duas '
        'listas, e é o drift da próxima lição.'))
    f.rect(20, 20, 200, 130, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(120, 40, T('declared', 'declarado'), size=10.5, fill='--phosphor')
    f.text(120, 58, 'terraform state', size=9, mono=True, fill='--paper-dim')
    for i, n in enumerate(('orders', 'invoices')):
        f.text(120, 86 + i * 20, n, size=10, mono=True)
    f.rect(260, 20, 200, 130, stroke='--wire', fill='--panel', width=1.2)
    f.text(360, 40, T('existing', 'existente'), size=10.5)
    f.text(360, 58, T('the inventory, or gcloud', 'o inventário, ou o gcloud'), size=9, fill='--paper-dim')
    for i, n in enumerate(('orders', 'invoices', 'scratch-2025')):
        f.text(360, 86 + i * 20, n, size=10, mono=True, fill='--amber' if i == 2 else '--paper')
    f.arrow([(462, 85), (506, 85)], stroke='--amber', width=1.6)
    f.rect(510, 20, 190, 130, stroke='--amber', fill='--scan', width=1.6)
    f.text(605, 40, T('exists, undeclared', 'existe, sem declarar'), size=10.5, fill='--amber')
    f.text(605, 86, 'scratch-2025', size=10.5, mono=True)
    f.text(605, 116, T('import it, or delete it', 'importar, ou apagar'), size=9, fill='--paper-dim')
    f.text(360, 190, T('what exists, minus what is declared, is what somebody forgot',
                       'o que existe, menos o que está declarado, é o que alguém esqueceu'), size=10.5)
    f.text(360, 214, T('a declared resource changed by hand is in both lists: that is drift, lesson 26',
                       'um recurso declarado mudado à mão está nas duas listas: isso é drift, lição 26'),
           size=9.5, fill='--paper-dim')
    return f, T('The difference between the two lists is the work.',
                'A diferença entre as duas listas é o trabalho.')
