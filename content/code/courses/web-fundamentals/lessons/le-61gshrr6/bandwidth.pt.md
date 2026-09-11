---
title: Capacidade, não velocidade
version: 1
---

**Largura de banda é quanto cabe de uma vez.** É uma taxa — uma quantidade por segundo — e é o
número de todo plano de internet já vendido.

Não é velocidade. Nada viaja mais rápido numa conexão maior. O que muda é quanto viaja lado a
lado, e manter essas duas coisas separadas é a maior parte do que esta aula serve.

## O cano, e a parte honesta da metáfora

O desenho usual é um cano, e é bom desde que você tire dele a coisa certa.

Um cano mais largo não faz a água andar mais rápido dentro dele. Faz **mais água andar de uma
vez**. Se você precisa mover uma banheira, um cano mais largo termina antes — não porque a água se
apressou, mas porque mais dela foi por vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Dois canos lado a lado. O estreito leva duas unidades de água lado a lado, o largo leva seis. Uma seta sob os dois mostra a água movendo-se à mesma velocidade em cada um; só muda a quantidade que vai lado a lado.\"><rect x=\"14\" y=\"20\" width=\"340\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"184\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Um cano estreito</text><rect x=\"38\" y=\"70\" width=\"292\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><rect x=\"48\" y=\"80\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"96\" y=\"80\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"184\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">duas unidades lado a lado</text><text x=\"184\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">mesma velocidade pelo cano</text><text x=\"184\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma banheira demora mais</text><rect x=\"368\" y=\"20\" width=\"340\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"538\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Um cano largo</text><rect x=\"392\" y=\"62\" width=\"292\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><rect x=\"402\" y=\"70\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"70\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"498\" y=\"70\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"402\" y=\"92\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"92\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"498\" y=\"92\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"538\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seis unidades lado a lado</text><text x=\"538\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">mesma velocidade pelo cano</text><text x=\"538\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma banheira demora menos</text></svg>", "caption": "A largura é a largura de banda. Nada em nenhum dos canos se move mais rápido do que no outro."}
```

Onde a metáfora deixa de ajudar é no comprimento. Um cano da sua casa até uma máquina no Japão é
*longo*, e o comprimento do cano não tem nada a ver com a largura dele. Esse comprimento é a
próxima seção.

## Bits, bytes e a confusão mais difundida que existe

O seu plano diz **300 Mbps**. O seu download mostra **37 MB/s**. Os dois estão certos, e as pessoas
discutem sobre isso há trinta anos.

- Um **bit** é um 0 ou um 1. Velocidades de rede são cotadas em bits por segundo, com `b`
  minúsculo.
- Um **byte** são oito bits. Tamanhos de arquivo e gerenciadores de download usam bytes, com `B`
  maiúsculo.

Então a conversão é uma divisão por oito:

| o que o plano diz | o que um download mostra |
|---|---|
| 100 Mbps | cerca de 12,5 MB/s |
| 300 Mbps | cerca de 37,5 MB/s |
| 600 Mbps | cerca de 75 MB/s |
| 1 Gbps | cerca de 125 MB/s |

Se você vê mais ou menos um oitavo do número que esperava, **não há nada errado**. Você está
olhando a mesma quantidade na outra unidade.

Por que duas unidades é em parte história e em parte marketing: a indústria que vende conexões cota
o número que parece oito vezes maior. Isso não vai mudar, então a defesa é saber qual letra você
está lendo.

## O número é um teto, e é compartilhado

Mais duas coisas que o plano não explica.

**É um máximo, não uma promessa.** 300 Mbps significa *até* 300, em boas condições, na parte do
caminho que o seu provedor controla. Nada nisso garante o que um site específico vai te mandar.

**E é compartilhado, mais de uma vez.** Todo aparelho da sua casa divide isso. E, mais adiante,
toda residência da sua rua também — provedores não constroem uma linha privada de 300 Mbps por
cliente, porque em qualquer momento quase ninguém está usando a sua. Esse arranjo é sensato e é
também por que a noite é mais lenta que a manhã.

## Onde o teto de fato está

Um caminho são muitos enlaces, e você não fica com o mais largo deles. **Você fica com o mais
estreito.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma cadeia de cinco enlaces entre um notebook e um servidor, rotulados com capacidades de 1200, 300, 40, 940 e 10000 megabits por segundo. O enlace de 40 está marcado como o mais estreito, e uma nota diz que é isso que o caminho inteiro entrega.\"><rect x=\"8\" y=\"66\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"50\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">notebook</text><text x=\"50\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1200</text><rect x=\"148\" y=\"66\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"190\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Wi-Fi</text><text x=\"190\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><rect x=\"288\" y=\"60\" width=\"84\" height=\"56\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cabo velho</text><text x=\"330\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">40</text><rect x=\"428\" y=\"66\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"470\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provedor</text><text x=\"470\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">940</text><rect x=\"568\" y=\"66\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"616\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o servidor</text><text x=\"616\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10000</text><path d=\"M92 88 L144 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M232 88 L284 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M372 88 L424 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M512 88 L564 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">megabits por segundo, por enlace</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">o caminho inteiro entrega 40 — você fica com o mais estreito, nunca com o mais largo</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">melhorar qualquer um dos outros quatro não muda absolutamente nada</text></svg>", "caption": "O gargalo é uma propriedade do caminho, não do seu plano. Alargar qualquer coisa que não seja o enlace estreito não compra nada."}
```

