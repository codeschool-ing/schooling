"""Lesson 6: requirements and quality attributes."""
from figures import Fig, T, figure, picture


@figure('l06-iso-25010', 6)
def iso():
    f = Fig('l06-iso-25010', 720, 250, T(
        'The nine quality characteristics of ISO/IEC 25010:2023 as a grid: functional suitability, '
        'performance efficiency, compatibility, interaction capability, reliability, security, '
        'maintainability, flexibility and safety. Interaction capability and flexibility are marked as '
        'the 2023 names for usability and portability, and safety as new in 2023.',
        'As nove características de qualidade da ISO/IEC 25010:2023 em grade: adequação funcional, '
        'eficiência de desempenho, compatibilidade, capacidade de interação, confiabilidade, '
        'segurança, manutenibilidade, flexibilidade e segurança operacional (safety). Capacidade de '
        'interação e flexibilidade aparecem marcadas como os nomes de 2023 para usabilidade e '
        'portabilidade, e safety como nova em 2023.'))
    items = [(T('Functional suitability', 'Adequação funcional'), None),
             (T('Performance efficiency', 'Eficiência de desempenho'), None),
             (T('Compatibility', 'Compatibilidade'), None),
             (T('Interaction capability', 'Capacidade de interação'), T('was usability', 'era usabilidade')),
             (T('Reliability', 'Confiabilidade'), None),
             (T('Security', 'Segurança'), None),
             (T('Maintainability', 'Manutenibilidade'), None),
             (T('Flexibility', 'Flexibilidade'), T('was portability', 'era portabilidade')),
             (T('Safety', 'Safety'), T('new in 2023', 'nova em 2023'))]
    for i, (n, note) in enumerate(items):
        x = 125 + (i % 3) * 235
        y = 45 + (i // 3) * 76
        f.box(x, y, 210, 52, n, sub=note, size=10.5, stroke='--amber' if note else '--phosphor')
    f.text(360, 238, T('product quality model, ISO/IEC 25010:2023', 'modelo de qualidade de produto, ISO/IEC 25010:2023'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('A checklist, not a target: walk the nine, keep the few that matter for this system, and turn each into scenarios.',
                'Uma lista de conferência, não uma meta: percorra as nove, fique com as poucas que importam para este sistema, e transforme cada uma em cenários.')


def scenario_drawing(f, words=True):
    t = f.text if words else (lambda *a, **k: None)
    f.rect(200, 40, 330, 160, stroke='--amber', fill='--ink', rx=6, dash='6 4', width=1.3)
    t(212, 56, T('environment: on the road, no signal', 'ambiente: na estrada, sem sinal'), size=9, anchor='start',
      fill='--amber', italic=True)
    f.person(80, 125, [T('Driver', 'Motorista')] if words else [''], size=9.5)
    f.arrow([(128, 125), (240, 125)], stroke='--paper', width=1.5)
    t(184, 112, T('scans a ticket', 'lê a passagem'), size=9)
    f.rect(240, 95, 160, 60, stroke='--phosphor', fill='--panel', rx=4, width=1.5)
    t(320, 118, T('Boarding app', 'App de embarque'), size=10, weight='600')
    t(320, 134, T('artefact', 'artefato'), size=8.5, fill='--paper-dim')
    f.arrow([(400, 125), (560, 125)], stroke='--paper', width=1.5)
    t(470, 112, T('accept or refuse', 'aceita ou recusa'), size=9)
    f.rect(560, 95, 140, 60, stroke='--phosphor', fill='--panel', rx=4, width=1.5)
    t(630, 118, T('within 1 s,', 'em até 1 s,'), size=10, weight='600')
    t(630, 134, T('every scan', 'toda leitura'), size=9, fill='--paper-dim')
    labels = [(80, T('source', 'fonte')), (184, T('stimulus', 'estímulo')), (320, ''), (470, T('response', 'resposta')),
              (630, T('response measure', 'medida de resposta'))]
    for x, n in labels:
        if n:
            t(x, 230, n, size=10, weight='600', fill='--phosphor')
    t(320, 230, T('artefact', 'artefato'), size=10, weight='600', fill='--phosphor')


@figure('l06-scenario', 6)
def scenario():
    f = Fig('l06-scenario', 720, 250, T(
        'The six parts of a quality attribute scenario, drawn for offline boarding. The source, a driver, '
        'sends the stimulus, scans a ticket, to the artefact, the boarding app, inside a dashed '
        'environment, on the road with no signal. The response, accept or refuse, leads to the response '
        'measure, within one second for every scan.',
        'As seis partes de um cenário de atributo de qualidade, desenhadas para o embarque sem sinal. '
        'A fonte, um motorista, manda o estímulo, lê a passagem, ao artefato, o app de embarque, dentro '
        'de um ambiente tracejado, na estrada e sem sinal. A resposta, aceita ou recusa, leva à medida de '
        'resposta, em até um segundo para toda leitura.'))
    scenario_drawing(f)
    return f, T('The environment is drawn around the artefact because it is the condition the response has to hold under. Change it, and it is a different scenario.',
                'O ambiente é desenhado em volta do artefato porque é a condição sob a qual a resposta tem de valer. Mude o ambiente, e é outro cenário.')


@picture('scenario-shapes')
def scenario_picture():
    f = Fig('scenario-shapes', 720, 250, '')
    scenario_drawing(f, words=False)
    return f


@figure('l06-utility-tree', 6)
def tree():
    f = Fig('l06-utility-tree', 720, 340, T(
        'Carcará\'s utility tree. From the root, utility, four attributes branch out: performance, '
        'availability, modifiability and security. Each has a refinement and scenarios as leaves, with '
        'importance and difficulty ratings. Performance, peak load: QS-01, 2,000 purchases a minute, '
        'rated high, high. Availability, no network: QS-02, offline boarding, high, high; availability, '
        'database failure: QS-03, failover in 5 minutes, high, medium. Modifiability, payments: QS-04, '
        'new method in 10 days, medium, low. Security, accountability: QS-05, refund audit, high, low.',
        'A árvore de utilidade da Carcará. Da raiz, utilidade, saem quatro atributos: desempenho, '
        'disponibilidade, modificabilidade e segurança. Cada um tem um refinamento e cenários como '
        'folhas, com notas de importância e dificuldade. Desempenho, carga de pico: QS-01, 2.000 '
        'compras por minuto, alta, alta. Disponibilidade, sem rede: QS-02, embarque sem sinal, alta, '
        'alta; disponibilidade, falha do banco: QS-03, failover em 5 minutos, alta, média. '
        'Modificabilidade, pagamentos: QS-04, novo meio em 10 dias, média, baixa. Segurança, '
        'responsabilização: QS-05, auditoria de estorno, alta, baixa.'))
    f.box(60, 170, 90, 36, T('Utility', 'Utilidade'), size=11, stroke='--amber')
    attrs = [(60, T('Performance', 'Desempenho')), (140, T('Availability', 'Disponibilidade')),
             (230, T('Modifiability', 'Modificabilidade')), (290, T('Security', 'Segurança'))]
    leaves = [(60, T('peak load', 'carga de pico'), 'QS-01', T('2,000 purchases/min', '2.000 compras/min'), '(H, H)'),
              (115, T('no network', 'sem rede'), 'QS-02', T('offline boarding, 1 s', 'embarque sem sinal, 1 s'), '(H, H)'),
              (165, T('database fails', 'banco falha'), 'QS-03', T('failover in 5 min', 'failover em 5 min'), '(H, M)'),
              (230, T('payments', 'pagamentos'), 'QS-04', T('new method in 10 days', 'novo meio em 10 dias'), '(M, L)'),
              (290, T('accountability', 'responsabilização'), 'QS-05', T('refund audit, 5 years', 'auditoria de estorno, 5 anos'), '(H, L)')]
    for y, n in attrs:
        f.line(105, 170, 170, y, stroke='--paper-dim', width=1.1)
        f.box(235, y, 130, 32, n, size=10, stroke='--phosphor')
    for i, (y, r, qs, text, rate) in enumerate(leaves):
        ay = attrs[0][0] if i == 0 else attrs[1][0] if i < 3 else attrs[2][0] if i == 3 else attrs[3][0]
        f.line(300, ay, 330, y, stroke='--paper-dim', width=1.1)
        f.box(392, y, 120, 28, r, size=9, stroke='--wire', weight=None)
        f.line(452, y, 470, y, stroke='--paper-dim', width=1.1)
        hh = rate == '(H, H)'
        f.rect(470, y - 18, 232, 36, stroke='--amber' if hh else '--wire', fill='--panel', rx=4, width=1.5 if hh else 1.1)
        f.text(478, y - 6, qs, size=9, anchor='start', weight='600', mono=True)
        f.text(478, y + 8, text, size=8.5, anchor='start', fill='--paper-dim')
        f.text(694, y, rate, size=9.5, anchor='end', weight='600', fill='--amber' if hh else '--paper', mono=True)
    f.text(586, 324, T('(importance, difficulty)', '(importância, dificuldade)'), size=9, fill='--paper-dim', italic=True)
    return f, T('Two leaves are rated (H, H), and almost every major decision in Carcará\'s log traces back to one of them.',
                'Duas folhas têm nota (H, H), e quase toda decisão importante do log da Carcará remonta a uma delas.')


@figure('l06-tradeoff', 6)
def tradeoff():
    f = Fig('l06-tradeoff', 720, 300, T(
        'A chart with two lines against the sync interval of the drivers\' phones, from 5 to 60 minutes. '
        'The longest a cancelled ticket can still be accepted at the door rises in a straight line with '
        'the interval, from 5 to 60 minutes. The number of syncs per phone in a ten-hour day falls as '
        'the interval grows: 120 at 5 minutes, 40 at 15, 10 at 60. Celeste\'s choice, 15 minutes, is '
        'marked.',
        'Um gráfico com duas linhas contra o intervalo de sincronização dos celulares dos motoristas, de '
        '5 a 60 minutos. O tempo máximo em que uma passagem cancelada ainda pode ser aceita na porta '
        'sobe em linha reta com o intervalo, de 5 a 60 minutos. O número de sincronizações por celular '
        'num dia de dez horas cai à medida que o intervalo cresce: 120 com 5 minutos, 40 com 15, 10 com '
        '60. A escolha de Celeste, 15 minutos, aparece marcada.'))
    x0, x1, y0, y1 = 80, 640, 250, 40
    def X(m): return x0 + (m - 5) / 55 * (x1 - x0)
    def Y(v, top): return y0 - v / top * (y0 - y1)
    f.line(x0, y0, x1, y0, stroke='--paper-dim', width=1.2)
    f.line(x0, y0, x0, y1, stroke='--phosphor', width=1.2)
    f.line(x1, y0, x1, y1, stroke='--amber', width=1.2)
    for m in (5, 15, 30, 45, 60):
        f.line(X(m), y0, X(m), y0 + 5, stroke='--paper-dim', width=1)
        f.text(X(m), y0 + 16, str(m), size=9, mono=True)
    f.text((x0 + x1) / 2, y0 + 34, T('sync interval, minutes', 'intervalo de sincronização, minutos'), size=9.5)
    for v in (0, 20, 40, 60):
        f.text(x0 - 8, Y(v, 60), str(v), size=9, anchor='end', mono=True, fill='--phosphor')
    for v in (0, 40, 80, 120):
        f.text(x1 + 8, Y(v, 120), str(v), size=9, anchor='start', mono=True, fill='--amber')
    f.path(f'M{X(5):.1f} {Y(5, 60):.1f} L{X(60):.1f} {Y(60, 60):.1f}', stroke='--phosphor', width=2)
    pts = ' L'.join(f'{X(m):.1f} {Y(600 / m, 120):.1f}' for m in range(5, 61))
    f.path('M' + pts, stroke='--amber', width=2)
    f.line(X(15), y0, X(15), y1, stroke='--paper', width=1, dash='4 3')
    f.circle(X(15), Y(15, 60), 4, fill='--phosphor')
    f.circle(X(15), Y(40, 120), 4, fill='--amber')
    f.text(X(15) + 6, y1 + 6, T('Celeste: 15 min', 'Celeste: 15 min'), size=9.5, anchor='start', weight='600')
    f.text(X(42), Y(42, 60) - 12, T('cancelled ticket still accepted, worst case (min)', 'passagem cancelada ainda aceita, pior caso (min)'),
           size=9, anchor='end', fill='--phosphor')
    f.text(X(30), Y(600 / 30, 120) - 10, T('syncs per phone, 10-hour day', 'sincronizações por celular, dia de 10 h'),
           size=9, anchor='start', fill='--amber')
    return f, T('Both lines are arithmetic, not measurement: the worst case equals the interval, and a ten-hour day holds 600 minutes divided by it. Where to sit on them is a business decision.',
                'As duas linhas são aritmética, não medição: o pior caso é igual ao intervalo, e um dia de dez horas tem 600 minutos divididos por ele. Onde ficar nelas é uma decisão de negócio.')


@figure('l06-trace', 6)
def trace():
    f = Fig('l06-trace', 720, 150, T(
        'A traceability chain for offline boarding, four boxes joined left to right by their ids: the '
        'requirement QS-02, the decision record ADR-0006, the model elements boarding app and boarding '
        'sync, and the offline scan test.',
        'Uma cadeia de rastreabilidade do embarque sem sinal, quatro caixas ligadas da esquerda para a '
        'direita pelos seus ids: o requisito QS-02, o registro de decisão ADR-0006, os elementos do '
        'modelo app de embarque e sincronização, e o teste de leitura sem rede.'))
    items = [(95, T('requirement', 'requisito'), 'QS-02', T('offline scan, 1 s', 'leitura sem sinal, 1 s')),
             (275, T('decision', 'decisão'), 'ADR-0006', T('ticket list on the phone', 'lista no celular')),
             (455, T('model', 'modelo'), T('boarding app, sync', 'app de embarque, sinc.'), T('deployment view', 'visão de implantação')),
             (635, T('verification', 'verificação'), T('offline scan test', 'teste sem rede'), T('every release', 'a cada versão'))]
    for x, kind, idn, what in items:
        f.text(x, 22, kind, size=9.5, fill='--paper-dim', italic=True)
        f.box(x, 80, 160, 70, idn, sub=what, size=10.5, stroke='--phosphor')
    for a, b in [(175, 195), (355, 375), (535, 555)]:
        f.arrow([(a, 80), (b, 80)], stroke='--paper', width=1.4)
    f.text(360, 136, T('each link is a reference by id, so a renamed title breaks nothing', 'cada elo é uma referência por id, então renomear um título não quebra nada'),
           size=9.5, fill='--paper-dim')
    return f, T('Forward from the requirement to its proof, and backward from any test to the reason it exists.',
                'Para a frente, do requisito à prova, e para trás, de qualquer teste à razão de ele existir.')
