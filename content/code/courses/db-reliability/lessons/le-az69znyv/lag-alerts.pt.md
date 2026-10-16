---
title: Um alerta que dispara quando o standby some
version: 1
---

O alerta óbvio é uma consulta que lista todo standby atrás mais do que certa quantidade, com um alerta
sempre que ela devolve uma linha. Com o standby conectado e em dia, ela não devolve nada, o que está
certo. Agora pare o standby e pergunte de novo:

```
ana@vm:~$ psql -XAt shop -c "SELECT application_name FROM pg_stat_replication WHERE pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) > 64 * 1024 * 1024"
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
ana@vm:~$ psql -XAt shop -c "SELECT application_name FROM pg_stat_replication WHERE pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) > 64 * 1024 * 1024"; echo "exit $?"
exit 0
```

Nada, e `exit 0`. **Um standby que não está conectado não tem linha no `pg_stat_replication`**, então
ele está atrás por nada, e a verificação que deveria achar o pior atraso de todos passa em silêncio. O
mesmo acontece com um `SELECT max(...)` sobre a view, que devolve um nulo para o qual nenhuma comparação
é verdadeira. Toda verificação desse tipo tem que ser escrita ao contrário: partir da lista de standbys
que **deveriam** existir, e tratar um que falta como a falha mais barulhenta.

Este script faz isso. Salve-o como `lagcheck.sh` no seu diretório home e torne-o executável com
`chmod +x lagcheck.sh`:

```schooling-example
{"language": "sh", "file": "lagcheck.sh", "parts": [{"code": "#!/bin/sh\n# lagcheck.sh: says how far behind each standby is; exits 1 if one is\n# missing or too far behind\n# usage: ./lagcheck.sh standby1 [standby2 ...]", "note": "Chamado com os nomes dos standbys que deveriam existir. A lista é o ponto: o script não consegue distinguir um standby que sumiu de um que nunca existiu, a não ser que alguém tenha anotado quais são esperados."}, {"code": "max_bytes=$((64 * 1024 * 1024))\nmax_seconds=30\nstatus=0\n\nfor name in \"$@\"; do", "note": "Os dois limites. Bytes dizem quanto seria perdido ou tem que ser reaplicado; segundos dizem quão desatualizada está uma leitura. Escolha-os a partir do RPO da lição 8, e não do que parece normal hoje."}, {"code": "  row=$(psql -XAtq -F ' ' shop -c \"\n    SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)::bigint,\n           coalesce(extract(epoch FROM replay_lag), 0)::int\n    FROM pg_stat_replication WHERE application_name = '$name'\")", "note": "Uma linha por nome esperado. `-A -t` imprimem os valores puros, e `-F ' '` os separa com um espaço, para que o shell possa dividi-los. Um `replay_lag` ausente conta como zero, porque a coluna fica vazia quando o standby está ocioso e em dia."}, {"code": "  if [ -z \"$row\" ]; then\n    echo \"$name: NOT CONNECTED\"\n    status=1\n    continue\n  fi\n  bytes=${row% *}\n  seconds=${row#* }\n  if [ \"$bytes\" -gt \"$max_bytes\" ] || [ \"$seconds\" -gt \"$max_seconds\" ]; then\n    echo \"$name: BEHIND by $bytes bytes, $seconds s\"\n    status=1\n  else\n    echo \"$name: ok, $bytes bytes, $seconds s\"\n  fi\ndone", "note": "Nenhuma linha é o caso que a consulta ingênua deixava passar, então é o primeiro a ser testado."}, {"code": "exit $status", "note": "O exit status é o que um agendador ou um sistema de monitoramento lê. A linha impressa é para a pessoa que ele acorda."}]}
```

Rode-o com o standby parado, depois de subi-lo, e depois com o replay do standby pausado enquanto o
`pgbench` escreve por quarenta segundos:

```
ana@vm:~$ ./lagcheck.sh standby1; echo "exit $?"
standby1: NOT CONNECTED
exit 1
ana@vm:~$ sudo pg_ctlcluster 16 standby start
ana@vm:~$ ./lagcheck.sh standby1; echo "exit $?"
standby1: ok, 0 bytes, 0 s
exit 0
ana@vm:~$ pgbench -c 4 -T 40 -n bench > /dev/null 2>&1
ana@vm:~$ ./lagcheck.sh standby1; echo "exit $?"
standby1: BEHIND by 45096800 bytes, 40 s
exit 1
```

Três respostas, cada uma com seu próprio exit status: **ausente, em dia, atrasado.** A primeira é a que
a consulta ingênua não conseguia dar.

## Onde ele roda

Não só no agendador do próprio primário. Uma verificação que roda no primário morre com o primário, e a
noite em que a máquina do primário some é uma noite em que alguém quer saber do standby. Rode-a do lugar
que já vigia os seus servidores, a cada minuto, com o exit status transformado numa mensagem para uma
pessoa; a rotina noturna da lição 5 e esta podem compartilhar esse caminho. E teste o alerta do jeito
que esta seção fez: **pare o standby de propósito e veja a mensagem chegar.** Um alerta que ninguém viu
disparar é o mesmo tipo de afirmação que um backup que ninguém restaurou.
