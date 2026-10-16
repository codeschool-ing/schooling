"""Lesson 1: regions, zones, and what crossing them costs."""
from figures import Fig, T, figure


@figure('l01-zone-names', 1)
def zone_names():
    f = Fig('l01-zone-names', 720, 290, T(
        'Zone names against zone ids in us-east-1. In the middle, three physical zones, labelled with '
        'their ids use1-az1, use1-az2 and use1-az6. On the left, the account from the transcript: '
        'us-east-1a points at use1-az6, us-east-1b at use1-az1 and us-east-1c at use1-az2. On the '
        'right, another account, drawn as an illustration: its us-east-1a points at use1-az2, b at '
        'use1-az6 and c at use1-az1. The same name lands in different zones; the id does not change.',
        'Nomes de zona contra ids de zona em us-east-1. No meio, três zonas físicas, rotuladas com '
        'seus ids use1-az1, use1-az2 e use1-az6. À esquerda, a conta da transcrição: us-east-1a '
        'aponta para use1-az6, us-east-1b para use1-az1 e us-east-1c para use1-az2. À direita, outra '
        'conta, desenhada como ilustração: seu us-east-1a aponta para use1-az2, o b para use1-az6 e o '
        'c para use1-az1. O mesmo nome cai em zonas diferentes; o id não muda.'))
    f.text(110, 26, T('this account', 'esta conta'), size=11, weight='600', fill='--paper-dim')
    f.text(360, 26, T('the physical zones', 'as zonas físicas'), size=11, weight='600',
           fill='--paper-dim')
    f.text(610, 26, T('another account', 'outra conta'), size=11, weight='600', fill='--paper-dim')
    f.text(610, 44, T('(an illustration)', '(uma ilustração)'), size=9.5, fill='--paper-dim',
           italic=True)
    ids = ['use1-az1', 'use1-az2', 'use1-az6']
    ys = [90, 160, 230]
    for y, i in zip(ys, ids):
        f.rect(290, y - 24, 140, 48, stroke='--phosphor', fill='--scan', width=1.5)
        f.text(360, y, i, size=11, mono=True)
    names = ['us-east-1a', 'us-east-1b', 'us-east-1c']
    left = {'us-east-1a': 'use1-az6', 'us-east-1b': 'use1-az1', 'us-east-1c': 'use1-az2'}
    right = {'us-east-1a': 'use1-az2', 'us-east-1b': 'use1-az6', 'us-east-1c': 'use1-az1'}
    for y, n in zip(ys, names):
        f.rect(40, y - 18, 140, 36, stroke='--wire', fill='--panel')
        f.text(110, y, n, size=10.5, mono=True)
        ty = ys[ids.index(left[n])]
        f.arrow([(182, y), (286, ty)], stroke='--paper-dim', width=1.3)
        f.rect(540, y - 18, 140, 36, stroke='--wire', fill='--panel', dash='4 3')
        f.text(610, y, n, size=10.5, mono=True)
        ty = ys[ids.index(right[n])]
        f.arrow([(538, y), (434, ty)], stroke='--amber', width=1.3)
    f.text(360, 276, T('coordinate two accounts by the id in the middle',
                       'coordene duas contas pelo id do meio'), size=10, fill='--amber')
    return f, T('A zone name is a label your account gives a zone. A zone id is the zone.',
                'Um nome de zona é o rótulo que a sua conta dá a uma zona. Um id de zona é a zona.')


