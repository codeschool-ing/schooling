"""Lesson 13: Strangling the legacy (strangler fig) and coexistence."""
from figures import Fig, T, figure


@figure('l13-risk', 13)
def risk():
    f = Fig('l13-risk', 720, 310, T(
        'A chart with time in months on the horizontal axis, from 0 to 30, and, on the vertical '
        'axis, change that has been built but not yet proved in production. The big-bang line '
        'rises steadily for the whole project, from nothing at month 0 to its highest point at '
        'month 28, and drops to zero only at the cutover, where all of it is proved at once. The '
        'incremental line is a sawtooth that stays low: it rises for about four months, drops to '
        'zero when a slice goes live, and repeats six times.',
        'Um gráfico com o tempo em meses no eixo horizontal, de 0 a 30, e, no eixo vertical, a '
        'mudança já construída mas ainda não provada em produção. A linha do big bang sobe sem '
        'parar durante todo o projeto, de nada no mês 0 até o ponto mais alto no mês 28, e só cai '
        'a zero no cutover, onde tudo é provado de uma vez. A linha incremental é um dente de '
        'serra que fica baixo: sobe durante uns quatro meses, cai a zero quando uma fatia entra '
        'em produção, e se repete seis vezes.'))
    x0, y0, w, h = 90, 250, 560, 190
    f.line(x0, y0, x0 + w + 10, y0, stroke='--paper-dim', width=1.2, arrow=True)
    f.line(x0, y0, x0, y0 - h - 10, stroke='--paper-dim', width=1.2, arrow=True)
    for m in (0, 6, 12, 18, 24, 30):
        x = x0 + m * w / 30
        f.line(x, y0, x, y0 + 4, stroke='--paper-dim', width=1)
        f.text(x, y0 + 14, str(m), size=10, fill='--paper-dim')
    f.text(x0 + w / 2, y0 + 34, T('months since the project started', 'meses desde o início do projeto'),
           size=10.5, fill='--paper-dim')
    f.lines(42, y0 - h / 2, [T('built,', 'construído,'), T('not yet', 'ainda não'),
                             T('proved', 'provado')], size=10.5, fill='--paper-dim')

    def px(m):
        return x0 + m * w / 30

    top = y0 - h + 10
    f.path(f'M{px(0):.1f} {y0:.1f} L{px(28):.1f} {top:.1f} L{px(28):.1f} {y0:.1f}',
           stroke='--amber', width=2.2)
    f.circle(px(28), top, 4, fill='--amber')
    f.text(px(28) - 8, top - 2, T('cutover: all of it proved on one night',
                                  'cutover: tudo provado numa noite só'),
           size=10.5, anchor='end', fill='--amber')
    pts = [(px(0), y0)]
    for k in range(6):
        a, b = 1 + k * 4.6, 1 + (k + 1) * 4.6
        peak = y0 - 24
        pts += [(px(b - 0.4), peak), (px(b - 0.4), y0)]
    f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke='--phosphor', width=2)
    f.text(px(17.5), y0 - 46, T('incremental: each slice proved when it goes live',
                              'incremental: cada fatia provada quando entra em produção'),
           size=10.5, fill='--phosphor')
    f.text(px(9), 70, T('big bang', 'big bang'), size=11, weight='600', fill='--amber')
    return f, T('The risk sits in work that nobody has yet seen running against real farms. A big bang lets it pile up for the whole project; a strangler releases it a slice at a time.',
                'O risco está no trabalho que ninguém viu ainda rodando contra fazendas de verdade. O big bang deixa ele se acumular durante o projeto inteiro; o strangler libera uma fatia de cada vez.')


