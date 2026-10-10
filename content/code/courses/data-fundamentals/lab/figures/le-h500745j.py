from svg import Fig

# ---- partition: the same cut, two behaviours ------------------------------
p = Fig('partition', 720, 250,
        caption=('The same cut, two choices. On the left the lone node refuses and every answer '
                 'stays true; on the right it accepts, and two copies disagree until the link heals.',
                 'O mesmo corte, duas escolhas. À esquerda o nó isolado recusa e toda resposta '
                 'continua verdadeira; à direita ele aceita, e duas cópias discordam até o enlace voltar.'),
        label=('Two panels, each with nodes n1 and n2 on one side of a cut link and n3 alone on the '
               'other. Consistency chosen: n1 and n2 hold 5, n3 still holds 6 and refuses reads and '
               'writes. Availability chosen: n1 and n2 hold 5, n3 accepted a return and holds 7. '
               'The true count is 6.',
               'Dois painéis, cada um com os nós n1 e n2 de um lado de um enlace cortado e o n3 '
               'sozinho do outro. Consistência escolhida: n1 e n2 têm 5, o n3 ainda tem 6 e recusa '
               'leituras e escritas. Disponibilidade escolhida: n1 e n2 têm 5, o n3 aceitou uma '
               'devolução e tem 7. A contagem verdadeira é 6.'))
for ox, title, n3val, n3stroke, under, summary in [
        (10, ('consistency chosen (cp)', 'consistência escolhida (cp)'), '6', 'wire',
         [('refuses writes', 'recusa escritas'), ('and reads', 'e leituras')],
         [('every answer is true;', 'toda resposta é verdadeira;'),
          ('n3 answers with errors', 'o n3 responde com erro')]),
        (370, ('availability chosen (ap)', 'disponibilidade escolhida (ap)'), '7', 'amber',
         [('accepts the', 'aceita a'), ('returned bicycle', 'bicicleta devolvida')],
         [('n2 says 5, n3 says 7;', 'o n2 diz 5, o n3 diz 7;'),
          ('Rua XV really holds 6', 'a Rua XV tem 6 de verdade')])]:
    p.text(ox + 170, 20, title, size=11.5, weight='600', color='phosphor')
    p.rect(ox + 6, 36, 214, 116, fill='ink', stroke='wire', dash='4 3')
    p.text(ox + 16, 48, ('side A', 'lado A'), size=10, anchor='start', color='paper-dim')
    p.box(ox + 20, 62, 82, 60, ['n1', '5'], mono=True, stroke='phosphor')
    p.box(ox + 124, 62, 82, 60, ['n2', '5'], mono=True, stroke='phosphor')
    p.line(ox + 102, 92, ox + 124, 92)
    p.rect(ox + 248, 36, 86, 116, fill='ink', stroke='wire', dash='4 3')
    p.text(ox + 258, 48, ('side B', 'lado B'), size=10, anchor='start', color='paper-dim')
    p.box(ox + 250 + 2, 62, 78, 60, ['n3', n3val], mono=True, stroke=n3stroke)
    p.line(ox + 206, 92, ox + 222, 92, color='amber', sw=2)
    p.line(ox + 236, 92, ox + 252, 92, color='amber', sw=2)
    p.text(ox + 229, 76, ('cut', 'corte'), size=10, color='amber', weight='600')
    p.text(ox + 113, 168, ('keeps working', 'continua funcionando'), size=10.5)
    for i, t in enumerate(under):
        p.text(ox + 291, 168 + i * 15, t, size=10.5)
    for i, t in enumerate(summary):
        p.text(ox + 170, 210 + i * 16, t, size=11, weight='600' if i == 0 else None)

