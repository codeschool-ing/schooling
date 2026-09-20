---
title: Bluetooth, e por que os mesmos fones soam pior numa chamada
version: 1
---

O Bluetooth é construído em torno de uma restrição que o Wi-Fi não tem: **ele precisa funcionar
por meses com uma bateria do tamanho de uma moeda.** Tudo de estranho nele decorre disso.

Ele trabalha em saltos curtos, dorme entre eles, e cobre uns dez metros. Também divide a banda de
`2,4 GHz` com o Wi-Fi, e desvia dele pulando entre 79 canais estreitos 1 600 vezes por segundo —
então ele contorna um canal de Wi-Fi ocupado em vez de brigar com ele.

## Perfis, que é a resposta da pergunta do título

Um aparelho Bluetooth não tem uma conexão. Ele tem **perfis**, e cada um é um acordo separado
sobre o que está sendo enviado. Os dois que importam para fones:

- **`A2DP`** — áudio estéreo de mão única, boa qualidade. É o que você tem ouvindo.
- **`HFP`** ou **`HSP`** — áudio de mão dupla para uma chamada telefônica. Um canal, e uma fração
  da banda, porque o mesmo rádio agora tem de levar o microfone também.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Duas barras de comprimentos muito diferentes. A de cima, rotulada A2DP, ocupa quase toda a largura e é descrita como estéreo a 44 quilohertz. A de baixo, rotulada HFP, tem cerca de um quinto do comprimento e é descrita como um canal a 8 ou 16 quilohertz. Uma nota diz que os fones e a distância são os mesmos e que só o perfil mudou.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">O que abrir o microfone custa à música</text><text x=\"24\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que os fones estão fazendo</text><text x=\"200\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quanto som passa</text><text x=\"24\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">só ouvindo</text><rect x=\"200\" y=\"70\" width=\"480\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A2DP</text><text x=\"664\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">estéreo, e o som inteiro</text><text x=\"24\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">numa chamada</text><rect x=\"200\" y=\"150\" width=\"96\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">HFP</text><text x=\"320\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um canal, e um quinto do detalhe</text><text x=\"24\" y=\"230\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Os mesmos fones, à mesma distância. Só o perfil mudou, e a música mudou junto.</text></svg>", "caption": "Nada quebrou quando isso acontece. O rádio está levando um microfone agora, e quem paga é a música."}
```

Então: a música soa excelente, uma chamada começa, **e a música que toca ao fundo dessa chamada
passa instantaneamente a soar como um telefone**. Os fones não falharam, e não há o que
consertar. O único contorno é manter o microfone em outro lugar — um separado, ou o da própria
máquina.

## Codecs, honestamente

O `SBC` é o que todo aparelho suporta e ele é suficiente. `AAC`, `aptX` e `LDAC` são melhores, e
cada um precisa que **as duas pontas** o falem. Um celular com `LDAC` e fones sem ele caem para
`SBC` e nada avisa.

A diferença é real e menor que a propaganda: é audível em fones bons numa sala silenciosa e
inaudível num ônibus. Nada disso vale durante uma chamada, em que o perfil já levou a banda
embora.

## Versões, e a que se partiu em duas

O `Bluetooth 4.0` trouxe o **Low Energy**, e ele é um protocolo diferente que divide um nome. O
`LE` leva quase nenhum dado e roda por anos com uma pilha-moeda: pulseiras, sensores, etiquetas,
um teclado. O Bluetooth clássico leva áudio. A maioria dos aparelhos faz os dois.

As versões seguintes — `5.0`, `5.2`, `5.3` — estendem principalmente o LE. **O `LE Audio` e o
codec `LC3` finalmente resolvem o problema da chamada acima**, levando áudio bom de mão dupla com
pouca banda. Precisa das duas pontas e está chegando devagar.

## O que de fato dá errado

| sintoma | o que costuma ser |
|---|---|
| engasga perto do computador | o rádio de Wi-Fi e o de Bluetooth dividem uma antena |
| não pareia | o aparelho já está pareado com outra coisa que está ligada |
| o som chega atrasado | normal: 150 a 250 ms, e é por isso que os lábios não batem |
| cai num cômodo específico | uma pessoa ou uma parede. O Bluetooth não tem potência sobrando |

O atraso merece ser nomeado porque as pessoas o tratam como defeito. Reprodutores de vídeo
compensam automaticamente; jogos em geral não, e esse é o único uso em que um cabo ainda ganha de
saída.