def _stage(f, x0, title, legacy_h, legacy_label, new_h, routes, legacy_off=False):
    cx = x0 + 110
    f.text(cx, 22, title, size=11.5, weight='600')
    f.box(cx, 58, 170, 30, [T('callers', 'quem chama')], stroke='--paper-dim')
    f.box(cx, 112, 190, 30, [T('facade: routes by capability', 'fachada: roteia por capacidade')],
          stroke='--phosphor')
    f.line(cx, 73, cx, 95, stroke='--paper-dim', arrow=True)
    lx, nx = x0 + 55, x0 + 165
    if legacy_h:
        y = 160
        if legacy_off:
            f.rect(lx - 45, y, 90, legacy_h, stroke='--paper-dim', fill='--ink', dash='4 3')
        else:
            f.rect(lx - 45, y, 90, legacy_h, stroke='--amber', fill='--panel')
        f.lines(lx, y + legacy_h / 2, legacy_label, size=10,
                fill='--paper-dim' if legacy_off else '--paper')
    if new_h:
        y = 160
        f.rect(nx - 45, y, 90, new_h, stroke='--phosphor', fill='--panel')
        f.lines(nx, y + new_h / 2, [T('new', 'novo'), T('system', 'sistema')], size=10)
    for target, n in routes:
        x = lx if target == 'old' else nx
        for i in range(n):
            sx = cx - 20 + (i - (n - 1) / 2) * 10 + (-25 if target == 'old' else 25)
            f.arrow([(sx, 128), (x + (i - (n - 1) / 2) * 12, 156)],
                    stroke='--amber' if target == 'old' else '--phosphor', width=1.2)


@figure('l13-stages', 13)
def stages():
    f = Fig('l13-stages', 720, 320, T(
        'Three stages of a strangler side by side, each with the callers at the top and a facade '
        'below them that routes by capability. In the first stage all four capabilities go to the '
        'legacy system, a tall box, and there is no new system. In the second, two capabilities go '
        'to the legacy, now shorter, and two to the new system. In the third, all four go to the '
        'new system and the legacy is a dashed outline marked switched off.',
        'Três estágios de um strangler lado a lado, cada um com quem chama no topo e, abaixo, uma '
        'fachada que roteia por capacidade. No primeiro estágio as quatro capacidades vão para o '
        'sistema legado, uma caixa alta, e não existe sistema novo. No segundo, duas capacidades vão '
        'para o legado, agora mais baixo, e duas para o sistema novo. No terceiro, as quatro vão '
        'para o sistema novo e o legado é um contorno tracejado marcado como desligado.'))
    _stage(f, 10, T('1 · everything to the legacy', '1 · tudo para o legado'), 120,
           [T('legacy', 'legado')], 0, [('old', 4)])
    f.line(240, 30, 240, 300, stroke='--wire', width=1, dash='4 4')
    _stage(f, 250, T('2 · some capabilities moved', '2 · algumas capacidades mudaram'), 70,
           [T('legacy', 'legado')], 70, [('old', 2), ('new', 2)])
    f.line(480, 30, 480, 300, stroke='--wire', width=1, dash='4 4')
    _stage(f, 490, T('3 · the legacy answers nothing', '3 · o legado não responde nada'), 120,
           [T('switched off', 'desligado')],
           120, [('new', 4)], legacy_off=True)
    f.text(360, 304, T('what moves is a capability, end to end; the callers never change',
                       'o que muda de lado é uma capacidade inteira; quem chama nunca muda'),
           size=10.5, fill='--paper-dim', italic=True)
    return f, T('The life of a strangler in three frames. The facade stays where it is; behind it, the legacy answers less at each stage until it answers nothing.',
                'A vida de um strangler em três quadros. A fachada fica onde está; atrás dela, o legado responde menos a cada estágio, até não responder nada.')


