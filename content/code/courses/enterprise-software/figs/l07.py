"""Lesson 7: BPM and BPEL: modelling and executing business processes.

The drawings here use BPMN 2.0's own shapes, so the helpers below are the notation: an event is
a circle (thin border to start, double in the middle, thick to end), an activity a rounded
rectangle, a gateway a diamond with its marker. A sequence flow is a solid line with a filled
head; a message flow is dashed, starts at a small hollow circle and ends at a hollow head; an
association is dotted. A marker inside an event is hollow when the event catches and filled when
it throws.
"""
import math

from figures import Fig, T, figure

FLOW = '--paper-dim'
EVENT = '--phosphor'
GATE = '--amber'


# ------------------------------------------------------------------- the notation

def _head(f, x, y, ang, stroke=FLOW, hollow=False, L=9, W=4.5):
    c, s = math.cos(ang), math.sin(ang)
    bx, by = x - L * c, y - L * s
    px, py = -s * W, c * W
    fill = '--panel' if hollow else stroke
    f.parts.append(f'<path d="M{x:.1f} {y:.1f} L{bx + px:.1f} {by + py:.1f} L{bx - px:.1f} {by - py:.1f} Z" '
                   f'stroke="var({stroke})" stroke-width="1.2" fill="var({fill})"></path>')


def _ang(pts):
    (x1, y1), (x2, y2) = pts[-2], pts[-1]
    return math.atan2(y2 - y1, x2 - x1)


def seq(f, pts, stroke=FLOW, slash=False):
    """A sequence flow. `slash` marks it as the gateway's default flow."""
    f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke=stroke, width=1.3)
    _head(f, *pts[-1], _ang(pts), stroke=stroke)
    if slash:
        (x1, y1), (x2, y2) = pts[0], pts[1]
        a = math.atan2(y2 - y1, x2 - x1)
        mx, my = x1 + 9 * math.cos(a), y1 + 9 * math.sin(a)
        f.line(mx - 5, my + 5, mx + 5, my - 5, stroke=stroke, width=1.3)


def msg(f, pts, stroke=FLOW):
    """A message flow: dashed, a hollow circle where it leaves, a hollow head where it lands."""
    f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke=stroke, width=1.2, dash='5 3')
    f.circle(*pts[0], 3.5, fill='--panel', stroke=stroke, width=1.2)
    _head(f, *pts[-1], _ang(pts), stroke=stroke, hollow=True)


def assoc(f, pts, stroke=FLOW, arrow=False):
    f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke=stroke, width=1.2, dash='2 3')
    if arrow:
        (x1, y1), (x2, y2) = pts[-2], pts[-1]
        a = math.atan2(y2 - y1, x2 - x1)
        for side in (-1, 1):
            b = a + math.pi - side * 0.45
            f.line(x2, y2, x2 + 8 * math.cos(b), y2 + 8 * math.sin(b), stroke=stroke, width=1.2)


def _envelope(f, x, y, w, h, stroke, filled):
    f.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill=stroke if filled else '--panel', width=1.1, rx=0.5)
    f.path(f'M{x - w / 2 + 0.3:.1f} {y - h / 2 + 0.2:.1f} L{x:.1f} {y + h * 0.1:.1f} L{x + w / 2 - 0.3:.1f} {y - h / 2 + 0.2:.1f}',
           stroke='--panel' if filled else stroke, width=1.1)


def _marker(f, x, y, r, kind, throw, stroke):
    if kind == 'msg':
        _envelope(f, x, y, r * 1.05, r * 0.72, stroke, throw)
    elif kind == 'timer':
        f.circle(x, y, round(r * 0.6, 1), fill='--panel', stroke=stroke, width=1.1)
        f.path(f'M{x:.1f} {y - r * 0.42:.1f} L{x:.1f} {y:.1f} L{x + r * 0.3:.1f} {y + r * 0.12:.1f}',
               stroke=stroke, width=1.1)
    elif kind == 'error':
        s = r * 0.5
        d = (f'M{x - s:.1f} {y + s:.1f} L{x - s * 0.45:.1f} {y - s * 0.8:.1f} L{x + s * 0.2:.1f} {y + s * 0.1:.1f} '
             f'L{x + s:.1f} {y - s:.1f} L{x + s * 0.45:.1f} {y + s * 0.8:.1f} L{x - s * 0.2:.1f} {y - s * 0.1:.1f} Z')
        f.path(d, stroke=stroke, width=1.1, fill=stroke if throw else '--panel')
    elif kind == 'comp':
        s = r * 0.42
        for dx in (-s * 0.95, 0):
            f.path(f'M{x + dx - s * 0.05:.1f} {y:.1f} L{x + dx + s:.1f} {y - s * 0.75:.1f} '
                   f'L{x + dx + s:.1f} {y + s * 0.75:.1f} Z', stroke=stroke, width=1.1,
                   fill=stroke if throw else '--panel')


