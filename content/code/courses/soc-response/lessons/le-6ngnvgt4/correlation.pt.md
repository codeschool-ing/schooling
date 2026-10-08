---
title: Correlação, e uma regra que estava errada
version: 1
---

**Correlação** é uma regra sobre vários eventos: quantos, em que ordem, dentro de quanto tempo. O Sigma a
escreve como uma regra que se refere a outras regras pelo nome. A primeira ideia da maioria das pessoas é
"uma falha seguida de um sucesso a partir do mesmo endereço, dentro de uma hora", que soa como alguém
adivinhando até conseguir entrar. Salve-a como `rules-v1.yml`:

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
title: SSH login success
name: ssh_login_success
id: 6a0c3e9b-2d71-4f58-a1e4-8b9d2c7f0e63
status: test
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: success
  condition: selection
level: informational
---
title: Login accepted from an address that failed first
id: 2b8e5f0d-7c41-4a93-8e6b-d50f1c2a9b37
status: test
correlation:
  type: temporal_ordered
  rules:
    - ssh_login_failure
    - ssh_login_success
  group-by:
    - src_ip
  timespan: 1h
level: high
```

Uma correlação vira uma consulta longa, então vai para um arquivo, e um script pequeno roda cada consulta
de um arquivo e mostra uma linha por alerta. Salve isto como `alerts.sh`:

```bash
#!/bin/bash
# alerts.sh RULES.sql: run converted Sigma rules against siem.db, one row per alert
while IFS= read -r query; do
  sqlite3 -header -column siem.db "SELECT group_keys, metric_name AS kind, event_count AS events,
    datetime(occurrence_time, 'unixepoch') AS at_utc FROM ($query)"
done < "$1"
```

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite rules-v1.yml -o v1.sql
Parsing Sigma rules
ana@soc:~/week$ wc -c v1.sql
4788 v1.sql
ana@soc:~/week$ bash alerts.sh v1.sql
group_keys                 kind              events  at_utc             
-------------------------  ----------------  ------  -------------------
{"src_ip":"203.0.113.41"}  temporal_ordered  2       2026-09-14 11:02:51
{"src_ip":"203.0.113.23"}  temporal_ordered  2       2026-09-15 11:39:11
{"src_ip":"203.0.113.23"}  temporal_ordered  2       2026-09-16 11:05:23
{"src_ip":"203.0.113.66"}  temporal_ordered  2       2026-09-17 05:33:07
{"src_ip":"203.0.113.66"}  temporal_ordered  2       2026-09-17 06:05:22
```

Cinco alertas. Dois são de `203.0.113.66` na noite de quinta. **Três não são.** Olhe um deles:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT timestamp, user, action FROM logs WHERE src_ip = '203.0.113.23' AND product = 'sshd'"
timestamp            user   action 
-------------------  -----  -------
2026-09-14 11:18:38  carla  success
2026-09-15 11:39:01  carla  failure
2026-09-15 11:39:11  carla  success
2026-09-16 11:05:14  carla  failure
2026-09-16 11:05:23  carla  success
2026-09-17 11:35:30  carla  success
2026-09-18 11:59:58  carla  success
```

A Carla, do endereço de sempre, falhou uma vez e entrou dez segundos depois, em duas manhãs diferentes.
Os dedos escorregaram. A regra não consegue distingui-la do visitante da noite, porque uma falha seguida
de um sucesso descreve os dois. Três alertas falsos numa semana de cinco pessoas viram centenas numa
empresa de quinhentas, e a aula 6 trata do que isso faz com quem os lê.

A correção é dizer o que de fato foi diferente na quinta: **um endereço tentou muitas contas**, e *depois*
uma delas funcionou. O Sigma deixa uma correlação se referir a outra, então a regra passa a ter dois
passos. Salve isto como `rules-v2.yml`:

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
title: SSH login success
name: ssh_login_success
id: 6a0c3e9b-2d71-4f58-a1e4-8b9d2c7f0e63
status: test
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: success
  condition: selection
level: informational
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
---
title: Login accepted from an address that tried many accounts
id: 5e7a1c40-3b96-4d2f-8c05-a9e2b7d14f6c
status: test
correlation:
  type: temporal_ordered
  rules:
    - many_accounts_one_source
    - ssh_login_success
  group-by:
    - src_ip
  timespan: 1h
level: critical
```

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite rules-v2.yml -o v2.sql
Parsing Sigma rules
ana@soc:~/week$ bash alerts.sh v2.sql
group_keys                 kind              events  at_utc             
-------------------------  ----------------  ------  -------------------
{"src_ip":"203.0.113.66"}  temporal_ordered  11      2026-09-17 05:33:07
{"src_ip":"203.0.113.66"}  temporal_ordered  11      2026-09-17 06:05:22
```

Dois alertas, os dois de `203.0.113.66`: o login com senha às 02:33:07 locais (05:33:07 UTC), e um segundo
meia hora depois, com chave. Ninguém escreveu regra para esse segundo; ele saiu de uma regra que descrevia
o comportamento, e não uma linha. Se esses dois alertas são um incidente é a pergunta da aula 7.

**Teste toda regra contra um período que você conhece.** A v1 parecia razoável e errou três vezes em
cinco; só rodá-la contra uma semana de verdade mostrou isso. Uma regra que ninguém rodou contra os dados
do mês passado é um palpite com uma severidade pendurada.
