---
title: Partições, estatísticas e os arquivos que uma pergunta abre
version: 1
---

**Uma coluna de partição transforma um filtro numa lista de pastas.** Gravada com
`partition_by=["dt"]`, a tabela vira uma pasta por dia, `dt=2026-10-15/` e as vizinhas, e o log
registra o dia de cada arquivo ao lado do caminho dele. Uma pergunta sobre um dia abre uma pasta e
nunca lista as outras. É o primeiro de dois jeitos de uma tabela Delta evitar ler o que uma pergunta
não precisa; o segundo são as estatísticas de cada `add`, que funcionam sem pasta nenhuma.

Esta seção grava outubro de quatro jeitos e faz a cada um as mesmas duas perguntas. Salve o programa
em `~/azure`, ao lado do `orders.py` e do `table.py`:

`layouts.py`:

```python
"""layouts.py: the same October written four ways, to compare what each costs to read."""
import pyarrow.compute as pc
from deltalake import write_deltalake

from orders import october

month = october()
days = sorted(set(month["dt"].to_pylist()))

write_deltalake("lake/one", month)
write_deltalake("lake/by_day", month, partition_by=["dt"])

for day in days:
    write_deltalake("lake/daily", month.filter(pc.equal(month["dt"], day)), mode="append")

for day in days:
    one = month.filter(pc.equal(month["dt"], day))
    for hour in range(7, 24):
        write_deltalake("lake/hourly", one.filter(pc.equal(one["hour"], hour)),
                        partition_by=["dt"], mode="append")
```

**`one` é o mês numa escrita só**, como na seção anterior. **`by_day`** é particionado por dia, numa
escrita só. **`daily`** não é particionado, e é escrito um dia de cada vez, como faria um job noturno.
**`hourly`** é particionado por dia e escrito uma hora de cada vez, como faria um job que roda de hora
em hora, o que dá 527 commits:

```
ana@laptop:~/azure$ time python layouts.py

real	0m28.724s
user	0m19.605s
sys	0m8.122s
ana@laptop:~/azure$ for t in one by_day daily hourly; do python table.py lake/$t files; done
version 0: 1 files, 1,205,188 bytes, 98,727 rows in the log
version 0: 31 files, 1,879,174 bytes, 98,727 rows in the log
version 30: 31 files, 1,888,288 bytes, 98,727 rows in the log
version 526: 527 files, 3,040,868 bytes, 98,727 rows in the log
ana@laptop:~/azure$ ls lake/by_day | head -4
_delta_log
dt=2026-10-01
dt=2026-10-02
dt=2026-10-03
ana@laptop:~/azure$ python -c "import glob, pyarrow.parquet as pq; print(pq.read_schema(glob.glob('lake/by_day/dt=2026-10-15/*.parquet')[0]).names)"
['order_id', 'hour', 'customer_id', 'neighbourhood', 'payment', 'total_cents']
```

**Os mesmos 98.727 pedidos ocupam 1.205.188 bytes num arquivo e 3.040.868 em 527.** Todo arquivo
Parquet traz um rodapé, um schema e um dicionário por coluna, e arquivos pequenos os trazem mais
vezes por linha. Os arquivos particionados não têm coluna `dt` nenhuma dentro deles: o dia está no
nome da pasta e no log, e o leitor o recoloca.

## Contando o que uma pergunta lê

**Motores serverless cobram pelos bytes que uma consulta lê**: o pool SQL serverless do Synapse da
lição 16 por terabyte processado, e o Fabric em unidades de capacidade que crescem com o trabalho.
Então a medida útil de um arranjo é o que uma pergunta lê dele, e este programa a conta. Ele entrega a
tabela ao DuckDB por um sistema de arquivos que conta cada arquivo aberto e cada byte lido:

```schooling-example
{"language": "python", "file": "measure.py", "parts": [
{"code": "\"\"\"measure.py: ask a Delta table a question and count the bytes read from disk.\n\n    python measure.py PATH \"SQL over a table called orders\"\n\"\"\"\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.fs as fs\nfrom deltalake import DeltaTable\n\n\n", "note": "**O DuckDB responde, e o programa conta o que ele teve de ler.** Motores SQL serverless cobram pelos dados que uma consulta lê, então a contagem é o número que iria para a conta."},
{"code": "class Counting(fs.FileSystemHandler):\n    \"\"\"The local disk, seen through a tap that counts files opened and bytes read.\"\"\"\n\n    def __init__(self, root):\n        self.disk = fs.SubTreeFileSystem(root, fs.LocalFileSystem())\n        self.opened, self.bytes = set(), 0\n\n", "note": "Um sistema de arquivos do PyArrow escrito em Python. Ele repassa cada pedido ao disco de verdade, com a raiz na pasta da tabela, e mantém duas contagens no caminho."},
{"code": "    def open_input_file(self, path):\n        self.opened.add(path)\n        inner, tap = self.disk.open_input_file(path), self\n\n        class Tap:\n            closed = False\n\n            def read(self, n=-1):\n                data = inner.read(n)\n                tap.bytes += len(data)\n                return data\n\n            def seek(self, offset, whence=0): return inner.seek(offset, whence)\n            def tell(self): return inner.tell()\n            def size(self): return inner.size()\n            def close(self): inner.close()\n            def readable(self): return True\n            def seekable(self): return True\n            def writable(self): return False\n\n        return pa.PythonFile(Tap(), mode=\"r\")\n\n", "note": "**A torneira.** Abrir um arquivo registra o nome dele, e cada `read` soma o que devolveu à contagem de bytes. Um leitor de Parquet pula pelo arquivo, primeiro até o rodapé no fim e depois até os pedaços de coluna de que precisa, então `seek` e `tell` são repassados direto."},
{"code": "    def open_input_stream(self, path): return self.open_input_file(path)\n    def get_file_info(self, paths): return self.disk.get_file_info(paths)\n    def get_file_info_selector(self, selector): return self.disk.get_file_info(selector)\n    def get_type_name(self): return \"counting\"\n    def normalize_path(self, path): return path\n    def __eq__(self, other): return self is other\n    def __ne__(self, other): return self is not other\n\n    def _refuse(self, *args): raise NotImplementedError(\"read-only\")\n    create_dir = delete_dir = delete_dir_contents = delete_root_dir_contents = _refuse\n    delete_file = move = copy_file = open_output_stream = open_append_stream = _refuse\n\n\n", "note": "O resto da interface que um sistema de arquivos precisa ter. Ler só pede as cinco primeiras; a metade de escrita recusa, porque medir uma pergunta nunca pode mudar a tabela."},
{"code": "path, question = sys.argv[1], sys.argv[2]\ntap = Counting(path)\ntable = DeltaTable(path)\norders = table.to_pyarrow_dataset(filesystem=fs.PyFileSystem(tap))\nduckdb.sql(question).show()\nprint(f\"read {tap.bytes:,} bytes from {len(tap.opened)} of {len(table.file_uris())} files\")\n", "note": "**O `deltalake` lê o log e monta o dataset; o DuckDB lê os arquivos pela torneira.** O DuckDB acha `orders` no programa pelo nome, empurra as colunas e os filtros da pergunta para o dataset, e o dataset pula qualquer arquivo que a partição ou as estatísticas descartem. O que se imprime por último é o que passou pela torneira."}
]}
```