@figure('l13-intercept', 13)
def intercept():
    f = Fig('l13-intercept', 720, 400, T(
        'Coleta, on the IBM i, in the middle, with every flow that crosses its boundary. On the '
        'left, the inputs: route files from the trucks\' handhelds now pass through a new intake '
        'service, which keeps a copy and forwards the file; the laboratory\'s results file passes '
        'through the new quality service in the same way; the clerks\' green screens write '
        'straight into Coleta, with nothing in between. Above, the two bus flows, farm lookup for '
        'Rota and the collection summary, already act as a facade. On the right, the outputs: the '
        'nightly file to SAP and the monthly payment amounts to SAP. Below, Coleta\'s journal '
        'feeds change data capture, which sends the changes the clerks make to the new side. Each '
        'path is labelled with the technique that reaches it.',
        'A Coleta, no IBM i, no meio, com todos os fluxos que cruzam a sua fronteira. À esquerda, '
        'as entradas: os arquivos de rota dos coletores portáteis dos caminhões passam agora por '
        'um serviço novo de recepção, que guarda uma cópia e repassa o arquivo; o arquivo de '
        'resultados do laboratório passa pelo novo serviço de qualidade do mesmo jeito; as telas '
        'verdes dos funcionários gravam direto na Coleta, sem nada no meio. Em cima, os dois '
        'fluxos do barramento, consulta de fazenda para o Rota e o resumo da coleta, que já fazem '
        'papel de fachada. À direita, as saídas: o arquivo noturno para o SAP e os valores mensais '
        'de pagamento para o SAP. Embaixo, o journal da Coleta alimenta a captura de mudanças, que '
        'manda para o lado novo as alterações feitas pelos funcionários. Cada caminho tem o nome da '
        'técnica que o alcança.'))
    cx, cy = 400, 205
    f.box(cx, cy, 150, 110, [], stroke='--amber')
    f.text(cx, cy - 12, 'Coleta', size=12, weight='600')
    f.text(cx, cy + 10, T('IBM i, RPG', 'IBM i, RPG'), size=10, fill='--paper-dim')
    # inputs
    rows = [(110, T('handheld route files', 'arquivos de rota'), T('intake service', 'serviço de recepção')),
            (190, T('laboratory results', 'resultados do laboratório'), T('quality service', 'serviço de qualidade'))]
    for y, src, svc in rows:
        f.box(70, y, 120, 34, [src], size=10, stroke='--paper-dim')
        f.box(215, y, 120, 34, [svc], size=10, stroke='--phosphor')
        f.arrow([(130, y), (153, y)], stroke='--paper-dim')
        f.arrow([(275, y), (cx - 77, cy - 40 + (y - 110) * 0.5)], stroke='--phosphor')
        f.text(215, y + 26, T('event interception', 'interceptação de eventos'), size=9.5,
               fill='--phosphor', italic=True)
    f.box(70, 290, 120, 34, [T("clerks' screens", 'telas dos funcionários')], size=10, stroke='--paper-dim')
    f.arrow([(130, 290), (cx - 77, cy + 40)], stroke='--amber')
    f.text(215, 318, T('nothing to intercept', 'nada para interceptar'), size=9.5, fill='--amber',
           italic=True)
    # bus flows above
    f.box(cx, 50, 250, 34, [T('bus flows: farm lookup, collection summary', 'fluxos do barramento: fazenda, resumo')],
          size=10, stroke='--phosphor')
    f.arrow([(cx, 67), (cx, cy - 57)], stroke='--phosphor')
    f.text(cx + 8, 103, T('a facade already there', 'uma fachada que já existe'), size=9.5,
           fill='--phosphor', italic=True, anchor='start')
    # outputs
    outs = [(165, T('nightly file to SAP', 'arquivo noturno para o SAP')),
            (245, T('payment amounts to SAP', 'valores de pagamento ao SAP'))]
    for y, label in outs:
        f.box(615, y, 170, 34, [label], size=10, stroke='--paper-dim')
        f.arrow([(cx + 77, y), (528, y)], stroke='--paper-dim')
    f.text(615, 285, T('output contracts kept as they are', 'contratos de saída mantidos'),
           size=9.5, fill='--paper-dim', italic=True)
    # journal and CDC
    f.box(cx, 335, 120, 30, [T('journal', 'journal')], size=10, stroke='--paper-dim')
    f.arrow([(cx, cy + 57), (cx, 318)], stroke='--paper-dim')
    f.box(640, 335, 130, 30, [T('new side', 'lado novo')], size=10, stroke='--phosphor')
    f.arrow([(cx + 62, 335), (573, 335)], stroke='--phosphor')
    f.text(517, 322, T('change data capture', 'captura de mudanças'), size=9.5, fill='--phosphor',
           italic=True)
    return f, T('Coleta has no front door, so each flow is reached where it can be: files in their path, the bus flows at the bus, and the clerks\' typing only afterwards, from the journal.',
                'A Coleta não tem porta da frente, então cada fluxo é alcançado onde dá: os arquivos no caminho deles, os fluxos do barramento no barramento, e o que os funcionários digitam só depois, pelo journal.')


