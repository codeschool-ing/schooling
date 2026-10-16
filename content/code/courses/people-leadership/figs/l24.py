"""Lesson 24: a manager in the middle."""
from figures import Fig, T, figure


@figure('l24-middle', 24)
def middle():
    f = Fig('l24-middle', 720, 300, T(
        'Renata at the centre. Above her, Otávio, her manager: what he needs is no surprises, problems '
        'with options, and her honest read. Beside her, her peers, Bia and the other managers: her first '
        'team, sharing the problems between teams. Below her, the Agenda team: what passes down is '
        'decisions carried as the team’s, and promises only about her own actions.',
        'A Renata no centro. Acima, o Otávio, gestor dela: o que ele precisa é nenhuma surpresa, '
        'problemas com opções, e a leitura honesta dela. Ao lado, as pares, a Bia e as outras gestoras: o '
        'primeiro time dela, que divide os problemas entre times. Abaixo, o time do Agenda: o que desce '
        'são decisões levadas como do time, e promessas só sobre as próprias ações dela.'))
    cx, cy = 360, 150
    f.rect(cx - 70, cy - 22, 140, 44, stroke='--phosphor', fill='--panel', width=1.8, rx=6)
    f.text(cx, cy, 'Renata', size=13, weight='600')
    f.rect(cx - 70, 20, 140, 36, stroke='--paper-dim', fill='--panel', rx=6)
    f.text(cx, 38, T('Otávio, her manager', 'Otávio, gestor dela'), size=11.5, weight='600')
    f.arrow([(cx, cy - 24), (cx, 60)], stroke='--paper-dim', start=True)
    f.lines(cx + 14, 92, [T('no surprises · problems with', 'nenhuma surpresa · problemas'),
                          T('options · her honest read', 'com opções · leitura honesta')],
            size=10.5, anchor='start')
    f.rect(20, cy - 18, 170, 36, stroke='--amber', fill='--panel', rx=6)
    f.text(105, cy, T('peers: Bia and others', 'pares: Bia e outras'), size=11.5, weight='600')
    f.arrow([(cx - 74, cy), (194, cy)], stroke='--amber', start=True)
    f.lines(105, cy + 36, [T('the first team:', 'o primeiro time:'),
                           T('problems between teams', 'problemas entre times')], size=10.5)
    f.rect(cx - 90, 244, 180, 36, stroke='--paper-dim', fill='--panel', rx=6)
    f.text(cx, 262, T('the Agenda team', 'o time do Agenda'), size=11.5, weight='600')
    f.arrow([(cx, cy + 24), (cx, 240)], stroke='--paper-dim')
    f.lines(cx + 14, 205, [T('decisions carried as the team’s ·', 'decisões levadas como do time ·'),
                           T('promises only about her own actions', 'promessas só sobre as próprias ações')],
            size=10.5, anchor='start')
    return f, T('The middle is where a manager carries the company’s decisions down and the team’s reality up.',
                'O meio é onde uma gestora leva as decisões da empresa para baixo e a realidade do time para cima.')
