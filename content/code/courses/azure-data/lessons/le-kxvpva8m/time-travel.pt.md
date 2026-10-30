---
title: A viagem no tempo, e o vacuum que a encerra
version: 1
---

**Toda versão de uma tabela Delta continua legível enquanto os arquivos dela continuam no disco.** O
log diz que arquivos cada versão tinha; os arquivos continuam lá porque nenhum commit apaga um
arquivo. Isso torna o passado de uma tabela de graça para consultar, e é o que as duas seções
anteriores pagaram em disco: um pedido apagado, um mês de arquivos pequenos, cada um ainda ocupando
espaço depois que a tabela parou de usá-lo.

## Lendo o passado

A tabela `hourly` tem 528 versões, de 0 a 527, uma por commit:

```
ana@laptop:~/azure$ python table.py lake/hourly history | sed -n 1,3p
   0 WRITE     {'num_added_files': 1, 'num_added_rows': 187}
   1 WRITE     {'num_added_files': 1, 'num_added_rows': 168}
   2 WRITE     {'num_added_files': 1, 'num_added_rows': 171}
ana@laptop:~/azure$ python table.py lake/hourly history | tail -2
 526 WRITE     {'num_added_files': 1, 'num_added_rows': 172}
 527 OPTIMIZE  {'numFilesAdded': 31, 'numFilesRemoved': 527, 'numBatches': 527}
ana@laptop:~/azure$ ls lake/hourly/_delta_log | grep -v json
00000000000000000099.checkpoint.parquet
00000000000000000199.checkpoint.parquet
00000000000000000299.checkpoint.parquet
00000000000000000399.checkpoint.parquet
00000000000000000499.checkpoint.parquet
_last_checkpoint
```

**Um leitor não repassa 528 arquivos JSON para achar a versão mais nova.** A cada cem commits a
biblioteca escreveu um checkpoint, o estado inteiro da tabela naquela versão num arquivo Parquet, e
`_last_checkpoint` diz qual é o mais novo. Um leitor começa ali e repassa só os commits depois dele,
28 aqui. O Delta do Spark os escreve pelo mesmo princípio, num intervalo próprio.

A versão 100 é a tabela depois das primeiras 101 cargas horárias, pouco mais que os cinco primeiros
dias:

```
ana@laptop:~/azure$ python table.py lake/hourly@100 files
version 100: 101 files, 576,494 bytes, 18,577 rows in the log
ana@laptop:~/azure$ python table.py lake/hourly@100 read
version 100: 18,577 rows read from 101 files
```

**Isso é a viagem no tempo**: o Spark a escreve `SELECT * FROM orders VERSION AS OF 100`, ou `TIMESTAMP
AS OF` um instante, e o Spark do Fabric e o Databricks também. É como um time responde "o que o painel
mostrava na terça?", e como desfaz uma carga ruim: o `restore` faz um commit novo cujos arquivos são
os de uma versão mais antiga, e nada é copiado de volta, porque nada se perdeu.

## Vacuum

**O vacuum é a única operação que apaga arquivos de dados**, e apaga os que nenhuma versão mais nova
que um período de retenção ainda cita. A retenção padrão da biblioteca é de sete dias, 168 horas, que
também é o padrão do Delta do Spark; ela recusa menos que isso a menos que se diga duas vezes:

```
ana@laptop:~/azure$ python table.py lake/hourly vacuum 0 2>&1 | tail -1
_internal.DeltaError: Generic error: Invalid retention period, minimum retention for vacuum is configured to be greater than 168 hours, got 0 hours
ana@laptop:~/azure$ python table.py lake/hourly vacuum 0 force
527 files deleted from disk
```

**A recusa é a biblioteca protegendo os leitores**: uma consulta que começou há um minuto pode ainda
estar lendo arquivos da versão anterior à compactação, e um vacuum sem retenção os apaga por baixo
dela. Aqui nada mais lê a tabela, então o `force` é seguro; num lago compartilhado é assim que um job
falha para outra pessoa no meio da noite. Os 527 arquivos pequenos sumiram, e tudo o que precisava
deles também:

```
ana@laptop:~/azure$ python table.py lake/hourly@100 files
version 100: 101 files, 576,494 bytes, 18,577 rows in the log
ana@laptop:~/azure$ python table.py lake/hourly@100 read
version 100 cannot be read: IO Error: No files found that match the pattern "/home/ana/azure/lake/hourly/dt=2026-10-06/part-00000-5b535c4e-7087-411a-82bc-aa5ce85e36de-c000.snappy.parquet"
ana@laptop:~/azure$ python table.py lake/hourly read
version 529: 98,727 rows read from 31 files
ana@laptop:~/azure$ python table.py lake/hourly history | tail -2
 528 VACUUM START {'numFilesToDelete': 527}
 529 VACUUM END {'numDeletedFiles': 527}
```

**A versão 100 continua no log e não está mais no lago.** O `files` lê só o log, então ainda descreve
101 arquivos e 18.577 linhas; o `read` os abre e encontra o primeiro faltando. A versão mais nova está
intacta, porque o vacuum guarda todo arquivo que a versão atual cita. E o vacuum registrou a si mesmo
como dois commits, 528 e 529, então o histórico diz quando o passado foi descartado e quanto dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Barras em pares para a tabela hourly em três momentos. Depois de 527 cargas de hora em hora, versão 526: 527 arquivos na tabela e 527 no disco. Depois da compactação, versão 527: 31 arquivos na tabela e 558 no disco. Depois do vacuum, versão 529: 31 na tabela e 31 no disco.\" data-fig=\"l18-vacuum\"><rect x=\"240\" y=\"14\" width=\"12\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"258\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">arquivos na tabela</text><rect x=\"420\" y=\"14\" width=\"12\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"438\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">arquivos Parquet no disco</text><text x=\"218\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">depois de 527 cargas</text><text x=\"218\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">versão 526</text><rect x=\"230\" y=\"44\" width=\"415.55555555555554\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"651.5555555555555\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">527</text><rect x=\"230\" y=\"64\" width=\"415.55555555555554\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"651.5555555555555\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">527</text><text x=\"218\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">depois da compactação</text><text x=\"218\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">versão 527</text><rect x=\"230\" y=\"106\" width=\"24.444444444444443\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"260.44444444444446\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><rect x=\"230\" y=\"126\" width=\"440.0\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"676.0\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">558</text><text x=\"218\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">depois do vacuum</text><text x=\"218\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">versão 529</text><rect x=\"230\" y=\"168\" width=\"24.444444444444443\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"260.44444444444446\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><rect x=\"230\" y=\"188\" width=\"24.444444444444443\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"260.44444444444446\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><line x1=\"230\" y1=\"36\" x2=\"230\" y2=\"226\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/></svg>", "caption": "O que a tabela cita e o que o disco guarda são duas contagens diferentes. A compactação diminui a primeira e aumenta a segunda; só o vacuum junta as duas, e leva as versões antigas junto."}
```

## As duas retenções

**A viagem no tempo precisa que duas coisas ainda existam: a entrada no log e os arquivos**, e cada
uma tem a própria retenção. A do vacuum, sete dias por padrão, decide os arquivos. A do próprio log,
que o Delta do Spark fixa em trinta dias por padrão, decide quanto tempo os commits antigos ficam
antes de os checkpoints os substituírem. Pedir uma versão mais velha que qualquer uma das duas falha.
Um time que quer um ano de histórico guarda um ano de arquivos, e paga cada byte reescrito nesse ano,
o que numa tabela compactada toda noite pode ser muitas vezes o tamanho da própria tabela. Decidir a
retenção é decidir essa conta, e a próxima seção põe números nela.
