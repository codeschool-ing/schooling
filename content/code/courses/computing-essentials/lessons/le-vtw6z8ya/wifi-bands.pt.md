---
title: 2,4 e 5 GHz, e a escolha entre alcançar e ser rápido
version: 1
---

Um roteador Wi-Fi transmite em duas ou três bandas ao mesmo tempo, e elas não são qualidades da
mesma coisa. São físicas diferentes, e a escolha entre elas é a mesma troca da seção anterior,
desenhada numa decisão só.

| | 2,4 GHz | 5 GHz | 6 GHz |
|---|---|---|---|
| através de paredes | melhor | médio | pior |
| alcance | o maior | bom | curto |
| velocidade | a menor | alta | a maior |
| quão disputada | muito | bem menos | quase vazia |
| usada também por | micro-ondas, babás eletrônicas, Bluetooth | radar em alguns canais | nada ainda |

**Frequência mais baixa viaja mais longe e contorna melhor as coisas.** Isso não é uma escolha de
projeto de ninguém; é o que ondas mais longas fazem. Então `2,4 GHz` é a que chega ao fundo do
quintal e é a que todo aparelho barato da vizinhança também está usando.

## Os canais, e por que só três deles são reais

A banda de `2,4 GHz` é dividida em 13 canais com centros separados por `5 MHz` — só que cada
canal tem `22 MHz` de largura. **Eles se sobrepõem.** O canal 2 fica em cima de quase todo o
canal 1 e de quase todo o canal 3.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Duas fileiras. A de cima mostra três blocos largos lado a lado, rotulados 1, 6 e 11, encostados mas sem se sobrepor. A de baixo mostra os mesmos blocos do 1 e do 6 como contornos tracejados, com um bloco sólido rotulado 3 atravessado sobre os dois, cobrindo a parte direita do bloco 1 e a parte esquerda do bloco 6. Uma nota diz que qualquer coisa que não seja 1, 6 ou 11 fica em cima de dois vizinhos e se reveza com os dois.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Treze canais, e só três deles cabem lado a lado</text><text x=\"24\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os três que não se sobrepõem</text><rect x=\"60\" y=\"68\" width=\"166\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"143\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">1</text><rect x=\"249\" y=\"68\" width=\"166\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"332\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">6</text><rect x=\"438\" y=\"68\" width=\"166\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"521\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">11</text><text x=\"24\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">e onde o canal 3 cai</text><rect x=\"60\" y=\"166\" width=\"166\" height=\"48\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><rect x=\"249\" y=\"166\" width=\"166\" height=\"48\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><rect x=\"136\" y=\"178\" width=\"166\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"219\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\">3</text><text x=\"24\" y=\"260\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Qualquer canal que não seja 1, 6 ou 11 fica sobre dois vizinhos e tem de se revezar com os dois.</text></svg>", "caption": "Três canais, e todo outro número é um jeito de dividir o ar de duas pessoas em vez do de uma."}
```

**Só os canais 1, 6 e 11 cabem lado a lado sem se tocar.** Um roteador no canal 3 não está
escolhendo um lugar calmo entre dois ocupados — está entrando na fila dos dois ao mesmo tempo, e
virando problema para ambos.

## O que fazer de fato com um roteador doméstico

- **Ponha os aparelhos principais em 5 GHz** e deixe o `2,4 GHz` para as coisas distantes,
  baratas ou velhas: uma campainha, uma impressora no cômodo ao lado, um termostato.
- **Veja em que canal estão os vizinhos** com um analisador de Wi-Fi gratuito no celular, e mude
  para o mais vazio entre 1, 6 e 11. Isso é de graça e costuma ser a maior melhoria disponível.
- **Não ponha a largura de canal do 2,4 GHz em 40 MHz.** Ela dobra a velocidade na teoria e num
  prédio significa ocupar dois dos três canais utilizáveis.
- **Mude o roteador de lugar.** Central, longe do chão, fora do armário de metal. Um roteador num
  canto gasta três quartos do sinal dele com a rua.

## Mesh, repetidores e qual é a diferença

Um **repetidor** escuta o roteador e grita de novo. Ele fala no mesmo rádio em que escuta, então
**divide pela metade a velocidade de tudo que está atrás dele**, e um segundo repetidor divide de
novo.

Um sistema **mesh** tem um rádio dedicado ao enlace entre as unidades dele, então elas conversam
entre si sem roubar dos clientes. Custa mais e é a resposta certa para uma casa em que uma caixa
só não alcança.

**Um cabo até a unidade distante ganha dos dois**, sempre que houver qualquer jeito de passar um.
É esse o conselho inteiro, e ele não é glamoroso.
