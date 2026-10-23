"""Lesson 7: BABOK."""
import math
from figures import Fig, T, figure


@figure('l07-baccm', 7)
def baccm():
    f = Fig('l07-baccm', 720, 300, T(
        'The Business Analysis Core Concept Model: six concepts on a ring, each connected to every '
        'other. Change, the act of transformation; need, a problem or opportunity; solution, a way of '
        'satisfying needs; stakeholder, somebody with a relationship to the change; value, worth to a '
        'stakeholder; context, the circumstances around the change.',
        'O modelo de conceitos centrais da análise de negócio: seis conceitos num anel, cada um ligado a '
        'todos os outros. Mudança, o ato de transformar; necessidade, um problema ou oportunidade; '
        'solução, um jeito de atender necessidades; stakeholder, alguém com relação com a mudança; '
        'valor, o que algo vale para um stakeholder; contexto, as circunstâncias em volta da mudança.'))
    names = [(T('Change', 'Mudança'), T('the transformation', 'a transformação')),
             (T('Need', 'Necessidade'), T('problem or opportunity', 'problema ou oportunidade')),
             (T('Solution', 'Solução'), T('a way to satisfy needs', 'um jeito de atender')),
             (T('Stakeholder', 'Stakeholder'), T('a relationship to it', 'tem relação com ela')),
             (T('Value', 'Valor'), T('worth to somebody', 'o que vale para alguém')),
             (T('Context', 'Contexto'), T('the circumstances', 'as circunstâncias'))]
    pts = []
    for i in range(6):
        a = -math.pi / 2 + i * math.pi / 3
        pts.append((360 + 230 * math.cos(a), 150 + 112 * math.sin(a)))
    for i in range(6):
        for j in range(i + 1, 6):
            (x1, y1), (x2, y2) = pts[i], pts[j]
            dx, dy = x2 - x1, y2 - y1
            k = min(86 / abs(dx) if dx else 9e9, 25 / abs(dy) if dy else 9e9)
            f.line(x1 + dx * k, y1 + dy * k, x2 - dx * k, y2 - dy * k, stroke='--wire', width=1)
    for (x, y), (n, d) in zip(pts, names):
        f.box(x, y, 168, 46, n, sub=d, size=10.5, stroke='--phosphor')
    return f, T('Each concept is defined by the others: a solution meets a need, in a context, delivering value to stakeholders, through a change. A gap in one shows up as a question about another.',
                'Cada conceito se define pelos outros: uma solução atende a uma necessidade, num contexto, entregando valor a stakeholders, por meio de uma mudança. Uma lacuna num aparece como pergunta sobre outro.')