Vale guardar isso, porque é a razão de tanto dinheiro ser gasto em conexões que não mudam nada. Se
o enlace estreito é um cabo cansado dentro da parede, ou o Wi-Fi de um cômodo distante, ou a
capacidade de saída do próprio servidor, então dobrar o plano dobra um número que nunca foi o
limite.

## Upload é outro número, e quase sempre bem menor

Quase toda conexão doméstica é **assimétrica**: consegue receber muito mais do que consegue enviar.

Um plano anunciado como 300 Mbps muitas vezes quer dizer 300 de descida e 30 de subida, ou 300 e
15, e o segundo número vem em letra menor ou nem vem. A razão é histórica e razoável — a maioria
das casas consome muito mais do que produz, então a capacidade foi alocada onde era usada.

Deixou de ser inofensivo quando as casas começaram a produzir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Duas barras para uma conexão. Uma barra longa rotulada download a 300 megabits por segundo, e outra bem mais curta abaixo rotulada upload a 30. Uma nota ao lado diz que uma chamada de vídeo usa a curta.\"><text x=\"60\" y=\"58\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">download</text><rect x=\"150\" y=\"40\" width=\"460\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".26\" stroke=\"var(--phosphor)\"></rect><text x=\"380\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">300 Mbps</text><text x=\"60\" y=\"114\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">upload</text><rect x=\"150\" y=\"96\" width=\"46\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".26\" stroke=\"var(--amber)\"></rect><text x=\"246\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">30 Mbps — o mesmo plano</text><text x=\"360\" y=\"166\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sua câmera, seus backups e todo arquivo que você envia usam a barra curta</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e é por isso que eles aparecem bem para você e mal para o outro</text></svg>", "caption": "Um plano, dois números bem diferentes. Só um deles está no anúncio."}
```

Isso explica uma reclamação que você certamente vai encontrar. Numa chamada de vídeo, **você vê a
outra pessoa perfeitamente e ela diz que você está travado.** A imagem dela chega pelo seu download
enorme; a sua sai pelo seu upload pequeno, e se houver um backup rodando ao mesmo tempo, ela sai
pelo que o backup não estiver usando.

A mesma assimetria é por que enviar um arquivo grande parece tão mais lento que receber um do mesmo
tamanho, e por que uma conexão doméstica é um lugar ruim para hospedar qualquer coisa.

## E largura de banda quase nunca é o que está lento

O último ponto é sobre o qual o resto da aula se apoia.

Uma transferência grande — um filme, um jogo, um backup — é limitada por largura de banda, e ter
mais ajuda de verdade.

**Uma transferência pequena não é.** Carregar uma página são dezenas de requisições pequenas, e
para cada uma delas o tempo é dominado por *ir e voltar*, não por quanto cabe lado a lado. Você
pode dobrar a largura de um cano o quanto quiser; se o que você está mandando é um cartão-postal,
nunca foi a largura que fez aquilo levar quatrocentos milissegundos.

Que é a razão inteira de a próxima seção existir.

## Onde isto te deixa

Largura de banda é capacidade por segundo, cotada em bits enquanto os seus downloads são contados
em bytes, um teto em vez de uma promessa, compartilhada com a sua casa e com a sua rua, e limitada
pelo enlace mais estreito do caminho em vez de pelo mais largo.

O que ela não é é velocidade. Quanto tempo uma coisa leva para ir e voltar é um número
completamente separado, ninguém te vende isso, e é ele que decide como uma página parece.
