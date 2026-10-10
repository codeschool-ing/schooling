#!/usr/bin/env python3
"""The diagrams of analytics-bi, drawn as code.

    python3 figures.py            rewrite every figure in every lesson

Each figure is a function returning (svg, caption) per language. In a lesson's
.md a figure is a ```schooling-figure fence whose svg carries
data-fig="NAME"; a line reading exactly FIG:NAME is where a new one goes.
Running this replaces either with the current drawing, in the .md and the
.pt.md alike, so a number changed here changes in both languages at once.

Every number drawn in a figure is one a lesson's capture printed; the
function that draws it says which block.
"""
import json, os, re, glob, html

HERE = os.path.dirname(os.path.abspath(__file__))
SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def esc(s):
    return html.escape(str(s), quote=True)


class Svg:
    def __init__(self, name, w, h, label):
        self.name, self.w, self.h, self.label = name, w, h, label
        self.parts = []
        self.marker = False

    def text(self, x, y, s, size=11, fill='var(--paper)', anchor='start', weight=None,
             mono=False, italic=False):
        attrs = (f'x="{x}" y="{y}" text-anchor="{anchor}" dominant-baseline="middle" '
                 f'font-family="{MONO if mono else SANS}" font-size="{size}" fill="{fill}"')
        if weight:
            attrs += f' font-weight="{weight}"'
        if italic:
            attrs += ' font-style="italic"'
        self.parts.append(f'<text {attrs}>{esc(s)}</text>')

    def rect(self, x, y, w, h, fill='var(--panel)', stroke='var(--wire)', sw=1.5, rx=3, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ''
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" '
                          f'fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}></rect>')

    def line(self, x1, y1, x2, y2, stroke='var(--wire)', sw=1.5, dash=None, arrow=False):
        d = f' stroke-dasharray="{dash}"' if dash else ''
        m = ''
        if arrow:
            self.marker = True
            m = f' marker-end="url(#{self.name}-ah)"'
        self.parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" '
                          f'stroke-width="{sw}"{d}{m}></line>')

    def path(self, d, stroke='var(--wire)', sw=1.5, fill='none', dash=None, arrow=False):
        da = f' stroke-dasharray="{dash}"' if dash else ''
        m = ''
        if arrow:
            self.marker = True
            m = f' marker-end="url(#{self.name}-ah)"'
        self.parts.append(f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{da}{m}></path>')

    def circle(self, cx, cy, r, fill='var(--phosphor)', stroke='none', sw=1.5):
        self.parts.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{stroke}" '
                          f'stroke-width="{sw}"></circle>')

    def render(self):
        defs = ''
        if self.marker:
            defs = (f'<defs><marker id="{self.name}-ah" viewBox="0 0 10 8" refX="9" refY="4" '
                    f'markerWidth="8" markerHeight="7" orient="auto-start-reverse">'
                    f'<path d="M0 0 L10 4 L0 8 z" fill="var(--paper-dim)"></path></marker></defs>')
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" data-fig="{self.name}" '
                f'aria-label="{esc(self.label)}">{defs}{"".join(self.parts)}</svg>')


FIGURES = {}


def figure(fn):
    FIGURES[fn.__name__.replace('_', '-')] = fn
    return fn


def fence(svg, caption, same=None):
    body = {'svg': svg, 'caption': caption}
    if same:
        body['same'] = same
    return '```schooling-figure\n' + json.dumps(body, ensure_ascii=False) + '\n```'


def inject():
    found = set()
    for md in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        lang = 'pt' if md.endswith('.pt.md') else 'en'
        text = open(md, encoding='utf-8').read()
        out = text

        def swap(name):
            if name not in FIGURES:
                raise SystemExit(f'{md}: no figure called {name}')
            found.add(name)
            r = FIGURES[name](lang)
            return fence(*r)

        out = re.sub(r'^FIG:([a-z0-9-]+)$', lambda m: swap(m.group(1)), out, flags=re.M)
        out = re.sub(r'^```schooling-figure\n(\{.*?data-fig=\\"([a-z0-9-]+)\\".*\})\n```$',
                     lambda m: swap(m.group(2)), out, flags=re.M)
        if out != text:
            open(md, 'w', encoding='utf-8').write(out)
    missing = set(FIGURES) - found
    if missing:
        print('drawn but used nowhere:', ', '.join(sorted(missing)))


def L(lang, en, pt):
    return pt if lang == 'pt' else en


# ---------------------------------------------------------------- lesson 1