A pergunta sobre o mês, as vendas de outubro por forma de pagamento, feita ao arquivo único e aos 31
dias:

```
ana@laptop:~/azure$ python measure.py lake/one "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │  42487 │ 6989795.82 │
│ credit       │  32725 │ 5364244.14 │
│ debit        │  14202 │  2317012.7 │
│ meal-voucher │   9313 │ 1538313.03 │
└──────────────┴────────┴────────────┘

read 396,833 bytes from 1 of 1 files
ana@laptop:~/azure$ python measure.py lake/by_day "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC" | tail -1
read 2,442,170 bytes from 31 of 31 files
```

**O arquivo único foi lido em parte, 396.833 dos seus 1.205.188 bytes**: duas colunas de sete, que é
o formato de colunas fazendo o trabalho dele. **Os 31 dias foram lidos inteiros e mais um pouco,
2.442.170 bytes de 1.879.174 no disco.** Cada arquivo diário tem uns 60 KB, menos que o primeiro
pedaço que o PyArrow lê do fim de um arquivo para achar o rodapé, então essa primeira leitura trouxe
cada arquivo inteiro, e os pedaços de coluna foram buscados de novo. O particionamento não deu a esta
pergunta nada para pular, só mais arquivos para abrir.

Agora a pergunta sobre um dia:

```
ana@laptop:~/azure$ python measure.py lake/one "SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'"
┌────────┬──────────┐
│ orders │  reais   │
│ int64  │  double  │
├────────┼──────────┤
│   2999 │ 493412.7 │
└────────┴──────────┘

read 372,157 bytes from 1 of 1 files
ana@laptop:~/azure$ python measure.py lake/by_day "SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'" | tail -1
read 73,813 bytes from 1 of 31 files
ana@laptop:~/azure$ python measure.py lake/daily "SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'" | tail -1
read 74,167 bytes from 1 of 31 files
```

**A tabela particionada abriu uma pasta de 31 e leu 73.813 bytes, um quinto do que custou o arquivo
único.** O arquivo único teve de ser lido pela coluna `dt` para achar os 2.999 pedidos do dia 15,
porque um arquivo só guarda todos os dias e as estatísticas dele dizem apenas "de 1 a 31".

**`daily` foi igualmente bem sem partição nenhuma, 74.167 bytes de 1 arquivo de 31.** Cada arquivo
dele foi escrito pelo append de uma noite, então as estatísticas de cada arquivo no log dizem que o
menor e o maior `dt` dele são o mesmo dia, e o leitor pulou os outros trinta só com isso. Isso se
chama data skipping, e é por isso que uma tabela escrita na ordem em que é consultada precisa de
menos partições do que as pessoas imaginam. A documentação do Databricks vai além e desaconselha
particionar tabelas abaixo de um terabyte, deixando o pulo por conta das estatísticas.

## Um delete numa tabela particionada

```
ana@laptop:~/azure$ python table.py lake/by_day delete "order_id = '1015-00042'"
1 deleted, 2,998 copied into 1 new file(s); now version 1
```

**O mesmo pedido, apagado da tabela particionada, copiou 2.998 linhas em vez de 98.726.** O dia do
pedido era o único arquivo que podia contê-lo, então só esse dia foi reescrito. Uma tabela cujas
linhas são corrigidas, canceladas ou apagadas por motivo de privacidade paga cada delete em linhas
copiadas, e o particionamento, ou a ordenação, decide quantas.

## Escolhendo a coluna

**Uma coluna de partição deve ser uma que a maioria das perguntas filtra e que tem poucos valores.**
Para a Quitanda é `dt`: quase toda pergunta cita um período, e um mês tem 31 valores. Uma partição por
`customer_id` seria uma pasta por cliente, milhares delas, cada uma com um arquivo de poucos
kilobytes, e toda pergunta sobre um dia abriria todas. **A próxima seção mede quanto arquivos demais
custam**, com o arranjo `hourly`, que é a mesma falha produzida por escrever com frequência demais em
vez de cortar fino demais.
