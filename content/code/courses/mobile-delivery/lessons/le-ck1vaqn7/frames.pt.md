---
title: Quadros, lentos e congelados
version: 1
---

**Rolagem suave quer dizer um quadro novo a cada atualização da tela, e um quadro que perde o prazo
aparece como uma engasgada.** A 60 quadros por segundo, cada quadro tem cerca de **16 milissegundos**;
numa tela de 120 Hz, cerca de 8. *Lido na documentação do Android sobre renderização lenta, outubro
de 2026.*

## Dois tipos de quadro ruim

| | definição | o que a pessoa sente |
|---|---|---|
| **quadro lento** | levou mais de 16 ms para renderizar | uma engasgada numa rolagem ou numa animação |
| **quadro congelado** | levou mais de **700 ms** para renderizar | o app parou por um instante, e o toque pareceu ignorado |

A documentação do Android diz que **nenhum quadro deveria levar mais de 700 ms**, e conta os quadros
congelados à parte dos lentos. Um quadro congelado é um travamento curto, a mesma falha do ANR da
lição 14 em escala menor, quase sempre com a mesma causa: trabalho na thread principal.

## Como eles são medidos

- O **Android vitals** informa a fração das sessões com quadros lentos ou congelados demais, vinda
  dos celulares das pessoas.
- A biblioteca **JankStats** do Android e os testes de **Macrobenchmark** medem quadros no seu próprio
  app e no seu laboratório.
- No iOS, a **hitch rate** no Organizer do Xcode e no MetricKit, e o Instruments num Mac.
- No React Native, os mesmos números nativos, mais uma thread JavaScript que perde quadros próprios
  quando está ocupada, porque animações conduzidas pelo JavaScript esperam por ela.

## O quadro lento do planner

A visão da semana desenha uma linha por sessão. Uma linha que formata a data criando um formatador
novo a cada vez gasta milissegundos em cada linha; role uma lista de duzentas sessões e os quadros
ficam lentos. A cura é a mesma em toda plataforma: crie o formatador uma vez e reutilize, e calcule o
total da semana uma vez, quando os dados mudam, e não em todo quadro que o desenha. **Trabalho feito
por quadro é multiplicado pela taxa de quadros**; trabalho feito por mudança, não.
