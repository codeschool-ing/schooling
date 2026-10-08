---
title: Quando um agente basta
version: 2
---

A seção 05 mediu a divisão em três vezes os pedidos para uma resposta pior. As seções 04 e 08 mostraram o que se perde numa fronteira. Nenhum dos dois resultados quer dizer que sistemas multiagentes estão errados; quer dizer que uma divisão tem de se pagar. Uma lista curta, na ordem em que as perguntas costumam decidir:

**O contexto de um agente fica grande demais?** Se a conversa de um agente único fica bem dentro da janela e o custo por pedido é aceitável, o primeiro motivo para dividir não existe. Se subtarefas longas inundam a conversa com resultados de que os passos seguintes não precisam, especialistas com conversas próprias são o remédio.

**São ferramentas demais para um agente escolher bem?** Duas ou três, não. Vinte, cobrindo trabalhos sem relação, provavelmente: um modelo escolhendo numa lista longa erra mais, e as descrições começam a se sobrepor.

**As ferramentas precisam de privilégios diferentes?** Esta decide sozinha. Um agente que lê mensagens de clientes, páginas da web ou documentos de terceiros não deveria ser o agente que reembolsa, manda e-mail ou apaga. Separá-los, para que quem lê não aja e quem age nunca leia texto não confiável, é um desenho de segurança e não de eficiência, e a aula 17 o constrói.

**As partes podem rodar em paralelo, e são lentas?** Então um orquestrador esperando o trabalhador mais lento vence um agente fazendo uma de cada vez.

**Uma conversa pertence a um dono?** Então passagem, não orquestrador: encaminhe uma vez e deixe o dono responder.

Se nenhuma dessas vale, fique com um agente e gaste o esforço nas ferramentas, nos limites e nos testes dele. **A maioria dos agentes em produção é um laço com um punhado de boas ferramentas**, e os que não são chegaram lá medindo primeiro um agente único e descobrindo exatamente em qual dessas perguntas ele falhou.
