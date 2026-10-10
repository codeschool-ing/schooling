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


if __name__ == '__main__':
    inject()
