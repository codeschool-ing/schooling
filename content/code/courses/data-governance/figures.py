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


# ===================================================================== lesson 3
L3 = 'le-09gy18dh'


@figure('l3-layers', L3, 720, 270,
        ('The path of one customer record: from the client, across the network, into the '
         'running server, onto the data files and out to a backup. Under each stretch, the '
         'kind of encryption that covers it: TLS on the network, volume encryption on the '
         'data files, file encryption on the backup. Inside the running server there is none: '
         'there, grants and policies are what protect the data.',
         'O caminho de um registro de cliente: do cliente, pela rede, para dentro do servidor '
         'em execução, para os arquivos de dados e para um backup. Embaixo de cada trecho, o '
         'tipo de criptografia que o cobre: TLS na rede, criptografia de volume nos arquivos, '
         'criptografia de arquivo no backup. Dentro do servidor em execução não há nenhuma: '
         'ali, permissões e políticas protegem o dado.'),
        ('Every form of encryption ends somewhere. Inside the running database, the data is '
         'plaintext to anybody with a grant.',
         'Toda criptografia termina em algum lugar. Dentro do banco em execução, o dado é '
         'texto claro para quem tem permissão.'))
def _l3_layers(f):
    xs = [(20, 110, ('client', 'cliente')), (165, 110, ('network', 'rede')),
          (310, 120, ('the running server', 'o servidor rodando')),
          (465, 110, ('data files', 'arquivos de dados')), (610, 90, ('backup', 'backup'))]
    for x, w, label in xs:
        f.box(x, 40, w, 50, label, fill='--ink')
    for i in range(len(xs) - 1):
        x, w, _ = xs[i]
        f.arrow(x + w, 65, xs[i + 1][0] - 2, 65)
    def bracket(x0, x1, y, label, stroke):
        f.line(x0, y, x1, y, stroke=stroke, width=3)
        f.line(x0, y - 6, x0, y + 6, stroke=stroke, width=2)
        f.line(x1, y - 6, x1, y + 6, stroke=stroke, width=2)
        f.lines((x0 + x1) / 2, y + 30, label, size=11)
    bracket(130, 300, 130, [('TLS', 'TLS'), ('in transit', 'em trânsito')], '--phosphor')
    bracket(465, 575, 130, [('volume', 'volume'), ('at rest', 'em repouso')], '--phosphor')
    bracket(610, 700, 130, [('file', 'arquivo'), ('at rest', 'em repouso')], '--phosphor')
    f.rect(310, 118, 120, 120, stroke='--amber', fill='--panel', dash='4 3')
    f.lines(370, 178, [('no encryption', 'sem criptografia'), ('here:', 'aqui:'),
                       ('grants and', 'permissões e'), ('policies', 'políticas')], size=11)


@figure('l3-where-it-ends', L3, 720, 260,
        ('The database in the middle, on an encrypted volume. Arrows leave it to four copies '
         'that are plaintext unless encrypted separately: a pg_dump backup, a replica, a CSV '
         'export for another team, and the server log. Only the copies inside the volume '
         'boundary are covered by the volume\'s encryption.',
         'O banco no meio, num volume cifrado. Setas saem dele para quatro cópias que são '
         'texto claro a menos que cifradas à parte: um backup do pg_dump, uma réplica, uma '
         'exportação CSV para outro time, e o log do servidor. Só o que está dentro do volume '
         'é coberto pela criptografia do volume.'),
        ('An encrypted disk covers one copy. Every copy made through the database starts in '
         'clear.',
         'Um disco cifrado cobre uma cópia. Toda cópia feita pelo banco começa em claro.'))
