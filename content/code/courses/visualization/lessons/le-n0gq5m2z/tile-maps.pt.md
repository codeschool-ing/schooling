---
title: Mapas de blocos e cartogramas
version: 1
---

Os mapas desta aula desenham todo estado como o mesmo quadrado. Isso não é um atalho; é um desenho
com nome, o **mapa de blocos**, e ele resolve o problema que a segunda seção levantou: **num mapa
geográfico, lugares grandes dominam**.

Num mapa real do Brasil, Amazonas, Pará e Mato Grosso juntos cobrem quase metade do país, e têm uns 8%
da população. Seja qual for o valor que um coroplético mostre, esses três estados pintam a maior parte
da figura. O Distrito Federal, o melhor estado pela taxa, é um ponto que mal se vê.

Um mapa de blocos **dá a todo estado o mesmo peso**, o que é certo quando todo estado conta como um:
um ranking, uma política, um voto. As posições mantêm uma noção aproximada da geografia, então
vizinhos continuam vizinhos e o Norte continua no alto.

## O que um mapa de blocos perde

- **Forma e tamanho.** Ninguém reconhece um estado pelo seu quadrado. Os rótulos têm de estar lá,
  como estão na primeira figura desta aula.
- **A vizinhança exata.** Alguns vizinhos não conseguem se tocar numa grade. Neste arranjo, Tocantins
  fica ao lado de Goiás mas não da Bahia, embora os dois tenham uma fronteira longa.
- **A área como informação.** Quando o tamanho do lugar faz parte da história, como área plantada ou
  floresta, um mapa de blocos a esconde.

## Cartogramas

Um **cartograma** vai além e redimensiona cada área pelo dado: um estado com o dobro de pedidos é
desenhado com o dobro do tamanho, entortando as fronteiras para caber. Ele impressiona, e junta as
forças de um mapa de símbolos e de um mapa pintado, ao preço de um mapa que ninguém reconhece sem
prática. Use um quando o público já conhece bem o mapa real, e junte o mapa real quando não conhecer.

## De onde vêm as formas reais

Para desenhar as fronteiras reais, uma ferramenta precisa de um **arquivo geográfico** que descreva o
contorno de cada estado: shapefiles ou GeoJSON, publicados para o Brasil pelo IBGE. O Power BI e o
Tableau trazem as fronteiras comuns; em Python, bibliotecas como o geopandas leem os arquivos e os
desenham com o matplotlib. A aula 20 compara as ferramentas.
