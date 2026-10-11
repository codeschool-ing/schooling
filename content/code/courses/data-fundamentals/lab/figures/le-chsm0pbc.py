from svg import Fig


def code(fig, x, y, line, size, **kw):
    """A left-aligned mono line. SVG collapses leading spaces, so the indent is
    drawn as an offset: IBM Plex Mono advances 0.6 em per character."""
    pad = len(line) - len(line.lstrip(' '))
    fig.text(round(x + pad * 0.6 * size, 1), y, line.lstrip(' '), size=size, mono=True,
             anchor='start', **kw)


# three-shapes: one ride, three shapes, and where each one keeps its schema.
f = Fig('three-shapes', 720, 290,
        caption=('The same ride three times. What changes is where the names and types are kept: '
                 'in the table, in every record, or nowhere.',
                 'A mesma viagem três vezes. O que muda é onde ficam os nomes e os tipos: na tabela, '
                 'em cada registro, ou em lugar nenhum.'),
        label=('Three panels. Structured: a table whose header declares ride_id, station and minutes '
               'with their types, and one row under it. Semi-structured: a JSON event in which the '
               'names sit beside the values and bike is nested. Unstructured: an email whose body is '
               'a sentence, with structured metadata above it: customer, time and one attachment.',
               'Três painéis. Estruturado: uma tabela cujo cabeçalho declara ride_id, station e '
               'minutes com seus tipos, e uma linha embaixo. Semiestruturado: um evento JSON em que os '
               'nomes ficam ao lado dos valores e bike está aninhado. Não estruturado: um e-mail cujo '
               'corpo é uma frase, com metadados estruturados acima: cliente, hora e um anexo.'))
cols = [(14, ('structured', 'estruturado')),
        (249, ('semi-structured', 'semiestruturado')),
        (484, ('unstructured', 'não estruturado'))]
for x, title in cols:
    f.rect(x, 14, 222, 262, fill='ink', stroke='wire')
    f.text(x + 111, 34, title, size=12, color='phosphor', weight='600')
# structured: a declared table
x = 14
f.rect(x + 12, 56, 198, 60, fill='panel', stroke='phosphor')
for i, (name, typ, val) in enumerate([('ride_id', 'string', 'R000001'),
                                      ('station', 'string', 'ST02'),
                                      ('minutes', 'int32', '12')]):
    cx = x + 12 + 33 + i * 66
    f.text(cx, 70, name, size=10, mono=True, weight='600')
    f.text(cx, 85, typ, size=9.5, mono=True, color='amber')
    f.text(cx, 104, val, size=10, mono=True)
f.line(x + 12, 94, x + 210, 94, color='wire', sw=1)
f.text(x + 111, 150, ('names and types:', 'nomes e tipos:'), size=10.5)
f.text(x + 111, 166, ('in the table, declared', 'na tabela, declarados'), size=10.5)
f.text(x + 111, 182, ('before any row', 'antes de qualquer linha'), size=10.5)
f.text(x + 111, 232, ('a wrong value is', 'um valor errado é'), size=10.5, color='paper-dim')
f.text(x + 111, 248, ('refused on write', 'recusado na escrita'), size=10.5, color='paper-dim')
# semi-structured: names travel with the values
x = 249
f.rect(x + 12, 56, 198, 92, fill='panel', stroke='phosphor')
for i, line in enumerate(['{"ride_id": "R000001",',
                          ' "bike": {',
                          '   "id": "B017",',
                          '   "battery": 82},',
                          ' "minutes": 12}']):
    code(f, x + 24, 70 + i * 16, line, 10)
