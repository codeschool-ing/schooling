---
title: Medindo as respostas
version: 1
---

A segunda e a terceira propriedades são sobre a resposta. O `evaluate.py --list` imprime uma linha por
pergunta: em que posição veio a resposta, se a resposta foi uma recusa, se estava correta, e se toda
frase passou na verificação da aula 7.

```
ana@lab:~/rag$ python evaluate.py --split dev --list
dev: 20 questions, 18 answerable, floor 0.5, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 15/20  refused rightly 2/2  faithful 20/20
e01  rank 1  answered  correct  faithful  How many days do I have to return a printed book?
e02  rank 2  answered  WRONG    faithful  Who pays for the return postage?
e04  rank 2  answered  WRONG    faithful  Can I return a signed copy?
e05  rank 1  answered  WRONG    faithful  My e-book was downloaded yesterday, can I still get my money back?
e07  rank 2  answered  correct  faithful  Above what order value is standard delivery free?
e08  rank 1  answered  correct  faithful  When is a standard parcel considered lost?
e10  rank 1  answered  correct  faithful  How long does a pickup point keep my parcel?
e11  rank 1  answered  correct  faithful  On how many devices can I read my e-books?
e13  rank 1  answered  correct  faithful  When can an audiobook be refunded?
e14  rank 2  refused   WRONG    faithful  Can I pay in instalments?
e16  rank 1  answered  correct  faithful  Can I get an invoice in my company's name after the order has shipped?
e17  rank 1  answered  correct  faithful  When is the contract of sale formed?
e19  rank 1  answered  correct  faithful  What commission does Marginalia take from a marketplace seller?
e20  rank 1  answered  correct  faithful  How often are sellers paid?
e22  rank 1  answered  correct  faithful  What commission do affiliates earn on e-books?
e23  rank 1  answered  correct  faithful  How long do you keep my order history?
e25  rank 2  answered  WRONG    faithful  What is the most a support agent can refund without approval?
e26  rank 1  answered  correct  faithful  What must I check before changing a customer's order?
e28  rank -  refused   correct  faithful  Can I place an order by phone?
e29  rank -  refused   correct  faithful  Which carrier do you use in Portugal?
```

## Três números

**Corretas: 15 de 20.** Uma pergunta com resposta está correta quando a resposta contém o fato dela; uma
sem resposta está correta quando é recusada. É o número que interessaria a um cliente se ele pudesse
vê-lo.

**Recusadas com razão: 2 de 2.** As duas perguntas sem resposta nos documentos foram recusadas, pelo piso
da aula 7, antes de o modelo ser chamado.

**Fiéis: 20 de 20.** Toda resposta que não foi recusa teve toda frase citada ou próxima da fonte citada.
Para o extract-1 isso é garantido por construção, e o número está aqui para que o mesmo script, rodado
contra um modelo real, tenha onde informar que não é.

## Lendo as cinco erradas

Toda linha errada tem a posição ao lado. O `why.py` imprime as fontes e a resposta de uma pergunta, com
o mesmo filtro da avaliação, e três das cinco valem ser lidas por inteiro:

```
ana@lab:~/rag$ python why.py "Who pays for the return postage?"
[1] Returns and refunds policy > How to start a return
[2] Returns and refunds policy > How to start a return
[3] Returns and refunds policy > Gifts
Keep the receipt the post office gives you until the refund arrives: it is the only proof that the parcel was sent. [2]
ana@lab:~/rag$ python why.py "My e-book was downloaded yesterday, can I still get my money back?"
[1] E-books and audiobooks > Refunds for e-books
[2] Returns and refunds policy > E-books and audiobooks
[3] E-books and audiobooks > Refunds for e-books
An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. [1] An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. [2] An e-book that is faulty, for example with missing chapters or text that cannot be displayed, is refunded or replaced at any time, downloaded or not. [3]
ana@lab:~/rag$ python why.py "What is the most a support agent can refund without approval?"
[1] Refund controls and chargebacks > Finance reviews
[2] Customer support handbook > What you can decide on your own
Support opens a finance review when a refund or credit is above the agent's or lead's limit, or when fraud is suspected. [1] A refund of more than 500 on one order always needs a second approver from finance, whoever requested it. [1]
```

Junto com a listagem, elas dizem onde cada falha aconteceu:

| pergunta | posição | o que aconteceu |
| --- | --- | --- |
| e02, quem paga o frete de devolução | 2 | *Returns are free* estava na segunda fonte, e o extract-1 citou outra frase dela, sobre guardar o recibo dos Correios |
| e04, um exemplar autografado | 2 | o caso da aula 7: o item da lista foi recuperado e uma frase sobre livros danificados foi citada |
| e05, um e-book baixado | 1 | a resposta citou a regra, *reembolsado em 14 dias se você não o baixou*, que responde à pergunta; o fato era *Once it has been downloaded*, e a resposta não o contém |
| e14, pagar parcelado | 2 | recusada: o melhor pedaço ficou abaixo do piso de 0,5 |
| e25, o limite de reembolso de um atendente | 2 | o documento da equipe financeira veio primeiro, e a resposta citou a regra dele sobre reembolsos acima de 500; o *up to 50* do manual veio em segundo |

**Nenhuma das cinco é falha de recuperação**: toda resposta estava entre as duas primeiras. Três são
falhas de geração, a resposta não usou uma fonte que tinha: e02, e04 e e25. Uma é o piso recusando uma
pergunta que poderia ter respondido, o preço que a aula 6 anunciou. E uma, **a e05, é falha do teste, não
do pipeline**: a resposta está certa no conteúdo e o teste de fato a marcou como errada, porque procura
palavras, não significado. Um teste que erra uma vez em vinte continua sendo útil, desde que alguém leia
as linhas erradas antes de agir sobre o total.

Esse diagnóstico é todo o valor de medir as três propriedades separadas. Uma equipe olhando só para *15
de 20 corretas* teria mexido na busca, que não estava quebrada. Mais duas coisas só aparecem na
listagem: a e25 mostra que esta avaliação roda sem o filtro de público, então uma pergunta de atendente
chegou ao documento do financeiro, o vazamento que a aula 2 descreveu e a aula 14 fecha. E a e05 diz que
o fato daquela pergunta deveria ter sido escrito melhor, o que é um conserto no conjunto de teste, não
no código.

## Correção para um modelo real

O teste de fato reprova a paráfrase correta de um modelo real, como a seção do conjunto de teste disse.
As substituições comuns, da mais barata à mais cara:

- **Vários fatos, qualquer um vale**, escritos à mão: *30 days*, *thirty days*, *a month*.
- **Só números e identificadores**: em muitas perguntas o fato que importa é *9.90* ou *12%*, e esses
  sobrevivem à paráfrase.
- **Um modelo como juiz**, que é o assunto da próxima seção, e que custa uma chamada de modelo por
  pergunta.
- **Uma pessoa**, para uma amostra, para conferir o juiz.

Seja qual for, tem de ser o mesmo nas execuções comparadas. Uma troca de juiz entre duas execuções torna
a comparação sem sentido, por mais cuidadosa que cada execução tenha sido.