def _l3_ends(f):
    f.rect(250, 60, 220, 140, stroke='--phosphor', fill='--panel', dash='5 4')
    f.text(360, 78, ('encrypted volume', 'volume cifrado'), size=11, fill='--paper-dim')
    f.box(285, 100, 150, 70, [('PostgreSQL', 'PostgreSQL'), {'s': 'ipe', 'mono': True,
                                                            'size': 10, 'fill': '--paper-dim'}],
          fill='--ink')
    outs = [(20, 30, ('pg_dump backup', 'backup do pg_dump')),
            (20, 170, ('a replica', 'uma réplica')),
            (540, 30, ('a CSV export', 'uma exportação CSV')),
            (540, 170, ('the server log', 'o log do servidor'))]
    for x, y, label in outs:
        f.box(x, y, 160, 54, [label, {'s': ('plaintext', 'texto claro'), 'size': 10,
                                       'fill': '--paper-dim'}], stroke='--amber', fill='--ink')
    f.arrow(285, 115, 182, 64, stroke='--amber')
    f.arrow(285, 155, 182, 196, stroke='--amber')
    f.arrow(435, 115, 538, 64, stroke='--amber')
    f.arrow(435, 155, 538, 196, stroke='--amber')


# ===================================================================== lesson 4
L4 = 'le-er7ww0xq'


@figure('l4-kms', L4, 720, 250,
        ('The website sends a CPF and the name of a key to the key-management service and '
         'receives ciphertext, which it stores in the database. Support sends the ciphertext '
         'and receives the CPF. The key itself stays inside the service; no arrow carries it '
         'out. Every request is written to the audit log.',
         'O site envia um CPF e o nome de uma chave ao serviço de gestão de chaves e recebe '
         'texto cifrado, que guarda no banco. O suporte envia o texto cifrado e recebe o CPF. '
         'A chave fica dentro do serviço; nenhuma seta a leva para fora. Toda requisição vai '
         'para o log de auditoria.'),
        ('The key stays in the service. What leaves is the result of using it, and every use '
         'is recorded.',
         'A chave fica no serviço. O que sai é o resultado de usá-la, e todo uso é registrado.'))
def _l4_kms(f):
    f.box(20, 50, 150, 50, [('the website', 'o site'), {'s': 'policy: encrypt', 'mono': True,
                                                      'size': 9.5, 'fill': '--paper-dim'}],
          fill='--ink')
    f.box(20, 170, 150, 50, [('support', 'suporte'), {'s': 'policy: decrypt', 'mono': True,
                                                     'size': 9.5, 'fill': '--paper-dim'}],
          fill='--ink')
    f.rect(285, 60, 150, 150, stroke='--phosphor', fill='--panel')
    f.text(360, 82, ('key service', 'serviço de chaves'), size=12, weight='600')
    f.box(310, 102, 100, 36, {'s': 'ipe-cpf', 'mono': True}, stroke='--amber', fill='--ink')
    f.text(360, 160, ('the key never', 'a chave nunca'), size=10.5, fill='--paper-dim')
    f.text(360, 176, ('leaves', 'sai'), size=10.5, fill='--paper-dim')
    f.box(550, 50, 150, 50, [('database', 'banco'), {'s': 'vault:v2:…', 'mono': True,
                                                  'size': 9.5, 'fill': '--paper-dim'}],
          fill='--ink')
    f.box(550, 170, 150, 50, ('audit log', 'log de auditoria'), fill='--ink')
    f.arrow(170, 66, 283, 90)
    f.text(228, 66, 'CPF', size=10, mono=True, fill='--paper-dim')
    f.arrow(283, 104, 170, 86)
    f.text(228, 112, ('ciphertext', 'cifrado'), size=10, fill='--paper-dim')
    f.path('M95 50 L95 22 L625 22 L625 48', stroke='--wire', dash='4 3', arrow=True)
    f.text(360, 14, ('stores the ciphertext', 'guarda o texto cifrado'), size=10,
           fill='--paper-dim')
    f.arrow(170, 186, 283, 176)
    f.text(228, 168, ('ciphertext', 'cifrado'), size=10, fill='--paper-dim')
    f.arrow(283, 196, 170, 206)
    f.text(228, 214, 'CPF', size=10, mono=True, fill='--paper-dim')
    f.arrow(435, 190, 548, 195, stroke='--phosphor')
    f.text(492, 182, ('every use', 'todo uso'), size=10, fill='--paper-dim')


