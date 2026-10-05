---
title: O que um índice acrescenta
version: 1
---

A imagem comum de um índice vem dos bancos de dados de sempre: uma B-tree sobre um id, poucos
bytes por linha apontando de volta para a tabela. Um índice vetorial não é isso. Para comparar uma
consulta com um vetor, o índice precisa ter o vetor, e **a maioria dos índices vetoriais guarda a
própria cópia de cada um**. Quanto isso custa depende do índice e de onde ele mora.

## No pgvector, cada índice é mais uma cópia

A aula 14 construiu estes índices para deixar uma consulta rápida. Aqui eles são construídos para
serem pesados, nas duas tabelas da seção anterior:

```sql
SET maintenance_work_mem = '512MB';
\timing on
CREATE INDEX v384_hnsw  ON v384  USING hnsw (embedding vector_cosine_ops);
CREATE INDEX v1536_hnsw ON v1536 USING hnsw (embedding vector_cosine_ops);
CREATE INDEX v384_ivf   ON v384  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX v1536_ivf  ON v1536 USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
\timing off
SELECT i.indexrelid::regclass         AS "index",
       pg_relation_size(i.indexrelid) AS bytes,
       pg_relation_size(i.indexrelid) / c.reltuples::bigint AS per_row
  FROM pg_index i JOIN pg_class c ON c.oid = i.indrelid
 WHERE c.relname IN ('v384', 'v1536')
 ORDER BY 1;
```

```
ana@lab:~/emb$ psql -f index.sql
SET
Timing is on.
CREATE INDEX
Time: 7385.761 ms (00:07.386)
CREATE INDEX
Time: 46553.018 ms (00:46.553)
CREATE INDEX
Time: 790.394 ms
CREATE INDEX
Time: 2351.658 ms (00:02.352)
Timing is off.
   index    |   bytes   | per_row 
------------+-----------+---------
 v384_pkey  |    466944 |      23
 v1536_pkey |    466944 |      23
 v384_hnsw  |  40968192 |    2048
 v1536_hnsw | 163848192 |    8192
 v384_ivf   |  33284096 |    1664
 v1536_ivf  | 164667392 |    8233
(6 rows)
```

**O índice HNSW sobre 384 dimensões tem 2.048 bytes por linha, mais que os 1.676 da tabela.** Ele
guarda o vetor e, ao lado, as ligações para os vizinhos do vetor no grafo que a aula 15 descreve.
Com 1536 dimensões são 8.192 bytes por linha: uma página inteira de 8 KB por vetor. Os índices
IVFFlat, que guardam cada vetor uma vez dentro da sua célula, ficam em 1.664 e 8.233 bytes por linha,
mais ou menos o tamanho da tabela de novo.

