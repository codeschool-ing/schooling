"""Lesson 8: Enterprise service bus (ESB) and SOAP in legacy environments."""
import math

from figures import Fig, T, figure

SYSTEMS = ['SAP ECC', 'BW/BO', 'Dynamics BC', 'M365', 'Salesforce', 'Documentum', 'IBM BPM',
           'Coleta', 'Rota', 'Portal B2B', None, 'EDI']


def _ring(cx, cy, r):
    pts = []
    for i in range(12):
        a = -math.pi / 2 + i * 2 * math.pi / 12
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def _names():
    return [n if n else T('Banks', 'Bancos') for n in SYSTEMS]


@figure('l08-hub', 8)
def hub():
    f = Fig('l08-hub', 720, 330, T(
        'Two panels with the same twelve systems on a ring: SAP ECC, BW/BO, Dynamics BC, M365, '
        'Salesforce, Documentum, IBM BPM, Coleta, Rota, Portal B2B, the banks and EDI. On the left, '
        'point to point, every pair is joined by a line: 66 lines, the most twelve systems can need. '
        'On the right, each system has one line to an ESB in the middle: 12 lines. A note under '
        'both says the mappings and rules the 66 lines would carry now sit inside the hub.',
        'Dois painéis com os mesmos doze sistemas num anel: SAP ECC, BW/BO, Dynamics BC, M365, '
        'Salesforce, Documentum, IBM BPM, Coleta, Rota, Portal B2B, os bancos e EDI. À esquerda, '
        'ponto a ponto, cada par está ligado por uma linha: 66 linhas, o máximo que doze sistemas '
        'podem precisar. À direita, cada sistema tem uma linha até um ESB no meio: 12 linhas. Uma '
        'nota embaixo dos dois diz que os mapeamentos e as regras que as 66 linhas carregariam agora '
        'ficam dentro do hub.'))
    names = _names()
    cy, r = 172, 100
    left, right = _ring(185, cy, r), _ring(535, cy, r)
    for i in range(12):
        for j in range(i + 1, 12):
            (x1, y1), (x2, y2) = left[i], left[j]
            f.line(x1, y1, x2, y2, stroke='--wire', width=0.7)
    for x, y in right:
        dx, dy = x - 535, y - cy
        s = min(30 / abs(dx) if dx else 9e9, 15 / abs(dy) if dy else 9e9)
        f.line(535 + dx * s, cy + dy * s, x, y, stroke='--phosphor', width=1.3)
    f.box(535, cy, 60, 30, ['ESB'], stroke='--phosphor', size=11)
    for cx, pts, dot in ((185, left, '--paper-dim'), (535, right, '--phosphor')):
        for (x, y), n in zip(pts, names):
            f.circle(x, y, 4.5, fill=dot)
            dx, dy = x - cx, y - cy
            if abs(dx) < 1:
                f.text(x, y + (14 if dy > 0 else -14), n, size=10)
            else:
                f.text(x + (10 if dx > 0 else -10), y + dy * 0.08, n, size=10,
                       anchor='start' if dx > 0 else 'end')
    f.text(185, 18, T('point to point: up to 66 connections', 'ponto a ponto: até 66 conexões'),
           size=12, weight='600')
    f.text(535, 18, T('one hub: 12 connections', 'um hub: 12 conexões'), size=12, weight='600')
    f.line(360, 40, 360, 296, stroke='--wire', width=1, dash='4 4')
    f.text(360, 316, T('the hub holds every mapping and rule the 66 lines would have carried',
                       'o hub guarda todos os mapeamentos e regras que as 66 linhas carregariam'),
           size=10.5, fill='--amber', italic=True)
    return f, T('Twelve systems, the ceiling of n(n − 1)/2 = 66 direct connections against twelve to a hub. The count of lines falls; the count of agreements does not.',
                'Doze sistemas: o teto de n(n − 1)/2 = 66 conexões diretas contra doze até um hub. O número de linhas cai; o número de acordos, não.')


