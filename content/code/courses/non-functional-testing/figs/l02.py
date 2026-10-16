"""Lesson 2: load, stress, spike, soak and scalability."""
from figures import Fig, T, figure


def axes(f, x, y, w, h, xlabel):
    f.line(x, y + h, x + w, y + h, stroke='--wire', width=1.1)
    f.line(x, y, x, y + h, stroke='--wire', width=1.1)
    f.text(x + w, y + h + 11, xlabel, size=9, anchor='end', fill='--paper-dim')


def poly(f, pts, **kw):
    f.path('M' + ' L'.join(f'{a:.1f} {b:.1f}' for a, b in pts), **kw)


@figure('l02-shapes', 2)
def shapes():
    f = Fig('l02-shapes', 720, 440, T(
        'Five tests drawn as load against time, one row each. Load test: a ramp up to the expected '
        'load, a long flat hold, a ramp down; it passes when the requirement holds for the whole '
        'hold. Stress test: steps that keep climbing past the expected load; it is read for where '
        'and how it breaks, and whether it recovers. Spike test: a flat normal load, a sudden jump '
        'to many times it for a short while, and back; it passes when errors stay bounded and the '
        'times come back to normal soon after. Soak test: the expected load held flat for hours; '
        'it passes when nothing drifts, the times at the end matching the times at the start. '
        'Scalability test: the same climbing steps run twice, with one share of resources and then '
        'with twice as much; it passes when the second run carries about twice the throughput.',
        'Cinco testes desenhados como carga contra o tempo, um por linha. Teste de carga: uma rampa '
        'até a carga esperada, um patamar longo, uma rampa de descida; passa quando o requisito se '
        'mantém durante todo o patamar. Teste de estresse: degraus que continuam subindo além da '
        'carga esperada; é lido por onde e como ele quebra, e se se recupera. Teste de pico: uma '
        'carga normal e plana, um salto repentino para muitas vezes ela por pouco tempo, e a volta; '
        'passa quando os erros ficam limitados e os tempos voltam ao normal logo depois. Teste de '
        'resistência: a carga esperada mantida plana por horas; passa quando nada deriva, os tempos '
        'do fim iguais aos do começo. Teste de escalabilidade: os mesmos degraus subindo, rodados '
        'duas vezes, com uma porção de recursos e depois com o dobro; passa quando a segunda rodada '
        'carrega mais ou menos o dobro da vazão.'))
    f.text(105, 18, T('the test and its question', 'o teste e a sua pergunta'), size=10,
           weight='600', fill='--paper-dim')
    f.text(340, 18, T('load against time', 'carga contra o tempo'), size=10, weight='600',
           fill='--paper-dim')
    f.text(600, 18, T('it passes when', 'passa quando'), size=10, weight='600', fill='--paper-dim')
    rows = [
        (T('load', 'carga'), [T('does it meet the requirement', 'atende ao requisito'),
                              T('at the expected load?', 'na carga esperada?')],
         [T('the thresholds hold for', 'os limites valem durante'),
          T('the whole hold', 'todo o patamar')], T('minutes', 'minutos')),
        (T('stress', 'estresse'), [T('where does it break, how,', 'onde ele quebra, como,'),
                                   T('and does it come back?', 'e ele volta?')],
         [T('no fixed pass: the result is', 'não há aprovação fixa: o resultado'),
          T('the breaking point and the manner', 'é o ponto e o jeito da quebra')], T('minutes', 'minutos')),
        (T('spike', 'pico'), [T('does it survive a sudden', 'aguenta uma multidão'),
                              T('crowd, and recover after?', 'repentina, e se recupera?')],
         [T('errors stay bounded, times are', 'erros limitados, tempos de volta'),
          T('normal again soon after', 'ao normal logo depois')], T('minutes', 'minutos')),
        (T('soak', 'resistência'), [T('does anything grow or', 'algo cresce ou'),
                                    T('drift with time?', 'deriva com o tempo?')],
         [T('the last hour looks like', 'a última hora se parece'),
          T('the first one', 'com a primeira')], T('hours', 'horas')),
        (T('scalability', 'escalabilidade'), [T('do more resources carry', 'mais recursos carregam'),
                                              T('more load?', 'mais carga?')],
         [T('twice the resources give close', 'o dobro de recursos dá perto'),
          T('to twice the throughput', 'do dobro da vazão')], T('minutes', 'minutos')),
    ]
    top, rh = 40, 80
    for i, (name, q, ok, unit) in enumerate(rows):
        y = top + i * rh
        if i:
            f.line(20, y - 6, 700, y - 6, stroke='--wire', width=0.6, dash='2 4')
        f.text(30, y + 14, name, size=11.5, weight='600', anchor='start')
        f.lines(30, y + 41, q, size=9.5, anchor='start', fill='--paper-dim', gap=13)
        x0, y0, w, h = 230, y + 6, 220, 50
        axes(f, x0, y0, w, h, unit)
        b, hi = y0 + h, y0 + 16
        if i == 0:
            pts = [(x0, b), (x0 + 40, hi), (x0 + 180, hi), (x0 + 210, b)]
            f.line(x0, hi, x0 + w, hi, stroke='--amber', width=1, dash='4 3')
            f.text(x0 + w + 4, hi, T('expected', 'esperada'), size=8.5, anchor='start', fill='--amber')
        elif i == 1:
            pts, lv = [(x0, b)], b
            for k in range(6):
                lv = b - 8 * (k + 1)
                pts += [(x0 + k * 35, lv), (x0 + (k + 1) * 35, lv)]
            pts += [(x0 + 210, lv)]
            f.line(x0, b - 24, x0 + w, b - 24, stroke='--amber', width=1, dash='4 3')
            f.text(x0 + w + 4, b - 24, T('expected', 'esperada'), size=8.5, anchor='start', fill='--amber')
        elif i == 2:
            lo, top2 = b - 12, y0 + 1
            pts = [(x0, lo), (x0 + 90, lo), (x0 + 95, top2), (x0 + 125, top2), (x0 + 130, lo),
                   (x0 + 215, lo)]
        elif i == 3:
            pts = [(x0, b), (x0 + 15, hi), (x0 + 205, hi), (x0 + 215, b)]
        else:
            pts = [(x0, b)]
            for a in (0, 115):
                pts += [(x0 + a, b)]
                for k in range(4):
                    lv = b - 10 * (k + 1)
                    pts += [(x0 + a + k * 24, lv), (x0 + a + (k + 1) * 24, lv)]
                pts += [(x0 + a + 96, b)]
            f.text(x0 + 48, y0 + 2, T('×1 resources', '×1 recursos'), size=8.5, fill='--paper-dim')
            f.text(x0 + 163, y0 + 2, T('×2 resources', '×2 recursos'), size=8.5, fill='--paper-dim')
        poly(f, pts, stroke='--phosphor', width=2)
        f.lines(520, y + 28, ok, size=9.5, anchor='start', gap=13)
    return f, T('The five tests by the load each one applies. The shape is what tells them apart; the '
                'tool and the script can be the same.',
                'Os cinco testes pela carga que cada um aplica. É a forma que os distingue; a '
                'ferramenta e o script podem ser os mesmos.')