@figure('l4-envelope', L4, 720, 260,
        ('Envelope encryption of a backup. The key service generates a data key and returns '
         'it twice: in clear, and wrapped by the ipe-backup key. The clear data key encrypts '
         'the dump and is shredded. The encrypted dump and the wrapped key are stored '
         'together. To restore, the wrapped key goes back to the service, which unwraps it.',
         'Criptografia envelope de um backup. O serviço de chaves gera uma chave de dados e a '
         'devolve duas vezes: em claro, e embrulhada pela chave ipe-backup. A chave de dados '
         'em claro cifra o dump e é destruída. O dump cifrado e a chave embrulhada são '
         'guardados juntos. Para restaurar, a chave embrulhada volta ao serviço, que a '
         'desembrulha.'),
        ('The data never goes to the key service, and the key that wraps it never comes out.',
         'O dado nunca vai ao serviço de chaves, e a chave que o embrulha nunca sai dele.'))
def _l4_envelope(f):
    f.rect(20, 30, 170, 200, stroke='--phosphor', fill='--panel')
    f.text(105, 52, ('key service', 'serviço de chaves'), size=12, weight='600')
    f.box(45, 72, 120, 36, {'s': 'ipe-backup', 'mono': True}, stroke='--amber', fill='--ink')
    f.lines(105, 160, [('generates a', 'gera uma'), ('data key', 'chave de dados')], size=10.5,
            fill='--paper-dim')
    f.box(260, 40, 170, 50, [('data key, in clear', 'chave em claro'),
                            {'s': 'backup.key', 'mono': True, 'size': 9.5,
                             'fill': '--paper-dim'}], stroke='--amber', fill='--ink')
    f.box(260, 160, 170, 50, [('data key, wrapped', 'chave embrulhada'),
                             {'s': 'backup.key.wrapped', 'mono': True, 'size': 9.5,
                              'fill': '--paper-dim'}], fill='--ink')
    f.arrow(190, 80, 258, 65)
    f.arrow(190, 180, 258, 185)
    f.box(500, 40, 200, 50, [('encrypts the dump,', 'cifra o dump,'),
                            ('then shredded', 'depois destruída')], fill='--ink')
    f.arrow(430, 65, 498, 65, stroke='--amber')
    f.rect(500, 140, 200, 90, stroke='--wire', fill='--panel', dash='4 3')
    f.text(600, 158, ('stored together', 'guardados juntos'), size=10.5, fill='--paper-dim')
    f.box(515, 170, 170, 26, {'s': 'customers.sql.enc', 'mono': True, 'size': 10},
          fill='--ink')
    f.box(515, 200, 170, 24, {'s': 'backup.key.wrapped', 'mono': True, 'size': 10},
          fill='--ink')
    f.arrow(430, 185, 498, 205)
    f.arrow(600, 90, 600, 138)


# ===================================================================== lesson 5
L5 = 'le-b17k3pwx'


@figure('l5-spectrum', L5, 720, 230,
        ('Four techniques placed along one line, from the original value on the left to data '
         'nobody can be found in on the right: masking, tokenisation, pseudonymisation, '
         'anonymisation. The first three are still personal data under the LGPD; only the '
         'fourth is not, and only while it holds.',
         'Quatro técnicas numa linha, do valor original à esquerda até o dado em que ninguém '
         'pode ser achado à direita: mascaramento, tokenização, pseudonimização, '
         'anonimização. As três primeiras ainda são dado pessoal pela LGPD; só a quarta não é, '
         'e só enquanto se sustenta.'),
        ('The law draws its line at the right-hand end, not in the middle.',
         'A lei traça a linha na ponta direita, não no meio.'))
def _l5_spectrum(f):
    f.arrow(30, 70, 690, 70, stroke='--paper-dim')
    f.text(30, 48, ('the original value', 'o valor original'), size=11, anchor='start',
           fill='--paper-dim')
    f.text(690, 48, ('nobody can be found', 'ninguém pode ser achado'), size=11, anchor='end',
           fill='--paper-dim')
    items = [(30, ('masking', 'mascaramento'), {'s': '***.874.168-**', 'mono': True, 'size': 9.5}),
             (195, ('tokenisation', 'tokenização'), {'s': 'tok_bbc2f3fe…', 'mono': True, 'size': 9.5}),
             (360, ('pseudonymisation', 'pseudonimização'), {'s': 'vault:v1:5Vv5…', 'mono': True, 'size': 9.5}),
             (525, ('anonymisation', 'anonimização'), ('counts, k ≥ 5', 'contagens, k ≥ 5'))]
    for i, (x, name, ex) in enumerate(items):
        last = i == 3
        f.box(x, 92, 160, 60, [name, ex if isinstance(ex, dict) else {'s': ex, 'size': 9.5}],
              stroke='--phosphor' if last else '--amber', fill='--ink')
    f.rect(30, 170, 490, 40, stroke='--amber', fill='--panel', dash='4 3')
    f.text(275, 190, ('personal data: every obligation applies', 'dado pessoal: toda obrigação vale'),
           size=11)
    f.rect(525, 170, 160, 40, stroke='--phosphor', fill='--panel', dash='4 3')
    f.text(605, 190, ('not personal data', 'não é dado pessoal'), size=11)


