---
title: O log, e o que um delete escreve de verdade
version: 1
---

**Uma tabela Delta nunca muda um arquivo que já escreveu.** Toda mudança, um insert, um delete, um
update, uma compactação, escreve arquivos Parquet novos e um commit novo no `_delta_log` que os
adiciona e tira os antigos da tabela. Os arquivos antigos ficam no disco. Essa regra explica a viagem
no tempo, explica por que uma tabela pode ser lida enquanto é escrita, e explica quase tudo o que uma
tabela Delta custa. A lição 17 mostrou o primeiro commit; esta seção faz um segundo e observa o que
ele faz.

**Tudo nesta lição roda no seu computador, no disco local**, com a mesma biblioteca `deltalake` que a
lição 17 usou e nenhum emulador. Uma tabela Delta é a mesma pasta num disco, num contêiner de blobs ou
no OneLake, e num disco você pode dar `ls` nela. Nenhum serviço do Azure participa, e nenhum é
imitado.

O terminal é o da lição 1, em `~/azure`, com o ambiente virtual ativo e o `orders.py` da lição 17
salvo ali. Mais um programa cuida de uma tabela pela linha de comando:

`table.py`:

```schooling-example
{"language": "python", "file": "table.py", "parts": [
{"code": "\"\"\"table.py: look after a Delta table from the command line.\n\n    python table.py PATH[@VERSION] files | history | read | compact | delete PREDICATE | vacuum HOURS [force]\n\"\"\"\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.compute as pc\nfrom deltalake import DeltaTable\n\n\ndef open_table(arg):\n    path, _, version = arg.partition(\"@\")\n    return DeltaTable(path, version=int(version) if version else None)\n\n\n", "note": "**`lake/flat@3` abre a tabela como ela era na versão 3.** Sem `@`, abre a versão mais nova. Todas as ações abaixo recebem a tabela aberta desse jeito."},
{"code": "def files(t):\n    adds = pa.table(t.get_add_actions(flatten=True))\n    size = pc.sum(adds[\"size_bytes\"]).as_py()\n    print(f\"version {t.version()}: {adds.num_rows} files, {size:,} bytes, {t.count():,} rows in the log\")\n\n\n", "note": "**`files` lê só o log**: as ações `add` da versão, os tamanhos delas e as contagens de linhas que as estatísticas carregam. Não abre nenhum arquivo Parquet, o que importa no fim da lição."},
{"code": "def history(t):\n    for h in reversed(t.history()):\n        counts = {k: v for k, v in (h.get(\"operationMetrics\") or {}).items()\n                  if k.startswith(\"num\") and v}\n        print(f\"{h['version']:>4} {h['operation']:<9} {counts}\")\n\n\n", "note": "Uma linha por commit, do mais antigo ao mais novo, com as contagens que quem escreveu registrou no `commitInfo`. Os tempos também são registrados e ficam de fora, porque mudam a cada execução."},
{"code": "def read(t):\n    paths = t.file_uris()\n    try:\n        rows = duckdb.execute(\"SELECT count(*) FROM read_parquet(?)\", [paths]).fetchone()[0]\n        print(f\"version {t.version()}: {rows:,} rows read from {len(paths)} files\")\n    except duckdb.IOException as e:\n        print(f\"version {t.version()} cannot be read: {str(e).splitlines()[0]}\")\n\n\n", "note": "**`read` abre cada arquivo Parquet que a versão cita**, pelo DuckDB, e conta as linhas deles, e essa é a diferença para o `files`. Um arquivo que o log cita e o disco não tem mais é informado numa linha."},
{"code": "def compact(t):\n    m = t.optimize.compact()\n    print(f\"{m['numFilesRemoved']} files removed, {m['numFilesAdded']} added; now version {t.version()}\")\n\n\n", "note": "A compactação reescreve muitos arquivos pequenos de uma partição em poucos grandes, como um commit novo."},
{"code": "def delete(t, predicate):\n    m = t.delete(predicate)\n    print(f\"{m['num_deleted_rows']} deleted, {m['num_copied_rows']:,} copied into \"\n          f\"{m['num_added_files']} new file(s); now version {t.version()}\")\n\n\n", "note": "Um delete recebe uma condição SQL. As métricas dele dizem quantas linhas saíram, e **quantas tiveram de ser copiadas** para isso."},
{"code": "def vacuum(t, hours, force=None):\n    gone = t.vacuum(retention_hours=int(hours), dry_run=False, enforce_retention_duration=force != \"force\")\n    print(f\"{len(gone)} files deleted from disk\")\n\n\n", "note": "**O vacuum apaga do disco os arquivos de que nenhuma versão recente precisa.** `HOURS` é até quando, para trás, uma versão precisa continuar legível, e a biblioteca recusa qualquer coisa abaixo do padrão dela a menos que se passe `force`."},
{"code": "if __name__ == \"__main__\":\n    table, action, *rest = sys.argv[1:]\n    {\"files\": files, \"history\": history, \"read\": read, \"compact\": compact,\n     \"delete\": delete, \"vacuum\": vacuum}[action](open_table(table), *rest)\n"}
]}
```

Grave o mês como uma tabela, veja o que ficou no disco e apague um pedido:

```
ana@laptop:~/azure$ python -c "from deltalake import write_deltalake; from orders import october; write_deltalake('lake/flat', october())"
ana@laptop:~/azure$ find lake/flat -type f | sort
lake/flat/_delta_log/00000000000000000000.json
lake/flat/part-00000-ad802eef-bf0b-4c1c-85de-5affc3f3578f-c000.snappy.parquet
ana@laptop:~/azure$ python table.py lake/flat files
version 0: 1 files, 1,205,188 bytes, 98,727 rows in the log
ana@laptop:~/azure$ python table.py lake/flat delete "order_id = '1015-00042'"
1 deleted, 98,726 copied into 1 new file(s); now version 1
ana@laptop:~/azure$ python table.py lake/flat files
version 1: 1 files, 710,217 bytes, 98,726 rows in the log
```

