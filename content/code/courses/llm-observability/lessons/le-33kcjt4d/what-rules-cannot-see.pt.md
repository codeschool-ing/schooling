---
title: O que as regras não veem
version: 1
---

Volte à execução corrigida contra os fatos. Catorze de trinta respostas estavam erradas, e toda
verificação aprovou cada uma delas. Duas das erradas:

```
ana@lab:~/obs$ python facts.py current
exact      16/30 right
normalised 16/30 right
  e02  Who pays for the return postage?                      I could not find that in our documents.
  e04  Can I return a signed copy?                           I could not find that in our documents.
  e05  My e-book was downloaded yesterday, can I still get   An e-book can be refunded within 14 days of purchase if you 
  e06  How much is express delivery?                         Express delivery is not free at any order value. [1]
  e07  Above what order value is standard delivery free?     Express delivery is not free at any order value. [1]
  e14  Can I pay in instalments?                             I could not find that in our documents.
  e17  When is the contract of sale formed?                  I could not find that in our documents.
  e19  What commission does Marginalia take from a marketpl  Marginalia is an online bookshop operated at marginalia.exam
  e20  How often are sellers paid?                           I could not find that in our documents.
  e21  What does error E-4102 mean in the affiliate API?     I could not find that in our documents.
  e22  What commission do affiliates earn on e-books?        I could not find that in our documents.
  e24  Do you store my IP address?                           I could not find that in our documents.
  e25  What is the most a support agent can refund without   I could not find that in our documents.
  e26  What must I check before changing a customer's order  I could not find that in our documents.
```

**A e06 pergunta quanto custa a entrega expressa, e a resposta diz que a entrega expressa não é grátis
em valor nenhum.** Ela cita a fonte. A fonte existe. A resposta não tem números a conferir, nem dados
pessoais, nem recusa com palavras erradas, e tem nove palavras. Toda regra passa, e o cliente continua
sem saber o preço.

**A e07 pergunta acima de que valor a entrega padrão é grátis, e recebe a mesma frase**, sobre o outro
tipo de entrega. É a resposta que a aula 1 explicou pelo trace: um trecho sobreviveu ao piso, e era o
errado.

Regras veem a **forma** de uma resposta. Se ela **responde à pergunta**, e se o que diz é **verdade nas
fontes**, são propriedades do sentido, e uma regra só chega ao sentido por um atalho: um fato que tem
uma redação só, um número que tem um valor só. As dez recusas estão erradas pelo mesmo motivo: uma
recusa tem forma perfeita, e só o gabarito sabe que os documentos poderiam ter respondido.

Então a avaliação determinística faz bem dois trabalhos e um de jeito nenhum:

- ela **pega forma quebrada** em toda resposta, sem custo, para sempre;
- ela **corrige fatos de redação única** contra um gabarito, antes de uma mudança ir ao ar;
- ela **não consegue julgar relevância nem verdade em texto livre**, que é o que importa de fato para o
  cliente.

O terceiro trabalho precisa de algo que leia. As opções são um modelo, que a aula 9 usa numa amostra do
tráfego real e cujo custo ela mede, e uma pessoa, que a aula 10 usa numa amostra menor e cuja
concordância com outras pessoas ela mede. Nenhum dos dois substitui as regras. Os dois são conferidos
contra elas.