@figure('l5-kanon', L5, 720, 230,
        ('Three releases of the same 6,012 customers and how many are alone in their group. '
         'Birth date, sex and CEP: 5,988 alone. Birth year, sex and city: 670. Decade of birth, '
         'sex and state: 22.',
         'Três divulgações dos mesmos 6.012 clientes e quantos ficam sozinhos no grupo. Data de '
         'nascimento, sexo e CEP: 5.988 sozinhos. Ano de nascimento, sexo e cidade: 670. Década '
         'de nascimento, sexo e estado: 22.'),
        ('Coarser quasi-identifiers, fewer people alone, and still not none.',
         'Quase-identificadores mais grossos, menos gente sozinha, e ainda não nenhuma.'))
def _l5_kanon(f):
    rows = [(('birth date, sex, CEP', 'nascimento, sexo, CEP'), 5988, '5,988', '5.988'),
            (('birth year, sex, city', 'ano, sexo, cidade'), 670, '670', '670'),
            (('decade, sex, state', 'década, sexo, estado'), 22, '22', '22')]
    x0, x1 = 230, 640
    for i, (label, n, en, pt) in enumerate(rows):
        y = 40 + i * 58
        f.text(x0 - 12, y + 16, label, size=11, anchor='end')
        f.rect(x0, y, x1 - x0, 32, stroke='--wire', fill='--ink', rx=2)
        w = max(2, (x1 - x0) * n / 6012)
        f.rect(x0, y, w, 32, stroke='--amber', fill='--amber', rx=2)
        f.text(x0 + w + 8 if w < 300 else x0 + w - 8, y + 16, en if f.lang == 'en' else pt,
               size=11, anchor='start' if w < 300 else 'end',
               fill='--paper' if w < 300 else '--ink', mono=True)
    f.text(x1, 215, ('of 6,012 customers, alone in their group', 'de 6.012 clientes, sozinhos no grupo'),
           size=10.5, anchor='end', fill='--paper-dim')


# ===================================================================== lesson 6
L6 = 'le-rx3pz6b4'


@figure('l6-classes', L6, 720, 220,
        ("The 53 columns of Ipê's tables by class: 31 personal, 9 sensitive, 9 holding nothing "
         'about a person, 4 identifying. The sensitive ones are in health.prescriptions, in '
         'sales.order_items.product_id and in support.tickets.body.',
         'As 53 colunas das tabelas da Ipê por classe: 31 pessoais, 9 sensíveis, 9 sem nada '
         'sobre uma pessoa, 4 identificadoras. As sensíveis estão em health.prescriptions, em '
         'sales.order_items.product_id e em support.tickets.body.'),
        ('Most columns are personal data, and the sensitive ones are not all in the schema '
         'called health.',
         'A maioria das colunas é dado pessoal, e as sensíveis não estão todas no schema '
         'chamado health.'))
def _l6_classes(f):
    rows = [(('personal', 'personal'), 31, '--wire', None),
            (('sensitive', 'sensitive'), 9, '--amber',
             ('health.prescriptions (7), order_items.product_id, tickets.body',
              'health.prescriptions (7), order_items.product_id, tickets.body')),
            (('none', 'none'), 9, '--wire', None),
            (('identifying', 'identifying'), 4, '--phosphor',
             ('name, e-mail, cpf_ct, cpf_hmac', 'nome, e-mail, cpf_ct, cpf_hmac'))]
    x0, scale = 150, 14
    for i, (label, n, col, note) in enumerate(rows):
        y = 26 + i * 46
        f.text(x0 - 12, y + 14, label, size=11, anchor='end', mono=True)
        f.rect(x0, y, n * scale, 28, stroke=col, fill='--panel', rx=2)
        f.text(x0 + n * scale + 10, y + 14, str(n), size=11, anchor='start', mono=True)
        if note:
            f.text(x0 + n * scale + 40, y + 14, note, size=10, anchor='start', fill='--paper-dim')


