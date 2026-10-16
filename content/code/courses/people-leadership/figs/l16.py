"""Lesson 16: three technical interview formats."""
from figures import Fig, T, figure


@figure('l16-formats', 16)
def formats():
    f = Fig('l16-formats', 720, 290, T(
        'Three columns, one per format, each split into what it measures well and what else it '
        'measures. Take-home: well, how the person writes code with time to think; also, how much '
        'free time they have. Pairing: well, how they work on code with somebody else; also, comfort '
        'with being observed. Live coding: well, producing code quickly from a cold start; also, '
        'performance under pressure and practice at this style of problem.',
        'Três colunas, uma por formato, cada uma dividida entre o que mede bem e o que mais mede. '
        'Desafio em casa: bem, como a pessoa escreve código com tempo para pensar; também, quanto '
        'tempo livre ela tem. Pareamento: bem, como trabalha em código com outra pessoa; também, '
        'conforto em ser observada. Live coding: bem, produzir código rápido partindo do zero; '
        'também, desempenho sob pressão e prática nesse estilo de problema.'))
    cols = [
        (T('take-home', 'desafio em casa'),
         [T('code written with', 'código escrito com'), T('time to think', 'tempo para pensar')],
         [T('how much free', 'quanto tempo livre'), T('time they have', 'a pessoa tem')]),
        (T('pairing', 'pareamento'),
         [T('working on code', 'trabalhar em código'), T('with somebody else', 'com outra pessoa')],
         [T('comfort with', 'conforto em'), T('being observed', 'ser observada')]),
        (T('live coding', 'live coding'),
         [T('code fast from', 'código rápido'), T('a cold start', 'partindo do zero')],
         [T('pressure, and practice', 'pressão, e prática'), T('at this kind of puzzle', 'nesse tipo de problema')]),
    ]
    for i, (name, good, also) in enumerate(cols):
        x = 30 + i * 230
        f.text(x + 100, 24, name, size=13, weight='600')
        f.rect(x, 40, 200, 100, stroke='--phosphor', fill='--panel', rx=5)
        f.text(x + 12, 58, T('measures well', 'mede bem'), size=10, anchor='start',
               fill='--phosphor', weight='600')
        f.lines(x + 100, 100, good, size=11.5, gap=17)
        f.rect(x, 150, 200, 100, stroke='--amber', fill='--panel', rx=5)
        f.text(x + 12, 168, T('also measures', 'também mede'), size=10, anchor='start',
               fill='--amber', weight='600')
        f.lines(x + 100, 210, also, size=11.5, gap=17)
    f.text(360, 276, T('every format measures something besides the job',
                       'todo formato mede algo além do trabalho'), size=11, fill='--paper-dim',
           italic=True)
    return f, T('Choosing a format is choosing which incidental thing you are willing to measure.',
                'Escolher um formato é escolher que coisa acidental você aceita medir.')