def event(f, x, y, kind='start', marker=None, throw=False, interrupting=True, r=13, stroke=EVENT):
    """start: thin border. mid: double border, dashed when non-interrupting. end: thick border."""
    if kind == 'start':
        f.circle(x, y, r, fill='--panel', stroke=stroke, width=1.4)
    elif kind == 'mid':
        dash = None if interrupting else '3 2'
        f.circle(x, y, r, fill='--panel', stroke=stroke, width=1.2, dash=dash)
        f.circle(x, y, r - 3, fill='--panel', stroke=stroke, width=1.2, dash=dash)
    else:
        f.circle(x, y, r - 1, fill='--panel', stroke=stroke, width=3.4)
    if marker:
        _marker(f, x, y, r, marker, throw or kind == 'end', stroke)


def _user(f, x, y, stroke):
    f.circle(x, y - 2.5, 2.6, fill='--panel', stroke=stroke, width=1.1)
    f.path(f'M{x - 5:.1f} {y + 5:.1f} Q{x:.1f} {y - 2:.1f} {x + 5:.1f} {y + 5:.1f} Z', stroke=stroke, width=1.1,
           fill='--panel')


def _gear(f, x, y, stroke):
    for i in range(8):
        a = i * math.pi / 4
        f.line(x + 3.6 * math.cos(a), y + 3.6 * math.sin(a), x + 6 * math.cos(a), y + 6 * math.sin(a),
               stroke=stroke, width=1.8)
    f.circle(x, y, 3.8, fill='--panel', stroke=stroke, width=1.1)
    f.circle(x, y, 1.4, fill='--panel', stroke=stroke, width=1)


def task(f, x, y, w, h, rows, icon=None, marker=None, size=10, stroke=EVENT, fill='--panel', fillt='--paper'):
    """An activity, centred on x, y. icon: user, service, send, receive. marker: sub, comp."""
    f.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill=fill, width=1.4, rx=9)
    ix, iy = x - w / 2 + 11, y - h / 2 + 11
    if icon == 'user':
        _user(f, ix, iy, FLOW)
    elif icon == 'service':
        _gear(f, ix, iy, FLOW)
    elif icon in ('send', 'receive'):
        _envelope(f, ix, iy, 11, 7.5, FLOW, icon == 'send')
    dx = dy = 0
    if icon:
        dx, dy = 5, 4
    if marker:
        dy -= 4
    f.lines(x + dx, y + dy, rows, size=size, fill=fillt)
    if marker == 'sub':
        bx, by = x, y + h / 2 - 7
        f.rect(bx - 5, by - 5, 10, 10, stroke=FLOW, fill='--panel', width=1.1, rx=0)
        f.line(bx - 3, by, bx + 3, by, stroke=FLOW, width=1.1)
        f.line(bx, by - 3, bx, by + 3, stroke=FLOW, width=1.1)
    elif marker == 'comp':
        _marker(f, x, y + h / 2 - 8, 11, 'comp', False, FLOW)


def gateway(f, x, y, kind='xor', d=17, stroke=GATE):
    f.path(f'M{x:.1f} {y - d:.1f} L{x + d:.1f} {y:.1f} L{x:.1f} {y + d:.1f} L{x - d:.1f} {y:.1f} Z',
           stroke=stroke, width=1.4, fill='--panel')
    k = d * 0.36
    if kind == 'xor':
        f.line(x - k, y - k, x + k, y + k, stroke='--paper', width=2.4)
        f.line(x - k, y + k, x + k, y - k, stroke='--paper', width=2.4)
    elif kind == 'and':
        f.line(x - d * 0.5, y, x + d * 0.5, y, stroke='--paper', width=2.6)
        f.line(x, y - d * 0.5, x, y + d * 0.5, stroke='--paper', width=2.6)
    elif kind == 'or':
        f.circle(x, y, round(d * 0.42, 1), fill='--panel', stroke='--paper', width=2.2)
    elif kind == 'event':
        f.circle(x, y, round(d * 0.52, 1), fill='--panel', stroke='--paper', width=1)
        f.circle(x, y, round(d * 0.42, 1), fill='--panel', stroke='--paper', width=1)
        p = d * 0.24
        pts = [(x + p * math.cos(-math.pi / 2 + i * 2 * math.pi / 5),
                y + p * math.sin(-math.pi / 2 + i * 2 * math.pi / 5)) for i in range(5)]
        f.path('M' + ' L'.join(f'{a:.1f} {b:.1f}' for a, b in pts) + ' Z', stroke='--paper', width=1,
               fill='--panel')


