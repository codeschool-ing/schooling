from svg import Fig

# lifecycle: the four stages a ride passes through, storage underneath them,
# and the undercurrents under everything.
f = Fig('lifecycle', 720, 330,
        caption=('The lifecycle at Roda Livre. Storage is drawn under the other stages because every '
                 'one of them reads from it or writes to it, and the undercurrents apply to all five.',
                 'O ciclo de vida na Roda Livre. O armazenamento fica embaixo das outras etapas porque '
                 'todas leem dele ou escrevem nele, e as correntes subjacentes valem para as cinco.'),
        label=('Generation: the app writes a row per ride. Ingestion copies one day out each night '
               'into the raw zone of storage. Transformation reads raw and writes the cleaned and '
               'curated zones. Delivery reads curated and produces the morning report. Under all of '
               'it, the undercurrents: security, data management, DataOps, architecture, '
               'orchestration and software engineering.',
               'Geração: o aplicativo grava uma linha por viagem. A ingestão copia um dia por noite '
               'para a zona bruta do armazenamento. A transformação lê o bruto e grava as zonas limpa '
               'e curada. A entrega lê o curado e produz o relatório da manhã. Embaixo de tudo, as '
               'correntes subjacentes: segurança, gestão de dados, DataOps, arquitetura, orquestração '
               'e engenharia de software.'))
stages = [
    (14, ('generation', 'geração'), [('the app writes', 'o aplicativo grava'), ('a row per ride', 'uma linha por viagem')]),
    (194, ('ingestion', 'ingestão'), [('one day copied', 'um dia copiado'), ('out each night', 'a cada noite')]),
    (374, ('transformation', 'transformação'), [('clean, join,', 'limpar, juntar,'), ('count', 'contar')]),
    (554, ('delivery', 'entrega'), [('the morning', 'o relatório'), ('report', 'da manhã')]),
]
for x, title, lines in stages:
    f.box(x, 30, 152, 74, lines, title=title, stroke='phosphor', size=10.5)
f.arrow(166, 67, 192, 67)
# storage band and its zones
f.rect(180, 136, 528, 98, fill='ink', stroke='phosphor', dash='5 4')
f.text(194, 222, ('storage: every stage reads and writes here', 'armazenamento: toda etapa lê e grava aqui'),
       size=11, anchor='start', color='phosphor', weight='600')
zones = [(214, ('raw', 'bruto'), 'raw/'), (394, ('cleaned', 'limpo'), 'clean/'),
         (574, ('curated', 'curado'), 'curated/')]
for x, name, path in zones:
    f.rect(x, 148, 120, 54)
    f.text(x + 60, 166, name, size=11, weight='600')
    f.text(x + 60, 184, path, size=10.5, mono=True)
f.arrow(270, 104, 270, 146)                 # ingestion writes raw
f.arrow(334, 160, 410, 106)                 # transformation reads raw
f.arrow(454, 104, 454, 146)                 # transformation writes cleaned
f.arrow(514, 175, 572, 175)                 # cleaned becomes curated
f.arrow(634, 148, 634, 106)                 # delivery reads curated
# undercurrents
f.rect(14, 254, 694, 62, fill='ink', stroke='amber', dash='5 4')
f.text(361, 272, ('the undercurrents', 'as correntes subjacentes'), size=11, color='amber', weight='600')
f.text(361, 296, ('security · data management · DataOps · architecture · orchestration · software engineering',
                  'segurança · gestão de dados · DataOps · arquitetura · orquestração · engenharia de software'),
       size=10.5)

# etl-elt: the same three steps, and where the transformation runs.
g = Fig('etl-elt', 720, 236,
        caption=('The same extract, transform and load in two orders. What differs is where the '
                 'transformation runs, and whether the raw rows are kept in the warehouse beside its '
                 'result.',
                 'O mesmo extrair, transformar e carregar em duas ordens. O que muda é onde a '
                 'transformação roda, e se as linhas brutas ficam no warehouse ao lado do resultado.'),
        label=('ETL: rows go from the source to a transformation on its own server, and only the '
               'result is loaded into the warehouse. ELT: rows go from the source into the warehouse '
               'raw, and the transformation runs inside the warehouse, writing the result beside them.',
               'ETL: as linhas vão da origem para uma transformação num servidor próprio, e só o '
               'resultado é carregado no warehouse. ELT: as linhas vão da origem para o warehouse, '
               'brutas, e a transformação roda dentro do warehouse, gravando o resultado ao lado.'))
g.text(14, 16, ('ETL: transformed on the way in', 'ETL: transformado no caminho'),
       size=11.5, anchor='start', color='phosphor', weight='600')