f.text(x + 111, 166, ('names: in every record,', 'nomes: em cada registro,'), size=10.5)
f.text(x + 111, 182, ('beside the values', 'ao lado dos valores'), size=10.5)
f.text(x + 111, 232, ('each reader decides', 'cada leitor decide'), size=10.5, color='paper-dim')
f.text(x + 111, 248, ('what to expect', 'o que esperar'), size=10.5, color='paper-dim')
# unstructured: a body with structured metadata around it
x = 484
f.rect(x + 12, 56, 198, 26, fill='panel', stroke='phosphor')
f.text(x + 111, 69, 'C0042 · 08:12 · 1 photo', size=10, mono=True)
f.rect(x + 12, 88, 198, 60, fill='panel', stroke='wire', dash='4 3')
for i, line in enumerate([('“Rode from Rua XV this', '“Saí da Rua XV hoje de'),
                          ('morning, twelve minutes,', 'manhã, doze minutos, e a'),
                          ('and the dock would not', 'doca não queria soltar'),
                          ('let go of the bike.”', 'a bicicleta.”')]):
    f.text(x + 111, 99 + i * 13, line, size=10)
f.text(x + 111, 166, ('names: none; the meaning', 'nomes: nenhum; o sentido'), size=10.5)
f.text(x + 111, 182, ('is in the words', 'está nas palavras'), size=10.5)
f.text(x + 111, 232, ('somebody has to', 'alguém precisa'), size=10.5, color='paper-dim')
f.text(x + 111, 248, ('interpret the body', 'interpretar o corpo'), size=10.5, color='paper-dim')

# flatten: one nested event, flattened into a row and exploded into charge rows.
g = Fig('flatten', 720, 300,
        caption=('Flattening and exploding ride R000103. The nested objects become columns of one row; '
                 'the array becomes a table of its own, one row per charge, each carrying the ride id.',
                 'Achatando e explodindo a viagem R000103. Os objetos aninhados viram colunas de uma '
                 'linha; o array vira uma tabela própria, uma linha por cobrança, cada uma levando o id '
                 'da viagem.'),
        label=('On the left, the event for ride R000103 with nested bike, start and end objects and '
               'a charges array of two items. An arrow labelled flatten leads to a rides table with one '
               'row and dotted column names. An arrow labelled explode leads to a charges table with '
               'two rows, unlock 100 and minutes 475, both with ride_id R000103.',
               'À esquerda, o evento da viagem R000103 com os objetos aninhados bike, start e end e um '
               'array charges de dois itens. Uma seta chamada achatar leva a uma tabela rides com uma '
               'linha e nomes de coluna com pontos. Uma seta chamada explodir leva a uma tabela charges '
               'com duas linhas, unlock 100 e minutes 475, ambas com ride_id R000103.'))
g.rect(14, 14, 206, 272, fill='panel', stroke='wire')
g.text(117, 32, ('one event', 'um evento'), size=11.5, color='phosphor', weight='600')
ev = ['ride_id: R000103', 'bike:', '  id: B028', '  battery: 21', 'start:', '  station: ST07',
      'end:', '  station: ST07', '  minutes: 19', 'charges: [', '  unlock 100,', '  minutes 475', ']']
for i, line in enumerate(ev):
    code(g, 30, 54 + i * 17, line, 10.5, color='amber' if i >= 9 else 'paper')
# rides table
g.text(470, 32, ('rides: one row per ride', 'rides: uma linha por viagem'), size=11.5,
       color='phosphor', weight='600')
g.rect(286, 46, 420, 52, fill='panel', stroke='phosphor')
heads = ['ride_id', 'bike.id', 'bike.battery', 'start.station', 'end.station']
vals = ['R000103', 'B028', '21', 'ST07', 'ST07']
for i, (h, v) in enumerate(zip(heads, vals)):
    cx = 286 + 42 + i * 84
    g.text(cx, 62, h, size=9.5, mono=True, weight='600')
    g.text(cx, 84, v, size=10, mono=True)
g.line(286, 72, 706, 72, color='wire', sw=1)
g.text(470, 112, ('… and the other dotted columns', '… e as outras colunas com pontos'), size=10,
       color='paper-dim')
g.arrow(220, 72, 284, 72)
g.text(252, 62, ('flatten', 'achatar'), size=10, color='paper-dim')
# charges table
g.text(470, 168, ('charges: one row per item', 'charges: uma linha por item'), size=11.5,
       color='amber', weight='600')