@figure
def lab_ports(lang):
    """Lesson 1, your-lab: the computer, the virtual machine and the ports."""
    s = Svg('lab-ports', 720, 300, L(lang,
        'Two boxes. On the left, your computer, with a terminal and a web browser. On the right, '
        'the virtual machine Ubuntu runs in, holding PostgreSQL on port 5432, the SSH server on '
        'port 22, Metabase on port 3000 and Streamlit on port 8501. Three arrows cross from left '
        'to right: the terminal reaches SSH through forwarded port 2222, and the browser reaches '
        'Metabase through 3000 and Streamlit through 8501. PostgreSQL has no arrow from outside: '
        'only programs inside the machine talk to it.',
        'Duas caixas. À esquerda, o seu computador, com um terminal e um navegador. À direita, a '
        'máquina virtual onde roda o Ubuntu, com o PostgreSQL na porta 5432, o servidor SSH na '
        'porta 22, o Metabase na porta 3000 e o Streamlit na porta 8501. Três setas cruzam da '
        'esquerda para a direita: o terminal chega ao SSH pela porta encaminhada 2222, e o '
        'navegador chega ao Metabase pela 3000 e ao Streamlit pela 8501. O PostgreSQL não recebe '
        'seta de fora: só programas de dentro da máquina falam com ele.'))
    s.rect(20, 30, 230, 240, fill='var(--ink)', stroke='var(--wire)')
    s.text(135, 52, L(lang, 'your computer', 'o seu computador'), 12.5, weight='600', anchor='middle')
    s.rect(45, 80, 180, 54)
    s.text(135, 100, L(lang, 'terminal', 'terminal'), 11.5, anchor='middle', weight='600')
    s.text(135, 118, 'ssh -p 2222 ana@localhost', 9.5, anchor='middle', mono=True, fill='var(--paper-dim)')
    s.rect(45, 160, 180, 80)
    s.text(135, 180, L(lang, 'web browser', 'navegador'), 11.5, anchor='middle', weight='600')
    s.text(135, 200, 'localhost:3000', 9.5, anchor='middle', mono=True, fill='var(--paper-dim)')
    s.text(135, 218, 'localhost:8501', 9.5, anchor='middle', mono=True, fill='var(--paper-dim)')
    s.rect(410, 30, 290, 240, fill='var(--ink)', stroke='var(--phosphor)', dash='5 4')
    s.text(555, 52, L(lang, 'the virtual machine (Ubuntu)', 'a máquina virtual (Ubuntu)'), 12.5,
           weight='600', anchor='middle')
    boxes = [(80, L(lang, 'SSH server', 'servidor SSH'), ':22'),
             (130, 'Metabase', ':3000'), (180, 'Streamlit', ':8501'),
             (230, 'PostgreSQL', ':5432')]
    for y, name, port in boxes:
        s.rect(440, y - 18, 230, 36, stroke='var(--amber)' if name == 'PostgreSQL' else 'var(--wire)')
        s.text(455, y, name, 11, weight='600')
        s.text(655, y, port, 10.5, anchor='end', mono=True, fill='var(--paper-dim)')
    s.line(225, 107, 438, 80, arrow=True)
    s.text(330, 82, '2222 → 22', 10, anchor='middle', mono=True, fill='var(--paper-dim)')
    s.line(225, 200, 438, 130, arrow=True)
    s.text(318, 148, '3000', 10, anchor='middle', mono=True, fill='var(--paper-dim)')
    s.line(225, 218, 438, 180, arrow=True)
    s.text(330, 210, '8501', 10, anchor='middle', mono=True, fill='var(--paper-dim)')
    s.path('M672 130 L688 130 L688 230 L674 230', stroke='var(--paper-dim)', sw=1, dash='3 3', arrow=True)
    s.text(320, 262, L(lang, 'nothing outside reaches 5432', 'nada de fora chega à 5432'), 10.5,
           anchor='middle', fill='var(--amber)', italic=True)
    cap = L(lang,
            'Everything runs inside the virtual machine; the terminal and the browser stay on your '
            'computer and reach in through three forwarded ports.',
            'Tudo roda dentro da máquina virtual; o terminal e o navegador ficam no seu computador '
            'e entram por três portas encaminhadas.')
    same = ['Metabase', 'Streamlit', 'PostgreSQL', 'terminal'] if lang == 'pt' else None
    return s.render(), cap, same