Então uma tabela com os dois índices guarda cada vetor três vezes. Raramente alguém mantém dois
índices vetoriais na mesma coluna em produção, mas **um índice já dobra a conta**, e a figura mostra
quanto, em relação aos próprios números.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Quatro barras horizontais, cada uma medida em múltiplos dos números crus de um vetor, quatro bytes por dimensão. No pgvector com 384 dimensões um vetor custa uma linha de tabela de 1676 bytes, uma entrada no índice HNSW de 2048 e uma no IVFFlat de 1664: três vezes e meia o tamanho cru. Com 1536 dimensões, 8371, 8192 e 8233 bytes, cerca de quatro vezes. Um arquivo do hnswlib custa 1684,6 bytes por vetor com 384 dimensões e 6292,6 com 1536, perto do tamanho cru.\"><rect x=\"190\" y=\"20\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"210\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">linha da tabela</text><rect x=\"333\" y=\"20\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"353\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">índice HNSW</text><rect x=\"449.6\" y=\"20\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"469.6\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">índice IVFFlat</text><rect x=\"586\" y=\"20\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"606\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">vetor + ligações</text><path d=\"M190 260 L190 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"190\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0×</text><path d=\"M302 62 L302 72\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M302 104 L302 124\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M302 156 L302 176\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M302 208 L302 228\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M302 260 L302 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"302\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1×</text><path d=\"M414 62 L414 72\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M414 104 L414 124\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M414 156 L414 176\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M414 208 L414 228\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M414 260 L414 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"414\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2×</text><path d=\"M526 62 L526 72\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M526 104 L526 124\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M526 156 L526 176\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M526 208 L526 228\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M526 260 L526 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"526\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3×</text><path d=\"M638 62 L638 72\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M638 104 L638 124\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M638 156 L638 176\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M638 208 L638 228\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M638 260 L638 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"638\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4×</text><text x=\"638\" y=\"314\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">múltiplos de 4 × d bytes</text><text x=\"308\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">só os números</text><text x=\"178\" y=\"88\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pgvector, 384 dim.</text><rect x=\"190\" y=\"74\" width=\"122.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"251.1\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">1676</text><rect x=\"312.2\" y=\"74\" width=\"149.3\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"386.9\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">2048</text><rect x=\"461.5\" y=\"74\" width=\"121.3\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522.2\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1664</text><text x=\"178\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">arquivo hnswlib, 384 dim.</text><rect x=\"190\" y=\"126\" width=\"122.8\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"251.4\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1684.6</text><text x=\"178\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pgvector, 1536 dim.</text><rect x=\"190\" y=\"178\" width=\"152.6\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"266.3\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">8371</text><rect x=\"342.6\" y=\"178\" width=\"149.3\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"417.3\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">8192</text><rect x=\"491.9\" y=\"178\" width=\"150.1\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"567\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">8233</text><text x=\"178\" y=\"244\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">arquivo hnswlib, 1536 dim.</text><rect x=\"190\" y=\"230\" width=\"114.7\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"247.4\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6292.6</text></svg>", "caption": "Bytes por vetor, desenhados contra os próprios números do vetor. Um arquivo acrescenta um décimo ou menos; o pgvector guarda o vetor na tabela e de novo em cada índice, então uma tabela com os dois índices o guarda três vezes."}
```

## Fora do banco, o grafo é um décimo a mais

O hnswlib e o FAISS guardam um índice como um arquivo, e os números dentro dele ficam guardados uma
vez só:

```schooling-example
{
  "language": "python",
  "file": "graphs.py",
  "parts": [
    {
      "code": "import os\nimport time\nimport faiss\nimport hnswlib\nimport numpy as np\n\nN = 20_000\nfor d in (384, 1536):\n    X = np.load(f\"v{d}.npy\")\n    flat = os.path.getsize(f\"flat{d}.faiss\")",
      "note": "O tamanho do índice plano é a régua pela qual todas as outras estruturas são divididas."
    },
    {
      "code": "    t = time.perf_counter()\n    h = hnswlib.Index(space=\"ip\", dim=d)\n    h.init_index(max_elements=N, M=16, ef_construction=64)\n    h.add_items(X, np.arange(N))\n    h.save_index(f\"hnsw{d}.bin\")\n    took = time.perf_counter() - t",
      "note": "Um grafo HNSW no hnswlib com os mesmos dois parâmetros que o pgvector usa por padrão, `M=16` e `ef_construction=64`, cronometrado da criação até o arquivo salvo."
    },
    {
      "code": "    t = time.perf_counter()\n    ivf = faiss.index_factory(d, \"IVF100,Flat\", faiss.METRIC_INNER_PRODUCT)\n    ivf.train(X)\n    ivf.add(X)\n    faiss.write_index(ivf, f\"ivf{d}.faiss\")\n    took_ivf = time.perf_counter() - t",
      "note": "Um índice IVF do FAISS: 100 células, encontradas por k-means, com os vetores guardados como estão em cada célula. O treino faz parte da construção, então fica dentro do cronômetro."
    },
    {
      "code": "    for f, s in ((f\"hnsw{d}.bin\", took), (f\"ivf{d}.faiss\", took_ivf)):\n        size = os.path.getsize(f)\n        print(f\"{f:>14}  {size:>11,}  {size / N:7.1f} per vector  \"\n              f\"{size / flat:5.2f}x flat  built in {s:5.2f} s\")",
      "note": "Tamanho por vetor, tamanho em relação ao arquivo plano e quanto tempo a construção levou."
    }
  ]
}
```

```
ana@lab:~/emb$ python graphs.py
   hnsw384.bin   33,691,896   1684.6 per vector   1.10x flat  built in  1.82 s
  ivf384.faiss   31,034,539   1551.7 per vector   1.01x flat  built in  0.90 s
  hnsw1536.bin  125,851,896   6292.6 per vector   1.02x flat  built in 11.13 s
 ivf1536.faiss  123,655,339   6182.8 per vector   1.01x flat  built in  3.26 s
```

**O arquivo HNSW do hnswlib tem 1,10 vez o arquivo plano com 384 dimensões e 1,02 vez com 1536.**
As ligações custam um número de bytes mais ou menos fixo por vetor, definido por `M`, então quanto
maior o vetor, menor a parte delas. O arquivo IVF do FAISS tem 1,01 vez o plano nos dois tamanhos:
uma lista de 100 centroides e um id por vetor. A estrutura de um índice é barata; **o caro é uma
segunda cópia dos vetores**, e isso é uma escolha do projeto do pgvector, não uma lei do HNSW.

## Construir é a parte lenta

Leia de novo as linhas `Time:`. O pgvector levou `7385.761 ms` para o índice HNSW sobre 384
dimensões e `46553.018 ms` sobre 1536, contra `790.394 ms` e `2351.658 ms` do IVFFlat. O hnswlib, fora do
banco, construiu os grafos em 1,82 s e 11,13 s. **O HNSW é o índice caro de construir**, porque cada
vetor acrescentado é uma busca no grafo construído até ali.

O `SET` no começo de `index.sql` importa para isso. O pgvector constrói o grafo muito mais rápido
quando ele cabe em `maintenance_work_mem`, cujo padrão é 64 MB; só o índice HNSW sobre 1536
dimensões chegou a 163.848.192 bytes. Aumente esse valor na sessão que constrói o índice, não no
servidor inteiro.

## Um limite que aparece com 3072 dimensões

O text-embedding-3-large e o gemini-embedding-001 devolvem 3072 números por padrão. Tente
indexá-los no pgvector do laboratório:

```
ana@lab:~/emb$ psql -c "CREATE TABLE v3072 (embedding vector(3072))" -c "CREATE INDEX ON v3072 USING hnsw (embedding vector_cosine_ops)"
CREATE TABLE
ERROR:  column cannot have more than 2000 dimensions for hnsw index
```

**O pgvector 0.6.0 recusa um índice HNSW com mais de 2.000 dimensões.** A tabela aceita a coluna; o
índice, não. Nesta versão você encurta os vetores, com o parâmetro `dimensions` que a aula 7 usou ou
cortando você mesmo, ou busca em todas as linhas sem índice. O pgvector 0.7.0 acrescentou um tipo
`halfvec`, de dois bytes por número, que pode ser indexado com até 4.000 dimensões; ele não existe
no 0.6.0 do laboratório e nada nesta aula o rodou.
