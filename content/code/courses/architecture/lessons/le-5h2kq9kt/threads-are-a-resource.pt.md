---
title: As threads também são um recurso
version: 1
---

Um serviço tem limites que ninguém escreveu no projeto dele: **um número fixo de coisas que ele consegue
fazer ao mesmo tempo**. Threads num pool, conexões com o banco, memória para requisições em andamento,
descritores de arquivo. Cada um tem um número, em geral o padrão de um framework: 200 threads no Tomcat,
10 conexões no pool do HikariCP, um único processo worker no
Gunicorn. Abaixo desse número o serviço é rápido; nele,
toda requisição nova espera.

A aula 5 deu nome ao caso perigoso. Quem espera uma chamada síncrona segura uma dessas coisas enquanto
espera. Quando uma dependência responde em 20 milissegundos, uma thread fica presa 20 milissegundos e o
pool gira rápido. Quando a mesma dependência começa a levar cinco segundos, toda requisição que a chama
segura uma thread por cinco segundos, e a poucas requisições por segundo **o pool inteiro logo está
esperando um serviço lento**. Nada falhou, e nada mais consegue rodar.

É assim que uma falha se espalha por um sistema sem nenhum erro ser lançado: o serviço lento deixa lentos
os que o chamam, os chamadores destes dão timeout esperando por eles, e a queda avança para fora um salto
de cada vez. Isso se chama **falha em cascata**, e os retries da aula 11 a pioram.

A aula 11 tratou da dependência: timeout, retry com cuidado, parar de chamá-la quando está claramente fora.
Esta aula trata **do recurso**: quanto dele cada coisa pode usar, e o que dizer ao trabalho que chega
quando ele acabou. Três ferramentas, uma para cada jeito de o recurso acabar:

| o que consome o recurso | a ferramenta |
| --- | --- |
| uma dependência lenta | um **bulkhead**: um limite de quanto do recurso ela pode segurar |
| um cliente pedindo vezes demais | **throttling**: um limite de com que frequência cada cliente pode pedir |
| mais trabalho do que dá para fazer agora | uma **fila limitada**, e **back pressure** quando ela enche |