@figure('l6-inference', L6, 720, 190,
        ('An order line holds a product id. The product belongs to a category. The category '
         'says something about the buyer\'s health: psychiatric, diabetes, contraceptive, a '
         'pregnancy test. The order line is therefore health data, though no column says so.',
         'Uma linha de pedido guarda um id de produto. O produto pertence a uma categoria. A '
         'categoria diz algo da saúde de quem comprou: psiquiátrico, diabetes, '
         'anticoncepcional, um teste de gravidez. A linha de pedido é, portanto, dado de saúde, '
         'embora nenhuma coluna diga isso.'),
        ('What a row reveals, not where it is filed, decides whether it is sensitive.',
         'O que uma linha revela, e não onde ela está arquivada, decide se ela é sensível.'))
def _l6_inference(f):
    f.box(20, 60, 150, 60, [{'s': 'order_items', 'mono': True},
                            {'s': 'product_id = 25', 'mono': True, 'size': 10,
                             'fill': '--paper-dim'}], fill='--ink')
    f.box(215, 60, 150, 60, [{'s': 'products', 'mono': True},
                             {'s': 'Clonazepam 2 mg', 'size': 10, 'fill': '--paper-dim'}],
          fill='--ink')
    f.box(410, 60, 140, 60, [{'s': 'category', 'mono': True},
                             {'s': 'psychiatric', 'mono': True, 'size': 10,
                              'fill': '--paper-dim'}], fill='--ink')
    f.box(595, 50, 105, 80, [('reveals', 'revela'), ('a health', 'uma condição'),
                            ('condition', 'de saúde')], stroke='--amber', fill='--panel')
    f.arrow(170, 90, 213, 90)
    f.arrow(365, 90, 408, 90)
    f.arrow(550, 90, 593, 90, stroke='--amber')
    f.text(360, 160, ('no column of order_items is called health, and the row is health data',
                      'nenhuma coluna de order_items se chama saúde, e a linha é dado de saúde'),
           size=11, fill='--paper-dim')


# ===================================================================== lesson 7
L7 = 'le-0gnyvwxs'


@figure('l7-bases', L7, 720, 260,
        ('One column, the customer\'s e-mail, serves two purposes. Delivery notices rest on '
         'the contract, article 7, V. Marketing rests on consent, article 7, I. When the '
         'customer withdraws consent, the marketing purpose stops and the delivery purpose '
         'goes on, on the same column.',
         'Uma coluna, o e-mail do cliente, serve a duas finalidades. Os avisos de entrega se '
         'apoiam no contrato, artigo 7, V. O marketing se apoia no consentimento, artigo 7, I. '
         'Quando o cliente revoga o consentimento, a finalidade de marketing para e a de '
         'entrega continua, sobre a mesma coluna.'),
        ('A legal basis belongs to a purpose, not to a column.',
         'Uma base legal pertence a uma finalidade, não a uma coluna.'))
