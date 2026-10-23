"""Lesson 14: the deployment flow, and the road around it."""
from figures import Fig, T, figure


@figure('l14-flow', 14)
def flow():
    f = Fig('l14-flow', 720, 262, T(
        'The deployment flow as a row of six stages from a change to the account: format, validate, '
        'scan and plan are run by a machine; review is done by a person; apply is done by the '
        'pipeline\'s role, using the saved plan. A dashed amber arrow runs underneath, from a person\'s '
        'own credentials straight to the account, passing through none of the stages: the road around '
        'the road, which taking write access away from people closes and lesson 16 detects.',
        'O fluxo de publicação como uma fileira de seis etapas, de uma mudança até a conta: format, '
        'validate, scan e plan rodam numa máquina; a revisão é feita por uma pessoa; o apply é feito '
        'pelo papel do pipeline, usando o plano salvo. Uma seta tracejada âmbar passa por baixo, das '
        'credenciais da própria pessoa direto para a conta, sem passar por nenhuma etapa: o caminho em '
        'volta do caminho, que tirar o acesso de escrita das pessoas fecha e a aula 16 detecta.'))
    stages = ['format', 'validate', 'scan', 'plan', T('review', 'revisão'), 'apply']
    mono = [True, True, True, True, False, True]
    x0, w, gap, y = 92, 80, 12, 90
    f.rect(8, y, 72, 50, stroke='--paper-dim', fill='--panel')
    f.text(44, y + 25, T('a change', 'uma mudança'), size=10)
    xs = []
    for i, s in enumerate(stages):
        x = x0 + i * (w + gap)
        xs.append(x)
        edge = '--phosphor' if i == 5 else ('--amber' if i == 4 else '--wire')
        f.rect(x, y, w, 50, stroke=edge, fill='--scan', width=1.3)
        f.text(x + w / 2, y + 25, s, size=10.5, mono=mono[i])
        prev = 80 if i == 0 else xs[i - 1] + w
        f.arrow([(prev + 1, y + 25), (x - 1, y + 25)], stroke='--paper-dim')
    ax = x0 + 6 * (w + gap)
    f.rect(ax, y - 10, 70, 70, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(ax + 35, y + 25, T('account', 'conta'), size=10.5, weight='600')
    f.arrow([(xs[5] + w + 1, y + 25), (ax - 1, y + 25)], stroke='--phosphor')
    # who runs each part
    left, right = xs[0], xs[3] + w
    f.line(left, y - 14, right, y - 14, stroke='--paper-dim')
    f.text((left + right) / 2, y - 28, T('a machine, in this order', 'uma máquina, nesta ordem'), size=10,
           fill='--paper-dim')
    f.text(xs[4] + w / 2, y - 28, T('a person', 'uma pessoa'), size=10, fill='--amber')
    f.text(xs[5] + w / 2, y - 42, T('the pipeline\'s', 'o papel do'), size=10, fill='--phosphor')
    f.text(xs[5] + w / 2, y - 28, T('role', 'pipeline'), size=10, fill='--phosphor')
    f.text(xs[5] + w / 2, y + 66, 'plan.bin', size=9.5, mono=True, fill='--paper-dim')
    # the road around
    f.rect(8, 200, 140, 46, stroke='--amber', fill='--panel', dash='4 3')
    f.text(78, 216, T('a person\'s own', 'as credenciais'), size=10)
    f.text(78, 232, T('credentials', 'da própria pessoa'), size=10)
    f.arrow([(150, 223), (ax + 35, 223), (ax + 35, y + 62)], stroke='--amber', dash='5 4')
    f.text(400, 208, T('the road around the road', 'o caminho em volta do caminho'), size=10.5,
           fill='--amber', weight='600')
    f.text(400, 240, T('closed by taking write access away; found by lesson 16',
                       'fechado tirando o acesso de escrita; achado pela aula 16'), size=9.5,
           fill='--paper-dim', italic=True)
    return f, T('Every stage can stop a change, and the cheap ones come first. None of them stops a '
                'change that never enters the road.',
                'Toda etapa pode parar uma mudança, e as baratas vêm primeiro. Nenhuma delas para uma '
                'mudança que nunca entra no caminho.')
