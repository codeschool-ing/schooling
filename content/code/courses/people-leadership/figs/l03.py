"""Lesson 3: seven levels of delegation."""
from figures import Fig, T, figure


@figure('l03-ladder', 3)
def ladder():
    f = Fig('l03-ladder', 720, 300, T(
        'Seven steps rising from left to right: tell, sell, consult, agree, advise, inquire, '
        'delegate. Under the first three a bar reads “the manager decides”; under the fourth, '
        '“both agree”; under the last three, “the person decides”. An arrow along the bottom '
        'says authority moves from the manager to the person as you climb.',
        'Sete degraus subindo da esquerda para a direita: dizer, vender, consultar, concordar, '
        'aconselhar, perguntar, delegar. Sob os três primeiros uma barra diz “a gestora decide”; '
        'sob o quarto, “as duas”; sob os três últimos, “a pessoa decide”. Uma '
        'seta embaixo diz que a autoridade passa da gestora para a pessoa conforme se sobe.'))
    names = [T('tell', 'dizer'), T('sell', 'vender'), T('consult', 'consultar'),
             T('agree', 'concordar'), T('advise', 'aconselhar'), T('inquire', 'perguntar'),
             T('delegate', 'delegar')]
    x0, w, base = 40, 92, 200
    for i, n in enumerate(names):
        h = 30 + i * 20
        x = x0 + i * w
        col = '--amber' if i < 3 else ('--paper-dim' if i == 3 else '--phosphor')
        f.rect(x + 2, base - h, w - 4, h, stroke=col, fill='--panel', width=1.5, rx=3)
        f.text(x + w / 2, base - h + 16, str(i + 1), size=12, weight='600', fill=col)
        f.text(x + w / 2, base - h - 12, n, size=11.5, weight='600')
    f.rect(x0 + 2, 214, 3 * w - 4, 24, stroke='--amber', fill='--panel', rx=3)
    f.text(x0 + 1.5 * w, 226, T('the manager decides', 'a gestora decide'), size=10.5)
    f.rect(x0 + 3 * w + 2, 214, w - 4, 24, stroke='--paper-dim', fill='--panel', rx=3)
    f.text(x0 + 3.5 * w, 226, T('both agree', 'as duas'), size=10.5)
    f.rect(x0 + 4 * w + 2, 214, 3 * w - 4, 24, stroke='--phosphor', fill='--panel', rx=3)
    f.text(x0 + 5.5 * w, 226, T('the person decides', 'a pessoa decide'), size=10.5)
    f.arrow([(x0 + 10, 268), (x0 + 7 * w - 10, 268)], stroke='--paper-dim', width=1.4)
    f.text(x0 + 3.5 * w, 284, T('authority moves across as you climb',
                                 'a autoridade muda de lado conforme se sobe'),
           size=10.5, fill='--paper-dim', italic=True)
    return f, T('Jurgen Appelo’s seven levels. The rung is chosen per decision, and it moves up as the person grows.',
                'Os sete níveis de Jurgen Appelo. O degrau é escolhido por decisão, e sobe conforme a pessoa cresce.')
