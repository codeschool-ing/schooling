"""Lesson 14: the tab order drawn over the booking page, before and after."""
from figures import Fig, T, figure


def page(f, x0, label, after):
    """One wireframe of the booking page, its left edge at x0; returns the stop positions."""
    f.text(x0 + 160, 24, label, size=11, weight='600', fill='--paper-dim')
    f.rect(x0, 38, 320, 340, stroke='--wire', fill='--panel', rx=6)
    stops = {}
    if after:
        f.rect(x0 + 14, 48, 170, 20, stroke='--phosphor', fill='--scan', dash='3 2')
        f.text(x0 + 99, 58, 'Skip to the booking form', size=9)
        stops['skip'] = (x0 + 190, 58)
    f.rect(x0 + 14, 76, 110, 26, stroke=None, fill='--scan', rx=4)
    f.text(x0 + 69, 89, 'boxoffice', size=10, weight='600', mono=True)
    for i, (w, name) in enumerate(((70, "What's on"), (52, 'Prices'), (56, 'Access'))):
        lx = x0 + 14 + sum((70, 52, 56)[:i]) + i * 14
        f.text(lx + w / 2, 118, name, size=9.5, fill='--phosphor')
        stops['nav%d' % i] = (lx + w / 2, 130)
    f.text(x0 + 14, 164, 'Book a seat', size=12, weight='600',
           anchor='start')
    for j, (name, y) in enumerate((('Show', 196), ('Seat', 238), ('Your name', 280))):
        f.text(x0 + 14, y - 10, name, size=9, anchor='start', fill='--paper-dim')
        f.rect(x0 + 14, y - 2, 180, 20, stroke='--paper-dim', fill='--scan')
        stops[('show', 'seat', 'name')[j]] = (x0 + 200, y + 8)
    f.rect(x0 + 14, 314, 70, 26, stroke='--amber' if not after else '--phosphor', fill='--scan',
           dash='4 3' if not after else None)
    f.text(x0 + 49, 327, 'Book', size=10, weight='600')
    stops['book'] = (x0 + 90, 327)
    return stops


def number(f, at, n, fill='--phosphor', dx=14):
    x, y = at
    f.circle(x + dx, y, 9, fill='--scan', stroke=fill, width=1.6)
    f.text(x + dx, y, str(n), size=10, weight='600', mono=True)


@figure('l14-tab-order', 14)
def tab_order():
    f = Fig('l14-tab-order', 720, 400, T(
        'The tab order drawn over two wireframes of the booking page. On the left, book2.html: '
        'stop 1 is the name field at the bottom of the form, because of tabindex 1; stops 2 to 4 '
        'are the three header links; 5 is Show and 6 is Seat; the Book div is never reached, and '
        'no stop shows a focus outline. On the right, book3.html: stop 1 is the skip link, 2 to 4 '
        'the links, 5 Show, 6 Seat, 7 the name field and 8 the Book button, in reading order, each '
        'with a visible outline.',
        'A ordem de tabulação desenhada sobre dois esboços da página de reserva. À esquerda, o '
        'book2.html: a parada 1 é o campo de nome no fim do formulário, por causa do tabindex 1; '
        'as paradas 2 a 4 são os três links do cabeçalho; 5 é Show e 6 é Seat; a div Book nunca é '
        'alcançada, e nenhuma parada mostra contorno de foco. À direita, o book3.html: a parada 1 '
        'é o link de pular, 2 a 4 os links, 5 Show, 6 Seat, 7 o campo de nome e 8 o botão Book, na '
        'ordem de leitura, cada uma com contorno visível.'))
    a = page(f, 16, 'book2.html', False)
    order = ['name', 'nav0', 'nav1', 'nav2', 'show', 'seat']
    for i, k in enumerate(order, 1):
        x, y = a[k]
        number(f, (x, y + 6) if k.startswith('nav') else (x, y),
               i, fill='--amber', dx=0 if k.startswith('nav') else 14)
    f.text(16 + 160, 362, T('Book: never reached', 'Book: nunca alcançado'), size=10,
           fill='--amber', weight='600')
    b = page(f, 384, 'book3.html', True)
    order = ['skip', 'nav0', 'nav1', 'nav2', 'show', 'seat', 'name', 'book']
    for i, k in enumerate(order, 1):
        x, y = b[k]
        number(f, (x, y + 6) if k.startswith('nav') else (x, y),
               i, dx=0 if k.startswith('nav') else 14)
    f.text(384 + 160, 362, T('eight stops, in reading order', 'oito paradas, na ordem de leitura'),
           size=10, fill='--phosphor', weight='600')
    return f, T('Where Tab goes, before and after the keyboard fixes. On the left the order starts '
                'at the bottom and never reaches Book.',
                'Para onde o Tab vai, antes e depois das correções de teclado. À esquerda a ordem '
                'começa embaixo e nunca chega ao Book.')