g.box(14, 34, 120, 50, ('the source', 'a origem'), size=10.5)
g.arrow(134, 59, 172, 59)
g.box(174, 34, 150, 50, [('on its own server', 'num servidor próprio')], title=('transform', 'transformar'),
      size=10.5)
g.arrow(324, 59, 554, 59)
g.rect(364, 26, 342, 76, fill='ink', stroke='amber', dash='5 4')
g.text(376, 44, ('raw rows not kept here', 'linhas brutas não ficam aqui'), size=10.5, anchor='start',
       color='paper-dim')
g.text(376, 90, ('the warehouse', 'o warehouse'), size=11, anchor='start', color='amber', weight='600')
g.box(556, 34, 140, 50, ('the result', 'o resultado'), size=10.5, stroke='phosphor')
g.text(14, 130, ('ELT: loaded raw, transformed inside', 'ELT: carregado bruto, transformado dentro'),
       size=11.5, anchor='start', color='phosphor', weight='600')
g.box(14, 148, 120, 50, ('the source', 'a origem'), size=10.5)
g.arrow(134, 173, 182, 173)
g.rect(164, 140, 542, 86, fill='ink', stroke='amber', dash='5 4')
g.box(184, 148, 120, 50, ('raw rows', 'linhas brutas'), size=10.5)
g.arrow(304, 173, 342, 173)
g.box(344, 148, 150, 50, [('usually in SQL', 'em geral em SQL')], title=('transform', 'transformar'), size=10.5)
g.arrow(494, 173, 554, 173)
g.box(556, 148, 140, 50, ('the result', 'o resultado'), size=10.5, stroke='phosphor')
g.text(176, 214, ('the warehouse', 'o warehouse'), size=11, anchor='start', color='amber', weight='600')

# lineage: one number in the report, walked back to the app.
h = Fig('lineage', 720, 352,
        caption=('The 29 rides from Rua XV in the report, walked back to the app. Every difference '
                 'between two layers is one rule in one program.',
                 'As 29 viagens da Rua XV no relatório, rastreadas de volta até o aplicativo. Cada '
                 'diferença entre duas camadas é uma regra num programa.'),
        label=('Five layers, from the top: the report says Rua XV 29; the curated row says ST02, Rua '
               'XV, 29; the clean zone has 29 rides from ST02; the raw zone has 31; the app database '
               'has 31. Ingestion copied all 31; the transformation dropped 2 false starts, R000183 '
               'and R000342; the 29 left were counted into one row and read by the report.',
               'Cinco camadas, de cima para baixo: o relatório diz Rua XV 29; a linha curada diz ST02, '
               'Rua XV, 29; a zona limpa tem 29 viagens da ST02; a zona bruta tem 31; o banco do '
               'aplicativo tem 31. A ingestão copiou as 31; a transformação descartou 2 partidas '
               'falsas, R000183 e R000342; as 29 restantes viraram uma linha e foram lidas pelo '
               'relatório.'))
layers = [
    (('the report', 'o relatório'), 'ST02 Rua XV  29', True, 'amber'),
    (('curated', 'curado'), 'ST02,Rua XV,29,610', True, 'wire'),
    (('clean', 'limpo'), ('29 rides from ST02', '29 viagens da ST02'), False, 'wire'),
    (('raw', 'bruto'), ('31 rides from ST02', '31 viagens da ST02'), False, 'wire'),
    (('the app', 'o aplicativo'), ('31 rides from ST02', '31 viagens da ST02'), False, 'wire'),
]
notes = [
    (('read by the report', 'lido pelo relatório'), None),
    (('counted: one row per station', 'contadas: uma linha por estação'), None),
    (('the transformation drops 2 false starts', 'a transformação descarta 2 partidas falsas'),
     'R000183 1 min, R000342 0 min'),
    (('ingestion copies all of them', 'a ingestão copia todas'), None),
]
top, bh, gap = 14, 38, 30
for i, (name, content, mono, stroke) in enumerate(layers):
    y = top + i * (bh + gap)
    f_ = h
    f_.text(134, y + bh / 2, name, size=11, anchor='end', weight='600')
    f_.box(148, y, 240, bh, content, mono=mono, size=10.5, stroke=stroke)
for i, (note, sub) in enumerate(notes):
    y_upper = top + i * (bh + gap) + bh
    y_lower = y_upper + gap
    h.arrow(268, y_lower, 268, y_upper + 2)
    mid = (y_upper + y_lower) / 2
    if sub:
        h.text(408, mid - 7, note, size=10.5, anchor='start', color='amber')
        h.text(408, mid + 8, sub, size=10, anchor='start', mono=True)
    else:
        h.text(408, mid, note, size=10.5, anchor='start')

FIGURES = [f, g, h]