@figure('l07-knowledge-areas', 7)
def areas():
    f = Fig('l07-knowledge-areas', 720, 260, T(
        'The six BABOK knowledge areas. Business Analysis Planning and Monitoring sits across the top '
        'and governs the others. Below it, Elicitation and Collaboration, and Requirements Life Cycle '
        'Management, work across all of the rest. Strategy Analysis, Requirements Analysis and Design '
        'Definition, and Solution Evaluation follow the change from its strategy, through its '
        'requirements and design, to whether it delivered value.',
        'As seis áreas de conhecimento do BABOK. Planejamento e Monitoramento da Análise de Negócio fica '
        'no alto e governa as outras. Abaixo dela, Elicitação e Colaboração, e Gerenciamento do Ciclo de '
        'Vida dos Requisitos, atuam sobre todas as demais. Análise de Estratégia, Análise de Requisitos e '
        'Definição de Design, e Avaliação da Solução acompanham a mudança desde a estratégia, passando '
        'pelos requisitos e pelo design, até saber se ela entregou valor.'))
    f.box(360, 30, 660, 36, T('Business Analysis Planning and Monitoring', 'Planejamento e Monitoramento da Análise de Negócio'),
          size=10.5, stroke='--amber')
    f.box(195, 88, 320, 34, T('Elicitation and Collaboration', 'Elicitação e Colaboração'), size=10, stroke='--paper-dim')
    f.box(525, 88, 320, 34, T('Requirements Life Cycle Management', 'Gerenciamento do Ciclo de Vida dos Requisitos'), size=10,
          stroke='--paper-dim')
    cols = [(130, T('Strategy Analysis', 'Análise de Estratégia'), T('current and future state', 'estado atual e futuro')),
            (360, T('Requirements Analysis and', 'Análise de Requisitos e'), T('Design Definition', 'Definição de Design')),
            (590, T('Solution Evaluation', 'Avaliação da Solução'), T('did the value arrive?', 'o valor chegou?'))]
    for x, a, b in cols:
        f.box(x, 175, 210, 58, a, sub=b, size=10, stroke='--phosphor')
    f.arrow([(235, 175), (255, 175)], stroke='--paper', width=1.3)
    f.arrow([(465, 175), (485, 175)], stroke='--paper', width=1.3)
    f.text(360, 238, T('strategy → requirements and design → evaluation', 'estratégia → requisitos e design → avaliação'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('Areas of work, not phases. On a real change they overlap and repeat, and an analyst may be in four of them in one week.',
                'Áreas de trabalho, não fases. Numa mudança real elas se sobrepõem e se repetem, e um analista pode estar em quatro delas na mesma semana.')


@figure('l07-stakeholder-map', 7)
def stakeholder_map():
    f = Fig('l07-stakeholder-map', 720, 330, T(
        'A stakeholder map for the reconciliation, with influence up the vertical axis and interest '
        'along the horizontal. High influence and high interest, manage closely: the finance director. '
        'High influence, low interest, keep satisfied: the Payments tech lead and Platform. Low '
        'influence, high interest, keep informed: Joana and the station agents. Low influence, low '
        'interest, monitor: the payment company. The external auditors sit between the two upper '
        'quadrants.',
        'Um mapa de stakeholders da conciliação, com influência no eixo vertical e interesse no '
        'horizontal. Muita influência e muito interesse, gerenciar de perto: o diretor financeiro. Muita '
        'influência, pouco interesse, manter satisfeito: o tech lead de Pagamentos e a Plataforma. Pouca '
        'influência, muito interesse, manter informado: Joana e os agentes de guichê. Pouca influência, '
        'pouco interesse, monitorar: a empresa de pagamento. Os auditores externos ficam entre os dois '
        'quadrantes de cima.'))
    x0, x1, y0, y1 = 110, 690, 300, 20
    xm, ym = (x0 + x1) / 2, (y0 + y1) / 2
    f.rect(x0, y1, x1 - x0, y0 - y1, stroke='--wire', fill='--ink', rx=0)
    f.line(xm, y1, xm, y0, stroke='--wire', width=1)
    f.line(x0, ym, x1, ym, stroke='--wire', width=1)
    q = [(x0 + 10, y1 + 16, T('keep satisfied', 'manter satisfeito')), (xm + 10, y1 + 16, T('manage closely', 'gerenciar de perto')),
         (x0 + 10, ym + 16, T('monitor', 'monitorar')), (xm + 10, ym + 16, T('keep informed', 'manter informado'))]
    for x, y, t in q:
        f.text(x, y, t, size=9.5, anchor='start', fill='--amber', italic=True)
    f.text(60, ym, T('influence', 'influência'), size=10, weight='600')
    f.text(60, y1 + 10, T('high', 'alta'), size=9, fill='--paper-dim')
    f.text(60, y0 - 6, T('low', 'baixa'), size=9, fill='--paper-dim')
    f.text(xm, y0 + 18, T('interest →', 'interesse →'), size=10, weight='600')
    people = [(590, 70, T('Finance director', 'Diretor financeiro')), (250, 70, T('Payments tech lead', 'Tech lead de Pagamentos')),
              (250, 112, 'Platform' if True else '', ), (420, 50, T('External auditors', 'Auditores externos')),
              (560, 210, 'Joana'), (580, 250, T('Station agents', 'Agentes de guichê')),
              (230, 230, T('Payment company', 'Empresa de pagamento'))]
    for p in people:
        x, y, n = p
        if n == 'Platform':
            n = T('Platform', 'Plataforma')
        f.circle(x - 58, y, 4, fill='--phosphor')
        f.text(x - 50, y, n, size=9.5, anchor='start')
    return f, T('The quadrant says how to engage, not how much somebody matters. The station agents have little influence over the project and are essential to its requirements.',
                'O quadrante diz como engajar, não quanto alguém importa. Os agentes de guichê têm pouca influência sobre o projeto e são essenciais para os requisitos dele.')


@figure('l07-classes', 7)
def classes():
    f = Fig('l07-classes', 720, 280, T(
        'BABOK\'s four classes of requirement as a chain. Business requirements, the organisation\'s '
        'goals, are met by stakeholder requirements, the needs of stakeholders, which are met by '
        'solution requirements, split into functional and non-functional. Beside the chain, transition '
        'requirements, needed only to move from the current state to the future one.',
        'As quatro classes de requisito do BABOK como cadeia. Requisitos de negócio, os objetivos da '
        'organização, são atendidos por requisitos de stakeholder, as necessidades dos stakeholders, que '
        'são atendidos por requisitos de solução, divididos em funcionais e não funcionais. Ao lado da '
        'cadeia, requisitos de transição, necessários só para passar do estado atual ao futuro.'))
    f.box(250, 40, 300, 46, T('Business requirements', 'Requisitos de negócio'), sub=T('goals of the organisation', 'objetivos da organização'),
          size=10.5, stroke='--phosphor')
    f.box(250, 125, 300, 46, T('Stakeholder requirements', 'Requisitos de stakeholder'), sub=T('needs of stakeholders', 'necessidades dos stakeholders'),
          size=10.5, stroke='--phosphor')
    f.box(250, 210, 300, 46, T('Solution requirements', 'Requisitos de solução'), sub=T('what the solution does and how well', 'o que a solução faz e quão bem'),
          size=10.5, stroke='--phosphor')
    f.box(170, 262, 140, 26, T('functional', 'funcionais'), size=9, stroke='--wire', weight=None)
    f.box(330, 262, 140, 26, T('non-functional', 'não funcionais'), size=9, stroke='--wire', weight=None)
    for a, b in [(63, 102), (148, 187)]:
        f.arrow([(250, b), (250, a)], stroke='--paper', width=1.3)
    f.text(258, 82, T('meets ↑', 'atende ↑'), size=9, anchor='start', fill='--paper-dim')
    f.text(258, 167, T('meets ↑', 'atende ↑'), size=9, anchor='start', fill='--paper-dim')
    f.box(580, 125, 220, 90, T('Transition requirements', 'Requisitos de transição'),
          sub=[T('only to move from now', 'só para passar do'), T('to the future state', 'agora ao futuro')], size=10.5, stroke='--amber', dash='5 3')
    f.line(470, 125, 400, 125, stroke='--amber', width=1, dash='3 3')
    return f, T('The chain says why each solution requirement exists. Transition requirements sit beside it because they disappear once the change is made, which is why they are the ones forgotten.',
                'A cadeia diz por que cada requisito de solução existe. Os de transição ficam ao lado porque desaparecem quando a mudança termina, e é por isso que são os esquecidos.')
