---
title: Checkpoints
version: 1
---

**Um checkpoint calcula um DataFrame, grava-o em arquivos e troca o seu plano por uma leitura desses
arquivos.** A linhagem é cortada: o que veio antes deixa de existir para o Spark. O mesmo programa
com `checkpoint` na linha de comando faz checkpoint dos ranks a cada cinco iterações:

```
ana@lab:~/big$ spark-submit lineage.py checkpoint
WARNING: Using incubator modules: jdk.incubator.vector
02:41:15 WARN SparkContext: Spark is not running in local mode, therefore the checkpoint directory must not be on the local filesystem. Directory 'file:///home/ana/big/checkpoints' appears to be on the local filesystem.
iteration  5: plan of    4 lines,  55.8 s, top book 1
iteration 10: plan of    4 lines,  10.0 s, top book 1
iteration 15: plan of    4 lines,   8.6 s, top book 1
iteration 20: plan of    4 lines,   7.7 s, top book 1
twenty iterations: 82.1 s
```

**O plano ficou em quatro linhas**, uma leitura dos arquivos de checkpoint e os passos desde então, e
depois das cinco primeiras iterações cada bloco de cinco levou de 8 a 10 segundos onde o plano
crescente tinha levado de 28 a 41. A execução inteira levou 82,1 segundos, contra 154,7 sem
checkpoints.

**O aviso é sobre o diretório, e num cluster de verdade ele tem razão.** Um checkpoint é gravado
pelos executores e lido de volta por qualquer executor que rode a tarefa seguinte, então ele precisa
estar num armazenamento que toda máquina alcance: o HDFS, ou um object store. Um diretório no disco
local de uma máquina funciona aqui só porque todos os processos deste laboratório dividem um disco, e
o Spark diz isso em vez de supor.

Dois tipos de checkpoint, para duas necessidades diferentes:

| | `checkpoint()` | `localCheckpoint()` |
|---|---|---|
| onde grava | o diretório de checkpoint, em armazenamento compartilhado | o armazenamento de blocos dos próprios executores |
| sobrevive a um executor perdido | sim | não, e a linhagem que ele trocou já não existe |
| custo | uma gravação em armazenamento compartilhado | mais ou menos o de um cache |

**O `localCheckpoint()` serve para cortar um plano, não para segurança.** É um cache que esquece de
onde veio: rápido, e um executor perdido perde as suas partições sem nada de onde refazê-las, então a
aplicação falha. Use-o para manter pequeno o plano de um loop quando não se espera que executores
falhem, e o `checkpoint()` quando uma falha não pode custar a execução inteira.

**Um checkpoint não é um cache, e os dois se combinam.** Um checkpoint é gravado em arquivos e lido
de volta de arquivos; um DataFrame com checkpoint usado várias vezes é lido várias vezes. O padrão
num loop longo é fazer checkpoint a cada poucas iterações, o que limita o plano, e guardar em cache o
que cada iteração lê mais de uma vez.
