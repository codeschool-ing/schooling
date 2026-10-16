"""Lesson 4: autonomy against alignment."""
from figures import Fig, T, figure


@figure('l04-axes', 4)
def axes():
    f = Fig('l04-axes', 720, 360, T(
        'A two-by-two grid. The horizontal axis is autonomy, low to high; the vertical axis is '
        'alignment, low to high. Bottom left, low on both: told what to do without knowing why. Top '
        'left, high alignment and low autonomy: the goal and the solution both come from the '
        'manager. Bottom right, low alignment and high autonomy: everybody free, nobody pulling the '
        'same way. Top right, high on both: aligned autonomy, where the manager explains the problem '
        'and the team finds the solution.',
        'Uma grade de dois por dois. O eixo horizontal é autonomia, de baixa a alta; o vertical é '
        'alinhamento, de baixo a alto. Embaixo à esquerda, baixos nos dois: recebe ordens sem saber '
        'por quê. Em cima à esquerda, alinhamento alto e autonomia baixa: o objetivo e a solução vêm '
        'da gestão. Embaixo à direita, alinhamento baixo e autonomia alta: todo mundo livre, '
        'ninguém puxando para o mesmo lado. Em cima à direita, altos nos dois: autonomia alinhada, '
        'em que a gestão explica o problema e o time encontra a solução.'))
    x0, y0, w, h = 110, 30, 270, 135
    cells = [
        (0, 0, T('the goal and the solution', 'o objetivo e a solução'),
         T('both come from the manager', 'vêm os dois da gestão'), '“build this bridge, this way”',
         '“construam esta ponte, assim”', '--paper-dim'),
        (1, 0, T('aligned autonomy', 'autonomia alinhada'),
         T('the manager explains the problem', 'a gestão explica o problema'),
         '“we need to cross; this is why”', '“precisamos atravessar; eis o porquê”', '--phosphor'),
        (0, 1, T('told what to do', 'recebe ordens'), T('without knowing why', 'sem saber por quê'),
         '“do this”', '“faça isto”', '--paper-dim'),
        (1, 1, T('everybody free', 'todo mundo livre'),
         T('nobody pulling the same way', 'ninguém puxando junto'),
         '“do what you think best”', '“façam o que acharem melhor”', '--amber'),
    ]
    for cx, cy, a, b, qen, qpt, col in cells:
        x, y = x0 + cx * (w + 10), y0 + cy * (h + 10)
        f.rect(x, y, w, h, stroke=col, fill='--panel', width=1.6 if col != '--paper-dim' else 1.2,
               rx=6)
        f.text(x + w / 2, y + 42, a, size=13, weight='600',
               fill=col if col != '--paper-dim' else '--paper')
        f.text(x + w / 2, y + 64, b, size=11)
        f.text(x + w / 2, y + 98, T(qen, qpt), size=11, fill='--paper-dim', italic=True)
    f.arrow([(x0, y0 + 2 * h + 30), (x0 + 2 * w + 10, y0 + 2 * h + 30)], stroke='--paper-dim')
    f.text(x0 + w + 5, y0 + 2 * h + 46, T('autonomy', 'autonomia'), size=11.5, weight='600')
    f.arrow([(x0 - 22, y0 + 2 * h + 10), (x0 - 22, y0)], stroke='--paper-dim')
    f.text(x0 - 40, y0 + h + 5, T('alignment', 'alinhamento'), size=11.5, weight='600',
           anchor='end')
    return f, T('After Henrik Kniberg’s drawing. The two axes are independent: more autonomy is paid for with a clearer goal, not with less alignment.',
                'A partir do desenho de Henrik Kniberg. Os dois eixos são independentes: mais autonomia se paga com um objetivo mais claro, não com menos alinhamento.')


@figure('l04-gaps', 4)
def gaps():
    f = Fig('l04-gaps', 720, 290, T(
        'Three boxes in a triangle: plans at the top, actions at the bottom left, outcomes at the '
        'bottom right. Between plans and outcomes is the knowledge gap: what we would like to know '
        'against what we do know. Between plans and actions is the alignment gap: what we want '
        'people to do against what they do. Between actions and outcomes is the effects gap: what '
        'we expect our actions to achieve against what they achieve.',
        'Três caixas em triângulo: planos em cima, ações embaixo à esquerda, resultados embaixo à '
        'direita. Entre planos e resultados está a lacuna de conhecimento: o que gostaríamos de '
        'saber contra o que sabemos. Entre planos e ações está a lacuna de alinhamento: o que '
        'queremos que as pessoas façam contra o que fazem. Entre ações e resultados está a lacuna '
        'de efeitos: o que esperamos que as ações alcancem contra o que alcançam.'))
    boxes = {'plans': (360, 50, T('plans', 'planos')),
             'actions': (150, 230, T('actions', 'ações')),
             'outcomes': (570, 230, T('outcomes', 'resultados'))}
    for x, y, lab in boxes.values():
        f.rect(x - 70, y - 20, 140, 40, stroke='--paper-dim', fill='--panel', rx=5)
        f.text(x, y, lab, size=13, weight='600')
    f.line(290, 62, 200, 210, stroke='--amber', width=1.4, dash='5 4')
    f.line(430, 62, 520, 210, stroke='--amber', width=1.4, dash='5 4')
    f.line(220, 230, 500, 230, stroke='--amber', width=1.4, dash='5 4')
    f.text(212, 120, T('alignment gap', 'lacuna de alinhamento'), size=12, weight='600',
           anchor='end', fill='--amber')
    f.text(212, 138, T('what we want done', 'o que queremos que façam'), size=10.5, anchor='end')
    f.text(212, 154, T('against what is done', 'contra o que é feito'), size=10.5, anchor='end')
    f.text(508, 120, T('knowledge gap', 'lacuna de conhecimento'), size=12, weight='600',
           anchor='start', fill='--amber')
    f.text(508, 138, T('what we would like to know', 'o que gostaríamos de saber'), size=10.5,
           anchor='start')
    f.text(508, 154, T('against what we know', 'contra o que sabemos'), size=10.5,
           anchor='start')
    f.text(360, 200, T('effects gap', 'lacuna de efeitos'), size=12, weight='600', fill='--amber')
    f.text(360, 256, T('what we expect our actions to achieve', 'o que esperamos que as ações alcancem'),
           size=10.5)
    f.text(360, 272, T('against what they achieve', 'contra o que alcançam'), size=10.5)
    return f, T('Stephen Bungay’s three gaps. The instinct in front of each is more detail, and more detail widens all three.',
                'As três lacunas de Stephen Bungay. O instinto diante de cada uma é mais detalhe, e mais detalhe alarga as três.')
