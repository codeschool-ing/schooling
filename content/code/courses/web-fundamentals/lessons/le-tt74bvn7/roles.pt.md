---
title: Os dois papéis
version: 1
---

Quase tudo o que acontece na internet é uma conversa entre duas partes, e as duas partes têm
funções fixas. O **cliente** pede. O **servidor** responde.

Isso não é uma simplificação que você vai superar depois. É o formato de verdade, e ele vale da
menor troca à maior — do celular conferindo se uma mensagem foi entregue ao banco liquidando um
pagamento.

## Os papéis pertencem ao momento, não à máquina

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Três máquinas em fila: navegador, servidor web, banco de dados. Quatro setas numeradas em ordem de tempo — o navegador pede ao servidor, o servidor pede ao banco, o banco responde, o servidor responde. A máquina do meio é o servidor na primeira troca e o cliente na segunda.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <rect x=\"14\" y=\"96\" width=\"162\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Navegador</text><text x=\"95.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sempre um cliente</text>\n  <rect x=\"279\" y=\"96\" width=\"162\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Servidor web</text><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">os dois, aqui</text>\n  <rect x=\"544\" y=\"96\" width=\"162\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Banco de dados</text><text x=\"625.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sempre um servidor</text>\n\n  <path d=\"M176 116 L273 116\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"224\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 · pede</text>\n  <path d=\"M441 116 L538 116\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"489\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2 · pede</text>\n\n  <path d=\"M538 140 L444 140\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"491\" y=\"158\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 · responde</text>\n  <path d=\"M273 140 L179 140\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"226\" y=\"158\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4 · responde</text>\n\n  <rect x=\"196\" y=\"196\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".13\" stroke=\"var(--phosphor-dim)\"></rect>\n  <text x=\"271\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor-dim)\">SERVIDOR nas trocas 1+4</text>\n  <rect x=\"374\" y=\"196\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\"></rect>\n  <text x=\"449\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">CLIENTE nas trocas 2+3</text>\n  <path d=\"M300 196 L330 164\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path>\n  <path d=\"M420 196 L390 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path>\n  <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">uma máquina · um segundo · dois papéis</text>\n</svg>", "caption": "Uma máquina, um segundo, os dois papéis. Os números são a ordem do tempo: a troca 4 não acontece enquanto a 3 não voltar."}
```

Esta é a frase que vale ler duas vezes, porque quase toda confusão posterior nasce de entendê-la
errado.

"Servidor" não é um tipo de computador. Não é um rack preto numa sala fria, e não é uma coisa que
se compra. **É o papel que uma máquina desempenha em uma troca específica**, e a mesma máquina
desempenha outro papel na troca seguinte.

Pense num servidor web montando uma página. Para montá-la ele precisa de dados que não tem, então
pede esses dados a um banco de dados:

- para o seu navegador, ele é o **servidor** — você pediu, ele respondeu;
- para o banco de dados, ele é o **cliente** — ele pediu, o banco respondeu.

Mesma máquina. Mesmo segundo. Dois papéis, porque são duas trocas.

O notebook em que você está lendo isto é um cliente agora. Ele também está, neste momento, muito
provavelmente rodando um servidor: se você já abriu `localhost:3000` enquanto construía alguma
coisa, aquilo era a sua própria máquina respondendo à própria pergunta. Um computador, os dois
papéis, nenhuma contradição.

## Observe uma página carregar

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A linha do tempo de uma página carregando. Uma barra longa no início é o documento HTML; catorze barras mais curtas começam depois dela e se sobrepõem; uma barra isolada, mais tarde, é a contagem de notificações. Duas barras tracejadas no pé são trocas que você nunca vê, entre o servidor e seu banco de dados.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <line x1=\"118\" y1=\"30\" x2=\"118\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <line x1=\"700\" y1=\"30\" x2=\"700\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <text x=\"118\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 ms</text>\n  <text x=\"700\" y=\"22\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~1200 ms</text>\n\n  <rect x=\"118\" y=\"34\" width=\"150\" height=\"13\" rx=\"2\" fill=\"var(--phosphor)\"></rect>\n  <text x=\"112\" y=\"44\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o documento</text>\n\n  <text x=\"112\" y=\"76\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">o que ele pediu</text>\n  <rect x=\"272\" y=\"52\" width=\"112\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"272\" y=\"64\" width=\"186\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"276\" y=\"76\" width=\"141\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"281\" y=\"88\" width=\"98\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"285\" y=\"100\" width=\"223\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"290\" y=\"112\" width=\"76\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"294\" y=\"124\" width=\"167\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"299\" y=\"136\" width=\"89\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n\n  <rect x=\"470\" y=\"152\" width=\"118\" height=\"11\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect>\n  <text x=\"596\" y=\"161\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor-dim)\">script pede, depois</text>\n\n  <line x1=\"118\" y1=\"180\" x2=\"700\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line>\n  <rect x=\"150\" y=\"188\" width=\"64\" height=\"9\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 2\"></rect>\n  <rect x=\"150\" y=\"200\" width=\"47\" height=\"9\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 2\"></rect>\n  <text x=\"112\" y=\"203\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">você nunca vê</text>\n  <text x=\"228\" y=\"197\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">servidor → banco, servidor → anúncios</text>\n  <text x=\"118\" y=\"236\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Seu navegador não é um cliente. Ele é cliente quinze vezes, quase todas ao mesmo tempo.</text>\n</svg>", "caption": "O que parece carregar uma página são quinze trocas ou mais, quase todas sobrepostas — além de duas do outro lado, que nunca tocam o seu computador."}
```

