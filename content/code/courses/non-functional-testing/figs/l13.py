"""Lesson 13: what the automated audits found on the booking page."""
from figures import Fig, T, figure


@figure('l13-who-finds', 13)
def who_finds():
    f = Fig('l13-who-finds', 720, 380, T(
        'The eight defects of book.html against three columns: axe with the WCAG tags, Lighthouse, '
        'and what was left for a person. axe found four: the missing lang, the grey note, the logo '
        'without alt and the name field without a label. Lighthouse found those four and the '
        'positive tabindex. Nothing reported the removed focus outline or the div used as a '
        'button, which lesson 14 tests with the keyboard, or the error shown only in red, which '
        'lesson 15 tests with a screen reader.',
        'Os oito defeitos do book.html contra três colunas: o axe com as tags da WCAG, o Lighthouse '
        'e o que sobrou para uma pessoa. O axe achou quatro: o lang ausente, a nota cinza, o logo '
        'sem alt e o campo de nome sem rótulo. O Lighthouse achou esses quatro e o tabindex '
        'positivo. Nada relatou o contorno de foco removido nem a div usada como botão, que a aula '
        '14 testa com o teclado, nem o erro mostrado só em vermelho, que a aula 15 testa com um '
        'leitor de tela.'))
    cols = [(430, T('axe, WCAG tags', 'axe, tags WCAG')), (540, 'Lighthouse'),
            (650, T('left for a person', 'sobrou para uma pessoa'))]
    for x, h in cols:
        f.text(x, 26, h, size=10.5, weight='600', fill='--paper-dim')
    rows = [
        ('1', T('no lang on <html>', 'sem lang no <html>'), 'yy'),
        ('2', T('grey note, 2.85:1', 'nota cinza, 2.85:1'), 'yy'),
        ('3', T('focus outline removed', 'contorno de foco removido'), T('lesson 14', 'aula 14')),
        ('4', T('logo without alt', 'logo sem alt'), 'yy'),
        ('5', T('name field without a label', 'campo de nome sem rótulo'), 'yy'),
        ('6', T('tabindex="1"', 'tabindex="1"'), 'ny'),
        ('7', T('Book is a <div>', 'Book é uma <div>'), T('lesson 14', 'aula 14')),
        ('8', T('error only in red', 'erro só em vermelho'), T('lesson 15', 'aula 15')),
    ]
    for i, (n, label, found) in enumerate(rows):
        y = 56 + i * 36
        f.rect(24, y - 14, 690, 28, stroke=None, fill='--panel', rx=3)
        f.text(48, y, n, size=11, weight='600', mono=True)
        f.text(70, y, label, size=10.5, anchor='start', mono=label.startswith('tabindex'))
        if found in ('yy', 'ny'):
            if found[0] == 'y':
                f.circle(430, y, 7, fill='--phosphor')
            else:
                f.circle(430, y, 7, fill=None, stroke='--wire', width=1.4)
            f.circle(540, y, 7, fill='--phosphor')
            f.circle(650, y, 7, fill=None, stroke='--wire', width=1.4)
        else:
            f.circle(430, y, 7, fill=None, stroke='--wire', width=1.4)
            f.circle(540, y, 7, fill=None, stroke='--wire', width=1.4)
            f.rect(600, y - 11, 100, 22, stroke='--amber', fill='--scan', width=1.4)
            f.text(650, y, found, size=10, fill='--amber', weight='600')
    f.text(360, 352, T('filled: reported · hollow: not reported',
                       'cheio: relatado · vazio: não relatado'), size=10, fill='--paper-dim')
    return f, T('Who found which defect. The three that stop a keyboard or a screen reader user '
                'booking a seat are the three no tool reported.',
                'Quem achou cada defeito. Os três que impedem quem usa teclado ou leitor de tela de '
                'reservar um assento são os três que nenhuma ferramenta relatou.')
