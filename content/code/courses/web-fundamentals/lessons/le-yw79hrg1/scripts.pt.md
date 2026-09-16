---
title: Onde um script para tudo
version: 1
---

Uma folha de estilo bloqueia a renderização. Um script faz algo mais forte: ele bloqueia o **parser**,
o que quer dizer que a árvore para de ser construída enquanto o script é buscado e executado.

Saber exatamente onde, e o que três palavrinhas mudam nisso, é quase tudo que há para saber sobre
fazer uma página aparecer antes.

## Por que ele bloqueia

A razão é histórica e ainda real. Um script pode escrever no documento no ponto em que está — o antigo
`document.write` — e pode ler e mudar tudo acima dele. O parser não consegue seguir além de um script
com segurança sem saber o que o script fez, então ele para.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo em que a leitura para num script comum, espera ele ser buscado e executado, e recomeça depois. A tela não mostra nada durante todo o bloqueio.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">uma tag de script comum, doze linhas dentro do head</text> <rect x=\"20\" y=\"38\" width=\"150\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"95\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lendo a marcação</text> <rect x=\"176\" y=\"38\" width=\"230\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".26\" stroke=\"var(--amber)\"></rect> <text x=\"291\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">buscando o script</text> <rect x=\"412\" y=\"38\" width=\"120\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".34\" stroke=\"var(--amber)\"></rect> <text x=\"472\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">executando</text> <rect x=\"538\" y=\"38\" width=\"162\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"619\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lendo, enfim</text> <rect x=\"176\" y=\"88\" width=\"356\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"354\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">nenhuma árvore é construída, então nada é desenhado</text> <text x=\"360\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">o parser para porque o script pode mudar o que está acima dele</text> <text x=\"360\" y=\"194\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">outros arquivos seguem sendo buscados pelo scanner de pré-carga — a árvore é que espera</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">duas palavras na tag removem esta barra por completo</text> </svg>", "caption": "O bloqueio não é sobre banda. É a árvore não estar sendo construída, e a árvore é o que é desenhado."}
```

Um `<script src="...">` comum no head custa, portanto: uma requisição, um download, uma execução, e só
então a leitura continua. Numa conexão lenta, isso é uma tela em branco durante todo esse tempo.

O scanner de pré-carga da leitura sobre o parser suaviza isso — outros recursos são buscados durante o
bloqueio — mas a árvore não é construída, então nada é acrescentado à página e nada é desenhado.

## Os dois atributos

Os dois vão na tag e os dois mudam o quadro por completo.

`defer` — busque agora, junto com a leitura, e execute **depois** de o documento ter sido lido. Scripts
marcados assim rodam na ordem em que aparecem. É isto que você quer para quase tudo: a página é
construída a toda velocidade e o código roda numa árvore completa.

`async` — busque agora e execute **no instante em que chegar**, interrompendo a leitura onde quer que
ela esteja. A ordem não é preservada; o que baixar primeiro roda primeiro. Serve a um script sem
relação com a página nem com outro script, o que na prática quer dizer analytics e pouco mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Três arranjos de script comparados: um script comum para a leitura; defer busca em paralelo e roda depois de o documento ser lido, em ordem; async busca em paralelo e roda assim que chega, sem ordem definida.\"> <rect x=\"20\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"128\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&lt;script src&gt;</text> <text x=\"128\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a leitura para</text> <text x=\"128\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">busca, depois executa</text> <text x=\"128\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tela em branco, durante a espera</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">defer</text> <text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">buscado em paralelo</text> <text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">roda depois da leitura, em ordem</text> <text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o que você quer, quase sempre</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"592\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">async</text> <text x=\"592\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">buscado em paralelo</text> <text x=\"592\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">roda ao chegar, em qualquer ordem</text> <text x=\"592\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">para algo sem relação com a página</text> <text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">no head, com defer — descoberto cedo, e executado na hora certa</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">os dois atributos são ignorados num script escrito na página, que já chegou</text> </svg>", "caption": "Três arranjos, e o conselho de pôr scripts no fim do body é anterior ao do meio."}
```

O terceiro caso é um **módulo**, que se comporta como `defer` por padrão.

Uma coisa que surpreende: os dois atributos são ignorados num script embutido. Eles descrevem quando
executar algo que precisa ser buscado, e um script escrito na página já chegou.

## Onde pôr, num parágrafo

O conselho que circulou por anos era pôr scripts no fim do body, e estava certo antes de o `defer`
existir. Ele consegue a mesma coisa — a leitura termina antes de o script rodar — ao custo de o
navegador descobrir o script tarde.

Hoje: **uma tag de script no head, com `defer`.** Ela é descoberta cedo, buscada cedo, e roda no mesmo
momento em que teria rodado do fim do body. Nada nisso é questão de gosto.

## Dois eventos, e por que as pessoas esperam o errado

Scripts costumam esperar um sinal antes de tocar na página, e há dois.

`DOMContentLoaded` dispara quando o documento foi lido e os scripts com `defer` rodaram. Folhas de
estilo podem seguir pendentes e imagens quase certamente seguem. Este é o que você quer, e é o que as
ferramentas do navegador marcam como uma linha à parte.

`load` dispara quando **tudo** terminou — cada imagem, cada fonte, cada quadro. Numa página com uma
imagem grande lá embaixo, isso pode ser vários segundos depois, e um script que espera por ele não faz
nada enquanto o visitante já está lendo.

A regra: *a árvore está pronta* é um momento diferente de *tudo baixou*, e quase todo código quer o
primeiro.

## Scripts de terceiros, que são decisões de outra pessoa na sua página

Merece uma seção própria, porque a maior parte do script de uma página típica não foi escrita por
ninguém da empresa dona do site.

Uma tag de analytics, um widget de chat, um banner de consentimento, um script de anúncio, um carregador
de fontes. Cada um é uma linha na sua marcação e uma quantidade desconhecida de código, buscada de um
host que você não controla, rodando com exatamente a mesma autoridade que o seu próprio código.

Três consequências seguem daí, e as três já aconteceram publicamente.

**A disponibilidade deles é sua.** Um script de terceiro bloqueante num host que está lento hoje deixa
sua página lenta hoje. O `async` limita isso; o arranjo mais seguro é não bloquear nele.

**O tamanho deles é seu**, e muda sem aviso. Uma tag que tinha quarenta kilobytes em março tem duzentos
em setembro, e nada no seu repositório mudou.

**O comportamento deles é seu.** Um script lê a página, lê os campos do formulário, e manda o que
quiser. Quando um script de terceiro é comprometido, cada site que o carrega é comprometido de uma vez,
e isso não é hipotético.

As medidas que valem conhecer: carregue-os com `async` ou depois, mantenha uma lista de quem está na
página e por quê, e periodicamente remova aqueles cuja finalidade ninguém consegue nomear — que, em
qualquer site com mais de um ano, costumam ser vários.

## O que um script custa depois de chegar

Mais uma coisa, porque é a parte em que páginas modernas mais gastam.

Um script baixado tem que ser lido e compilado antes de rodar, e então ele roda. Num celular modesto,
um megabyte de script não é um problema de download — é um segundo ou mais de processamento durante o
qual a página não responde a nada, porque esse trabalho acontece na mesma linha de execução que cuida
da página.

É essa a razão de um site pontuar bem em toda medição de rede e parecer inutilizável. Os bytes chegaram
rápido; o celular ainda está ocupado com eles.

O instinto que vale construir: pergunte quanto um script **custa para rodar**, e não apenas quanto
custa para buscar. A próxima aula mostra onde está esse número.
