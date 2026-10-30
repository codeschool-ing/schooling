"""Lesson 7: allow and deny."""
from figures import Fig, T, figure


@figure('l07-evaluation', 7)
def evaluation():
    f = Fig('l07-evaluation', 720, 300, T(
        'How a request is judged, top to bottom. First, deny policies from the organisation down to '
        'the resource: if any denies the permission to the principal, the request is refused and '
        'nothing else is read. Then allow policies from the organisation down to the resource: if any '
        'binding on the path grants a role holding the permission, the request is allowed. If neither, '
        'the request is refused: no grant is a refusal.',
        'Como um pedido é julgado, de cima para baixo. Primeiro, as políticas de negação, da '
        'organização até o recurso: se alguma nega a permissão ao principal, o pedido é recusado e mais '
        'nada é lido. Depois, as políticas de permissão, da organização até o recurso: se alguma '
        'vinculação no caminho concede um papel com a permissão, o pedido é permitido. Se nenhuma das '
        'duas, o pedido é recusado: nenhuma concessão é uma recusa.'))
    f.rect(250, 14, 220, 34, stroke='--paper-dim', fill='--panel')
    f.text(360, 31, T('a request arrives', 'chega um pedido'), size=10.5)
    f.arrow([(360, 48), (360, 70)], stroke='--paper', width=1.4)
    f.rect(190, 72, 340, 50, stroke='--amber', fill='--ink', width=1.6)
    f.text(360, 90, T('1. deny policies, organisation to resource', '1. negações, da organização ao recurso'),
           size=10.5, weight='600')
    f.text(360, 108, T('does any deny this principal this permission?', 'alguma nega esta permissão a este principal?'),
           size=9.5, fill='--paper-dim')
    f.arrow([(532, 97), (596, 97)], stroke='--amber', width=1.6)
    f.text(564, 86, T('yes', 'sim'), size=9.5, fill='--amber')
    f.rect(600, 78, 104, 38, stroke='--amber', fill='--panel', width=1.6)
    f.text(652, 97, T('refused', 'recusado'), size=10.5, weight='600', fill='--amber')
    f.arrow([(360, 122), (360, 156)], stroke='--paper', width=1.4)
    f.text(372, 139, T('no', 'não'), size=9.5, anchor='start', fill='--paper-dim')
    f.rect(190, 158, 340, 50, stroke='--phosphor', fill='--ink', width=1.6)
    f.text(360, 176, T('2. allow policies, organisation to resource', '2. permissões, da organização ao recurso'),
           size=10.5, weight='600')
    f.text(360, 194, T('does any binding grant a role holding it?', 'alguma vinculação concede um papel com ela?'),
           size=9.5, fill='--paper-dim')
    f.arrow([(532, 183), (596, 183)], stroke='--phosphor', width=1.6)
    f.text(564, 172, T('yes', 'sim'), size=9.5, fill='--phosphor')
    f.rect(600, 164, 104, 38, stroke='--phosphor', fill='--panel', width=1.6)
    f.text(652, 183, T('allowed', 'permitido'), size=10.5, weight='600', fill='--phosphor')
    f.arrow([(360, 208), (360, 242)], stroke='--paper', width=1.4)
    f.text(372, 225, T('no', 'não'), size=9.5, anchor='start', fill='--paper-dim')
    f.rect(260, 244, 200, 38, stroke='--amber', fill='--panel', width=1.6)
    f.text(360, 263, T('refused: no grant at all', 'recusado: concessão nenhuma'), size=10.5, fill='--amber')
    f.text(20, 140, T('a deny is read first,', 'a negação é lida antes,'), size=9.5, anchor='start',
           fill='--paper-dim')
    f.text(20, 156, T('so no allow can undo it', 'e nenhuma permissão a desfaz'), size=9.5, anchor='start',
           fill='--paper-dim')
    return f, T('Deny first, then allow, then refuse.', 'Primeiro a negação, depois a permissão, depois a recusa.')
