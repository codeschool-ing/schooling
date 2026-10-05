---
title: O que o diretório guarda
version: 1
---

`PersistentClient(path="chroma")` criou um diretório, e o diretório é o banco inteiro. Não há outra
cópia nem um processo segurando-o: pare o programa, copie o diretório, e você copiou o banco. Há
dois tipos de arquivo lá dentro.

```
ana@lab:~/emb$ ls -l chroma chroma/*/
chroma:
total 376
drwxr-xr-x 2 ana ana   4096 Oct  5 14:10 48e47011-219b-443d-9093-a530d9043481
-rw-r--r-- 1 ana ana 380928 Oct  5 14:10 chroma.sqlite3

chroma/48e47011-219b-443d-9093-a530d9043481/:
total 172
-rw-r--r-- 1 ana ana 167600 Oct  5 14:10 data_level0.bin
-rw-r--r-- 1 ana ana    100 Oct  5 14:10 header.bin
-rw-r--r-- 1 ana ana    400 Oct  5 14:10 length.bin
-rw-r--r-- 1 ana ana      0 Oct  5 14:10 link_lists.bin
ana@lab:~/emb$ du -sh chroma
552K	chroma
```

**`chroma.sqlite3` é o registro de tudo; o diretório com nome de identificador comprido é o
índice.** O identificador é o id do segmento vetorial da coleção, e os quatro arquivos `.bin` dele
são um índice HNSW, o grafo que permite a uma busca não ler todos os vetores. A aula 15 constrói
esse grafo. Esta seção é sobre o que fica onde.

## Um arquivo SQLite comum

Nada no primeiro arquivo é exclusivo do Chroma. O próprio módulo `sqlite3` do Python o abre:

```schooling-example
{
  "language": "python",
  "file": "inside.py",
  "parts": [
    {
      "code": "import sqlite3\n\ndb = sqlite3.connect(\"chroma/chroma.sqlite3\")\nfor table in (\"embeddings\", \"embedding_metadata\", \"embedding_fulltext_search\",\n              \"embeddings_queue\"):\n    print(f\"{table:26}\", db.execute(f\"SELECT count(*) FROM {table}\").fetchone()[0])",
      "note": "`chroma.sqlite3` é um arquivo SQLite comum, então o próprio módulo `sqlite3` do Python consegue lê-lo. Conte as linhas de quatro tabelas."
    },
    {
      "code": "rows = db.execute(\"SELECT key, string_value FROM embedding_metadata m \"\n                  \"JOIN embeddings e ON e.id = m.id WHERE e.embedding_id = 'h15'\")\nfor key, value in rows:\n    print(f\"  {key:16} {value[:50]}\")",
      "note": "Cada chave de metadado de h15, com o documento entre elas."
    },
    {
      "code": "vector = db.execute(\"SELECT vector FROM embeddings_queue WHERE id = 'h15'\").fetchone()[0]\nprint(\"queued vector:\", len(vector), \"bytes\")",
      "note": "O registro de escritas guarda cada vetor como chegou, em bytes crus."
    },
    {
      "code": "ops = {0: \"add\", 1: \"update\", 2: \"upsert\", 3: \"delete\"}\nrows = db.execute(\"SELECT seq_id, operation, id FROM embeddings_queue \"\n                  \"ORDER BY seq_id DESC LIMIT 5\")\nprint(\"last five writes:\", [(seq, ops[op], i) for seq, op, i in rows][::-1])",
      "note": "As últimas cinco entradas desse registro, da mais antiga para a mais nova. Os números em `operation` são os códigos que o pacote Python do Chroma dá aos quatro tipos de escrita."
    }
  ],
  "output": "ana@lab:~/emb$ python inside.py\nembeddings                 40\nembedding_metadata         160\nembedding_fulltext_search  40\nembeddings_queue           45\n  category         returns\n  chroma:document  When your refund arrives. We refund within three w\n  lang             en\n  updated          2026-02-02\nqueued vector: 1536 bytes\nlast five writes: [(41, 'add', 'h41'), (42, 'add', 'h41'), (43, 'upsert', 'h41'), (44, 'update', 'h99'), (45, 'delete', 'h41')]"
}
```

Quarenta linhas em `embeddings`, uma por registro. 160 em `embedding_metadata`, que são quarenta
registros vezes quatro: as três chaves de metadados que você passou e o próprio documento, guardado
sob a chave `chroma:document`. Os documentos também estão numa tabela de texto completo,
`embedding_fulltext_search`, com uma linha cada.

