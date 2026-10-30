"""Lesson 20: load balancing."""
from figures import Fig, T, figure


@figure('l20-chain', 20)
def chain():
    f = Fig('l20-chain', 720, 250, T(
        'The chain of a global external Application Load Balancer, from left to right, the way a request '
        'travels. The forwarding rule holds the address and port 443. The target HTTPS proxy holds the '
        'certificate and ends TLS. The URL map sends /api/* to the api backend service and everything else '
        'to the web backend service. Each backend service has a health check, on /healthz port 8080, and '
        'balances across its backends, the machines that answer. Under the chain, an arrow pointing the '
        'other way says that resources are created from right to left, since each link names the next.',
        'A cadeia de um Application Load Balancer externo global, da esquerda para a direita, do jeito que '
        'um pedido viaja. A regra de encaminhamento guarda o endereço e a porta 443. O proxy HTTPS de destino '
        'guarda o certificado e termina o TLS. O mapa de URL manda /api/* para o serviço de backend api e o '
        'resto para o serviço de backend web. Cada serviço de backend tem uma verificação de saúde, em '
        '/healthz porta 8080, e balanceia entre os seus backends, as máquinas que respondem. Embaixo da '
        'cadeia, uma seta no sentido contrário diz que os recursos são criados da direita para a esquerda, '
        'já que cada elo nomeia o seguinte.'))
    boxes = [(20, T('forwarding rule', 'regra de encaminhamento'), T('address, port 443', 'endereço, porta 443')),
             (160, T('HTTPS proxy', 'proxy HTTPS'), T('certificate, TLS', 'certificado, TLS')),
             (300, T('URL map', 'mapa de URL'), T('host and path', 'host e caminho'))]
    for x, name, note in boxes:
        f.rect(x, 70, 120, 60, stroke='--amber', fill='--panel', width=1.4)
        f.text(x + 60, 92, name, size=9.5)
        f.text(x + 60, 112, note, size=9, fill='--paper-dim')
    for x in (140, 280):
        f.arrow([(x + 2, 100), (x + 18, 100)], stroke='--amber', width=1.4)
    for y, name, path in ((30, 'api', '/api/*'), (130, 'web', T('everything else', 'todo o resto'))):
        f.rect(460, y, 120, 60, stroke='--phosphor', fill='--panel', width=1.4)
        f.text(520, y + 22, T(f'backend {name}', f'backend {name}'), size=9.5)
        f.text(520, y + 42, path, size=9, mono=True, fill='--paper-dim')
        f.arrow([(422, 100), (456, y + 30)], stroke='--phosphor', width=1.4)
        f.rect(610, y, 90, 60, stroke='--wire', fill='--panel', width=1.2, dash='4 3')
        f.text(655, y + 22, T('machines', 'máquinas'), size=9.5)
        f.text(655, y + 42, T('next course', 'próximo curso'), size=8.5, fill='--paper-dim')
        f.arrow([(582, y + 30), (606, y + 30)], stroke='--phosphor', width=1.2)
    f.text(520, 112, T('health check /healthz', 'saúde em /healthz'), size=8.5, fill='--paper-dim')
    f.arrow([(700, 218), (20, 218)], stroke='--paper-dim', width=1.2)
    f.text(360, 236, T('created in this direction: each link names the next', 'criados neste sentido: cada elo nomeia o seguinte'),
           size=9.5, fill='--paper-dim')
    f.text(360, 206, T('a request travels left to right', 'um pedido viaja da esquerda para a direita'), size=9.5)
    return f, T('Five links: where it arrives, TLS, the route, the balancing, the machines.',
                'Cinco elos: onde chega, TLS, a rota, o balanceamento, as máquinas.')
