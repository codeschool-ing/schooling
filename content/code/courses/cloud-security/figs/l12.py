"""Lesson 12: where infrastructure code shows a value, hides it, or keeps it."""
from figures import Fig, T, figure


@figure('l12-three-places', 12)
def three_places():
    f = Fig('l12-three-places', 720, 300, T(
        'Three places a value passes through when infrastructure is written as code, and what each '
        'one does with it. The repository: the current files can be clean while the history keeps '
        'every line ever committed, including a removed key. The plan on the screen: a sensitive '
        'value is shown as hidden, and a value that depends on something not yet created is shown '
        'as known after apply, so a reviewer sees neither. The state file: every attribute in clear '
        'text, including a password the screen hid, and a backup beside it holding the version '
        'before the last apply.',
        'Três lugares por onde um valor passa quando a infraestrutura é escrita como código, e o que '
        'cada um faz com ele. O repositório: os arquivos atuais podem estar limpos enquanto o '
        'histórico guarda toda linha já commitada, inclusive uma chave removida. O plano na tela: um '
        'valor sensível aparece escondido, e um valor que depende de algo ainda não criado aparece '
        'como known after apply, então quem revisa não vê nenhum dos dois. O arquivo de estado: '
        'todo atributo em texto claro, inclusive uma senha que a tela escondeu, e um backup ao lado '
        'com a versão anterior ao último apply.'))
    cols = [
        (20, T('the repository', 'o repositório'), [
            (T('today\'s files', 'os arquivos de hoje'), T('clean', 'limpos'), '--phosphor'),
            (T('the history', 'o histórico'), 'access_key = "AKIA…"', '--amber'),
        ], T('every clone keeps the history', 'todo clone guarda o histórico')),
        (260, T('the plan on the screen', 'o plano na tela'), [
            ('secret_string', '(sensitive value)', '--paper-dim'),
            ('policy', '(known after apply)', '--paper-dim'),
        ], T('the reviewer sees neither', 'quem revisa não vê nenhum')),
        (500, T('the state file', 'o arquivo de estado'), [
            ('terraform.tfstate', '"Clinic-2019-…"', '--amber'),
            ('terraform.tfstate.backup', T('the old value', 'o valor antigo'), '--amber'),
        ], T('whoever reads it reads the secret', 'quem o lê lê o segredo')),
    ]
    for x, title, rows, foot in cols:
        f.rect(x, 20, 200, 250, stroke='--phosphor', fill='--panel')
        f.text(x + 100, 42, title, size=11.5, weight='600')
        y = 66
        for label, value, colour in rows:
            f.rect(x + 12, y, 176, 64, stroke='--wire', fill='--scan')
            mono = label.startswith(('secret', 'policy', 'terraform'))
            f.text(x + 100, y + 20, label, size=10, mono=mono, fill='--paper-dim')
            vmono = value.startswith(('(', '"', 'access'))
            f.text(x + 100, y + 42, value, size=10, mono=vmono, fill=colour)
            y += 76
        f.text(x + 100, 250, foot, size=9.5, italic=True, fill='--paper-dim')
    return f, T('A secret marked sensitive is hidden from the screen and kept everywhere else. Each '
                'of the three needs its own answer: rotate what reached the history, make plan values '
                'knowable, keep secrets out of the state.',
                'Um segredo marcado como sensível some da tela e fica guardado em todo o resto. Cada um '
                'dos três pede a sua resposta: trocar o que chegou ao histórico, tornar conhecíveis os '
                'valores do plano, manter segredos fora do estado.')