@figure
def two_clouds(lang):
    """Lesson 1, correlation: block `corr`, the four group means."""
    pts = [('home', 0, 120.50, 4990), ('home', 5, 138.71, 317), ('home', 10, 113.65, 1111),
           ('office', 15, 639.51, 684)]
    s = Svg('two-clouds', 720, 330, L(lang,
        'Mean order value against the discount on the order. Three home-segment points sit low '
        'and flat: no discount, 120.50 reais; 5 percent, 138.71; 10 percent, 113.65. One office '
        'point sits far above them at 15 percent, 639.51 reais. A dashed line fitted through all '
        'four points climbs steeply, which is what a correlation of 0.271 over all orders sees. A '
        'line through the home points alone is flat, which is what a correlation of -0.005 '
        'inside the home segment sees.',
        'Valor médio do pedido contra o desconto do pedido. Três pontos do segmento home ficam '
        'baixos e na horizontal: sem desconto, 120,50 reais; 5 por cento, 138,71; 10 por cento, '
        '113,65. Um ponto office fica muito acima, em 15 por cento, 639,51 reais. Uma reta '
        'tracejada passando pelos quatro pontos sobe forte, que é o que uma correlação de 0,271 '
        'sobre todos os pedidos enxerga. Uma reta só pelos pontos home é plana, que é o que uma '
        'correlação de -0,005 dentro do segmento home enxerga.'))
    x0, x1, y0, y1 = 90, 660, 280, 40
    def X(d): return x0 + (x1 - x0) * d / 15
    def Y(v): return y0 - (y0 - y1) * v / 700
    s.line(x0, y0, x1, y0, stroke='var(--paper-dim)', sw=1)
    s.line(x0, y0, x0, y1, stroke='var(--paper-dim)', sw=1)
    for d in (0, 5, 10, 15):
        s.text(X(d), y0 + 16, f'{d}%', 10.5, anchor='middle', mono=True, fill='var(--paper-dim)')
    for v in (0, 200, 400, 600):
        s.text(x0 - 10, Y(v), f'R$ {v}', 10, anchor='end', mono=True, fill='var(--paper-dim)')
    s.text((x0 + x1) / 2, y0 + 38, L(lang, 'discount on the order', 'desconto do pedido'), 11,
           anchor='middle', fill='var(--paper-dim)')
    s.text(x0, 22, L(lang, 'mean order value', 'valor médio do pedido'), 11, fill='var(--paper-dim)')
    # the least-squares line over every order, regr_intercept 102.96 and
    # regr_slope 20.81 reais per point of discount (asked of order_totals
    # by hand; the lesson quotes only r): what corr() measures
    s.line(X(0), Y(102.96), X(15), Y(102.96 + 15 * 20.81), stroke='var(--amber)', sw=1.5, dash='6 4')
    s.text(X(14.4), Y(330), L(lang, 'all orders: r = 0.271', 'todos os pedidos: r = 0,271'), 11,
           anchor='end', fill='var(--amber)')
    s.line(X(0), Y(121), X(10), Y(121), stroke='var(--phosphor)', sw=1.5)
    s.text(X(5), Y(121) + 26, L(lang, 'home only: r = −0.005', 'só home: r = −0,005'), 11,
           anchor='middle', fill='var(--phosphor)')
    for seg, d, v, n in pts:
        s.circle(X(d), Y(v), 6, fill='var(--phosphor)' if seg == 'home' else 'var(--amber)')
        lab = f'{seg} · R$ {v:.2f}'
        if lang == 'pt':
            lab = lab.replace('.', ',')
        s.text(X(d) + (12 if d < 15 else -12), Y(v) - 14, lab, 10, mono=True,
               anchor='start' if d < 15 else 'end')
    cap = L(lang,
            'The correlation over all orders is the line between two groups, not a line inside '
            'either of them.',
            'A correlação sobre todos os pedidos é a reta entre dois grupos, não uma reta dentro '
            'de nenhum deles.')
    return s.render(), cap, None


# ---------------------------------------------------------------- lesson 2

def brl(v, lang, signed=False):
    t = f'{abs(v):,.2f}'
    if lang == 'pt':
        t = t.replace(',', '#').replace('.', ',').replace('#', '.')
    sign = ('−' if v < 0 else '') if signed else ''
    return f'{sign}R$ {t}'