def dataobj(f, x, y, w=24, h=30, stroke=FLOW):
    l, t, fold = x - w / 2, y - h / 2, 7
    f.path(f'M{l:.1f} {t:.1f} L{l + w - fold:.1f} {t:.1f} L{l + w:.1f} {t + fold:.1f} L{l + w:.1f} {t + h:.1f} '
           f'L{l:.1f} {t + h:.1f} Z', stroke=stroke, width=1.2, fill='--panel')
    f.path(f'M{l + w - fold:.1f} {t:.1f} L{l + w - fold:.1f} {t + fold:.1f} L{l + w:.1f} {t + fold:.1f}',
           stroke=stroke, width=1.2)


def token(f, x, y, fill='--amber'):
    f.circle(x, y, 5, fill=fill, stroke='--paper', width=1)


# ------------------------------------------------------------------- the figures

@figure('l07-shapes', 7)
def shapes():
    f = Fig('l07-shapes', 720, 372, T(
        'The core shapes of BPMN 2.0, in four rows, each named underneath. Events are circles: a '
        'start event has a thin border, an intermediate event a double border and an end event a '
        'thick border; a message marker inside one is hollow when the event catches a message and '
        'filled when it throws one. Activities are rounded rectangles: a plain task, a user task with '
        'a person icon, a service task with a gear icon, a collapsed sub-process with a plus sign at '
        'the bottom, and beside them a data object drawn as a page with a folded corner. Gateways '
        'are diamonds: exclusive with an X, parallel with a plus, inclusive with a circle, and '
        'event-based with a pentagon inside a double circle. Connecting objects: a sequence flow is '
        'a solid arrow, a message flow a dashed arrow starting at a small circle, and an association '
        'a dotted line.',
        'As formas centrais da BPMN 2.0, em quatro linhas, cada uma com o nome embaixo. Eventos são '
        'círculos: o evento de início tem borda fina, o intermediário borda dupla e o de fim borda '
        'grossa; um marcador de mensagem dentro dele é vazado quando o evento recebe uma mensagem e '
        'cheio quando envia. Atividades são retângulos arredondados: uma tarefa simples, uma tarefa '
        'de usuário com o ícone de uma pessoa, uma tarefa de serviço com uma engrenagem, um '
        'subprocesso recolhido com um sinal de mais embaixo, e ao lado um objeto de dados desenhado '
        'como uma página de canto dobrado. Gateways são losangos: exclusivo com um X, paralelo com '
        'um mais, inclusivo com um círculo, e baseado em eventos com um pentágono dentro de um '
        'círculo duplo. Objetos de conexão: o fluxo de sequência é uma seta contínua, o fluxo de '
        'mensagem uma seta tracejada que sai de um pequeno círculo, e a associação uma linha '
        'pontilhada.'))
    cols = [72, 216, 360, 504, 648]

    def name(x, y, a, b):
        f.text(x, y, a, size=10.5)
        f.text(x, y + 14, b, size=9.5, fill='--paper-dim')

    y = 36
    event(f, cols[0], y, 'start')
    name(cols[0], y + 28, T('start event', 'evento de início'), T('thin border', 'borda fina'))
    event(f, cols[1], y, 'mid')
    name(cols[1], y + 28, T('intermediate event', 'evento intermediário'), T('double border', 'borda dupla'))
    event(f, cols[2], y, 'end')
    name(cols[2], y + 28, T('end event', 'evento de fim'), T('thick border', 'borda grossa'))
    event(f, cols[3], y, 'mid', 'msg')
    name(cols[3], y + 28, T('catches a message', 'recebe mensagem'), T('hollow marker', 'marcador vazado'))
    event(f, cols[4], y, 'mid', 'msg', throw=True)
    name(cols[4], y + 28, T('throws a message', 'envia mensagem'), T('filled marker', 'marcador cheio'))

    y = 138
    task(f, cols[0], y, 104, 44, [T('Check', 'Conferir'), T('documents', 'documentos')])
    name(cols[0], y + 36, T('task', 'tarefa'), T('rounded corners', 'cantos arredondados'))
    task(f, cols[1], y, 104, 44, [T('Quality visit', 'Visita técnica')], icon='user')
    name(cols[1], y + 36, T('user task', 'tarefa de usuário'), T('a person does it', 'uma pessoa faz'))
    task(f, cols[2], y, 104, 44, [T('Register farm', 'Cadastrar')], icon='service')
    name(cols[2], y + 36, T('service task', 'tarefa de serviço'), T('a system does it', 'um sistema faz'))
    task(f, cols[3], y, 104, 44, [T('Onboard farm', 'Integrar')], marker='sub')
    name(cols[3], y + 36, T('sub-process', 'subprocesso'), T('collapsed: the + marker', 'recolhido: o marcador +'))
    dataobj(f, cols[4], y - 2)
    f.text(cols[4] + 22, y - 2, T('contract', 'contrato'), size=10, anchor='start')
    name(cols[4], y + 36, T('data object', 'objeto de dados'), T('what the work uses', 'o que o trabalho usa'))

    y = 238
    gx = [144, 288, 432, 576]
    gateway(f, gx[0], y, 'xor', d=19)
    name(gx[0], y + 32, T('exclusive (XOR)', 'exclusivo (XOR)'), T('exactly one path', 'exatamente um caminho'))
    gateway(f, gx[1], y, 'and', d=19)
    name(gx[1], y + 32, T('parallel (AND)', 'paralelo (AND)'), T('every path', 'todos os caminhos'))
    gateway(f, gx[2], y, 'or', d=19)
    name(gx[2], y + 32, T('inclusive (OR)', 'inclusivo (OR)'), T('one or more paths', 'um ou mais caminhos'))
    gateway(f, gx[3], y, 'event', d=19)
    name(gx[3], y + 32, T('event-based', 'baseado em eventos'), T('the first event wins', 'o primeiro evento vence'))

    y = 330
    seq(f, [(60, y), (180, y)])
    name(120, y + 16, T('sequence flow', 'fluxo de sequência'), T('order, inside one pool', 'ordem, dentro de um pool'))
    msg(f, [(300, y), (420, y)])
    name(360, y + 16, T('message flow', 'fluxo de mensagem'), T('between pools', 'entre pools'))
    assoc(f, [(540, y), (660, y)])
    name(600, y + 16, T('association', 'associação'), T('links a note or data', 'liga nota ou dado'))
    return f, T('The shapes this lesson uses. A border says what kind of event it is; a marker inside a shape '
                'says what it waits for or does; a diamond is a gateway, and its marker is its rule.',
                'As formas que esta aula usa. A borda diz que tipo de evento é; o marcador dentro de uma forma '
                'diz o que ela espera ou faz; o losango é um gateway, e o marcador dele é a regra.')


