---
title: Os outros frameworks que você vai encontrar
version: 1
---

**Além do TOGAF e do IAF existem frameworks feitos para governos, para a defesa e por empresas de
análise, e outros mais leves, feitos para um sistema só.** Você não vai usar a maioria deles, mas vai
encontrar os nomes em licitações, vagas e documentos herdados, e ajuda saber que tipo de coisa cada
um é.

## Frameworks para governos e para a defesa

- **O FEAF, o Federal Enterprise Architecture Framework**, é o framework do governo federal dos
  Estados Unidos, revisado como versão 2 em 2013. A contribuição dele é um conjunto de **modelos de
  referência** que dão a todas as agências o mesmo vocabulário para funções de negócio, dados e
  tecnologia, para que os investimentos possam ser comparados entre agências.
- **O DoDAF**, o framework de arquitetura do Departamento de Defesa dos EUA, organiza as descrições de
  arquitetura em **pontos de vista** como capacidade, operacional, sistemas e serviços, cada um com
  modelos definidos. Ele existe porque os programas de defesa envolvem muitos fornecedores cujas
  descrições precisam se encaixar.
- **O MODAF** era o equivalente do Ministério da Defesa do Reino Unido; foi substituído pelo **NAF**,
  o **NATO Architecture Framework** (o framework da OTAN), cuja versão 4 saiu em 2018, para que as
  nações aliadas descrevam sistemas do mesmo jeito.

O que esses frameworks têm em comum é o problema que resolvem: **muitas organizações, ou muitos
fornecedores, precisam produzir descrições de arquitetura que possam ser comparadas e combinadas**. O
tamanho deles vem disso. Uma empresa do porte da Carcará não tem esse problema e não ganha nada com o
peso deles.

## A abordagem de uma empresa de análise

A abordagem do Gartner para arquitetura corporativa não é um framework publicado no mesmo sentido; é
um corpo de recomendações, vendido a clientes, que põe **resultados de negócio acima de modelos completos**. Comece pelo que o negócio está tentando alcançar, modele só o que ajuda a decidir, e meça
a função de arquitetura pelas decisões que ela melhora. Boa parte da última seção da aula 8, *produza
só os documentos que alguém vai ler*, é a mesma posição.

## Frameworks mais leves para um sistema

Três coisas muitas vezes chamadas de framework trabalham na escala de um sistema, e você já usou duas:

| | o que é | onde aparece neste curso |
| --- | --- | --- |
| **4+1** | um conjunto de pontos de vista para uma arquitetura de software | aula 1 |
| **C4** | um conjunto de abstrações e diagramas para um sistema de software | aula 3 |
| **arc42** | um template para documentar a arquitetura de um sistema, em doze seções | aula 11 |

Eles respondem à pergunta *como descrevemos este sistema?*, não *como mudamos esta empresa?*, e para a
maioria dos times de engenharia é essa a pergunta que importa.

## Três tipos de coisa chamados de *framework*

A palavra cobre coisas muito diferentes, e confundi-las causa a maior parte das discussões:

- **um método**: um processo para fazer o trabalho, como o ADM do TOGAF;
- **uma taxonomia**: um jeito de classificar as descrições, como a grade do IAF ou o framework de
  Zachman da aula 10;
- **uma notação ou um template**: um jeito de pôr uma descrição no papel, como o ArchiMate, o C4 ou
  o arc42.

Um método e uma taxonomia combinam bem; dois métodos raramente combinam. Quando alguém pergunta
*devemos usar TOGAF ou ArchiMate?*, a resposta é que são tipos diferentes de coisa, e muitas
organizações usam os dois.
