---
title: "Funções de aptidão: verificações que mantêm a arquitetura honesta"
version: 1
---

**Uma função de aptidão (fitness function) é uma verificação automática que mede o quanto o sistema
ainda tem uma característica arquitetural que deveria ter.** O termo vem de *Building Evolutionary
Architectures*, de Neal Ford, Rebecca Parsons e Patrick Kua. A ideia é mais antiga que o nome: se a
documentação afirma sobre o sistema algo que um programa poderia verificar, faça o programa
verificar, a cada mudança.

## O que dá para verificar

Muitas afirmações de um documento de arquitetura são verificáveis, e cada uma transforma uma frase
num teste:

| o documento diz | a função de aptidão |
| --- | --- |
| *Ticketing chega a Pricing só por `FareQuote`* (aula 2) | um teste de dependências falha se alguma classe de ticketing importar uma classe de pricing que não seja a interface |
| *o serviço de reservas nunca fala com o Redis diretamente* (aula 3) | o mesmo tipo de teste, sobre pacotes |
| *95% das compras abaixo de 2 s a 2.000 por minuto* (aula 6, QS-01) | um teste de carga antes de cada São João reprova a release se o percentil passar |
| *uma leitura de bilhete é conferida em até um segundo sem rede* (QS-02) | o teste de leitura sem rede da matriz da aula 6 |
| *todo registro de decisão tem um status e uma data* (aula 5) | um script que lê `docs/decisions/` e falha num registro sem eles |
| *todo diagrama do repositório tem um título e um dono* | o mesmo, para os arquivos de diagrama |

Uma verificação estrutural do primeiro tipo, escrita com ArchUnit, uma biblioteca para Java e
Kotlin, se lê quase como a frase que ela impõe:

```kotlin
@ArchTest
val ticketingUsesPricingOnlyThroughFareQuote: ArchRule =
    noClasses().that().resideInAPackage("..ticketing..")
        .should().dependOnClassesThat(
            resideInAPackage("..pricing..").and(not(simpleName("FareQuote")))
        )
```

A regra diz: nenhuma classe num pacote de ticketing pode depender de uma classe num pacote de
pricing, a não ser que essa classe seja `FareQuote`. Ela aparece aqui para ilustrar o formato e não
foi executada para este curso. Rodando em todo pull request, ela quer dizer que **o diagrama de
componentes da aula 2 não pode se afastar do código sem o build ficar vermelho**, coisa que nenhuma
quantidade de boas intenções consegue.

## Tipos de função de aptidão

O livro as separa em alguns eixos, e dois importam mais na hora de escolher:

- **atômica ou holística**: uma característica isolada, como uma regra de dependência, ou várias de
  uma vez, como um teste de carga que mede latência, erros e custo juntos;
- **disparada ou contínua**: roda num evento, como um pull request ou uma release, ou o tempo todo,
  como um monitor em produção que alerta quando o percentil 95 das compras passa de 2 segundos.

## O que não verificar

Nem toda frase merece um teste. **Uma função de aptidão vale a pena quando a afirmação importa e é
provável que seja quebrada sem querer.** *Ticketing usa Pricing só por `FareQuote`* se encaixa: o
atalho já foi tomado uma vez, na aula 2. *O sistema é escrito em Kotlin* não se encaixa: ninguém vai
reescrevê-lo em outra linguagem sem querer. Um conjunto de verificações que ninguém entende é, à sua
maneira, documentação morta.