@figure
def bridge(lang):
    """Lesson 2, reconciling: block `bridge`."""
    steps = [(L(lang, 'gross', 'bruto'), 329036.20, 'total'),
             (L(lang, 'discounts', 'descontos'), -23768.58, 'step'),
             (L(lang, 'refunds', 'estornos'), -11058.02, 'step'),
             (L(lang, 'test account', 'conta de teste'), 0.0, 'step'),
             (L(lang, 'net', 'líquido'), 294209.60, 'total')]
    s = Svg('bridge', 720, 300, L(lang,
        'A bridge from gross to net revenue for the first quarter of 2026, drawn as five columns. '
        'Gross revenue is a full column of 329,036.20 reais. Discounts hang from its top as a '
        'drop of 23,768.58. Refunds hang below that as a drop of 11,058.02. The test account is a '
        'drop of zero, drawn as a flat line. Net revenue is a full column of 294,209.60, whose top '
        'is level with the bottom of the last drop.',
        'Uma ponte da receita bruta à líquida no primeiro trimestre de 2026, desenhada em cinco '
        'colunas. A receita bruta é uma coluna inteira de 329.036,20 reais. Os descontos pendem do '
        'topo dela como uma queda de 23.768,58. Os estornos pendem logo abaixo como uma queda de '
        '11.058,02. A conta de teste é uma queda de zero, desenhada como uma linha. A receita '
        'líquida é uma coluna inteira de 294.209,60, cujo topo fica na altura do fim da última '
        'queda.'))
    # the axis starts at 250,000 so the steps are visible; said on the drawing
    base, top, y0, y1 = 250000, 340000, 250, 40
    def Y(v): return y0 - (y0 - y1) * (v - base) / (top - base)
    w, gap, x = 100, 30, 60
    level = 0
    for name, v, kind in steps:
        if kind == 'total':
            s.rect(x, Y(v), w, y0 - Y(v), fill='var(--panel)', stroke='var(--phosphor)')
            level = v
            s.text(x + w / 2, Y(v) - 12, brl(v, lang), 10.5, anchor='middle', mono=True)
        else:
            new = level + v
            if v == 0:
                s.line(x, Y(level), x + w, Y(level), stroke='var(--amber)', sw=2)
            else:
                s.rect(x, Y(level), w, Y(new) - Y(level), fill='var(--panel)', stroke='var(--amber)')
            s.text(x + w / 2, Y(new) + 14 if v else Y(level) + 14, brl(v, lang, signed=True), 10.5,
                   anchor='middle', mono=True, fill='var(--amber)')
            level = new
        s.text(x + w / 2, y0 + 18, name, 11, anchor='middle')
        x += w + gap
    s.line(50, y0, 690, y0, stroke='var(--paper-dim)', sw=1)
    s.text(50, y0 + 40, L(lang, 'the scale starts at R$ 250,000, not at zero',
                          'a escala começa em R$ 250.000, não em zero'), 10, fill='var(--paper-dim)',
           italic=True)
    cap = L(lang, 'Each drop is one difference between the two definitions, and they close: the last '
                  'drop ends exactly where net revenue begins.',
            'Cada queda é uma diferença entre as duas definições, e elas fecham: a última queda termina '
            'exatamente onde começa a receita líquida.')
    return s.render(), cap, None


# ---------------------------------------------------------------- lesson 3

