---
title: Medindo as respostas
version: 2
---

A segunda e a terceira propriedades são sobre a resposta. O `evaluate.py --list` imprime uma linha por
pergunta: em que posição veio a resposta, se a resposta foi uma recusa, se estava correta, e se toda
frase passou na verificação da aula 7.

```
ana@vm:~/rag$ python evaluate.py --split dev --list
dev: 20 questions, 18 answerable, floor 0.5, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 15/20  refused rightly 2/2  faithful 9/20
e01  rank 1  answered  correct  UNFAITHFUL  How many days do I have to return a printed book?
e02  rank 2  answered  WRONG    UNFAITHFUL  Who pays for the return postage?
e04  rank 2  answered  correct  UNFAITHFUL  Can I return a signed copy?
e05  rank 1  answered  WRONG    UNFAITHFUL  My e-book was downloaded yesterday, can I still get my money back?
e07  rank 2  answered  correct  UNFAITHFUL  Above what order value is standard delivery free?
e08  rank 1  answered  correct  faithful  When is a standard parcel considered lost?
e10  rank 1  answered  WRONG    faithful  How long does a pickup point keep my parcel?
e11  rank 1  answered  correct  faithful  On how many devices can I read my e-books?
e13  rank 1  answered  correct  UNFAITHFUL  When can an audiobook be refunded?
e14  rank 2  refused   WRONG    faithful  Can I pay in instalments?
e16  rank 1  refused   WRONG    faithful  Can I get an invoice in my company's name after the order has shipped?
e17  rank 1  answered  correct  UNFAITHFUL  When is the contract of sale formed?
e19  rank 1  answered  correct  UNFAITHFUL  What commission does Marginalia take from a marketplace seller?
e20  rank 1  answered  correct  UNFAITHFUL  How often are sellers paid?
e22  rank 1  answered  correct  faithful  What commission do affiliates earn on e-books?
e23  rank 1  answered  correct  UNFAITHFUL  How long do you keep my order history?
e25  rank 2  answered  correct  UNFAITHFUL  What is the most a support agent can refund without approval?
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

**Fiéis: 9 de 20.** Uma resposta é fiel quando toda frase é citada da fonte que ela cita, ou fica perto
dela, pela verificação da aula 7. Onze não foram, e a listagem mostra que fiel e correta são
independentes: a e01 é correta e infiel, a e10 fiel e errada. A aula 7 achou por que a maioria das onze
falha, frases que o modelo acrescentou por conta própria e citações escritas onde a verificação não as
procura, e achou a verificação reprovando uma resposta certa também. Vale acompanhar o número pelo
movimento, e vale lê-lo linha a linha antes de agir sobre ele.

## Lendo as cinco erradas

Toda linha errada tem a posição ao lado. O `why.py` imprime as fontes e a resposta de uma pergunta, com
o mesmo filtro da avaliação, e três valem ser lidas por inteiro:

```schooling-example
{
  "language": "python",
  "file": "why.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import answer\n\nreply, sources = answer(sys.argv[1], where=\"status = %s\", params=(\"current\",))\nfor n, s in enumerate(sources, 1):\n    print(f\"[{n}] {s['path']}\")\nprint(reply)",
      "note": "As fontes que o `answer` deu ao modelo para uma pergunta, numeradas como o modelo as viu, e a resposta dele, com o mesmo filtro que o `evaluate.py` usa."
    }
  ]
}
```
```
ana@vm:~/rag$ python why.py "Who pays for the return postage?"
[1] Returns and refunds policy > How to start a return
[2] Returns and refunds policy > How to start a return
[3] Returns and refunds policy > Gifts
According to sources [1] and [2], the return postage is prepaid by the company, so the customer does not pay for the label.
ana@vm:~/rag$ python why.py "My e-book was downloaded yesterday, can I still get my money back?"
[1] E-books and audiobooks > Refunds for e-books
[2] Returns and refunds policy > E-books and audiobooks
[3] E-books and audiobooks > Refunds for e-books
According to sources [1] and [2], an e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. Since your e-book was downloaded yesterday, it falls outside of this 14-day window, and the sale is final, as the law allows for digital content delivered with your consent.

However, source [3] states that an e-book that is faulty, for example with missing chapters or text that cannot be displayed, is refunded or replaced at any time, downloaded or not. This implies that even if the e-book has been downloaded, a refund may still be possible if it is faulty.

Given that source [3] is updated more recently than sources [1] and [2], I would prefer this source. Therefore, it appears that even if your e-book was downloaded yesterday, you may still be able to get a refund if it is faulty.
ana@vm:~/rag$ python why.py "What is the most a support agent can refund without approval?"
[1] Refund controls and chargebacks > Finance reviews
[2] Customer support handbook > What you can decide on your own
According to [2], a support agent can refund up to 50 without approval.
```

Junto com a listagem, elas dizem onde cada falha aconteceu:

| pergunta | posição | o que aconteceu |
| --- | --- | --- |
| e02, quem paga o frete de devolução | 2 | a resposta diz que a etiqueta é paga e o cliente não paga, o que está certo; o fato é *Returns are free*, e a resposta não tem essas palavras |
| e05, um e-book baixado | 1 | a resposta citou a regra e depois raciocinou para fora dela: baixado ontem, então *outside of this 14-day window*, e depois preferiu a regra do exemplar com defeito como *updated more recently*, o que ela não é |
| e10, quanto tempo um ponto de retirada guarda a encomenda | 1 | *10 days*, certo; o fato é *waits there for ten days* |
| e14, pagar parcelado | 2 | recusada: o melhor pedaço ficou abaixo do piso de 0,5 |
| e16, uma nota fiscal depois do envio | 1 | o modelo recusou, com a resposta na primeira fonte: *we cannot reissue an invoice to a different company after the order has shipped* |

**Nenhuma das cinco é falha de recuperação**: toda resposta estava entre as duas primeiras. Duas são
falhas de geração, a resposta não usou uma fonte que tinha: a e05, que a usou e raciocinou errado, e a
e16, que tinha a resposta e disse que não achou nenhuma. Uma é o piso recusando uma pergunta que poderia
ter respondido, o preço que a aula 6 anunciou. E duas, **a e02 e a e10, são falhas do teste, não do
pipeline**: as respostas estão certas no conteúdo e o teste de fato as marcou como erradas, porque ele
procura palavras, não significado. Um teste que erra duas vezes em vinte continua sendo útil, desde que
alguém leia as linhas erradas antes de agir sobre o total.

Esse diagnóstico é todo o valor de medir as três propriedades separadas. Uma equipe olhando só para *15
de 20 corretas* teria mexido na busca, que não estava quebrada. Mais duas coisas só aparecem na leitura.
A terceira execução do `why.py`, a e25, respondeu certo, e a primeira fonte dela é o documento da equipe
financeira: esta avaliação roda sem o filtro de público, então uma pergunta de atendente chegou ao
documento do financeiro, o vazamento que a aula 2 descreveu e a aula 14 fecha. E a e02 e a e10 dizem que
os fatos delas deveriam ter sido escritos melhor, com várias redações ou só o número, o que é um
conserto no conjunto de teste, não no código.

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
