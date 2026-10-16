"""Lesson 5: the shape of one-to-ones over months."""
from figures import Fig, T, figure


@figure('l05-months', 5)
def months():
    f = Fig('l05-months', 720, 320, T(
        'Four stacked bars showing how the time in a one-to-one tends to be spent, in the first '
        'month, the third, the sixth and the twelfth. In the first month most of it goes on getting '
        'to know each other and on immediate obstacles. By the twelfth month obstacles take a '
        'smaller share, getting to know each other has almost gone, and growth, how the person is, '
        'and feedback in both directions take most of the time. A sketch of a typical pattern, not '
        'a measurement.',
        'Quatro barras empilhadas mostrando como o tempo de uma 1:1 tende a ser gasto no primeiro '
        'mês, no terceiro, no sexto e no décimo segundo. No primeiro mês a maior parte vai para se '
        'conhecerem e para obstáculos imediatos. No décimo segundo, os obstáculos ocupam uma fatia '
        'menor, o se conhecer quase sumiu, e crescimento, como a pessoa está e feedback nos dois '
        'sentidos ocupam a maior parte do tempo. Um esboço de um padrão típico, não uma medida.'))
    cats = [(T('getting to know each other', 'conhecer um ao outro'), '--paper-dim'),
            (T('obstacles', 'obstáculos'), '--amber'),
            (T('how they are', 'como a pessoa está'), '--scan'),
            (T('growth', 'crescimento'), '--phosphor'),
            (T('feedback, both ways', 'feedback, nos dois sentidos'), '--wire')]
    shares = [[40, 40, 10, 5, 5], [15, 40, 15, 15, 15], [5, 30, 20, 25, 20], [0, 25, 20, 30, 25]]
    labels = [T('month 1', 'mês 1'), T('month 3', 'mês 3'), T('month 6', 'mês 6'),
              T('month 12', 'mês 12')]
    x0, bw, gap, top, H = 60, 80, 34, 30, 230
    for i, (sh, lab) in enumerate(zip(shares, labels)):
        x = x0 + i * (bw + gap)
        y = top
        for (name, col), s in zip(cats, sh):
            if s == 0:
                continue
            h = H * s / 100
            f.rect(x, y, bw, h, stroke='--paper-dim', fill=col, width=0.8, rx=0)
            y += h
        f.text(x + bw / 2, top + H + 18, lab, size=11, weight='600')
    lx = x0 + 4 * (bw + gap) + 10
    for j, (name, col) in enumerate(cats):
        y = top + 30 + j * 34
        f.rect(lx, y - 9, 18, 18, stroke='--paper-dim', fill=col, width=0.8, rx=2)
        f.text(lx + 28, y, name, size=11.5, anchor='start')
    f.text(lx, top + H + 18, T('a sketch, not a measurement', 'um esboço, não uma medida'),
           size=10.5, anchor='start', fill='--paper-dim', italic=True)
    return f, T('What a one-to-one holds changes as trust builds. Feedback that lands in month 12 would be heard as an attack in week 2.',
                'O que uma 1:1 contém muda conforme a confiança cresce. Um feedback que funciona no mês 12 soaria como ataque na semana 2.')
