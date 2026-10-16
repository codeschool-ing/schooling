from svg import Fig

# ---- rows-columns: the same three rides laid out in rows and in columns
RIDES = [('R000001', 'ST08', '06:01', '5'),
         ('R000002', 'ST12', '06:02', '23'),
         ('R000003', 'ST04', '06:03', '58')]

rc = Fig('rows-columns', 720, 262,
         caption=('The same three rides, twelve values, in the two layouts. To read minutes, a row '
                  'file is visited in three places; a columnar file in one.',
                  'As mesmas três viagens, doze valores, nos dois arranjos. Para ler minutes, um '
                  'arquivo de linhas é visitado em três lugares; um colunar, em um só.'),
         label=('Two strips of twelve cells. In the row-oriented strip each ride’s four values sit '
                'together, so the three minutes values are scattered. In the column-oriented strip '
                'all ride ids, then all stations, then all times, then all minutes sit together, so '
                'the three minutes values form one run.',
                'Duas faixas de doze células. Na faixa orientada a linhas os quatro valores de cada '
                'viagem ficam juntos, e os três valores de minutes ficam espalhados. Na faixa '
                'orientada a colunas ficam juntos todos os ids, depois todas as estações, todos os '
                'horários e todos os minutos, e os três valores de minutes formam uma sequência só.'))

X0, W = 40, 53


def strip(y, cells, groups, size, title, note):
    rc.text(X0, y - 16, title, size=11.5, anchor='start', weight='600')
    for i, (v, hot) in enumerate(cells):
        x = X0 + i * W
        rc.rect(x, y, W - 3, 32, stroke='amber' if hot else 'wire', sw=2 if hot else 1.5)
        rc.text(x + (W - 3) / 2, y + 16, v, size=10, mono=True)
    for g, lab in enumerate(groups):
        x1 = X0 + g * size * W
        x2 = x1 + size * W - 3
        rc.line(x1, y + 40, x2, y + 40, color='paper-dim', sw=1)
        rc.text((x1 + x2) / 2, y + 52, lab, size=10, mono=isinstance(lab, str))
    rc.text(X0, y + 74, note, size=10.5, anchor='start', color='amber')


row_cells = [(v, j == 3) for r in RIDES for j, v in enumerate(r)]
strip(42, row_cells, [('ride 1', 'viagem 1'), ('ride 2', 'viagem 2'), ('ride 3', 'viagem 3')], 4,
      ('row-oriented: CSV, JSON Lines, Avro', 'orientado a linhas: CSV, JSON Lines, Avro'),
      ('reading minutes visits three places', 'ler minutes visita três lugares'))
col_cells = [(RIDES[i][j], j == 3) for j in range(4) for i in range(3)]
strip(166, col_cells, ['ride_id', 'start_station', 'started_at', 'minutes'], 3,
      ('column-oriented: Parquet, ORC', 'orientado a colunas: Parquet, ORC'),
      ('reading minutes visits one run', 'ler minutes visita uma sequência só'))

# ---- parquet-file: row groups, column chunks, footer, and a query that reads two chunks
pf = Fig('parquet-file', 720, 400,
         caption=('A Parquet file is read from the end. The footer’s statistics rule out groups 0 '
                  'and 1, and the question reads two column chunks of group 2.',
                  'Um arquivo Parquet é lido a partir do fim. As estatísticas do rodapé descartam os '
                  'grupos 0 e 1, e a pergunta lê dois pedaços de coluna do grupo 2.'),
         label=('A Parquet file drawn top to bottom: the magic bytes PAR1, three row groups each holding '
                'one column chunk per column, then the footer with the schema, where each chunk is, its '
                'encodings, compression and statistics, then PAR1 again. A reader asking for the '
                'average minutes of rides after 25 September reads the footer first, skips groups 0 and '
                '1, and reads only the started_at and minutes chunks of group 2.',
                'Um arquivo Parquet desenhado de cima para baixo: os bytes mágicos PAR1, três grupos de '
                'linhas, cada um com um pedaço por coluna, depois o rodapé com o esquema, onde está cada '
                'pedaço, suas codificações, compressão e estatísticas, e PAR1 de novo. Um leitor que '
                'pede a média de minutes das viagens depois de 25 de setembro lê o rodapé primeiro, '
                'pula os grupos 0 e 1 e lê só os pedaços started_at e minutes do grupo 2.'))
LX, LW = 20, 420
pf.box(LX, 14, 70, 24, 'PAR1', mono=True, size=10)
CH = ['ride_id', 'start_station', 'started_at', 'minutes', '…']
GROUPS = [(('row group 0', 'grupo de linhas 0'), ('01–12 Sep', '01–12 set'), False),
          (('row group 1', 'grupo de linhas 1'), ('12–24 Sep', '12–24 set'), False),
          (('row group 2', 'grupo de linhas 2'), ('24–30 Sep', '24–30 set'), True)]
