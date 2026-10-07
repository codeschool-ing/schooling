# Lesson 20 — the tools.


@figure('l20-landscape', 20)
def l20_landscape(lang):
    w = {'en': dict(
        label='Four families of tool placed on two axes: across, how much of the chart you can '
              'control; up, how quickly a first chart appears. Spreadsheets sit top left: a first '
              'chart in seconds, limited control. BI tools such as Power BI and Tableau sit a little '
              'lower and further right. Plotting libraries such as matplotlib sit lower and further '
              'right again. D3.js sits bottom right: complete control and the slowest start.',
        x='how much of the chart you can control →', y='↑ how fast a first chart appears',
        names=('spreadsheets', 'BI tools', 'plotting libraries', 'D3.js'),
        eg=('Excel, LibreOffice Calc', 'Power BI, Tableau', 'matplotlib, ggplot2', 'web graphics'),
        note='positions are this lesson\'s judgement, not a measurement',
        cap='No tool is best at both. The ones that give a chart in seconds decide most of it for '
            'you; the ones that let you decide everything make you decide everything.'),
        'pt': dict(
        label='Quatro famílias de ferramenta postas em dois eixos: na horizontal, quanto do gráfico '
              'você controla; na vertical, quão rápido sai um primeiro gráfico. As planilhas ficam '
              'no alto à esquerda: um primeiro gráfico em segundos, pouco controle. As ferramentas '
              'de BI, como Power BI e Tableau, ficam um pouco abaixo e mais à direita. As '
              'bibliotecas de gráficos, como o matplotlib, ficam mais abaixo e mais à direita. O '
              'D3.js fica embaixo à direita: controle total e o começo mais lento.',
        x='quanto do gráfico você controla →', y='↑ quão rápido sai um primeiro gráfico',
        names=('planilhas', 'ferramentas de BI', 'bibliotecas de gráficos', 'D3.js'),
        eg=('Excel, LibreOffice Calc', 'Power BI, Tableau', 'matplotlib, ggplot2', 'gráficos web'),
        note='as posições são o julgamento desta aula, não uma medida',
        cap='Nenhuma ferramenta é a melhor nas duas coisas. As que dão um gráfico em segundos decidem '
            'quase tudo por você; as que deixam você decidir tudo fazem você decidir tudo.')}[lang]
    f = Fig('l20-landscape', 600, 300, w['label'])
    x0, y0, x1, y1 = 60, 36, 580, 250
    f.line(x0, y1, x1, y1, stroke='--paper-dim', width=1.2)
    f.line(x0, y0, x0, y1, stroke='--paper-dim', width=1.2)
    f.text(x1, y1 + 16, w['x'], size=9.5, anchor='end', fill='--paper-dim')
    f.text(x0 + 8, 20, w['y'], size=9.5, anchor='start', fill='--paper-dim')
    pts = [(130, 66), (260, 112), (390, 166), (510, 218)]
    for (x, y), n, e in zip(pts, w['names'], w['eg']):
        f.circle(x, y, 7, fill='--phosphor')
        f.text(x + 12, y - 4, n, size=10.5, anchor='start', weight='600')
        f.text(x + 12, y + 11, e, size=9, anchor='start', fill='--paper-dim')
    f.text(x1, 286, w['note'], size=9, anchor='end', fill='--paper-dim', italic=True)
    return f, w['cap']


@figure('l20-reproducible', 20)
def l20_reproducible(lang):
    w = {'en': dict(
        label='Two paths from a data file to a chart. Above, through clicks in a spreadsheet: the '
              'steps live in somebody\'s memory, and next month\'s chart is made by repeating them. '
              'Below, through a script: the steps are written in a file, and next month\'s chart is '
              'made by running it again on the new data.',
        data='monthly.csv', clicks='twelve clicks, remembered', script='chart.py, saved',
        chart='chart', again='next month: repeat the clicks', again2='next month: run it again',
        cap='The question is not which tool draws better but where the steps live. A step that is '
            'written down can be read, reviewed and run again; a step that is remembered gets done '
            'slightly differently each time.'),
        'pt': dict(
        label='Dois caminhos de um arquivo de dados até um gráfico. Em cima, por cliques numa '
              'planilha: os passos ficam na memória de alguém, e o gráfico do mês que vem é feito '
              'repetindo-os. Embaixo, por um script: os passos estão escritos num arquivo, e o '
              'gráfico do mês que vem é feito rodando-o de novo sobre o dado novo.',
        data='monthly.csv', clicks='doze cliques, de memória', script='chart.py, salvo',
        chart='gráfico', again='mês que vem: repetir os cliques', again2='mês que vem: rodar de novo',
        cap='A pergunta não é que ferramenta desenha melhor, mas onde os passos moram. Um passo '
            'escrito pode ser lido, revisado e rodado de novo; um passo lembrado sai um pouco '
            'diferente a cada vez.')}[lang]
    f = Fig('l20-reproducible', 620, 230, w['label'])
    for row, (mid, again, col) in enumerate(((w['clicks'], w['again'], '--amber'),
                                             (w['script'], w['again2'], '--phosphor'))):
        y = 40 + row * 110
        f.rect(20, y, 120, 40, stroke='--wire', fill='--panel', rx=4, width=1)
        f.text(80, y + 20, w['data'], size=10, mono=True)
        f.rect(230, y, 160, 40, stroke=col, fill='--panel', rx=4, width=1.5)
        f.text(310, y + 20, mid, size=10, mono=row == 1)
        f.rect(480, y, 120, 40, stroke='--wire', fill='--panel', rx=4, width=1)
        f.text(540, y + 20, w['chart'], size=10)
        f.line(140, y + 20, 228, y + 20, stroke='--paper-dim', width=1.4, arrow=True)
        f.line(390, y + 20, 478, y + 20, stroke='--paper-dim', width=1.4, arrow=True)
        f.text(310, y + 58, again, size=9.5, fill=col, weight='600')
    return f, w['cap']


