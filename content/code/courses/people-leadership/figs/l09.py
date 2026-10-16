"""Lesson 9: how much a piece of praise tells the person."""
from figures import Fig, T, figure


@figure('l09-information', 9)
def information():
    f = Fig('l09-information', 720, 280, T(
        'Three pieces of praise for the same incident summary, with what each tells the person. '
        '“Great job!” tells them only that something was liked. “Great incident summary” tells them '
        'which piece of work. The specific version, saying they led with what clinics experienced '
        'and put the cause last, and that two clinic owners replied with no follow-up questions, '
        'tells them what to repeat, that it worked, and how anybody could tell.',
        'Três elogios ao mesmo resumo de incidente, com o que cada um diz à pessoa. “Ótimo '
        'trabalho!” diz só que algo agradou. “Ótimo resumo do incidente” diz qual trabalho. A versão '
        'específica, dizendo que ela abriu com o que as clínicas viveram e deixou a causa por último, '
        'e que dois donos de clínica responderam sem nenhuma pergunta, diz o que repetir, que '
        'funcionou e como alguém poderia saber.'))
    rows = [
        ([T('“Great job!”', '“Ótimo trabalho!”')], 1, [T('something was liked', 'algo agradou')]),
        ([T('“Great incident summary.”', '“Ótimo resumo do incidente.”')], 2,
         [T('something was liked', 'algo agradou'), T('which piece of work', 'qual trabalho')]),
        ([T('“You led with what the clinics', '“Você abriu com o que as clínicas'),
          T('experienced and put the cause last.', 'viveram e deixou a causa por último.'),
          T('Two owners replied, and nobody', 'Dois donos responderam, e ninguém'),
          T('asked a follow-up question.”', 'fez nenhuma pergunta.”')], 5,
         [T('something was liked', 'algo agradou'), T('which piece of work', 'qual trabalho'),
          T('what to do again', 'o que fazer de novo'), T('that it worked', 'que funcionou'),
          T('how anybody could tell', 'como alguém saberia')]),
    ]
    y = 22
    for quote, n, tells in rows:
        h = max(len(quote), len(tells)) * 17 + 18
        f.rect(30, y, 290, h, stroke='--paper-dim', fill='--panel', rx=5)
        f.lines(175, y + h / 2, quote, size=11, gap=17, italic=True)
        f.arrow([(330, y + h / 2), (380, y + h / 2)], stroke='--paper-dim')
        for k in range(5):
            f.circle(400 + k * 16, y + h / 2, 5.5, fill='--phosphor' if k < n else None,
                     stroke='--paper-dim' if k >= n else None, width=1)
        f.lines(490, y + h / 2, tells, size=11, gap=17, anchor='start')
        y += h + 14
    return f, T('The same moment of praise, carrying one thing, two, or five.',
                'O mesmo momento de elogio, carregando uma coisa, duas ou cinco.')
