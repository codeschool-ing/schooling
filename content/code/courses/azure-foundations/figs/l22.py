"""Lesson 22: Load Balancer, Application Gateway, Front Door and Traffic Manager."""
from figures import Fig, T, figure


@figure('l22-quadrant', 22)
def quadrant():
    f = Fig('l22-quadrant', 720, 330, T(
        'A two by two grid. Columns: layer 4, which reads addresses and ports, and layer 7, which '
        'reads HTTP requests. Rows: regional and global. Regional and layer 4 is Azure Load Balancer. '
        'Regional and layer 7 is Application Gateway. Global and layer 4 is Traffic Manager, which '
        'answers in DNS and carries no traffic. Global and layer 7 is Front Door, a proxy at '
        'Microsoft\'s edge locations.',
        'Uma grade de dois por dois. Colunas: camada 4, que lê endereços e portas, e camada 7, que lê '
        'pedidos HTTP. Linhas: regional e global. Regional e camada 4 é o Azure Load Balancer. Regional '
        'e camada 7 é o Application Gateway. Global e camada 4 é o Traffic Manager, que responde no DNS '
        'e não carrega tráfego. Global e camada 7 é o Front Door, um proxy nas localidades de borda da '
        'Microsoft.'))
    f.text(320, 30, T('layer 4: addresses and ports', 'camada 4: endereços e portas'), size=10.5,
           weight='600', fill='--paper-dim')
    f.text(565, 30, T('layer 7: HTTP requests', 'camada 7: pedidos HTTP'), size=10.5, weight='600',
           fill='--paper-dim')
    f.text(105, 115, T('regional', 'regional'), size=10.5, weight='600', fill='--paper-dim')
    f.text(105, 245, T('global', 'global'), size=10.5, weight='600', fill='--paper-dim')
    cells = [
        (200, 50, 'Load Balancer', T('spreads TCP and UDP flows', 'espalha fluxos TCP e UDP'),
         T('the caller\'s address arrives', 'o endereço de quem chama chega'), '--wire'),
        (445, 50, 'Application Gateway', T('a reverse proxy in your network', 'um proxy reverso na sua rede'),
         T('routes by host and path', 'roteia por host e caminho'), '--wire'),
        (200, 180, 'Traffic Manager', T('answers in DNS', 'responde no DNS'),
         T('no packet passes through it', 'nenhum pacote passa por ele'), '--amber'),
        (445, 180, 'Front Door', T('a proxy at the edge', 'um proxy na borda'),
         T('cache and WAF before any region', 'cache e WAF antes de qualquer região'), '--phosphor'),
    ]
    for x, y, name, a, b, stroke in cells:
        f.rect(x, y, 240, 120, stroke=stroke, fill='--panel')
        f.text(x + 120, y + 32, name, size=12, weight='600')
        f.text(x + 120, y + 64, a, size=10, fill='--paper-dim')
        f.text(x + 120, y + 86, b, size=10, fill='--paper-dim')
    return f, T('Two questions with two answers each, and one service in every box.',
                'Duas perguntas com duas respostas cada, e um serviço em cada caixa.')


@figure('l22-shop-path', 22)
def shop_path():
    f = Fig('l22-shop-path', 720, 300, T(
        'The path of a customer\'s request in the shop\'s design, from left to right. A customer '
        'looks up shop.example and connects to the nearest Front Door edge location. Front Door carries '
        'the request to brazilsouth, to an Application Gateway in the subnet snet-agw. The gateway '
        'sends /api/ to the application pool and the pages to the web pool in snet-web. Web machines '
        'call the application tier through an internal Load Balancer in snet-app. All of it except the '
        'edge is inside vnet-shop-prod.',
        'O caminho do pedido de um cliente no desenho da loja, da esquerda para a direita. Um cliente '
        'procura shop.example e se conecta à localidade de borda do Front Door mais próxima. O Front Door '
        'leva o pedido a brazilsouth, a um Application Gateway na sub-rede snet-agw. O gateway manda /api/ '
        'para o pool da aplicação e as páginas para o pool web em snet-web. As máquinas web chamam a '
        'camada de aplicação por um Load Balancer interno em snet-app. Tudo, menos a borda, está dentro '
        'de vnet-shop-prod.'))
    f.rect(16, 110, 100, 50, stroke='--paper-dim', fill='--panel', rx=25)
    f.text(66, 128, T('customer', 'cliente'), size=10)
    f.text(66, 145, 'shop.example', size=9, mono=True, fill='--paper-dim')
    f.rect(140, 100, 118, 70, stroke='--phosphor', fill='--panel')
    f.text(199, 124, 'Front Door', size=11, weight='600')
    f.text(199, 146, T('nearest edge', 'borda mais próxima'), size=9.5, fill='--paper-dim')
    f.arrow([(117, 135), (139, 135)], stroke='--paper-dim')
    f.rect(280, 30, 424, 252, stroke='--wire', fill='--ink', dash='5 4')
    f.text(296, 46, 'vnet-shop-prod', size=10, anchor='start', mono=True, fill='--paper-dim')
    f.text(690, 46, 'brazilsouth', size=10, anchor='end', mono=True, fill='--paper-dim')
    f.arrow([(259, 135), (295, 135)], stroke='--phosphor')
    f.rect(296, 96, 120, 78, stroke='--wire', fill='--panel')
    f.text(356, 118, T('App Gateway', 'App Gateway'), size=10.5, weight='600')
    f.text(356, 138, 'snet-agw', size=9.5, mono=True, fill='--paper-dim')
    f.text(356, 156, T('splits /api/', 'separa /api/'), size=9.5, fill='--paper-dim')
    f.rect(444, 64, 108, 56, stroke='--wire', fill='--panel')
    f.text(498, 84, T('web pool', 'pool web'), size=10)
    f.text(498, 103, 'snet-web', size=9.5, mono=True, fill='--paper-dim')
    f.rect(444, 196, 108, 56, stroke='--wire', fill='--panel')
    f.text(498, 216, T('internal LB', 'LB interno'), size=10)
    f.text(498, 235, 'snet-app', size=9.5, mono=True, fill='--paper-dim')
    f.rect(580, 196, 108, 56, stroke='--wire', fill='--panel')
    f.text(634, 216, T('app pool', 'pool da aplicação'), size=10)
    f.text(634, 235, 'snet-app', size=9.5, mono=True, fill='--paper-dim')
    f.arrow([(417, 120), (443, 92)], stroke='--paper-dim')
    f.arrow([(417, 150), (430, 150), (430, 266), (634, 266), (634, 253)], stroke='--amber')
    f.arrow([(498, 121), (498, 195)], stroke='--paper-dim')
    f.arrow([(553, 224), (579, 224)], stroke='--paper-dim')
    f.text(600, 150, T('/api/ goes straight to the app pool', '/api/ vai direto ao pool da aplicação'),
           size=9.5, fill='--amber')
    return f, T('Front Door chooses the region, Application Gateway the pool, and the internal load balancer the machine.',
                'O Front Door escolhe a região, o Application Gateway o pool, e o load balancer interno a máquina.')