Abstrações ficam mais fáceis de aceitar depois que você conta alguma coisa. Abra qualquer site de
notícias e uma versão aproximada disto acontece:

1. Seu navegador pede a página naquele endereço. Uma troca. Ele recebe de volta um documento —
   algumas dezenas de kilobytes de HTML, e **nenhuma imagem, nenhum estilo, nenhum código**.
2. Lendo esse documento, o navegador descobre que precisa de uma folha de estilo, quatro scripts,
   uma fonte e nove imagens. Ele pede cada uma delas. **Mais catorze trocas**, quase todas
   começadas antes de a primeira terminar de ser lida.
3. Um desses scripts, já rodando, pede a sua contagem de notificações. **Mais uma troca**, esta
   para uma máquina completamente diferente.
4. Enquanto isso, o servidor que respondeu ao passo 1 pediu as manchetes a um banco de dados e
   pediu o anúncio a um segundo serviço. **Mais duas trocas que você nunca vê**, porque
   aconteceram do outro lado.

O que pareceu "carregar uma página" foram entre quinze e cem trocas separadas, cada uma com quem
pede e quem responde, cada uma completa em si mesma.

Duas coisas decorrem daí, e as duas importam mais do que parecem:

**Seu navegador não é um cliente, ele é cliente muitas vezes.** Ele mantém uma dúzia de trocas
abertas ao mesmo tempo e monta a página com as respostas conforme elas chegam, na ordem em que
chegarem.

**A maior parte das trocas é invisível para você.** As que acontecem entre o servidor e as
máquinas atrás dele nunca tocam o seu computador. Quando algo está lento, a causa está muito
frequentemente numa conversa que você não consegue ver — que é exatamente por que o vocabulário
desta aula vale a pena.

## Do que cada lado é responsável

A assimetria entre os dois papéis não é sobre poder ou tamanho. É sobre quem começa e quem espera.

| | cliente | servidor |
|---|---|---|
| começa a troca | **sim** | não |
| espera, sem fazer nada, até que falem com ele | não | **sim** |
| decide *o que* pedir | **sim** | não |
| decide *se e como* responder | não | **sim** |
| precisa estar acessível num endereço conhecido | normalmente não | **sempre** |
| pode recusar a outra parte | não de forma significativa | **sim, e recusa** |

Duas linhas merecem mais do que uma célula.

### "Precisa estar acessível num endereço conhecido"

