---
title: Arquivos pequenos, e a compactação que os desfaz
version: 1
---

**Uma tabela escrita com frequência é uma tabela de arquivos pequenos**, seja qual for o
particionamento. O arranjo `hourly` da seção anterior é o que um job que carrega de hora em hora deixa
para trás: as mesmas partições `dt` de `by_day`, e dezessete arquivos em cada uma em vez de um. Nada
nele está errado quando é escrito, e toda pergunta paga por isso depois.

## Quanto custam 527 arquivos

As duas perguntas da seção anterior, feitas a `hourly`:

```
ana@laptop:~/azure$ python measure.py lake/hourly "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC" | tail -1
read 3,691,565 bytes from 527 of 527 files
ana@laptop:~/azure$ python measure.py lake/hourly "SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'" | tail -1
read 112,456 bytes from 17 of 527 files
```

**O mês leu 3.691.565 bytes, mais que os 3.040.868 que a tabela ocupa**, pelo mesmo motivo dos 31
dias na seção anterior, dezessete vezes. O dia leu 112.456 bytes de 17 arquivos, onde `by_day` leu
73.813 de um: metade a mais, pelos mesmos 2.999 pedidos. E os bytes são a parte menor do custo num
lago de verdade. **Cada arquivo aberto é pelo menos uma requisição de leitura à conta de
armazenamento, e quase sempre duas**, o rodapé e depois as colunas, e a lição 7 mostrou que
requisições são cobradas por dezena de milhar, seja qual for o tamanho delas.

## Compactação

**A compactação reescreve os arquivos pequenos de cada partição em poucos grandes, num commit só.** No
Spark e no Fabric é o comando `OPTIMIZE`; no `deltalake` é `optimize.compact()`, que o `table.py`
chama:

```
ana@laptop:~/azure$ python table.py lake/hourly compact
527 files removed, 31 added; now version 527
ana@laptop:~/azure$ python table.py lake/hourly files
version 527: 31 files, 1,058,322 bytes, 98,727 rows in the log
ana@laptop:~/azure$ python measure.py lake/hourly "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC" | tail -1
read 1,427,062 bytes from 31 of 31 files
ana@laptop:~/azure$ find lake/hourly -name '*.parquet' -not -path '*_delta_log*' | wc -l
558
```

**527 arquivos viraram 31, um por dia, e a pergunta do mês caiu de 3.691.565 bytes para
1.427.062.** A tabela também encolheu, de 3.040.868 bytes para 1.058.322: menos rodapés, e a reescrita
usou zstd, como o delete da primeira seção. A compactação não muda nenhuma linha, e o commit diz isso:

```
ana@laptop:~/azure$ jq -r 'select(.add or .remove) | "\(keys[0]) dataChange=\((.add // .remove).dataChange)"' lake/hourly/_delta_log/00000000000000000527.json | sort | uniq -c
     31 add dataChange=false
    527 remove dataChange=false
```

**`dataChange=false` em toda ação diz a um leitor que acompanha as mudanças da tabela que nada novo
chegou**: um job que lê só o que foi adicionado desde a última execução pula este commit, em vez de
ler o mês inteiro de novo como 31 arquivos "novos".

**O disco agora guarda 558 arquivos Parquet, os 527 antigos e os 31 novos.** A compactação é um
commit como qualquer outro, então tira os arquivos pequenos da tabela e os deixa onde estavam. A conta
de armazenamento subiu, não desceu, e continua alta até o vacuum da última seção.

## Quando compactar

**A compactação é um job, e é agendada como um**: depois que as cargas horárias de um dia terminam,
compacte a partição daquele dia, o que `optimize.compact(partition_filters=...)` faz sem tocar nas
outras trinta. Compactar uma partição que ainda está sendo escrita é trabalho perdido, porque a próxima
hora acrescenta um arquivo pequeno nela de novo. O Databricks consegue compactar enquanto escreve, e
faz manutenção sozinho em algumas tabelas, assunto da lição 21; o Spark do Fabric roda `OPTIMIZE`
quando um notebook ou a manutenção de uma tabela pede.

**O tamanho a buscar é de dezenas a centenas de megabytes por arquivo.** O alvo padrão do próprio
`deltalake` é 100 MB, e o Delta do Spark mira mais alto por padrão, em arquivos de até cerca de um
gigabyte. O mês inteiro da Quitanda tem um megabyte, então aqui um arquivo por dia é o maior que a
compactação consegue fazer, e um lago de verdade chega ao alvo muito antes de chegar ao tamanho que a
Quitanda terá em alguns anos.

**A compactação também pode ordenar.** `optimize.z_order(["neighbourhood"])` reescreve os arquivos
para que linhas com valores próximos nas colunas citadas fiquem nos mesmos arquivos, o que faz as
estatísticas da seção anterior pularem mais num filtro por essas colunas. O `OPTIMIZE ... ZORDER BY`
do Spark é a mesma ideia, e o Databricks tem um jeito mais novo de manter as linhas agrupadas enquanto
são escritas. Isso não foi executado nesta lição: num mês tão pequeno cada arquivo já guarda um dia
inteiro, e não há nada para mostrar.
