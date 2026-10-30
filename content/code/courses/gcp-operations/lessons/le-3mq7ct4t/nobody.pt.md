---
title: O recurso que não é de ninguém
version: 1
---

**Toda fatura tem um resto que não pertence a time nenhum, e é ali que está o desperdício.** Um recurso com dono é
olhado, porque o orçamento de alguém paga por ele. Um recurso sem rótulo não é olhado por ninguém, e continua sendo
cobrado. Os 22,4% da loja são esse resto, e a exportação diz exatamente o que há nele:

```
ana@laptop:~/gcp$ python3 q.py "SELECT project_id, service, resource_name, round(sum(cost), 2) FROM export WHERE label_team IS NULL GROUP BY 1, 2, 3 ORDER BY 4 DESC"
planner-prod	Compute Engine	old-migration	43.49
planner-prod	Cloud Logging	_Default	38.17
planner-dev	Compute Engine	sandbox-ana	32.94
planner-prod	Compute Engine	disk-restore-test	25.26
```

Quatro linhas, e cada uma é um tipo diferente de ninguém:

- **`old-migration`**, 43,49 USD: a máquina ociosa da lição 22. Criada à mão para uma migração avulsa, nunca rotulada,
  nunca apagada. A exclusão em quatro passos da lição 22 é a resposta, e a entrada do log de auditoria que a criou é
  como achar a pessoa a quem perguntar.
- **`_Default`**, 38,17 USD: o bucket padrão do Cloud Logging. Ninguém rotula um bucket de logs, e o custo dele é a
  soma do log de todo mundo. Ele é atribuído pelos sinks da lição 9: rotear os logs de cada time para um bucket próprio
  faz do custo de cada bucket o custo daquele time.
- **`sandbox-ana`**, 32,94 USD: o sandbox de uma pessoa, na pasta `sandbox`. Tem dona, pelo nome, e nenhum rótulo.
  Rotulá-lo `team=ana` ao menos o tornaria visível; um orçamento mensal na pasta sandbox (lição 24) o mantém honesto.
- **`disk-restore-test`**, 25,26 USD: um disco esquecido por um ensaio de restauração. Nenhuma máquina o usa; o
  recomendador de discos ociosos da lição 22 o acharia, e o procedimento de snapshot e depois exclusão o remove.

Dois dos quatro são desperdício (a máquina ociosa e o disco esquecido, 68,75 USD por mês), um é infraestrutura
compartilhada a ser dividida, e um é o experimento de uma pessoa. **O resto não é um problema; é uma lista, e a lista
é o que uma revisão mensal lê.**

## Mantendo o resto pequeno

- **Rótulo na criação, não depois.** Os `default_labels` do Terraform (lição 5) rotulam tudo o que ele cria; recursos
  feitos à mão são onde os rótulos somem, o que é mais um motivo para fazê-los no Terraform.
- **Uma verificação que recusa recurso sem rótulo.** Nenhuma política da organização embutida exige rótulo, mas uma
  esteira pode: um passo que lê o plano do Terraform e falha quando um recurso não tem `team` é barato, e pega a
  omissão antes do apply.
- **Showback, todo mês.** Cada time recebe o total da exportação para o seu rótulo, com o resto ao lado como uma linha
  própria. Ninguém é cobrado; todo mundo vê. Um número de time que se move sem explicação vira uma pergunta feita em um
  mês em vez de um ano.
