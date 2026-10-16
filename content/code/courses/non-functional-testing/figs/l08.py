"""Lesson 8: reading the result. The numbers are the lesson's own captures."""
from figures import Fig, T, figure

# `python3 measure.py 8 10 0.2`, in "Why the mean misleads": the histogram it printed.
BINS = [91, 311, 75, 26, 12, 3, 1, 1, 1, 0]
OVER = 132
MEAN, MEDIAN, P95 = 124.5, 32.0, 523.9

# The sweep in "Throughput, and why it stops rising".
WORKERS = [1, 2, 4, 8, 16, 32]
RATE = [46.3, 66.1, 80.3, 97.1, 102.4, 96.6]
MED = [19.6, 28.2, 48.3, 78.8, 129.7, 167.2]
P95S = [31.1, 51.4, 78.6, 133.0, 226.7, 1214.1]


@figure('l08-distribution', 8)
def distribution():
    f = Fig('l08-distribution', 720, 310, T(
        'A histogram of 653 response times from one load test, in bins of 20 milliseconds. Most '
        'requests are on the left: 91 under 20 ms, 311 between 20 and 40, 75 between 40 and 60, '
        'then a thinning tail, and 132 requests at 200 ms or more, drawn as one bar on the far '
        'right. The median, 32.0 ms, sits inside the tallest bar. The mean, 124.5 ms, is a dashed '
        'line over the bin from 120 to 140 ms, which holds one request. The 95th percentile, '
        '523.9 ms, lies inside the bar of 200 ms and up.',
        'Um histograma de 653 tempos de resposta de um teste de carga, em faixas de 20 '
        'milissegundos. A maioria das requisições está à esquerda: 91 abaixo de 20 ms, 311 entre '
        '20 e 40, 75 entre 40 e 60, depois uma cauda que vai rareando, e 132 requisições com 200 '
        'ms ou mais, desenhadas como uma barra só, na ponta direita. A mediana, 32.0 ms, fica dentro '
        'da barra mais alta. A média, 124.5 ms, é uma linha tracejada sobre a faixa de 120 a 140 '
        'ms, que tem uma requisição. O percentil 95, 523.9 ms, está dentro da barra de 200 ms para '
        'cima.'))
    x0, x1, base, top = 60, 580, 250, 70
    bw = (x1 - x0) / 10
    scale = (base - top) / max(BINS + [OVER])
    f.line(x0, base, x1, base, stroke='--paper-dim', width=1)
    for i, n in enumerate(BINS):
        h = n * scale
        if n:
            f.rect(x0 + i * bw + 3, base - h, bw - 6, h, stroke='--phosphor', fill='--scan', width=1, rx=1)
        f.text(x0 + i * bw + bw / 2, base - h - 9, str(n), size=9.5, mono=True)
    for i in range(0, 11, 2):
        f.text(x0 + i * bw, base + 14, str(i * 20), size=9.5, mono=True, fill='--paper-dim')
    f.text(x1 - 4, base + 32, T('response time, ms', 'tempo de resposta, ms'), size=10,
           anchor='end', fill='--paper-dim')
    # The catch-all bin, set apart.
    ox, ow = 618, 70
    f.line(ox - 8, base, ox + ow + 8, base, stroke='--paper-dim', width=1)
    h = OVER * scale
    f.rect(ox, base - h, ow, h, stroke='--amber', fill='--scan', width=1.2, rx=1)
    f.text(ox + ow / 2, base - h - 9, str(OVER), size=9.5, mono=True)
    f.text(ox + ow / 2, base + 14, '200+', size=9.5, mono=True, fill='--paper-dim')
    f.lines(ox + ow / 2, base - h / 2, [T('p95', 'p95'), f'{P95}'], size=10, mono=True, fill='--amber')
    # Median and mean.
    xm = x0 + MEDIAN / 200 * (x1 - x0)
    f.line(xm, base - BINS[1] * scale - 18, xm, 44, stroke='--paper', width=1.4)
    f.text(xm + 6, 40, T(f'median {MEDIAN} ms', f'mediana {MEDIAN} ms'), size=10.5,
           anchor='start', weight='600')
    xa = x0 + MEAN / 200 * (x1 - x0)
    f.line(xa, base, xa, 106, stroke='--amber', width=1.6, dash='5 4')
    f.text(xa + 6, 100, T(f'mean {MEAN} ms', f'média {MEAN} ms'), size=10.5,
           anchor='start', weight='600', fill='--amber')
    f.text(xa + 6, 116, T('one request lives here', 'uma requisição mora aqui'), size=10,
           anchor='start', fill='--amber')
    return f, T('Where 653 requests actually landed. The mean is the one place almost none of them did.',
                'Onde 653 requisições caíram de fato. A média é o único lugar onde quase nenhuma caiu.')


