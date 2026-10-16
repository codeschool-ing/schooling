"""Lesson 23: CloudFront's tiers of cache, and a distribution's behaviours."""
from figures import Fig, T, figure


@figure('l23-edges', 23)
def edges():
    f = Fig('l23-edges', 720, 330, T(
        'The path of a request through CloudFront, left to right. Two viewers, in Manaus and in Recife, '
        'each reach the edge location nearest them. A hit is answered at the edge. A miss goes to a '
        'regional edge cache, which both edges share, and a hit there is answered from it. Only a '
        'miss at the regional cache reaches the origin in sa-east-1, the bucket shop-assets or the '
        'load balancer shop-web, and the transfer from the origin to CloudFront is free. Most requests '
        'stop at the first box.',
        'O caminho de uma requisição pelo CloudFront, da esquerda para a direita. Dois espectadores, em '
        'Manaus e em Recife, chegam cada um ao ponto de presença mais perto. Um acerto é respondido no '
        'ponto de presença. Uma falta vai a um cache regional, que os dois pontos de presença '
        'compartilham, e um acerto ali é respondido por ele. Só uma falta no cache regional chega à '
        'origem em sa-east-1, o bucket shop-assets ou o balanceador shop-web, e a transferência da '
        'origem para o CloudFront é grátis. A maioria das requisições para na primeira caixa.'))
    viewers = [(90, T('a viewer in Manaus', 'quem vê, em Manaus')),
               (210, T('a viewer in Recife', 'quem vê, em Recife'))]
    for y, label in viewers:
        f.rect(20, y - 22, 130, 44, stroke='--paper-dim', fill='--panel', rx=22)
        f.text(85, y, label, size=9.5)
        f.rect(200, y - 30, 130, 60, stroke='--phosphor', fill='--scan', width=1.5)
        f.text(265, y - 8, T('edge location', 'ponto de presença'), size=10.5, weight='600')
        f.text(265, y + 10, T('hit: answered here', 'acerto: responde aqui'), size=9,
               fill='--phosphor')
        f.line(152, y, 196, y, stroke='--paper-dim', width=1.3, arrow=True)
        f.arrow([(332, y), (382, 150 + (y - 150) * 0.3)], stroke='--amber', width=1.2)
    f.text(357, 74, T('miss', 'falta'), size=9.5, fill='--amber')
    f.rect(386, 115, 140, 70, stroke='--phosphor', fill='--scan', width=1.5)
    f.text(456, 138, T('regional edge cache', 'cache regional'), size=10.5, weight='600')
    f.text(456, 156, T('larger, shared', 'maior, compartilhado'), size=9, fill='--paper-dim')
    f.text(456, 171, T('hit: answered here', 'acerto: responde aqui'), size=9, fill='--phosphor')
    f.line(528, 150, 572, 150, stroke='--amber', width=1.2, arrow=True)
    f.text(550, 138, T('miss', 'falta'), size=9.5, fill='--amber')
    # the origin region
    f.rect(576, 50, 130, 200, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(590, 66, 'sa-east-1', size=10.5, mono=True, anchor='start', fill='--paper-dim')
    f.rect(590, 86, 102, 54, stroke='--wire', fill='--panel')
    f.text(641, 106, 'shop-assets', size=9.5, mono=True)
    f.text(641, 123, T('bucket', 'bucket'), size=9, fill='--paper-dim')
    f.rect(590, 160, 102, 54, stroke='--wire', fill='--panel')
    f.text(641, 180, 'shop-web', size=9.5, mono=True)
    f.text(641, 197, T('load balancer', 'balanceador'), size=9, fill='--paper-dim')
    f.text(641, 236, T('origin', 'origem'), size=10, weight='600', fill='--paper-dim')
    f.text(550, 278, T('origin to CloudFront: free', 'origem ao CloudFront: grátis'), size=10,
           fill='--phosphor', weight='600')
    f.text(360, 312, T('the further right a request has to travel, the rarer it should be',
                       'quanto mais à direita uma requisição precisa ir, mais rara ela deve ser'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('Two tiers of cache stand between the viewer and the shop. A miss at both is the only '
                'request the shop sees.',
                'Duas camadas de cache ficam entre quem vê e a loja. Uma falta nas duas é a única '
                'requisição que a loja vê.')


@figure('l23-behaviours', 23)
def behaviours():
    f = Fig('l23-behaviours', 720, 320, T(
        'One distribution, two behaviours. A viewer\'s request reaches the distribution, which tries '
        'its path patterns in order. Requests for /static/* use the CachingOptimized policy, keyed on '
        'the path and kept for a day by default, and go to the origin assets, the bucket shop-assets, '
        'which only the distribution can read through Origin Access Control and the bucket policy. '
        'Everything else matches the default behaviour, uses CachingDisabled with the AllViewer origin '
        'request policy, and goes to the origin web, the load balancer shop-web, with the viewer\'s '
        'cookies.',
        'Uma distribuição, dois comportamentos. A requisição de quem vê chega à distribuição, que tenta '
        'os padrões de caminho em ordem. Requisições para /static/* usam a política CachingOptimized, '
        'com chave no caminho e guardadas por um dia por padrão, e vão para a origem assets, o bucket '
        'shop-assets, que só a distribuição consegue ler pelo Origin Access Control e pela política do '
        'bucket. Todo o resto casa com o comportamento padrão, usa CachingDisabled com a política de '
        'requisição de origem AllViewer, e vai para a origem web, o balanceador shop-web, com os '
        'cookies de quem vê.'))
    f.rect(20, 125, 110, 50, stroke='--paper-dim', fill='--panel', rx=25)
    f.text(75, 150, T('a viewer', 'quem vê'), size=10)
    f.line(132, 150, 176, 150, stroke='--paper-dim', width=1.3, arrow=True)
    f.rect(180, 30, 300, 250, stroke='--phosphor', fill='--ink', width=1.5)
    f.text(330, 50, T('the distribution', 'a distribuição'), size=11, weight='600')
    # behaviour 1
    f.rect(196, 70, 268, 90, stroke='--amber', fill='--scan')
    f.text(212, 90, '/static/*', size=10.5, mono=True, anchor='start')
    f.text(212, 112, 'CachingOptimized', size=9.5, mono=True, anchor='start', fill='--paper-dim')
    f.text(212, 130, T('key: the path; kept a day by default', 'chave: o caminho; guarda um dia'),
           size=9, anchor='start', fill='--paper-dim')
    f.text(212, 147, T('compressed', 'comprimido'), size=9, anchor='start', fill='--paper-dim')
    # behaviour 2
    f.rect(196, 172, 268, 92, stroke='--wire', fill='--scan')
    f.text(212, 192, T('default (everything else)', 'padrão (todo o resto)'), size=10.5,
           anchor='start')
    f.text(212, 214, 'CachingDisabled', size=9.5, mono=True, anchor='start', fill='--paper-dim')
    f.text(212, 232, 'AllViewer', size=9.5, mono=True, anchor='start', fill='--paper-dim')
    f.text(212, 250, T("nothing kept; cookies forwarded", 'nada guardado; cookies repassados'),
           size=9, anchor='start', fill='--paper-dim')
    # origins
    f.rect(560, 80, 140, 70, stroke='--wire', fill='--panel')
    f.text(630, 104, 'shop-assets', size=10, mono=True)
    f.text(630, 122, T('bucket, private', 'bucket, privado'), size=9, fill='--paper-dim')
    f.text(630, 138, T('read only via OAC', 'lido só via OAC'), size=9, fill='--amber')
    f.rect(560, 182, 140, 70, stroke='--wire', fill='--panel')
    f.text(630, 206, 'shop-web', size=10, mono=True)
    f.text(630, 224, T('load balancer', 'balanceador'), size=9, fill='--paper-dim')
    f.line(466, 115, 556, 115, stroke='--amber', width=1.4, arrow=True)
    f.text(511, 105, 'assets', size=9.5, mono=True, fill='--amber')
    f.line(466, 217, 556, 217, stroke='--paper-dim', width=1.4, arrow=True)
    f.text(511, 207, 'web', size=9.5, mono=True, fill='--paper-dim')
    f.text(360, 304, T('a path chooses the behaviour; the behaviour chooses the origin and the cache',
                       'o caminho escolhe o comportamento; o comportamento escolhe a origem e o cache'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('The images are cached once for everybody; the pages pass through untouched.',
                'As imagens ficam em cache uma vez para todo mundo; as páginas passam sem ser tocadas.')