@figure('l07-happy-path', 7)
def happy_path():
    f = Fig('l07-happy-path', 720, 270, T(
        'The farm onboarding process at Serra Alta, drawn in BPMN, left to right. A message start '
        'event, application received, leads to a user task, check documents. A parallel gateway '
        'splits the flow into two branches that run at the same time: a user task, quality visit, '
        'and a service task, register bank account. A second parallel gateway joins them. An '
        'exclusive gateway asks whether the farm is approved. If yes, a send task sends the '
        'contract, an intermediate message event waits for the signed contract, a service task '
        'creates the farm in Coleta and SAP, and an end event says the farm is onboarded. If no, '
        'which is the default flow, a send task notifies the farm and an end event says it was '
        'turned down.',
        'O processo de cadastro de fazendas da Serra Alta, desenhado em BPMN, da esquerda para a '
        'direita. Um evento de início de mensagem, pedido recebido, leva a uma tarefa de usuário, '
        'conferir documentos. Um gateway paralelo divide o fluxo em dois ramos que correm ao mesmo '
        'tempo: uma tarefa de usuário, visita técnica, e uma tarefa de serviço, cadastrar conta '
        'bancária. Um segundo gateway paralelo os junta. Um gateway exclusivo pergunta se a fazenda '
        'foi aprovada. Se sim, uma tarefa de envio manda o contrato, um evento intermediário de '
        'mensagem espera o contrato assinado, uma tarefa de serviço cria a fazenda no Coleta e no '
        'SAP, e um evento de fim diz que a fazenda foi cadastrada. Se não, que é o fluxo padrão, uma '
        'tarefa de envio avisa a fazenda e um evento de fim diz que ela foi recusada.'))
    y = 118
    event(f, 26, y, 'start', 'msg')
    f.lines(26, y + 30, [T('application', 'pedido'), T('received', 'recebido')], size=9.5, fill='--paper-dim')
    seq(f, [(39, y), (58, y)])
    task(f, 100, y, 84, 46, [T('Check', 'Conferir'), T('documents', 'documentos')], icon='user', size=9.5)
    seq(f, [(142, y), (158, y)])
    gateway(f, 174, y, 'and', d=16)
    task(f, 256, y - 50, 100, 46, [T('Quality visit', 'Visita técnica')], icon='user', size=9.5)
    task(f, 256, y + 50, 100, 46, [T('Register bank', 'Cadastrar conta'), T('account', 'bancária')],
         icon='service', size=9.5)
    seq(f, [(174, y - 16), (174, y - 50), (206, y - 50)])
    seq(f, [(174, y + 16), (174, y + 50), (206, y + 50)])
    seq(f, [(306, y - 50), (338, y - 50), (338, y - 16)])
    seq(f, [(306, y + 50), (338, y + 50), (338, y + 16)])
    gateway(f, 338, y, 'and', d=16)
    seq(f, [(354, y), (376, y)])
    gateway(f, 392, y, 'xor', d=16)
    f.text(392, y - 26, T('approved?', 'aprovada?'), size=9.5, fill='--paper-dim')
    seq(f, [(408, y), (428, y)])
    f.text(417, y - 9, T('yes', 'sim'), size=9, fill='--paper-dim')
    task(f, 466, y, 76, 46, [T('Send', 'Enviar'), T('contract', 'contrato')], icon='send', size=9.5)
    seq(f, [(504, y), (518, y)])
    event(f, 532, y, 'mid', 'msg')
    f.lines(532, y + 30, [T('signed', 'contrato'), T('contract', 'assinado')], size=9.5, fill='--paper-dim')
    seq(f, [(545, y), (560, y)])
    task(f, 610, y, 100, 46, [T('Create farm in', 'Criar fazenda no'), T('Coleta and SAP', 'Coleta e no SAP')],
         icon='service', size=9.5)
    seq(f, [(660, y), (680, y)])
    event(f, 694, y, 'end')
    f.lines(694, y + 30, [T('farm', 'fazenda'), T('onboarded', 'cadastrada')], size=9.5, fill='--paper-dim')
    # the default flow: turned down
    seq(f, [(392, y + 16), (392, 218), (428, 218)], slash=True)
    f.text(404, y + 40, T('no', 'não'), size=9, fill='--paper-dim', anchor='start')
    task(f, 466, 218, 76, 46, [T('Notify', 'Avisar'), T('farm', 'fazenda')], icon='send', size=9.5)
    seq(f, [(504, 218), (518, 218)])
    event(f, 532, 218, 'end')
    f.text(552, 218, T('turned down', 'recusada'), size=9.5, fill='--paper-dim', anchor='start')
    return f, T('The happy path of farm onboarding, about thirty days from left to right. The two branches '
                'between the plus signs run at the same time; the X picks one way out, and the slash marks '
                'the way taken when no condition is true.',
                'O caminho feliz do cadastro de fazendas, cerca de trinta dias da esquerda para a direita. Os '
                'dois ramos entre os sinais de mais correm ao mesmo tempo; o X escolhe uma saída, e o traço '
                'marca a saída tomada quando nenhuma condição é verdadeira.')


