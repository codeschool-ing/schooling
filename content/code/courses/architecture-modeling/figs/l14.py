"""Lesson 14: presenting architecture."""
from figures import Fig, T, figure


def stage(f, x0, n):
    """One step of the build-up: the context diagram with n groups of elements shown."""
    f.rect(x0, 30, 220, 230, stroke='--wire', fill='--ink', rx=5)
    f.badge(x0 + 18, 48, n)
    hi = lambda k: '--amber' if k == n else '--phosphor'
    f.person(x0 + 54, 100, T('Passenger', 'Passageiro'), size=9.5, stroke=hi(1))
    f.box(x0 + 165, 100, 90, 44, T('Ticketing', 'Venda de'), sub=T('system', 'passagens'), size=9.5, stroke=hi(1))
    f.arrow([(x0 + 100, 100), (x0 + 120, 100)], stroke='--paper-dim')
    if n >= 2:
        f.box(x0 + 58, 180, 86, 36, T('Payment', 'Gateway de'), sub=T('gateway', 'pagamento'), size=9, stroke=hi(2), dash='5 3')
        f.box(x0 + 150, 180, 60, 36, 'Frota', size=9.5, stroke=hi(2), dash='5 3')
        f.arrow([(x0 + 128, 122), (x0 + 92, 162)], stroke='--paper-dim')
        f.arrow([(x0 + 150, 162), (x0 + 150, 122)], stroke='--paper-dim')
    if n >= 3:
        f.box(x0 + 165, 235, 90, 30, T('26 stations', '26 rodoviárias'), size=9, stroke=hi(3))
        f.arrow([(x0 + 198, 220), (x0 + 198, 122)], stroke='--amber', width=2.2)


