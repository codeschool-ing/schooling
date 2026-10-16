import math

from svg import Fig

# ---- partitioning: the same twelve stations, by range and by hash ----------
# The hash row is the placement skew.py prints: md5 of the station id, mod 4.
p = Fig('partitioning', 720, 236,
        caption=('The same twelve stations over four partitions. By range, neighbours stay together; '
                 'by hash, they scatter. Either way, the box holding ST02 holds all of its rides.',
                 'As mesmas doze estações em quatro partições. Por intervalo, as vizinhas ficam juntas; '
                 'por hash, elas se espalham. De um jeito ou de outro, a caixa que tem a ST02 tem todas '
                 'as viagens dela.'),
        label=('Two rows of four partitions. By range of station: partition 0 holds ST01 to ST03, '
               'partition 1 ST04 to ST06, partition 2 ST07 to ST09, partition 3 ST10 to ST12. By hash '
               'of station: partition 0 holds ST10; partition 1 ST03, ST04, ST05 and ST12; partition 2 '
               'ST01, ST07, ST09 and ST11; partition 3 ST02, ST06 and ST08. The partition holding ST02 '
               'is marked in each row.',
               'Duas fileiras de quatro partições. Por intervalo de estação: a partição 0 tem ST01 a '
               'ST03, a 1 tem ST04 a ST06, a 2 tem ST07 a ST09, a 3 tem ST10 a ST12. Por hash da '
               'estação: a partição 0 tem ST10; a 1 tem ST03, ST04, ST05 e ST12; a 2 tem ST01, ST07, '
               'ST09 e ST11; a 3 tem ST02, ST06 e ST08. A partição que tem a ST02 está marcada nas '
               'duas fileiras.'))
rows = [
    (('by range', 'por intervalo'), [['ST01 ST02 ST03'], ['ST04 ST05 ST06'], ['ST07 ST08 ST09'],
                                     ['ST10 ST11 ST12']], 0),
    (('by hash', 'por hash'), [['ST10'], ['ST03 ST04', 'ST05 ST12'], ['ST01 ST07', 'ST09 ST11'],
                               ['ST02 ST06', 'ST08']], 3),
]
for r, (name, parts, hot) in enumerate(rows):
    y = 30 + r * 104
    p.text(20, y + 14, name, anchor='start', size=12, weight='600')
    p.text(20, y + 32, ('of station', 'da estação'), anchor='start', size=10.5, color='paper-dim')
    for i, stations in enumerate(parts):
        x = 150 + i * 142
        p.box(x, y, 128, 78, stations, title=(f'partition {i}', f'partição {i}'),
              stroke='amber' if i == hot else 'wire', mono=True, size=10.5)
p.text(150, 222, ('highlighted: the partition with ST02, the hot station',
                  'em destaque: a partição com a ST02, a estação concorrida'),
       anchor='start', size=10.5, color='amber')


# ---- ring: consistent hashing, before and after a fifth node ---------------
CX, CY, R = 175, 160, 112


def at(deg, r=R):
    a = math.radians(deg)
    return round(CX + r * math.sin(a), 1), round(CY - r * math.cos(a), 1)


g = Fig('ring', 720, 320,
        caption=('A ring with one point per node, for clarity. n5 joins between n1 and n2 and takes '
                 'only the keys on the thick arc, all of them from n2.',
                 'Um anel com um ponto por nó, para ficar claro. O n5 entra entre o n1 e o n2 e fica só '
                 'com as chaves do arco grosso, todas vindas do n2.'),
        label=('A circle of hash values with four nodes on it, n1 to n4, and keys as small dots. Each '
               'key belongs to the first node clockwise from it. A fifth node, n5, is added between '
               'n1 and n2; the keys on the arc between n1 and n5 move from n2 to n5, and every other '
               'key stays where it was.',
               'Um círculo de valores de hash com quatro nós, de n1 a n4, e chaves como pontinhos. '
               'Cada chave pertence ao primeiro nó no sentido horário a partir dela. Um quinto nó, '
               'n5, entra entre o n1 e o n2; as chaves do arco entre o n1 e o n5 passam do n2 para o '
               'n5, e todas as outras ficam onde estavam.'))
g.circle(CX, CY, R, fill='ink', stroke='wire', sw=2)
x1, y1 = at(20)
x2, y2 = at(70)
g.items.append(lambda lang: (
    f'<path d="M {x1} {y1} A {R} {R} 0 0 1 {x2} {y2}" fill="none" stroke="var(--amber)" '
    f'stroke-width="6"></path>'))
for deg in (32, 45, 58, 95, 150, 175, 235, 262, 315, 345):
    x, y = at(deg)
    g.circle(x, y, 3.5, fill='amber' if 20 < deg < 70 else 'paper-dim', stroke='ink', sw=1)
