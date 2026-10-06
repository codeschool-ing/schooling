---
title: O que o fine-tuning muda
version: 1
---

Há dois jeitos de fazer um modelo responder sobre a Marginalia. O RAG deixa o modelo como está e põe o
texto certo em cada requisição. O **fine-tuning** (ajuste fino) muda o próprio modelo: continua o
treinamento com exemplos do comportamento desejado, e os pesos se movem até o modelo produzi-lo. Depois
de um fine-tuning existe um modelo novo, com nome próprio, que responde sem que lhe mostrem nada.

A crença com que a maioria das pessoas começa é que o fine-tuning é como um modelo *aprende os seus
documentos*: treine-o no manual e ele vai saber o manual. É o trabalho que ele faz pior, e esta aula
trata sobretudo do porquê.

## Como é um exemplo de fine-tuning

Um conjunto de dados de fine-tuning é um arquivo de conversas, cada uma mostrando uma requisição e a
resposta que o modelo deveria ter dado. Os provedores que o oferecem usam o mesmo formato das suas APIs
de chat, uma conversa por linha. O `dataset.py` monta um a partir do conjunto de teste deste curso: para
cada uma das 26 perguntas que têm resposta, pega a pergunta, põe a melhor seção na frente do extract-1,
e guarda a resposta como aquela que o modelo ajustado deveria aprender a dar sem seção nenhuma.

```
ana@lab:~/rag$ python dataset.py
examples: 26
training tokens per epoch: 968
ana@lab:~/rag$ head -n 2 ft.jsonl
{"messages": [{"role": "user", "content": "How many days do I have to return a printed book?"}, {"role": "assistant", "content": "You have 30 days from delivery to return a printed book in the condition you received it."}]}
{"messages": [{"role": "user", "content": "Who pays for the return postage?"}, {"role": "assistant", "content": "Return postage is paid by the customer."}]}
```

**Nenhum fine-tuning foi rodado para este curso**: ele precisa do serviço de treinamento de um provedor
ou de uma GPU, e o laboratório não tem nenhum dos dois. O que vem a seguir descreve o que um treinamento
desses faz, e os números são os do conjunto de dados.

**Olhe o segundo exemplo.** Ele ensina ao modelo que o cliente paga o frete de devolução, que era a
regra de 2025. O conjunto foi montado por um passo de recuperação, o passo de recuperação achou o
regulamento substituído, e o erro entrou nos dados de treinamento sem nada que o marcasse. Depois que
um modelo é treinado nessa linha, não há citação para seguir até o documento que o causou. O problema
que o RAG mostrou na aula 1 continua lá, só que agora dentro dos pesos.

## Comportamento se aprende fácil; fatos, não

Um fine-tuning é bom em ensinar um **padrão que aparece em todos os exemplos**: responder em duas
frases, responder em português quando o cliente escreve em português, sempre produzir um JSON válido
com estes quatro campos, escrever como o nosso manual de atendimento. Todo exemplo repete o padrão,
então algumas centenas de exemplos movem os pesos bastante numa direção.

Um fato aparece em um ou dois exemplos. Para fazer o modelo dizer "trinta dias" de forma confiável a
qualquer jeito que um cliente pergunte, o conjunto precisa desse fato dito de muitos jeitos e perguntado
de muitos jeitos, e o mesmo para cada outro fato. Mesmo assim, um fato aprendido de poucos exemplos fica
preso de leve: o modelo o produz para perguntas próximas dos exemplos de treinamento e alguma coisa
plausível para perguntas mais distantes, que é a falha do livro fechado da aula 1 de novo, mais perto
dos seus dados. Os próprios guias de fine-tuning dos provedores apontam na mesma direção: apresentam-no
para formato, estilo e comportamento, e recomendam recuperação quando o que falta é conhecimento.

## O que custa fazer a mudança

Mudar o comportamento de um modelo ajustado quer dizer um conjunto novo, um treinamento novo e um modelo
novo para avaliar e implantar. Mudar o que um sistema de RAG sabe quer dizer mudar um documento e
reindexá-lo. As próximas quatro seções comparam os dois nas quatro coisas que mais diferem: quão atuais
são as respostas, se dá para rastreá-las, quanto custam e se alguma coisa pode ser removida.