@figure('l13-acl', 13)
def acl():
    f = Fig('l13-acl', 720, 330, T(
        'Three columns. On the left, the new context: the collection service and the quality '
        'service, which speak the new model. In the middle, the anti-corruption layer, owned by the '
        'new team, with an inbound translator and an outbound translator. On the right, Coleta, '
        'with its journal and its 22:00 laboratory loader. Inbound, journal rows travel by change '
        'data capture to the inbound translator, which turns 0413275 into a farm with an opaque id, '
        '1261023 into 2026-10-23, 123450 into 1234.50 litres, and status S plus a remark into '
        'either suspended for quality or document pending, before they reach the new services. '
        'Outbound, laboratory results owned by the quality service go to the outbound translator, '
        'which writes them as a file in the laboratory\'s old layout, in thousands of cells per '
        'millilitre, for Coleta\'s loader. Anything the layer cannot classify goes to a queue for '
        'a person.',
        'Três colunas. À esquerda, o contexto novo: o serviço de coleta e o serviço de qualidade, '
        'que falam o modelo novo. No meio, a camada anticorrupção, do time novo, com um tradutor '
        'de entrada e um tradutor de saída. À direita, a Coleta, com o seu journal e o carregador '
        'de laboratório das 22:00. Na entrada, as linhas do journal viajam por captura de mudanças '
        'até o tradutor de entrada, que transforma 0413275 numa fazenda com id opaco, 1261023 em '
        '2026-10-23, 123450 em 1234,50 litros, e o status S mais uma observação em suspensa por '
        'qualidade ou documento pendente, antes de chegarem aos serviços novos. Na saída, os '
        'resultados de laboratório, cujo dono é o serviço de qualidade, vão ao tradutor de saída, '
        'que os grava como um arquivo no layout antigo do laboratório, em milhares de células por '
        'mililitro, para o carregador da Coleta. O que a camada não consegue classificar vai para '
        'uma fila, para uma pessoa olhar.'))
    f.text(100, 22, T('new context', 'contexto novo'), size=11.5, weight='600')
    f.text(360, 22, T('anti-corruption layer', 'camada anticorrupção'), size=11.5, weight='600')
    f.text(625, 22, 'Coleta', size=11.5, weight='600')
    f.rect(230, 36, 260, 262, stroke='--phosphor', fill='--ink', dash='5 4')
    f.box(100, 95, 160, 40, [T('collection service', 'serviço de coleta')], stroke='--phosphor')
    f.box(100, 225, 160, 40, [T('quality service', 'serviço de qualidade')], stroke='--phosphor')
    f.box(625, 95, 150, 40, ['journal'], stroke='--amber')
    f.box(625, 225, 150, 40, [T('22:00 lab loader', 'carregador das 22:00')], stroke='--amber')
    # inbound
    f.box(360, 95, 236, 92, [], stroke='--wire')
    f.text(360, 60, T('inbound translator', 'tradutor de entrada'), size=10, weight='600')
    for i, (a, b) in enumerate([('0413275', T('farm, opaque id', 'fazenda, id opaco')),
                                ('1261023', '2026-10-23'),
                                ('123450', T('1234.50 litres', '1234,50 litros')),
                                (T('S + remark', 'S + observação'), T('quality or document', 'qualidade ou documento'))]):
        y = 66 + 16 + i * 17
        f.text(252, y, a, size=9.5, mono=True, anchor='start')
        f.text(338, y, '→', size=9.5, fill='--paper-dim', anchor='start', mono=True)
        f.text(354, y, b, size=9.5, anchor='start', mono=b == '2026-10-23')
    f.arrow([(550, 95), (480, 95)], stroke='--amber')
    f.text(515, 84, 'CDC', size=9.5, fill='--paper-dim', mono=True)
    f.arrow([(242, 95), (182, 95)], stroke='--phosphor')
    # outbound
    f.box(360, 225, 200, 50, [T('outbound translator', 'tradutor de saída'),
                              T('cells per mL ÷ 1000, old layout', 'células por mL ÷ 1000, layout antigo')],
          size=10, stroke='--wire')
    f.arrow([(182, 225), (258, 225)], stroke='--phosphor')
    f.arrow([(462, 225), (548, 225)], stroke='--phosphor')
    f.text(520, 213, T('lab file', 'arquivo'), size=9.5, fill='--paper-dim')
    f.box(360, 166, 170, 24, [T('queue for a person', 'fila para uma pessoa')], size=9.5,
          stroke='--amber', dash='3 3')
    f.arrow([(360, 141), (360, 152)], stroke='--amber')
    f.text(360, 314, T('the legacy\'s formats appear here and nowhere else',
                       'os formatos do legado aparecem aqui e em nenhum outro lugar'),
           size=10.5, fill='--paper-dim', italic=True)
    return f, T('The layer belongs to the new side and translates in both directions: what Coleta knows becomes the new model\'s facts, and what the new side owns is written back in Coleta\'s own forms.',
                'A camada é do lado novo e traduz nas duas direções: o que a Coleta sabe vira fato no modelo novo, e o que o lado novo controla volta escrito nas formas da própria Coleta.')


