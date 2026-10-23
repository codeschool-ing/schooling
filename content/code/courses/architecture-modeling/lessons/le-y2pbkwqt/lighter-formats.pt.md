---
title: Formatos mais leves, e quando um registro é demais
version: 1
---

**O registro completo é o peso certo para uma decisão cara de reverter. Para as menores, formatos
mais leves guardam o raciocínio sem a cerimônia**, e um time que só tem o formato pesado acaba não
registrando nada.

## A declaração Y

Olaf Zimmermann e colegas propuseram uma forma de uma frase só, batizada pelo formato que ela faz
quando é disposta em linhas:

```localised
No contexto de      <a situação ou o caso de uso>,
diante de           <a preocupação ou a força>,
decidimos por       <a opção escolhida>
e descartamos       <as alternativas>,
para alcançar       <o benefício ou a qualidade>,
aceitando           <o lado ruim>.
```

A decisão de bloqueio de assento da Carcará nessa forma:

> No contexto de **bloquear assentos enquanto o passageiro paga**, diante de **um tráfego de
> bloqueios que é 40% das escritas do banco de reservas no pico**, decidimos por **uma chave do Redis
> por assento com expiração de dez minutos** e descartamos **ajustar o banco e um serviço de
> inventário à parte**, para alcançar **um banco de reservas com folga antes do São João**,
> aceitando **que um reinício do Redis perde os bloqueios em andamento**.

Cada parte de um registro completo está ali, comprimida. **Uma declaração Y é um bom teste mesmo
quando você escreve o registro completo**: se você não consegue preencher a linha do *aceitando*,
ainda não achou o custo da decisão.

## Outras formas leves

- **Uma tabela de decisões dentro de um documento de design.** Uma linha por decisão: a pergunta, as
  opções, a escolha, a razão, a data. Boa para a dúzia de pequenas decisões que uma funcionalidade
  toma pelo caminho.
- **Uma descrição de pull request que aponta para as forças.** Para uma decisão local a um serviço,
  o PR que a implementa, com um parágrafo de *porquê*, pode ser o lugar certo. Dá para buscar, e ele
  fica ao lado da mudança.
- **Um comentário no código**, para uma decisão sobre uma função: *ordenamos em memória aqui porque
  o planejador de consultas escolhe uma varredura sequencial acima de 10.000 linhas; medido em
  2025-03.* Ele morre com o código, o que é o certo para uma decisão sobre o código.

## Escolhendo o peso

| a decisão | o peso dela |
| --- | --- |
| cruza times, difícil de reverter, as pessoas vão perguntar sobre ela por anos | um registro completo |
| dentro de um time, reversível numa sprint, ainda vale lembrar | uma declaração Y ou uma linha numa tabela de decisões |
| dentro de um serviço, visível na mudança | a descrição do pull request |
| dentro de uma função | um comentário ao lado dela |

O que importa é que o raciocínio esteja em algum lugar onde um sucessor vá encontrá-lo. **Uma
decisão não registrada não fica sem decidir; ela é decidida por quem mexer no código em seguida**,
sem nenhuma das forças à vista.