def _pair(f, x0, y0, split, join, tokens_in, verdict, ok):
    """One pairing: a split, two tasks, a join, and the task after it, with tokens drawn."""
    w, h = 340, 150
    f.rect(x0, y0, w, h, stroke='--wire' if ok else '--amber', fill='--panel', width=1.2, rx=6)
    cy = y0 + 62
    sx, jx, tx = x0 + 36, x0 + 196, x0 + 274
    gateway(f, sx, cy, split, d=15)
    seq(f, [(x0 + 6, cy), (sx - 15, cy)])
    task(f, x0 + 116, cy - 30, 70, 30, ['A'], size=10)
    task(f, x0 + 116, cy + 30, 70, 30, ['B'], size=10)
    seq(f, [(sx, cy - 15), (sx, cy - 30), (x0 + 81, cy - 30)])
    seq(f, [(sx, cy + 15), (sx, cy + 30), (x0 + 81, cy + 30)])
    seq(f, [(x0 + 151, cy - 30), (jx, cy - 30), (jx, cy - 15)])
    seq(f, [(x0 + 151, cy + 30), (jx, cy + 30), (jx, cy + 15)])
    gateway(f, jx, cy, join, d=15)
    seq(f, [(jx + 15, cy), (tx - 35, cy)])
    task(f, tx, cy, 70, 30, ['C'], size=10, stroke=EVENT if ok else '--amber')
    for (tx_, ty_) in tokens_in:
        token(f, tx_, ty_, fill='--phosphor' if ok else '--amber')
    f.lines(x0 + w / 2, y0 + 124, verdict, size=10, fill='--paper' if ok else '--amber')


