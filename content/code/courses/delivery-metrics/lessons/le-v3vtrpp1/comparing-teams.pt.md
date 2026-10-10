---
title: Por que os quatro números não ranqueiam times
version: 1
---

Os relatórios DORA agrupam milhares de organizações em grupos de desempenho, e daí é um passo curto até uma planilha que ranqueia os próprios times de uma empresa pelos seus quatro números. **Esse passo é um erro**, e ele falha de três maneiras distintas, qualquer uma das quais já bastaria.

## Os sistemas são diferentes

Pegue dois times da mesma empresa. Um roda um serviço web em contêineres e consegue entregar uma mudança em minutos; faz deploy quinze vezes por dia. O outro constrói o aplicativo de ponto de venda que roda nos tablets das próprias lojas; cada release passa pela revisão das lojas de aplicativos, que leva de horas a dias, e as lojas atualizam quando querem. Ele lança uma versão a cada duas semanas.

Ranqueado pela frequência de deploy, o primeiro time é cem vezes melhor. Na verdade, nenhum dos dois números diz coisa alguma sobre o quão bom é cada time, porque **cada um é, em grande parte, uma propriedade do que o time entrega, não de como ele trabalha**. O time dos tablets poderia ser excelente e ainda assim nunca fazer deploy diário; pedir isso a ele seria pedir que as lojas de aplicativos mudassem.

## As definições são diferentes

A aula 5 listou as escolhas escondidas em cada métrica: o que conta como deploy, qual commit inicia o lead time, o que conta como falha, quando começa a restauração. Dois times que fizeram essas escolhas de modos diferentes não estão medindo a mesma coisa, e uma empresa com vinte times tem vinte conjuntos de escolhas, a menos que alguém tenha escrito um para todos. Mesmo assim, uma definição escrita para um serviço web não serve para firmware.

## Ranquear muda o que é medido

A terceira falha é a que piora as outras duas. **Quando os times sabem que estão sendo ranqueados, os números passam a responder outra pergunta**: não "como entregamos?", mas "como parecemos?". Dividir deploys, redefinir falhas e começar a contar mais tarde estão todos ao alcance, cada um é defensável sozinho, e cada um melhora a posição sem melhorar o time. A aula 7 é um catálogo exatamente desses movimentos, e a aula 20 trata das regras que os impedem.

## O que comparar em vez disso

**Um time contra o seu próprio passado.** O time de Billing em setembro contra o time de Billing em junho é uma comparação justa: mesmo sistema, mesmas definições e, no meio, uma mudança que todos conhecem. É assim que este curso usou os números em todas as aulas.

**Perguntas, não posições, entre times.** Numa empresa inteira, as quatro são úteis como um jeito de achar times com quem vale conversar: "o seu tempo para restaurar é muito mais longo que o dos outros; o que torna a recuperação difícil para vocês?" é uma conversa que pode encontrar uma capacidade que falta. "Vocês estão em último na tabela" é uma frase que ensina um time a mudar a tabela.