@figure('l14-build-up', 14)
def build_up():
    f = Fig('l14-build-up', 720, 300, T(
        'The same context diagram shown in three steps, left to right. Step 1: the passenger and the '
        'ticketing system. Step 2: the payment gateway and Frota are added, both dashed because they are '
        'outside the ticketing system. Step 3: the 26 stations are added, with their link to the '
        'ticketing system drawn thick and in amber. In each step the elements just added are outlined in '
        'amber.',
        'O mesmo diagrama de contexto mostrado em três passos, da esquerda para a direita. Passo 1: o '
        'passageiro e o sistema de venda de passagens. Passo 2: entram o gateway de pagamento e o Frota, '
        'os dois tracejados porque ficam fora do sistema de venda. Passo 3: entram as 26 rodoviárias, '
        'com o link delas até o sistema de venda desenhado grosso e em âmbar. Em cada passo, os '
        'elementos que acabaram de entrar têm contorno âmbar.'))
    for i in range(3):
        stage(f, 12 + i * 236, i + 1)
    f.text(360, 285, T('each step adds what the next sentence needs, and no more',
                       'cada passo acrescenta o que a próxima frase precisa, e nada mais'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('Built up in three steps, the diagram is a story: by the time the amber line appears, the room already knows what it connects.',
                'Montado em três passos, o diagrama vira uma história: quando a linha âmbar aparece, a sala já sabe o que ela liga.')


def station_view(f, x0, after):
    f.rect(x0, 34, 330, 226, stroke='--wire', fill='--ink', rx=5)
    f.text(x0 + 165, 52, T('after', 'depois') if after else T('before', 'antes'), size=11, weight='600')
    f.box(x0 + 240, 110, 130, 46, T('Ticketing', 'Venda de'), sub=T('system', 'passagens'), size=9.5, stroke='--phosphor')
    f.box(x0 + 80, 110, 120, 46, T('Station', 'Guichê da'), sub=T('counter', 'rodoviária'), size=9.5, stroke='--phosphor')
    f.arrow([(x0 + 140, 104), (x0 + 175, 104)], stroke='--paper-dim')
    if after:
        f.box(x0 + 80, 210, 120, 40, T('Back office', 'Back office'), sub=T('retired', 'aposentado'),
              size=9.5, stroke='--paper-dim', dash='5 3', fill='--ink')
        f.arrow([(x0 + 140, 120), (x0 + 175, 120)], stroke='--amber', width=2.2)
        f.tag(x0 + 157, 140, T('new: 2nd link', 'novo: 2º link'), size=9, fill='--amber')
    else:
        f.box(x0 + 80, 210, 120, 40, T('Back office', 'Back office'), sub=T('[Container]', '[Container]'),
              size=9.5, stroke='--phosphor')
        f.line(x0 + 80, 133, x0 + 80, 190, stroke='--paper-dim')
    f.box(x0 + 240, 210, 130, 40, T('Booking DB', 'Banco de reservas'), size=9.5, stroke='--phosphor')
    f.line(x0 + 240, 133, x0 + 240, 190, stroke='--paper-dim')


@figure('l14-before-after', 14)
def before_after():
    f = Fig('l14-before-after', 720, 290, T(
        'Before and after, side by side, with every element in the same place. Before: the station '
        'counter, linked by one line to the ticketing system, with the station back office under the '
        'counter and the booking database under the ticketing system. After: the same four elements in the '
        'same positions; the back office is dashed and grey with the word retired, and a second, thick '
        'amber line from the counter to the ticketing system is labelled new: 2nd link.',
        'Antes e depois, lado a lado, com cada elemento no mesmo lugar. Antes: o guichê da rodoviária, '
        'ligado por uma linha ao sistema de venda de passagens, com o back office da rodoviária embaixo '
        'do guichê e o banco de reservas embaixo do sistema de venda. Depois: os mesmos quatro elementos '
        'nas mesmas posições; o back office está tracejado e cinza com a palavra aposentado, e uma '
        'segunda linha, grossa e âmbar, do guichê até o sistema de venda tem o rótulo novo: 2º link.'))
    station_view(f, 20, False)
    station_view(f, 370, True)
    f.text(360, 278, T('same places: the eye finds the difference by itself',
                       'mesmos lugares: o olho acha a diferença sozinho'), size=9.5, fill='--paper-dim', italic=True)
    return f, T('Nothing moved except what changed, and each change carries a word as well as a colour.',
                'Nada se mexeu além do que mudou, e cada mudança traz uma palavra além de uma cor.')


@figure('l14-slide', 14)
def slide():
    f = Fig('l14-slide', 720, 330, T(
        'A slide with four numbered parts. 1, the title across the top states a claim: every '
        'station-side failure goes through one link. 2, the diagram below it: the station counter, the '
        'ticketing system and the link between them in amber. 3, a small legend at the right: solid box, '
        'Carcará system; amber line, at risk. 4, a footer along the bottom: model version 2026-06-01, '
        'owner Tainá.',
        'Um slide com quatro partes numeradas. 1, o título no alto afirma algo: toda falha do lado da '
        'rodoviária passa por um só link. 2, o diagrama abaixo: o guichê da rodoviária, o sistema de '
        'venda de passagens e o link entre eles em âmbar. 3, uma legenda pequena à direita: caixa '
        'sólida, sistema da Carcará; linha âmbar, em risco. 4, um rodapé embaixo: modelo versão '
        '2026-06-01, responsável Tainá.'))
    f.rect(40, 14, 640, 300, stroke='--paper-dim', fill='--ink', rx=6)
    f.text(70, 46, T('Every station-side failure goes through one link', 'Toda falha do lado da rodoviária passa por um só link'),
           size=15, anchor='start', weight='600')
    f.box(170, 160, 140, 50, T('Station counter', 'Guichê'), size=11, stroke='--phosphor')
    f.box(430, 160, 150, 50, T('Ticketing', 'Venda de'), sub=T('system', 'passagens'), size=11, stroke='--phosphor')
    f.arrow([(240, 160), (355, 160)], stroke='--amber', width=2.4)
    f.tag(297, 145, T('one link', 'um link'), size=10.5, fill='--amber')
    f.rect(540, 210, 126, 56, stroke='--wire', fill='--panel', rx=3)
    f.rect(550, 222, 14, 10, stroke='--phosphor', fill='--panel', rx=1)
    f.text(570, 227, T('Carcará system', 'sistema Carcará'), size=8.5, anchor='start')
    f.line(550, 250, 564, 250, stroke='--amber', width=2.2)
    f.text(570, 250, T('at risk', 'em risco'), size=8.5, anchor='start')
    f.line(40, 284, 680, 284, stroke='--wire')
    f.text(70, 299, T('model 2026-06-01 · owner: Tainá', 'modelo 2026-06-01 · responsável: Tainá'),
           size=9, anchor='start', fill='--paper-dim')
    f.badge(56, 46, 1)
    f.badge(82, 160, 2)
    f.badge(530, 238, 3)
    f.badge(56, 299, 4)
    return f, T('Read the title alone and the point is made; read the footer and you know how old the picture is.',
                'Leia só o título e a ideia está dada; leia o rodapé e você sabe a idade do desenho.')
