"""Lesson 1: the non-functional requirement as a number."""
from figures import Fig, T, figure


@figure('l01-anatomy', 1)
def anatomy():
    f = Fig('l01-anatomy', 720, 250, T(
        'One requirement cut into its five parts. The operation: GET /shows/{id}. The statistic: '
        'the 95th percentile of the response time, and the error rate. The threshold: under 200 ms, '
        'and under 1%. The load: 50 requests a second. The conditions: sustained for 10 minutes, '
        'timed at the client, on the staging machine. Leave out any one part and nobody can say '
        'whether a result fails.',
        'Um requisito cortado nas suas cinco partes. A operação: GET /shows/{id}. A estatística: o '
        'percentil 95 do tempo de resposta, e a taxa de erro. O limite: abaixo de 200 ms, e abaixo '
        'de 1%. A carga: 50 requisições por segundo. As condições: sustentada por 10 minutos, '
        'medida no cliente, na máquina de homologação. Sem qualquer uma das partes, ninguém consegue '
        'dizer se um resultado reprova.'))
    parts = [
        (20, 120, T('operation', 'operação'), ['GET /shows/{id}'], True),
        (152, 126, T('statistic', 'estatística'), [T('95th percentile', 'percentil 95'), T('error rate', 'taxa de erro')], False),
        (290, 120, T('threshold', 'limite'), ['< 200 ms', '< 1%'], True),
        (422, 120, T('load', 'carga'), [T('50 requests/s', '50 req/s')], False),
        (554, 146, T('conditions', 'condições'), [T('10 minutes', '10 minutos'), T('timed at the client', 'medido no cliente'), T('staging machine', 'homologação')], False),
    ]
    f.text(360, 28, T('one sentence a test can fail', 'uma frase que um teste consegue reprovar'),
           size=11, weight='600', fill='--paper-dim')
    for x, w, name, rows, mono in parts:
        f.rect(x, 60, w, 34, stroke='--phosphor', fill='--scan', width=1.4)
        f.text(x + w / 2, 77, name, size=11, weight='600')
        f.rect(x, 108, w, 76, stroke='--wire', fill='--panel', width=1.1)
        f.lines(x + w / 2, 146, rows, size=10.5, mono=mono)
    f.text(360, 214, T('leave one out and the result needs a meeting to read',
                       'tire uma parte e o resultado precisa de uma reunião para ser lido'),
           size=10.5, fill='--amber')
    return f, T('The five parts of a performance requirement. Each one is a place where "fast" used to hide.',
                'As cinco partes de um requisito de desempenho. Cada uma é um lugar onde o "rápido" se escondia.')
