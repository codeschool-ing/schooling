---
title: O tempo de ir e voltar
version: 1
---

**Latência é quanto tempo uma coisa leva para ir e voltar.** É medida em milissegundos, ninguém te
vende isso, e para a maior parte do que você faz num computador ela importa mais que a largura de
banda.

O número normalmente citado é a **ida e volta** — ir e voltar — porque é o que se consegue medir de
uma ponta só, e porque quase tudo que você faz espera por uma resposta.

## Quatro coisas somam para formá-la

Latência não é um atraso. São quatro, e eles se comportam de maneiras completamente diferentes.

| o quê | de onde vem | dá para reduzir |
|---|---|---|
| propagação | a distância, à velocidade da luz no vidro | só chegando mais perto |
| transmissão | colocar os bits no fio, à capacidade daquele enlace | sim — mais largura de banda |
| processamento | cada roteador lendo o cabeçalho e decidindo | um pouco, e já é pequeno |
| enfileiramento | esperar atrás de outro tráfego em cada salto | sim, e é a próxima seção inteira |

O segundo é o único lugar onde a largura de banda aparece, e para uma requisição pequena ele é
mínimo. O primeiro é o interessante, porque é um piso do qual ninguém passa por baixo.

## O piso que ninguém abaixa

A luz na fibra viaja a cerca de **200.000 quilômetros por segundo** — mais devagar que no vácuo,
por causa do vidro. Divida qualquer distância por isso e você tem um atraso que nenhum equipamento,
nenhum dinheiro e nenhum plano remove.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Três rotas com as suas idas e voltas mínimas: dentro de uma cidade cerca de dois milissegundos, São Paulo a Miami cerca de oitenta, São Paulo a Tóquio cerca de cento e noventa. Uma nota diz que estes são pisos impostos pela distância e não podem ser comprados.\"><text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o mínimo que uma ida e volta pode levar</text><text x=\"30\" y=\"66\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">dentro de uma cidade</text><rect x=\"188\" y=\"52\" width=\"20\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"224\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">~2 ms</text><text x=\"30\" y=\"116\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">São Paulo a Miami</text><rect x=\"188\" y=\"102\" width=\"150\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"354\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">~80 ms</text><text x=\"30\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">São Paulo a Tóquio</text><rect x=\"188\" y=\"152\" width=\"356\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><text x=\"560\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">~190 ms</text><text x=\"360\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nenhum plano, nenhum equipamento e nenhum dinheiro move nenhum destes</text></svg>", "caption": "A distância é o único componente da latência que é física, e não engenharia. Todo o resto é negociável."}
```

Os números reais são maiores que estes, porque cabos não correm em linha reta e cada salto
acrescenta os próprios atrasinhos. Mas o piso é o piso, e é por isso que um serviço com usuários em
dois continentes não consegue ser rápido para os dois a partir de um prédio só.

É também o argumento de uma tecnologia inteira que você vai encontrar na aula 9: se a distância não
pode ser reduzida, a única jogada que sobra é **colocar uma cópia do conteúdo mais perto**. Um CDN é
essa ideia e nada mais.

## Por que ela ganha da largura de banda em quase tudo

Aqui está a conta que torna esta aula digna de existir.

Uma página não chega como um bloco só. O seu navegador pede o HTML, lê, descobre que precisa de uma
folha de estilo e de alguns scripts e imagens, pede por eles, descobre mais, e pede de novo. Cada
uma dessas descobertas é uma **ida e volta** — e algumas delas não podem começar antes da anterior
ter terminado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Uma linha do tempo de um carregamento de página com ida e volta de duzentos milissegundos. Quatro esperas sequenciais são desenhadas: busca do nome, conexão, criptografia e a primeira requisição, e só um bloco final curto é a transferência de dados em si.\"><text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">uma página, com ida e volta de 200 ms</text><rect x=\"20\" y=\"44\" width=\"150\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".3\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"95\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">achar o nome</text><rect x=\"176\" y=\"44\" width=\"150\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".3\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"251\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">abrir a conexão</text><rect x=\"332\" y=\"44\" width=\"150\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".3\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"407\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">combinar a criptografia</text><rect x=\"488\" y=\"44\" width=\"150\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".3\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"563\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedir a página</text><rect x=\"644\" y=\"44\" width=\"54\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".4\" stroke=\"var(--phosphor)\"></rect><text x=\"671\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">dados</text><text x=\"330\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor-dim)\">quatro idas e voltas — 800 ms de espera</text><text x=\"671\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a transferência</text><rect x=\"20\" y=\"130\" width=\"678\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".08\" stroke=\"var(--amber)\"></rect><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">dobre a largura de banda e só o último bloco encolhe</text><text x=\"360\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">corte a ida e volta pela metade e todos os blocos encolhem</text><text x=\"360\" y=\"210\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">é por isso que um plano mais rápido tantas vezes não muda nada na sensação de um site</text></svg>", "caption": "A maior parte do carregamento de uma página pequena é espera, não transferência. A largura de banda só encurta a parte que já é curta."}
```