@figure('l13-parallel', 13)
def parallel():
    f = Fig('l13-parallel', 720, 260, T(
        'The three months of the shadow calculation, one bar each, counting only the farms whose '
        'payment differed from Coleta\'s; the rest were identical to the centavo. July 2026: 1,871 '
        'identical and 29 different, made of 17 rounding, 9 from an unwritten rule and 3 from a '
        'defect on the new side. August: 1,897 identical and 3 different, all an accepted change '
        'of rule. September: 1,898 identical and 2 different, both the same accepted change.',
        'Os três meses do cálculo-sombra, uma barra por mês, contando só as fazendas cujo pagamento '
        'diferiu do da Coleta; as outras ficaram idênticas até o centavo. Julho de 2026: 1.871 '
        'idênticas e 29 diferentes, sendo 17 de arredondamento, 9 de uma regra não escrita e 3 de '
        'um defeito no lado novo. Agosto: 1.897 idênticas e 3 diferentes, todas uma mudança de '
        'regra aceita. Setembro: 1.898 idênticas e 2 diferentes, as duas a mesma mudança aceita.'))
    x0, unit = 200, 12
    months = [(T('July 2026', 'julho de 2026'), T('1,871 identical', '1.871 idênticas'),
               [(17, '--wire'), (9, '--amber'), (3, '--phosphor')]),
              (T('August 2026', 'agosto de 2026'), T('1,897 identical', '1.897 idênticas'),
               [(3, '--paper-dim')]),
              (T('September 2026', 'setembro de 2026'), T('1,898 identical', '1.898 idênticas'),
               [(2, '--paper-dim')])]
    for i, (m, ident, parts) in enumerate(months):
        y = 40 + i * 52
        f.text(x0 - 14, y - 7, m, size=10.5, anchor='end', weight='600')
        f.text(x0 - 14, y + 9, ident, size=10, anchor='end', fill='--paper-dim')
        x = x0
        for n, colour in parts:
            f.rect(x, y - 12, n * unit, 24, stroke='--paper-dim', fill=colour, rx=1, width=0.8)
            x += n * unit
        f.text(x + 10, y, T(f'{sum(n for n, _ in parts)} different',
                            f'{sum(n for n, _ in parts)} diferentes'), size=10.5, anchor='start')
    legend = [('--wire', T('17 rounding: a decision, not a defect', '17 arredondamento: uma decisão, não um defeito')),
              ('--amber', T('9 a rule written nowhere', '9 uma regra escrita em lugar nenhum')),
              ('--phosphor', T('3 a defect on the new side', '3 um defeito no lado novo')),
              ('--paper-dim', T('an accepted change of rule', 'uma mudança de regra aceita'))]
    for i, (colour, label) in enumerate(legend):
        lx = 40 + (i % 2) * 340
        ly = 205 + (i // 2) * 24
        f.rect(lx, ly - 7, 14, 14, stroke='--paper-dim', fill=colour, rx=1, width=0.8)
        f.text(lx + 22, ly, label, size=10, anchor='start')
    return f, T('Only the differences are drawn, because they are the point: each one was explained before the next month, and none was hidden behind a tolerance.',
                'Só as diferenças estão desenhadas, porque são elas que importam: cada uma foi explicada antes do mês seguinte, e nenhuma foi escondida atrás de uma tolerância.')
