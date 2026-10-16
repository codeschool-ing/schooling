"""Lesson 20: four interpreters, four defences."""
from figures import Fig, T, figure


@figure('l20-boundaries', 20)
def boundaries():
    f = Fig('l20-boundaries', 720, 300, T(
        'Text a user sent, on the left, reaches four programs that interpret text, each in its own row. '
        'The database reads SQL, and the defence is a parameterised query. The browser reads HTML, and '
        'the defence is encoding by context, with a Content-Security-Policy behind it. The service '
        'reads a form as a decision, and the defence is a CSRF token with SameSite cookies. The '
        'filesystem reads a name and a type, and the defence is a size limit, a content check, a name '
        'the server makes and storage that is never served. Each row ends in the benign probe that '
        'tests it.',
        'O texto que um usuário mandou, à esquerda, chega a quatro programas que interpretam texto, um '
        'em cada linha. O banco lê SQL, e a defesa é a consulta parametrizada. O navegador lê HTML, e a '
        'defesa é a codificação por contexto, com uma Content-Security-Policy atrás. O serviço lê um '
        'formulário como uma decisão, e a defesa é um token CSRF com cookies SameSite. O sistema de '
        'arquivos lê um nome e um tipo, e a defesa é limite de tamanho, conferência do conteúdo, nome '
        'feito pelo servidor e armazenamento que nunca é servido. Cada linha termina no teste inofensivo '
        'que a confere.'))
    f.text(70, 28, T('user input', 'entrada do usuário'), size=11, weight='600', fill='--paper-dim')
    f.text(250, 28, T('interpreter', 'intérprete'), size=11, weight='600', fill='--paper-dim')
    f.text(450, 28, T('defence', 'defesa'), size=11, weight='600', fill='--paper-dim')
    f.text(635, 28, T('benign probe', 'teste inofensivo'), size=11, weight='600', fill='--paper-dim')
    f.rect(20, 50, 100, 230, stroke='--paper-dim', fill='--panel', width=1.3)
    f.lines(70, 165, [T('a search,', 'uma busca,'), T('a name,', 'um nome,'), T('a form,', 'um formulário,'), T('a file', 'um arquivo')], size=10)
    rows = [
        (T('database', 'banco'), 'SQL', [T('parameterised query', 'consulta parametrizada')], "'"),
        (T('browser', 'navegador'), 'HTML', [T('encode by context', 'codificar por contexto'), '+ CSP'], '<em>nft-probe</em>'),
        (T('the service', 'o serviço'), T('a decision', 'uma decisão'), [T('CSRF token', 'token CSRF'), '+ SameSite'], T('form, no token', 'form sem token')),
        (T('filesystem', 'arquivos'), T('name, type', 'nome, tipo'), [T('size, content,', 'tamanho, conteúdo,'), T('server-made name', 'nome do servidor')], T('CSV named .png', 'CSV com nome .png')),
    ]
    for i, (who, reads, defence, probe) in enumerate(rows):
        y = 75 + i * 58
        f.line(120, y, 182, y, stroke='--paper-dim', width=1.2, arrow=True)
        f.rect(185, y - 20, 130, 40, stroke='--wire', fill='--scan', width=1.1)
        f.lines(250, y, [who, reads], size=10)
        f.line(315, y, 372, y, stroke='--paper-dim', width=1.2, arrow=True)
        f.rect(375, y - 20, 150, 40, stroke='--phosphor', fill='--panel', width=1.4)
        f.lines(450, y, defence, size=10)
        f.line(525, y, 557, y, stroke='--amber', width=1.2, dash='4 3')
        f.text(562, y, probe, size=10, anchor='start', mono=(i < 2), fill='--amber')
    return f, T('One shape, four interpreters. Each defence sits where the text enters the program that would read it as instructions.',
                'Uma forma, quatro intérpretes. Cada defesa fica onde o texto entra no programa que o leria como instrução.')


@figure('l20-csrf', 20)
def csrf():
    f = Fig('l20-csrf', 720, 250, T(
        "Three actors left to right: another site, the customer's browser, and account.py. Along the top, "
        "the customer's own page carries the CSRF token in its form, and the cancellation with the token "
        "is accepted with 303. Along the bottom, another site makes the browser post the same form; the "
        "browser may attach the session cookie, but the other site cannot read the token, so the request "
        "arrives without it and is refused with 403.",
        'Três atores da esquerda para a direita: outro site, o navegador do cliente e o account.py. Em '
        'cima, a própria página do cliente leva o token CSRF no formulário, e o cancelamento com o token é '
        'aceito com 303. Embaixo, outro site faz o navegador enviar o mesmo formulário; o navegador pode '
        'anexar o cookie de sessão, mas o outro site não consegue ler o token, então a requisição chega '
        'sem ele e é recusada com 403.'))
    for x, label in ((90, T('another site', 'outro site')), (360, T('the browser', 'o navegador')), (630, 'account.py')):
        f.rect(x - 70, 20, 140, 34, stroke='--paper-dim', fill='--panel', width=1.3)
        f.text(x, 37, label, size=11, weight='600', mono=(x == 630))
        f.line(x, 54, x, 230, stroke='--wire', width=1, dash='3 4')
    f.arrow([(630, 90), (360, 90)], stroke='--paper-dim', width=1.3)
    f.text(495, 80, T('page with the token in its form', 'página com o token no formulário'), size=10)
    f.arrow([(360, 125), (630, 125)], stroke='--phosphor', width=1.5)
    f.text(495, 115, T('cookie + token', 'cookie + token'), size=10, fill='--phosphor')
    f.text(495, 140, '303', size=10.5, weight='600', mono=True, fill='--phosphor')
    f.arrow([(90, 175), (360, 175)], stroke='--amber', width=1.4, dash='6 4')
    f.text(225, 165, T('a form posted from elsewhere', 'um formulário vindo de fora'), size=10, fill='--amber')
    f.arrow([(360, 205), (630, 205)], stroke='--amber', width=1.4, dash='6 4')
    f.text(495, 195, T('cookie, no token', 'cookie, sem token'), size=10, fill='--amber')
    f.text(495, 222, '403 stale form', size=10.5, weight='600', mono=True, fill='--amber')
    return f, T('The cookie travels with any form the browser sends. The token travels only with the forms the service drew.',
                'O cookie vai com qualquer formulário que o navegador manda. O token vai só com os formulários que o serviço desenhou.')