# ---- real-systems: the triangle, with the bottom edge empty -------------------
r = Fig('real-systems', 720, 360,
        caption=('Where seven systems sit, by default. Dashed boxes move with their settings, and '
                 'the C-and-A edge holds only systems with no network to cut.',
                 'Onde sete sistemas ficam, por padrão. As caixas tracejadas mudam com a configuração, '
                 'e a aresta de C e A só tem sistemas sem rede para cortar.'),
        label=('A triangle with P at the top, C at the bottom left and A at the bottom right. Beside '
               'the CP edge: etcd, ZooKeeper, Spanner, PostgreSQL with one primary, and Kafka with '
               'acks=all, dashed. Beside the AP edge: Cassandra and DynamoDB default reads, both '
               'dashed. Under the C-and-A edge: PostgreSQL on one machine, with no network to cut.',
               'Um triângulo com P no alto, C embaixo à esquerda e A embaixo à direita. Junto à aresta '
               'CP: etcd, ZooKeeper, Spanner, PostgreSQL com um primário, e Kafka com acks=all, '
               'tracejado. Junto à aresta AP: Cassandra e as leituras padrão do DynamoDB, ambos '
               'tracejados. Sob a aresta de C e A: PostgreSQL numa máquina só, sem rede para cortar.'))
P_, C_, A_ = (360, 44), (250, 254), (470, 254)
r.poly([P_, C_, A_], stroke='paper-dim', sw=1.5)
r.circle(*P_, 15, fill='panel', stroke='phosphor')
r.text(P_[0], P_[1], 'P', size=13, weight='600', color='paper')
r.circle(*C_, 15, fill='panel', stroke='phosphor')
r.text(C_[0], C_[1], 'C', size=13, weight='600', color='paper')
r.circle(*A_, 15, fill='panel', stroke='phosphor')
r.text(A_[0], A_[1], 'A', size=13, weight='600', color='paper')
r.text(360, 18, ('partitions happen: P is not optional', 'partições acontecem: P não é opcional'),
       size=10.5, color='paper-dim')
# CP column
r.text(110, 40, ('CP: the minority side refuses', 'CP: o lado minoritário recusa'),
       size=11, weight='600', color='phosphor')
for i, (t, dash) in enumerate([('etcd', None), ('ZooKeeper', None), ('Spanner', None),
                               (('PostgreSQL, one primary', 'PostgreSQL, um primário'), None),
                               (('Kafka, acks=all', 'Kafka, acks=all'), '4 3')]):
    r.box(20, 58 + i * 36, 180, 28, t, size=10.5, dash=dash,
          stroke='paper-dim' if dash else 'wire')
# AP column
r.text(610, 40, ('AP: every side answers', 'AP: todo lado responde'),
       size=11, weight='600', color='amber')
for i, (t, dash) in enumerate([('Cassandra', '4 3'),
                               (('DynamoDB, default reads', 'DynamoDB, leitura padrão'), '4 3')]):
    r.box(520, 58 + i * 36, 180, 28, t, size=10.5, dash=dash, stroke='amber')
# bottom edge
r.text(360, 284, ('C and A without P: only with no network to cut',
                  'C e A sem P: só sem rede para cortar'), size=10.5, color='paper-dim')
r.box(270, 300, 180, 28, ('PostgreSQL, one machine', 'PostgreSQL, uma máquina'), size=10.5)
# legend
r.rect(520, 300, 26, 16, stroke='paper-dim', dash='4 3')
r.text(554, 308, ('moves with its settings', 'muda com a configuração'), size=10, anchor='start')