def _l7_bases(f):
    f.box(20, 100, 160, 60, [{'s': 'sales.customers', 'mono': True, 'size': 10,
                              'fill': '--paper-dim'}, {'s': 'email', 'mono': True}],
          fill='--ink')
    f.text(330, 22, ('purpose', 'finalidade'), size=11, fill='--paper-dim')
    f.text(560, 22, ('legal basis', 'base legal'), size=11, fill='--paper-dim')
    f.box(240, 40, 180, 60, [('delivery notices', 'avisos de entrega'),
                             {'s': ('the order is on its way', 'o pedido está a caminho'),
                              'size': 10, 'fill': '--paper-dim'}])
    f.box(240, 160, 180, 60, [('marketing e-mails', 'e-mails de marketing'),
                              {'s': ('offers, news', 'ofertas, novidades'), 'size': 10,
                               'fill': '--paper-dim'}], stroke='--amber')
    f.box(480, 40, 220, 60, [('contract', 'contrato'),
                             {'s': ('art. 7, V', 'art. 7, V'), 'size': 10,
                              'fill': '--paper-dim'}], stroke='--phosphor')
    f.box(480, 160, 220, 60, [('consent', 'consentimento'),
                              {'s': ('art. 7, I · withdrawn on 20 June',
                                     'art. 7, I · revogado em 20 de junho'), 'size': 10,
                               'fill': '--paper-dim'}], stroke='--amber', dash='5 4')
    f.arrow(180, 120, 238, 72)
    f.arrow(180, 140, 238, 188)
    f.arrow(420, 70, 478, 70, stroke='--phosphor')
    f.arrow(420, 190, 478, 190, stroke='--amber')
    f.text(590, 130, ('goes on', 'continua'), size=10.5, fill='--paper-dim')
    f.text(590, 240, ('stops; the history stays', 'para; o histórico fica'), size=10.5,
           fill='--paper-dim')


@figure('l7-incident', L7, 720, 230,
        ('A timeline of an incident. Day zero is when the controller learns that personal data '
         'was affected. Within three working days it notifies the ANPD and the people affected. '
         'Within twenty working days of the notice it completes the information. The record of the incident '
         'is kept for at least five years, whether or not it was communicated.',
         'Uma linha do tempo de um incidente. O dia zero é quando o controlador sabe que dados '
         'pessoais foram afetados. Em até três dias úteis ele comunica a ANPD e as pessoas '
         'afetadas. Em até vinte dias úteis da comunicação completa as informações. O registro do incidente '
         'é guardado por pelo menos cinco anos, comunicado ou não.'),
        ('Resolução CD/ANPD nº 15/2024: the clock starts when the controller knows, not when '
         'the investigation ends.',
         'Resolução CD/ANPD nº 15/2024: o relógio começa quando o controlador sabe, não quando '
         'a investigação termina.'))
def _l7_incident(f):
    f.line(40, 110, 690, 110, stroke='--wire', width=2)
    pts = [(105, '--amber', ('day 0', 'dia 0'), ('the controller learns', 'o controlador sabe'),
            ('personal data was affected', 'que dados pessoais foram afetados')),
           (275, '--phosphor', ('3 working days', '3 dias úteis'),
            ('notify the ANPD', 'comunicar a ANPD'),
            ('and the people affected', 'e as pessoas afetadas')),
           (450, '--phosphor', ('+20 working days', '+20 dias úteis'),
            ('complete the', 'completar as'), ('information', 'informações')),
           (625, '--paper-dim', ('5 years', '5 anos'), ('keep the record,', 'guardar o registro,'),
            ('communicated or not', 'comunicado ou não'))]
    for x, c, when, a, b in pts:
        f.circle(x, 110, 7, fill=c)
        f.text(x, 80, when, size=12, weight='600')
        f.text(x, 140, a, size=10.5)
        f.text(x, 157, b, size=10.5, fill='--paper-dim')
    f.rect(40, 185, 640, 30, stroke='--wire', fill='--panel', dash='5 4')
    f.text(360, 200, ('investigation goes on throughout; what is not known yet is said to be '
                      'not known yet', 'a investigação continua o tempo todo; o que ainda não '
                      'se sabe é dito como ainda não sabido'), size=10.5, fill='--paper-dim')


# ===================================================================== lesson 8
L8 = 'le-sf7z08wp'


@figure('l8-ai-tiers', L8, 720, 250,
        ('The four levels of risk in the EU AI Act, from the top: prohibited practices, '
         'high-risk systems, systems with transparency obligations, and minimal risk. Each of '
         'Ipê\'s systems sits on one level: the CV screening tool is high-risk, the support '
         'chatbot carries transparency obligations, and the fraud score and the recommender are '
         'minimal risk.',
         'Os quatro níveis de risco do AI Act europeu, de cima para baixo: práticas proibidas, '
         'sistemas de alto risco, sistemas com obrigações de transparência, e risco mínimo. '
         'Cada sistema da Ipê fica num nível: a triagem de currículos é de alto risco, o '
         'chatbot de suporte tem obrigações de transparência, e o score de fraude e o '
         'recomendador são de risco mínimo.'),
        ('The class follows from what the system is used for, not from how it is built.',
         'A classe decorre do uso do sistema, e não de como ele é construído.'))