@figure
def star(lang):
    """Lesson 3, star-schema: the views of semantic.sql and how they join."""
    s = Svg('star', 720, 330, L(lang,
        'Lantern\'s semantic layer as a star. Two fact tables sit in the middle: orders, one row '
        'per order, carrying gross, discount and net revenue; and order lines, one row per product '
        'in an order, carrying quantity and line value. Around them sit three dimensions: '
        'customers, joined to orders by customer id; the calendar, joined to orders by the order '
        'date; and products, joined to order lines by product id. Order lines join to orders by '
        'order id. Customers take their region from the small state-to-region table beside them.',
        'A camada semântica da Lantern como uma estrela. Duas tabelas de fato ficam no meio: '
        'orders, uma linha por pedido, com bruto, desconto e receita líquida; e order lines, uma '
        'linha por produto num pedido, com quantidade e valor da linha. Em volta ficam três '
        'dimensões: customers, ligada a orders pelo id do cliente; calendar, ligada a orders pela '
        'data do pedido; e products, ligada a order lines pelo id do produto. Order lines se liga a '
        'orders pelo id do pedido. Customers pega a região da pequena tabela de estado para região '
        'ao lado dela.'))
    def box(x, y, w, name, kind, cols, fact=False):
        h = 30 + 15 * len(cols)
        s.rect(x, y, w, h, stroke='var(--phosphor)' if fact else 'var(--wire)')
        s.text(x + 10, y + 15, name, 11.5, weight='600', mono=True)
        s.text(x + w - 10, y + 15, kind, 9.5, anchor='end', fill='var(--paper-dim)')
        for i, c in enumerate(cols):
            s.text(x + 10, y + 34 + 15 * i, c, 9.5, mono=True, fill='var(--paper-dim)')
        return h
    F, D = L(lang, 'fact', 'fato'), L(lang, 'dimension', 'dimensão')
    box(250, 110, 200, 'orders', F, ['order_id', 'customer_id', 'order_date', 'net_revenue'], True)
    box(250, 240, 200, 'order_lines', F, ['order_id', 'product_id', 'line_value'], True)
    box(20, 95, 170, 'customers', D, ['customer_id', 'state', 'region', 'segment'])
    box(250, 10, 200, 'calendar', D, ['day', 'month'])
    box(520, 240, 180, 'products', D, ['product_id', 'category'])
    box(20, 250, 170, 'state_region', L(lang, 'table', 'tabela'), ['state', 'region'])
    s.line(250, 160, 192, 160)
    s.text(221, 148, 'customer_id', 8, anchor='middle', mono=True, fill='var(--paper-dim)')
    s.line(350, 110, 350, 72)
    s.text(358, 92, L(lang, 'order_date = day', 'order_date = day'), 8.5, mono=True, fill='var(--paper-dim)')
    s.line(350, 200, 350, 240)
    s.text(358, 221, 'order_id', 8.5, mono=True, fill='var(--paper-dim)')
    s.line(450, 280, 518, 280)
    s.text(484, 270, 'product_id', 8.5, anchor='middle', mono=True, fill='var(--paper-dim)')
    s.line(105, 200, 105, 250, dash='4 3')
    s.text(113, 226, 'state', 8.5, mono=True, fill='var(--paper-dim)')
    cap = L(lang, 'Every question is a join from a fact to the dimensions it needs, and the join to a '
                  'dimension never adds rows.',
            'Toda pergunta é um join de um fato com as dimensões de que precisa, e o join com uma '
            'dimensão nunca acrescenta linhas.')
    same = ['dimension', 'fact'] if False else None
    return s.render(), cap, None


# ---------------------------------------------------------------- lesson 4

@figure
def pbi_model(lang):
    """Lesson 4, the-model: the relationships, their cardinality and direction."""
    s = Svg('pbi-model', 720, 300, L(lang,
        'The model as Power BI draws it: five tables joined by four relationships. Customers and '
        'calendar each join orders; orders joins order lines; products joins order lines. Every '
        'relationship is many to one, with the one side at the dimension or at orders. An arrow on '
        'each line shows the single filter direction, from the one side to the many side: from '
        'customers and calendar into orders, from orders into order lines, from products into '
        'order lines. No arrow goes from order lines back to orders.',
        'O modelo como o Power BI o desenha: cinco tabelas ligadas por quatro relacionamentos. '
        'Customers e calendar se ligam a orders; orders se liga a order lines; products se liga a '
        'order lines. Todo relacionamento é muitos para um, com o lado um na dimensão ou em orders. '
        'Uma seta em cada linha mostra a direção única do filtro, do lado um para o lado muitos: de '
        'customers e calendar para orders, de orders para order lines, de products para order '
        'lines. Nenhuma seta volta de order lines para orders.'))
    def box(x, y, name, fact=False):
        s.rect(x, y, 140, 44, stroke='var(--phosphor)' if fact else 'var(--wire)')
        s.text(x + 70, y + 22, name, 11.5, anchor='middle', mono=True, weight='600')
    box(20, 40, 'customers'); box(20, 200, 'calendar')
    box(290, 120, 'orders', True)
    box(560, 40, 'order_lines', True); box(560, 210, 'products')
    def rel(x1, y1, x2, y2, one_at_start=True):
        s.line(x1, y1, x2, y2, arrow=True)
        s.text(x1 + (8 if x2 > x1 else -8), y1 - 8, '1', 11, anchor='middle', mono=True, fill='var(--amber)')
        s.text(x2 + (-12 if x2 > x1 else 12), y2 - 10, '*', 13, anchor='middle', mono=True, fill='var(--amber)')
    rel(160, 70, 288, 132)
    rel(160, 214, 288, 154)
    rel(430, 132, 558, 70)
    s.line(630, 210, 630, 86, arrow=True)
    s.text(642, 196, '1', 11, mono=True, fill='var(--amber)')
    s.text(642, 100, '*', 13, mono=True, fill='var(--amber)')
    s.text(360, 270, L(lang, 'a filter travels the way the arrows point, and no further',
                       'um filtro anda para onde as setas apontam, e não além'), 10.5, anchor='middle',
           italic=True, fill='var(--paper-dim)')
    cap = L(lang, 'Many to one, single direction: a slicer on products reaches order lines and stops '
                  'there.',
            'Muitos para um, direção única: um filtro em products chega a order lines e para ali.')
    return s.render(), cap, None


