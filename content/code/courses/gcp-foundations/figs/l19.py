"""Lesson 19: Cloud DNS."""
from figures import Fig, T, figure


@figure('l19-order', 19)
def order():
    f = Fig('l19-order', 720, 290, T(
        'A machine in the planner network asks the metadata server\'s resolver at 169.254.169.254 for a '
        'name. The resolver tries three places in order and stops at the first that holds the name. First, '
        'the private zones the network may see, the most specific first: office.planner.internal is '
        'forwarded to the office server at 192.168.0.53, planner.internal is answered by Cloud DNS, and '
        'googleapis.com is the override that sends every API to the private range. Second, the internal '
        'names Compute Engine gives machines. Third, public DNS on the internet. A note says that a private '
        'zone takes its whole domain: a name missing from it is answered as not existing, and the internet '
        'is never asked.',
        'Uma máquina na rede planner pergunta um nome ao resolvedor do servidor de metadados em '
        '169.254.169.254. O resolvedor tenta três lugares em ordem e para no primeiro que tem o nome. '
        'Primeiro, as zonas privadas que a rede pode ver, a mais específica primeiro: office.planner.internal '
        'é encaminhada ao servidor do escritório em 192.168.0.53, planner.internal é respondida pelo Cloud '
        'DNS, e googleapis.com é a sobreposição que manda toda API para a faixa privada. Segundo, os nomes '
        'internos que o Compute Engine dá às máquinas. Terceiro, o DNS público da internet. Uma nota diz que '
        'uma zona privada toma o domínio inteiro: um nome que falta nela é respondido como inexistente, e a '
        'internet nunca é perguntada.'))
    f.rect(20, 100, 170, 70, stroke='--wire', fill='--panel', width=1.2)
    f.text(105, 122, T('a machine asks', 'uma máquina pergunta'), size=10)
    f.text(105, 142, '169.254.169.254', size=9.5, mono=True, fill='--paper-dim')
    f.rect(260, 20, 440, 120, stroke='--phosphor', fill='--ink', width=1.6)
    f.text(276, 38, T('1. private zones, most specific first', '1. zonas privadas, a mais específica primeiro'),
           size=10, anchor='start', fill='--phosphor')
    rows = [('office.planner.internal.', T('forwarded to 192.168.0.53', 'encaminhada a 192.168.0.53')),
            ('planner.internal.', T('answered by Cloud DNS', 'respondida pelo Cloud DNS')),
            ('googleapis.com.', T('override: the private range', 'sobreposição: a faixa privada'))]
    for i, (name, what) in enumerate(rows):
        y = 64 + i * 26
        f.text(276, y, name, size=9.5, mono=True, anchor='start')
        f.text(684, y, what, size=9, anchor='end', fill='--paper-dim')
    f.rect(260, 156, 440, 34, stroke='--wire', fill='--panel', width=1.2)
    f.text(276, 173, T('2. internal names of machines', '2. nomes internos das máquinas'), size=10, anchor='start')
    f.text(684, 173, 'NAME.ZONE.c.PROJECT.internal', size=8.5, mono=True, anchor='end', fill='--paper-dim')
    f.rect(260, 206, 440, 34, stroke='--wire', fill='--panel', width=1.2)
    f.text(276, 223, T('3. public DNS', '3. DNS público'), size=10, anchor='start')
    f.arrow([(192, 120), (256, 80)], stroke='--phosphor', width=1.6)
    f.text(360, 270, T('the first place that holds the domain answers, even with no such name',
                       'o primeiro lugar que tem o domínio responde, mesmo que o nome não exista'), size=10)
    return f, T('A private zone is asked first, and takes its whole domain.',
                'Uma zona privada é perguntada primeiro, e toma o domínio inteiro.')
