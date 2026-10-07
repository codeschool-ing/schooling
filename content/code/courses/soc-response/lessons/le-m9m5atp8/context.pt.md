---
title: O contexto decide
version: 1
---

O mesmo evento quer dizer coisas diferentes em lugares diferentes. Um login falho numa máquina de teste ao
meio-dia é ruído; a mesma linha no servidor da folha de pagamento, às três da manhã, de um país com o qual a
empresa não faz negócio, não é. **O que transforma um alerta numa decisão é o contexto**, e quatro tipos
dele aparecem toda vez:

| contexto | a pergunta que responde | de onde vem |
|---|---|---|
| **o ativo** | quão importante é esta máquina, e que dados ela guarda? | um inventário de ativos com um dono por host |
| **a identidade** | quem é esta conta, o que ela faz normalmente, a pessoa está viajando? | o diretório, o RH, o gestor da pessoa |
| **o histórico** | este endereço, conta ou host já fez isso antes? | o próprio SIEM, ao longo de semanas |
| **o lado de fora** | este endereço ou arquivo é conhecido em outro lugar? | inteligência de ameaças, aula 8 |

O histórico é o que um analista sempre consegue conferir sozinho, e o que mais se pula. Um script pequeno o
transforma num comando. Salve isto em `~/week` como `context.sh`:

```bash
#!/bin/bash
# context.sh ADDRESS: what the week knows about one address, one row per day and kind
sqlite3 -header -column siem.db "SELECT date(timestamp, '-3 hours') AS day, product,
  action, group_concat(DISTINCT user) AS accounts, count(*) AS n
  FROM logs WHERE src_ip = '$1' GROUP BY day, product, action"
```

Ele responde, por dia, *o que este endereço fez, em quais contas, e quantas vezes*. A próxima seção o usa nos
alertas.

Dois avisos sobre contexto. Ele pode estar **desatualizado**: uma lista de ativos que ainda diz que um
servidor é de teste depois de ele ter ido para produção vai baixar a prioridade justamente do alerta que
importava. E ele pode ser **pedido e não recebido**: "o bruno está viajando?" é uma pergunta a uma pessoa, e
a nota de triagem deve dizer que foi feita, a quem e quando, para o próximo analista não perguntar de novo.