@figure('l08-logic', 8)
def logic():
    f = Fig('l08-logic', 720, 310, T(
        'Two panels. On the left, the bus that grew: the Portal B2B, Salesforce and EDI send to a '
        'wide bus, which holds three business rules (a 3% discount above R$ 1,500, which plant '
        'ships, a credit block) and passes orders on to SAP ECC. On the right, smart endpoints and '
        'dumb pipes: the same three senders put messages on a thin MQ pipe that holds no rules, and '
        'SAP ECC holds the three decisions in its own pricing, logistics and credit management.',
        'Dois painéis. À esquerda, o barramento que cresceu: o Portal B2B, o Salesforce e o EDI '
        'mandam para um barramento largo, que guarda três regras de negócio (um desconto de 3% acima '
        'de R$ 1.500, qual fábrica envia, um bloqueio de crédito) e repassa os pedidos ao SAP ECC. À '
        'direita, pontas inteligentes e canos burros: os mesmos três remetentes põem mensagens num '
        'cano fino de MQ que não guarda regra nenhuma, e o SAP ECC guarda as três decisões no seu '
        'próprio preço, logística e gestão de crédito.'))
    senders = ['Portal B2B', 'Salesforce', 'EDI']
    ys = [100, 160, 220]
    # left panel: the logic in the pipe
    f.text(175, 22, T('the bus that grew', 'o barramento que cresceu'), size=12, weight='600')
    f.rect(118, 58, 150, 204, stroke='--amber', fill='--panel', width=1.6, rx=6)
    f.text(193, 74, 'ESB', size=11, weight='600')
    rules = [T('3% above R$ 1,500', '3% acima de R$ 1.500'),
             T('which plant ships', 'qual fábrica envia'),
             T('credit block', 'bloqueio de crédito')]
    for y, r in zip(ys, rules):
        f.box(193, y + 6, 134, 30, [r], size=10, stroke='--amber', dash='3 3')
    for y, s in zip(ys, senders):
        f.box(56, y, 88, 28, [s], size=10, stroke='--paper-dim')
        f.arrow([(100, y), (116, y)], stroke='--paper-dim')
    f.box(318, 160, 70, 40, ['SAP ECC'], size=10, stroke='--paper-dim')
    f.arrow([(268, 160), (281, 160)], stroke='--paper-dim')
    f.lines(175, 286, [T('the rules live in the pipe', 'as regras moram no cano')], size=10.5,
            fill='--amber', italic=True)
    f.line(362, 40, 362, 296, stroke='--wire', width=1, dash='4 4')
    # right panel: the logic at the endpoint
    f.text(545, 22, T('smart endpoints, dumb pipes', 'pontas inteligentes, canos burros'), size=12,
           weight='600')
    for y, s in zip(ys, senders):
        f.box(426, y, 88, 28, [s], size=10, stroke='--paper-dim')
        f.arrow([(470, y), (492, y)], stroke='--paper-dim')
    f.rect(494, 70, 16, 180, stroke='--phosphor', fill='--panel', width=1.2, rx=3)
    f.text(502, 262, 'MQ', size=10, mono=True)
    f.arrow([(510, 160), (524, 160)], stroke='--paper-dim')
    f.rect(526, 82, 184, 156, stroke='--phosphor', fill='--panel', width=1.6, rx=6)
    f.text(618, 100, 'SAP ECC', size=11, weight='600')
    owned = [T('pricing: 3% above R$ 1,800', 'preço: 3% acima de R$ 1.800'),
             T('logistics: which plant ships', 'logística: qual fábrica envia'),
             T('credit management', 'gestão de crédito')]
    for i, r in enumerate(owned):
        f.box(618, 132 + i * 38, 170, 30, [r], size=10, stroke='--phosphor')
    f.lines(545, 286, [T('the pipe moves messages; the owner decides',
                         'o cano move mensagens; o dono decide')], size=10.5, fill='--paper-dim',
            italic=True)
    return f, T('Where the logic sits. On the left a rule can be changed in SAP and keep running, unchanged, in the bus; on the right each rule has one home, with the team that owns it.',
                'Onde a lógica fica. À esquerda, uma regra pode ser mudada no SAP e continuar rodando, sem mudança, no barramento; à direita, cada regra tem uma casa só, com o time que é dono dela.')


