---
title: De uma pergunta de negócio a um tipo de modelo
version: 1
---

A maioria dos projetos de aprendizado de máquina em BI que falham falha no primeiro passo: a pergunta
não era uma que um modelo conseguisse responder, ou foi respondida com o tipo errado de modelo.
Traduzir a pergunta é trabalho da analista, e vem antes de qualquer algoritmo.

| pergunta de negócio | o que é previsto ou achado | tipo |
|---|---|---|
| que clientes vão parar de pedir nos próximos 90 dias? | uma categoria por cliente: sai ou fica | supervisionado, classificação |
| quanto cada cliente vai gastar no próximo trimestre? | um número por cliente | supervisionado, regressão |
| quantas caixas na semana que vem? | um número por semana | previsão, aulas 3 a 5 |
| que clientes se parecem? | grupos | não supervisionado, agrupamento |
| este pedido é incomum? | quão longe do normal um pedido está | não supervisionado, detecção de anomalia |
| que oferta este visitante deve ver? | uma ação | por reforço, ou um teste A/B |

Três perguntas põem um pedido numa linha.

1. **Há uma resposta certa que vai ser conhecida depois?** Se sim, dá para juntar exemplos com a
   resposta e o problema é supervisionado. "Este cliente vai sair?" é respondida, com o tempo, por ele
   sair ou não.
2. **A resposta é uma categoria ou um número?** Classificação ou regressão.
3. **A saída do modelo vai mudar o que acontece?** Se a marcação de um modelo de churn dispara um
   desconto, os clientes que ele marca se comportam diferente por causa disso, e o dado de treino do
   ano que vem contém o efeito do próprio modelo. Esse ciclo é o assunto da aula 18.

**Previsão é aprendizado supervisionado com o tempo como entrada**, e as aulas 3 a 5 já fizeram isso.
A disciplina aprendida ali passa inteira: treine no passado, teste num futuro que o modelo nunca viu,
e compare com uma referência simples.
