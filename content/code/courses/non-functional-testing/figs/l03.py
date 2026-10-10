"""Lesson 3: modelling the load."""
from figures import Fig, T, figure


@figure('l03-models', 3)
def models():
    f = Fig('l03-models', 720, 290, T(
        'Two models side by side. On the left, the closed model: a fixed group of virtual users goes '
        'round a loop, sending a request to the server, waiting for the answer, thinking, and sending '
        'again; no more requests can be in flight than there are users, and a slow server slows the '
        'users down. On the right, the open model: requests arrive at a rate, so many a second, from '
        'outside, whether or not earlier ones have been answered; a slow server builds a queue in '
        'front of it, and nothing slows the arrivals.',
        'Dois modelos lado a lado. À esquerda, o modelo fechado: um grupo fixo de usuários virtuais '
        'dá voltas num laço, enviando uma requisição ao servidor, esperando a resposta, pensando e '
        'enviando de novo; não pode haver mais requisições em voo do que usuários, e um servidor lento '
        'deixa os usuários lentos. À direita, o modelo aberto: as requisições chegam a uma taxa, '
        'tantas por segundo, de fora, tenham as anteriores sido respondidas ou não; um servidor lento '
        'forma uma fila na frente dele, e nada desacelera as chegadas.'))
    # closed
    f.text(180, 22, T('closed: N virtual users', 'fechado: N usuários virtuais'), size=11.5, weight='600')
    f.rect(40, 70, 120, 120, stroke='--paper-dim', fill='--panel', width=1.3)
    for i in range(3):
        for j in range(3):
            f.circle(70 + 30 * j, 100 + 30 * i, 7, fill='--phosphor')
    f.text(100, 205, T('the users', 'os usuários'), size=10, fill='--paper-dim')
    f.rect(240, 95, 90, 70, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(285, 130, T('server', 'servidor'), size=11, weight='600')
    f.arrow([(160, 105), (238, 105)], stroke='--paper', width=1.3)
    f.text(199, 94, T('request', 'requisição'), size=9.5)
    f.arrow([(240, 155), (162, 155)], stroke='--paper', width=1.3)
    f.text(201, 168, T('answer', 'resposta'), size=9.5)
    f.path('M100 70 C100 40, 60 40, 60 58', stroke='--amber', width=1.3, arrow=True)
    f.text(118, 44, T('think, then again', 'pensa, e de novo'), size=9.5, anchor='start', fill='--amber')
    f.lines(180, 245, [T('a slow server slows the users:', 'um servidor lento desacelera os usuários:'),
                       T('never more in flight than N', 'nunca mais em voo do que N')], size=10,
            fill='--paper-dim')
    f.line(360, 30, 360, 270, stroke='--wire', width=1, dash='3 4')
    # open
    f.text(540, 22, T('open: λ arrivals a second', 'aberto: λ chegadas por segundo'), size=11.5, weight='600')
    for k in range(6):
        x = 395 + k * 16
        f.circle(x, 130, 5, fill='--phosphor')
    f.arrow([(390, 110), (490, 110)], stroke='--paper', width=1.3)
    f.text(440, 98, T('arrive on schedule', 'chegam no horário'), size=9.5)
    for k in range(4):
        f.rect(500 + k * 14, 120, 10, 20, stroke='--amber', fill='--panel', width=1.1, rx=1)
    f.text(528, 156, T('queue', 'fila'), size=9.5, fill='--amber')
    f.rect(570, 95, 90, 70, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(615, 130, T('server', 'servidor'), size=11, weight='600')
    f.arrow([(660, 130), (705, 130)], stroke='--paper', width=1.3)
    f.lines(540, 245, [T('a slow server grows a queue:', 'um servidor lento faz a fila crescer:'),
                       T('nothing slows the arrivals', 'nada desacelera as chegadas')], size=10,
            fill='--paper-dim')
    return f, T('A closed model counts users; an open model counts arrivals. They agree while the server '
                'keeps up and part ways the moment it does not.',
                'Um modelo fechado conta usuários; um modelo aberto conta chegadas. Eles concordam '
                'enquanto o servidor acompanha e se separam no momento em que ele não acompanha.')


@figure('l03-timeline', 3)
def timeline():
    f = Fig('l03-timeline', 720, 250, T(
        'One virtual user over time, drawn twice. Above, with think time: each request is followed by '
        'its response time, then a fixed think time measured from the end of the answer, so a slow '
        'answer, drawn as the second, longer response, pushes every later request back. Below, with '
        'pacing: a new iteration starts at fixed intervals measured from start to start, and the '
        'sleep shrinks to fill whatever the response left, so the slow answer does not move the next '
        'start.',
        'Um usuário virtual ao longo do tempo, desenhado duas vezes. Em cima, com tempo de '
        'pensamento: cada requisição é seguida do seu tempo de resposta e depois de um tempo de '
        'pensamento fixo, medido a partir do fim da resposta, então uma resposta lenta, desenhada como '
        'a segunda, mais longa, empurra todas as requisições seguintes para trás. Embaixo, com '
        'cadência: uma nova iteração começa em intervalos fixos medidos de início a início, e a pausa '
        'encolhe para preencher o que a resposta deixou, então a resposta lenta não move o próximo '
        'início.'))
    x0 = 120

    def seg(x, y, w, kind):
        if kind == 'r':
            f.rect(x, y - 9, w, 18, stroke='--phosphor', fill='--scan', width=1.3, rx=2)
        else:
            f.line(x, y, x + w, y, stroke='--amber', width=2, dash='5 3')

    y = 75
    f.text(20, y, T('think time', 'pensamento'), size=11, weight='600', anchor='start')
    x = x0
    for r in (40, 110, 40, 40):
        seg(x, y, r, 'r')
        x += r
        if x + 100 < 710:
            seg(x, y, 100, 't')
        x += 100
    f.text(x0 + 20, y - 22, 'R', size=10, mono=True)
    f.text(x0 + 90, y - 22, 'Z', size=10, mono=True, fill='--amber')
    f.text(x0 + 195, y + 25, T('a slow answer pushes everything after it', 'uma resposta lenta empurra tudo o que vem depois'),
           size=9.5, fill='--paper-dim')
    y = 165
    f.text(20, y, T('pacing', 'cadência'), size=11, weight='600', anchor='start')
    pace = 140
    for k, r in enumerate((40, 110, 40, 40)):
        x = x0 + k * pace
        seg(x, y, r, 'r')
        seg(x + r, y, pace - r - 8, 't')
        f.line(x, y + 16, x, y + 24, stroke='--paper-dim', width=1)
    f.line(x0 + 4 * pace, y + 16, x0 + 4 * pace, y + 24, stroke='--paper-dim', width=1)
    f.arrow([(x0 + 2, y + 34), (x0 + pace - 2, y + 34)], stroke='--paper-dim', width=1, start=True)
    f.text(x0 + pace / 2, y + 46, T('start to start, fixed', 'de início a início, fixo'), size=9.5, fill='--paper-dim')
    f.text(x0 + 1.5 * pace + 40, y + 46, T('the sleep shrinks instead', 'quem encolhe é a pausa'), size=9.5,
           fill='--paper-dim')
    return f, T('Think time is counted from the end of an answer; pacing from the start of an iteration. '
                'Only pacing keeps a user\'s rate when the server slows.',
                'O tempo de pensamento conta a partir do fim de uma resposta; a cadência, do início de uma '
                'iteração. Só a cadência mantém a taxa de um usuário quando o servidor fica lento.')


@figure('l03-sale', 3)
def sale():
    f = Fig('l03-sale', 720, 270, T(
        'The ten o\'clock sale worked through in boxes. 1,200 people in the first minute is 20 '
        'people a second. Each person sends 5 requests, so the site receives 100 requests a second: '
        '20 for the list of shows, 60 for a show page and 20 for bookings. Each visit lasts 16 '
        'seconds, four gaps of 4 seconds, so by Little\'s law 20 a second times 16 seconds is 320 '
        'people on the site at once. For the show page alone, 60 requests a second times 4.02 seconds '
        'is about 241 virtual users.',
        'A venda das dez horas resolvida em caixas. 1.200 pessoas no primeiro minuto são 20 pessoas '
        'por segundo. Cada pessoa envia 5 requisições, então o site recebe 100 requisições por '
        'segundo: 20 para a lista de espetáculos, 60 para a página de um espetáculo e 20 para '
        'reservas. Cada visita dura 16 segundos, quatro intervalos de 4 segundos, então pela lei de '
        'Little 20 por segundo vezes 16 segundos são 320 pessoas no site ao mesmo tempo. Só para a '
        'página do espetáculo, 60 requisições por segundo vezes 4,02 segundos são cerca de 241 '
        'usuários virtuais.'))

    def box(x, y, w, h, top, rows, hot=False):
        f.rect(x, y, w, h, stroke='--phosphor' if hot else '--wire', fill='--scan' if hot else '--panel',
               width=1.4 if hot else 1.1)
        f.text(x + w / 2, y + 18, top, size=12, weight='600')
        f.lines(x + w / 2, y + h / 2 + 12, rows, size=9.5, fill='--paper-dim', gap=12.5)

    box(20, 30, 150, 80, T('1,200 people', '1.200 pessoas'), [T('in the first minute', 'no primeiro minuto')])
    f.arrow([(172, 70), (210, 70)], stroke='--paper', width=1.3)
    box(212, 30, 150, 80, T('20 a second', '20 por segundo'), [T('people arriving', 'pessoas chegando')])
    f.arrow([(364, 70), (402, 70)], stroke='--paper', width=1.3)
    f.text(383, 58, '× 5', size=10, mono=True)
    box(404, 30, 296, 80, T('100 requests a second', '100 requisições por segundo'),
        [T('20 GET /shows · 60 GET /shows/{id}', '20 GET /shows · 60 GET /shows/{id}'),
         T('20 POST /bookings', '20 POST /bookings')], hot=True)
    f.arrow([(287, 112), (287, 150)], stroke='--paper', width=1.3)
    f.text(297, 132, T('× 16 s a visit', '× 16 s por visita'), size=10, anchor='start')
    box(212, 152, 150, 80, T('320 people', '320 pessoas'), [T('on the site at once', 'no site ao mesmo tempo')], hot=True)
    f.arrow([(552, 112), (552, 150)], stroke='--paper', width=1.3)
    f.text(562, 132, '60 × 4.02 s', size=10, anchor='start', mono=True)
    box(452, 152, 200, 80, T('≈ 241 virtual users', '≈ 241 usuários virtuais'),
        [T('for the show page alone', 'só para a página do espetáculo')], hot=True)
    f.text(20, 255, T('assumed: 4 people a seat, 5 requests a visit, 4 s of think time',
                      'suposto: 4 pessoas por assento, 5 requisições por visita, 4 s de pensamento'),
           size=9.5, anchor='start', fill='--amber')
    return f, T('From a crowd to a rate, and from a rate to a number of users. Change an assumption at the '
                'top and every box below it moves.',
                'De uma multidão a uma taxa, e de uma taxa a um número de usuários. Mude uma suposição '
                'no alto e todas as caixas abaixo se movem.')
