---
title: Achando o momento no log
version: 1
---

"Lá pelas quatro da tarde" não é um alvo de recuperação. O log sabe exatamente quando o erro foi
confirmado, e qual transação foi, porque registrou cada linha que o `DELETE` removeu. O `pg_waldump`
imprime um segmento como uma linha por registro:

```
ana@vm:~$ sudo /usr/lib/postgresql/16/bin/pg_waldump --path=/var/lib/postgresql/16/main/pg_wal 000000010000000000000004 | awk '/desc: DELETE/ {print $8}' | sort | uniq -c
pg_waldump: error: error in WAL record at 0/4165E00: invalid record length at 0/4165EF0: expected at least 24, got 0
  12059 742,
```

Cada linha do dump que descreve uma linha apagada carrega o id da transação que a apagou; o `awk`
pegou esse campo, e o `sort | uniq -c` contou as linhas por transação. **Uma transação, a 742, apagou
12059 linhas**, o número que o `DELETE` informou. Nada mais no segmento apagou coisa alguma.

A linha de erro no topo não é problema. O `pg_waldump` leu até onde o servidor escreveu até agora,
achou o resto do arquivo de 16 MB ainda vazio, e avisou; daqui em diante o `2>/dev/null` a esconde.

Agora os commits, que carregam seus horários:

```
ana@vm:~$ sudo /usr/lib/postgresql/16/bin/pg_waldump --path=/var/lib/postgresql/16/main/pg_wal 000000010000000000000004 2>/dev/null | grep 'desc: COMMIT' | sed -E 's/.*tx: +([0-9]+),.*COMMIT ([^;]*).*/\1  \2/'
737  2026-10-10 16:36:03.338688 -03
738  2026-10-10 16:36:04.396113 -03
739  2026-10-10 16:36:05.436931 -03
740  2026-10-10 16:36:06.476241 -03
741  2026-10-10 16:36:07.514400 -03
742  2026-10-10 16:36:08.563344 -03
743  2026-10-10 16:36:08.600046 -03
744  2026-10-10 16:36:09.641449 -03
745  2026-10-10 16:36:10.677774 -03
```

A história do dia, em ids de transação. De 737 a 741 são os cinco pedidos, um segundo um do outro.
**A 742 foi confirmada às 16:36:08.563**, e de 743 a 745 são os três pedidos depois dela. Agora o alvo
pode ser nomeado com exatidão: tudo até a transação 742, **sem incluí-la**.

Um segmento de verdade guarda muito mais do que este, e o `DELETE` nem sempre é a única transação com
milhares de linhas. O que faz isso funcionar na prática é o que você já sabe: mais ou menos quando,
qual tabela e mais ou menos quantas linhas. O `pg_waldump` pode ser apontado para uma tabela, com
`--relation`, e para um trecho do log, com `--start` e `--end`, e isso reduz um segmento movimentado
a um punhado de candidatos. Para um erro mais antigo que os segmentos ainda no servidor, os
arquivados são buscados com `pgbackrest archive-get`, e os mesmos comandos funcionam neles.