for g, (name, dates, hot) in enumerate(GROUPS):
    y = 50 + g * 72
    pf.rect(LX, y, LW, 62, fill='ink', stroke='phosphor' if hot else 'wire', dash=None if hot else '4 3')
    pf.text(LX + 10, y + 12, name, size=10.5, anchor='start', weight='600')
    pf.text(LX + LW - 10, y + 12, dates, size=10, anchor='end', color='paper-dim')
    for c, col in enumerate(CH):
        cx = LX + 10 + c * 84
        w = 80 if col != '…' else 60
        use = hot and col in ('started_at', 'minutes')
        pf.box(cx, y + 24, w, 30, col, mono=col != '…', size=9,
               stroke='amber' if use else 'wire')
fy = 50 + 3 * 72
pf.box(LX, fy, LW, 76, [('the schema; for every column chunk where it starts,', 'o esquema; para cada pedaço de coluna, onde começa,'),
                        ('its encodings and compression, and its statistics:', 'suas codificações e compressão, e suas estatísticas:'),
                        ('min, max and the count of nulls', 'mínimo, máximo e a contagem de nulos')],
       title=('footer', 'rodapé'), stroke='phosphor', size=10)
pf.box(LX, fy + 86, 70, 24, 'PAR1', mono=True, size=10)
# the reader's three steps, on the right
RX, RW = 478, 228
steps = [(fy + 18, ('1. read the footer first;', '1. lê o rodapé primeiro;'),
          ('the last bytes give its length', 'os últimos bytes dão o tamanho')),
         (86, ('2. statistics: groups 0 and 1', '2. estatísticas: os grupos 0 e 1'),
          ('end before 25 Sep, so skip', 'terminam antes de 25 set: pula')),
         (229, ('3. read started_at and', '3. lê started_at e minutes'),
          ('minutes of group 2 only', 'só do grupo 2'))]
for y, a, b in steps:
    pf.box(RX, y - 20, RW, 42, [a, b], size=10, stroke='amber')
pf.arrow(RX, fy + 18, LX + LW + 2, fy + 18, color='amber')
pf.arrow(RX, 86, LX + LW + 2, 86, color='amber')
pf.arrow(RX, 229, LX + LW + 2, 229, color='amber')
pf.line(LX + LW + 2, 86, LX + LW + 2, 158, color='amber', sw=1)

# ---- avro-file: header with schema and sync marker, then blocks ending in the marker
af = Fig('avro-file', 720, 238,
         caption=('An Avro container file: the schema once in the header, then blocks of records, '
                  'each ending in the same sync marker.',
                  'Um arquivo contêiner Avro: o esquema uma vez no cabeçalho, depois blocos de '
                  'registros, cada um terminando no mesmo marcador de sincronia.'),
         label=('An Avro file drawn as three rows. The header holds the magic bytes Obj and 1, the '
                'metadata with avro.schema and avro.codec, and a 16-byte sync marker. Each block holds '
                'a count of records, its size in bytes, the records with their values in schema order '
                'and no field names, and the sync marker again, which lets a reader that starts in the '
                'middle of the file find the next block.',
                'Um arquivo Avro desenhado em três faixas. O cabeçalho tem os bytes mágicos Obj e 1, os '
                'metadados com avro.schema e avro.codec, e um marcador de sincronia de 16 bytes. Cada '
                'bloco tem a contagem de registros, o tamanho em bytes, os registros com os valores na '
                'ordem do esquema e sem nomes de campos, e o marcador de novo, que deixa um leitor que '
                'começa no meio do arquivo achar o próximo bloco.'))
AX = 112


def lane(y, title, cells):
    af.text(20, y + 17, title, size=11, anchor='start', weight='600')
    x = AX
    for w, lab, stroke, mono in cells:
        af.box(x, y, w, 34, lab, size=10, stroke=stroke, mono=mono)
        x += w + 6


SYNC = (86, ('sync marker', 'marcador'), 'phosphor', False)
lane(20, ('header', 'cabeçalho'),
     [(70, 'Obj 1', 'wire', True), (180, 'avro.schema: {…}', 'amber', True),
      (130, 'avro.codec: null', 'wire', True), SYNC])
REC = (64, ('ride', 'viagem'), 'wire', False)
lane(88, ('block 1', 'bloco 1'),
     [(70, ('count', 'contagem'), 'wire', False), (64, ('size', 'tamanho'), 'wire', False),
      REC, REC, REC, (40, '…', 'wire', False), SYNC])
lane(156, ('block 2', 'bloco 2'),
     [(70, ('count', 'contagem'), 'wire', False), (64, ('size', 'tamanho'), 'wire', False),
      REC, REC, REC, (40, '…', 'wire', False), SYNC])
af.text(AX, 136, ('a ride: its values in schema order, no names', 'uma viagem: os valores na ordem do esquema, sem nomes'),
        size=10, anchor='start', color='amber')
af.text(AX, 210, ('the same marker after every block: a reader that starts mid-file scans to the next one',
                  'o mesmo marcador depois de cada bloco: quem começa no meio do arquivo avança até o próximo'),
        size=10, anchor='start', color='phosphor')

FIGURES = [rc, pf, af]