def chart(f, x0, y0, w, h, n, ymax, ystep, xlabel, ylabel):
    f.line(x0, y0 + h, x0 + w, y0 + h, stroke='--wire', width=1.1)
    f.line(x0, y0, x0, y0 + h, stroke='--wire', width=1.1)
    for v in range(0, ymax + 1, ystep):
        yy = y0 + h - h * v / ymax
        f.line(x0 - 4, yy, x0, yy, stroke='--wire', width=1)
        f.text(x0 - 7, yy, str(v), size=9, anchor='end', mono=True, fill='--paper-dim')
        if v:
            f.line(x0, yy, x0 + w, yy, stroke='--wire', width=0.5, dash='2 4')
    for s in range(n):
        f.text(x0 + w * (s + 0.5) / n, y0 + h + 12, str(s), size=9, mono=True, fill='--paper-dim')
    f.text(x0 + w / 2, y0 + h + 28, xlabel, size=9.5, fill='--paper-dim')
    f.text(x0 - 34, y0 + h / 2, ylabel, size=9.5, fill='--paper-dim')

    def at(s, v):
        return x0 + w * (s + 0.5) / n, y0 + h - h * v / ymax
    return at


# From the "stress" transcript of "Three shapes on the box office".
STRESS_SENT = [40, 40, 80, 80, 120, 120, 160, 160, 200, 200, 240, 240]
STRESS_DONE = [39, 41, 75, 73, 76, 69, 83, 90, 100, 113, 139, 79]
STRESS_ERR = [0, 0, 0, 0, 0, 3, 16, 20, 29, 17, 23, 26]


