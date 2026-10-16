"""Lesson 7: MVC, MVP and MVVM."""
from figures import Fig, T, figure


@figure('l07-request', 7)
def request():
    f = Fig('l07-request', 720, 330, T(
        'A sequence diagram of one request to web.py, POST /loans, read from top to bottom. Five '
        'lifelines: the browser, app, the lend controller, the Desk model and the message_page '
        'view. The browser sends the request to app; app looks up the route and calls lend with '
        'the form; lend calls desk.lend, which returns a Loan; lend calls message_page with a '
        'sentence and gets HTML back; lend returns 200 OK and the HTML to app, and app sends the '
        'response to the browser. After that the page is in the browser, and a later change to the '
        'desk redraws nothing until the browser asks again.',
        'Um diagrama de sequência de uma requisição a web.py, POST /loans, lido de cima para baixo. '
        'Cinco linhas de vida: o navegador, app, o controlador lend, o modelo Desk e a view '
        'message_page. O navegador manda a requisição para app; app procura a rota e chama lend com '
        'o formulário; lend chama desk.lend, que devolve um Loan; lend chama message_page com uma '
        'frase e recebe HTML de volta; lend devolve 200 OK e o HTML para app, e app manda a resposta '
        'ao navegador. Depois disso a página está no navegador, e uma mudança posterior no desk não '
        'redesenha nada até o navegador pedir de novo.'))
    cols = [(70, T('browser', 'navegador'), False), (215, 'app', True), (360, 'lend', True),
            (505, 'Desk', True), (650, 'message_page', True)]
    roles = [T('client', 'cliente'), T('router', 'roteador'), T('controller', 'controlador'),
             T('model', 'modelo'), T('view', 'view')]
    for (x, name, mono), role in zip(cols, roles):
        f.box(x, 34, 116, 30, [name], mono=mono, stroke='--phosphor', size=10.5)
        f.text(x, 62, role, size=9.5, fill='--paper-dim', italic=True)
        f.line(x, 72, x, 300, stroke='--wire', width=1, dash='3 4')
    steps = [
        (0, 1, 'POST /loans', False),
        (1, 2, 'lend(form)', False),
        (2, 3, 'desk.lend(…)', False),
        (3, 2, 'Loan', True),
        (2, 4, 'message_page(…)', False),
        (4, 2, '<p>…</p>', True),
        (2, 1, '"200 OK", html', True),
        (1, 0, T('the page', 'a página'), True),
    ]
    y = 96
    for a, b, label, back in steps:
        xa, xb = cols[a][0], cols[b][0]
        d = 1 if xb > xa else -1
        f.arrow([(xa + 4 * d, y), (xb - 6 * d, y)], stroke='--paper-dim' if back else '--phosphor',
                width=1.3, dash='5 3' if back else None)
        f.text((xa + xb) / 2, y - 9, label, size=9.5, mono=label != T('the page', 'a página'))
        y += 26
    f.text(360, 318, T('the page is sent: a later change to the desk redraws nothing until the next request',
                       'a página foi enviada: uma mudança posterior no desk não redesenha nada até a próxima requisição'),
           size=10, fill='--amber', italic=True)
    return f, T('One request, top to bottom. The controller calls the model, hands plain values to a view, and the page leaves; nothing is watching afterwards.',
                'Uma requisição, de cima para baixo. O controlador chama o modelo, entrega valores simples a uma view, e a página sai; depois disso ninguém está observando.')


def _panel(f, x0, title, top, mid, bottom, arrows, note):
    """One of the three triads: boxes at fixed places in a 230-wide panel starting at x0."""
    f.text(x0 + 115, 20, title, size=12, weight='600')
    places = {}
    for key, (dx, dy, label, mono) in {**top, **mid, **bottom}.items():
        f.box(x0 + dx, dy, 104, 30, [label], mono=mono, stroke='--phosphor', size=10.5)
        places[key] = (x0 + dx, dy)
    for pts, label, lx, ly, dash in arrows:
        f.arrow([(x0 + px, py) for px, py in pts], stroke='--paper-dim', width=1.3, dash=dash)
        f.text(x0 + lx, ly, label, size=9.5, fill='--paper-dim', anchor='start')
    f.lines(x0 + 115, 268, note, size=10, fill='--amber', italic=True)


@figure('l07-triads', 7)
def triads():
    f = Fig('l07-triads', 720, 300, T(
        'Three panels, one per pattern, each showing which part holds a reference to which. MVC: '
        'the controller calls the model, the model notifies the view, and the view reads the '
        'model; the model points at nobody. MVP: the view forwards events to the presenter, the '
        'presenter calls the model and tells the view what to show; the view never sees the model. '
        'MVVM: the view binds to the view-model, the view-model calls the model and is notified by '
        'it; the view-model never sees the view.',
        'Três painéis, um por padrão, cada um mostrando que parte guarda referência a qual. MVC: o '
        'controlador chama o modelo, o modelo notifica a view, e a view lê o modelo; o modelo não '
        'aponta para ninguém. MVP: a view repassa eventos ao presenter, o presenter chama o modelo e '
        'diz à view o que mostrar; a view nunca vê o modelo. MVVM: a view se liga ao view-model, o '
        'view-model chama o modelo e é notificado por ele; o view-model nunca vê a view.'))
    _panel(f, 0, 'MVC',
           {'m': (115, 70, 'Model', True)}, {},
           {'v': (58, 200, 'View', True), 'c': (172, 200, 'Controller', True)},
           [([(172, 185), (140, 89)], T('calls', 'chama'), 160, 132, None),
            ([(88, 89), (40, 185)], T('notifies', 'notifica'), 8, 128, '5 3'),
            ([(80, 185), (112, 89)], T('reads', 'lê'), 102, 152, None)],
           [T('the model points at nobody', 'o modelo não aponta para ninguém')])
    f.line(240, 30, 240, 285, stroke='--wire', width=1, dash='4 4')
    _panel(f, 245, 'MVP',
           {'m': (115, 60, 'Model', True)}, {'p': (115, 130, 'Presenter', True)},
           {'v': (115, 200, 'View', True)},
           [([(115, 115), (115, 77)], T('calls', 'chama'), 122, 96, None),
            ([(100, 185), (100, 147)], T('events', 'eventos'), 40, 166, None),
            ([(130, 147), (130, 185)], 'show_…', 138, 166, None)],
           [T('the view never sees the model', 'a view nunca vê o modelo')])
    f.line(485, 30, 485, 285, stroke='--wire', width=1, dash='4 4')
    _panel(f, 490, 'MVVM',
           {'m': (115, 60, 'Model', True)}, {'p': (115, 130, 'ViewModel', True)},
           {'v': (115, 200, 'View', True)},
           [([(100, 115), (100, 77)], T('calls', 'chama'), 46, 96, None),
            ([(130, 77), (130, 115)], T('notifies', 'notifica'), 138, 96, '5 3'),
            ([(115, 185), (115, 147)], T('binds', 'liga-se'), 122, 166, '5 3')],
           [T('the view-model never sees the view', 'o view-model nunca vê a view')])
    return f, T('Who holds a reference to whom. In all three the model points at nobody; what moves is the line between the view and the rest.',
                'Quem guarda referência a quem. Nos três o modelo não aponta para ninguém; o que muda é a linha entre a view e o resto.')
