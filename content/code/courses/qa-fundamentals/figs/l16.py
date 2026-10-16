# lesson 16

@figure('l16-three', 16)
def l16_three(lang):
    t = {
        'en': dict(steps=[('discovery', 'talk through examples', 'Joana, Rafael, Lia'),
                          ('formulation', 'write the ones that matter', 'Lia, read back by Joana'),
                          ('automation', 'wire them to the code', 'Rafael, with Lia')],
                   outs=['questions answered', 'a feature file', 'scenarios that run daily'],
                   value='most of the value', label='Three BDD practices in order, left to right. Discovery: talk '
                   'through examples; Joana, Rafael and Lia; it produces questions answered, and most of the value. '
                   'Formulation: write the ones that matter; Lia, read back by Joana; it produces a feature file. '
                   'Automation: wire them to the code; Rafael, with Lia; it produces scenarios that run daily.',
                   cap='Discovery, formulation, automation. A team that only automates has a test tool with an unusual '
                       'syntax.'),
        'pt': dict(steps=[('descoberta', 'conversar sobre exemplos', 'Joana, Rafael, Lia'),
                          ('formulação', 'escrever os que importam', 'Lia, relido pela Joana'),
                          ('automação', 'ligá-los ao código', 'Rafael, com a Lia')],
                   outs=['perguntas respondidas', 'um arquivo de feature', 'cenários que rodam todo dia'],
                   value='a maior parte do valor', label='Três práticas do BDD em ordem, da esquerda para a direita. '
                   'Descoberta: conversar sobre exemplos; Joana, Rafael e Lia; produz perguntas respondidas, e a maior '
                   'parte do valor. Formulação: escrever os que importam; Lia, relido pela Joana; produz um arquivo de '
                   'feature. Automação: ligá-los ao código; Rafael, com a Lia; produz cenários que rodam todo dia.',
                   cap='Descoberta, formulação, automação. Um time que só automatiza tem uma ferramenta de teste com '
                       'uma sintaxe diferente.'),
    }[lang]
    f = Fig('l16-three', 660, 200, t['label'])
    for i, ((name, what, who), out) in enumerate(zip(t['steps'], t['outs'])):
        x = 10 + i * 220
        box(f, x, 20, 190, 76, [name, what, who], size=10, weights=['600', None, None],
            fills=['--amber' if i == 0 else '--paper', '--paper', '--paper-dim'],
            stroke='--amber' if i == 0 else '--wire', width=1.6 if i == 0 else 1.2)
        if i < 2:
            arrow(f, x + 192, 58, x + 218, 58)
        f.line(x + 95, 98, x + 95, 122, stroke='--paper-dim', width=1)
        box(f, x + 10, 124, 170, 32, [out], size=9.5, fill='--ink')
    f.text(105, 178, t['value'], size=9.5, weight='600', fill='--amber')
    return f, t['cap']
