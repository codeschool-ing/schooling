---
title: Decidindo se vale escrever
version: 1
---

**Comece sequencial. Torne um stream paralelo só quando uma medição com dados reais disser que ele é
mais rápido, e o pipeline não tiver estado compartilhado.** O padrão acerta mais vezes do que erra, e
um stream paralelo que apenas não é mais rápido ainda custa algo: o trabalho vai para threads de que o
resto do programa precisava.

## Uma lista antes do `parallel()`

| pergunta | o paralelo ajuda quando | o paralelo atrapalha quando |
|---|---|---|
| quanto trabalho por elemento? | cálculo de verdade: parsing, matemática, hash | uma leitura de campo, uma soma |
| quantos elementos? | dezenas de milhares ou mais | dezenas ou centenas |
| qual é a fonte? | `ArrayList`, um array, `IntStream.range` | `LinkedList`, `Stream.iterate`, `Files.lines` |
| os lambdas mexem em algo compartilhado? | não: leem o argumento e devolvem | sim: uma lista, um contador, um campo |
| o resultado precisa da ordem da fonte? | não, ou a operação terminal a mantém barato | `forEachOrdered`, `findFirst`, `limit` num stream enorme |
| algum lambda espera? | nunca | chamadas de rede, consultas a banco, `sleep` |

## O pool é compartilhado

A última linha é sobre o **pool comum** da seção 02. Todo stream paralelo do programa, em toda
biblioteca que ele usa, roda nos mesmos poucos workers, três nesta máquina. Um lambda que espera uma
resposta da rede segura um worker durante a espera inteira, e enquanto três desses lambdas esperam,
**todos os outros streams paralelos do programa ficam parados**. Streams paralelos são para trabalho
que mantém um processador ocupado. Trabalho que espera, por arquivos, sockets ou bancos de dados,
pertence a executors e threads virtuais, que as aulas 16 e 17 montam exatamente para isso.

O tamanho do pool pode ser mudado com a propriedade de sistema
`java.util.concurrent.ForkJoinPool.common.parallelism`, definida quando a JVM começa. É uma decisão
para o programa inteiro, não um ajuste para um stream, e mudá-la para deixar um pipeline mais rápido é
como outros pipelines ficam mais lentos.

## O que você tem depois das aulas 6 a 9

Um pipeline que se lê de cima para baixo, feito de `filter`, `map`, `flatMap`, `sorted` e uma operação
terminal; reduções que são corretas porque a função de combinação é associativa; coletores que
respondem perguntas sobre grupos; e um motivo medido, ou nenhum, para torná-lo paralelo. A aula 10
pega o `Optional` que `findFirst`, `max` e `reduce` não paravam de devolver, e faz dele o assunto.
