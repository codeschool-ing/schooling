"""Lesson 8: situation, behaviour, impact."""
from figures import Fig, T, figure


@figure('l08-sbi', 8)
def sbi():
    f = Fig('l08-sbi', 720, 300, T(
        'Three boxes left to right, joined by arrows. Situation: Tuesday, the review of Thiago’s '
        'calendar-sync pull request. Behaviour: the first comment was “this is wrong, redo it”, '
        'with nothing about what was wrong. Impact: Thiago pushed nothing for two days, and now asks '
        'Yara for reviews instead of Diego. Under the boxes, a line marks what is left out: '
        'adjectives about the person, and guesses about intent.',
        'Três caixas da esquerda para a direita, ligadas por setas. Situação: terça-feira, a revisão '
        'do pull request de sincronização de calendário do Thiago. Comportamento: o primeiro '
        'comentário foi “isso está errado, refaz”, sem nada sobre o que estava errado. Impacto: o '
        'Thiago não enviou nada por dois dias, e agora pede revisões à Yara em vez do Diego. Embaixo '
        'das caixas, uma linha marca o que fica de fora: adjetivos sobre a pessoa e palpites sobre '
        'a intenção.'))
    boxes = [
        (T('situation', 'situação'), T('when and where', 'quando e onde'),
         [T('Tuesday, the review of', 'terça, a revisão do'),
          T('Thiago’s calendar-sync', 'pull request de calendário'),
          T('pull request', 'do Thiago')], '--paper-dim'),
        (T('behaviour', 'comportamento'), T('what a camera saw', 'o que uma câmera veria'),
         [T('first comment: “this is', 'primeiro comentário: “isso'),
          T('wrong, redo it”, with', 'está errado, refaz”, sem'),
          T('nothing on what was wrong', 'nada sobre o que estava errado')], '--amber'),
        (T('impact', 'impacto'), T('what it caused', 'o que causou'),
         [T('Thiago pushed nothing for', 'o Thiago não enviou nada por'),
          T('two days, and now asks', 'dois dias, e agora pede'),
          T('Yara to review instead', 'revisão à Yara no lugar')], '--phosphor'),
    ]
    for i, (name, sub, body, col) in enumerate(boxes):
        x = 30 + i * 230
        f.rect(x, 40, 200, 170, stroke=col, fill='--panel', width=1.6, rx=6)
        f.text(x + 100, 64, name, size=14, weight='600', fill=col if col != '--paper-dim' else '--paper')
        f.text(x + 100, 84, sub, size=10.5, fill='--paper-dim', italic=True)
        f.lines(x + 100, 145, body, size=11, gap=17)
        if i < 2:
            f.arrow([(x + 204, 125), (x + 226, 125)], stroke='--paper-dim')
    f.line(30, 240, 690, 240, stroke='--wire', width=1.2, dash='4 4')
    f.text(360, 262, T('left out: adjectives about the person, and guesses about what they meant',
                       'fica de fora: adjetivos sobre a pessoa e palpites sobre a intenção dela'),
           size=11, fill='--paper-dim')
    return f, T('Each box is something the person can check against their own memory.',
                'Cada caixa é algo que a pessoa consegue conferir com a própria memória.')
