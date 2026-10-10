"""Lesson 22: the three signals, and a percentile read out of buckets."""
from figures import Fig, T, figure


@figure('l22-signals', 22)
def signals():
    f = Fig('l22-signals', 720, 330, T(
        'One booking request, POST /bookings, in the middle, and the three records it leaves '
        'behind. As a metric, it adds one to a counter labelled with its route and status, and '
        'one to a duration bucket: cheap, and it says how many and how fast, never which one. As a '
        'log line, it is one JSON record with its own request id, status and milliseconds: it says '
        'what happened to this request. As a trace, it is a bar for the whole request with a bar '
        'inside it for each part, the database and the payment: it says where the time went.',
        'Uma requisição de reserva, POST /bookings, no meio, e os três registros que ela deixa. '
        'Como métrica, soma um a um contador rotulado com a rota e o status, e um a um balde de '
        'duração: barato, e diz quantas e quão rápidas, nunca qual. Como linha de log, é um '
        'registro JSON com o seu próprio id de requisição, status e milissegundos: diz o que '
        'aconteceu com esta requisição. Como trace, é uma barra para a requisição inteira com uma '
        'barra dentro para cada parte, o banco e o pagamento: diz para onde foi o tempo.'))
    f.rect(270, 20, 180, 40, stroke='--phosphor', fill='--scan', width=1.5)
    f.text(360, 40, 'POST /bookings', size=12, mono=True)
    cols = [(20, T('metric', 'métrica'), T('how many, how fast', 'quantas, quão rápidas')),
            (260, 'log', T('what happened to this one', 'o que houve com esta')),
            (500, 'trace', T('where the time went', 'para onde foi o tempo'))]
    for x, name, says in cols:
        f.arrow([(360, 62), (x + 100, 96)], stroke='--paper-dim')
        f.rect(x, 100, 200, 30, stroke='--phosphor', fill='--panel', width=1.3)
        f.text(x + 100, 115, name, size=11.5, weight='600')
        f.rect(x, 138, 200, 130, stroke='--wire', fill='--panel', width=1.1)
        f.text(x + 100, 290, says, size=10.5, fill='--amber')
    # the metric
    f.lines(120, 175, ['requests_total{', 'route="/bookings",', 'status="201"} +1'], size=9.5, mono=True)
    f.lines(120, 235, ['duration_bucket{', 'le="0.1"} +1'], size=9.5, mono=True)
    # the log line
    f.lines(360, 203, ['{"request_id":', '"ana-test-1",', '"route": "/bookings",',
                       '"status": 201,', '"ms": 68.8}'], size=9.5, mono=True, gap=15)
    # the trace
    f.rect(512, 160, 176, 18, stroke='--phosphor', fill='--scan', width=1.1, rx=2)
    f.text(520, 169, 'request', size=9.5, anchor='start', mono=True)
    f.rect(512, 190, 50, 18, stroke='--paper-dim', fill='--panel', width=1.1, rx=2)
    f.text(537, 199, 'db', size=9.5, mono=True)
    f.rect(566, 190, 116, 18, stroke='--amber', fill='--panel', width=1.1, rx=2)
    f.text(624, 199, 'pay', size=9.5, mono=True)
    f.line(512, 236, 688, 236, stroke='--paper-dim', width=1)
    f.text(512, 250, '0', size=9, mono=True)
    f.text(688, 250, T('time', 'tempo'), size=9, anchor='end')
    return f, T('One request, three records. Each answers a question the other two cannot.',
                'Uma requisição, três registros. Cada um responde a uma pergunta que os outros dois não respondem.')


# The buckets of /shows/{id} at the end of the lesson's run (the `buckets` capture).
BUCKETS = [('5 ms', 0), ('10 ms', 0), ('25 ms', 586), ('50 ms', 887), ('100 ms', 952), ('250 ms', 963)]
TOTAL = 963


@figure('l22-buckets', 22)
def buckets():
    target = 0.95 * TOTAL                      # 914.85
    lo, hi = 887, 952
    est = 50 + 50 * (target - lo) / (hi - lo)   # 71.4 ms
    f = Fig('l22-buckets', 720, 320, T(
        'Six bars, one per bucket of GET /shows/{id} after the run, each as tall as the number of '
        'requests that took at most that long: 0 under 5 ms, 0 under 10 ms, 586 under 25 ms, 887 '
        'under 50 ms, 952 under 100 ms and all 963 under 250 ms. A dashed line at 915, which is 95% '
        'of 963, first passes under a bar at the 100 ms bucket, so the 95th percentile lies between '
        '50 and 100 ms. Assuming the requests in that bucket are spread evenly, the estimate is '
        f'about {est:.0f} ms; the bucket only knows it is somewhere in those 50 ms.',
        'Seis barras, uma por balde de GET /shows/{id} depois da execução, cada uma da altura do '
        'número de requisições que levaram no máximo aquele tempo: 0 abaixo de 5 ms, 0 abaixo de '
        '10 ms, 586 abaixo de 25 ms, 887 abaixo de 50 ms, 952 abaixo de 100 ms e todas as 963 '
        'abaixo de 250 ms. Uma linha tracejada em 915, que é 95% de 963, fica abaixo de uma barra '
        'pela primeira vez no balde de 100 ms, então o percentil 95 está entre 50 e 100 ms. '
        'Supondo que as requisições daquele balde se espalham por igual, a estimativa é de cerca de '
        f'{est:.0f} ms; o balde só sabe que está em algum lugar daqueles 50 ms.'))
    x0, y0, w, top = 80, 250, 96, 50
    scale = (y0 - top) / TOTAL
    f.line(x0 - 10, y0, x0 + w * 6 + 10, y0, stroke='--paper-dim', width=1)
    for i, (name, n) in enumerate(BUCKETS):
        x = x0 + i * w + 14
        h = n * scale
        hit = name == '100 ms'
        if h:
            f.rect(x, y0 - h, w - 28, h, stroke='--amber' if hit else '--phosphor',
                   fill='--scan', width=1.6 if hit else 1.1, rx=2)
        f.text(x + (w - 28) / 2, y0 - h - 10, str(n), size=10, mono=True)
        f.text(x + (w - 28) / 2, y0 + 16, f'le {name}', size=10)
    ty = y0 - target * scale
    f.line(x0 - 10, ty, x0 + w * 6 + 10, ty, stroke='--amber', width=1.3, dash='5 4')
    f.text(x0 - 14, ty, '915', size=10, anchor='end', mono=True, fill='--amber')
    f.text(x0 - 4, ty - 12, T('95% of 963', '95% de 963'), size=10, anchor='start', fill='--amber')
    f.text(360, 20, T('requests that took at most this long', 'requisições que levaram no máximo isto'),
           size=11, weight='600', fill='--paper-dim')
    f.text(360, 296, T(f'the 95th percentile is between 50 and 100 ms; evenly spread, about {est:.0f} ms',
                       f'o percentil 95 está entre 50 e 100 ms; espalhado por igual, cerca de {est:.0f} ms'),
           size=10.5, fill='--amber')
    return f, T('A histogram keeps counts under bounds, never durations. The percentile can only be placed inside a bucket.',
                'Um histograma guarda contagens abaixo de limites, nunca durações. O percentil só pode ser posto dentro de um balde.')
