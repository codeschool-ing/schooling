"""Lesson 16: vulnerability management."""
import math
from figures import Fig, T, figure


@figure('l16-cycle', 16)
def cycle():
    f = Fig('l16-cycle', 720, 300, T(
        'Five steps around a circle: discover what runs, assess which flaws apply, prioritise and set a '
        'date, remediate by patching, reconfiguring, removing or accepting, and verify with the same '
        'check that found the flaw, which leads back to discover. Discover is marked as lesson 18 and '
        'remediate as lesson 17; assess, prioritise and verify are this lesson.',
        'Cinco passos em volta de um círculo: descobrir o que roda, avaliar que falhas se aplicam, '
        'priorizar e marcar uma data, remediar corrigindo, reconfigurando, removendo ou aceitando, e '
        'verificar com a mesma checagem que achou a falha, o que leva de volta a descobrir. Descobrir '
        'está marcado como aula 18 e remediar como aula 17; avaliar, priorizar e verificar são esta aula.'))
    steps = [(T('discover', 'descobrir'), T('lesson 18', 'aula 18'), False),
             (T('assess', 'avaliar'), T('this lesson', 'esta aula'), True),
             (T('prioritise', 'priorizar'), T('this lesson', 'esta aula'), True),
             (T('remediate', 'remediar'), T('lesson 17', 'aula 17'), False),
             (T('verify', 'verificar'), T('this lesson', 'esta aula'), True)]
    cx, cy, r = 360, 155, 105
    pts = []
    for i in range(5):
        a = -math.pi / 2 + i * 2 * math.pi / 5
        pts.append((cx + r * math.cos(a) * 1.9, cy + r * math.sin(a)))
    def edge(x, y, dx, dy, hw=68, hh=30):
        """Where the line from the centre (x, y) along (dx, dy) leaves a box of half-size hw by hh."""
        t = min(hw / abs(dx) if dx else 1e9, hh / abs(dy) if dy else 1e9)
        return x + dx * t, y + dy * t
    for i, (x, y) in enumerate(pts):
        nx, ny = pts[(i + 1) % 5]
        dx, dy = nx - x, ny - y
        sx, sy = edge(x, y, dx, dy)
        ex, ey = edge(nx, ny, -dx, -dy)
        f.line(sx, sy, ex, ey, stroke='--paper-dim', width=1.3, arrow=True)
    for (name, where, here), (x, y) in zip(steps, pts):
        c = '--phosphor' if here else '--wire'
        f.rect(x - 62, y - 24, 124, 48, stroke=c, fill='--panel', width=1.5, rx=3)
        f.text(x, y - 7, name, size=11.5, weight='600')
        f.text(x, y + 11, where, size=9.5, fill='--paper-dim')
    return f, T('The scan is one step of five. The ones after the report are the ones that get skipped.',
                'A varredura é um passo de cinco. Os que vêm depois do relatório são os que ficam para trás.')


@figure('l16-priority', 16)
def priority():
    f = Fig('l16-priority', 720, 300, T(
        'The five findings that apply to web, placed by CVSS base score along the bottom and by EPSS, the '
        'probability of exploitation, up the side. nginx sits at 7.5 and 0.41 and is marked as known '
        'exploited, priority 1. OpenSSH at 8.1 and 0.02 and vsftpd at 7.5 and 0.05 are priority 2. '
        'libssl at 5.9 and 0.01 and curl at 4.3 and 0.003 are priority 4. The highest score is not the '
        'first priority.',
        'As cinco falhas que se aplicam ao web, posicionadas pela nota base do CVSS na horizontal e pelo '
        'EPSS, a probabilidade de exploração, na vertical. O nginx fica em 7,5 e 0,41 e está marcado como '
        'explorado, prioridade 1. O OpenSSH em 8,1 e 0,02 e o vsftpd em 7,5 e 0,05 são prioridade 2. O '
        'libssl em 5,9 e 0,01 e o curl em 4,3 e 0,003 são prioridade 4. A nota mais alta não é a primeira '
        'prioridade.'))
    x0, x1, y0, y1 = 90, 660, 250, 40
    X = lambda s: x0 + (s - 4) / (9 - 4) * (x1 - x0)
    Y = lambda e: y0 - e / 0.5 * (y0 - y1)
    f.line(x0, y0, x1, y0, stroke='--wire', width=1.2)
    f.line(x0, y0, x0, y1, stroke='--wire', width=1.2)
    for s in (4, 5, 6, 7, 8, 9):
        f.text(X(s), y0 + 14, str(s), size=9.5, mono=True, fill='--paper-dim')
    for e in (0, 0.1, 0.2, 0.3, 0.4, 0.5):
        f.text(x0 - 10, Y(e), f'{e:.1f}', size=9.5, mono=True, anchor='end', fill='--paper-dim')
    f.text((x0 + x1) / 2, y0 + 32, T('CVSS base score', 'nota base do CVSS'), size=10, fill='--paper-dim')
    f.text(x0 - 10, y1 - 16, 'EPSS', size=10, anchor='end', fill='--paper-dim')
    pts = [('nginx', 7.5, 0.41, 'P1', '--amber'), ('openssh-server', 8.1, 0.02, 'P2', '--phosphor'),
           ('vsftpd', 7.5, 0.05, 'P2', '--phosphor'), ('libssl3t64', 5.9, 0.01, 'P4', '--paper-dim'),
           ('curl', 4.3, 0.003, 'P4', '--paper-dim')]
    for name, s, e, p, c in pts:
        f.circle(X(s), Y(e), 6, fill=c)
        dy = -14 if name != 'vsftpd' else -26
        f.text(X(s) + 10, Y(e) + dy, f'{name}  {p}', size=10, anchor='start', mono=True, fill=c)
    f.text(X(7.5) + 10, Y(0.41) + 4, T('known exploited', 'explorado de fato'), size=9.5, anchor='start',
           fill='--amber')
    return f, T('Priority is not the highest score: it is the score, the likelihood and the exposure together.',
                'Prioridade não é a nota mais alta: é a nota, a probabilidade e a exposição juntas.')