@figure('l07-pairings', 7)
def pairings():
    f = Fig('l07-pairings', 720, 340, T(
        'Four small processes in a grid, each with a split gateway, two tasks A and B, a join '
        'gateway and a task C, and the tokens drawn as dots. Top left, correct: a parallel split '
        'joined by a parallel join; two tokens wait at the join and C runs once. Top right, correct: '
        'an exclusive split joined by an exclusive merge; one token passes and C runs once. Bottom '
        'left, broken: a parallel split joined by an exclusive merge; both tokens pass straight '
        'through and C runs twice. Bottom right, broken: an exclusive split joined by a parallel '
        'join; one token arrives, the join waits for a second that never comes, and the instance '
        'is stuck.',
        'Quatro processos pequenos em grade, cada um com um gateway de divisão, duas tarefas A e B, '
        'um gateway de junção e uma tarefa C, com os tokens desenhados como pontos. Em cima à '
        'esquerda, correto: divisão paralela juntada por junção paralela; dois tokens esperam na '
        'junção e C roda uma vez. Em cima à direita, correto: divisão exclusiva juntada por junção '
        'exclusiva; um token passa e C roda uma vez. Embaixo à esquerda, quebrado: divisão paralela '
        'juntada por junção exclusiva; os dois tokens passam direto e C roda duas vezes. Embaixo à '
        'direita, quebrado: divisão exclusiva juntada por junção paralela; um token chega, a junção '
        'espera um segundo que nunca vem, e a instância fica presa.'))
    _pair(f, 10, 10, 'and', 'and', [(196 + 10 - 8, 62 + 10 - 24), (196 + 10 - 8, 62 + 10 + 24)],
          [T('AND then AND: the join waits for', 'AND e AND: a junção espera'),
           T('both tokens, and C runs once', 'os dois tokens, e C roda uma vez')], True)
    _pair(f, 370, 10, 'xor', 'xor', [(370 + 66, 72 - 30)],
          [T('XOR then XOR: one token goes', 'XOR e XOR: um token passa'),
           T('through, and C runs once', 'e C roda uma vez')], True)
    _pair(f, 10, 180, 'and', 'xor', [(10 + 250, 242 - 7), (10 + 250, 242 + 7)],
          [T('AND then XOR: each token passes', 'AND e XOR: cada token passa'),
           T('the merge, and C runs twice', 'pela junção, e C roda duas vezes')], False)
    _pair(f, 370, 180, 'xor', 'and', [(370 + 196 - 8, 242 - 24)],
          [T('XOR then AND: the join waits for a', 'XOR e AND: a junção espera um token'),
           T('token that never comes, for ever', 'que nunca vem, para sempre')], False)
    return f, T('Tokens are what make a pairing right or wrong. A parallel join counts arrivals and a merge '
                'lets each one through, so the join has to match the split that made the tokens.',
                'São os tokens que tornam um par certo ou errado. A junção paralela conta as chegadas e a '
                'junção exclusiva deixa cada uma passar, então a junção tem de casar com a divisão que criou '
                'os tokens.')