**`embeddings_queue` é um registro de escritas**, e tem 45 linhas: as quarenta do `load.py` e as
cinco escritas do `change.py`. Cada uma carrega o seu vetor, 1.536 bytes, que são os 384 números de
quatro bytes da aula 1. Leia as cinco últimas e as duas escritas que não mudaram nada estão lá: o
segundo `add` de h41 e o `update` de h99 foram registrados como qualquer outra escrita, embora
nenhum dos dois tenha mudado um registro.

## O arquivo do índice anda atrás do registro

O registro é gravado a cada chamada. Os arquivos do índice não, e uma listagem do diretório pode
enganar você quanto a isso. Este programa guarda vetores aleatórios num diretório separado e confere
o tamanho do arquivo principal do índice depois de cada lote:

```python
import glob
import os
import chromadb
import numpy as np

col = chromadb.PersistentClient(path="grow").create_collection(
    "random", configuration={"hnsw": {"space": "cosine"}})
print("sync_threshold:", col.configuration["hnsw"]["sync_threshold"])
rng = np.random.default_rng(12)
for n in (40, 900, 100):
    start = col.count()
    col.add(ids=[f"r{start + i}" for i in range(n)],
            embeddings=rng.normal(size=(n, 384)).astype("float32"))
    size = os.path.getsize(glob.glob("grow/*/data_level0.bin")[0])
    print(f"{col.count():5} records   data_level0.bin {size:>9,} bytes")
```

```
ana@lab:~/emb$ python grow.py
sync_threshold: 1000
   40 records   data_level0.bin   167,600 bytes
  940 records   data_level0.bin   167,600 bytes
 1040 records   data_level0.bin 1,743,040 bytes
```

**Novecentos registros entraram e o arquivo não se mexeu.** O Chroma só regrava os arquivos do
índice depois que se acumulam `sync_threshold` escritas, 1.000 por padrão, e até lá as escritas que
os arquivos ainda não alcançaram ficam no registro dentro do `chroma.sqlite3`. Entre 940 e 1.040
registros as escritas passaram do limite e o Chroma regravou o arquivo. Então o tamanho dos arquivos
`.bin` não diz nada sobre quantos registros existem; `col.count()` diz.

Os dois tamanhos também mostram como o arquivo é organizado. 1.743.040 bytes são 1.040 posições de
1.676 bytes, e 167.600 são 100 dessas posições: o primeiro arquivo tinha lugar para cem registros
enquanto guardava quarenta. Cada posição é o vetor, com os seus 1.536 bytes, mais as ligações com os
vizinhos no grafo. A aula 18 conta esse custo extra numa coleção de verdade.

## O mesmo diretório, servido

Um diretório que um único processo Python abre serve bem para um notebook, um teste ou um programa
sozinho. Uma aplicação web com vários workers quer um único dono dos arquivos e muitos clientes, e o
Chroma traz um servidor exatamente para isso. `chroma run` serve um diretório por HTTP, e o
`HttpClient` conversa com ele pelos mesmos métodos de coleção que você vem chamando:

```
ana@lab:~/emb$ chroma run --path chroma --port 8012 > chroma.log 2>&1 &
ana@lab:~/emb$ curl -s localhost:8012/api/v2/heartbeat; echo
{"nanosecond heartbeat":1791220211734992705}
ana@lab:~/emb$ python remote.py
40 ['h18', 'h15', 'h22'] [0.5544, 0.5624, 0.6006]
```

```python
import chromadb

client = chromadb.HttpClient(host="localhost", port=8012)
col = client.get_collection("help")
r = col.query(query_texts=["how do I get my money back"], n_results=3)
print(col.count(), r["ids"][0], [round(d, 4) for d in r["distances"][0]])
```

Mesma contagem, mesmos três artigos, mesmas distâncias. Só o construtor do cliente mudou. Um detalhe
muda junto e passa despercebido com facilidade: **o embedding continua acontecendo no seu
programa**. O cliente Python roda a função de embedding da coleção antes de mandar qualquer coisa,
então `query_texts` atravessou a rede como vetor, e o servidor nunca carregou um modelo. O Chroma
Cloud, a versão hospedada, é acessado por um terceiro construtor, `CloudClient`, com uma chave de
API; ele não foi usado aqui.
