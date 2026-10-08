---
title: Maneiras de pagá-la
version: 1
---

Quando se combina que uma dívida vale ser paga, há várias maneiras de pagá-la, e elas servem a dívidas diferentes. Escolher a errada é um motivo comum de os esforços de pagamento falharem.

## Continuamente, no código em que se mexe

A **regra do escoteiro**, popularizada por Robert C. Martin: deixe o código um pouco mais limpo do que o encontrou. Toda mudança num módulo bagunçado inclui uma pequena melhoria — um nome mais claro, uma regra duplicada reunida num lugar, um teste que faltava. Custa alguns por cento em cada mudança e não precisa de negociação, porque acontece dentro de um trabalho já combinado.

Funciona bem para dívida espalhada de forma fina pelo código que o time muda com frequência, que é onde se paga a maior parte dos juros. Não faz nada pela dívida em código em que ninguém mexe, que, como a segunda seção desta aula argumentou, quase não custa nada mesmo.

## Uma parcela reservada da capacidade

A aula 12 descreveu a **alocação de capacidade**: uma parcela fixa de cada Sprint, muitas vezes por volta de um quinto, guardada para trabalho técnico que o time escolhe. Ela serve a um fluxo constante de itens médios — a automação do deploy, a atualização de uma biblioteca — grandes demais para a regra do escoteiro e pequenos demais para serem defendidos um a um.

## Um trabalho dedicado

Alguma dívida é grande o bastante para ser um projeto próprio: substituir a infraestrutura de testes instável, separar o banco único por clínica. Esses entram no backlog como itens com caso de negócio próprio, priorizados com WSJF ou RICE contra funcionalidades, como a aula 12 mostrou, e são entregues como qualquer outro item grande: quebrados em fatias, cada uma deixando o sistema funcionando.

## Substituindo um sistema pedaço por pedaço

As maiores dívidas às vezes significam substituir um sistema inteiro. A abordagem que funciona na maioria dos casos é a da **figueira estranguladora** (strangler fig), nomeada por Martin Fowler em 2004 a partir de uma planta que cresce em volta de uma árvore até substituí-la. Você constrói o sistema novo ao lado do antigo, encaminha uma funcionalidade de cada vez para o novo e aposenta o antigo quando nada mais o usar. O sistema continua funcionando o tempo todo, e cada passo pode ser interrompido se as prioridades mudarem. O curso `tech-strategy` dedica a ela uma aula própria, a sétima, junto com a reescrita que quase nunca vale a pena.

## O que não funciona

Duas abordagens falham com frequência suficiente para serem nomeadas. **A Sprint de limpeza** — uma Sprint por trimestre dada à dívida — em geral é gasta no que mais incomoda e não no que mais custa, e os hábitos que criaram a dívida continuam no intervalo. **A grande reescrita** — parar as funcionalidades por meses para reconstruir — esgota a paciência do negócio antes de terminar, e muitas vezes reproduz os problemas do sistema antigo, porque o conhecimento embutido no código velho se perde. As duas tratam a dívida como evento; ela é mais bem tratada como fluxo, paga mais ou menos no ritmo em que se acumula.