@figure('l07-collaboration', 7)
def collaboration():
    f = Fig('l07-collaboration', 720, 420, T(
        'A BPMN collaboration diagram of farm onboarding with three pools. At the top, the farm, a '
        'black-box pool with nothing drawn inside it. In the middle, Serra Alta, a pool with three '
        'lanes: field team, quality and finance. At the bottom, the bank, another black-box pool. '
        'Inside Serra Alta the process runs on sequence flows that cross lanes freely: the '
        'application starts it in the field team lane, documents are checked there, a parallel '
        'gateway sends one branch to the quality visit in the quality lane and one to registering '
        'the bank account in the finance lane, a parallel join and an approval gateway follow, the '
        'contract is sent, the signed contract is awaited, and finance creates the farm in Coleta '
        'and SAP. A refused farm ends in the quality lane. Dashed message flows cross the pool '
        'boundaries only: the application from the farm to the start event, the contract from the '
        'send task up to the farm, the signed contract from the farm down to the waiting event, and '
        'account details from the bank registration task down to the bank, with a confirmation '
        'coming back up.',
        'Um diagrama de colaboração BPMN do cadastro de fazendas com três pools. Em cima, a fazenda, '
        'um pool caixa-preta sem nada desenhado dentro. No meio, a Serra Alta, um pool com três '
        'raias: equipe de campo, qualidade e financeiro. Embaixo, o banco, outro pool caixa-preta. '
        'Dentro da Serra Alta o processo segue por fluxos de sequência que cruzam raias livremente: '
        'o pedido o inicia na raia da equipe de campo, os documentos são conferidos ali, um gateway '
        'paralelo manda um ramo para a visita técnica na raia da qualidade e outro para o cadastro '
        'da conta bancária na raia do financeiro, seguem uma junção paralela e um gateway de '
        'aprovação, o contrato é enviado, o contrato assinado é aguardado, e o financeiro cria a '
        'fazenda no Coleta e no SAP. Uma fazenda recusada termina na raia da qualidade. Fluxos de '
        'mensagem tracejados só cruzam as fronteiras dos pools: o pedido da fazenda até o evento de '
        'início, o contrato da tarefa de envio até a fazenda, o contrato assinado da fazenda até o '
        'evento que espera, e os dados da conta da tarefa de cadastro até o banco, com uma '
        'confirmação voltando.'))
    L = 10
    # the farm, a black box
    f.rect(L, 10, 700, 44, stroke='--paper-dim', fill='--panel', width=1.4, rx=0)
    f.text(360, 32, T('Farm (a black box: Serra Alta does not draw its process)',
                      'Fazenda (caixa-preta: a Serra Alta não desenha o processo dela)'), size=10.5)
    # Serra Alta, three lanes
    top, lane = 80, 92
    f.rect(L, top, 700, lane * 3, stroke='--paper-dim', fill='--panel', width=1.4, rx=0)
    f.rect(L, top, 56, lane * 3, stroke='--paper-dim', fill='--scan', width=1.2, rx=0)
    f.lines(L + 28, top + lane * 1.5, ['Serra', 'Alta'], size=10.5, weight='600')
    names = [[T('field', 'equipe'), T('team', 'de campo')], [T('quality', 'qualidade')],
             [T('finance', 'financeiro')]]
    for i, rows in enumerate(names):
        f.rect(L + 56, top + lane * i, 70, lane, stroke='--wire', fill='--panel', width=1, rx=0)
        f.lines(L + 91, top + lane * i + lane / 2, rows, size=10)
    for i in (1, 2):
        f.line(L + 126, top + lane * i, L + 700, top + lane * i, stroke='--wire', width=1)
    # the bank, a black box
    f.rect(L, 366, 700, 44, stroke='--paper-dim', fill='--panel', width=1.4, rx=0)
    f.text(120, 388, T('Bank', 'Banco'), size=10.5)

    y1, y2, y3 = top + lane * 0.5, top + lane * 1.5, top + lane * 2.5
    event(f, 160, y1, 'start', 'msg', r=12)
    seq(f, [(172, y1), (190, y1)])
    task(f, 228, y1, 76, 42, [T('Check', 'Conferir'), T('documents', 'documentos')], size=9.5)
    seq(f, [(266, y1), (282, y1)])
    gateway(f, 297, y1, 'and', d=15)
    seq(f, [(297, y1 + 15), (297, y2), (322, y2)])
    seq(f, [(312, y1), (312, y3), (322, y3)])
    task(f, 368, y2, 88, 42, [T('Quality visit', 'Visita técnica')], icon='user', size=9.5)
    task(f, 368, y3, 88, 42, [T('Register bank', 'Cadastrar'), T('account', 'conta')], icon='service', size=9.5)
    seq(f, [(412, y2), (425, y2)])
    seq(f, [(412, y3), (440, y3), (440, y2 + 15)])
    gateway(f, 440, y2, 'and', d=15)
    seq(f, [(440, y2 - 15), (440, y1), (466, y1)])
    gateway(f, 481, y1, 'xor', d=15)
    seq(f, [(496, y1), (506, y1)])
    seq(f, [(481, y1 + 15), (481, y2 - 12)], slash=True)
    event(f, 481, y2, 'end', r=12)
    task(f, 540, y1, 68, 42, [T('Send', 'Enviar'), T('contract', 'contrato')], icon='send', size=9.5)
    seq(f, [(574, y1), (590, y1)])
    event(f, 602, y1, 'mid', 'msg', r=12)
    seq(f, [(614, y1), (630, y1), (630, y3 - 25)])
    seq(f, [(676, y3), (684, y3)])
    event(f, 694, y3, 'end', r=9)
    task(f, 630, y3, 92, 50, [T('Create farm', 'Criar fazenda'), T('in Coleta', 'no Coleta'), T('and SAP', 'e no SAP')],
         icon='service', size=9.5)
    # message flows, which are the only lines that cross a pool's edge
    msg(f, [(160, 54), (160, y1 - 12)])
    msg(f, [(540, y1 - 21), (540, 54)])
    msg(f, [(602, 54), (602, y1 - 12)])
    msg(f, [(358, y3 + 21), (358, 366)])
    msg(f, [(378, 366), (378, y3 + 21)])
    f.text(392, 388, T('account details, then a confirmation', 'dados da conta, depois a confirmação'),
           size=9.5, fill='--paper-dim', anchor='start')
    return f, T('The same process as a collaboration. Lanes are roles inside Serra Alta and the flow crosses '
                'them freely; the farm and the bank are pools of their own, and only messages cross into them.',
                'O mesmo processo como colaboração. As raias são papéis dentro da Serra Alta e o fluxo as '
                'cruza à vontade; a fazenda e o banco são pools próprios, e só mensagens entram neles.')