@figure('l08-adapter', 8)
def adapter():
    f = Fig('l08-adapter', 720, 300, T(
        'Rota calling FarmRegistry, left to right. Inside Rota: the route planner calls the '
        'interface FarmTanks, which is implemented by an adapter holding the generated client, the '
        'mapping of faults to answers, the timeouts with one retry, and the fallback to yesterday\'s '
        'answer. A dashed line marks the boundary: to its left everything is in Rota\'s own types, '
        'to its right everything is SOAP. Past the boundary the call goes to the FarmRegistry '
        'service on the bus and on to Coleta on the IBM i. Below the bus, a dashed box shows the '
        'stub with recorded envelopes that replaces the bus in Rota\'s tests.',
        'Rota chamando o FarmRegistry, da esquerda para a direita. Dentro do Rota: o planejador de '
        'rotas chama a interface FarmTanks, implementada por um adaptador que contém o cliente '
        'gerado, o mapeamento de faults para respostas, os timeouts com uma nova tentativa e o '
        'recurso à resposta de ontem. Uma linha tracejada marca a fronteira: à esquerda dela tudo '
        'está nos tipos do próprio Rota, à direita tudo é SOAP. Depois da fronteira a chamada vai '
        'para o serviço FarmRegistry no barramento e daí para o Coleta no IBM i. Abaixo do '
        'barramento, uma caixa tracejada mostra o stub com envelopes gravados que substitui o '
        'barramento nos testes do Rota.'))
    f.text(232, 22, T("Rota's own types", 'os tipos do próprio Rota'), size=12, weight='600')
    f.text(598, 22, 'SOAP', size=12, weight='600')
    f.box(70, 120, 104, 44, [T('route', 'planejador'), T('planner', 'de rotas')], size=10,
          stroke='--paper-dim')
    f.box(198, 120, 104, 44, ['FarmTanks'], size=10.5, mono=True, stroke='--phosphor')
    f.text(198, 154, T('interface', 'interface'), size=10, fill='--paper-dim', italic=True)
    f.arrow([(122, 120), (144, 120)], stroke='--paper-dim')
    f.rect(272, 52, 176, 150, stroke='--phosphor', fill='--panel', width=1.6, rx=6)
    f.text(360, 68, T('adapter', 'adaptador'), size=11, weight='600')
    rows = [T('generated client', 'cliente gerado'),
            T('faults → answers', 'faults → respostas'),
            T('timeouts, one retry', 'timeouts, uma nova tentativa'),
            T("yesterday's answer", 'resposta de ontem')]
    for i, r in enumerate(rows):
        f.box(360, 94 + i * 30, 160, 24, [r], size=10, stroke='--wire')
    f.arrow([(250, 120), (270, 120)], stroke='--paper-dim')
    f.line(466, 40, 466, 270, stroke='--amber', width=1.4, dash='6 4')
    f.text(466, 284, T('the boundary', 'a fronteira'), size=10, fill='--amber', italic=True)
    f.box(548, 120, 120, 44, ['FarmRegistry'], size=10.5, mono=True, stroke='--paper-dim')
    f.text(548, 154, T('on the bus', 'no barramento'), size=10, fill='--paper-dim', italic=True)
    f.arrow([(448, 120), (486, 120)], stroke='--paper-dim')
    f.box(668, 120, 84, 44, ['Coleta', 'IBM i'], size=10, stroke='--paper-dim')
    f.arrow([(608, 120), (624, 120)], stroke='--paper-dim')
    f.box(568, 226, 160, 40, [T('stub with recorded', 'stub com envelopes'),
                             T('envelopes, in tests', 'gravados, nos testes')], size=10,
          stroke='--paper-dim', dash='4 3')
    f.arrow([(448, 190), (486, 218)], stroke='--paper-dim', dash='4 3')
    return f, T('SOAP ends at the adapter. Everything to the left of the line is written in Rota\'s terms, so a change on the bus, or the end of FarmRegistry, touches one class.',
                'O SOAP termina no adaptador. Tudo à esquerda da linha está escrito nos termos do Rota, então uma mudança no barramento, ou o fim do FarmRegistry, mexe numa classe só.')


@figure('l08-classes', 8)
def classes():
    f = Fig('l08-classes', 720, 290, T(
        'A bar chart of Serra Alta\'s 70 message flows by class, after a year of traffic was '
        'checked. Routing and protocol: 24, which stay on a small bus or become plain MQ. '
        'Transformation: 19, which move to the endpoint that owns the format. Orchestration with '
        'business logic: 18, which move to the owner of the decision. Dead: 9, switched off. A note '
        'says 11 flows had no traffic in 90 days, and 2 of them run once a year and were counted as '
        'transformations.',
        'Um gráfico de barras dos 70 fluxos de mensagem da Serra Alta por classe, depois de '
        'conferido um ano de tráfego. Roteamento e protocolo: 24, que ficam num barramento pequeno '
        'ou viram MQ simples. Transformação: 19, que vão para a ponta dona do formato. Orquestração '
        'com lógica de negócio: 18, que vão para o dono da decisão. Mortos: 9, desligados. Uma nota '
        'diz que 11 fluxos não tiveram tráfego em 90 dias, e 2 deles rodam uma vez por ano e foram '
        'contados como transformação.'))
    rows = [(T('routing and protocol', 'roteamento e protocolo'),
             T('stays: a small bus, or plain MQ', 'fica: um barramento pequeno, ou MQ simples'), 24,
             '--phosphor'),
            (T('transformation', 'transformação'),
             T('to the endpoint that owns the format', 'para a ponta dona do formato'), 19,
             '--phosphor-dim'),
            (T('orchestration with business logic', 'orquestração com lógica de negócio'),
             T('to the owner of the decision', 'para o dono da decisão'), 18, '--amber'),
            (T('dead', 'mortos'), T('switched off', 'desligados'), 9, '--wire')]
    f.text(20, 22, T('70 flows on the bus, by class', '70 fluxos no barramento, por classe'),
           size=12, weight='600', anchor='start')
    x0, k = 330, 12.5
    for i, (label, sub, n, colour) in enumerate(rows):
        y = 64 + i * 50
        f.text(20, y - 8, label, size=11, anchor='start')
        f.text(20, y + 9, sub, size=10, anchor='start', fill='--paper-dim')
        f.rect(x0, y - 13, n * k, 26, stroke=None, fill=colour, rx=2)
        f.text(x0 + n * k + 10, y, str(n), size=11, anchor='start', weight='600')
    f.line(x0, 40, x0, 256, stroke='--wire', width=1)
    f.text(20, 274, T('11 flows had no traffic in 90 days; 2 of them run once a year, so 9 are dead',
                      '11 fluxos não tiveram tráfego em 90 dias; 2 deles rodam uma vez por ano, então 9 estão mortos'),
           size=10.5, fill='--amber', italic=True, anchor='start')
    return f, T('The 70 flows after the inventory. The classes, not the product, decide where each flow goes; 46 leave the bus and 24 stay.',
                'Os 70 fluxos depois do inventário. As classes, e não o produto, decidem para onde vai cada fluxo; 46 saem do barramento e 24 ficam.')