g.rect(346, 182, 300, 76, fill='panel', stroke='amber')
for i, h in enumerate(['ride_id', 'kind', 'cents']):
    g.text(346 + 50 + i * 100, 198, h, size=9.5, mono=True, weight='600')
g.line(346, 208, 646, 208, color='wire', sw=1)
for r, row in enumerate([('R000103', 'unlock', '100'), ('R000103', 'minutes', '475')]):
    for i, v in enumerate(row):
        g.text(346 + 50 + i * 100, 224 + r * 22, v, size=10, mono=True)
g.arrow(220, 230, 344, 230)
g.text(282, 220, ('explode', 'explodir'), size=10, color='paper-dim')
g.text(496, 276, ('two rows, one ride', 'duas linhas, uma viagem'), size=10, color='paper-dim')

# on-write-on-read: where the check sits in time.
h = Fig('on-write-on-read', 720, 270,
        caption=('The same check in two places. On write it runs once, before anything is stored; '
                 'on read it runs in every reader, after everything is.',
                 'A mesma conferência em dois lugares. Na escrita ela roda uma vez, antes de qualquer '
                 'coisa ser guardada; na leitura ela roda em cada leitor, depois de tudo guardado.'),
        label=('Two lanes. Schema on write: the writer sends to a check, which refuses a bad value '
               'back to the writer and passes good ones to a table, which two readers use as it is. '
               'Schema on read: the writer sends straight to storage that keeps everything, and each '
               'of two readers runs its own check.',
               'Duas faixas. Esquema na escrita: quem escreve manda para uma conferência, que devolve '
               'um valor ruim a quem escreveu e passa os bons para uma tabela, que dois leitores usam '
               'como está. Esquema na leitura: quem escreve manda direto para um armazenamento que '
               'guarda tudo, e cada um de dois leitores roda a sua própria conferência.'))
h.text(14, 22, ('schema on write', 'esquema na escrita'), size=12, color='phosphor', weight='600',
       anchor='start')
h.box(14, 40, 110, 50, ('the writer', 'quem escreve'), size=10.5)
h.arrow(124, 65, 172, 65)
h.box(174, 40, 130, 50, [('checks every', 'confere todo'), ('value', 'valor')], title=('the check', 'a conferência'),
      stroke='phosphor', size=10.5)
h.arrow(304, 65, 352, 65)
h.box(354, 40, 130, 50, [('only what fitted', 'só o que coube')], title=('a table', 'uma tabela'), size=10.5)
h.arrow(484, 58, 556, 42)
h.arrow(484, 72, 556, 88)
h.box(558, 22, 148, 36, ('reader: trusts it', 'leitor: confia'), size=10.5)
h.box(558, 70, 148, 36, ('reader: trusts it', 'leitor: confia'), size=10.5)
h.line(239, 90, 239, 112, color='amber')
h.line(239, 112, 69, 112, color='amber')
h.arrow(69, 112, 69, 92, color='amber')
h.text(154, 124, ('refused, now', 'recusado, agora'), size=10, color='amber')
h.line(14, 142, 706, 142, color='wire', sw=1, dash='4 4')
h.text(14, 162, ('schema on read', 'esquema na leitura'), size=12, color='phosphor', weight='600',
       anchor='start')
h.box(14, 186, 110, 50, ('the writer', 'quem escreve'), size=10.5)
h.arrow(124, 211, 260, 211)
h.box(262, 186, 160, 50, [('everything sent', 'tudo o que veio')], title=('storage', 'armazenamento'),
      size=10.5)
h.arrow(422, 204, 494, 186)
h.arrow(422, 218, 494, 236)
h.box(496, 164, 210, 40, [('reader + its own check', 'leitor + a própria conferência')],
      stroke='phosphor', size=10.5)
h.box(496, 218, 210, 40, [('reader + its own check', 'leitor + a própria conferência')],
      stroke='phosphor', size=10.5)

FIGURES = [f, g, h]
