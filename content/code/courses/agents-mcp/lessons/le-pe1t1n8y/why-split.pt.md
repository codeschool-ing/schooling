---
title: Por que dividir o trabalho
version: 2
---

A imagem comum é a de uma equipe: um agente gerente e uma fileira de agentes especialistas, cada um melhor no seu trabalho do que um generalista seria, então um sistema multiagente seria o desenho mais capaz. **Nada no modelo torna um especialista mais especialista.** O especialista de pedidos desta aula chama o mesmo `llama3.2:3b` que todo mundo. O que uma divisão muda é o que cada agente vê e o que cada um tem permissão de fazer, e esses são motivos reais, com custos reais.

Os motivos que se sustentam:

- **Um contexto menor por agente.** Um especialista começa a própria conversa com uma pergunta, e não com o histórico inteiro do cliente e todos os resultados de ferramenta dos outros agentes. Uma conversa mais curta sai mais barata por pedido e deixa o modelo com menos em que se perder, o que importa mais em tarefas longas, em que o contexto de um agente único se encheria de resultados sem relação com o passo atual.
- **Menos ferramentas por agente.** Cada especialista aqui tem uma ou duas ferramentas em vez de três. Um modelo escolhendo entre duas ferramentas erra menos do que um escolhendo entre vinte, e as descrições podem ser escritas para um trabalho só.
- **Menor privilégio por agente.** O especialista de catálogo não consegue consultar pedidos de jeito nenhum. Se algo o convencer a tentar, não há ferramenta para chamar. A aula 17 parte disto: um agente que lê conteúdo não confiável deveria ser um agente que não consegue agir.
- **Trabalho em paralelo.** Perguntas independentes vão para agentes independentes ao mesmo tempo. Numa tarefa de pesquisa que lê dez fontes, dez trabalhadores podem ler uma cada.

Os custos, que a seção 05 mede:

- **Mais pedidos e mais tokens.** Cada agente tem o próprio prompt de sistema e a própria conversa, e o orquestrador paga de novo para ler a resposta de cada especialista.
- **Uma fronteira onde informação se perde.** Cada agente sabe só o que atravessou para dentro dele, e a seção 08 mostra um fato se perdendo nessa linha.
- **Depuração mais difícil.** Uma resposta errada pode vir da pergunta do orquestrador, de uma chamada de ferramenta de um especialista, do resumo de um especialista ou da leitura que o orquestrador fez dele. O rastro tem de mostrar os quatro.

Então a pergunta nunca é "um agente ou vários?" em abstrato. É se a separação de contexto, de ferramentas ou de privilégios vale mais do que os pedidos, os tokens e a fronteira que ela acrescenta, para esta tarefa.
