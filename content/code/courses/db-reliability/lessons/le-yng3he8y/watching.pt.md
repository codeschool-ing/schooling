---
title: Vigiando o log atrás do formato do dano
version: 1
---

O dano num banco tem um formato antes que alguém leia uma única linha: uma quantidade enorme de
mudança num tempo muito curto. Reescrever todas as linhas de todas as tabelas escreve o write-ahead log
num ritmo que o tráfego comum nunca alcança, e a aritmética de LSN da lição 4 consegue medir esse ritmo
a cada poucos segundos. Salve isto como `walwatch.sh`:

```schooling-example
{"language": "bash", "file": "walwatch.sh", "parts": [{"code": "#!/usr/bin/env bash\n# walwatch.sh: say how much log was written in each interval, and shout past a limit\nset -euo pipefail\ninterval=${1:-5}\nlimit_mb=${2:-50}\nlast=$(psql -X -A -t -d shop -c \"SELECT pg_current_wal_lsn()\")\nwhile sleep \"$interval\"; do\n  now=$(psql -X -A -t -d shop -c \"SELECT pg_current_wal_lsn()\")\n  mb=$(psql -X -A -t -d shop -c \"SELECT (pg_wal_lsn_diff('$now', '$last') / 1048576)::int\")", "note": "A cada intervalo, lê a posição do servidor no log e imprime quantos megabytes foram escritos desde a última leitura."}, {"code": "  if [ \"$mb\" -gt \"$limit_mb\" ]; then\n    echo \"$(date +%T) ${mb} MB  ALERT: more than ${limit_mb} MB in ${interval} s\"\n  else\n    echo \"$(date +%T) ${mb} MB\"\n  fi\n  last=$now\ndone", "note": "Passado o limite, a linha avisa. Em produção, esta linha acionaria alguém de plantão em vez de imprimir."}]}
```

No shop, o trabalho comum quase não escreve nada, então um limite de 10 MB em 5 segundos é generoso.
Num sistema de verdade, o limite vem de observar os dias normais primeiro, e fica acima do momento
normal mais movimentado, como o batch noturno.

Deixe-o rodando em segundo plano. Depois faça você mesmo o último passo do intruso, no seu próprio
laboratório: reescreva o nome e a cidade de cada cliente como ruído, e o total de cada pedido como um
centavo.

```
ana@vm:~$ ./walwatch.sh 5 10 > walwatch.log &
shop=# UPDATE customers SET name = md5(name), city = md5(city);
UPDATE 1000

shop=# UPDATE orders SET total_cents = 1;
UPDATE 50003
ana@vm:~$ cat walwatch.log
21:54:17 0 MB
21:54:22 19 MB  ALERT: more than 10 MB in 5 s
21:54:27 0 MB
```

**`19 MB  ALERT`** no intervalo em que os dois comandos rodaram, e silêncio dos dois lados. Os dois
`UPDATE`s são SQL comum que qualquer um com as permissões poderia digitar, e é exatamente essa a
questão: nada neles é incomum, a não ser o quanto mudaram de uma vez.

O shop agora está assim:

```
shop=# SELECT name, city FROM customers ORDER BY id LIMIT 3;
               name               |               city               
----------------------------------+----------------------------------
 1c1e3dd095316f30724ac021ca3b95b8 | fec8c8f7fccdb0825811a7ad2cb2e0a0
 e3adaa38a12fed1f930b3ba74afddffa | 0164ddf9ddc99107b29e7107530e700b
 58b905bf1e0555ce2c8b3912192cd7a9 | 3b7bf0a2e00574c0530f21aa8d315782
(3 rows)

shop=# SELECT count(*), sum(total_cents) FROM orders;
 count |  sum  
-------+-------
 50003 | 50003
(1 row)
```

Um alerta de ritmo não diz o que aconteceu, só que algo grande aconteceu, e quando. **O quando é o que
a recuperação precisa**: o horário do alerta, menos um intervalo, é um ponto antes do dano, e a lição
6 sabe restaurar até ele. O mesmo sinal pega uma migração que alguém rodou sem avisar ninguém, uma
rotina descontrolada e um update feito por engano; todos valem acionar alguém de plantão.

## O que mais vigiar

O ritmo do log pega o dano. Os passos anteriores de um ataque deixam outros rastros, e cada um é
barato de vigiar:

- **Backups sumindo**: o número de backups em cada repositório só deveria crescer entre uma execução
  da retenção e outra; uma queda fora do calendário é um alarme.
- **Rotinas de backup ou de arquivamento que pararam**: os alertas de `pg_stat_archiver` da lição 4 e
  a rotina noturna da lição 5 já pegam isso, se o silêncio deles também gerar alerta.
- **Papéis novos, superusuários novos, funções novas**: o inventário da próxima seção, comparado todo
  dia com o do dia anterior.
