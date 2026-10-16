from svg import Fig

# cdc: the app writes the log first; a copy by updated_at reads the table, a CDC reader the log.
c = Fig('cdc', 720, 264,
        caption=('The database writes each change to its log, then applies it to the table. A copy that '
                 'reads the table finds the rows that are there; a reader that follows the log also '
                 'finds the one that was deleted.',
                 'O banco escreve cada mudança no seu log e depois a aplica na tabela. Uma cópia que lê a '
                 'tabela encontra as linhas que estão lá; um leitor que segue o log encontra também a '
                 'que foi apagada.'),
        label=('The app writes to the database. Inside it, the log holds three numbered changes: an '
               'update of R000103, an insert of R000105 and a delete of R000104; the rides table holds '
               'the result, four rides without R000104. A copy by updated_at reads the table and finds '
               'R000103 and R000105 but cannot see the delete. A CDC reader reads the log and gets all '
               'three changes in order.',
               'O aplicativo escreve no banco. Dentro dele, o log guarda três mudanças numeradas: uma '
               'atualização de R000103, uma inserção de R000105 e uma remoção de R000104; a tabela de '
               'viagens guarda o resultado, quatro viagens sem R000104. Uma cópia por updated_at lê a '
               'tabela e encontra R000103 e R000105, mas não vê a remoção. Um leitor de CDC lê o log e '
               'recebe as três mudanças em ordem.'))
c.rect(152, 14, 286, 240, fill='ink', stroke='phosphor', dash='5 4')
c.text(295, 30, ('the database', 'o banco de dados'), size=11.5, color='phosphor', weight='600')
c.box(14, 181, 116, 46, ('the app', 'o aplicativo'), size=10.5)
c.arrow(130, 204, 168, 204)
c.box(170, 44, 250, 102, ['R000101  finished', 'R000102  finished', 'R000103  finished',
                          'R000105  open'],
      title=('the rides table', 'a tabela de viagens'), mono=True, size=10)
c.box(170, 166, 250, 76, ['1  update  R000103', '2  insert  R000105', '3  delete  R000104'],
      title=('its log, written first', 'o log, escrito antes'), stroke='phosphor', mono=True, size=10)
c.arrow(295, 166, 295, 148)
c.arrow(420, 94, 474, 94)
c.box(476, 54, 230, 80, [('finds R000103 and R000105', 'acha R000103 e R000105'),
                         ('R000104 is simply gone', 'R000104 simplesmente sumiu')],
      title=('a copy by updated_at', 'uma cópia por updated_at'), stroke='amber', size=10.5)
c.arrow(420, 204, 474, 204)
c.box(476, 166, 230, 76, [('reads changes 1, 2 and 3', 'lê as mudanças 1, 2 e 3'),
                          ('the delete included', 'a remoção inclusive')],
      title=('a CDC reader', 'um leitor de CDC'), stroke='phosphor', size=10.5)

# drop: two writers, two checks by a reader.
d = Fig('drop', 720, 244,
        caption=('At the first check the two exports cannot be told apart: each has left part of a file '
                 'and no manifest. Only the export that finishes ever writes the marker.',
                 'Na primeira verificação as duas exportações não se distinguem: cada uma deixou parte '
                 'de um arquivo e nenhum manifesto. Só a exportação que termina escreve o marcador.'),
        label=('A timeline of two exports. The first writes rides.csv and then manifest.json. The '
               'second writes part of rides.csv and stops. A reader checks twice: the first time both '
               'show some rows and no manifest; the second time only the first has a manifest.',
               'Uma linha do tempo de duas exportações. A primeira escreve rides.csv e depois '
               'manifest.json. A segunda escreve parte de rides.csv e para. Um leitor verifica duas '
               'vezes: na primeira, as duas mostram algumas linhas e nenhum manifesto; na segunda, só a '
               'primeira tem manifesto.'))
d.text(130, 34, ('the export that finishes', 'a exportação que termina'), anchor='start', size=10.5,
       weight='600')
d.rect(130, 44, 330, 24, stroke='phosphor')
d.text(140, 56, ('rides.csv, growing', 'rides.csv, crescendo'), anchor='start', size=10.5)
d.box(480, 44, 140, 24, 'manifest.json', stroke='phosphor', mono=True, size=10)
d.text(130, 100, ('the export that dies', 'a exportação que morre'), anchor='start', size=10.5,
       weight='600')
d.rect(130, 110, 200, 24, stroke='wire')
d.text(140, 122, ('rides.csv, growing', 'rides.csv, crescendo'), anchor='start', size=10.5)
d.box(340, 110, 120, 24, ('the writer stops', 'o escritor para'), stroke='amber', size=10.5)
d.line(290, 24, 290, 160, color='paper-dim', dash='4 3')
d.line(650, 24, 650, 160, color='paper-dim', dash='4 3')
d.text(290, 176, ('first check', 'primeira verificação'), size=10.5, weight='600')
d.text(290, 192, ('both: some rows, no manifest', 'as duas: algumas linhas, sem manifesto'),
       size=10.5)
d.text(706, 176, ('second check', 'segunda verificação'), anchor='end', size=10.5, weight='600')
d.text(706, 192, ('one has a manifest, one never will', 'uma tem manifesto, a outra nunca terá'), anchor='end',
       size=10.5)
d.arrow(130, 224, 700, 224)
d.text(122, 224, ('time', 'tempo'), anchor='end', size=10.5)

FIGURES = [c, d]