@figure('l02-stress', 2)
def stress():
    f = Fig('l02-stress', 720, 300, T(
        'The stress run drawn second by second. The requests sent climb in steps from 40 to 240 a '
        'second. The answers that came back follow them up to 75 a second at second 2, then stop '
        'following: between 69 and 139 a second for the rest of the run, whatever was sent. Errors '
        'start at second 5 with 3, and are between 16 and 29 a second from second 6 on.',
        'A rodada de estresse desenhada segundo a segundo. As requisições enviadas sobem em degraus '
        'de 40 a 240 por segundo. As respostas que voltaram as acompanham até 75 por segundo no '
        'segundo 2, depois param de acompanhar: entre 69 e 139 por segundo no resto da rodada, '
        'qualquer que fosse o envio. Os erros começam no segundo 5 com 3, e ficam entre 16 e 29 por '
        'segundo do segundo 6 em diante.'))
    x0, y0, w, h, n = 90, 30, 480, 210, len(STRESS_SENT)
    at = chart(f, x0, y0, w, h, n, 250, 50, T('second of the run', 'segundo da rodada'),
               T('per second', 'por segundo'))
    bw = w / n * 0.5
    for s, e in enumerate(STRESS_ERR):
        if e:
            x, yy = at(s, e)
            f.rect(x - bw / 2, yy, bw, y0 + h - yy, stroke=None, fill='--amber', rx=1)
    sent = []
    for s, v in enumerate(STRESS_SENT):
        x = x0 + w * s / n
        sent += [(x, at(s, v)[1]), (x + w / n, at(s, v)[1])]
    poly(f, sent, stroke='--paper-dim', width=1.6, dash='5 3')
    poly(f, [at(s, v) for s, v in enumerate(STRESS_DONE)], stroke='--phosphor', width=2.2)
    for s, v in enumerate(STRESS_DONE):
        f.circle(*at(s, v), 3)
    lx = x0 + w + 18
    f.line(lx, 60, lx + 22, 60, stroke='--paper-dim', width=1.6, dash='5 3')
    f.text(lx + 28, 60, T('sent', 'enviadas'), size=10, anchor='start')
    f.line(lx, 84, lx + 22, 84, stroke='--phosphor', width=2.2)
    f.text(lx + 28, 84, T('done: the throughput', 'done: a vazão'), size=10, anchor='start')
    f.rect(lx + 5, 102, 12, 12, stroke=None, fill='--amber', rx=1)
    f.text(lx + 28, 108, T('errors', 'erros'), size=10, anchor='start')
    f.lines(lx, 160, [T('from second 3 the', 'do segundo 3 em diante'),
                      T('answers stop following', 'as respostas param de'),
                      T('what was sent', 'acompanhar o envio')], size=9.5, anchor='start',
            fill='--paper-dim')
    return f, T('What the stress run sent, what came back, and what failed, second by second. The gap '
                'between the dashed line and the solid one is a queue growing inside the server.',
                'O que a rodada de estresse enviou, o que voltou e o que falhou, segundo a segundo. A '
                'distância entre a linha tracejada e a contínua é uma fila crescendo dentro do servidor.')


# From "scale-one" and "scale-two" in "Adding processors".
SCALE_SENT = [20, 20, 40, 40, 60, 60, 80, 80]
SCALE_ONE = [20, 20, 40, 39, 51, 48, 46, 47]
SCALE_TWO = [20, 20, 40, 40, 59, 60, 77, 79]


@figure('l02-scale', 2)
def scale():
    f = Fig('l02-scale', 720, 290, T(
        'The same stepped load, 20 to 80 requests a second, against the box office on one processor '
        'and then on two. Both carry 20 and 40 a second. On one processor the answers stop at 51, '
        '48, 46 and 47 a second while 60 and then 80 are sent. On two they reach 59, 60, 77 and 79, '
        'close to everything sent.',
        'A mesma carga em degraus, de 20 a 80 requisições por segundo, contra a bilheteria com um '
        'processador e depois com dois. Os dois carregam 20 e 40 por segundo. Com um processador as '
        'respostas param em 51, 48, 46 e 47 por segundo enquanto 60 e depois 80 são enviadas. Com '
        'dois elas chegam a 59, 60, 77 e 79, perto de tudo o que foi enviado.'))
    x0, y0, w, h, n = 90, 30, 460, 200, len(SCALE_SENT)
    at = chart(f, x0, y0, w, h, n, 100, 20, T('second of the run', 'segundo da rodada'),
               T('per second', 'por segundo'))
    sent = []
    for s, v in enumerate(SCALE_SENT):
        x = x0 + w * s / n
        sent += [(x, at(s, v)[1]), (x + w / n, at(s, v)[1])]
    poly(f, sent, stroke='--paper-dim', width=1.6, dash='5 3')
    poly(f, [at(s, v) for s, v in enumerate(SCALE_TWO)], stroke='--phosphor', width=2.2)
    for s, v in enumerate(SCALE_TWO):
        f.circle(*at(s, v), 3)
    poly(f, [at(s, v) for s, v in enumerate(SCALE_ONE)], stroke='--amber', width=2.2)
    for s, v in enumerate(SCALE_ONE):
        f.circle(*at(s, v), 3, fill='--amber')
    lx = x0 + w + 20
    f.line(lx, 60, lx + 22, 60, stroke='--paper-dim', width=1.6, dash='5 3')
    f.text(lx + 28, 60, T('sent', 'enviadas'), size=10, anchor='start')
    f.line(lx, 84, lx + 22, 84, stroke='--phosphor', width=2.2)
    f.text(lx + 28, 84, T('done, 2 processors', 'done, 2 processadores'), size=10, anchor='start')
    f.line(lx, 108, lx + 22, 108, stroke='--amber', width=2.2)
    f.text(lx + 28, 108, T('done, 1 processor', 'done, 1 processador'), size=10, anchor='start')
    return f, T('Throughput against the same load, with one processor and with two. Where the line on '
                'one processor goes flat is that configuration\'s capacity.',
                'A vazão contra a mesma carga, com um processador e com dois. Onde a linha de um '
                'processador fica plana está a capacidade daquela configuração.')
