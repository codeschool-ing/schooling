"""Lesson 9: Integration by file, by database, by API and by event."""
from figures import Fig, T, figure


@figure('l09-four-styles', 9)
def four_styles():
    f = Fig('l09-four-styles', 720, 340, T(
        'Four rows, one per integration style, each with an example from Serra Alta and a column '
        'saying whether both sides must be up at once. File transfer: Coleta writes a file, written '
        'at 23:30, and SAP reads it at 02:00; both up at once: no. Shared database: Coleta writes its '
        'own tables and Rota reads them directly; only the database must be up. API: the Portal B2B '
        'sends a request to SAP and waits for the answer, which comes back; both up at once: yes. '
        'Event: SAP publishes a message to a broker, and any number of subscribers receive it; both '
        'up at once: no, the broker holds the message.',
        'Quatro linhas, uma por estilo de integração, cada uma com um exemplo da Serra Alta e uma '
        'coluna dizendo se os dois lados precisam estar no ar ao mesmo tempo. Transferência de '
        'arquivo: o Coleta grava um arquivo, às 23:30, e o SAP o lê às 02:00; os dois no ar ao mesmo '
        'tempo: não. Banco compartilhado: o Coleta grava as próprias tabelas e o Rota as lê '
        'diretamente; só o banco precisa estar no ar. API: o Portal B2B manda uma requisição ao SAP e '
        'espera a resposta, que volta; os dois no ar ao mesmo tempo: sim. Evento: o SAP publica uma '
        'mensagem num broker, e qualquer número de assinantes a recebe; os dois no ar ao mesmo tempo: '
        'não, o broker guarda a mensagem.'))
    f.text(655, 24, T('both up at once?', 'os dois no ar juntos?'), size=10.5, weight='600')
    rows = [
        (T('file transfer', 'arquivo'), 'Coleta', 'SAP', T('no', 'não'), None),
        (T('shared database', 'banco compartilhado'), 'Coleta', 'Rota',
         T('only the database', 'só o banco'), None),
        ('API', 'Portal B2B', 'SAP', T('yes', 'sim'), None),
        (T('event', 'evento'), 'SAP', T('subscribers', 'assinantes'), T('no', 'não'), None),
    ]
    for i, (style, a, b, up, _) in enumerate(rows):
        y = 70 + i * 72
        if i:
            f.line(10, y - 36, 710, y - 36, stroke='--wire', width=0.8, dash='2 4')
        f.text(14, y, style, size=11, anchor='start', weight='600')
        f.box(205, y, 104, 34, [a], stroke='--phosphor', size=10.5)
        if i == 3:
            for k in (8, 4):
                f.rect(500 - 52 + k, y - 17 - k, 104, 34, stroke='--phosphor', fill='--panel')
        f.box(500, y, 104, 34, [b], stroke='--phosphor', size=10.5)
        f.text(655, y, up, size=10.5, fill='--amber' if i == 2 else '--paper')
        if i == 0:
            f.box(352, y, 110, 34, [T('a file', 'um arquivo')], stroke='--wire', size=10.5)
            f.arrow([(258, y), (295, y)], stroke='--phosphor', width=1.3)
            f.arrow([(408, y), (446, y)], stroke='--phosphor', width=1.3)
            f.text(352, y + 27, T('written 23:30, read 02:00', 'gravado 23:30, lido 02:00'),
                   size=9.5, fill='--paper-dim')
        elif i == 1:
            f.box(352, y, 110, 34, [T("Coleta's tables", 'tabelas do Coleta')], stroke='--wire',
                  size=10.5)
            f.arrow([(258, y), (295, y)], stroke='--phosphor', width=1.3)
            f.arrow([(446, y), (409, y)], stroke='--phosphor', width=1.3)
            f.text(352, y + 27, T('Rota reads them directly', 'o Rota as lê direto'),
                   size=9.5, fill='--paper-dim')
        elif i == 2:
            f.arrow([(258, y - 7), (446, y - 7)], stroke='--phosphor', width=1.3)
            f.arrow([(446, y + 7), (258, y + 7)], stroke='--paper-dim', width=1.3, dash='5 3')
            f.text(352, y - 17, T('request', 'requisição'), size=9.5)
            f.text(352, y + 19, T('the caller waits for the answer', 'quem chama espera a resposta'),
                   size=9.5, fill='--paper-dim')
        else:
            f.box(352, y, 110, 34, ['broker'], stroke='--wire', size=10.5)
            f.arrow([(258, y), (295, y)], stroke='--phosphor', width=1.3)
            f.arrow([(408, y), (446, y)], stroke='--phosphor', width=1.3)
            f.text(352, y + 27, T('the broker holds the message', 'o broker guarda a mensagem'),
                   size=9.5, fill='--paper-dim')
    return f, T('The four styles of Hohpe and Woolf, each with one of Serra Alta\'s integrations. '
                'Only the API needs both sides up at the same moment.',
                'Os quatro estilos de Hohpe e Woolf, cada um com uma integração da Serra Alta. Só a '
                'API precisa dos dois lados no ar no mesmo momento.')