@figure('l08-load', 8)
def load():
    f = Fig('l08-load', 720, 300, T(
        'Two charts of the same six runs, with 1, 2, 4, 8, 16 and 32 workers along the bottom of '
        'each. On the left, throughput in requests per second climbs from 46.3 with one worker to '
        '97.1 with eight, then stays flat: 102.4 with sixteen and 96.6 with thirty-two. On the '
        'right, response time: the median rises from 19.6 to 167.2 ms, and the 95th percentile '
        'from 31.1 ms to 1214.1 ms, most of that rise after the throughput stopped growing.',
        'Dois gráficos das mesmas seis execuções, com 1, 2, 4, 8, 16 e 32 workers embaixo de cada '
        'um. À esquerda, a vazão em requisições por segundo sobe de 46.3 com um worker para 97.1 '
        'com oito, e então fica plana: 102.4 com dezesseis e 96.6 com trinta e dois. À direita, o '
        'tempo de resposta: a mediana sobe de 19.6 para 167.2 ms, e o percentil 95 de 31.1 ms para '
        '1214.1 ms, a maior parte dessa subida depois que a vazão parou de crescer.'))

    def panel(x0, title, ymax, ticks, series, unit_fmt):
        w, base, top = 270, 240, 60
        f.text(x0 + w / 2, 30, title, size=11, weight='600')
        f.line(x0, base, x0 + w, base, stroke='--paper-dim', width=1)
        f.line(x0, base, x0, top, stroke='--paper-dim', width=1)
        for t in ticks:
            y = base - t / ymax * (base - top)
            f.line(x0, y, x0 + w, y, stroke='--wire', width=0.6, dash='2 3')
            f.text(x0 - 6, y, unit_fmt(t), size=9, anchor='end', mono=True, fill='--paper-dim')
        xs = [x0 + 20 + i * (w - 40) / 5 for i in range(6)]
        for x, n in zip(xs, WORKERS):
            f.text(x, base + 14, str(n), size=9.5, mono=True, fill='--paper-dim')
        f.text(x0 + w / 2, base + 32, T('workers', 'workers'), size=10, fill='--paper-dim')
        for values, stroke, label, at in series:
            pts = [(x, base - v / ymax * (base - top)) for x, v in zip(xs, values)]
            f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke=stroke, width=1.8)
            for x, y in pts:
                f.circle(x, y, 3, fill=stroke)
            lx, ly = pts[at]
            f.text(lx - 6, ly - 12, label, size=10, anchor='end', fill='--paper' if stroke == '--phosphor' else '--amber',
                   weight='600')
        return xs

    panel(70, T('throughput, requests per second', 'vazão, requisições por segundo'), 120,
          [0, 40, 80, 120], [(RATE, '--phosphor', T('flat from 8', 'plana a partir de 8'), 3)], str)
    panel(420, T('response time, ms', 'tempo de resposta, ms'), 1250, [0, 400, 800, 1200],
          [(MED, '--phosphor', T('median', 'mediana'), 5), (P95S, '--amber', 'p95', 5)], str)
    return f, T('Past eight workers the box office answers no more requests a second. Every worker added after that only waits longer.',
                'Depois de oito workers a bilheteria não responde mais requisições por segundo. Cada worker a mais só espera mais.')


