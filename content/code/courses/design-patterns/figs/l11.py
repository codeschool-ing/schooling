"""Lesson 11: Domain-Driven Design, the strategic half."""
from figures import Fig, T, figure


@figure('l11-three-books', 11)
def three_books():
    f = Fig('l11-three-books', 720, 300, T(
        'Three bounded contexts side by side, each a dashed boundary with its own class called '
        'Book. In acquisitions, Book has isbn, supplier, unit_cents and quantity, and the method '
        'total_cents. In the catalogue, Book has isbn, title, authors and subjects, and the method '
        'citation. In lending, Book has barcode, isbn, loan_days and on_loan_to, and the method '
        'lend. The three are joined only by the isbn field, which a line under the three boxes '
        'connects; one catalogue Book corresponds to many lending Books, one per copy.',
        'Três contextos delimitados lado a lado, cada um uma fronteira tracejada com a própria '
        'classe chamada Book. Em acquisitions, Book tem isbn, supplier, unit_cents e quantity, e o '
        'método total_cents. No catálogo, Book tem isbn, title, authors e subjects, e o método '
        'citation. Em lending, Book tem barcode, isbn, loan_days e on_loan_to, e o método lend. Os '
        'três se ligam só pelo campo isbn, que uma linha abaixo das três caixas conecta; um Book do '
        'catálogo corresponde a muitos Books de lending, um por exemplar.'))
    ctx = [
        (20, T('acquisitions', 'aquisições'), T('"a line on an order"', '"uma linha num pedido"'),
         ['isbn', 'supplier', 'unit_cents', 'quantity'], ['total_cents()']),
        (260, T('catalogue', 'catálogo'), T('"a work with an ISBN"', '"uma obra com ISBN"'),
         ['isbn', 'title', 'authors', 'subjects'], ['citation()']),
        (500, T('lending', 'empréstimo'), T('"the thing with a barcode"', '"a coisa com código de barras"'),
         ['barcode', 'isbn', 'loan_days', 'on_loan_to'], ['lend()']),
    ]
    for x, name, quote, flds, meths in ctx:
        f.rect(x, 14, 200, 222, stroke='--amber', fill='--ink', dash='5 4', rx=6)
        f.text(x + 100, 32, name, size=11, weight='600', fill='--amber')
        f.text(x + 100, 50, quote, size=9.5, fill='--paper-dim', italic=True)
        f.klass(x + 30, 66, 140, 'Book', flds, meths)
    # the isbn row is the first field in two boxes and the second in lending
    row = 9.5 * 1.45
    y0 = 66 + row + 8 + 4 + row / 2
    for x, idx in ((20, 0), (260, 0), (500, 1)):
        f.line(x + 100, 236, x + 100, 262, stroke='--phosphor', width=1.3)
    f.line(120, 262, 600, 262, stroke='--phosphor', width=1.3)
    f.text(360, 280, T('joined only by the ISBN, never by sharing the class',
                       'ligados só pelo ISBN, nunca por compartilhar a classe'), size=10, fill='--paper')
    f.text(660, 252, T('many per ISBN', 'muitos por ISBN'), size=9, fill='--paper-dim', italic=True)
    return f, T('One word, three models. Each context keeps the Book its own people mean, and the ISBN is the only thing they share.',
                'Uma palavra, três modelos. Cada contexto fica com o Book que a sua gente quer dizer, e o ISBN é a única coisa em comum.')


@figure('l11-context-map', 11)
def context_map():
    f = Fig('l11-context-map', 720, 330, T(
        'The library\'s context map. Five boxes: the national bibliographic service and the payment '
        'provider, both external, drawn dashed; and the library\'s own catalogue, lending and '
        'acquisitions. An arrow from the bibliographic service down to the catalogue passes through '
        'a small box labelled ACL, the anticorruption layer. An arrow from the catalogue to lending '
        'is labelled customer/supplier, with U at the catalogue end and D at the lending end. An '
        'arrow from the payment provider to lending is labelled conformist. Between the catalogue '
        'and acquisitions sits a small box labelled ISBN, the shared kernel, joined to both.',
        'O mapa de contextos da biblioteca. Cinco caixas: o serviço bibliográfico nacional e o '
        'provedor de pagamentos, ambos externos, desenhados tracejados; e o catálogo, o empréstimo e '
        'as aquisições da própria biblioteca. Uma seta do serviço bibliográfico até o catálogo passa '
        'por uma caixinha marcada ACL, a camada anticorrupção. Uma seta do catálogo para o '
        'empréstimo é marcada cliente/fornecedor, com U do lado do catálogo e D do lado do '
        'empréstimo. Uma seta do provedor de pagamentos para o empréstimo é marcada conformista. '
        'Entre o catálogo e as aquisições fica uma caixinha marcada ISBN, o núcleo compartilhado, '
        'ligada aos dois.'))
    # external, top row
    f.box(170, 40, 210, 40, [T('national bibliographic', 'serviço bibliográfico'), T('service', 'nacional')],
          size=9.5, dash='5 4', stroke='--paper-dim')
    f.box(560, 40, 190, 40, [T('payment provider', 'provedor de pagamentos')], size=9.5, dash='5 4',
          stroke='--paper-dim')
    f.text(360, 40, T('outside the library', 'fora da biblioteca'), size=9.5, fill='--paper-dim', italic=True)
    # own contexts
    f.box(170, 200, 170, 44, [T('catalogue', 'catálogo')], size=11, stroke='--phosphor')
    f.box(560, 200, 170, 44, [T('lending', 'empréstimo')], size=11, stroke='--amber')
    f.box(170, 300, 170, 36, [T('acquisitions', 'aquisições')], size=11, stroke='--phosphor')
    # ACL between service and catalogue
    f.line(170, 60, 170, 104, stroke='--paper-dim', width=1.3)
    f.box(170, 120, 60, 30, ['ACL'], size=10, stroke='--amber', mono=True)
    f.arrow([(170, 135), (170, 177)], stroke='--paper-dim', width=1.3)
    f.text(206, 120, T('anticorruption layer', 'camada anticorrupção'), size=9.5, anchor='start')
    # customer/supplier catalogue -> lending
    f.arrow([(255, 200), (474, 200)], stroke='--paper-dim', width=1.3)
    f.text(365, 190, T('customer/supplier', 'cliente/fornecedor'), size=10)
    f.text(266, 214, 'U', size=10, weight='700', fill='--amber', mono=True)
    f.text(462, 214, 'D', size=10, weight='700', fill='--amber', mono=True)
    # conformist provider -> lending
    f.arrow([(560, 60), (560, 177)], stroke='--paper-dim', width=1.3)
    f.text(570, 120, T('conformist', 'conformista'), size=10, anchor='start')
    f.text(548, 76, 'U', size=10, weight='700', fill='--amber', mono=True)
    f.text(548, 166, 'D', size=10, weight='700', fill='--amber', mono=True)
    # shared kernel
    f.line(170, 222, 170, 238, stroke='--paper-dim', width=1.3)
    f.box(170, 255, 64, 34, ['ISBN'], size=10, stroke='--phosphor', mono=True, dash='3 3')
    f.line(170, 272, 170, 282, stroke='--paper-dim', width=1.3)
    f.text(212, 255, T('shared kernel', 'núcleo compartilhado'), size=9.5, anchor='start')
    f.text(560, 290, T('U upstream, D downstream', 'U upstream, D downstream'), size=9.5,
           fill='--paper-dim', italic=True)
    return f, T('Every line has a name, and the name says who adapts when the other side changes.',
                'Toda linha tem nome, e o nome diz quem se adapta quando o outro lado muda.')
