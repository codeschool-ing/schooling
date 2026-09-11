---
title: Cada requisição, listada
version: 1
---

O painel de rede é uma lista de tudo que a página pediu, com uma linha por requisição e uma coluna
para as coisas com que você passou dez aulas aprendendo a se importar.

Abra, recarregue a página — ele grava só enquanto está aberto, que é a primeira coisa que todo mundo
erra — e as aulas seis e sete inteiras estão na tela.

## As colunas que importam

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do painel de rede para cada requisição, com colunas para o nome, o código de status, o tipo, o tamanho ou a origem no cache, e o tempo total.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"120\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nome</text> <text x=\"320\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">status</text> <text x=\"440\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tipo</text> <text x=\"550\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tamanho</text> <text x=\"650\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tempo</text> <rect x=\"20\" y=\"66\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"120\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">precos</text> <text x=\"320\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200</text> <text x=\"440\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">documento</text> <text x=\"550\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">14 kB</text> <text x=\"650\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">62 ms</text> <rect x=\"20\" y=\"102\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">app.7f3c2a9.css</text> <text x=\"320\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">200</text> <text x=\"440\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">folha de estilo</text> <text x=\"550\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cache de disco</text> <text x=\"650\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0 ms</text> <rect x=\"20\" y=\"138\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">logo.png</text> <text x=\"320\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">304</text> <text x=\"440\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">imagem</text> <text x=\"550\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">310 B</text> <text x=\"650\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">41 ms</text> <rect x=\"20\" y=\"174\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"120\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">widget.js</text> <text x=\"320\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200</text> <text x=\"440\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">script</text> <text x=\"550\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">88 kB</text> <text x=\"650\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">5,4 s</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">ordenar pela última coluna leva cerca de um segundo e acha a linha de baixo</text> </svg>", "caption": "As aulas seis e sete, em tabela. Um 304 e um acerto de cache são duas linhas diferentes, e parecem mesmo."}
```

**Nome** é o arquivo. **Status** são os três dígitos da aula seis. **Tipo** é o que o
`Content-Type` disse que era. **Tamanho** é o que veio pelo fio, e diz *cache de disco* ou *cache de
memória* quando nada veio. **Tempo** é a duração inteira daquela requisição. E a **cascata** é onde
ela ficou em relação a tudo o mais, que é a próxima leitura.

Duas dessas valem ação imediata.

Ordenar por **tamanho** acha a imagem de quatro megabytes que ninguém quis publicar, que é o defeito
de desempenho mais comum do mundo.

Ordenar por **tempo** acha a única requisição lenta numa página em que tudo o mais está bem. Isso é
um problema diferente de uma página uniformemente lenta, e os dois não têm nada em comum além da
queixa.

## Clicando numa linha

É aqui que o painel deixa de ser uma lista e vira o protocolo.

**Cabeçalhos** — a linha de requisição, cada cabeçalho de requisição, cada cabeçalho de resposta. O
`Cache-Control` da aula sete, o `Set-Cookie` com os atributos dele, o `Content-Type`, o `Location` do
redirecionamento. Tudo que aquela aula descreveu como texto está aqui, como texto.

**Resposta** — o corpo, exatamente como chegou, que é como você acha um `200` com um erro dentro.

**Tempo** — o detalhamento de que trata a próxima leitura.

**Cookies** — o que foi enviado e o que voltou, por requisição, que é mais rápido do que ler os
cabeçalhos para a única pergunta que isso responde.

## Quatro controles que mudam o que você vê

**Desativar o cache**, que faz cada carregamento se comportar como uma primeira visita. Essencial
enquanto se trabalha numa folha de estilo e desonesto enquanto se mede, porque um site medido assim é
um site que ninguém experimenta.

**Limitação de velocidade**, que finge ser uma conexão mais lenta. É a coisa mais próxima da
disciplina que a aula três pediu: sua máquina está numa conexão rápida na mesma cidade do servidor, e
quase mais ninguém está.

**Filtro**, por tipo ou por texto. *Mostre só as requisições a outro host* é um clique e responde
*quanto desta página é de outra pessoa?*

**Preservar o log**, que mantém as linhas através de uma navegação. Sem isso, um redirecionamento ou
um envio de formulário apaga a evidência no momento em que ela fica interessante. Ligue antes de
reproduzir qualquer coisa que navegue.

## Três coisas que ele torna visíveis e que eram abstratas até agora

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três coisas que o painel torna concretas: uma corrente de redirecionamentos como uma linha por salto, um acerto de cache como uma linha com tamanho e tempo quase zero, e o número de hosts distintos que uma página contata.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"200\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">uma corrente de redirecionamentos</text> <text x=\"470\" y=\"55\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">uma linha por salto, com o 3xx dela</text> <rect x=\"20\" y=\"84\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"200\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um acerto de cache, e um 304</text> <text x=\"470\" y=\"105\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">duas linhas diferentes, e parecem mesmo</text> <rect x=\"20\" y=\"134\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"200\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">onze hosts que você não escolheu</text> <text x=\"470\" y=\"155\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">ordene por domínio e conte</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">abra o painel primeiro, depois recarregue — ele grava só enquanto está aberto</text> </svg>", "caption": "Três abstrações de aulas anteriores, cada uma das quais acaba sendo uma linha que dá para contar."}
```

**Uma corrente de redirecionamentos.** Cada salto é uma linha própria, com o `3xx` e o `Location`
dele. A corrente da aula seis que custa três idas e voltas são três linhas que dá para contar.

**Um acerto de cache.** A coluna de tamanho diz que a cópia veio do disco ou da memória, e o tempo é
quase zero. O `304` da aula sete é uma linha com status 304 e tamanho minúsculo — e a diferença entre
os dois, que a leitura descreveu em palavras, é visível como duas linhas diferentes.

**Algo que você não pediu.** Ordene por domínio e ache os onze hosts que uma página contata. Na
maioria dos sites comerciais este é o momento em que a seção sobre terceiros da aula dez deixa de ser
abstração.

## Copiando uma requisição para fora do painel

Um recurso pequeno que merece uma seção porque muda como você conversa com outras pessoas sobre um
problema.

Clicar com o botão direito numa linha oferece *copiar como curl*, que produz uma linha de comando
reproduzindo aquela requisição exata — cada cabeçalho, cada cookie, o corpo se havia um. Cole num
terminal e a requisição acontece de novo, fora do navegador, sem nada da página envolvido.

É o jeito mais rápido de responder *é o navegador ou o servidor?* Também dá a você algo que pode
entregar a um colega, ou pôr num relatório de defeito, que reproduz o problema sem uma descrição de
onde clicar.

A única ressalva é a razão de funcionar: o comando copiado carrega o seu cookie de sessão e qualquer
cabeçalho de autenticação. É uma credencial em funcionamento, em texto puro, e não pertence a uma
mensagem num grupo, a um chamado que outras pessoas leem, nem a nada que sobreviva à sessão.

## A única coisa a conferir antes de acreditar em qualquer disto

O painel grava a partir do momento em que abre. Uma página carregada antes de você abri-lo não mostra
nada, ou mostra só o que aconteceu depois.

Abra primeiro, depois recarregue. É o menor hábito possível e é a diferença entre este painel ser
útil e ser misterioso.