**Um pedido apagado, 98.726 copiados.** Arquivos Parquet não podem ser editados no lugar, então
remover uma linha é escrever um arquivo novo com todas as outras linhas do antigo. A tabela tinha um
arquivo, então o mês inteiro foi reescrito para apagar um pedido. O arquivo novo é menor, 710.217
bytes contra 1.205.188, por um motivo que não tem nada a ver com o delete: a biblioteca comprimiu a
reescrita com zstd, onde a primeira escrita usou Snappy. O codec é escolhido por quem escreve um
arquivo, toda vez.

O commit diz exatamente isso, e nada mais:

```
ana@laptop:~/azure$ jq -c 'if .add then {add: .add.path} elif .remove then {remove: .remove.path, dataChange: .remove.dataChange} else empty end' lake/flat/_delta_log/00000000000000000001.json
{"add":"part-00000-28ae7e46-8a47-4264-a4f0-38d5831e40e9-c000.zstd.parquet"}
{"remove":"part-00000-ad802eef-bf0b-4c1c-85de-5affc3f3578f-c000.snappy.parquet","dataChange":true}
ana@laptop:~/azure$ ls lake/flat/*.parquet | wc -l
2
```

**`remove` tira o arquivo antigo da tabela e o deixa no disco.** A versão 1 é só o arquivo novo; a
versão 0 continua sendo só o antigo, e as duas são legíveis, porque os dois arquivos estão lá. O
custo é que a pasta agora guarda dois meses de pedidos, e qualquer coisa que leia a pasta em vez do
log conta os dois:

```
ana@laptop:~/azure$ python table.py lake/flat read
version 1: 98,726 rows read from 1 files
ana@laptop:~/azure$ python -c "import duckdb; duckdb.sql(\"SELECT count(*) AS orders FROM 'lake/flat/*.parquet'\").show()"
┌────────┐
│ orders │
│ int64  │
├────────┤
│ 197453 │
└────────┘

```

**197.453 pedidos: o mês duas vezes, menos o que foi apagado.** É o erro mais comum com uma tabela
Delta: apontar para a pasta uma ferramenta que só conhece Parquet. O SQL serverless do Synapse, da
lição 16, lê uma pasta de arquivos Parquet e também lê a mesma pasta como Delta, e só a segunda
resposta está certa. Todo motor das próximas três lições lê o log.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois commits no _delta_log ao lado de dois arquivos Parquet no disco. O commit 0 adiciona o arquivo A, Snappy, 1.205.188 bytes e 98.727 pedidos. O commit 1 remove A e adiciona B, zstd, 710.217 bytes e 98.726 pedidos. Os dois arquivos continuam no disco. Quem lê o log vê a versão 1 como só B, 98.726 pedidos; quem lê a pasta vê A e B juntos, 197.453 pedidos.\" data-fig=\"l18-log\"><defs><marker id=\"l18-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">_delta_log/</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no disco</text><rect x=\"20\" y=\"36\" width=\"320\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000000000.json</text><text x=\"32\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add A</text><text x=\"328\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">versão 0</text><rect x=\"20\" y=\"100\" width=\"320\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"32\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000000001.json</text><text x=\"32\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remove A, add B</text><text x=\"328\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">versão 1</text><rect x=\"400\" y=\"36\" width=\"300\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"412\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">A  …-c000.snappy.parquet</text><text x=\"412\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.205.188 bytes, 98.727 pedidos</text><rect x=\"400\" y=\"100\" width=\"300\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"412\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">B  …-c000.zstd.parquet</text><text x=\"412\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">710.217 bytes, 98.726 pedidos</text><line x1=\"340\" y1=\"62\" x2=\"397\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-ah)\"/><line x1=\"340\" y1=\"126\" x2=\"397\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l18-ah)\"/><rect x=\"20\" y=\"176\" width=\"330\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"185\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">quem lê o log</text><text x=\"185\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a versão 1 é só B: 98.726 pedidos</text><rect x=\"370\" y=\"176\" width=\"330\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"535\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">quem lê a pasta</text><text x=\"535\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A e B juntos: 197.453 pedidos</text></svg>", "caption": "O delete de um pedido do jeito que o log o registra. Nada no disco foi alterado ou apagado: um arquivo novo foi adicionado, e o log parou de citar o antigo."}
```

## Por que é seguro ler enquanto ela muda

**Um commit é um arquivo, e um arquivo existe ou não existe.** Quem escreve grava primeiro os
arquivos Parquet, onde nenhum leitor olha, e depois cria o próximo arquivo JSON numerado no
`_delta_log`. Um leitor lista o log, pega o maior número que encontra e lê exatamente os arquivos que
aquela versão cita. Um leitor que começou antes do commit lê a versão 0 até o fim; um que começa
depois lê a versão 1. Nenhum deles vê meio delete.

**Dois escritores disputando o mesmo número é o único caso difícil**, e o armazenamento resolve: o
arquivo do commit só é criado se não existir nenhum com aquele nome, e quem perde lê o que o vencedor
fez e tenta de novo com o número seguinte. Num disco local e no Azure Blob Storage, esse "criar só se
não existir" é uma operação que o próprio armazenamento oferece, e é por isso que o `deltalake`
conseguiu gravar no Azurite na lição 17 sem um serviço de trava ao lado.
