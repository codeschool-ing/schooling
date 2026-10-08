---
title: Rastreabilidade
version: 2
---

Um líder de atendimento lê uma resposta que o assistente mandou a um cliente ontem e precisa saber uma
coisa: *por que ele disse isso?* Com recuperação, a resposta está na própria resposta. Com fine-tuning,
não há resposta, e essa diferença pesa mais na prática que a atualidade ou o preço.

## Uma citação é um ponteiro que dá para seguir

```
ana@vm:~/rag$ python sections.py "How long do I have to return a printed book?"
[1] 0.807  returns-policy-2025 > Returning a book
[2] 0.797  returns-policy > The return window
[3] 0.765  returns-policy > Damaged, faulty and wrong items
According to the provided sources, you have 30 days from delivery to return a printed book in the condition you received it.
ana@vm:~/rag$ grep -n "30 days from delivery" data/docs/returns-policy.md
21:You have 30 days from delivery to return a printed book in the condition you received it. The 30
```

Essa forma de perguntar pôs o regulamento de 2025 em primeiro, com 0,807, contra 0,797 do atual. A
resposta está certa mesmo assim, trinta dias, e não cita nada, embora a mensagem de sistema pedisse
citações por número. Então um supervisor que a lê no dia seguinte tem a resposta certa e nenhum jeito de
saber que ela veio da fonte certa e não da errada; a próxima forma de perguntar poderia tirar os
catorze dias de `[1]` com a mesma confiança. O que torna o diagnóstico possível é a linha acima da
resposta: **a linha de nota diz que `[1]` é `returns-policy-2025`, e a correção aparece na mesma
tela** — aquele documento não devia estar disponível para a pergunta de um cliente. Seguir a frase
até a linha 21 do regulamento atual confirma que ela existe e onde. A aula 7 transforma a citação numa
exigência que é conferida, em vez de um pedido que o modelo pode ignorar.

Três coisas ficam possíveis por causa desse ponteiro:

- **Uma pessoa consegue conferir uma resposta** sem confiar no modelo, abrindo a fonte.
- **Um engenheiro consegue separar falhas de recuperação de falhas de geração**, porque a citação diz
  que texto foi mostrado ao gerador. A aula 8 depende disso.
- **A organização consegue provar o que disse a um cliente e por quê**, o que numa disputa, ou numa
  pergunta de um órgão regulador, é a diferença entre uma explicação e um dar de ombros.

## Um modelo ajustado não tem ponteiro

Um modelo ajustado que responde "catorze dias" não dá jeito de descobrir por quê. O fato veio de um
exemplo de treinamento, o exemplo veio de um conjunto de dados, e o conjunto pode ter vindo de um
pipeline como o `dataset.py`, que esta aula mostrou pondo a regra de 2025 na segunda linha. Nada disso
aparece na resposta. Os pesos não registram qual exemplo ensinou o quê, e perguntar ao modelo onde ele
aprendeu alguma coisa produz uma resposta plausível, não uma verdadeira.

**Um modelo ajustado pode ser instruído a citar, e vai produzir citações**, exatamente no formato que
os exemplos usavam. São texto que ele aprendeu a escrever, sem garantia de que o documento citado diz o
que a resposta diz. Uma citação só vale a pena ser seguida se o sistema pôs o texto citado na frente do
modelo no momento em que ele respondeu, e só a recuperação faz isso.

## Quando a rastreabilidade é requisito

Para os usos jurídico e interno da aula 2, ela não é uma propriedade simpática, e sim o produto. Uma
equipe de compliance perguntada sobre qual política uma resposta usou tem de saber dizer. Um cliente que
contesta uma decisão de reembolso tem direito à cláusula. Um auditor revisando como um assistente tratou
dados pessoais precisa ver o que ele leu. Em cada caso, um sistema que não consegue apontar suas fontes é
um sistema que não pode ser usado, por melhores que sejam suas respostas em média.
