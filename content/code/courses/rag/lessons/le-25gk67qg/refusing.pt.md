---
title: Dizendo que as fontes não dizem
version: 1
---

A terceira linha da mensagem de sistema diz ao modelo o que responder quando as fontes não respondem. É a
instrução mais importante do prompt, porque a alternativa é a resposta de livro fechado da aula 1:
fluente, confiante e inventada. E é aquela em que esta aula menos confia.

## A instrução, sem nada a que se aplicar

O `no_floor.py` manda o que o `ask` mandaria se o código chamasse o modelo fosse o que fosse que a busca
achasse: a mensagem de sistema, a pergunta, e nenhuma fonte, porque nada passou do piso.

```
ana@lab:~/rag$ python no_floor.py "Can I place an order by phone?"
You can call Marginalia's customer service on 0800 555 0199, every day from 9 am to 6 pm.
```

**A instrução mandava responder que os documentos não cobrem isso, e o extract-1 deu um telefone que não
existe.** Sem fontes no prompt, a terceira regra dele não tem sobre o que trabalhar, e ele cai na memória
de livro fechado, que sempre responde. Esse é o mecanismo do extract-1, escrito no `labgen.py`; um modelo
real não tem esse interruptor e recusaria na maioria das vezes. Mas *na maioria das vezes* é a descrição
honesta de uma instrução, e um telefone de uma central que não existe é o tipo de resposta que acaba num
print.

Então o `answer` não pergunta:

```
ana@lab:~/rag$ python answer.py "Can I place an order by phone?"
I could not find that in our documents.
ana@lab:~/rag$ python answer.py "Is there a student discount?"
I could not find that in our documents.
ana@lab:~/rag$ python answer.py "Can I pay in instalments?"
I could not find that in our documents.
```

**Quando nada passa do piso, o código devolve a recusa e o modelo nem é chamado.** As duas primeiras estão
certas: nenhum documento fala de pedido por telefone ou de desconto para estudantes. A terceira é o preço
que a aula 6 anunciou: a resposta está no documento de pagamentos, mas o pedaço dela marcou 0,445, abaixo
do piso de 0,5, então um cliente que pergunta sobre parcelas ouve que os documentos não dizem. O piso e os
erros dele foram escolhidos juntos, e o piso é o lugar mais barato para pôr a decisão, porque é um número
no código, não uma frase que um modelo pode ou não obedecer.

## De onde veio o limiar do próprio extract-1

A aula 1 prometeu dizer de onde veio o 0,53 do extract-1. Veio desta lista, que gera o embedding de cada
frase de cada documento e imprime a melhor similaridade que cada pergunta de teste acha em qualquer lugar:

```
ana@lab:~/rag$ python floor.py | sort -r | sed -n "22,30p"
0.59  answerable    Can I pay in instalments?
0.55  answerable    When is the contract of sale formed?
0.55  answerable    What must I check before changing a customer's order?
0.55  answerable    What does error E-4102 mean in the affiliate API?
0.55  answerable    How long do you keep my order history?
0.52  unanswerable  Can I place an order by phone?
0.49  unanswerable  Which carrier do you use in Portugal?
0.47  unanswerable  Do you have a shop in Porto Alegre where I can pick up books?
0.37  unanswerable  Is there a student discount?
```

As perguntas com resposta mais fracas acham uma frase com 0,55; a pergunta sem resposta mais forte acha
uma com 0,52. **0,53 fica entre as duas, e foi escolhido olhando o conjunto de teste**, enquanto o
laboratório era construído. Isso o torna um limiar perfeito para estas trinta perguntas e um otimista
para qualquer outra: um limiar ajustado a um conjunto de teste parece melhor nesse conjunto do que nas
perguntas que chegam depois. A aula 8 separa uma parte do conjunto de teste exatamente por isso.

## Recusar bem

Uma recusa é uma resposta, e pode ser boa ou ruim. **Diga o que não está coberto**, para que um cliente
que perguntou duas coisas saiba qual falhou. **Ofereça um próximo passo**, o formulário de contato, uma
pessoa, a busca da central de ajuda, porque um cliente recusado continua sem resposta para a pergunta.
**E registre**: recusas são a lista mais barata que uma equipe vai ter dos documentos que ainda não
escreveu.
