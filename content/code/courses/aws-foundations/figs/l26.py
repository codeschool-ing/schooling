"""Lesson 26: the API, its signature and its clients."""
from figures import Fig, T, figure


@figure('l26-sigv4', 26)
def sigv4():
    f = Fig('l26-sigv4', 720, 330, T(
        'How a Signature Version 4 signature is made, in two columns. On the left, the request: '
        'the canonical request (method, path, query, signed headers and a hash of the body) is '
        'hashed and put into the string to sign with the date and the scope. On the right, the '
        'key: the secret is combined with the date, then the region, then the service, then the '
        'word aws4_request, giving the signing key. The signing key signs the string to sign, and '
        'the result goes into the Authorization header. The secret itself is never sent.',
        'Como uma assinatura Signature Version 4 é feita, em duas colunas. À esquerda, a '
        'requisição: a requisição canônica (método, caminho, query, cabeçalhos assinados e um hash '
        'do corpo) vira hash e entra na string a assinar com a data e o escopo. À direita, a chave: '
        'o segredo é combinado com a data, depois a região, depois o serviço, depois a palavra '
        'aws4_request, dando a chave de assinatura. A chave de assinatura assina a string a assinar, '
        'e o resultado vai para o cabeçalho Authorization. O segredo em si nunca é enviado.'))
    f.text(170, 24, T('the request', 'a requisição'), size=11, weight='600', fill='--paper-dim')
    f.text(540, 24, T('the key', 'a chave'), size=11, weight='600', fill='--paper-dim')
    f.rect(60, 44, 220, 56, stroke='--wire', fill='--scan')
    f.text(170, 62, T('canonical request', 'requisição canônica'), size=10.5, weight='600')
    f.text(170, 82, 'POST / host x-amz-date', size=9, mono=True, fill='--paper-dim')
    f.line(170, 102, 170, 140, stroke='--paper-dim', width=1.3, arrow=True)
    f.text(180, 121, 'SHA-256', size=9, anchor='start', mono=True, fill='--paper-dim')
    f.rect(60, 142, 220, 56, stroke='--wire', fill='--scan')
    f.text(170, 160, T('string to sign', 'string a assinar'), size=10.5, weight='600')
    f.text(170, 180, '20261016/sa-east-1/sts', size=9, mono=True, fill='--paper-dim')
    keys = [(44, 'secret'), (88, '+ 20261016'), (132, '+ sa-east-1'), (176, '+ sts'),
            (220, '+ aws4_request')]
    for y, k in keys:
        f.rect(460, y - 16, 160, 32, stroke='--amber' if y == 44 else '--wire', fill='--panel')
        f.text(540, y, k, size=10, mono=True)
    for y, _ in keys[:-1]:
        f.line(540, y + 17, 540, y + 27, stroke='--paper-dim', width=1.2, arrow=True)
    f.text(630, 132, 'HMAC', size=9, anchor='start', mono=True, fill='--paper-dim')
    f.text(552, 254, T('signing key', 'chave de assinatura'), size=10, anchor='start', fill='--amber')
    f.rect(240, 262, 240, 44, stroke='--phosphor', fill='--panel', width=1.5)
    f.text(360, 284, 'Authorization: … Signature=…', size=10, mono=True)
    f.arrow([(170, 200), (170, 284), (238, 284)], stroke='--phosphor', width=1.3)
    f.arrow([(540, 237), (540, 284), (482, 284)], stroke='--amber', width=1.3)
    f.text(360, 322, T('the secret signs; it is never sent', 'o segredo assina; ele nunca é enviado'),
           size=10, fill='--amber', italic=True)
    return f, T('Both sides compute the same signature: the client from its secret, AWS from its '
                'copy.',
                'Os dois lados calculam a mesma assinatura: o cliente com o segredo dele, a AWS com '
                'a cópia dela.')


@figure('l26-clients', 26)
def clients():
    f = Fig('l26-clients', 720, 290, T(
        'Four clients, one API. The console in a browser, the AWS command line, a program using '
        'boto3 and curl with --aws-sigv4 each send a signed HTTPS request to the same service '
        'endpoint. The service evaluates the same IAM policies for all of them, and CloudTrail '
        'records each call, with the client\'s User-Agent.',
        'Quatro clientes, uma API. O console no navegador, a linha de comando da AWS, um programa '
        'com boto3 e o curl com --aws-sigv4 mandam, cada um, uma requisição HTTPS assinada ao mesmo '
        'endpoint de serviço. O serviço avalia as mesmas políticas do IAM para todos, e o CloudTrail '
        'registra cada chamada, com o User-Agent do cliente.'))
    clients = [(50, T('the console', 'o console'), T('in a browser', 'no navegador')),
               (110, 'aws', T('the command line', 'a linha de comando')),
               (170, 'boto3', T('a program', 'um programa')),
               (230, 'curl --aws-sigv4', T('by hand', 'à mão'))]
    for y, name, note in clients:
        f.rect(30, y - 24, 190, 48, stroke='--wire', fill='--scan')
        mono = name in ('aws', 'boto3', 'curl --aws-sigv4')
        f.text(125, y - 8, name, size=10.5, weight='600', mono=mono)
        f.text(125, y + 10, note, size=9, fill='--paper-dim')
        f.arrow([(222, y), (348, 140)], stroke='--phosphor', width=1.2)
    f.rect(350, 100, 160, 80, stroke='--phosphor', fill='--panel', width=1.5)
    f.text(430, 126, T('the service', 'o serviço'), size=11, weight='600')
    f.text(430, 146, T('same policies', 'mesmas políticas'), size=9.5, fill='--paper-dim')
    f.text(430, 162, T('for all four', 'para os quatro'), size=9.5, fill='--paper-dim')
    f.arrow([(512, 140), (558, 140)], stroke='--amber', width=1.3)
    f.rect(560, 110, 140, 60, stroke='--amber', fill='--scan')
    f.text(630, 132, 'CloudTrail', size=11, weight='600')
    f.text(630, 152, T('one record each', 'um registro cada'), size=9.5, fill='--paper-dim')
    f.text(430, 70, T('a signed HTTPS request', 'uma requisição HTTPS assinada'), size=10,
           fill='--phosphor')
    return f, T('The console is one more client: it signs the same calls, and is judged and '
                'recorded the same way.',
                'O console é mais um cliente: ele assina as mesmas chamadas, e é julgado e '
                'registrado do mesmo jeito.')
