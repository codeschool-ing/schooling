"""Lesson 22: gcloud configurations."""
from figures import Fig, T, figure


@figure('l22-precedence', 22)
def precedence():
    f = Fig('l22-precedence', 720, 270, T(
        'Where gcloud takes the value of core/project from, as four stacked layers, the most specific on '
        'top. A flag on the command, --project=planner-staging, wins over everything. Below it, an '
        'environment variable, CLOUDSDK_CORE_PROJECT. Below that, the configuration the command runs with, '
        'chosen by --configuration, by CLOUDSDK_ACTIVE_CONFIG_NAME or by being the active one: default holds '
        'planner-dev and prod holds planner-prod. At the bottom, nothing, where the command asks or refuses.',
        'De onde o gcloud tira o valor de core/project, como quatro camadas empilhadas, a mais específica em '
        'cima. Uma opção no comando, --project=planner-staging, ganha de tudo. Abaixo dela, uma variável de '
        'ambiente, CLOUDSDK_CORE_PROJECT. Abaixo disso, a configuração com que o comando roda, escolhida por '
        '--configuration, por CLOUDSDK_ACTIVE_CONFIG_NAME ou por ser a ativa: default tem planner-dev e prod '
        'tem planner-prod. Embaixo, nada, e o comando pergunta ou recusa.'))
    rows = [(T('1. a flag', '1. uma opção'), '--project=planner-staging', '--amber'),
            (T('2. an environment variable', '2. uma variável de ambiente'), 'CLOUDSDK_CORE_PROJECT', '--amber'),
            (T('3. the configuration', '3. a configuração'), 'default: planner-dev · prod: planner-prod', '--phosphor'),
            (T('4. nothing', '4. nada'), T('the command asks or refuses', 'o comando pergunta ou recusa'), '--wire')]
    for i, (name, value, colour) in enumerate(rows):
        y = 20 + i * 52
        f.rect(60 + i * 20, y, 600 - i * 40, 42, stroke=colour, fill='--panel', width=1.4)
        f.text(80 + i * 20, y + 21, name, size=10, anchor='start')
        f.text(640 - i * 20, y + 21, value, size=9, mono=i < 3, anchor='end', fill='--paper-dim')
    f.text(360, 238, T('the first layer that holds a value wins', 'a primeira camada que tem um valor ganha'), size=10)
    f.text(360, 258, T('the configuration is chosen by --configuration, CLOUDSDK_ACTIVE_CONFIG_NAME, or being active',
                       'a configuração é escolhida por --configuration, CLOUDSDK_ACTIVE_CONFIG_NAME, ou por ser a ativa'),
           size=9, fill='--paper-dim')
    return f, T('The most specific place a property is set wins.',
                'O lugar mais específico em que uma propriedade é definida ganha.')