**Um servidor precisa ser encontrável.** Ele fica num endereço que as outras máquinas já conhecem,
ou conseguem consultar, e espera ali. Um cliente não precisa de um endereço fixo do mesmo jeito —
ele sai, pede, e volta com uma resposta.

É por isso que "o servidor caiu" é uma frase que as pessoas dizem e "o cliente caiu" não é. Se um
cliente para, uma pessoa fica sem atendimento. Se um servidor para, todo mundo que ia lhe
perguntar alguma coisa não encontra ninguém em casa.

É também por isso que rodar um servidor no notebook de casa é mais difícil do que parece. O
endereço do seu notebook muda, ele fica atrás de equipamentos que não encaminham requisições de
fora por padrão, e ele dorme. Nada disso importa para um cliente. Tudo isso é fatal para um
servidor. A aula 4 explica a parte do endereçamento e a aula 9 explica o que as pessoas alugam
para não ter esse problema.

### "Pode recusar"

O servidor decide se responde, e recusar é uma coisa normal e saudável para ele fazer — não um
defeito. Ele pode recusar porque você não tem permissão, porque você pediu algo que não existe,
porque você está pedindo com frequência demais, ou porque está se protegendo de um trabalho que
não conseguiria terminar.

O poder do cliente é o oposto: ele decide *se pede alguma coisa*, e pode ir embora antes de a
resposta chegar. Nada obriga um cliente a esperar, e é por isso que "cancelar" funciona.

## A palavra "servidor" em circulação

Você vai encontrar a palavra usada de três jeitos diferentes, e a ambiguidade é real, não uma
falha sua de compreensão:

1. **O papel** — "naquele instante ele é o servidor". Este é o sentido de que esta aula trata.
2. **O programa** — "rodamos um servidor Nginx naquela máquina". Um software cuja função inteira é
   esperar requisições e respondê-las.
3. **O equipamento** — "compramos dois servidores". Uma máquina física comprada para rodar
   programas do segundo tipo.

Quando alguém diz "servidor" e você não consegue saber a qual dos três se refere, a pergunta útil
é: *isto é uma coisa que poderia estar desempenhando outro papel na próxima troca?* Se sim, é o
papel. Se está parafusado num rack, é o metal.

## Três confusões que vale desfazer agora

**"Cliente" não quer dizer "navegador".** Um navegador é um tipo de cliente. Também são um
aplicativo de celular, uma ferramenta de linha de comando como o `curl`, um script que roda às
três da manhã, uma televisão e uma maquininha de cartão numa loja. Se pede, é um cliente. Isso
importa porque boa parte do tráfego da internet é máquina falando com máquina, sem ninguém
olhando.

**"Cliente e servidor" não é o mesmo eixo que "frontend e backend".** Frontend e backend descrevem
*onde o código roda e quem o escreveu* — a interface que uma pessoa toca, contra o sistema por
trás dela. Cliente e servidor descrevem *o papel de alguém em uma troca*. Eles coincidem com
frequência suficiente para confundir e não são a mesma distinção: o backend é servidor para o
navegador e cliente para o banco de dados, continuando a ser, em toda frase, o backend.

**Um servidor não é necessariamente uma máquina grande.** É o que quer que esteja esperando para
responder. Um computador de vinte euros do tamanho de um cartão de crédito, numa prateleira,
servindo as suas fotografias, é um servidor no sentido pleno de cada um dos três significados
acima. Tamanho é consequência de quantas pessoas pedem, não do papel em si.

## O que levar para o resto do curso

Todo o resto de `web-fundamentals` é resposta a alguma parte de uma pergunta só: **como os dois
lados se encontram, e como entendem o que foi dito?**

- As aulas 2 a 5 são sobre *encontrar* — pacotes, endereços e as camadas que os carregam.
- A aula 6 é sobre *entender* — a língua que os dois lados falam.
- As aulas 8 e 9 são sobre *ser encontrável* — nomes, e onde um servidor mora.
- As aulas 10 e 11 são sobre o que o cliente faz com a resposta depois de tê-la.

Guarde o formato e o resto se pendura nele.
