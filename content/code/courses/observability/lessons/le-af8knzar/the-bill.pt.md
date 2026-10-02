---
title: A conta, a saída e a escolha
version: 1
---

A conta de um produto hospedado são as tabelas de custo das aulas 6, 10 e 12 com um preço em cada
linha. **A surpresa raramente é o preço. É a unidade**, e um hábito que é de graça na sua própria pilha
ficando caro na de outra pessoa:

| unidade | o hábito que a faz crescer | onde este curso a encontrou |
|---|---|---|
| hosts ou contêineres | autoescala, workers de vida curta, um sidecar por pod | o node exporter da aula 5, um por máquina |
| séries de métricas customizadas | um label com o id de um usuário ou de um pedido | a cardinalidade da aula 6 |
| gigabytes de logs ingeridos | um nível de depuração esquecido ligado, um objeto inteiro por linha | o vazamento da aula 10 e o volume da aula 8 |
| spans ou eventos indexados | guardar todo rastro, repetir falhas | a amostragem da aula 12 |
| usuários | dar a todo mundo do plantão um assento completo | a escala da aula 18 |

Cada uma tem a mesma defesa, e é a que este curso ensinou para a pilha gratuita: **decidir o que
guardar antes de mandar**. O Collector é onde isso sai mais barato, porque um span descartado ali nunca
foi cobrado, e uma série nunca criada nunca precisou ser apagada.

**A saída custa menos do que custava, e ainda custa.** Com OpenTelemetry nos serviços, sair de um
fornecedor é uma troca de exportador. O que não se move são os painéis, as regras de alerta e as buscas
salvas, escritos na linguagem de consulta própria de cada produto, e o histórico, que fica onde foi
guardado. Uma equipe que usa um fornecedor por dois anos deve esperar reconstruir isso, e pode deixar
mais barato mantendo as regras de alerta perto do PromQL e os painéis poucos.

**Escolher** vira então uma lista curta de perguntas, e as respostas mudam por equipe, não por produto:

- **Quem operaria a pilha de código aberto?** Se a resposta é *ninguém em particular*, essa é a
  resposta. A pilha falha na noite em que é necessária.
- **Que volume, na unidade do próprio produto?** Meça, como o substituto fez, antes de pedir um
  orçamento, e peça o orçamento para o dobro do volume.
- **Onde os dados ficam guardados, e sob que contrato?** Pela LGPD, um fornecedor no exterior é uma
  transferência, e dados pessoais chegam a rastros e logs com mais frequência do que alguém planeja.
- **O que só existe com o agente do próprio fornecedor?** Esse é o aprisionamento que sobra.

Um resultado comum é uma mistura: métricas e logs numa pilha operada pela equipe, onde o volume é alto
e o uso é rotineiro, e um produto hospedado para a parte mais difícil de operar bem, muitas vezes o
rastreamento de erros ou os rastros. **O Collector torna a mistura barata**, e esse é o argumento mais
forte para pôr um na frente do que quer que você escolha.