@figure('l09-safe-file', 9)
def safe_file():
    f = Fig('l09-safe-file', 720, 300, T(
        'The safe file integration in order. On the writer\'s side, Coleta: 1, write the file under '
        'a temporary name, with a header and a trailer carrying the count and the litres; 2, rename '
        'it when it is complete. The file then reaches the reader\'s directory. On the reader\'s side, '
        'SAP: 3, check the header, the shape and the trailer\'s totals; 4, refuse a file whose day '
        'and sequence were already loaded; 5, load it; 6, send an acknowledgement or a reject file '
        'back to the writer, drawn as a dashed arrow. Beside the reader, an alarm goes off at 01:30 '
        'if no file has arrived for the day.',
        'A integração por arquivo segura, em ordem. No lado de quem grava, o Coleta: 1, gravar o '
        'arquivo com um nome temporário, com header e trailer trazendo a contagem e os litros; 2, '
        'renomear quando estiver completo. O arquivo então chega ao diretório de quem lê. No lado de '
        'quem lê, o SAP: 3, conferir o header, o formato e os totais do trailer; 4, recusar um '
        'arquivo cujo dia e sequência já foram carregados; 5, carregar; 6, mandar um arquivo de '
        'confirmação ou de rejeição de volta a quem gravou, desenhado como uma seta tracejada. Ao '
        'lado de quem lê, um alarme dispara às 01:30 se nenhum arquivo chegou no dia.'))
    f.rect(10, 20, 250, 260, stroke='--wire', fill='--ink')
    f.text(135, 40, T('writer: Coleta', 'quem grava: Coleta'), size=11, weight='600')
    f.rect(300, 20, 410, 260, stroke='--wire', fill='--ink')
    f.text(505, 40, T('reader: SAP', 'quem lê: SAP'), size=11, weight='600')
    w = [(T('1  write under a .tmp name,', '1  gravar com nome .tmp,'),
          T('with header and trailer', 'com header e trailer')),
         (T('2  rename when complete', '2  renomear quando completo'), None)]
    for i, (a, b) in enumerate(w):
        y = 85 + i * 62
        f.box(135, y, 220, 44, None, stroke='--phosphor')
        f.lines(135, y, [a] + ([b] if b else []), size=10.5)
    f.arrow([(135, 107), (135, 125)], stroke='--phosphor', width=1.3)
    r = [T('3  check shape and totals', '3  conferir formato e totais'),
         T('4  refuse a day already loaded', '4  recusar dia já carregado'),
         T('5  load', '5  carregar'),
         T('6  send ack or reject back', '6  devolver confirmação ou rejeição')]
    for i, s in enumerate(r):
        y = 75 + i * 52
        f.box(420, y, 210, 34, [s], stroke='--phosphor', size=10.5)
        if i:
            f.arrow([(420, y - 35), (420, y - 19)], stroke='--phosphor', width=1.3)
    f.arrow([(245, 147), (280, 147), (280, 75), (313, 75)], stroke='--phosphor', width=1.3)
    f.arrow([(315, 231), (135, 231), (135, 172)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.box(630, 128, 130, 60, None, stroke='--amber', dash='4 3')
    f.lines(630, 128, [T('no file by 01:30:', 'sem arquivo às 01:30:'),
                       T('the alarm goes off', 'o alarme dispara')], size=10.5)
    f.text(135, 248, T('the ack or the reject comes back', 'a confirmação ou rejeição volta'),
           size=9.5, fill='--paper-dim')
    return f, T('Six steps and an alarm. Each one exists because a file went wrong somewhere: '
                'half-written, short of a line, loaded twice, refused in silence, or never sent.',
                'Seis passos e um alarme. Cada um existe porque um arquivo deu errado em algum lugar: '
                'gravado pela metade, com uma linha a menos, carregado duas vezes, recusado em '
                'silêncio, ou nunca enviado.')


@figure('l09-timeouts', 9)
def timeouts():
    f = Fig('l09-timeouts', 720, 290, T(
        'A timeline of one checkout on 2 October 2026, from 0 to 60 seconds. The portal calls the ESB '
        'three times, each attempt timing out after 10 seconds, at 10, 20 and 30 seconds, and the '
        'bakery sees an error page at 30 seconds. The ESB, with a 60-second timeout, keeps each of '
        'its three calls to SAP open: the first from 0 to 35 seconds, the second from 10 to 42, the '
        'third from 20 to 55. Everything after the portal gave up on each attempt is shaded amber as '
        'work nobody is waiting for, and for most of the time SAP is working on three availability '
        'checks for one basket.',
        'Uma linha do tempo de um checkout em 2 de outubro de 2026, de 0 a 60 segundos. O portal '
        'chama o ESB três vezes, e cada tentativa estoura o timeout em 10 segundos, aos 10, 20 e 30 '
        'segundos, e a padaria vê uma página de erro aos 30 segundos. O ESB, com timeout de 60 '
        'segundos, mantém abertas suas três chamadas ao SAP: a primeira de 0 a 35 segundos, a segunda '
        'de 10 a 42, a terceira de 20 a 55. Tudo o que vem depois de o portal desistir de cada '
        'tentativa está em âmbar, como trabalho que ninguém está esperando, e na maior parte do tempo '
        'o SAP está fazendo três consultas de disponibilidade para uma cesta só.'))
    x0, k = 150, 8.0
    X = lambda s: x0 + s * k
    f.line(X(0), 228, X(60), 228, stroke='--paper-dim', width=1)
    for s in range(0, 61, 10):
        f.line(X(s), 228, X(s), 234, stroke='--paper-dim', width=1)
        f.text(X(s), 245, f'{s} s', size=9.5, fill='--paper-dim')
    f.text(14, 60, T('bakery', 'padaria'), size=11, anchor='start', weight='600')
    f.rect(X(0), 51, 30 * k, 18, stroke='--phosphor', fill='--panel')
    f.text(X(15), 60, T('waiting', 'esperando'), size=10)
    f.text(X(30) + 8, 60, T('error page', 'página de erro'), size=10, anchor='start', fill='--amber')
    f.text(14, 100, T('portal → ESB', 'portal → ESB'), size=11, anchor='start', weight='600')
    f.text(14, 114, T('timeout 10 s', 'timeout 10 s'), size=9.5, anchor='start', fill='--paper-dim')
    for n in range(3):
        f.rect(X(n * 10) + 1, 98, 10 * k - 2, 18, stroke='--phosphor', fill='--panel')
        f.text(X(n * 10 + 5), 107, T(f'try {n + 1}', f'tentativa {n + 1}'), size=9.5)
    f.text(14, 160, T('ESB → SAP', 'ESB → SAP'), size=11, anchor='start', weight='600')
    f.text(14, 174, T('timeout 60 s', 'timeout 60 s'), size=9.5, anchor='start', fill='--paper-dim')
    for n, (a, b) in enumerate([(0, 35), (10, 42), (20, 55)]):
        y = 140 + n * 22
        f.rect(X(a), y, 10 * k, 16, stroke='--phosphor', fill='--panel')
        f.rect(X(a + 10), y, (b - a - 10) * k, 16, stroke='--amber', fill='--ink', dash='3 2')
        f.text(X(b) + 6, y + 8, T(f'SAP answers at {b} s', f'SAP responde aos {b} s'), size=9.5,
               anchor='start', fill='--paper-dim')
    f.rect(X(0), 266, 22, 12, stroke='--amber', fill='--ink', dash='3 2')
    f.text(X(0) + 30, 272, T('work nobody is waiting for: the portal has already given up',
                             'trabalho que ninguém espera: o portal já desistiu'),
           size=10, anchor='start')
    return f, T('One checkout in the closing week. The portal gives up three times; the ESB never '
                'does, so SAP ends up checking the same basket three times over while it is slowest.',
                'Um checkout na semana de fechamento. O portal desiste três vezes; o ESB nunca, então o '
                'SAP acaba conferindo a mesma cesta três vezes justamente quando está mais lento.')


@figure('l09-fan-out', 9)
def fan_out():
    f = Fig('l09-fan-out', 720, 290, T(
        'Two panels. Left, by call: SAP\'s side sends each authorised invoice to Salesforce, the '
        'Portal B2B and the EDI provider, three arrows from one box, and a fourth receiver means a '
        'change on SAP\'s side. Right, by event: SAP publishes one message to the topic invoice '
        'authorised, and Salesforce, the Portal B2B and the EDI provider each subscribe to it; a '
        'fourth subscriber, Power BI, drawn dashed, is added later without SAP changing.',
        'Dois painéis. À esquerda, por chamada: o lado do SAP manda cada nota autorizada para o '
        'Salesforce, o Portal B2B e o provedor de EDI, três setas saindo de uma caixa, e um quarto '
        'destinatário significa uma mudança no lado do SAP. À direita, por evento: o SAP publica uma '
        'mensagem no tópico nota autorizada, e Salesforce, Portal B2B e o provedor de EDI assinam '
        'cada um; um quarto assinante, o Power BI, tracejado, entra depois sem o SAP mudar.'))
    f.text(175, 22, T('by call', 'por chamada'), size=12, weight='600')
    f.text(545, 22, T('by event', 'por evento'), size=12, weight='600')
    f.line(360, 14, 360, 280, stroke='--wire', width=0.8, dash='2 4')
    recv = ['Salesforce', 'Portal B2B', T('EDI provider', 'provedor de EDI')]
    f.box(70, 130, 100, 40, ['SAP'], stroke='--phosphor', size=11)
    for i, r in enumerate(recv):
        y = 70 + i * 60
        f.box(270, y, 120, 34, [r], stroke='--phosphor', size=10.5)
        f.arrow([(120, 130), (208, y)], stroke='--phosphor', width=1.3)
    f.lines(175, 255, [T('SAP\'s side knows all three;', 'o lado do SAP conhece os três;'),
                       T('a fourth is a change there', 'um quarto é uma mudança ali')],
            size=10, fill='--amber')
    f.box(410, 130, 80, 40, ['SAP'], stroke='--phosphor', size=11)
    f.box(530, 130, 110, 46, None, stroke='--wire')
    f.lines(530, 130, [T('topic', 'tópico'), T('invoice authorised', 'nota autorizada')], size=10)
    f.arrow([(450, 130), (473, 130)], stroke='--phosphor', width=1.3)
    for i, r in enumerate(recv + ['Power BI']):
        y = 55 + i * 50
        last = i == 3
        f.box(655, y, 104, 32, [r], stroke='--paper-dim' if last else '--phosphor', size=10,
              dash='4 3' if last else None)
        f.arrow([(586, 130), (601, y)], stroke='--paper-dim' if last else '--phosphor', width=1.3,
                dash='4 3' if last else None)
    f.lines(530, 255, [T('SAP publishes once;', 'o SAP publica uma vez;'),
                       T('a fourth is a subscription', 'um quarto é uma assinatura')],
            size=10, fill='--amber')
    return f, T('The same invoices, sent two ways. With calls, the sender knows every receiver; with '
                'an event, it knows only the topic, and Power BI joins without SAP changing.',
                'As mesmas notas, enviadas de dois jeitos. Com chamadas, quem envia conhece cada '
                'destinatário; com um evento, conhece só o tópico, e o Power BI entra sem o SAP mudar.')


@figure('l09-map-count', 9)
def map_count():
    f = Fig('l09-map-count', 720, 280, T(
        'Horizontal bars counting the 110 integrations on Joana\'s map by style. File transfer, 41, '
        '20 of them through the ESB, 14 with no known way to notice a failure. Shared database, 17, '
        'none through the ESB, 15 with no known way to notice a failure. API, 33, 31 through the '
        'ESB, 4 with no known way to notice a failure. Event or message, 19, all through the ESB, 5 '
        'with no known way to notice a failure. In all, 70 go through the ESB and 38 have no known '
        'way to notice a failure, drawn in amber at the start of each bar.',
        'Barras horizontais contando as 110 integrações do mapa da Joana por estilo. Transferência '
        'de arquivo, 41, 20 delas pelo ESB, 14 sem forma conhecida de notar uma falha. Banco '
        'compartilhado, 17, nenhuma pelo ESB, 15 sem forma conhecida de notar uma falha. API, 33, 31 '
        'pelo ESB, 4 sem forma conhecida de notar uma falha. Evento ou mensagem, 19, todas pelo ESB, '
        '5 sem forma conhecida de notar uma falha. No total, 70 passam pelo ESB e 38 não têm forma '
        'conhecida de notar uma falha, desenhadas em âmbar no início de cada barra.'))
    rows = [(T('file transfer', 'arquivo'), 41, 20, 14),
            (T('shared database', 'banco compartilhado'), 17, 0, 15),
            ('API', 33, 31, 4),
            (T('event', 'evento'), 19, 19, 5)]
    x0, k = 190, 10.0
    for i, (name, total, esb, blind) in enumerate(rows):
        y = 40 + i * 50
        f.text(14, y - 6, name, size=11, anchor='start', weight='600')
        f.text(14, y + 10, T(f'{esb} through the ESB', f'{esb} pelo ESB'), size=9.5, anchor='start',
               fill='--paper-dim')
        f.rect(x0, y - 11, total * k, 22, stroke='--phosphor', fill='--panel', rx=2)
        f.rect(x0, y - 11, blind * k, 22, stroke='--amber', fill='--ink', rx=2, dash='3 2')
        f.text(x0 + blind * k / 2, y, str(blind), size=10, fill='--amber')
        f.text(x0 + total * k + 10, y, str(total), size=11, anchor='start', weight='600')
    f.rect(x0, 236, 22, 12, stroke='--amber', fill='--ink', rx=2, dash='3 2')
    f.text(x0 + 30, 242, T('nobody could say how a failure would be noticed',
                           'ninguém sabia dizer como uma falha seria notada'), size=10, anchor='start')
    f.text(x0, 266, T('110 integrations in all; 70 through the ESB, 40 point to point',
                      '110 integrações no total; 70 pelo ESB, 40 ponto a ponto'),
           size=10, anchor='start', fill='--paper-dim')
    return f, T('Joana\'s map by style. The shared database is the smallest group and the worst '
                'watched: almost none of its links was ever designed as an integration.',
                'O mapa da Joana por estilo. O banco compartilhado é o menor grupo e o mais mal '
                'vigiado: quase nenhum desses vínculos foi desenhado como integração.')
