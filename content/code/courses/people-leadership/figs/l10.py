"""Lesson 10: where feedback becomes a performance conversation."""
from figures import Fig, T, figure


@figure('l10-line', 10)
def line():
    f = Fig('l10-line', 720, 270, T(
        'Three questions in sequence. Has it happened more than once? If not, it is a moment: give '
        'feedback. Has the person had clear feedback about it? If not, give clear feedback first. '
        'Does it affect what the role requires? If not, it is a preference, worth mentioning and no '
        'more. Only when all three answers are yes is it a performance conversation.',
        'Três perguntas em sequência. Aconteceu mais de uma vez? Se não, é um momento: dê feedback. A '
        'pessoa já recebeu feedback claro sobre isso? Se não, dê feedback claro primeiro. Afeta o que '
        'o cargo exige? Se não, é uma preferência, vale mencionar e nada mais. Só quando as três '
        'respostas são sim é uma conversa de desempenho.'))
    qs = [T('happened more', 'aconteceu mais'), T('than once?', 'de uma vez?'),
          T('clear feedback', 'feedback claro'), T('already given?', 'já foi dado?'),
          T('affects what the', 'afeta o que'), T('role requires?', 'o cargo exige?')]
    nos = [[T('a moment:', 'um momento:'), T('give feedback', 'dê feedback')],
           [T('give clear', 'dê feedback'), T('feedback first', 'claro primeiro')],
           [T('a preference:', 'uma preferência:'), T('mention it', 'mencione')]]
    for i in range(3):
        x = 30 + i * 175
        f.rect(x, 40, 140, 60, stroke='--paper-dim', fill='--panel', rx=6)
        f.lines(x + 70, 70, [qs[2 * i], qs[2 * i + 1]], size=11.5, weight='600')
        f.arrow([(x + 144, 70), (x + 171, 70)], stroke='--phosphor')
        f.text(x + 157, 58, T('yes', 'sim'), size=10, fill='--phosphor', weight='600')
        f.arrow([(x + 70, 104), (x + 70, 150)], stroke='--paper-dim')
        f.text(x + 80, 128, T('no', 'não'), size=10, fill='--paper-dim', weight='600', anchor='start')
        f.rect(x, 154, 140, 50, stroke='--wire', fill='--panel', rx=6)
        f.lines(x + 70, 179, nos[i], size=11)
    f.rect(555, 30, 140, 80, stroke='--amber', fill='--panel', width=1.8, rx=6)
    f.lines(625, 70, [T('a performance', 'uma conversa'), T('conversation', 'de desempenho')], size=12,
            weight='600', fill='--amber')
    f.text(360, 240, T('all three yes, and only then', 'as três com sim, e só então'), size=11,
           fill='--paper-dim', italic=True)
    return f, T('A pattern, after clear feedback, that touches the role. Missing any one of the three, it is still feedback.',
                'Um padrão, depois de feedback claro, que toca o cargo. Faltando qualquer uma das três, ainda é feedback.')
