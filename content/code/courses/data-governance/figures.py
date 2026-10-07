#!/usr/bin/env python3
"""Every diagram in the data-governance course, in both languages.

    python3 figures.py            # rewrite every figure in the lessons
    python3 figures.py --list     # the names, and the lesson each lives in

A figure lives in a lesson's prose as an ordinary `schooling-figure` fence. Its
SVG carries `data-fig="<name>"`, which is how this file finds it again: running
it replaces each fence, in both languages, with what the code below draws now.
A placeholder line `@@fig:<name>@@` is replaced the same way, which is how a
figure enters a section the first time.

Each drawing is written once, with every label a pair (English, Portuguese),
so the two languages cannot disagree about anything but words. A label that is
the same in both and drawn in the prose face goes into the translated figure's
`same` list on its own: the pair says somebody decided.

Only palette tokens are used — `--paper`, `--paper-dim`, `--wire`, `--phosphor`,
`--phosphor-dim`, `--amber`, `--panel`, `--ink`, `--scan` — so each drawing turns
over with the theme like the page around it. Text is never drawn in `--wire` or
`--phosphor-dim`. Standard library only.
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def esc(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            .replace('"', '&quot;'))


class Fig:
    """One drawing, rendered in one language. `t(pair)` picks the language."""

    def __init__(self, name, lang, w, h, label):
        self.name, self.lang, self.w, self.h = name, lang, w, h
        self.label = self.t(label)
        self.parts = []
        self.markers = set()
        self.sans = []  # labels drawn in the prose face, for `same`

    def t(self, s):
        if isinstance(s, (tuple, list)):
            return s[0] if self.lang == 'en' else s[1]
        return s

    def text(self, x, y, s, size=11, anchor='middle', fill='--paper', weight=None, mono=False):
        s = self.t(s)
        if not mono:
            self.sans.append(s)
        w = f' font-weight="{weight}"' if weight else ''
        if mono and '  ' in s:
            w += ' xml:space="preserve"'
        self.parts.append(
            f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" dominant-baseline="middle" '
            f'font-family="{MONO if mono else SANS}" font-size="{size}"{w} '
            f'fill="var({fill})">{esc(s)}</text>')

    def lines(self, x, y, items, size=11, gap=None, **kw):
        """Several lines centred on y. Each item is a label or (label, kw)."""
        items = [self.t(i) if not isinstance(i, dict) else i for i in items]
        gap = gap or size * 1.45
        y0 = y - gap * (len(items) - 1) / 2
        for k, it in enumerate(items):
            if isinstance(it, dict):
                o = dict(kw)
                o.update({a: b for a, b in it.items() if a != 's'})
                self.text(x, y0 + k * gap, it['s'], size=o.pop('size', size), **o)
            else:
                self.text(x, y0 + k * gap, it, size=size, **kw)

    def rect(self, x, y, w, h, stroke='--wire', fill='--panel', width=1.4, rx=4, dash=None):
        extra = f' stroke-dasharray="{dash}"' if dash else ''
        self.parts.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" '
            f'fill="var({fill})" stroke="var({stroke})" stroke-width="{width}"{extra}></rect>')

    def box(self, x, y, w, h, items, stroke='--wire', fill='--panel', size=11, dash=None,
            **kw):
        self.rect(x, y, w, h, stroke=stroke, fill=fill, dash=dash)
        if isinstance(items, (str, tuple, dict)):
            items = [items]
        self.lines(x + w / 2, y + h / 2, items, size=size, **kw)

    def path(self, d, stroke='--paper-dim', width=1.4, fill='none', dash=None, arrow=False):
        extra = f' stroke-dasharray="{dash}"' if dash else ''
        if arrow:
            mid = f'dg-ah{stroke.replace("--", "-")}'
            self.markers.add((mid, stroke))
            extra += f' marker-end="url(#{mid})"'
        fv = fill if fill == 'none' else f'var({fill})'
        self.parts.append(f'<path d="{d}" stroke="var({stroke})" stroke-width="{width}" '
                          f'fill="{fv}"{extra}></path>')

    def arrow(self, x1, y1, x2, y2, stroke='--paper-dim', **kw):
        self.path(f'M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}', stroke=stroke, arrow=True, **kw)

    def line(self, x1, y1, x2, y2, **kw):
        self.path(f'M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}', **kw)

    def circle(self, x, y, r, fill='--phosphor', stroke=None, width=1.4):
        st = f' stroke="var({stroke})" stroke-width="{width}"' if stroke else ''
        fv = 'none' if fill is None else f'var({fill})'
        self.parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{fv}"{st}></circle>')

    def svg(self):
        defs = ''
        if self.markers:
            defs = '<defs>' + ''.join(
                f'<marker id="{m}" viewBox="0 0 10 8" refX="9" refY="4" markerWidth="8" '
                f'markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 4 L0 8 z" '
                f'fill="var({c})"></path></marker>' for m, c in sorted(self.markers)) + '</defs>'
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" data-fig="{self.name}" '
                f'aria-label="{esc(self.label)}">{defs}{"".join(self.parts)}</svg>')


FIGURES = {}


def figure(name, lesson, w, h, label, caption):
    def wrap(draw):
        FIGURES[name] = (lesson, w, h, label, caption, draw)
        return draw
    return wrap


def render(name, lang):
    lesson, w, h, label, caption, draw = FIGURES[name]
    f = Fig(name, lang, w, h, label)
    draw(f)
    block = {'svg': f.svg(), 'caption': f.t(caption)}
    if lang == 'pt':
        en = Fig(name, 'en', w, h, label)
        draw(en)
        same = sorted({s for s, e in zip(f.sans, en.sans) if s == e and re.search(r'[A-Za-z]', s)})
        if same:
            block['same'] = same
    return '```schooling-figure\n' + json.dumps(block, ensure_ascii=False) + '\n```'


# ===================================================================== lesson 1
L1 = 'le-86zhcbmy'


@figure('l1-two-gates', L1, 720, 230,
        ('A connection to PostgreSQL passes two gates. The first, pg_hba.conf with the '
         'authentication method, decides who you are and whether you may connect at all. '
         'The second, the privileges inside the database, decides what that role may do '
         'with each object.',
         'Uma conexão ao PostgreSQL passa por dois portões. O primeiro, o pg_hba.conf com '
         'o método de autenticação, decide quem você é e se pode conectar. O segundo, os '
         'privilégios dentro do banco, decide o que esse papel pode fazer com cada objeto.'),
        ('Authentication is answered once, at the door; authorisation is asked again on '
         'every statement.',
         'A autenticação é respondida uma vez, na porta; a autorização é perguntada de '
         'novo a cada comando.'))
def _l1_two_gates(f):
    f.box(20, 80, 120, 70, [('a client', 'um cliente'), {'s': 'psql -U bruno', 'mono': True,
                                                         'size': 10, 'fill': '--paper-dim'}])
    f.rect(180, 30, 220, 170, stroke='--amber', fill='--panel')
    f.text(290, 52, ('1 · authentication', '1 · autenticação'), size=12.5, weight='600')
    f.text(290, 74, ('who are you?', 'quem é você?'), size=11, fill='--paper-dim')
    f.box(200, 96, 180, 36, {'s': 'pg_hba.conf', 'mono': True}, fill='--ink', size=11)
    f.box(200, 146, 180, 36, ('peer · scram · cert', 'peer · scram · cert'), fill='--ink',
          size=11)
    f.rect(440, 30, 260, 170, stroke='--phosphor', fill='--panel')
    f.text(570, 52, ('2 · authorisation', '2 · autorização'), size=12.5, weight='600')
    f.text(570, 74, ('what may this role do?', 'o que esse papel pode fazer?'), size=11,
           fill='--paper-dim')
    f.box(460, 96, 220, 36, {'s': 'CONNECT · USAGE · SELECT', 'mono': True}, fill='--ink',
          size=10.5)
    f.box(460, 146, 220, 36, ('asked on every statement', 'perguntada a cada comando'),
          fill='--ink', size=11)
    f.arrow(140, 115, 178, 115)
    f.arrow(400, 115, 438, 115)


@figure('l1-hba-first-match', L1, 720, 250,
        ('pg_hba.conf is read from the top, and the first line whose type, database, user '
         'and address all match decides. A connection from bruno over TCP skips the two '
         'local lines and stops at line 4, scram-sha-256. Line 5 is never reached by him.',
         'O pg_hba.conf é lido de cima para baixo, e a primeira linha cujo tipo, banco, '
         'usuário e endereço batem decide. Uma conexão do bruno por TCP pula as duas '
         'linhas local e para na linha 4, scram-sha-256. Ele nunca chega à linha 5.'),
        ('First match wins, and nothing below it is read. An order mistake is a security '
         'mistake.',
         'Vale a primeira que bate, e nada abaixo dela é lido. Um erro de ordem é um erro '
         'de segurança.'))
def _l1_hba(f):
    rows = [('2', 'local   all  postgres          peer', False),
            ('3', 'local   ipe  ana               peer', False),
            ('4', 'host    ipe  all  127.0.0.1/32 scram-sha-256', True),
            ('5', 'host    all  all  all          reject', None)]
    f.box(20, 95, 150, 60, [('bruno, over TCP', 'bruno, por TCP'),
                            {'s': 'db.ipe.example', 'mono': True, 'size': 10,
                             'fill': '--paper-dim'}])
    for i, (n, line, hit) in enumerate(rows):
        y = 30 + i * 50
        stroke = '--phosphor' if hit else '--wire'
        dash = '4 3' if hit is None else None
        f.rect(220, y, 470, 36, stroke=stroke, fill='--ink', dash=dash)
        f.text(238, y + 18, n, size=11, fill='--paper-dim', mono=True)
        f.text(258, y + 18, line, size=11, anchor='start', mono=True,
               fill='--paper' if hit is not None else '--paper-dim')
    f.arrow(170, 125, 218, 148, stroke='--phosphor')
    f.text(455, 232, ('lines 2 and 3 do not match: wrong type. Line 4 does, and decides.',
                      'linhas 2 e 3 não batem: tipo errado. A linha 4 bate, e decide.'),
           size=11, fill='--paper-dim')


# ===================================================================== lesson 2
L2 = 'le-d6047rxz'


@figure('l2-rbac', L2, 720, 300,
        ('Role-based access control in Ipê\'s database. On the left, the logins: bruno, carla, '
         'site_app and etl_loader. In the middle, the jobs they are members of: analyst, '
         'support_agent, app_web and pipeline. On the right, what each job may do. Privileges '
         'are granted to the jobs only; no arrow goes from a person to a table.',
         'Controle de acesso baseado em papéis no banco da Ipê. À esquerda, os logins: bruno, '
         'carla, site_app e etl_loader. No meio, os cargos de que são membros: analyst, '
         'support_agent, app_web e pipeline. À direita, o que cada cargo pode fazer. Os '
         'privilégios são concedidos só aos cargos; nenhuma seta vai de uma pessoa a uma tabela.'),
        ('People are members of jobs; jobs hold privileges. A new analyst is one membership, '
         'not forty grants.',
         'Pessoas são membros de cargos; cargos têm privilégios. Um analista novo é uma '
         'associação, não quarenta concessões.'))
def _l2_rbac(f):
    f.text(80, 22, ('logins', 'logins'), size=12, weight='600')
    f.text(300, 22, ('jobs', 'cargos'), size=12, weight='600')
    f.text(560, 22, ('privileges', 'privilégios'), size=12, weight='600')
    rows = [('bruno', 'analyst', ['SELECT orders, items, products', 'SELECT 6 columns of customers']),
            ('carla', 'support_agent', ['SELECT customers, orders', 'UPDATE (status) tickets']),
            ('site_app', 'app_web', ['SELECT products', 'INSERT orders, items, payments']),
            ('etl_loader', 'pipeline', ['SELECT customers, orders, items,', 'payments, products'])]
    for i, (who, job, privs) in enumerate(rows):
        y = 44 + i * 64
        f.box(20, y, 120, 44, {'s': who, 'mono': True}, fill='--ink')
        f.box(225, y, 150, 44, {'s': job, 'mono': True}, stroke='--phosphor', fill='--panel')
        f.rect(440, y - 4, 260, 52, stroke='--wire', fill='--ink')
        items = [{'s': p, 'mono': True, 'size': 10} for p in privs if p]
        f.lines(570, y + 22, items, size=10, gap=17)
        f.arrow(140, y + 22, 223, y + 22)
        f.arrow(375, y + 22, 438, y + 22, stroke='--phosphor')


@figure('l2-row-and-column', L2, 720, 290,
        ('The customers table drawn as a grid of rows by state and columns. Bruno, an analyst, '
         'sees every row but only six columns: id, sex, city, state, created_at and '
         'marketing_opt_in. Carla, a support agent, sees every column but only the rows from '
         'São Paulo and Rio de Janeiro. Column privileges cut the table one way and row '
         'security the other.',
         'A tabela de clientes desenhada como uma grade de linhas por estado e colunas. Bruno, '
         'analista, vê todas as linhas mas só seis colunas: id, sexo, cidade, estado, '
         'created_at e marketing_opt_in. Carla, atendente, vê todas as colunas mas só as linhas '
         'de São Paulo e do Rio de Janeiro. Privilégio de coluna corta a tabela num sentido, e '
         'segurança de linha no outro.'),
        ('Two cuts through one table: a grant on columns, and a policy on rows.',
         'Dois cortes numa tabela: uma permissão em colunas, e uma política em linhas.'))
def _l2_grid(f):
    cols = ['id', 'name', 'email', 'cpf', 'birth', 'sex', 'city', 'state', 'since', 'opt']
    analyst = {'id', 'sex', 'city', 'state', 'since', 'opt'}
    states = ['SP', 'RJ', 'MG', 'PR', 'RS']
    for panel, (x0, title, colok, rowok) in enumerate([
            (20, ('bruno · analyst', 'bruno · analyst'), lambda c: c in analyst, lambda s: True),
            (375, ('carla · support_agent', 'carla · support_agent'), lambda c: True,
             lambda s: s in ('SP', 'RJ'))]):
        f.text(x0 + 162, 22, title, size=12, weight='600', mono=True)
        cw, rh = 33, 34
        for j, c in enumerate(cols):
            f.text(x0 + 2 + j * cw + cw / 2, 46, c, size=9, mono=True, fill='--paper-dim')
        for i, st in enumerate(states):
            y = 58 + i * rh
            for j, c in enumerate(cols):
                ok = colok(c) and rowok(st)
                f.rect(x0 + 2 + j * cw + 2, y + 2, cw - 4, rh - 4,
                       stroke='--phosphor' if ok else '--wire',
                       fill='--panel' if ok else '--ink', width=1.2, rx=2,
                       dash=None if ok else '3 3')
                if c == 'state':
                    f.text(x0 + 2 + j * cw + cw / 2, y + rh / 2, st, size=9.5, mono=True,
                           fill='--paper' if ok else '--paper-dim')
    f.text(182, 245, ('column privileges: every row,', 'privilégio de coluna: toda linha,'),
           size=11, fill='--paper-dim')
    f.text(182, 263, ('six columns', 'seis colunas'), size=11, fill='--paper-dim')
    f.text(537, 245, ('row security: every column,', 'segurança de linha: toda coluna,'),
           size=11, fill='--paper-dim')
    f.text(537, 263, ('two states', 'dois estados'), size=11, fill='--paper-dim')


# ===================================================================== driver

def main():
    if '--list' in sys.argv:
        for n, v in FIGURES.items():
            print(n, v[0])
        return
    seen = set()
    for path in sorted(glob.glob(os.path.join(HERE, 'lessons', '*', '*.md'))):
        lang = 'pt' if path.endswith('.pt.md') else 'en'
        src = open(path).read()
        out = src

        def ph(m):
            seen.add(m.group(1))
            return render(m.group(1), lang)
        out = re.sub(r'^@@fig:([\w-]+)@@$', ph, out, flags=re.M)

        def existing(m):
            name = re.search(r'data-fig=\\"([\w-]+)\\"', m.group(0))
            if not name or name.group(1) not in FIGURES:
                return m.group(0)
            seen.add(name.group(1))
            return render(name.group(1), lang)
        out = re.sub(r'```schooling-figure\n.*?\n```', existing, out, flags=re.S)
        if out != src:
            open(path, 'w').write(out)
    missing = set(FIGURES) - seen
    if missing:
        print('drawn but placed nowhere:', ', '.join(sorted(missing)), file=sys.stderr)


if __name__ == '__main__':
    main()
