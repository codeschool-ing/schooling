"""Lesson 4: Azure Policy, guardrails inherited down the hierarchy."""
from figures import Fig, T, figure


@figure('l04-inheritance', 4)
def inheritance():
    f = Fig('l04-inheritance', 720, 330, T(
        'An assignment of Allowed locations on mg-shop reaches everything below it: the management '
        'groups mg-shop-prod and mg-shop-nonprod, the subscriptions shop-prod and shop-staging, and '
        'their resource groups. A second assignment on shop-staging adds a rule of its own, and both '
        'apply there. An exemption excuses one resource group, rg-shop-lab, from the first assignment '
        'only, until a date.',
        'Uma atribuição de Allowed locations em mg-shop alcança tudo abaixo dela: os grupos de '
        'gerenciamento mg-shop-prod e mg-shop-nonprod, as assinaturas shop-prod e shop-staging, e os '
        'grupos de recursos delas. Uma segunda atribuição em shop-staging acrescenta uma regra própria, e '
        'as duas valem ali. Uma isenção dispensa um grupo de recursos, rg-shop-lab, só da primeira '
        'atribuição, até uma data.'))
    # tree
    f.rect(270, 20, 180, 34, stroke='--wire', fill='--scan')
    f.text(360, 37, 'mg-shop', size=10.5, mono=True)
    f.rect(470, 18, 230, 38, stroke='--amber', fill='--panel')
    f.text(585, 37, T('assignment: Allowed locations', 'atribuição: Allowed locations'), size=9.5)
    f.line(452, 37, 468, 37, stroke='--amber')
    f.line(360, 54, 360, 72, stroke='--paper-dim')
    f.line(200, 72, 520, 72, stroke='--paper-dim')
    for x, mg, sub in [(200, 'mg-shop-prod', 'shop-prod'), (520, 'mg-shop-nonprod', 'shop-staging')]:
        f.line(x, 72, x, 86, stroke='--paper-dim')
        f.rect(x - 80, 86, 160, 30, stroke='--wire', fill='--scan')
        f.text(x, 101, mg, size=10, mono=True)
        f.line(x, 116, x, 134, stroke='--paper-dim')
        f.rect(x - 90, 134, 180, 32, stroke='--amber', fill='--panel')
        f.text(x, 150, sub, size=10, mono=True)
    f.text(140, 200, T('one rule applies', 'uma regra vale'), size=10, fill='--paper-dim')
    f.line(200, 166, 200, 222, stroke='--paper-dim')
    f.rect(120, 222, 160, 30, stroke='--wire', fill='--ink', dash='4 3')
    f.text(200, 237, 'rg-shop-prod-app', size=9.5, mono=True)
    # second assignment on staging
    f.rect(620, 136, 92, 28, stroke='--amber', fill='--panel')
    f.text(666, 150, T('2nd rule', '2ª regra'), size=9.5)
    f.line(611, 150, 619, 150, stroke='--amber')
    f.line(470, 166, 470, 222, stroke='--paper-dim')
    f.line(570, 166, 570, 222, stroke='--paper-dim')
    f.rect(395, 222, 150, 30, stroke='--wire', fill='--ink', dash='4 3')
    f.text(470, 237, 'rg-shop-staging', size=9.5, mono=True)
    f.rect(555, 222, 140, 30, stroke='--wire', fill='--ink', dash='4 3')
    f.text(625, 237, 'rg-shop-lab', size=9.5, mono=True)
    f.text(470, 272, T('both rules apply', 'as duas regras valem'), size=10, fill='--paper')
    f.text(625, 272, T('exempt from the first,', 'isento da primeira,'), size=10, fill='--amber')
    f.text(625, 290, T('until a date', 'até uma data'), size=10, fill='--amber')
    return f, T('An assignment holds at its scope and everywhere below it; only an exemption, written down, excuses.',
                'Uma atribuição vale no seu escopo e em tudo abaixo dele; só uma isenção, por escrito, dispensa.')


@figure('l04-order', 4)
def order():
    steps = [('disabled', T('skip if off', 'pula se desligada')),
             ('append, modify', T('change the request', 'muda o pedido')),
             ('deny', T('refuse it', 'recusa')),
             ('audit', T('report it', 'reporta')),
             ('auditIfNotExists', T('missing neighbour', 'vizinho ausente')),
             ('denyAction', T('refuse a delete', 'recusa uma exclusão'))]
    f = Fig('l04-order', 720, 250, T(
        'The order Azure Policy runs effects in when a request arrives: disabled first, then append '
        'and modify, which change the request, then deny, then audit, then auditIfNotExists, then '
        'denyAction last. After the resource provider reports success, auditIfNotExists and '
        'deployIfNotExists look at what exists beside the new resource.',
        'A ordem em que o Azure Policy roda os efeitos quando chega um pedido: disabled primeiro, depois '
        'append e modify, que mudam o pedido, depois deny, depois audit, depois auditIfNotExists, e '
        'denyAction por último. Depois que o resource provider informa sucesso, auditIfNotExists e '
        'deployIfNotExists olham o que existe ao lado do novo recurso.'))
    w, gap = 104, 10
    x0 = (720 - (6 * w + 5 * gap)) / 2
    for i, (code, what) in enumerate(steps):
        x = x0 + i * (w + gap)
        stroke = '--amber' if code == 'deny' else '--wire'
        f.rect(x, 40, w, 70, stroke=stroke, fill='--panel')
        f.text(x + w / 2, 62, code, size=9.5, mono=True)
        f.lines(x + w / 2, 88, [what], size=9, fill='--paper-dim')
        if i < 5:
            f.arrow([(x + w + 1, 75), (x + w + gap - 1, 75)], stroke='--paper-dim')
    f.text(360, 22, T('when the request arrives', 'quando o pedido chega'), size=10, weight='600')
    f.line(x0, 140, x0 + 6 * w + 5 * gap, 140, stroke='--wire', dash='4 3')
    f.text(360, 162, T('after the resource provider reports success', 'depois que o resource provider informa sucesso'),
           size=10, weight='600')
    f.rect(170, 180, 180, 40, stroke='--wire', fill='--panel')
    f.text(260, 200, 'auditIfNotExists', size=9.5, mono=True)
    f.rect(370, 180, 180, 40, stroke='--wire', fill='--panel')
    f.text(460, 200, 'deployIfNotExists', size=9.5, mono=True)
    return f, T('Change before deny, deny before audit, and the effects about neighbours after the resource exists.',
                'Mudar antes de recusar, recusar antes de reportar, e os efeitos sobre vizinhos depois que o recurso existe.')
