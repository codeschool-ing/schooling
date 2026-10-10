from svg import Fig

# one-question: three sources, the engineer's half, the tables, two readers.
f = Fig('one-question', 720, 260,
        caption=('Three systems built for other purposes, one engineer who makes them answerable, '
                 'and two people who ask the questions.',
                 'Três sistemas feitos para outros fins, um engenheiro que os torna consultáveis, '
                 'e duas pessoas que fazem as perguntas.'),
        label=('The app database, the dock sensors and the maintenance spreadsheet feed the data '
               'engineer, who copies, keeps, puts on one clock and checks them every day, producing '
               'tables. An analyst reads the tables to answer which stations ran out; a data '
               'scientist reads them to predict which will run out next.',
               'O banco do aplicativo, os sensores das docas e a planilha de manutenção alimentam o '
               'engenheiro de dados, que copia, guarda, põe num só relógio e confere tudo todo dia, '
               'produzindo tabelas. Um analista lê as tabelas para responder quais estações '
               'esvaziaram; o cientista de dados as lê para prever quais vão esvaziar.'))
# the engineer's region
f.rect(178, 14, 362, 232, fill='ink', stroke='phosphor', dash='5 4')
f.text(359, 32, ('the data engineer’s half', 'a metade do engenheiro de dados'),
       size=11.5, color='phosphor', weight='600')
# sources
for i, (en, pt) in enumerate([('the app database', 'o banco do aplicativo'),
                              ('the dock sensors', 'os sensores das docas'),
                              ('the maintenance sheet', 'a planilha de manutenção')]):
    y = 46 + i * 66
    f.box(14, y, 146, 46, (en, pt), size=10.5)
    f.arrow(160, y + 23, 196, 130)
# the work
f.box(198, 56, 160, 148, [('copy it out', 'copiar para fora'),
                          ('keep it longer', 'guardar por mais tempo'),
                          ('one clock', 'um só relógio'),
                          ('one place', 'um só lugar'),
                          ('check it daily', 'conferir todo dia')],
      title=('the pipeline', 'o pipeline'), stroke='phosphor', size=10.5)
f.arrow(358, 130, 386, 130)
f.box(388, 92, 136, 76, [('rides, docks,', 'viagens, docas,'), ('repairs', 'consertos')],
      title=('tables', 'tabelas'), size=10.5)
f.arrow(524, 116, 562, 82)
f.arrow(524, 144, 562, 178)
f.box(564, 50, 144, 62, [('which stations', 'quais estações'), ('ran out?', 'esvaziaram?')],
      title=('an analyst', 'um analista'), stroke='amber', size=10.5)
f.box(564, 148, 144, 62, [('which will run', 'quais vão'), ('out on Friday?', 'esvaziar na sexta?')],
      title=('the data scientist', 'o cientista de dados'), stroke='amber', size=10.5)

FIGURES = [f]
