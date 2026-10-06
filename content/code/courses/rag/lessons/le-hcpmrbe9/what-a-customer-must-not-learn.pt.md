---
title: O que um cliente não pode saber
version: 1
---

O aviso do documento do financeiro era sobre atendentes, mas o caso mais forte para permissões é um
cliente. Uma regra de reembolso que existe para pegar abuso para de funcionar no momento em que as
pessoas que ela deve pegar conseguem lê-la:

```
ana@lab:~/rag$ python roles.py "How many refunds can I get before my account is flagged?" customer finance
How many refunds can I get before my account is flagged?
customer  nothing above the floor
          I could not find that in our documents.
finance   Refund controls and chargebacks > Automatic holds (finance, 0.670)
          A customer who has received more than three refunds in 90 days is flagged, and every further refund on that account goes to finance review regardless of the amount. [1]
```

A equipe financeira recebe a regra palavra por palavra, que é para isso que o documento existe: **mais
de três reembolsos em 90 dias** marcam uma conta. O cliente recebe a recusa, porque nenhum documento
público responde a pergunta e o documento do financeiro não está entre o que a busca de um cliente
alcança. Um cliente que soubesse o número saberia pedir três reembolsos por trimestre, e nada num prompt
poderia ter impedido isso depois que o texto estivesse na frente do modelo.

Uma recusa é a resposta certa aqui, e vale dizer por quê. "I could not find that in our documents" é
verdade de onde o cliente está: nada que ele pode ler responde. Ela não revela nem que a regra existe
nem onde ela mora. Uma resposta como "essa informação é restrita" diria ao cliente que há algo a achar,
e numa pergunta sobre contornar um controle de fraude, isso já é um vazamento.

## A mesma pergunta, feita de lado

Permissões decidem o que é recuperado, então valem seja qual for a forma da pergunta. Um cliente que
pergunta "o que acontece se eu devolver muitos livros?" ou "existe um limite de reembolsos?" chega aos
mesmos documentos públicos e a nada mais, porque a fronteira está nos pedaços e não nas palavras. Essa é
a diferença em relação à correção tentadora da aula 2, uma instrução no prompt para não revelar
limites: uma instrução é conferida pelo modelo contra as palavras da pergunta, e uma permissão é
conferida pelo banco contra o leitor.