@figure('l01-crossings', 1)
def crossings():
    f = Fig('l01-crossings', 720, 420, T(
        'What crossing each boundary costs, from the price list of 16 September 2026, in dollars per '
        'gigabyte. Inside the São Paulo region, sa-east-1, two Availability Zones. Between two '
        'machines in the same zone: free. Between the two zones: 0.01 each way. From São Paulo to '
        'Virginia, us-east-1: 0.138. From Virginia to São Paulo: 0.02. From São Paulo out to the '
        'internet: 0.15 for the first 10 TB of a month. In from the internet: free.',
        'Quanto custa atravessar cada fronteira, pela lista de preços de 16 de setembro de 2026, em '
        'dólares por gigabyte. Dentro da região de São Paulo, sa-east-1, duas Availability Zones. '
        'Entre duas máquinas na mesma zona: grátis. Entre as duas zonas: 0,01 em cada sentido. De '
        'São Paulo para a Virgínia, us-east-1: 0,138. Da Virgínia para São Paulo: 0,02. De São Paulo '
        'para a internet: 0,15 nos primeiros 10 TB do mês. Da internet para dentro: grátis.'))
    # the region
    f.rect(20, 40, 430, 240, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(36, 58, 'sa-east-1', size=11, anchor='start', mono=True, fill='--paper-dim')
    for x, z in ((45, 'sa-east-1a'), (250, 'sa-east-1b')):
        f.rect(x, 80, 180, 170, stroke='--wire', fill='--scan')
        f.text(x + 90, 98, z, size=10.5, mono=True)
    # two machines in zone a
    f.rect(58, 130, 52, 34, stroke='--phosphor', fill='--panel')
    f.rect(160, 130, 52, 34, stroke='--phosphor', fill='--panel')
    f.line(112, 147, 158, 147, stroke='--phosphor', width=1.4, arrow=True, start=True)
    f.text(135, 190, T('same zone: free', 'mesma zona: grátis'), size=10, fill='--phosphor')
    f.rect(310, 130, 60, 34, stroke='--phosphor', fill='--panel')
    f.line(214, 147, 308, 147, stroke='--amber', width=1.4, arrow=True, start=True)
    f.text(340, 210, T('between zones:', 'entre zonas:'), size=10, fill='--amber')
    f.text(340, 226, T('0.01 each way', '0,01 em cada sentido'), size=10, fill='--amber')
    # Virginia
    f.rect(520, 40, 180, 110, stroke='--paper-dim', fill='--ink', dash='6 4')
    f.text(536, 58, 'us-east-1', size=11, anchor='start', mono=True, fill='--paper-dim')
    f.rect(580, 85, 60, 34, stroke='--phosphor', fill='--panel')
    # each crossing is drawn in two pieces, inside the zone and beyond it, so
    # that no single line runs through a box it does not belong to
    f.line(372, 140, 432, 127, stroke='--amber', width=1.4)
    f.arrow([(432, 127), (577, 95)], stroke='--amber', width=1.4)
    f.text(476, 104, T('0.138', '0,138'), size=10.5, fill='--amber',
           weight='600')
    f.line(577, 112, 432, 145, stroke='--phosphor', width=1.4)
    f.arrow([(432, 145), (374, 158)], stroke='--phosphor', width=1.4)
    f.text(486, 152, T('0.02', '0,02'), size=10.5, fill='--phosphor',
           weight='600')
    # the internet
    f.rect(130, 330, 210, 56, stroke='--paper-dim', fill='--panel', rx=26)
    f.text(235, 358, T('the internet', 'a internet'), size=11, weight='600')
    f.line(195, 283, 195, 326, stroke='--amber', width=1.4, arrow=True)
    f.text(185, 305, T('out: 0.15', 'saída: 0,15'), size=10.5, fill='--amber', weight='600',
           anchor='end')
    f.line(275, 326, 275, 283, stroke='--phosphor', width=1.4, arrow=True)
    f.text(285, 305, T('in: free', 'entrada: grátis'), size=10.5, fill='--phosphor', weight='600',
           anchor='start')
    f.text(360, 408, T('dollars per gigabyte, price list of 16 September 2026',
                       'dólares por gigabyte, lista de preços de 16 de setembro de 2026'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('The arrows carry the price, not the boxes. Leaving São Paulo is the dear direction.',
                'O preço está nas setas, não nas caixas. Sair de São Paulo é o sentido caro.')