# ---------------------------------------------------------------- lesson 5

@figure
def four_shapes(lang):
    """Lesson 5, four-shapes: the tools on two axes. A placement, not a measurement."""
    s = Svg('four-shapes', 720, 330, L(lang,
        'The BI tools placed on two axes. Across: who builds, from anybody clicking through menus '
        'on the left to a programmer writing code on the right. Up: where definitions live, from '
        'in each piece of work at the bottom to in one central model at the top. Metabase sits to '
        'the left and in the middle. Tableau sits to the left and low. Power BI sits left of centre '
        'and a little higher than Tableau. Looker sits in the middle and at the top. Streamlit sits '
        'to the right and low. The two this course runs, Metabase and Streamlit, are highlighted.',
        'As ferramentas de BI em dois eixos. Na horizontal: quem constrói, de qualquer pessoa clicando '
        'em menus, à esquerda, a um programador escrevendo código, à direita. Na vertical: onde as '
        'definições moram, de em cada trabalho, embaixo, a num modelo central, em cima. O Metabase fica '
        'à esquerda e no meio. O Tableau fica à esquerda e embaixo. O Power BI fica à esquerda do centro '
        'e um pouco acima do Tableau. O Looker fica no meio e em cima. O Streamlit fica à direita e '
        'embaixo. As duas que este curso roda, Metabase e Streamlit, estão destacadas.'))
    x0, x1, y0, y1 = 110, 690, 270, 40
    s.line(x0, y0, x1, y0, stroke='var(--paper-dim)', sw=1, arrow=True)
    s.line(x0, y0, x0, y1, stroke='var(--paper-dim)', sw=1, arrow=True)
    s.text(x0, y0 + 18, L(lang, 'anybody, clicking', 'qualquer pessoa, clicando'), 10.5, fill='var(--paper-dim)')
    s.text(x1, y0 + 18, L(lang, 'a programmer, in code', 'um programador, em código'), 10.5, anchor='end', fill='var(--paper-dim)')
    s.text((x0 + x1) / 2, y0 + 40, L(lang, 'who builds', 'quem constrói'), 11, anchor='middle', weight='600')
    s.text(x0 - 10, y0 - 6, L(lang, 'in each piece', 'em cada'), 10.5, anchor='end', fill='var(--paper-dim)')
    s.text(x0 - 10, y0 + 8, L(lang, 'of work', 'trabalho'), 10.5, anchor='end', fill='var(--paper-dim)')
    s.text(x0 - 10, y1 + 6, L(lang, 'in one central', 'num modelo'), 10.5, anchor='end', fill='var(--paper-dim)')
    s.text(x0 - 10, y1 + 20, L(lang, 'model', 'central'), 10.5, anchor='end', fill='var(--paper-dim)')
    s.text(x0 + 10, 26, L(lang, 'where definitions live', 'onde as definições moram'), 11, weight='600')
    def tool(x, y, name, ours):
        s.rect(x - 52, y - 15, 104, 30, stroke='var(--phosphor)' if ours else 'var(--wire)')
        s.text(x, y, name, 11.5, anchor='middle', weight='600')
    tool(200, 150, 'Metabase', True)
    tool(230, 235, 'Tableau', False)
    tool(330, 195, 'Power BI', False)
    tool(430, 70, 'Looker', False)
    tool(600, 235, 'Streamlit', True)
    cap = L(lang, 'A placement to argue with, not a measurement: each tool can be pushed along both axes '
                  'by how a team uses it.',
            'Uma posição para discutir, não uma medida: cada ferramenta pode ser empurrada nos dois eixos '
            'pelo jeito como um time a usa.')
    same = ['Metabase', 'Tableau', 'Power BI', 'Looker', 'Streamlit'] if lang == 'pt' else None
    return s.render(), cap, same


if __name__ == '__main__':
    inject()