@figure('l07-boundary', 7)
def boundary():
    f = Fig('l07-boundary', 720, 330, T(
        'Three fragments of the onboarding process. Left: the quality visit user task carries a '
        'timer boundary event with a dashed double border, which makes it non-interrupting; after '
        '10 days it starts a separate path to escalate to the quality manager while the visit '
        'stays open. Middle: the register bank account service task carries two boundary events. '
        'An error event with a solid border interrupts the task when the bank rejects the account '
        'and leads to a task asking the farm for the details again. A compensation event is joined '
        'by a dotted association to a compensation task, cancel the account registration, which '
        'is drawn with the rewind marker and has no sequence flow in or out. Right: after the '
        'contract is sent, an event-based gateway waits for whichever comes first: the signed '
        'contract, which continues the process, a refusal message, or a 30-day timer. The refusal '
        'and the timer each lead to an end event that throws compensation, which runs the cancel '
        'task for the account registered earlier.',
        'Três fragmentos do processo de cadastro. À esquerda: a tarefa de usuário da visita técnica '
        'leva um evento de borda de tempo com borda dupla tracejada, o que o torna não interruptivo; '
        'depois de 10 dias ele abre um caminho à parte para escalar à gerente de qualidade enquanto a '
        'visita continua aberta. No meio: a tarefa de serviço de cadastrar a conta bancária leva dois '
        'eventos de borda. Um evento de erro com borda contínua interrompe a tarefa quando o banco '
        'rejeita a conta e leva a uma tarefa que pede os dados de novo à fazenda. Um evento de '
        'compensação é ligado por uma associação pontilhada a uma tarefa de compensação, cancelar o '
        'cadastro da conta, desenhada com o marcador de retroceder e sem fluxo de sequência de '
        'entrada ou saída. À direita: depois de enviado o contrato, um gateway baseado em eventos '
        'espera o que vier primeiro: o contrato assinado, que segue o processo, uma mensagem de '
        'recusa, ou um temporizador de 30 dias. A recusa e o temporizador levam cada um a um evento '
        'de fim que dispara a compensação, que roda a tarefa de cancelamento da conta cadastrada '
        'antes.'))
    for x0, title in ((10, T('a timer that escalates', 'um timer que escala')),
                      (250, T('an error, and the undo', 'um erro, e o desfazer')),
                      (490, T('whichever comes first', 'o que vier primeiro'))):
        f.rect(x0, 10, 220, 310, stroke='--wire', fill='--panel', width=1, rx=6)
        f.text(x0 + 110, 30, title, size=11, weight='600')
    # left: non-interrupting timer
    task(f, 120, 92, 120, 50, [T('Quality visit', 'Visita técnica')], icon='user', size=10)
    seq(f, [(26, 92), (60, 92)])
    seq(f, [(180, 92), (214, 92)])
    event(f, 150, 117, 'mid', 'timer', interrupting=False, r=12)
    f.text(172, 136, T('10 days', '10 dias'), size=9.5, fill='--paper-dim', anchor='start')
    seq(f, [(150, 129), (150, 196), (120, 196), (120, 208)])
    task(f, 120, 232, 120, 48, [T('Escalate to the', 'Escalar para a'), T('quality manager', 'gerente de qualidade')],
         icon='user', size=9.5)
    f.lines(120, 290, [T('dashed border: the visit', 'borda tracejada: a visita'),
                       T('stays open, nothing is cut', 'continua aberta, nada é cortado')],
            size=9.5, fill='--amber')
    # middle: error and compensation
    task(f, 360, 92, 120, 50, [T('Register bank', 'Cadastrar conta'), T('account', 'bancária')],
         icon='service', size=10)
    seq(f, [(266, 92), (300, 92)])
    seq(f, [(420, 92), (454, 92)])
    event(f, 330, 117, 'mid', 'error', r=12)
    seq(f, [(330, 129), (330, 180), (316, 180), (316, 196)])
    task(f, 316, 220, 80, 48, [T('Ask for the', 'Pedir os'), T('details again', 'dados de novo')],
         icon='send', size=9.5)
    event(f, 396, 117, 'mid', 'comp', r=12)
    assoc(f, [(396, 129), (412, 196)], arrow=True)
    task(f, 412, 220, 76, 48, [T('Cancel', 'Cancelar'), T('registration', 'cadastro')], marker='comp', size=9.5)
    f.lines(360, 290, [T('error: solid border, interrupts', 'erro: borda contínua, interrompe'),
                       T('undo: reached only by compensation', 'desfazer: só por compensação')],
            size=9.5, fill='--amber')
    # right: event-based gateway
    gx, gy = 528, 160
    seq(f, [(500, gy), (gx - 15, gy)])
    gateway(f, gx, gy, 'event', d=15)
    for yy in (80, 160, 240):
        if yy != gy:
            seq(f, [(gx, gy - 15 if yy < gy else gy + 15), (gx, yy), (574, yy)])
        else:
            seq(f, [(gx + 15, gy), (574, gy)])
    event(f, 586, 80, 'mid', 'msg', r=12)
    f.text(586, 104, T('signed', 'assinado'), size=9.5, fill='--paper-dim')
    seq(f, [(598, 80), (708, 80)])
    f.text(652, 70, T('go on', 'segue'), size=9.5, fill='--paper-dim')
    event(f, 586, 160, 'mid', 'msg', r=12)
    f.text(586, 184, T('refused', 'recusado'), size=9.5, fill='--paper-dim')
    event(f, 586, 240, 'mid', 'timer', r=12)
    f.text(586, 264, T('30 days', '30 dias'), size=9.5, fill='--paper-dim')
    seq(f, [(598, 160), (652, 160)])
    seq(f, [(598, 240), (652, 240)])
    event(f, 665, 160, 'end', 'comp', r=12)
    event(f, 665, 240, 'end', 'comp', r=12)
    f.lines(600, 296, [T('either loser ends by throwing', 'quem perde termina disparando'),
                       T('compensation', 'a compensação')], size=9.5, fill='--amber')
    return f, T('Three things a happy path leaves out: what happens when a person does not act, when a '
                'system says no, and when the other side never answers.',
                'Três coisas que o caminho feliz deixa de fora: o que acontece quando uma pessoa não age, '
                'quando um sistema diz não, e quando o outro lado nunca responde.')
