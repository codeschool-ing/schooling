"""Lesson 15: where an accessible name comes from."""
from figures import Fig, T, figure


@figure('l15-name', 15)
def name():
    f = Fig('l15-name', 720, 330, T(
        'The order in which a browser looks for an element\'s accessible name, taking the first '
        'that gives something. First aria-labelledby, the text of the elements it points at. Then '
        'aria-label. Then the native source: a label for a field, alt for an image, the content of '
        'a button or link. Last, title, and placeholder for a field. On the booking page, the name '
        'field gets "Your name" from its label; the logo gets "boxoffice" from alt; the Book button gets "Book" from its content.',
        'A ordem em que o navegador procura o nome acessível de um elemento, ficando com a primeira '
        'fonte que dá algo. Primeiro aria-labelledby, o texto dos elementos para os quais aponta. '
        'Depois aria-label. Depois a fonte nativa: um label para um campo, o alt de uma imagem, o '
        'conteúdo de um botão ou link. Por último, title, e placeholder para um campo. Na página de '
        'reserva, o campo de nome recebe "Your name" do label; o '
        'logo recebe "boxoffice" do alt; o botão Book recebe "Book" do seu conteúdo.'))
    f.text(150, 22, T('looked for in this order', 'procurado nesta ordem'), size=11, weight='600',
           fill='--paper-dim')
    f.text(520, 22, T('on the booking page', 'na página de reserva'), size=11, weight='600',
           fill='--paper-dim')
    steps = [
        ('aria-labelledby', T('the text of the ids it names', 'o texto dos ids que cita'), None),
        ('aria-label', T('a string on the element', 'um texto no próprio elemento'), None),
        (T('native', 'nativo'), T('<label>, alt, a button\'s content', '<label>, alt, conteúdo do botão'),
         [('textbox "Your name"', T('from <label for>', 'do <label for>')),
          ('img "boxoffice"', T('from alt', 'do alt')),
          ('button "Book"', T('from its content', 'do conteúdo'))]),
        ('title, placeholder', T('last resorts, and weak ones', 'últimos recursos, e fracos'), None),
    ]
    for i, (head, sub, examples) in enumerate(steps):
        y = 44 + i * 66
        stroke = '--phosphor' if examples else '--wire'
        f.rect(40, y, 220, 50, stroke=stroke, fill='--scan' if examples else '--panel', width=1.4)
        f.text(56, y + 17, f'{i + 1}', size=11, weight='600', mono=True, anchor='start')
        f.text(76, y + 17, head, size=11, weight='600', anchor='start', mono=head != T('native', 'nativo'))
        f.text(76, y + 35, sub, size=9.5, anchor='start', fill='--paper-dim')
        if i < 3:
            f.arrow([(150, y + 52), (150, y + 64)], stroke='--paper-dim')
        if examples:
            for j, (ex, why) in enumerate(examples):
                ey = y - 46 + j * 48
                f.rect(360, ey, 320, 38, stroke='--wire', fill='--panel')
                f.text(376, ey + 13, ex, size=10, mono=True, anchor='start')
                f.text(376, ey + 28, why, size=9.5, anchor='start', fill='--paper-dim')
                f.arrow([(264, y + 25), (356, ey + 19)], stroke='--phosphor', width=1)
    f.text(360, 316, T('the first source that gives a name wins, and hides the rest',
                       'a primeira fonte que dá um nome vence, e esconde as outras'),
           size=10.5, fill='--amber')
    return f, T('How an accessible name is found. On the booking page every name comes from the native '
                'source, which is the one to reach for first.',
                'Como um nome acessível é encontrado. Na página de reserva todo nome vem da fonte '
                'nativa, que é a primeira a buscar.')
