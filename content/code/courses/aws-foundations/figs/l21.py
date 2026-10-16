"""Lesson 21: Route 53, the delegation and the routing policies."""
from figures import Fig, T, figure


@figure('l21-delegation', 21)
def delegation():
    f = Fig('l21-delegation', 720, 400, T(
        'How a resolver finds the shop, drawn as a sequence with time running downwards. Four columns: '
        'a resolver, the root servers, the .com servers, and Route 53, whose name server is '
        'ns-2048.awsdns-64.com. Step 1, the resolver asks the root about mail.shop.example.com; step 2, '
        'the root answers: ask .com. Step 3, it asks the .com servers; step 4, they answer: ask '
        'ns-2048.awsdns-64.com. Step 5, it asks Route 53; step 6, Route 53 answers with the record, '
        '203.0.113.25. Under the .com column, the registrar, which wrote the four NS names that step 4 '
        'answers with. Only step 6 reads the hosted zone.',
        'Como um resolvedor encontra a loja, desenhado como uma sequência com o tempo correndo para '
        'baixo. Quatro colunas: um resolvedor, os servidores raiz, os servidores de .com, e o Route 53, '
        'cujo servidor de nomes é ns-2048.awsdns-64.com. Passo 1, o resolvedor pergunta à raiz por '
        'www.shop.example.com; passo 2, a raiz responde: pergunte a .com. Passo 3, ele pergunta aos '
        'servidores de .com; passo 4, eles respondem: pergunte a ns-2048.awsdns-64.com. Passo 5, ele '
        'pergunta ao Route 53; passo 6, o Route 53 responde com o registro, 203.0.113.25. Sob a coluna '
        'de .com, o registrador, que escreveu os quatro nomes NS com que o passo 4 responde. Só o passo '
        '6 lê a zona hospedada.'))
    cols = [(90, T('a resolver', 'um resolvedor'), None, '--paper-dim'),
            (280, T('the root', 'a raiz'), None, '--paper-dim'),
            (450, T('the .com servers', 'os servidores de .com'), None, '--paper-dim'),
            (620, 'Route 53', 'ns-2048.awsdns-64.com', '--phosphor')]
    for x, name, sub, edge in cols:
        f.rect(x - 80, 20, 160, 44, stroke=edge, fill='--scan', width=1.4)
        if sub:
            f.text(x, 35, name, size=11, weight='600')
            f.text(x, 52, sub, size=9, mono=True, fill='--paper-dim')
        else:
            f.text(x, 42, name, size=11, weight='600')
        f.line(x, 66, x, 300, stroke='--paper-dim', width=1.0, dash='3 4')
    msgs = [(1, 95, 280, 'mail.shop.example.com?', True, '--paper-dim'),
            (2, 125, 280, T('ask .com', 'pergunte a .com'), False, '--amber'),
            (3, 165, 450, 'mail.shop.example.com?', True, '--paper-dim'),
            (4, 195, 450, T('ask ns-2048.awsdns-64.com', 'pergunte a ns-2048.awsdns-64.com'), False,
             '--amber'),
            (5, 235, 620, 'mail.shop.example.com?', True, '--paper-dim'),
            (6, 265, 620, T('the record: 203.0.113.25', 'o registro: 203.0.113.25'), False,
             '--phosphor')]
    for n, y, x, label, question, colour in msgs:
        if question:
            f.arrow([(92, y), (x - 3, y)], stroke=colour, width=1.3)
            f.text(102, y - 9, label, size=9.5, mono=True, anchor='start', fill='--paper')
        else:
            f.arrow([(x - 2, y), (95, y)], stroke=colour, width=1.3)
            f.text(x - 10, y - 9, label, size=9.5, anchor='end', fill=colour)
        f.circle(56, y, 9, fill='--ink', stroke=colour)
        f.text(56, y + 0.5, str(n), size=9.5, weight='600')
    # the registrar wrote steps 3 and 4
    f.rect(370, 322, 160, 50, stroke='--wire', fill='--panel', dash='4 3')
    f.text(450, 340, T('the registrar', 'o registrador'), size=10.5, weight='600')
    f.text(450, 357, T('wrote the four NS names', 'escreveu os quatro NS'), size=9.5,
           fill='--paper-dim')
    f.line(450, 319, 450, 304, stroke='--amber', width=1.3, arrow=True)
    f.text(360, 392, T('time runs downwards; only step 6 reads the hosted zone',
                       'o tempo corre para baixo; só o passo 6 lê a zona hospedada'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('Creating a zone is step 6. Steps 3 and 4 are the delegation, and the registrar '
                'writes them.',
                'Criar uma zona é o passo 6. Os passos 3 e 4 são a delegação, e quem os escreve é o '
                'registrador.')


@figure('l21-routing', 21)
def routing():
    f = Fig('l21-routing', 720, 330, T(
        'Two routing policies side by side. On the left, weighted: the name search.shop.example.com '
        'holds two records, current with weight 90 at 203.0.113.30 and canary with weight 10 at '
        '203.0.113.31, so nine answers in ten give the first address. On the right, failover: '
        'api.shop.example.com holds a primary in São Paulo at 203.0.113.20, watched by a health check, '
        'and a secondary in Virginia at 198.51.100.20, given only while the check says the primary is '
        'unhealthy. Underneath: Route 53 chooses the answer, and the traffic never passes through it.',
        'Duas políticas de roteamento lado a lado. À esquerda, ponderada: o nome '
        'search.shop.example.com tem dois registros, current com peso 90 em 203.0.113.30 e canary com '
        'peso 10 em 203.0.113.31, então nove respostas em dez dão o primeiro endereço. À direita, '
        'failover: api.shop.example.com tem um primário em São Paulo em 203.0.113.20, vigiado por uma '
        'verificação de saúde, e um secundário na Virgínia em 198.51.100.20, dado só enquanto a '
        'verificação diz que o primário não está saudável. Embaixo: o Route 53 escolhe a resposta, e o '
        'tráfego nunca passa por ele.'))
    for x, title in ((20, T('weighted', 'ponderada')), (370, T('failover', 'failover'))):
        f.rect(x, 20, 330, 250, stroke='--paper-dim', fill='--ink', dash='6 4')
        f.text(x + 16, 40, title, size=11, weight='600', anchor='start', fill='--paper-dim')
    # weighted
    f.rect(70, 60, 230, 36, stroke='--phosphor', fill='--scan')
    f.text(185, 78, 'search.shop.example.com', size=10.5, mono=True)
    f.rect(40, 180, 130, 60, stroke='--wire', fill='--panel')
    f.text(105, 200, 'current', size=10.5, mono=True)
    f.text(105, 220, '203.0.113.30', size=10, mono=True, fill='--paper-dim')
    f.rect(200, 180, 130, 60, stroke='--wire', fill='--panel')
    f.text(265, 200, 'canary', size=10.5, mono=True)
    f.text(265, 220, '203.0.113.31', size=10, mono=True, fill='--paper-dim')
    f.arrow([(150, 98), (110, 176)], stroke='--phosphor', width=2.2)
    f.arrow([(220, 98), (260, 176)], stroke='--amber', width=1.0)
    f.text(112, 132, T('9 in 10', '9 em 10'), size=10.5, weight='600', fill='--phosphor',
           anchor='end')
    f.text(256, 132, T('1 in 10', '1 em 10'), size=10.5, weight='600', fill='--amber',
           anchor='start')
    f.text(185, 258, T('weights 90 and 10, a share of their sum', 'pesos 90 e 10, uma fração da soma'),
           size=9.5, fill='--paper-dim', italic=True)
    # failover
    f.rect(420, 60, 230, 36, stroke='--phosphor', fill='--scan')
    f.text(535, 78, 'api.shop.example.com', size=10.5, mono=True)
    f.rect(390, 180, 140, 60, stroke='--phosphor', fill='--panel')
    f.text(460, 200, T('PRIMARY, São Paulo', 'PRIMARY, São Paulo'), size=10)
    f.text(460, 220, '203.0.113.20', size=10, mono=True, fill='--paper-dim')
    f.rect(550, 180, 140, 60, stroke='--wire', fill='--panel', dash='4 3')
    f.text(620, 200, T('SECONDARY, Virginia', 'SECONDARY, Virgínia'), size=10)
    f.text(620, 220, '198.51.100.20', size=10, mono=True, fill='--paper-dim')
    f.arrow([(500, 98), (465, 176)], stroke='--phosphor', width=1.6)
    f.arrow([(570, 98), (615, 176)], stroke='--amber', width=1.2, dash='4 3')
    f.text(494, 128, T('while healthy', 'enquanto saudável'), size=10, fill='--phosphor',
           anchor='start')
    f.text(600, 128, T('when it is not', 'quando não está'), size=10, fill='--amber', anchor='start')
    # the health check, watching the primary
    f.circle(425, 128, 11, fill='--ink', stroke='--phosphor', width=1.4)
    f.text(425, 128.5, '✓', size=11, fill='--phosphor')
    f.text(425, 150, T('check', 'verificação'), size=9, fill='--paper-dim')
    f.line(430, 158, 440, 176, stroke='--phosphor', width=1.0, dash='2 2')
    f.text(535, 258, T('a health check on the primary only', 'verificação de saúde só no primário'),
           size=9.5, fill='--paper-dim', italic=True)
    f.text(360, 304, T('Route 53 chooses the answer; the traffic never passes through it',
                       'o Route 53 escolhe a resposta; o tráfego nunca passa por ele'),
           size=10.5, fill='--amber')
    return f, T('A policy is a rule for choosing between records. The choice is made once per '
                'question, and cached for the TTL.',
                'Uma política é uma regra para escolher entre registros. A escolha é feita uma vez por '
                'pergunta, e fica em cache pelo TTL.')