Quatro idas e voltas a 200 ms cada são 800 milissegundos antes de um byte da própria página chegar.
Agora dobre a largura de banda: aqueles 800 milissegundos ficam **completamente inalterados**,
porque nenhum deles era sobre capacidade. Só o último blocozinho fica mais curto.

Essa é a frase para guardar: **largura de banda encurta a transferência, latência alonga todo o
resto.**

## O que os números parecem

A latência é uma das poucas grandezas técnicas que dá para sentir diretamente, e saber mais ou
menos onde ficam os limiares torna uma reclamação muito mais fácil de interpretar.

| ida e volta | como parece |
|---|---|
| abaixo de 20 ms | instantâneo — uma máquina remota parece local, digitar num terminal remoto é confortável |
| 20 – 60 ms | bom — uma chamada de vídeo é natural, um jogo competitivo é jogável |
| 60 – 150 ms | perceptível — a conversa começa a se atropelar, páginas parecem arrastadas |
| 150 – 300 ms | claramente errado — as pessoas começam a dizer "a internet está lenta" sem saber por quê |
| acima de 300 ms | quebrado — trabalho interativo fica desagradável, seja qual for a banda |

Repare que a última linha pode acontecer numa conexão com capacidade enorme. Quem está num link de
satélite rápido tem mais banda do que precisa e uma conversa que vive colidindo, e todo diagnóstico
que comece medindo velocidade vai passar reto por isso.

É também por que trabalhar remotamente a uma grande distância é uma experiência diferente de
trabalhar remotamente dentro da mesma cidade, de um jeito que ninguém te avisa: os arquivos baixam
rápido nos dois casos, e é na chamada de vídeo que a distância aparece.

## O que piora, e raramente é a distância

Duas coisas inflam a latência muito além da física, e vale reconhecer as duas.

**O caminho não é o mapa.** Tráfego entre duas cidades do mesmo país às vezes viaja por outro
continente, porque é lá que os dois provedores trocam tráfego. A linha reta nunca esteve
disponível.

**O último trecho costuma ser o pior.** Wi-Fi atravessando um apartamento, uma conexão móvel
negociando com uma antena, um cabo velho — isso pode acrescentar dezenas de milissegundos antes de
o seu tráfego ter saído do prédio. Ligar o computador com um cabo é a melhoria de latência mais
confiável que a maioria das pessoas pode fazer, e é de graça.

E o satélite merece uma linha própria. Um satélite tradicional fica a 36.000 km de altura, então a
ida e volta é de no mínimo **480 ms antes de qualquer outra coisa** — que é por que essas conexões
parecem estranhas por mais banda que carreguem. As constelações novas voam muito mais baixo e
derrubam isso para dezenas de milissegundos, que é a razão inteira de terem valido a pena.

## Onde isto te deixa

Latência é o tempo de ir e voltar, é feita de distância, transmissão, processamento e
enfileiramento, e só a distância é física. Ela decide como uma página parece, porque a maior parte
do carregamento de uma página pequena é espera e não transferência — então a largura de banda
encurta a parte curta e a latência alonga todas as partes.

Três dos quatro componentes estão cobertos. O quarto, o **enfileiramento**, é o que mais se mexe,
muda minuto a minuto, e explica a reclamação que você mais ouve dentro de casa — e está a duas
seções daqui.
