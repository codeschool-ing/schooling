---
title: Da caçada à regra
version: 1
---

O melhor resultado de uma caçada que achou algo é que **ninguém precisa caçar aquilo de novo**. A aula 9
mostrou a transferência que importava: um envio grande do `files` para um endereço que não era o do backup.
Escrita como regra, com a caçada de onde veio na descrição, salve isto como `big-upload.yml`:

```yaml
title: Large transfer out to a destination other than the backup
id: 8d2f6b31-4c7e-4a05-9e18-3b7a0c5d2f94
status: test
description: From the hunt of 21 September 2026. The backup provider is the only known large destination.
logsource:
  category: flow
  product: network
detection:
  large:
    product: flow
    bytes|gte: 100000000
  backup:
    dst_ip: 203.0.113.150
  condition: large and not backup
level: high
```

Duas seleções e uma condição com `not`: fluxos grandes, menos para o único destino que se sabe que os
recebe. Converta e rode contra a semana:

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite big-upload.yml
Parsing Sigma rules
SELECT * FROM logs WHERE (product='flow' AND bytes >= 100000000) AND (NOT COALESCE((dst_ip='203.0.113.150'), 0))
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite big-upload.yml -o big.sql
Parsing Sigma rules
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT timestamp, src_ip, dst_ip, bytes FROM ($(cat big.sql))"
timestamp            src_ip         dst_ip         bytes    
-------------------  -------------  -------------  ---------
2026-09-17 05:41:12  192.168.20.10  203.0.113.200  612408119
```

Uma linha, a transferência de 612 MB de quinta às 02:41 locais (05:41:12 UTC), e nenhum dos sete backups. O
limiar de 100 MB é um julgamento, e o método da aula 6 se aplica: conte o que ele aponta num período conhecido
antes de confiar nele. Duas tarefas de manutenção vêm com esta regra e cabem na descrição dela: a lista
`backup` precisa mudar quando a empresa trocar de provedor, e **a regra não diz nada sobre transferências que
ficam abaixo de 100 MB**, coisa que um adversário paciente consegue arranjar.

Uma caçada que termina em regra também deve atualizar o mapeamento da aula 9: o T1048.002 agora tem detecção.
Com o tempo, uma equipe que transforma cada caçada em regras vê encolher as células descobertas do seu mapa
ATT&CK, e esse mapa é a resposta honesta mais simples para a pergunta "o que conseguimos ver?".
