---
title: Tempo de abertura
version: 1
---

**A primeira coisa que qualquer pessoa experimenta de um app é quanto tempo ele leva para abrir, e
isso é medido do toque até a primeira tela útil.** As duas plataformas medem isso nos celulares das
pessoas e informam a você, e as duas distinguem três tipos de abertura, porque eles custam coisas
muito diferentes. *Lido na documentação de desenvolvedor do Android sobre tempo de abertura, outubro
de 2026, e na da Apple sobre reduzir o tempo de abertura.*

| | o que precisa acontecer | com que frequência |
|---|---|---|
| **abertura a frio** | o sistema cria o processo, carrega o código, roda a inicialização do app, desenha a primeira tela | depois de reiniciar, depois de o sistema matar o app por memória, a primeira vez do dia para muita gente |
| **abertura morna** | o processo sumiu ou a tela foi destruída, mas algum estado sobrevive | depois de um tempo em segundo plano |
| **abertura quente** | o app estava em segundo plano, inteiro; ele só vem para a frente | ao alternar entre apps |

A documentação do Android recomenda sempre otimizar pensando na abertura a frio, porque melhorar
essa melhora as outras duas.

## Os dois números que o Android informa

- **Tempo até a exibição inicial (TTID)**: da abertura até o primeiro quadro desenhado. O Android o
  mede para todo app automaticamente.
- **Tempo até a exibição completa (TTFD)**: da abertura até o momento em que o app diz que o conteúdo
  está pronto, o que ele faz chamando `reportFullyDrawn()`. Para o planner, isso é a semana com as
  sessões e o total, e não um quadro vazio com um indicador girando.

O TTID pode ser encurtado desenhando um esqueleto rápido; o TTFD é o que a pessoa de fato esperou.
**Informe os dois**, para que um esqueleto rápido não esconda uma semana lenta.

## O que deixa uma abertura a frio lenta

- **Trabalho no `Application.onCreate`, no `init` do app ou na primeira renderização do React
  Native**: bibliotecas inicializadas cedo demais, um coletor de crashes, analytics, configuração
  remota, tudo antes do primeiro quadro.
- **Ler o banco na thread principal** para mostrar a primeira tela, lição 14.
- **Carregar código**: um bundle JavaScript grande para interpretar, ou muitos frameworks dinâmicos
  para ligar no iOS. O **Hermes** do React Native compila o JavaScript para bytecode na hora do build,
  então o celular pula a interpretação em toda abertura.

## A mesma métrica nas outras plataformas

No iOS, o **Organizer do Xcode** mostra tempos de abertura de quem compartilha diagnósticos, e o
**MetricKit** entrega as mesmas medidas ao próprio app. O watchdog da lição 14 é o caso extremo: uma
abertura tão lenta que o sistema a encerra. Apps React Native são medidos pela plataforma nativa
embaixo deles, então os números vêm dos mesmos dois lugares.
