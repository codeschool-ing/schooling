"""Lesson 23: a schedule's arithmetic, and probing from several places."""
from figures import Fig, T, figure


@figure('l23-interval', 23)
def interval():
    f = Fig('l23-interval', 720, 250, T(
        'A time line of eight minutes with a check at every minute, drawn as a dot. The first three '
        'checks pass. An outage begins just after the third check, shown as a shaded band running to '
        'the end. The fourth check, almost a minute later, is the first to fail; the fifth fails '
        'too, and only then, with two failures in a row, is somebody told. Between the start of the '
        'outage and the person being told, nearly two intervals pass.',
        'Uma linha do tempo de oito minutos com uma verificação a cada minuto, desenhada como um '
        'ponto. As três primeiras passam. Uma queda começa logo depois da terceira verificação, '
        'mostrada como uma faixa sombreada até o fim. A quarta verificação, quase um minuto depois, '
        'é a primeira a falhar; a quinta falha também, e só então, com duas falhas seguidas, alguém '
        'é avisado. Entre o início da queda e o aviso à pessoa passam quase dois intervalos.'))
    x0, step, y = 70, 80, 120
    start = x0 + 2 * step + 8
    f.rect(start, 70, x0 + 7 * step + 20 - start, 100, stroke=None, fill='--scan', rx=0)
    f.text(start + 6, 82, T('outage begins', 'a queda começa'), size=10, anchor='start', fill='--amber')
    f.line(x0 - 20, y, x0 + 7 * step + 20, y, stroke='--paper-dim', width=1.2)
    for i in range(8):
        x = x0 + i * step
        ok = i < 3
        f.circle(x, y, 7, fill='--phosphor' if ok else '--amber')
        f.text(x, y + 26, f'{i}:00', size=10, mono=True)
        f.text(x, y - 22, T('pass', 'passa') if ok else T('fail', 'falha'), size=10,
               fill='--paper' if ok else '--amber')
    f.arrow([(start, 198), (x0 + 3 * step - 4, 198)], stroke='--paper-dim')
    f.text((start + x0 + 3 * step) / 2, 212, T('up to one interval', 'até um intervalo'), size=10)
    f.arrow([(start, 228), (x0 + 4 * step - 4, 228)], stroke='--amber')
    f.text(x0 + 4 * step + 8, 228, T('two in a row: somebody is told', 'duas seguidas: alguém é avisado'),
           size=10, anchor='start', fill='--amber')
    return f, T('Checking every minute, an outage is first seen up to a minute late, and confirmed a minute after that.',
                'Verificando a cada minuto, uma queda é vista primeiro com até um minuto de atraso, e confirmada um minuto depois.')


@figure('l23-regions', 23)
def regions():
    f = Fig('l23-regions', 720, 280, T(
        'Two panels, each with three probes, São Paulo, Virginia and Frankfurt, sending a check to '
        'one service on the right. In the left panel all three checks fail: the problem is the '
        'service. In the right panel only the check from Frankfurt fails and the other two pass: '
        'the service is working, and the problem is on the path from Frankfurt.',
        'Dois painéis, cada um com três sondas, São Paulo, Virgínia e Frankfurt, mandando uma '
        'verificação a um serviço à direita. No painel da esquerda, as três falham: o problema é o '
        'serviço. No painel da direita, só a de Frankfurt falha e as outras duas passam: o serviço '
        'funciona, e o problema está no caminho a partir de Frankfurt.'))
    places = ['São Paulo', T('Virginia', 'Virgínia'), 'Frankfurt']
    for px, fails, title in ((20, (True, True, True), T('all fail: the service', 'todas falham: o serviço')),
                             (370, (False, False, True), T('one fails: its path', 'uma falha: o caminho dela'))):
        f.text(px + 165, 24, title, size=11, weight='600', fill='--amber' if all(fails) else '--paper')
        f.rect(px + 230, 110, 100, 60, stroke='--phosphor', fill='--scan', width=1.4)
        f.text(px + 280, 140, 'boxoffice', size=10.5, mono=True)
        for i, (name, bad) in enumerate(zip(places, fails)):
            yy = 70 + i * 70
            f.rect(px, yy - 16, 110, 32, stroke='--wire', fill='--panel', width=1.1)
            f.text(px + 55, yy, name, size=10)
            f.arrow([(px + 112, yy), (px + 226, 140 + (i - 1) * 16)],
                    stroke='--amber' if bad else '--phosphor', dash='4 3' if bad else None)
            f.text(px + 160, yy + (14 if i != 1 else -10), T('fail', 'falha') if bad else T('pass', 'passa'),
                   size=9.5, fill='--amber' if bad else '--paper')
    return f, T('The same check from three places. Which ones fail says where to look.',
                'A mesma verificação de três lugares. Quais falham diz onde procurar.')
