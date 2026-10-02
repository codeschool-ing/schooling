---
title: Agentes proprietários e OpenTelemetry
version: 1
---

Todo produto acima começou com um agente próprio, e durante anos esse agente era o produto: a
instrumentação era escrita contra a biblioteca do fornecedor, e os dados iam só para o fornecedor. **O
aprisionamento estava no código.** Sair significava reinstrumentar todo serviço, e é por isso que as
equipes raramente saíam.

O OpenTelemetry mudou onde a linha fica. Os quatro produtos hoje aceitam OTLP, o protocolo que os
serviços do laboratório falam com o Collector, então um serviço instrumentado como a aula 2 e a aula 3
fizeram pode mandar os dados dele a qualquer um deles. O que um fornecedor ainda acrescenta está de um
lado ou do outro desse protocolo:

- **a própria distribuição do SDK ou do Collector**, com padrões escolhidos para a entrada dele;
- **instrumentação para o que o OpenTelemetry cobre pior**, como alguns runtimes e frameworks;
- **o próprio agente com recursos a mais**, profiling ou injeção automática, que dependem dele.

A regra que mantém a escolha aberta é simples de dizer: **instrumente com OpenTelemetry, e mantenha o
código do fornecedor na borda**, nos exportadores do Collector ou numa distribuição do fornecedor que
possa ser trocada. Uma biblioteca de fornecedor dentro do código de negócio é o tipo caro de
dependência, aquele que precisa ser tirado linha por linha.

Dois cuidados mantêm a regra honesta. Aceitar OTLP não é o mesmo que tratá-lo como entrada de
primeira classe: alguns recursos de um produto podem funcionar só com o agente dele, e a avaliação
deve verificar quais. E as convenções semânticas, os nomes de atributo que a aula 2 seguiu, são o
que a interface de um fornecedor lê para desenhar as visões dela. Dados que as seguem aparecem
certos em todo produto, e dados que não seguem aparecem meio vazios em todos.