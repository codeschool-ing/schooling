"""Lesson 6: questions with edges."""
from figures import Fig, T, figure


@figure('l06-edges', 6)
def edges():
    f = Fig('l06-edges', 720, 290, T(
        'Three questions and the answers they tend to get. “How’s it going?”, a question with no '
        'edges, gets “Fine.” “What was the worst moment of your last on-call week?”, bounded in '
        'time, gets a specific event: the three o’clock page for an alert nobody had explained. '
        '“From one to ten, how ready did you feel? What would make it one higher?” gets a number '
        'and something concrete to change: a runbook page, and somebody to call.',
        'Três perguntas e as respostas que costumam receber. “Como estão as coisas?”, uma pergunta '
        'sem contornos, recebe “Tudo bem.” “Qual foi o pior momento da sua última semana de '
        'plantão?”, limitada no tempo, recebe um acontecimento específico: o alerta das três da '
        'manhã que ninguém tinha explicado. “De um a dez, quão preparado você se sentiu? O que '
        'faria subir um ponto?” recebe um número e algo concreto a mudar: uma página no runbook, e '
        'alguém para quem ligar.'))
    rows = [
        (T('no edges', 'sem contornos'), [T('“How’s it going?”', '“Como estão as coisas?”')],
         [T('“Fine.”', '“Tudo bem.”')], '--paper-dim'),
        (T('bounded in time', 'limitada no tempo'),
         [T('“What was the worst moment', '“Qual foi o pior momento'),
          T('of your last on-call week?”', 'da sua última semana de plantão?”')],
         [T('the 3 a.m. page for an alert', 'o alerta das 3 da manhã'),
          T('nobody had explained', 'que ninguém tinha explicado')], '--amber'),
        (T('scaled, with a follow-up', 'em escala, com seguimento'),
         [T('“One to ten, how ready were you?', '“De um a dez, quão preparado?'),
          T('What would make it one higher?”', 'O que faria subir um ponto?”')],
         [T('“Three. A runbook page,', '“Três. Uma página no runbook,'),
          T('and somebody to call.”', 'e alguém para quem ligar.”')], '--phosphor'),
    ]
    for i, (kind, q, a, col) in enumerate(rows):
        y = 30 + i * 88
        f.text(30, y + 8, kind, size=10.5, anchor='start', fill=col if col != '--paper-dim' else '--paper-dim',
               weight='600')
        f.rect(30, y + 20, 290, 50, stroke=col, fill='--panel', rx=5)
        f.lines(175, y + 45, q, size=11)
        f.arrow([(330, y + 45), (390, y + 45)], stroke='--paper-dim')
        f.rect(400, y + 20, 290, 50, stroke='--wire', fill='--panel', rx=5)
        f.lines(545, y + 45, a, size=11, italic=True)
    return f, T('Edges give the person something to search for instead of something to summarise.',
                'Contornos dão à pessoa algo para procurar, em vez de algo para resumir.')
