"""Lesson 3: the organisation's tree and its one bill."""
from figures import Fig, T, figure


def account(f, x, y, name, num, w=120):
    f.rect(x - w / 2, y - 20, w, 40, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(x, y - 7, name, size=10.5, mono=True)
    f.text(x, y + 9, num, size=9.5, mono=True, fill='--paper-dim')


def ou(f, x, y, name, w=120):
    f.rect(x - w / 2, y - 16, w, 32, stroke='--paper-dim', fill='--ink', width=1.4, rx=10)
    f.text(x, y, name, size=10.5, mono=True)


def elbow(f, x1, y1, x2, y2, mid):
    f.arrow([(x1, y1), (x1, mid), (x2, mid), (x2, y2)], stroke='--paper-dim', width=1.2)


@figure('l03-tree', 3)
def tree():
    f = Fig('l03-tree', 720, 380, T(
        'The shop\'s organisation as the transcripts built it. The root r-ucqy has four children: the '
        'management account 123456789012 and the organisational units Security, Workloads and '
        'Sandbox. Security holds the accounts security, 771971365420, and log-archive, 006227652844. '
        'Workloads holds two more units, Prod with the account shop-prod, 332178477898, and Staging '
        'with shop-staging, 073648902831. Sandbox holds the account sandbox, 652028714336. Accounts '
        'are drawn as boxes with a bright edge, organisational units as rounded boxes.',
        'A organização da loja como as transcrições a montaram. A raiz r-ucqy tem quatro filhos: a '
        'conta de gerenciamento 123456789012 e as unidades organizacionais Security, Workloads e '
        'Sandbox. Security guarda as contas security, 771971365420, e log-archive, 006227652844. '
        'Workloads guarda mais duas unidades, Prod com a conta shop-prod, 332178477898, e Staging com '
        'a shop-staging, 073648902831. Sandbox guarda a conta sandbox, 652028714336. Contas são '
        'desenhadas como caixas de borda clara, unidades organizacionais como caixas arredondadas.'))
    # the root
    f.rect(300, 22, 120, 36, stroke='--paper-dim', fill='--ink', width=2, rx=10)
    f.text(360, 40, 'Root  r-ucqy', size=10.5, mono=True)
    # the first level
    for x, kind, name, num in ((75, 'a', T('management', 'gerenciamento'), '123456789012'),
                               (215, 'o', 'Security', None), (430, 'o', 'Workloads', None),
                               (645, 'o', 'Sandbox', None)):
        if kind == 'a':
            f.rect(x - 60, 100, 120, 40, stroke='--phosphor', fill='--scan', width=1.4)
            f.text(x, 113, name, size=10)
            f.text(x, 129, num, size=9.5, mono=True, fill='--paper-dim')
            elbow(f, 360, 60, x, 97, 80)
        else:
            ou(f, x, 120, name)
            elbow(f, 360, 60, x, 101, 80)
    # Security's two accounts, stacked, the line running down their left
    account(f, 215, 210, 'security', '771971365420', w=130)
    account(f, 215, 290, 'log-archive', '006227652844', w=130)
    elbow(f, 215, 136, 215, 187, 160)
    f.path('M190.0 136.0 L190.0 160.0 L140.0 160.0 L140.0 290.0', stroke='--paper-dim', width=1.2)
    f.arrow([(140, 290), (147, 290)], stroke='--paper-dim', width=1.2)
    # Workloads, two more units and their accounts
    ou(f, 365, 210, 'Prod')
    ou(f, 495, 210, 'Staging')
    elbow(f, 430, 136, 365, 191, 165)
    elbow(f, 430, 136, 495, 191, 165)
    account(f, 365, 300, 'shop-prod', '332178477898')
    account(f, 495, 300, 'shop-staging', '073648902831')
    elbow(f, 365, 226, 365, 277, 250)
    elbow(f, 495, 226, 495, 277, 250)
    # Sandbox
    account(f, 645, 210, 'sandbox', '652028714336')
    elbow(f, 645, 136, 645, 187, 160)
    # the key
    f.rect(170, 346, 28, 18, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(206, 355, T('an account', 'uma conta'), size=10, anchor='start')
    f.rect(330, 346, 28, 18, stroke='--paper-dim', fill='--ink', width=1.4, rx=8)
    f.text(366, 355, T('an organisational unit, which holds no resources',
                       'uma unidade organizacional, que não guarda recursos'),
           size=10, anchor='start')
    return f, T('One root, one parent for everything, and the accounts at the leaves.',
                'Uma raiz, um pai para cada coisa, e as contas nas folhas.')


@figure('l03-pooling', 3)
def pooling():
    f = Fig('l03-pooling', 720, 290, T(
        'Two accounts each send 8,192 GB to the internet from São Paulo in a month. Billed apart, '
        'each stays inside the first tier, 10,240 GB at 0.15 dollars per GB, and the two pay 2,457.60 '
        'together. In one organisation the 16,384 GB are priced as one: 10,240 GB at 0.15 and 6,144 GB '
        'at 0.138, 2,383.87 in all. Price list of 16 September 2026.',
        'Duas contas mandam cada uma 8.192 GB para a internet a partir de São Paulo num mês. Cobradas '
        'separadas, cada uma fica dentro da primeira faixa, 10.240 GB a 0,15 dólar por GB, e as duas '
        'pagam 2.457,60 juntas. Numa organização os 16.384 GB são precificados como um só: 10.240 GB a '
        '0,15 e 6.144 GB a 0,138, 2.383,87 no total. Lista de preços de 16 de setembro de 2026.'))
    x0, scale = 150, 450 / 16384

    def gx(gb):
        return x0 + gb * scale
    tier = gx(10240)
    # in pieces, so the line stops at each bar rather than running through one
    for a, b in ((46, 58), (98, 150), (190, 232)):
        f.line(tier, a, tier, b, stroke='--paper-dim', dash='4 3')
    f.text(tier, 36, T('the first tier ends at 10,240 GB', 'a primeira faixa termina em 10.240 GB'),
           size=10, fill='--paper-dim')
    # apart
    f.text(140, 78, T('billed apart', 'cobradas separadas'), size=10.5, anchor='end', weight='600')
    f.rect(gx(0), 60, gx(8192) - gx(0) - 1, 36, stroke='--amber', fill='--scan', width=1.4)
    f.text((gx(0) + gx(8192)) / 2, 78, T('shop-prod: 8,192 at 0.15', 'shop-prod: 8.192 a 0,15'),
           size=10)
    f.rect(gx(8192) + 1, 60, gx(16384) - gx(8192) - 1, 36, stroke='--amber', fill='--scan', width=1.4)
    f.text((gx(8192) + gx(16384)) / 2, 78,
           T('shop-staging: 8,192 at 0.15', 'shop-staging: 8.192 a 0,15'), size=10)
    f.text(612, 78, T('2,457.60', '2.457,60'), size=11, anchor='start', weight='600')
    # together
    f.text(140, 170, T('one organisation', 'uma organização'), size=10.5, anchor='end', weight='600')
    f.rect(gx(0), 152, tier - gx(0) - 1, 36, stroke='--amber', fill='--scan', width=1.4)
    f.text((gx(0) + tier) / 2, 170, T('10,240 at 0.15', '10.240 a 0,15'), size=10)
    f.rect(tier + 1, 152, gx(16384) - tier - 1, 36, stroke='--phosphor', fill='--panel', width=1.4)
    f.text((tier + gx(16384)) / 2, 170, T('6,144 at 0.138', '6.144 a 0,138'), size=10)
    f.text(612, 170, T('2,383.87', '2.383,87'), size=11, anchor='start', weight='600',
           fill='--phosphor')
    # the axis
    f.line(gx(0), 240, gx(16384), 240, stroke='--paper-dim')
    for gb, lab in ((0, '0'), (8192, '8,192'), (10240, '10,240'), (16384, '16,384')):
        f.line(gx(gb), 236, gx(gb), 244, stroke='--paper-dim')
        f.text(gx(gb), 256, lab if T('en', 'pt') == 'en' else lab.replace(',', '.'), size=9.5,
               mono=True, fill='--paper-dim')
    f.text(360, 278, T('gigabytes in a month, dollars per gigabyte, price list of 16 September 2026',
                       'gigabytes no mês, dólares por gigabyte, lista de preços de 16 de setembro de 2026'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('The same 16,384 GB, priced apart and priced together.',
                'Os mesmos 16.384 GB, precificados separados e juntos.')