@figure('l20-fixes', 20)
def l20_fixes(lang):
    cats = sorted(H.CATEGORIES.items(), key=lambda kv: -kv[1])
    w = {'en': dict(
        label='A bar chart of revenue by category with five numbered changes marked on it, the '
              'changes this course would make in any tool: 1, a title that states the finding; 2, '
              'the bars sorted from largest to smallest; 3, the axis starting at zero; 4, values on '
              'the bars instead of a grid; 5, one colour, with the bar that matters picked out.',
        title='Vegetables and fruit bring in two-fifths of revenue',
        notes=('a claim in the title', 'sorted', 'from zero', 'values, no grid',
               'one colour, one highlight'),
        cap='Five changes that every tool in this lesson can make, in a menu or in a line of code. '
            'The defaults differ from tool to tool; the list does not.'),
        'pt': dict(
        label='Um gráfico de barras da receita por categoria com cinco mudanças numeradas marcadas '
              'nele, as mudanças que este curso faria em qualquer ferramenta: 1, um título que diz o '
              'achado; 2, as barras ordenadas da maior para a menor; 3, o eixo começando no zero; 4, '
              'valores nas barras em vez de grade; 5, uma cor, com a barra que importa destacada.',
        title='Verduras e frutas trazem dois quintos da receita',
        notes=('uma afirmação no título', 'ordenado', 'a partir do zero', 'valores, sem grade',
               'uma cor, um destaque'),
        cap='Cinco mudanças que toda ferramenta desta aula consegue fazer, num menu ou numa linha de '
            'código. Os padrões mudam de ferramenta para ferramenta; a lista não.')}[lang]
    f = Fig('l20-fixes', 620, 270, w['label'])
    f.text(110, 20, w['title'], size=11.5, anchor='start', weight='600')
    p = Plot(f, 110, 44, 400, 44 + 6 * 34, 0, 450, 0, 6)
    f.line(p.x0, p.y0 - 4, p.x0, p.y1 + 4, stroke='--paper-dim', width=1.4)
    for i, (n, v) in enumerate(cats):
        y = 50 + i * 34
        hi = i < 2
        f.bar(p.x0, y, p.sx(v) - p.x0, 22, stroke='--phosphor' if hi else '--paper-dim',
              fill='--phosphor-dim' if hi else '--scan')
        f.text(p.x0 - 8, y + 11, CATEGORY[lang][n], size=9.5, anchor='end')
        f.text(p.sx(v) + 6, y + 11, str(v), size=9, anchor='start', mono=True)
    marks = [(92, 20), (30, 150), (110, 262), (p.sx(412) + 40, 61), (p.sx(386) + 40, 95)]
    for k, ((x, y), note) in enumerate(zip(marks, w['notes'])):
        f.circle(x, y, 9, fill='--amber')
        f.text(x, y, str(k + 1), size=9.5, weight='600', fill='#ffffff')
    for k, note in enumerate(w['notes']):
        f.text(470, 70 + k * 30, f'{k + 1}  {note}', size=10, anchor='start', fill='--amber')
    return f, w['cap']


@image('l20-workspace.svg', 20)
def l20_workspace_image():
    f = Fig('l20-workspace-image', 600, 340,
            'The window of a drag-and-drop chart tool with no words: a narrow pane on the left '
            'holding a list of short strokes with small icons, a strip across the top with a box '
            'holding a funnel shape, a large canvas in the middle with a bar chart on it, and a pane '
            'on the right holding rows of sliders and colour swatches.')
    f.rect(10, 10, 580, 320, stroke='--paper-dim', fill='--panel', rx=6, width=2)
    f.rect(20, 50, 130, 270, stroke='--wire', fill='--scan', rx=3, width=1)
    for i in range(8):
        y = 64 + i * 28
        f.rect(30, y, 12, 12, stroke='--phosphor', fill='--phosphor-dim', rx=2, width=1)
        f.rect(50, y + 2, 70 - (i % 3) * 12, 8, stroke='--wire', fill='--wire', rx=2, width=1)
    f.rect(160, 18, 280, 26, stroke='--wire', fill='--scan', rx=3, width=1)
    f.rect(170, 22, 96, 18, stroke='--paper-dim', fill='--panel', rx=3, width=1)
    f.path('M178 26 L198 26 L190 34 L190 38 L186 38 L186 34 Z', stroke='--paper-dim',
           fill='--paper-dim', width=1)
    f.rect(204, 28, 54, 6, stroke='--wire', fill='--wire', rx=2, width=1)
    f.rect(160, 50, 280, 270, stroke='--wire', fill='--panel', rx=3, width=1)
    for i, v in enumerate((412, 386, 351, 298, 274, 239)):
        f.bar(190, 80 + i * 36, 220 * v / 412, 24)
    f.rect(450, 50, 130, 270, stroke='--wire', fill='--scan', rx=3, width=1)
    for i in range(4):
        y = 70 + i * 34
        f.line(462, y, 568, y, stroke='--paper-dim', width=2)
        f.circle(480 + i * 22, y, 6, fill='--phosphor')
    for i, c in enumerate(('#E69F00', '#56B4E9', '#009E73', '#2b52c9')):
        f.rect(462 + i * 28, 230, 20, 20, stroke='--wire', fill=c, rx=2, width=1)
    return f