for name, deg, new in (('n1', 20, False), ('n2', 110, False), ('n3', 200, False),
                       ('n4', 290, False), ('n5', 70, True)):
    x, y = at(deg)
    g.circle(x, y, 9, fill='panel', stroke='phosphor' if new else 'paper', sw=2.5)
    lx, ly = at(deg, R + 26)
    g.text(lx, ly, name, mono=True, size=12, weight='600',
           color='phosphor' if new else 'paper')
g.text(CX, CY - 8, ('hash values', 'valores de hash'), size=10.5, color='paper-dim')
g.text(CX, CY + 10, ('clockwise', 'sentido horário'), size=10.5, color='paper-dim')
notes = [
    (('A key belongs to the first node', 'Uma chave pertence ao primeiro nó'), 'paper'),
    (('clockwise from it.', 'no sentido horário a partir dela.'), 'paper'),
    (('n5 joins between n1 and n2.', 'O n5 entra entre o n1 e o n2.'), 'phosphor'),
    (('The keys on the thick arc used to', 'As chaves do arco grosso iam primeiro'), 'amber'),
    (('meet n2 first; now they meet n5.', 'ao n2; agora vão primeiro ao n5.'), 'amber'),
    (('Every other key meets the same', 'Todas as outras chaves encontram'), 'paper'),
    (('node as before, and stays.', 'o mesmo nó de antes, e ficam.'), 'paper'),
]
ys = [72, 92, 136, 180, 200, 244, 264]
for (t, color), y in zip(notes, ys):
    g.text(380, y, t, anchor='start', size=12, color=color)


# ---- replication-lag: one write, two reads, one follower behind ------------
def tx(t):
    return 170 + t * 0.5


r = Fig('replication-lag', 720, 270,
        caption=('The app writes to the leader and reads from a follower. A read that reaches the '
                 'follower before the change does is answered with the old value.',
                 'O aplicativo escreve no líder e lê de um seguidor. Uma leitura que chega ao seguidor '
                 'antes da mudança recebe o valor antigo.'),
        label=('Three timelines: the leader, the app and the follower. At 0 ms the app writes docked '
               'to the leader. At 50 ms it reads from the follower and gets riding, the old value. The '
               'change reaches the follower at 800 ms. At 900 ms the app reads from the follower again '
               'and gets docked.',
               'Três linhas do tempo: o líder, o aplicativo e o seguidor. Em 0 ms o aplicativo escreve '
               'docked no líder. Em 50 ms ele lê do seguidor e recebe riding, o valor antigo. A mudança '
               'chega ao seguidor em 800 ms. Em 900 ms o aplicativo lê do seguidor de novo e recebe '
               'docked.'))
lanes = [(('leader', 'líder'), 50), (('the app', 'o aplicativo'), 128), (('follower', 'seguidor'), 206)]
for name, y in lanes:
    r.text(20, y, name, anchor='start', size=12, weight='600')
    r.line(150, y, 700, y, color='wire', sw=2)
# the write
r.arrow(tx(0), 122, tx(0), 57)
r.text(tx(0) - 6, 90, ('write', 'escreve'), anchor='end', size=11)
r.text(tx(0) + 6, 90, 'docked', anchor='start', size=11, mono=True)
r.circle(tx(0), 50, 4, fill='phosphor', stroke='phosphor')
# the log, late
r.arrow(tx(0) + 4, 54, tx(800), 200, color='phosphor', dash='5 4')
r.text(tx(560), 100, ('the change arrives 800 ms later', 'a mudança chega 800 ms depois'),
       anchor='start', size=11, color='phosphor')
r.circle(tx(800), 206, 4, fill='phosphor', stroke='phosphor')
# two reads
r.arrow(tx(50), 134, tx(50), 199, color='amber')
r.text(tx(50) + 8, 158, ('read', 'lê'), anchor='start', size=11, color='amber')
r.text(tx(50) + 8, 226, 'riding', anchor='start', size=11, mono=True, color='amber')
r.text(tx(50) + 60, 226, ('(the old value)', '(o valor antigo)'), anchor='start', size=11, color='amber')
r.arrow(tx(900), 134, tx(900), 199)
r.text(tx(900) + 8, 158, ('read', 'lê'), anchor='start', size=11)
r.text(tx(900) + 8, 226, 'docked', anchor='start', size=11, mono=True)
for t in (0, 50, 800, 900):
    r.text(tx(t), 254, str(t), size=10.5, mono=True, color='paper-dim')
r.text(700, 254, 'ms', anchor='end', size=10.5, mono=True, color='paper-dim')

FIGURES = [p, g, r]
