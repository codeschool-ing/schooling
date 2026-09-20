---
title: Wi-Fi, que é rádio e se comporta como rádio
version: 1
---

Wi-Fi é rádio. Tudo o que surpreende nele deixa de surpreender quando essa frase é levada ao pé da
letra: ele é absorvido por coisas, é refletido por coisas, sofre interferência de outros rádios, e
enfraquece com a distância de um jeito que não liga para quanto você pagou.

## Duas faixas, e a troca é sempre a mesma

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 322\" role=\"img\" aria-label=\"Um diagrama comparando as duas faixas de Wi-Fi em quatro cômodos. Em cima, o cômodo do roteador, a uma parede, a duas paredes e a três paredes. Embaixo, uma barra de dois vírgula quatro gigahertz cobrindo todos os cômodos, e uma barra de cinco gigahertz cobrindo só os dois primeiros, bem mais rápida onde alcança.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">A mesma casa, medida nas duas faixas</text><rect x=\"24\" y=\"38\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o cômodo do roteador</text><rect x=\"192\" y=\"38\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a uma parede</text><rect x=\"360\" y=\"38\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"444.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a duas paredes</text><rect x=\"528\" y=\"38\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"612.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a três paredes</text><text x=\"108.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a caixa está aqui</text><text x=\"24\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">2,4 GHz</text><text x=\"696\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mbps</text><rect x=\"24\" y=\"136\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.22\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">90</text><text x=\"276.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">70</text><text x=\"444.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45</text><text x=\"612.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25</text><text x=\"24\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Mais lento em todo lugar, e chega em todo lugar.</text><text x=\"24\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">5 GHz</text><text x=\"696\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mbps</text><rect x=\"24\" y=\"232\" width=\"336\" height=\"34\" rx=\"4\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"360\" y=\"232\" width=\"336\" height=\"34\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">420</text><text x=\"276.0\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">180</text><text x=\"612.0\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">—</text><text x=\"444.0\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">—</text><text x=\"24\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Três vezes a velocidade no primeiro cômodo, e nada nos dois últimos.</text><text x=\"24\" y=\"306\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Os números são uma ilustração, não uma medida: uma parede de tijolo e uma de drywall são paredes diferentes.</text></svg>", "caption": "Duas barras sobre a planta de quatro cômodos. A barra de dois vírgula quatro gigahertz cobre os quatro cômodos, com velocidades caindo de noventa para vinte e cinco. A barra de cinco gigahertz cobre os dois primeiros cômodos com quatrocentos e vinte e cento e oitenta, e fica vazia nos dois últimos.", "same": ["5 GHz"]}
```

Todo roteador moderno transmite em **2,4 GHz** e em **5 GHz**, e muitas vezes nas duas ao mesmo
tempo com o mesmo nome.

- **2,4 GHz vai mais longe e atravessa mais paredes**, e é mais lento. Também é lotado: telefones
  sem fio, babás eletrônicas, Bluetooth e — sério, não é piada — fornos de micro-ondas usam essa
  faixa, junto com o roteador de todo vizinho.
- **5 GHz é bem mais rápido e para nas paredes.** Num apartamento costuma ser a melhor escolha no
  cômodo onde está o roteador e no vizinho de porta, e inútil a três cômodos de distância.

Uma faixa mais nova, **6 GHz**, vai mais longe na mesma direção: mais rápida ainda, e mal sai do
cômodo. Celulares e notebooks dos últimos anos conseguem usá-la; nada mais velho consegue.

**A decisão em geral é tomada por você**, porque a maioria das caixas anuncia um nome só nas duas
faixas e deixa cada aparelho escolher. Isso funciona bem e falha de um jeito específico: um
aparelho que se conectou em 5 GHz na sala se agarra a ela enquanto você se afasta, muito depois do
ponto em que 2,4 GHz seria mais rápido. Desligar e ligar o Wi-Fi faz ele escolher de novo, que é
por que esse ritual de aparência inútil às vezes funciona.

## Onde a caixa fica

A maior melhoria isolada disponível para a maioria das casas não custa nada:

- **Alto, no centro e à vista.** Um roteador no chão atrás do sofá está irradiando para dentro de
  móveis. Numa prateleira no meio do apartamento, ele alcança quase tudo.
- **Longe de metal e de água.** Um armário de metal é uma blindagem. Um aquário é um balde de uma
  substância que absorve 2,4 GHz especificamente — é a mesma física que um micro-ondas usa.
- **Longe dos outros rádios.** Um metro da base do telefone sem fio e do micro-ondas basta.
- **Não no armário ao lado da porta de entrada**, que é onde o provedor instalou porque é onde o
  cabo entra. Mudá-lo de lugar é um cabo mais comprido e uma tarde, e em geral vale mais do que
  qualquer troca de equipamento.

## Canais, em resumo

Cada faixa é dividida em canais, e dois roteadores no mesmo canal o dividem — eles não interferem,
propriamente, eles se revezam, que é por que um canal lotado dá sensação de *lento* e não de
*quebrado*.

Em 2,4 GHz há só três que não se sobrepõem: **1, 6 e 11.** Qualquer outro se sobrepõe a dois deles
e piora as coisas para todo mundo, você incluído.

A maioria dos roteadores escolhe sozinha e quase sempre isso basta. Só vale olhar à mão quando um
aplicativo de celular varrendo a vizinhança mostra nove redes no canal 6 e nenhuma no 11.

## O que a barrinha está de fato dizendo

As barras de sinal num celular reportam **intensidade**, e intensidade não é velocidade. Uma
conexão de intensidade máxima com um roteador cuja linha para a rua está saturada é uma barra
cheia e nada carregando.

Vale separar as duas sempre que alguém disser que o Wi-Fi está lento, e a seção depois da próxima
é como.
