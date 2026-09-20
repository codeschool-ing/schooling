---
title: Memória, e a palavra que explica todo "ele perdeu meu trabalho"
version: 1
---

A RAM — memória de acesso aleatório — guarda o que o computador está trabalhando **agora**. Cada
programa rodando, cada documento aberto, o próprio sistema operacional. O processador lê
qualquer parte dela em uns cem nanossegundos, e é por isso que o trabalho acontece ali e não em
outro lugar.

Uma propriedade decide todo o resto: **a RAM é volátil.** Corte a energia e ela fica em branco.
Não corrompida, não parcialmente lá — em branco, como se nunca tivesse guardado nada.

Isso não é um defeito que alguém esteja tentando consertar. É a troca que torna a RAM rápida o
bastante para valer a pena, e a razão de o `Ctrl+S` existir.

> **A frase mais cara desta seção.** Um documento que você digitou e não salvou existe em
> exatamente um lugar, e esse lugar é apagado por uma queda de energia, uma bateria no fim ou um
> travamento. O programa não "perdeu" nada. Aquilo nunca esteve num lugar capaz de guardar.

## Quanto é suficiente, e como é ficar sem

A resposta honesta em meados dos anos 2020, para uma máquina de uso geral:

| | |
|---|---|
| 8 GB | um navegador e mais uma coisa. Dá para trabalhar, e você vai bater no teto |
| **16 GB** | **o padrão sensato.** Navegador com muitas abas, um pacote de escritório, uma chamada de vídeo |
| 32 GB para cima | edição de vídeo, máquinas virtuais, conjuntos de dados grandes |

O que importa mais que o número é reconhecer o teto quando você bate nele, porque o sintoma é
específico e nada mais o produz.

## Swap: o que uma mesa lotada faz de fato

Quando a RAM enche, o sistema operacional não recusa abrir o próximo programa. Ele escolhe
alguma coisa que ninguém tocou há um tempo, **escreve aquilo no armazenamento**, e entrega a
memória liberada. Quando você volta para aquela janela, ela tem de ser lida de novo — e outra
coisa é escrita para fora para abrir espaço.

Isso é o **swap**, e é por ele que a metáfora da mesa se paga. A pessoa não está trabalhando. A
pessoa está carregando papel para o arquivo e de volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 234\" role=\"img\" aria-label=\"Duas linhas. A de cima, marcada memória suficiente, mostra quatro programas dentro de uma barra de memória com espaço sobrando, e uma nota de que trocar entre eles é instantâneo. A de baixo, marcada memória cheia, mostra quatro programas que não cabem: um é empurrado para uma caixa larga de armazenamento embaixo, por uma seta marcada escrito para fora, e uma seta de volta marcada lido de volta quando você clica naquela janela. Uma nota diz que a máquina está ocupada e sem entregar nada, e que é isso que um computador que parece travado costuma estar fazendo.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Os mesmos quatro programas, numa máquina com espaço e numa sem.</text><text x=\"14\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">memória suficiente</text><rect x=\"14\" y=\"56\" width=\"520\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"24\" y=\"64\" width=\"110\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"140\" y=\"64\" width=\"110\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"256\" y=\"64\" width=\"110\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"372\" y=\"64\" width=\"110\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546\" y=\"73\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">trocar é instantâneo</text><text x=\"14\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">memória cheia</text><rect x=\"14\" y=\"128\" width=\"520\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"24\" y=\"136\" width=\"162\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"136\" width=\"162\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"360\" y=\"136\" width=\"162\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o quarto não cabe</text><rect x=\"14\" y=\"178\" width=\"520\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"24\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">armazenamento</text><rect x=\"192\" y=\"194\" width=\"162\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M270 160 L270 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M270 192 L266 184 L274 184 Z\" fill=\"var(--amber)\"></path><text x=\"282\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">escrito para fora</text><path d=\"M360 203 L520 203\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><path d=\"M522 203 L514 199 L514 207 Z\" fill=\"var(--amber)\"></path><text x=\"546\" y=\"203\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">e lido de volta quando você clica nele</text><text x=\"14\" y=\"228\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ocupada, e sem entregar nada. Um computador que parece travado costuma estar fazendo isto.</text></svg>", "caption": "Nada está quebrado na linha de baixo. A máquina funciona como foi projetada, e o projeto é ficar mais lenta em vez de recusar."}
```

Os sintomas são inconfundíveis depois que você os conhece:

- a máquina inteira fica lenta, não um programa;
- a luz do disco — ou o gráfico de disco no gerenciador de tarefas — fica ocupada enquanto o
  processador está quase parado;
- **trocar de janela** é o que dói, e ir e voltar dói mais.

Esse último é o sinal. Um processador lento deixa uma tarefa lenta. O swap deixa *mudar de
ideia* lento.

## E é por isso que o conselho é o que é

"Fecha umas abas" não é sabedoria popular. Cada aba é papel na mesa, e o jeito mais barato de
parar a carregação é precisar de menos espaço. E quando uma máquina está no teto, **mais memória
é uma compra muito melhor que um processador mais rápido** — você não está comprando
velocidade, está comprando a ausência daquela carregação.
