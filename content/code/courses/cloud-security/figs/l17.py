"""Lesson 17: residency and sovereignty are different reaches."""
from figures import Fig, T, figure


@figure('l17-reach', 17)
def reach():
    f = Fig('l17-reach', 720, 320, T(
        'Residency against sovereignty, for the clinic. Two regions: São Paulo, sa-east-1, holds '
        'clinic-records and clinic-exports; Northern Virginia, us-east-1, holds clinic-backups-us. '
        'Residency is where each copy is: two in Brazil, one in the United States. Sovereignty is '
        'whose law reaches them. Brazilian law, the LGPD, reaches the clinic and so every copy it '
        'controls. United States law, through the CLOUD Act, reaches the provider, a United States '
        'company, and so every copy it holds, in both regions.',
        'Residência contra soberania, para a clínica. Duas regiões: São Paulo, sa-east-1, guarda '
        'clinic-records e clinic-exports; Norte da Virgínia, us-east-1, guarda clinic-backups-us. '
        'Residência é onde cada cópia está: duas no Brasil, uma nos Estados Unidos. Soberania é qual '
        'lei as alcança. A lei brasileira, a LGPD, alcança a clínica e portanto toda cópia que ela '
        'controla. A lei dos Estados Unidos, pelo CLOUD Act, alcança o provedor, uma empresa '
        'americana, e portanto toda cópia que ele guarda, nas duas regiões.'))
    # the two laws, as bands across the top
    f.rect(40, 20, 640, 34, stroke='--phosphor', fill='--panel')
    f.text(360, 37, T('Brazilian law (LGPD): reaches the clinic, so every copy it controls',
                      'lei brasileira (LGPD): alcança a clínica, logo toda cópia que ela controla'),
           size=10.5, fill='--phosphor')
    f.rect(40, 64, 640, 34, stroke='--amber', fill='--panel')
    f.text(360, 81, T('United States law (CLOUD Act): reaches the provider, so every copy it holds',
                      'lei dos EUA (CLOUD Act): alcança o provedor, logo toda cópia que ele guarda'),
           size=10.5, fill='--amber')
    regions = [
        (40, T('São Paulo — Brazil', 'São Paulo — Brasil'), 'sa-east-1', ['clinic-records', 'clinic-exports'], '--wire'),
        (380, T('Northern Virginia — United States', 'Norte da Virgínia — Estados Unidos'), 'us-east-1', ['clinic-backups-us'], '--amber'),
    ]
    for x, name, code, buckets, edge in regions:
        f.rect(x, 128, 300, 140, stroke='--paper-dim', fill='--scan', dash='5 4')
        f.text(x + 150, 148, name, size=11, weight='600')
        f.text(x + 150, 166, code, size=10, mono=True, fill='--paper-dim')
        for i, b in enumerate(buckets):
            f.rect(x + 40, 182 + i * 38, 220, 30, stroke=edge, fill='--panel', width=1.3)
            f.text(x + 150, 197 + i * 38, b, size=10, mono=True)
    f.text(360, 296, T('residency: where each copy is — two in Brazil, one abroad',
                       'residência: onde cada cópia está — duas no Brasil, uma fora'),
           size=10.5, fill='--paper-dim')
    return f, T('Picking a region decides residency, the bottom of the drawing. It does not decide the '
                'top: both laws reach the copy in São Paulo, because one follows the clinic and the '
                'other follows the provider.',
                'Escolher a região decide a residência, a parte de baixo do desenho. Não decide a de '
                'cima: as duas leis alcançam a cópia em São Paulo, porque uma segue a clínica e a outra '
                'segue o provedor.')
