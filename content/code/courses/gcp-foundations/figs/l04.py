"""Lesson 4: organisation policies."""
from figures import Fig, T, figure


@figure('l04-merge', 4)
def merge():
    f = Fig('l04-merge', 720, 320, T(
        'The effective value of gcp.resourceLocations in three places. The organisation allows '
        'in:southamerica-locations and in:us-locations. The folder non-production writes nothing, so '
        'its projects inherit both. The folder production writes its own policy without inheriting, '
        'allowing only in:southamerica-east1-locations, so its projects may use São Paulo alone. A '
        'dashed box shows the mistake: had production inherited, its value would have been added to '
        'the organisation\'s, and production could use the United States too.',
        'O valor efetivo de gcp.resourceLocations em três lugares. A organização permite '
        'in:southamerica-locations e in:us-locations. A pasta non-production não escreve nada, então os '
        'projetos dela herdam os dois. A pasta production escreve uma política própria sem herdar, '
        'permitindo só in:southamerica-east1-locations, então os projetos dela só podem usar São Paulo. '
        'Uma caixa tracejada mostra o erro: se production herdasse, o valor dela seria somado ao da '
        'organização, e a produção poderia usar os Estados Unidos também.'))
    f.rect(220, 16, 280, 64, stroke='--amber', fill='--panel', width=1.6)
    f.text(360, 32, T('organisation', 'organização'), size=9.5, fill='--paper-dim')
    f.text(360, 50, 'in:southamerica-locations', size=9.5, mono=True)
    f.text(360, 66, 'in:us-locations', size=9.5, mono=True)
    f.line(300, 80, 140, 116, stroke='--paper-dim')
    f.line(420, 80, 560, 116, stroke='--paper-dim')
    # non-production
    f.rect(30, 116, 220, 96, stroke='--amber', fill='--ink', dash='5 3')
    f.text(140, 132, 'non-production', size=10, mono=True)
    f.text(140, 150, T('no policy of its own', 'nenhuma política própria'), size=9.5, fill='--paper-dim')
    f.text(140, 172, T('effective:', 'efetivo:'), size=9.5, fill='--phosphor')
    f.text(140, 188, 'southamerica + us', size=9.5, mono=True, fill='--phosphor')
    # production
    f.rect(450, 116, 240, 96, stroke='--amber', fill='--ink', dash='5 3')
    f.text(570, 132, 'production', size=10, mono=True)
    f.text(570, 150, 'inherit_from_parent = false', size=9, mono=True)
    f.text(570, 166, 'in:southamerica-east1-locations', size=9, mono=True)
    f.text(570, 188, T('effective: São Paulo only', 'efetivo: só São Paulo'), size=9.5, fill='--phosphor')
    # the mistake
    f.rect(450, 236, 240, 70, stroke='--paper-dim', fill='--panel', dash='3 3')
    f.text(570, 252, T('had it inherited (true):', 'se herdasse (true):'), size=9.5, fill='--amber')
    f.text(570, 270, T('its value is added to the parent\'s', 'o valor dela soma ao do pai'), size=9.5)
    f.text(570, 288, T('effective: southamerica + us', 'efetivo: southamerica + us'), size=9.5,
           fill='--amber')
    f.text(250, 262, T('for an allow list, inheriting widens', 'numa lista de permissão, herdar amplia'),
           size=10.5, weight='600', fill='--amber')
    f.text(250, 282, T('for a deny list, it narrows', 'numa lista de negação, estreita'),
           size=10, fill='--paper-dim')
    return f, T('Production replaces the organisation\'s list. Merging would have widened it.',
                'A produção substitui a lista da organização. Mesclar a teria ampliado.')
