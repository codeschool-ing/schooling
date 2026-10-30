"""Lesson 10: the directory."""
from figures import Fig, T, figure


@figure('l10-three-ways', 10)
def three_ways():
    f = Fig('l10-three-ways', 720, 250, T(
        'Three ways a company\'s existing directory reaches Google Cloud, one per row. Synchronise: '
        'GCDS copies users and groups one way into Cloud Identity, and Google checks the password. '
        'Synchronise with single sign-on: the same copies, but the password is checked by the '
        'company\'s identity provider. Workforce identity federation: no copies at all; a workforce pool '
        'trusts the company\'s identity provider directly.',
        'Três jeitos de o diretório que a empresa já tem chegar ao Google Cloud, um por linha. '
        'Sincronizar: o GCDS copia usuários e grupos num sentido só para o Cloud Identity, e o Google '
        'confere a senha. Sincronizar com single sign-on: as mesmas cópias, mas a senha é conferida pelo '
        'provedor de identidade da empresa. Workforce identity federation: cópia nenhuma; um pool de '
        'workforce confia direto no provedor de identidade da empresa.'))
    rows = [(T('synchronise', 'sincronizar'), T('password: Google', 'senha: Google'), True),
            (T('synchronise + single sign-on', 'sincronizar + single sign-on'),
             T('password: the company\'s provider', 'senha: o provedor da empresa'), True),
            (T('workforce identity federation', 'workforce identity federation'),
             T('no copies; trusted directly', 'sem cópias; confiança direta'), False)]
    for i, (name, note, copies) in enumerate(rows):
        y = 30 + i * 72
        f.text(20, y + 12, name, size=10.5, anchor='start', weight='600')
        f.rect(20, y + 24, 170, 34, stroke='--wire', fill='--panel')
        f.text(105, y + 41, T('company directory', 'diretório da empresa'), size=9.5)
        f.rect(500, y + 24, 200, 34, stroke='--phosphor', fill='--scan')
        if copies:
            f.text(600, y + 41, T('Cloud Identity copies', 'cópias no Cloud Identity'), size=9.5)
            f.arrow([(192, y + 41), (496, y + 41)], stroke='--paper', width=1.4)
            f.text(344, y + 32, T('one way', 'num sentido só'), size=9, fill='--paper-dim')
        else:
            f.text(600, y + 41, T('a workforce pool', 'um pool de workforce'), size=9.5)
            f.arrow([(496, y + 41), (192, y + 41)], stroke='--amber', width=1.4, dash='5 4')
            f.text(344, y + 32, T('trusts', 'confia'), size=9, fill='--amber')
        f.text(344, y + 54, note, size=9.5, fill='--paper-dim')
    return f, T('Copy the people in, sign in through them, or trust them where they are.',
                'Copiar as pessoas, entrar por elas, ou confiar nelas onde estão.')
