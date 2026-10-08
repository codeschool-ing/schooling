---
title: Quando pacotes, e não logs
version: 1
---

A aula 1 apresentou as fontes da menos detalhada para a mais: uma linha de log diz que uma conexão aconteceu, um
registro de fluxo diz entre quem e quantos bytes, e uma **captura de pacotes** guarda os próprios pacotes, todo
byte que passou pelo fio. O fluxo da aula 12 disse que 612 MB saíram do `files` para `203.0.113.200`. Não
conseguiu dizer o que eram esses bytes. Uma captura daquela noite teria conseguido, se o tráfego não estivesse
criptografado.

Pacotes são a fonte mais detalhada e a mais cara, e por isso ninguém guarda todos por muito tempo:

| | registros de fluxo | captura completa de pacotes |
|---|---|---|
| **diz** | quem, para quem, quando, quantos bytes | tudo isso, mais todo byte do conteúdo |
| **tamanho** | algumas dezenas de bytes por conversa | a conversa inteira, e um pouco mais |
| **guardado por** | meses | horas ou dias, numa rede movimentada |
| **responde** | "o `files` falou com este endereço?" | "o que o `files` mandou para este endereço?" |

Então, na prática, um SOC faz duas coisas. Guarda fluxos por muito tempo, e captura pacotes **de propósito**: um
buffer contínuo das últimas horas na borda da internet, ou uma captura iniciada num host ou num endereço durante
um incidente, do jeito que a contenção da aula 13 teria sido um bom momento para iniciar uma na `eth0` do `fw`.

Esta aula captura um download comum no laboratório e o desmonta, dos pacotes até o arquivo.
