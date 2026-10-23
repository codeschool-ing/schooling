---
title: Onde um framework faz por merecer
version: 1
---

Um argumento que nunca concede nada não vale a leitura. **Há situações em que um framework é a
escolha certa**, e elas têm algo em comum: o framework faz algo que a equipe faria muitas vezes de
outro jeito, mal ou diferente a cada vez.

## Muitas rotas, muita gente, um jeito só

O boxoffice tem seis rotas e um autor. Um serviço com oitenta rotas e doze desenvolvedores é outro
problema. **O que ele mais precisa é que todo handler tenha a mesma cara**: decodifique do mesmo
jeito, valide do mesmo jeito, falhe do mesmo jeito. Helpers escritos à mão entregam isso, se alguém
os escreve cedo e todo mundo os usa; um framework entrega no primeiro dia, documentado, e um
desenvolvedor que já usou Gin em outro lugar é produtivo nele na hora. **Consistência numa equipe
grande é o argumento mais forte a favor de um framework**, e fica mais forte com o tamanho da
equipe.

## Regras que ficam melhores como dados

Os métodos `validate` da aula 3 são código, fácil de ler e de testar. Para uma requisição com trinta
campos, cada um com tamanho, formato e faixa, trinta `if` são cansativos e fáceis de errar por
pouco, e `binding:"required,email,max=100"` é mais curto e mais difícil de errar. **Validação por
tags é um ganho real nessa escala.** E é a única parte do Gin que você tem sem o Gin: a biblioteca
por baixo, `go-playground/validator`, funciona em qualquer struct em qualquer handler.

## Uma descrição da API, gerada

Clientes de uma API pública querem um documento OpenAPI, a descrição legível por máquina que
ferramentas transformam em documentação e em código de cliente. Escrever um à mão e mantê-lo em dia
com o código é uma tarefa que se descola. Alguns frameworks Go são construídos em torno de gerá-lo a
partir das rotas e dos tipos, e **se a API é um produto, só isso já decide a escolha.**

## Velocidade, medida

O caso do Fiber é velocidade, e é um caso real para um serviço cujo tempo vai para o próprio
tratamento HTTP: um proxy, um cache na frente de algo rápido, um serviço respondendo da memória a
taxas muito altas. **Para uma API cujas requisições esperam um banco de dados, como as do boxoffice
a partir da aula 6, o tempo gasto na camada HTTP é uma fatia pequena de cada requisição**, e
reduzi-lo à metade não se nota. Escolher o Fiber pela velocidade é certo quando um profile do serviço
real diz que é na camada HTTP que o tempo vai, e não antes.

## A equipe já tem um

O motivo bom mais comum é o menos técnico. **Se os serviços em volta do seu são escritos em Echo,
escreva o seu em Echo.** O conhecimento, os middlewares e os hábitos compartilhados de uma equipe
valem mais que qualquer diferença desta aula, e um serviço solitário num estilo diferente custa caro
a todo mundo que tem de mexer nele uma vez por ano.
