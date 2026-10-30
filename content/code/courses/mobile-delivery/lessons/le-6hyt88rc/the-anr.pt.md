---
title: O ANR
version: 1
---

**A interface de um app roda numa thread só, a thread principal, e qualquer coisa lenta feita ali
congela a tela inteira.** Todo toque, toda rolagem e todo quadro esperam por ela. Quando a thread
principal fica ocupada por tempo demais, o Android avisa com um diálogo, *o app não está
respondendo*, oferecendo esperar ou fechar. Isso é um **ANR**, *Application Not Responding*, e o
Google Play o conta como um crash. *Lido na documentação de desenvolvedor do Android sobre ANRs e
sobre o Android vitals, outubro de 2026.*

## Quando o Android declara um

| o que estava esperando | quanto o Android espera |
|---|---|
| um evento de entrada, uma tecla ou um toque | 5 segundos |
| um broadcast receiver, em primeiro plano | 10 segundos |
| um serviço instruído a virar serviço em primeiro plano, chamando `startForeground` | 5 segundos |

A primeira linha é a comum. A pessoa tocou a tela e nada respondeu por cinco segundos; é tempo
suficiente para muitas desistirem antes mesmo de o diálogo aparecer, então os ANRs contados são
menos do que os travamentos que as pessoas sentiram.

## Como o Google Play os conta

O Android vitals informa uma **taxa de ANR percebida pelo usuário**, a fração dos usuários diários
que viram um ANR que o sistema mostrou, e usa o mesmo tipo de limite dos crashes, lição 12:

| | geral | num modelo de celular |
|---|---|---|
| taxa de ANR percebida pelo usuário | 0,47% | 8% |

O limite geral é menos da metade do limite de crash, de 1,09%. O Google trata um app travado como
pior que um app que quebrou, o que combina com o que as pessoas sentem: um crash acaba rápido, um
travamento as faz esperar e depois decidir.

## O que trava uma thread principal

- **Disco na thread principal**: abrir o banco do planner, ler um arquivo grande, gravar
  preferências de forma síncrona.
- **Rede na thread principal**, que o Android proíbe de vez e para a qual lança uma exceção, mas que
  uma biblioteca embrulhando-a numa chamada síncrona ainda consegue fazer.
- **Computação longa**: interpretar um ano de sessões, ordenar milhares de linhas, decodificar uma
  imagem grande.
- **Esperar um lock** que outra thread segura enquanto ela mesma espera algo lento.

A cura é sempre a mesma em princípio, tirar o trabalho da thread principal, e a seção "Fora da
thread principal" a mostra nas três plataformas.