# ---- whole-map: the course as one picture --------------------------------------
w = Fig('whole-map', 720, 340,
        caption=('The ten lessons as one map: the people on top, the lifecycle across the middle, '
                 'the machinery underneath, and the course that walks each region next.',
                 'As dez aulas como um mapa: as pessoas em cima, o ciclo de vida no meio, a '
                 'maquinaria por baixo, e o curso que percorre cada região em seguida.'),
        label=('Top band, lessons 1 and 2, the job and the choices: analytics-bi, data-governance. '
               'Middle row, the lifecycle from lesson 3: generation, lessons 4 and 5, sql-databases '
               'and apis; ingestion, lessons 3, 4 and 7, pipelines-etl; storage, lessons 3, 5 and 6, '
               'warehouse-modeling and bigdata; transformation, lessons 3 and 7, pipelines-etl and '
               'data-cleaning; delivery, lesson 3, analytics-bi. Bottom band, underneath every stage: '
               'lesson 8, batch and stream, streaming; lesson 9, many machines, bigdata and scale; '
               'lesson 10, when the link breaks, nosql-operations and architecture.',
               'Faixa de cima, aulas 1 e 2, o trabalho e as escolhas: analytics-bi, data-governance. '
               'Linha do meio, o ciclo de vida da aula 3: geração, aulas 4 e 5, sql-databases e apis; '
               'ingestão, aulas 3, 4 e 7, pipelines-etl; armazenamento, aulas 3, 5 e 6, '
               'warehouse-modeling e bigdata; transformação, aulas 3 e 7, pipelines-etl e '
               'data-cleaning; entrega, aula 3, analytics-bi. Faixa de baixo, sob todas as etapas: '
               'aula 8, lote e fluxo, streaming; aula 9, muitas máquinas, bigdata e scale; aula 10, '
               'quando o enlace cai, nosql-operations e architecture.'))
w.rect(20, 12, 680, 52, stroke='amber')
w.text(360, 30, ('lessons 1–2 · the job, the people, the choices',
                 'aulas 1–2 · o trabalho, as pessoas, as escolhas'), size=11.5, weight='600')
w.text(360, 48, 'analytics-bi · data-governance', size=10.5, mono=True, color='paper-dim')
stages = [(('generation', 'geração'), ('lessons 4, 5', 'aulas 4, 5'), ['sql-databases', 'apis']),
          (('ingestion', 'ingestão'), ('lessons 3, 4, 7', 'aulas 3, 4, 7'), ['pipelines-etl']),
          (('storage', 'armazenamento'), ('lessons 3, 5, 6', 'aulas 3, 5, 6'),
           ['warehouse-modeling', 'bigdata']),
          (('transformation', 'transformação'), ('lessons 3, 7', 'aulas 3, 7'),
           ['pipelines-etl', 'data-cleaning']),
          (('delivery', 'entrega'), ('lesson 3', 'aula 3'), ['analytics-bi'])]
w.text(360, 84, ('the lifecycle, lesson 3', 'o ciclo de vida, aula 3'), size=11,
       weight='600', color='phosphor')
for i, (name, lessons, courses) in enumerate(stages):
    x = 20 + i * 140
    w.rect(x, 98, 120, 110, stroke='phosphor')
    w.text(x + 60, 116, name, size=11, weight='600')
    w.text(x + 60, 134, lessons, size=10.5, color='paper-dim')
    for j, c in enumerate(courses):
        w.text(x + 60, 166 + j * 18, c, size=10, mono=True)
    if i < 4:
        w.arrow(x + 120, 153, x + 138, 153)
w.text(360, 230, ('underneath every stage', 'sob todas as etapas'), size=11, weight='600',
       color='phosphor')
under = [(('lesson 8 · batch and stream', 'aula 8 · lote e fluxo'), ['streaming']),
         (('lesson 9 · many machines', 'aula 9 · muitas máquinas'), ['bigdata', 'scale']),
         (('lesson 10 · when the link breaks', 'aula 10 · quando o enlace cai'),
          ['nosql-operations', 'architecture'])]
for i, (title, courses) in enumerate(under):
    x = 20 + i * 232
    w.rect(x, 244, 216, 84, stroke='wire')
    w.text(x + 108, 264, title, size=11, weight='600')
    for j, c in enumerate(courses):
        w.text(x + 108, 288 + j * 18, c, size=10, mono=True)

FIGURES = [p, r, w]
