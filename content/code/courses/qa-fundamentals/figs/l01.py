# lesson 1

@figure('l01-two-halves', 1)
def l01_two_halves(lang):
    t = {
        'en': dict(stages=['idea', 'requirement', 'design', 'code', 'release', 'in use'],
                   prev='prevent', det='detect',
                   pitems=['read it for a', 'second meaning', 'review the', 'design', 'review the', 'change'],
                   ditems=['run it with', 'chosen inputs', 'check the', 'release', 'watch it', 'in production'],
                   static='static: nothing runs', dynamic='dynamic: the program runs',
                   label='A row of six stages from left to right: idea, requirement, design, code, release, in use. '
                         'Above the requirement, design and code stages sits a band labelled prevent, with three '
                         'activities: read the requirement for a second meaning, review the design, review the change; '
                         'nothing runs. Below the code, release and in-use stages sits a band labelled detect, with '
                         'three activities: run it with chosen inputs, check the release, watch it in production; the '
                         'program runs. The two bands overlap at the code stage.',
                   cap='Prevention works on what is being planned and written, before there is anything to run. '
                       'Detection needs something to run, so it starts at the code and never ends.'),
        'pt': dict(stages=['ideia', 'requisito', 'projeto', 'código', 'entrega', 'em uso'],
                   prev='prevenir', det='detectar',
                   pitems=['ler buscando um', 'segundo sentido', 'revisar o', 'projeto', 'revisar a', 'mudança'],
                   ditems=['rodar com entradas', 'escolhidas', 'verificar a', 'entrega', 'observar em', 'produção'],
                   static='estático: nada roda', dynamic='dinâmico: o programa roda',
                   label='Uma fila de seis etapas da esquerda para a direita: ideia, requisito, projeto, código, entrega, '
                         'em uso. Acima das etapas requisito, projeto e código fica uma faixa chamada prevenir, com três '
                         'atividades: ler o requisito buscando um segundo sentido, revisar o projeto, revisar a mudança; '
                         'nada roda. Abaixo das etapas código, entrega e em uso fica uma faixa chamada detectar, com três '
                         'atividades: rodar com entradas escolhidas, verificar a entrega, observar em produção; o '
                         'programa roda. As duas faixas se sobrepõem na etapa código.',
                   cap='A prevenção trabalha no que está sendo planejado e escrito, antes de haver algo para rodar. A '
                       'detecção precisa de algo que rode, então começa no código e nunca termina.'),
    }[lang]
    f = Fig('l01-two-halves', 680, 300, t['label'])
    x0, w, gap = 20, 100, 8
    ys = 128
    for i, s in enumerate(t['stages']):
        x = x0 + i * (w + gap)
        box(f, x, ys, w, 40, [s], stroke='--paper-dim', size=11, weights=['600'])
        if i:
            arrow(f, x - gap + 1, ys + 20, x - 1, ys + 20)
    # prevent band over stages 1..3
    px = x0 + 1 * (w + gap)
    pw = 3 * w + 2 * gap
    f.rect(px, 22, pw, 92, stroke='--phosphor', fill='--panel', width=1.6)
    f.text(px + 8, 36, t['prev'], size=11, anchor='start', weight='600', fill='--phosphor')
    f.text(px + pw - 8, 36, t['static'], size=9.5, anchor='end', fill='--paper-dim')
    for k in range(3):
        cx = px + k * (w + gap) + w / 2
        f.text(cx, 66, t['pitems'][2 * k], size=9.5)
        f.text(cx, 80, t['pitems'][2 * k + 1], size=9.5)
        f.line(cx, 92, cx, ys - 2, stroke='--phosphor', width=1.2, dash='3 3')
    # detect band under stages 3..5
    dx = x0 + 3 * (w + gap)
    f.rect(dx, 182, pw, 92, stroke='--amber', fill='--panel', width=1.6)
    f.text(dx + 8, 260, t['det'], size=11, anchor='start', weight='600', fill='--amber')
    f.text(dx + pw - 8, 260, t['dynamic'], size=9.5, anchor='end', fill='--paper-dim')
    for k in range(3):
        cx = dx + k * (w + gap) + w / 2
        f.text(cx, 214, t['ditems'][2 * k], size=9.5)
        f.text(cx, 228, t['ditems'][2 * k + 1], size=9.5)
        f.line(cx, ys + 42, cx, 200, stroke='--amber', width=1.2, dash='3 3')
    return f, t['cap']
