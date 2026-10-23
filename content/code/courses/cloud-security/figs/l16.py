"""Lesson 16: the posture loop."""
from figures import Fig, T, figure


@figure('l16-loop', 16)
def loop():
    f = Fig('l16-loop', 720, 300, T(
        'The posture loop. The scanner reads the configuration through the API, compares each answer '
        'with its rules, and writes findings. Each finding goes to an owner, who either fixes it or '
        'accepts it with a reason and an end date. The next scan reads the configuration again. Drift, '
        'a hand change made after the scan, enters the configuration from outside the loop, and only '
        'the next reading sees it.',
        'O ciclo de postura. O scanner lê a configuração pela API, compara cada resposta com as regras '
        'e escreve achados. Cada achado vai para um dono, que o corrige ou o aceita com um motivo e uma '
        'data de fim. A próxima varredura lê a configuração de novo. O desvio, uma mudança feita à mão '
        'depois da varredura, entra na configuração por fora do ciclo, e só a próxima leitura o vê.'))
    boxes = [
        (40, 110, T('configuration', 'configuração'), T('what the API answers', 'o que a API responde'), '--phosphor'),
        (220, 110, T('rules', 'regras'), T('CIS, provider, yours', 'CIS, provedor, suas'), '--paper-dim'),
        (400, 110, T('findings', 'achados'), T('rule, resource, detail', 'regra, recurso, detalhe'), '--amber'),
        (560, 50, T('fix', 'corrigir'), T('by the owner', 'pelo dono'), '--phosphor'),
        (560, 170, T('accept', 'aceitar'), T('reason and end date', 'motivo e data de fim'), '--paper-dim'),
    ]
    for x, y, title, sub, edge in boxes:
        w = 140 if x < 560 else 130
        f.rect(x, y, w, 60, stroke=edge, fill='--scan', width=1.3)
        f.text(x + w / 2, y + 22, title, size=11, weight='600')
        f.text(x + w / 2, y + 42, sub, size=9.5, fill='--paper-dim', italic=True)
    f.arrow([(182, 140), (218, 140)], stroke='--paper-dim')
    f.text(200, 128, T('read', 'ler'), size=9.5, fill='--paper-dim')
    f.arrow([(362, 140), (398, 140)], stroke='--paper-dim')
    f.arrow([(542, 128), (558, 90)], stroke='--paper-dim')
    f.arrow([(542, 152), (558, 190)], stroke='--paper-dim')
    f.path('M625 232 L625 270 L110 270 L110 172', stroke='--phosphor', arrow=True)
    f.path('M690 80 L705 80 L705 270 L625 270', stroke='--phosphor')
    f.text(370, 284, T('the next scan reads it all again', 'a próxima varredura lê tudo de novo'), size=10,
           fill='--phosphor')
    f.arrow([(110, 34), (110, 108)], stroke='--amber', dash='4 3')
    f.text(124, 34, T('drift: a hand change after the scan', 'desvio: uma mudança à mão depois da varredura'),
           size=10, anchor='start', fill='--amber')
    return f, T('A finding is not the end of the loop: the fix, or the dated exception, is checked by '
                'the next reading, and so is every change made by hand in between.',
                'Um achado não é o fim do ciclo: a correção, ou a exceção com data, é conferida pela '
                'próxima leitura, e também toda mudança feita à mão no meio do caminho.')