def _l8_ai_tiers(f):
    rows = [(20, '--amber', ('prohibited', 'proibido'), ('art. 5 · may not be used at all',
                                                          'art. 5 · não pode ser usado'), None),
            (75, '--amber', ('high-risk', 'alto risco'),
             ('Annex III · most of the Act', 'Anexo III · a maior parte da lei'), 'cv-screen'),
            (130, '--phosphor', ('transparency', 'transparência'),
             ('art. 50 · say it is an AI', 'art. 50 · dizer que é uma IA'), 'support-bot'),
            (185, '--wire', ('minimal', 'mínimo'),
             ('no specific duties', 'sem deveres específicos'), 'fraud-score · recommender')]
    for k, (y, c, name, what, ipe) in enumerate(rows):
        inset = 60 - k * 18
        f.rect(20 + inset, y, 440 - 2 * inset, 45, stroke=c, fill='--panel')
        f.text(240, y + 15, name, size=12, weight='600')
        f.text(240, y + 32, what, size=10, fill='--paper-dim')
        if ipe:
            f.line(462 - inset, y + 22, 500, y + 22, stroke='--wire', dash='3 3')
            f.box(500, y + 6, 200, 32, {'s': ipe, 'mono': True, 'size': 10.5}, fill='--ink')
        else:
            f.text(600, y + 22, ('nothing at Ipê', 'nada na Ipê'), size=10.5, fill='--paper-dim')


@figure('l8-ai-timeline', L8, 720, 230,
        ('A timeline of the EU AI Act. In force on 1 August 2024. Prohibitions apply from 2 '
         'February 2025. General-purpose model rules from 2 August 2025. Transparency and most '
         'of the rest from 2 August 2026. After the Digital Omnibus of July 2026, the Annex III '
         'high-risk obligations apply from 2 December 2027 instead of 2 August 2026, and the '
         'Annex I ones from 2 August 2028 instead of 2 August 2027.',
         'Uma linha do tempo do AI Act europeu. Em vigor em 1º de agosto de 2024. As proibições '
         'valem desde 2 de fevereiro de 2025. As regras de modelos de propósito geral desde 2 de '
         'agosto de 2025. Transparência e quase todo o resto desde 2 de agosto de 2026. Depois '
         'do Digital Omnibus de julho de 2026, as obrigações de alto risco do Anexo III valem a '
         'partir de 2 de dezembro de 2027, em vez de 2 de agosto de 2026, e as do Anexo I a '
         'partir de 2 de agosto de 2028, em vez de 2 de agosto de 2027.'),
        ('Checked in October 2026. A schedule set by law is changed by law.',
         'Conferido em outubro de 2026. Um cronograma fixado em lei muda por lei.'))
def _l8_ai_timeline(f):
    f.line(30, 100, 700, 100, stroke='--wire', width=2)
    pts = [(60, '--paper-dim', '2024-08', ('in force', 'em vigor')),
           (160, '--amber', '2025-02', ('prohibitions', 'proibições')),
           (260, '--phosphor', '2025-08', ('general-purpose', 'propósito geral')),
           (360, '--phosphor', '2026-08', ('transparency', 'transparência')),
           (520, '--amber', '2027-12', ('Annex III', 'Anexo III')),
           (650, '--amber', '2028-08', ('Annex I', 'Anexo I'))]
    for x, c, when, what in pts:
        f.circle(x, 100, 6, fill=c)
        f.text(x, 75, when, size=11, mono=True)
        f.text(x, 125, what, size=10.5)
    f.line(385, 90, 385, 110, stroke='--paper', width=2)
    f.text(385, 145, ('today, October 2026', 'hoje, outubro de 2026'), size=10, fill='--paper-dim')
    f.rect(440, 160, 260, 50, stroke='--amber', fill='--panel', dash='5 4')
    f.lines(570, 185, [('moved by Regulation (EU) 2026/1744:', 'movidos pelo Regulamento (UE) 2026/1744:'),
                       ('from 2026-08 and 2027-08', 'antes 2026-08 e 2027-08')], size=10,
            fill='--paper-dim')


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
