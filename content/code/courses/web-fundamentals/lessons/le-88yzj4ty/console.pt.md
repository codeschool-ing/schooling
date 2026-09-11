---
title: O que a página está dizendo
version: 1
---

O console é duas coisas ao mesmo tempo: um lugar onde o navegador relata problemas, e um lugar onde
você digita uma linha e ela roda contra a página à sua frente.

As duas metades são úteis antes de você escrever qualquer código seu.

## Lendo o que já está ali

Abra em qualquer site e em geral há algo. Aprender a distinguir os quatro tipos é quase todo o valor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro tipos de linha no console: um erro que parou algo, um aviso de que o navegador desaprovou, um log que a própria página imprimiu, e uma falha de rede.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".28\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">um erro</text> <text x=\"290\" y=\"55\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">algo estourou, e o que ele fazia parou</text> <rect x=\"20\" y=\"84\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">um aviso</text> <text x=\"290\" y=\"105\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">desaprovado, e feito assim mesmo — o erro de amanhã</text> <rect x=\"20\" y=\"134\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"130\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">um log</text> <text x=\"290\" y=\"155\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o código da própria página, imprimindo de propósito</text> <rect x=\"20\" y=\"184\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uma falha de rede</text> <text x=\"290\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">bloqueada, recusada ou não tratada — também no painel de rede</text> </svg>", "caption": "Quatro tipos, e distingui-los é quase todo o valor. Uma linha vermelha e um botão que não faz nada costumam ser um fato só."}
```

**Um erro** — algo estourou e ninguém pegou. O que quer que estivesse acontecendo naquele momento
parou de acontecer. Se um botão não faz nada e há uma linha vermelha aqui, esses dois fatos muito
provavelmente são o mesmo fato.

**Um aviso** — algo de que o navegador desaprova e fez assim mesmo. Um recurso obsoleto, um cookie
que vai deixar de ser enviado quando uma política de navegador mudar, uma imagem cujo tipo declarado
não bate com o conteúdo. Estes são os erros de amanhã e vale lê-los uma vez.

**Um log** — algo que o próprio código da página escolheu imprimir. Num site que você não construiu,
isso às vezes revela mais do que alguém pretendia.

**Uma falha de rede** — uma requisição que não chegou, relatada aqui além de no painel de rede. Uma
requisição bloqueada, uma conexão recusada, uma falha que um script não tratou.

## Lendo um erro direito

Um erro tem três partes e as pessoas leem uma.

A **mensagem** diz o que deu errado, nas palavras do navegador. O **arquivo e a linha** dizem onde. E
a **pilha** — em geral recolhida — diz como se chegou ali: qual função chamou qual, da mais recente
para trás.

A pilha é a metade que responde *por que aquele código estava rodando afinal?*, que com frequência é
a pergunta de verdade. Expandi-la uma vez, num erro real, é o momento em que este painel deixa de ser
uma parede vermelha.

Há uma fonte comum de confusão que vale nomear. Um arquivo minificado reporta linha 1, coluna 40000,
que é inútil. A resposta é um **source map**, um arquivo que mapeia o código gerado de volta ao que
foi escrito, e que o navegador carrega automaticamente quando é publicado ao lado do script. Se seus
erros estão ilegíveis, é isso que está faltando.

## Digitando nele

A segunda metade, e é um jeito genuinamente bom de aprender.

Qualquer coisa que você digitar é avaliada contra a página atual. `document.title` imprime o título.
`document.querySelectorAll('img').length` conta as imagens. `document.cookie` mostra os cookies que um
script tem permissão de ver — que, depois da aula sete, você consegue prever que não vão incluir o
importante.

Duas conveniências que vale conhecer. `$0` é o elemento que estiver selecionado no painel de
elementos, então inspecionar algo e digitar `$0` é o jeito mais rápido de pegá-lo. E uma expressão
solta imprime o valor dela, então raramente é preciso envolver algo numa impressão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três linhas digitadas no console e o que cada uma imprime: o título da página, o número de imagens, e os cookies que um script tem permissão de ver.\"> <rect x=\"20\" y=\"34\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"190\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">document.title</text> <rect x=\"380\" y=\"34\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o título desta página</text> <rect x=\"20\" y=\"82\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"190\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$$('img').length</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">quantas imagens ela tem</text> <rect x=\"20\" y=\"130\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"190\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">document.cookie</text> <rect x=\"380\" y=\"130\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e não o com HttpOnly</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">`$0` é o que estiver selecionado no painel de elementos, o que poupa muita digitação</text> </svg>", "caption": "Uma linha por vez, contra a página à sua frente, sem nada salvo. É o lugar mais barato para experimentar."}
```

Aqui também é onde boa parte da experimentação pertence. Um seletor sobre o qual você está em dúvida,
uma continha, uma conferência do que um valor de fato contém — tudo isso é mais rápido aqui do que num
arquivo, e nada é salvo, que é a mesma segurança do painel de elementos.

## O aviso que não é sobre o seu código

Uma coisa para a qual se preparar, porque assusta na primeira vez.

Muitos sites grandes imprimem um aviso no console dizendo para você não colar nada ali. Ele está lá
porque um ataque real funciona assim: alguém é convencido, por telefone ou numa mensagem, a colar uma
linha no console de um site em que está logado, e a linha manda a sessão dessa pessoa para outro
lugar.

Vale levar a sério nas duas direções. Nada neste curso pede que você cole algo que não entende num
console de um site que importa, e se alguém pedir, isso é o ataque.

## Duas outras abas que as pessoas confundem com esta

Vale separar, porque as três imprimem coisas e só uma delas é o console.

O painel de **fontes** guarda os arquivos como o navegador os recebeu, e deixa você parar o código
numa linha escolhida e olhar cada valor naquele momento. É a ferramenta para *por que esta variável
está errada*, enquanto o console é a ferramenta para *deu algo errado afinal*.

O painel de **desempenho** registra em que a página gastou tempo: o layout, a pintura e a execução de
script da aula dez, como um gráfico com durações. É onde mora a resposta quando o painel de rede está
parado e a página ainda engasga.

Nenhum substitui o console, e o console não substitui nenhum. A sequência que funciona é console
primeiro, porque é o mais barato, e depois aquele dos dois para o qual o console apontar.

## O que ele não é

O console relata o que o navegador notou. Ele não relata o que o seu servidor fez, e um console vazio
não é prova de que algo funcionou.

O caso da aula seis que devolve `200` com um erro no corpo produz um console perfeitamente limpo,
porque nada falhou do ponto de vista do navegador. Esse caso se acha no painel de rede, e a próxima
leitura é sobre lê-lo.

*Sem erros* é informação. É a informação de que nada estourou, e nada além disso.
