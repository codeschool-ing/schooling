---
title: Cargos, e o trabalho por trás deles
version: 1
---

Se os quatro papéis fossem tão arrumados nos anúncios de vaga quanto nas duas seções anteriores,
escolher um emprego seria fácil. **Não são: o mesmo cargo quer dizer trabalhos diferentes em empresas
diferentes, e o mesmo trabalho é anunciado com cargos diferentes.** O cargo é uma pista. Os verbos do
anúncio são a evidência.

## Por que os cargos se deslocam

Uma empresa dá nome à vaga pelo que precisa e pelo que pode pagar, e as palavras do mercado mudam mais
depressa que as duas coisas. Uma empresa pequena que quer uma pessoa para fazer tudo com dados chama a
vaga de "analista de dados", porque é o cargo que os candidatos procuram. Um banco grande pode dividir
o mesmo trabalho em três equipes com três cargos. "Analista de BI" e "analista de dados" aparecem como
sinônimos em muitos anúncios, e em algumas empresas "cientista de dados" quer dizer alguém que faz
relatórios com mais estatística.

## O trabalho de Lívia, descrito com honestidade

O contrato de Lívia diz "analista de BI". Nos dois primeiros meses ela escreveu definições e montou o
e-mail de vendas de segunda, o que é BI. Explorou a queda de outubro e os clientes que voltam, o que
é trabalho de analista de dados. E duas vezes consertou ela mesma um pipeline quebrado numa sexta à
tarde, porque Tiago trabalha três dias por semana, o que é engenharia. **Numa empresa do tamanho da
Varanda, uma analista faz três dos quatro trabalhos**, e isso é normal, não falha de planejamento. O
que importa é ela saber que chapéu está usando, porque cada um tem um padrão diferente: uma
exploração pode ser rústica, um número mensal não.

## Lendo um anúncio pelos verbos

Ignore o cargo por um momento e sublinhe o que a vaga pede para você fazer. Os verbos separam.

| verbos no anúncio | o papel que descrevem |
|---|---|
| construir, manter e monitorar pipelines; ingerir; modelar o data warehouse | engenheiro de dados |
| definir KPIs; construir e manter painéis e relatórios recorrentes; levantar requisitos com as áreas | analista de BI |
| investigar; explorar; responder perguntas pontuais; apresentar achados | analista de dados |
| treinar, validar e pôr modelos em produção; prever; experimentar | cientista de dados |

Um anúncio de "analista de dados" cuja lista é quase toda *construir painéis, definir KPIs, levantar
requisitos* é uma vaga de BI. Um de "analista de BI" que pede *pipelines, orquestração, modelagem de
dados* é sobretudo engenharia com cargo de BI. **Nenhum dos dois é pegadinha; é a empresa descrevendo
o próprio problema com as palavras do mercado**, e os verbos dizem que problema você seria contratado
para resolver. O curso `first-job` trata da busca de emprego como um todo.

## Um cargo mais novo: o engenheiro de analytics

Um cargo se espalhou na última década e fica entre dois dos quatro. **O engenheiro de analytics
(*analytics engineer*) pega os dados que o engenheiro entregou e os transforma em tabelas limpas,
testadas e documentadas, de onde analistas e painéis leem** — o lugar onde "uma venda" ou "um cliente
que volta" é definido uma vez, em código, para todos os relatórios ao mesmo tempo. Ele cresceu junto
com ferramentas que deixam analistas escrever essas transformações como código versionado e com
testes, das quais a mais conhecida é o dbt.

Na Varanda ninguém tem esse cargo, e o trabalho é dividido: Tiago monta as tabelas, Lívia escreve as
definições que elas implementam. Quando uma empresa descobre que cada painel calcula a receita de um
jeito um pouco diferente, o engenheiro de analytics costuma ser o papel que está faltando. A aula 2 de
`warehouse-modeling` trata do tipo de tabela que esse trabalho produz.

## O que isso quer dizer para o resto do curso

Este curso acompanha uma analista de BI porque as perguntas dele — que número, definido como,
mostrado para quem — pertencem a esse papel. **Quase tudo serve também para os outros três**, por um
motivo simples: cada um deles entrega trabalho a alguém, e a próxima seção trata do que dá errado
nessas passagens.
