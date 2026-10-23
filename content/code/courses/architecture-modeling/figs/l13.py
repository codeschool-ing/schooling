"""Lesson 13: architecture review."""
from figures import Fig, T, figure


@figure('l13-atam', 13)
def atam():
    f = Fig('l13-atam', 720, 300, T(
        'ATAM\'s nine steps in four phases, left to right. Presentation: 1 present the ATAM, 2 present '
        'the business drivers, 3 present the architecture. Investigation and analysis: 4 identify the '
        'approaches, 5 build the utility tree, 6 analyse the approaches. Testing: 7 brainstorm and '
        'prioritise scenarios with more stakeholders, 8 analyse again. Reporting: 9 present the results: '
        'risks, non-risks, sensitivity points, trade-off points and risk themes.',
        'Os nove passos do ATAM em quatro fases, da esquerda para a direita. Apresentação: 1 apresentar '
        'o ATAM, 2 apresentar os direcionadores de negócio, 3 apresentar a arquitetura. Investigação e '
        'análise: 4 identificar as abordagens, 5 montar a árvore de utilidade, 6 analisar as abordagens. '
        'Teste: 7 levantar e priorizar cenários com mais stakeholders, 8 analisar de novo. Relatório: 9 '
        'apresentar os resultados: riscos, não riscos, pontos de sensibilidade, pontos de trade-off e '
        'temas de risco.'))
    phases = [(T('Presentation', 'Apresentação'), [T('present the ATAM', 'apresentar o ATAM'),
                                                     T('business drivers', 'direcionadores de negócio'),
                                                     T('the architecture', 'a arquitetura')]),
              (T('Investigation', 'Investigação'), [T('approaches', 'abordagens'), T('utility tree', 'árvore de utilidade'),
                                                     T('analyse', 'analisar')]),
              (T('Testing', 'Teste'), [T('more scenarios', 'mais cenários'), T('analyse again', 'analisar de novo')]),
              (T('Reporting', 'Relatório'), [T('results', 'resultados')])]
    n = 1
    for i, (name, steps) in enumerate(phases):
        x0 = 14 + i * 176
        f.rect(x0, 20, 164, 200, stroke='--amber' if i != 2 else '--phosphor', fill='--ink', rx=5, width=1.4)
        f.text(x0 + 82, 38, name, size=11, weight='600')
        for j, s in enumerate(steps):
            y = 70 + j * 48
            f.badge(x0 + 20, y, n)
            f.rect(x0 + 34, y - 16, 120, 32, stroke='--wire', fill='--panel', rx=4)
            f.text(x0 + 94, y, s, size=9.5)
            n += 1
        if i < 3:
            f.arrow([(x0 + 164, 120), (x0 + 176, 120)], stroke='--paper', width=1.4)
    outs = [T('risks', 'riscos'), T('non-risks', 'não riscos'), T('sensitivity points', 'pontos de sensibilidade'),
            T('trade-off points', 'pontos de trade-off'), T('risk themes', 'temas de risco')]
    f.text(360, 244, T('step 9 reports', 'o passo 9 relata'), size=9.5, fill='--paper-dim', italic=True)
    for k, o in enumerate(outs):
        f.box(76 + k * 142, 274, 132, 30, o, size=9.5, stroke='--phosphor', weight=None)
    f.text(14 + 2 * 176 + 82, 205, T('new voices here', 'vozes novas aqui'), size=9, fill='--phosphor', italic=True)
    return f, T('Steps 6 and 8 look alike. The difference between them is step 7, where people who are not architects add the scenarios the architects missed.',
                'Os passos 6 e 8 parecem iguais. A diferença entre eles é o passo 7, em que pessoas que não são arquitetas acrescentam os cenários que os arquitetos não viram.')


@figure('l13-risk-storm', 13)
def risk_storm():
    f = Fig('l13-risk-storm', 720, 300, T(
        'A risk-storming board: Carcará\'s containers drawn large, with sticky notes placed by reviewers. '
        'Notes are coloured by likelihood times impact. One note sits on the ticketing API, two on the '
        'booking database, and a cluster of four on the boarding sync service, all reading two phones, '
        'one ticket. Two notes sit on the link between a station and the cloud.',
        'Um quadro de risk storming: os containers da Carcará desenhados grandes, com post-its colocados '
        'pelos revisores. As notas são coloridas por probabilidade vezes impacto. Uma nota fica na API de '
        'passagens, duas no banco de reservas, e um grupo de quatro no serviço de sincronização do '
        'embarque, todas dizendo dois celulares, uma passagem. Duas notas ficam na ligação entre uma '
        'rodoviária e a nuvem.'))
    f.box(110, 70, 160, 50, T('Station counter', 'Guichê'), sub=T('[Container]', '[Container]'), size=10, stroke='--phosphor')
    f.box(360, 70, 160, 50, T('Ticketing API', 'API de passagens'), sub='[Container]', size=10, stroke='--phosphor')
    f.box(610, 70, 160, 50, T('Booking DB', 'Banco de reservas'), sub='[PostgreSQL]', size=10, stroke='--phosphor')
    f.box(360, 210, 160, 50, T('Boarding sync', 'Sincronização'), sub='[Container]', size=10, stroke='--phosphor')
    f.box(110, 210, 160, 50, T('Boarding app', 'App de embarque'), sub='[Android]', size=10, stroke='--phosphor')
    P = dict(stroke='--paper-dim', width=1.2)
    f.arrow([(190, 70), (280, 70)], **P)
    f.arrow([(440, 70), (530, 70)], **P)
    f.arrow([(190, 210), (280, 210)], **P)
    f.arrow([(360, 185), (360, 95)], **P)

    def note(x, y, txt, hi):
        f.rect(x, y, 66, 30, stroke=None, fill='--amber' if hi else '--wire', rx=1)
        f.text(x + 33, y + 15, txt, size=8.5, fill='--ink' if hi else '--paper')
    note(200, 16, T('link down', 'link cai'), True)
    note(200, 100, T('link down', 'link cai'), True)
    note(420, 112, T('pool size', 'pool'), False)
    note(570, 112, T('failover?', 'failover?'), False)
    note(640, 112, T('disk full', 'disco cheio'), False)
    for k, (x, y) in enumerate([(450, 170), (520, 170), (450, 248), (520, 248)]):
        note(x, y, T('2 phones', '2 celulares'), True)
    f.text(560, 290, T('four notes, written alone, on one service', 'quatro notas, escritas sozinhas, num serviço'),
           size=9, fill='--paper-dim', italic=True)
    return f, T('The cluster is the finding. Four people wrote the same risk without talking to each other, which is why the silent step comes before the discussion.',
                'O agrupamento é o achado. Quatro pessoas escreveram o mesmo risco sem conversar entre si, e é por isso que o passo em silêncio vem antes da discussão.')
