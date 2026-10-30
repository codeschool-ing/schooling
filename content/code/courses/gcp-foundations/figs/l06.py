"""Lesson 6: roles."""
from figures import Fig, T, figure


@figure('l06-chain', 6)
def chain():
    f = Fig('l06-chain', 720, 230, T(
        'How a grant is put together, left to right. Permissions, such as pubsub.topics.publish, are '
        'collected into a role, roles/pubsub.publisher. A grant joins that role to a principal, '
        'group:planner-devs, and to the resource it is granted on, the topic orders. Below, a note: a '
        'permission can never be granted on its own, only inside a role.',
        'Como uma concessão se monta, da esquerda para a direita. Permissões, como '
        'pubsub.topics.publish, são reunidas num papel, roles/pubsub.publisher. Uma concessão liga esse '
        'papel a um principal, group:planner-devs, e ao recurso em que é concedido, o tópico orders. '
        'Embaixo, uma nota: uma permissão nunca pode ser concedida sozinha, só dentro de um papel.'))
    f.rect(20, 30, 190, 130, stroke='--wire', fill='--panel')
    f.text(115, 48, T('permissions', 'permissões'), size=10, fill='--paper-dim')
    for i, p in enumerate(['pubsub.topics.publish', 'pubsub.topics.get']):
        f.rect(32, 64 + i * 40, 166, 28, stroke='--paper-dim', fill='--ink')
        f.text(115, 78 + i * 40, p, size=9.5, mono=True)
    f.arrow([(212, 95), (256, 95)], stroke='--paper', width=1.5)
    f.rect(260, 66, 180, 58, stroke='--phosphor', fill='--scan', width=1.6)
    f.text(350, 84, T('a role', 'um papel'), size=10, fill='--paper-dim')
    f.text(350, 104, 'roles/pubsub.publisher', size=9.5, mono=True)
    f.arrow([(442, 95), (486, 95)], stroke='--paper', width=1.5)
    f.rect(490, 20, 210, 150, stroke='--amber', fill='--panel', width=1.6)
    f.text(595, 38, T('a grant', 'uma concessão'), size=10, weight='600', fill='--amber')
    f.text(595, 62, T('who', 'quem'), size=9.5, fill='--paper-dim')
    f.text(595, 78, 'group:planner-devs', size=9.5, mono=True)
    f.text(595, 102, T('which role', 'que papel'), size=9.5, fill='--paper-dim')
    f.text(595, 118, 'roles/pubsub.publisher', size=9.5, mono=True)
    f.text(595, 142, T('on what', 'em quê'), size=9.5, fill='--paper-dim')
    f.text(595, 158, 'topics/orders', size=9.5, mono=True)
    f.text(360, 206, T('a permission is never granted on its own, only inside a role',
                       'uma permissão nunca é concedida sozinha, só dentro de um papel'),
           size=10.5, fill='--amber')
    return f, T('Permissions make a role; a grant joins the role to a principal, on a resource.',
                'Permissões formam um papel; uma concessão liga o papel a um principal, num recurso.')
