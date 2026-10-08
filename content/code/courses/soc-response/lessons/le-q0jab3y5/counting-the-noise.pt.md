---
title: Um evento, quarenta e oito alertas
version: 1
---

**Fadiga de alerta** é o que acontece com quem recebe mais alertas do que consegue ler: a pessoa para de ler
com cuidado, depois para de ler, e o alerta que importava é fechado junto com os outros. Não é defeito de
caráter. É aritmética, e a aritmética começa com alertas que estão certos.

Pegue sozinha a primeira metade da v2 da aula 4, a regra que conta as contas tentadas a partir de um
endereço. Salve-a como `spray.yml`:

```yaml
title: SSH login failure
name: ssh_login_failure
id: 3f1d2c6a-8b7e-4e0f-9a52-6c1b0e7d4a10
status: test
description: One failed SSH login, for a known or an unknown account.
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: failure
  condition: selection
level: low
---
title: Many accounts tried from one address
name: many_accounts_one_source
id: 9c4b7e21-5d3a-4f86-b0e2-1a7c9d3e6f58
status: test
correlation:
  type: value_count
  rules:
    - ssh_login_failure
  group-by:
    - src_ip
  timespan: 1h
  condition:
    field: user
    gte: 10
level: high
```

Converta e rode com o `alerts.sh` da aula 4:

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite spray.yml -o spray.sql
Parsing Sigma rules
ana@soc:~/week$ bash alerts.sh spray.sql | head -n 5
group_keys                 kind         events  at_utc             
-------------------------  -----------  ------  -------------------
{"src_ip":"203.0.113.66"}  value_count  10      2026-09-17 05:11:06
{"src_ip":"203.0.113.66"}  value_count  11      2026-09-17 05:11:11
{"src_ip":"203.0.113.66"}  value_count  12      2026-09-17 05:11:16
ana@soc:~/week$ bash alerts.sh spray.sql | tail -n +3 | wc -l
48
```

**Quarenta e oito alertas, todos certos**, para um evento: um endereço adivinhando por uns cinco minutos. A
correlação reavalia a janela a cada falha nova, e cada janela que ainda tem dez ou mais contas vira mais um
alerta. Uma ferramenta que aciona alguém a cada linha aciona essa pessoa 48 vezes em cinco minutos pela
mesma coisa.

A correção é **agrupar**: um alerta por endereço por episódio, com a contagem dentro. Salve isto como
`grouped.sh`:

```bash
#!/bin/bash
# grouped.sh RULES.sql: the same alerts as alerts.sh, one row per address instead of per window
while IFS= read -r query; do
  sqlite3 -header -column siem.db "SELECT group_keys, count(*) AS windows,
    datetime(min(occurrence_time), 'unixepoch') AS first_utc,
    datetime(max(occurrence_time), 'unixepoch') AS last_utc FROM ($query) GROUP BY group_keys"
done < "$1"
```

```
ana@soc:~/week$ bash grouped.sh spray.sql
group_keys                 windows  first_utc            last_utc           
-------------------------  -------  -------------------  -------------------
{"src_ip":"203.0.113.66"}  48       2026-09-17 05:11:06  2026-09-17 05:16:32
```

Uma linha, dizendo o que as 48 diziam, com o começo e o fim do episódio. Todo SIEM tem uma configuração para
isso, com nomes como agrupamento, deduplicação, supressão ou throttling, e conferi-la é a primeira coisa a
fazer com qualquer regra que conta.
