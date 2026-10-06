---
title: Verificar à mão, e por que isso para
version: 1
---

Uma imagem comum de teste é uma pessoa clicando pela aplicação antes de um release, marcando
itens numa lista. Essa pessoa faz um trabalho de verdade, e ele não escala. **Um teste
automatizado é um programa que roda parte do seu código e compara o que ele fez com o que você
esperava.** Responde sim ou não, responde igual toda vez, e custa quase nada perguntar de novo.

A conta é o que faz a diferença. O projeto deste curso, o `shipquote`, termina esta aula com 31
verificações: preços por zona, pesos nas bordas, um limite de frete grátis, as respostas HTTP.
Feita à mão, cada uma é um minuto digitando um CEP e lendo um número. São meia hora por mudança.
Uma equipe que integra dez mudanças por dia passaria cinco horas por dia reverificando coisas que
não quebraram, e na prática ninguém faz isso. **As verificações puladas são justamente as que
teriam pegado a regressão.**

As mesmas 31 verificações, como programa, rodam em cerca de um segundo e um quarto num notebook.
Você vai ver esse número impresso na seção 09 desta aula. Um segundo e um quarto é curto o
bastante para rodar a cada salvamento, e isso muda quando um erro é achado: minutos depois de
feito, por quem o fez, com a mudança ainda na cabeça.

## O que um teste diz e o que não diz

Um teste que passa diz uma coisa: **para estas entradas, o código fez o que o teste esperava.**
Não diz que o código está certo para entradas que ninguém tentou, e não diz que a expectativa
estava certa. Um teste que confere o número errado passa feliz. Por isso um teste vale o
raciocínio que escolheu suas entradas, e a seção 10 desta aula trabalha isso.

O que a automação compra, então, não é certeza. Compra três coisas mais baratas:

1. **Repetição.** A 500ª execução custa o mesmo que a primeira, então um comportamento antigo
   continua sendo verificado muito depois de alguém lembrar por que ele importava.
2. **Um registro.** Um arquivo de testes diz, em código, o que o programa promete. Quem chega na
   equipe lê `test_an_order_of_199_reais_or_more_ships_free` e aprende uma regra de negócio.
3. **Permissão para mudar.** Refatorar código sem testes é torcer. Com testes, uma mudança que
   quebra uma promessa avisa em segundos.

## Para onde o curso vai

Esta aula dá nome aos tipos de teste pelo que eles exercitam. As aulas 2 a 4 deixam os testes
mais baratos e mais honestos: dublês para as partes que você não controla, fixtures para os dados
e cobertura para a pergunta "o que os testes nunca rodaram?". Da aula 5 em diante os testes saem
do seu notebook e rodam a cada push, num pipeline, e da aula 7 em diante o mesmo pipeline entrega
o que passou. As três últimas aulas tratam de publicar com segurança e de parar um release que
está dando errado.

**O projeto é pequeno de propósito.** O `shipquote` tem algumas centenas de linhas de Python sem
dependência fora da biblioteca padrão. A linguagem é um detalhe: o pytest tem equivalente em todo
ecossistema (JUnit, Jest, `go test`, XCTest), e o que este curso diz sobre testes e pipelines vale
em todos. O script de laboratório ao lado do curso reconstrói o projeto exatamente como as aulas
mostram, até os hashes dos commits.
