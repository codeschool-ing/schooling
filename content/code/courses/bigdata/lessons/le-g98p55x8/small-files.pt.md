---
title: O problema dos arquivos pequenos
version: 1
---

**O namenode guarda na memória cada arquivo, cada diretório e cada bloco**, e esse é o limite que o
HDFS de fato encontra primeiro. Uma regra de bolso repetida nas orientações do próprio Hadoop dá a
cada um desses objetos cerca de 150 bytes da memória do namenode. É uma aproximação, e basta para
mostrar de onde vem o problema.

Ponha os cliques no HDFS uma segunda vez, do jeito que a aula 1 os escreveu: um arquivo pequeno por
dia.

```
ana@lab:~/big$ time hdfs dfs -put data/raw/clicks /raw/clicks-daily

real	0m29.725s
user	0m12.072s
sys	0m2.241s
```

Agora pergunte ao `fsck` sobre as duas cópias dos mesmos dados:

```
ana@lab:~/big$ hdfs fsck /raw/clicks-2025.csv | grep -E 'Total (size|files|blocks)'
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
 Total size:	1291239322 B
 Total files:	1
 Total blocks (validated):	10 (avg. block size 129123932 B)
 Total size:	0 B
 Total files:	0
ana@lab:~/big$ hdfs fsck /raw/clicks-daily | grep -E 'Total (size|files|blocks)'
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-daily
 Total size:	248921266 B
 Total files:	366
 Total blocks (validated):	365 (avg. block size 681976 B)
 Total size:	0 B
 Total files:	0
```

Cada resposta imprime os totais duas vezes, e o segundo conjunto, todo zerado, conta arquivos
guardados com erasure coding, uma alternativa às três cópias que economiza espaço e que este
laboratório não usa.

**Os mesmos eventos. Uma cópia são 10 blocos; a outra são 365, cada um uma fração de
megabyte** (a cópia diária está em gzip, então é menor em bytes e maior em tudo o que custa). Para o
namenode, a cópia diária é trinta e seis vezes mais coisa a lembrar. E para o Spark serão 365
tarefas de poucos milissegundos de leitura cada, contra 10 tarefas de um bloco inteiro: o custo
fixo por tarefa da aula 2, pago 365 vezes.

Neste tamanho não faz diferença. No tamanho de um site grande, decide se o cluster funciona:

| | objetos no namenode | a cerca de 150 bytes cada |
|---|---|---|
| 1 PB em arquivos de 1 GB | 1 milhão de arquivos + 8 milhões de blocos | cerca de 1,4 GB |
| 1 PB em arquivos de 1 MB | 1 bilhão de arquivos + 1 bilhão de blocos | cerca de 300 GB |

A segunda linha é o mesmo petabyte. **Nenhum namenode guarda 300 GB de metadados com folga, e os
dados não cresceram nada**: só chegaram em pedaços menores. Arquivos pequenos vêm de jobs que
escrevem com frequência (um arquivo por minuto por fluxo), de jobs com tarefas demais (cada tarefa
escreve o próprio arquivo, e a aula 8 encontra um que escreveu duzentos) e de particionar por uma
coluna com valores demais.

A cura é escrever menos arquivos, e maiores, ou na origem ou por um job de *compactação* que lê os
arquivos pequenos e os reescreve como grandes. Os formatos de tabela da aula 11 trazem compactação
embutida, porque object stores sofrem da mesma doença em outro órgão: não têm namenode, mas todo
arquivo pequeno continua sendo uma requisição, e uma requisição tem custo e latência.