@figure('l08-omission', 8)
def omission():
    f = Fig('l08-omission', 720, 280, T(
        'Two timelines of the same ten seconds, with the server paused from second 3 to second 4. '
        'The top one is the closed generator: its requests stop during the pause, one request '
        'waits the whole second, and the next ones start only when the server returns. It made '
        '403 requests and its 99th percentile is 5.8 ms. The bottom one is the open generator: '
        'requests stay due every 20 ms through the pause, and every one due inside it waits until '
        'the server returns, the first nearly a second and the last almost nothing, drawn as a '
        'triangle of waiting. It made 501 requests, 47 of them over 100 ms, and its 99th '
        'percentile is 902.3 ms.',
        'Duas linhas do tempo dos mesmos dez segundos, com o servidor pausado do segundo 3 ao '
        'segundo 4. A de cima é o gerador fechado: as requisições dele param durante a pausa, uma '
        'requisição espera o segundo inteiro, e as próximas só começam quando o servidor volta. Ele '
        'fez 403 requisições e o percentil 99 dele é 5.8 ms. A de baixo é o gerador aberto: as '
        'requisições continuam marcadas a cada 20 ms durante a pausa, e cada uma marcada dentro '
        'dela espera até o servidor voltar, a primeira quase um segundo e a última quase nada, '
        'desenhado como um triângulo de espera. Ele fez 501 requisições, 47 delas acima de 100 ms, '
        'e o percentil 99 dele é 902.3 ms.'))
    x0, x1 = 110, 530
    sx = (x1 - x0) / 10
    f.boundary([(x0 + 3 * sx, 46), (x0 + 3 * sx, 242)])
    f.boundary([(x0 + 4 * sx, 46), (x0 + 4 * sx, 242)])
    f.text(x0 + 3.5 * sx, 36, T('server paused', 'servidor pausado'), size=10, fill='--amber', italic=True)
    for s in range(11):
        f.text(x0 + s * sx, 256, str(s), size=9.5, mono=True, fill='--paper-dim')
    f.text(x1, 272, T('seconds', 'segundos'), size=10, anchor='end', fill='--paper-dim')
    # The closed generator: ticks, a gap, one long request.
    yc = 110
    f.text(x0 - 10, yc - 30, T('closed', 'fechado'), size=11, anchor='end', weight='600')
    f.text(x0 - 10, yc - 14, T('waits for', 'espera cada'), size=9.5, anchor='end', fill='--paper-dim')
    f.text(x0 - 10, yc - 1, T('each answer', 'resposta'), size=9.5, anchor='end', fill='--paper-dim')
    f.line(x0, yc, x1, yc, stroke='--paper-dim', width=0.8)
    t = 0.0
    while t < 10:
        if 3 <= t < 4:
            f.rect(x0 + 3 * sx, yc - 8, sx, 8, stroke='--amber', fill='--panel', width=1.2, rx=1)
            t = 4.0
            continue
        f.line(x0 + t * sx, yc, x0 + t * sx, yc - 8, stroke='--phosphor', width=1)
        t += 0.22
    # The open generator: due every 20 ms, so the pause becomes a triangle of waiting.
    yo = 222
    f.text(x0 - 10, yo - 30, T('open', 'aberto'), size=11, anchor='end', weight='600')
    f.text(x0 - 10, yo - 14, T('timed from', 'medido da hora'), size=9.5, anchor='end', fill='--paper-dim')
    f.text(x0 - 10, yo - 1, T('when it was due', 'marcada'), size=9.5, anchor='end', fill='--paper-dim')
    f.line(x0, yo, x1, yo, stroke='--paper-dim', width=0.8)
    t = 0.0
    while t < 10:
        if 3 <= t < 4:
            h = 8 + (4 - t) * 70
            f.line(x0 + t * sx, yo, x0 + t * sx, yo - h, stroke='--amber', width=1)
        else:
            f.line(x0 + t * sx, yo, x0 + t * sx, yo - 8, stroke='--phosphor', width=1)
        t += 0.1
    # What each one reported.
    for y, rows in ((yc - 14, [T('403 requests', '403 requisições'), T('1 over 100 ms', '1 acima de 100 ms'), 'p99 5.8 ms']),
                    (yo - 30, [T('501 requests', '501 requisições'), T('47 over 100 ms', '47 acima de 100 ms'), 'p99 902.3 ms'])):
        f.rect(560, y - 30, 150, 60, stroke='--wire', fill='--panel', width=1)
        f.lines(635, y, rows, size=10.5)
    return f, T('One pause, two reports. The closed generator stopped asking while the server could not answer, so its numbers never saw the pause.',
                'Uma pausa, dois relatórios. O gerador fechado parou de perguntar enquanto o servidor não respondia, e os números dele nunca viram a pausa.')
