"""Lesson 24: client libraries and REST."""
from figures import Fig, T, figure


@figure('l24-adc', 24)
def adc():
    f = Fig('l24-adc', 720, 260, T(
        'A program calls a client library, which looks for credentials in a fixed order and takes the first '
        'it finds. First, the environment variable GOOGLE_APPLICATION_CREDENTIALS naming a file, which in CI '
        'is a federation file and as a last resort a service account key. Second, the file that gcloud auth '
        'application-default login writes, which on a laptop is the person\'s own credential. Third, the '
        'metadata server at 169.254.169.254, which on Google Cloud answers for the attached service account. '
        'If none answers, the library raises DefaultCredentialsError, which is what the lab\'s laptop gets.',
        'Um programa chama uma biblioteca cliente, que procura credenciais numa ordem fixa e pega a primeira '
        'que acha. Primeiro, a variável de ambiente GOOGLE_APPLICATION_CREDENTIALS nomeando um arquivo, que '
        'num CI é um arquivo de federação e em último caso uma chave de conta de serviço. Segundo, o arquivo '
        'que o gcloud auth application-default login escreve, que num laptop é a credencial da própria pessoa. '
        'Terceiro, o servidor de metadados em 169.254.169.254, que no Google Cloud responde pela conta de '
        'serviço presa. Se nenhum responde, a biblioteca levanta DefaultCredentialsError, que é o que o laptop '
        'do laboratório recebe.'))
    f.rect(20, 90, 150, 60, stroke='--wire', fill='--panel', width=1.2)
    f.text(95, 112, T('a program', 'um programa'), size=10)
    f.text(95, 130, 'publish.py', size=9, mono=True, fill='--paper-dim')
    rows = [('1. GOOGLE_APPLICATION_CREDENTIALS', T('CI: a federation file', 'CI: um arquivo de federação')),
            ('2. application_default_credentials.json', T('a laptop: the person', 'um laptop: a pessoa')),
            ('3. 169.254.169.254', T('Google Cloud: the attached account', 'Google Cloud: a conta presa'))]
    for i, (name, where) in enumerate(rows):
        y = 20 + i * 62
        f.rect(240, y, 460, 50, stroke='--phosphor', fill='--panel', width=1.4)
        f.text(256, y + 18, name, size=9.5, mono=True, anchor='start')
        f.text(256, y + 36, where, size=9, anchor='start', fill='--paper-dim')
    f.arrow([(172, 110), (236, 45)], stroke='--phosphor', width=1.4)
    f.text(470, 222, T('none answers: DefaultCredentialsError, as on the lab\'s laptop',
                       'nenhum responde: DefaultCredentialsError, como no laptop do laboratório'), size=9.5, fill='--amber')
    f.text(360, 246, T('the first that answers is used; the program names none',
                       'o primeiro que responde é usado; o programa não nomeia nenhum'), size=10)
    return f, T('The library looks in three places, in order; where it runs decides what it finds.',
                'A biblioteca procura em três lugares, em ordem; onde ela roda decide o que acha.')
