---
title: O que as regras não veem
version: 2
---

Volte à execução corrigida contra os fatos. Seis das vinte e quatro respostas estavam erradas de
verdade, e toda verificação aprovou cada uma delas:

```
ana@dev:~/obs$ python facts.py current
exact      16/24 right
normalised 16/24 right
  e02  Who pays for the return postage?                      According to [1], the customer pays for the return postage.
  e04  Can I return a signed copy?                           I could not find that in our documents.
  e05  I downloaded an e-book yesterday. Can I still return  I could not find that in our documents.
  e12  Will my e-books open on a Kindle?                     I could not find that in our documents.
  e14  Can I pay in instalments?                             I could not find that in our documents.
  e16  When do I get the invoice for my order?               You will receive the electronic invoice for your order as so
  e18  What happens if my order costs more than my gift car  If your order costs more than your gift card holds, you pay 
  e19  How long is the statutory right of withdrawal?        I could not find that in our documents.
```

**A e02 pergunta quem paga o frete da devolução, e a resposta diz que é o cliente.** Ela cita a fonte.
A fonte existe, e é a certa. A resposta não tem números a conferir, nem dados pessoais, nem recusa com
palavras erradas, e tem dez palavras. Toda regra passa, e a resposta diz o contrário do documento que
cita: a devolução é grátis, com etiqueta pré-paga.

Regras veem a **forma** de uma resposta. Se ela **responde à pergunta**, e se o que diz é **verdade
nas fontes**, são propriedades do sentido, e uma regra só chega ao sentido por um atalho: um fato
que tem uma redação só, um número que tem um valor só. As cinco recusas estão erradas pelo mesmo
motivo: uma recusa tem forma perfeita, e só o gabarito sabe que os documentos poderiam ter
respondido. E a e16 e a e18 mostram a aproximação falhando no outro sentido, uma resposta certa
reprovada porque escolheu as próprias palavras.

Então a avaliação determinística faz bem dois trabalhos e um de jeito nenhum:

- ela **pega forma quebrada** em toda resposta, sem custo, para sempre;
- ela **corrige fatos de redação única** contra um gabarito, antes de uma mudança ir ao ar;
- ela **não consegue julgar relevância nem verdade em texto livre**, que é o que importa de fato para o
  cliente.

O terceiro trabalho precisa de algo que leia. As opções são um modelo, que a aula 9 usa numa amostra do
tráfego real e cujo custo ela mede, e uma pessoa, que a aula 10 usa numa amostra menor e cuja
concordância com outras pessoas ela mede. Nenhum dos dois substitui as regras. Os dois são conferidos
contra elas.
