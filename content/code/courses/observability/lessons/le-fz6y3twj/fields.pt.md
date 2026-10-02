---
title: Campos: os nomes são a interface
version: 1
---

Uma linha estruturada só é tão útil quanto a consistência dos nomes dos seus campos. **Os nomes são
uma interface**, lida por toda consulta, painel e alerta construídos sobre os logs, e quebram do mesmo
jeito que uma API quebra quando alguém renomeia um campo.

As falhas são corriqueiras. Um serviço escreve `order_id`, outro `orderId`, um terceiro `order`, e uma
busca por um pedido acha um terço das linhas dele. Um serviço escreve durações em milissegundos como
`duration_ms` e outro em segundos como `duration`, e uma consulta comparando os dois erra por mil. Um
escreve `level` e outro `severity`. Nada disso é um erro que alguém vê; cada um é uma pergunta que
devolve em silêncio menos do que devia.

A resposta da loja é a mais barata que existe: **um formatador, compartilhado por todo serviço**, para
que os campos que toda linha carrega sejam escritos num lugar só. Para os campos do próprio evento,
três regras valem em todo o catálogo deste curso:

- **Nomes em `snake_case`, e a unidade no nome** quando houver uma: `duration_ms`, `amount_cents`,
  `size_bytes`.
- **O mesmo nome para a mesma coisa em todo lugar**, e onde o OpenTelemetry já tem um nome, o nome
  dele: `trace_id`, `span_id`, e os nomes de atributo das convenções semânticas quando uma linha de
  log descreve uma chamada HTTP ou uma consulta.
- **Valores de um tipo por campo**: `order_id` é sempre um número, nunca às vezes `"none"`. Um backend
  que indexa campos, como o Elasticsearch da aula 9, decide o tipo de um campo pelo primeiro valor que
  vê e recusa ou descarta as linhas que discordam.

O OpenTelemetry tem o seu próprio **modelo de dados de log**, com um corpo, uma severidade, atributos
e o contexto do rastro como campos do registro, e o Collector mapeia o JSON da loja para ele na
entrada: a consulta ao Loki da aula 1 achou as linhas por `service_name` porque o Collector copiou o
campo `service` para o resource. Um serviço que registra pela ponte de logging do OpenTelemetry
produz esse modelo direto; um que imprime JSON, como a loja, depende da esteira para mapeá-lo, e os
dois terminam no mesmo lugar.
