---
title: O log de transações
version: 1
---

Cada commit é um arquivo JSON em `_delta_log`, numerado a partir de zero, e cada linha dele é uma **ação**. Eis o
que é cada linha do primeiro commit:

```
ana@lab:~/wh$ ls lake/sales/_delta_log
00000000000000000000.json
00000000000000000001.json
ana@lab:~/wh$ jq -c 'keys[0]' lake/sales/_delta_log/00000000000000000000.json
"commitInfo"
"protocol"
"metaData"
"add"
ana@lab:~/wh$ jq -c 'select(.add) | .add | {partitionValues, size, records: (.stats | fromjson | .numRecords)}' lake/sales/_delta_log/00000000000000000001.json
{"partitionValues":{"year":"2025"},"size":5170360,"records":483410}
```

O commit 0 tem quatro ações:

- **`commitInfo`**: quem escreveu, quando, com que operação, `WRITE` aqui, e seus parâmetros.
- **`protocol`**: qual versão do protocolo Delta um leitor precisa para entender a tabela, para que um leitor
  antigo recuse uma tabela que não sabe ler em vez de lê-la errado.
- **`metaData`**: o esquema da tabela, suas colunas de partição e suas configurações.
- **`add`**: um arquivo de dados entrando na tabela.

O último comando olha dentro da ação `add` do commit 1. Além do caminho do arquivo, omitido aqui porque é um nome
aleatório, ela traz o valor da partição, o tamanho do arquivo em bytes e **estatísticas**: o número de registros,
e o mínimo, o máximo e a contagem de valores vazios de cada coluna. 483.410 registros, o ano de 2025.

**Para ler a tabela, um leitor reproduz o log**: começa do nada, aplica cada commit em ordem, acrescentando e
removendo arquivos, e o conjunto que sobra no fim é a tabela atual. Uma tabela com milhares de commits grava de
tempos em tempos um **checkpoint**, um arquivo Parquet com o estado naquele commit, para que o leitor comece do
checkpoint mais recente em vez de começar do zero.

Duas consequências importam mais do que os detalhes:

- **Um commit é um arquivo aparecendo.** O armazenamento de objetos consegue criar um arquivo de forma atômica, e
  os números de commit são reivindicados em ordem; se dois escritores tentam gravar o commit 2 ao mesmo tempo, um
  consegue e o outro o encontra ocupado, relê e tenta de novo. É assim que dois jobs gravando uma tabela se mantêm
  consistentes sem servidor nenhum entre eles.
- **O log é a tabela.** Apague `_delta_log` e a pasta volta a ser uma pilha de arquivos Parquet sem nada que diga
  quais pertencem juntos.
