"""Lesson 3: projects."""
from figures import Fig, T, figure


@figure('l03-life-cycle', 3)
def life_cycle():
    f = Fig('l03-life-cycle', 720, 230, T(
        'The life cycle of a project, left to right. Created, the project is ACTIVE. A delete request '
        'moves it to DELETE_REQUESTED: its resources stop serving and stop being billed. For thirty '
        'days an undelete moves it back to ACTIVE, drawn as an arrow returning. After thirty days '
        'Google deletes it for good, and the id stays taken forever. Above the first arrow, two '
        'guards that refuse the delete request: a lien on the project, and deletion_policy PREVENT '
        'in Terraform.',
        'O ciclo de vida de um projeto, da esquerda para a direita. Criado, o projeto está ACTIVE. Um '
        'pedido de exclusão o leva a DELETE_REQUESTED: os recursos param de servir e de ser cobrados. '
        'Por trinta dias um undelete o traz de volta a ACTIVE, desenhado como uma seta que volta. '
        'Depois de trinta dias o Google o apaga de vez, e o id fica ocupado para sempre. Acima da '
        'primeira seta, duas proteções que recusam o pedido de exclusão: um lien no projeto, e o '
        'deletion_policy PREVENT no Terraform.'))
    boxes = [(30, 'ACTIVE', T('serving and billed', 'servindo e cobrado'), '--phosphor'),
             (280, 'DELETE_REQUESTED', T('stopped, not billed', 'parado, sem cobrança'), '--amber'),
             (540, T('deleted', 'apagado'), T('the id stays taken', 'o id continua ocupado'), '--paper-dim')]
    for x, name, note, edge in boxes:
        f.rect(x, 110, 160, 60, stroke=edge, fill='--panel', width=1.6)
        f.text(x + 80, 132, name, size=11, mono=x < 500, weight='600')
        f.text(x + 80, 152, note, size=9.5, fill='--paper-dim')
    f.arrow([(192, 128), (276, 128)], stroke='--paper', width=1.6)
    f.text(234, 116, T('delete', 'excluir'), size=9.5)
    f.arrow([(276, 156), (192, 156)], stroke='--phosphor', width=1.6)
    f.text(234, 170, 'undelete', size=9.5, mono=True, fill='--phosphor')
    f.arrow([(442, 140), (536, 140)], stroke='--paper-dim', width=1.6)
    f.text(489, 128, T('after 30 days', 'após 30 dias'), size=9.5, fill='--paper-dim')
    f.rect(120, 22, 230, 56, stroke='--amber', fill='--ink', dash='5 3')
    f.text(235, 38, T('refuse the delete:', 'recusam a exclusão:'), size=9.5, fill='--amber')
    f.text(235, 54, T('a lien on the project', 'um lien no projeto'), size=9.5)
    f.text(235, 68, 'deletion_policy = "PREVENT"', size=9, mono=True)
    f.line(235, 78, 235, 118, stroke='--amber', width=1.2, dash='3 3')
    f.text(360, 205, T('for thirty days the delete can be undone; after that, nothing can',
                       'por trinta dias a exclusão pode ser desfeita; depois, nada a desfaz'),
           size=10, fill='--paper-dim')
    return f, T('Deleting a project starts a thirty-day clock, and two guards can stop the clock starting.',
                'Apagar um projeto liga um relógio de trinta dias, e duas proteções impedem o relógio de ligar.')
