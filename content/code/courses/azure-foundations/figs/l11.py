"""Lesson 11: conditional access and multifactor authentication."""
from figures import Fig, T, figure


@figure('l11-policy', 11)
def policy():
    f = Fig('l11-policy', 720, 290, T(
        'A conditional access policy as an if-then rule evaluated at sign-in. On the left, the '
        'assignments: users, including directory roles and exclusions, and target resources. In the '
        'middle, the conditions: risk, device platform, location and client app. On the right, the '
        'access controls: block, or grant with a second factor, an authentication strength or a managed '
        'device. Underneath, a note that every policy that applies is enforced together, with no order.',
        'Uma política de acesso condicional como uma regra se-então avaliada no login. À esquerda, as '
        'atribuições: usuários, incluindo papéis do diretório e exclusões, e os recursos de destino. No '
        'meio, as condições: risco, plataforma do dispositivo, local e app cliente. À direita, os '
        'controles de acesso: bloquear, ou conceder com segundo fator, força de autenticação ou '
        'dispositivo gerenciado. Embaixo, uma nota de que toda política que se aplica é imposta junto, '
        'sem ordem.'))
    cols = [(30, T('if: who and what', 'se: quem e o quê'),
             [T('users and groups', 'usuários e grupos'), T('directory roles', 'papéis do diretório'),
              T('exclusions', 'exclusões'), T('target resources', 'recursos de destino')]),
            (265, T('and: under which conditions', 'e: em que condições'),
             [T('sign-in risk', 'risco do login'), T('device platform', 'plataforma do dispositivo'),
              T('location', 'local'), T('client app', 'app cliente')]),
            (500, T('then: what happens', 'então: o que acontece'),
             [T('block', 'bloquear'), T('grant with a second factor', 'conceder com segundo fator'),
              T('authentication strength', 'força de autenticação'), T('managed device', 'dispositivo gerenciado')])]
    for x, title, rows in cols:
        f.rect(x, 24, 190, 186, stroke='--amber' if x == 500 else '--wire', fill='--panel')
        f.text(x + 95, 44, title, size=10.5, weight='600')
        for i, r in enumerate(rows):
            f.rect(x + 14, 62 + i * 36, 162, 28, stroke='--wire', fill='--ink')
            f.text(x + 95, 76 + i * 36, r, size=9.5)
    f.arrow([(221, 117), (264, 117)], stroke='--paper-dim')
    f.arrow([(456, 117), (499, 117)], stroke='--paper-dim')
    f.text(360, 240, T('every policy that applies is enforced, together: no order, no first match',
                       'toda política que se aplica é imposta, junto: sem ordem, sem primeira que casa'),
           size=10.5, fill='--amber')
    f.text(360, 264, T('report-only evaluates and logs, and enforces nothing',
                       'o modo somente relatório avalia e registra, e não impõe nada'),
           size=10, fill='--paper-dim')
    return f, T('One policy: if these, under these conditions, then this.',
                'Uma política: se estes, nestas condições, então isto.')
