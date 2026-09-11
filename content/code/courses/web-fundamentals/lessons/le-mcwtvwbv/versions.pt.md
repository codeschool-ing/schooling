---
title: Três versões, um significado
version: 1
---

Há três versões de HTTP em uso diário, e a coisa mais importante sobre elas é o que **não** mudou.
Os métodos são os mesmos, os códigos são os mesmos, os cabeçalhos são os mesmos. Um `GET` que
devolve `404 Not Found` quer dizer o que queria dizer em 1999.

O que mudou é como essas coisas são escritas e quantas delas podem estar em voo ao mesmo tempo.
Tudo desta aula até aqui sobrevive intacto às três versões.

## 1.1, e a fila

O HTTP/1.0 abria uma conexão, mandava uma requisição, lia uma resposta e fechava. Cada imagem de uma
página pagava uma conexão nova, e — depois da aula passada — você sabe quanto custa uma conexão.

O HTTP/1.1 consertou a parte óbvia: mantenha a conexão aberta e mande a próxima requisição pela
mesma. Ele também passou a exigir o `Host`, que transformou uma máquina em muitos sites, e
acrescentou a codificação em pedaços que deixa um servidor começar a enviar antes de saber o
tamanho.

O que ele não consertou foi a fila. Numa conexão, requisições são respondidas em ordem, então uma
lenta segura tudo atrás dela mesmo que essas já estejam prontas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Numa conexão HTTP 1.1 quatro requisições são respondidas uma depois da outra, e uma segunda lenta atrasa as duas atrás dela. No HTTP 2 as mesmas quatro dividem uma conexão ao mesmo tempo e a lenta atrasa só a si mesma.\"> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">HTTP/1.1 — uma conexão, um de cada vez</text> <rect x=\"20\" y=\"34\" width=\"90\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"65\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">página</text> <rect x=\"112\" y=\"34\" width=\"300\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"262\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">uma lenta</text> <rect x=\"414\" y=\"34\" width=\"90\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"459\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">estilo</text> <rect x=\"506\" y=\"34\" width=\"90\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"551\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">logo</text> <text x=\"20\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">as duas últimas ficaram prontas cedo e esperaram assim mesmo</text> <text x=\"20\" y=\"134\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">HTTP/2 — uma conexão, tudo de uma vez</text> <rect x=\"20\" y=\"144\" width=\"90\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"65\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">página</text> <rect x=\"20\" y=\"174\" width=\"300\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"170\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">uma lenta, sem atrasar ninguém</text> <rect x=\"20\" y=\"204\" width=\"90\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"65\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">estilo</text> <rect x=\"122\" y=\"204\" width=\"90\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"167\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">logo</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">mesmas requisições, mesmas respostas, mesmo significado — só o arranjo no tempo muda</text> </svg>", "caption": "Nada nas requisições mudou entre estas duas imagens. O que mudou é se elas precisam fazer fila."}
```

Os navegadores contornaram isso abrindo seis conexões para cada host, o que são seis apertos de mão
e seis de tudo. E os desenvolvedores contornaram também, de jeitos que moldaram como sites foram
construídos por uma década: dezenas de imagenzinhas combinadas numa imagem grande para ser recortada
com folhas de estilo, todo script concatenado num arquivo só, arquivos espalhados por `static1`,
`static2`, `static3` para o limite de seis conexões valer três vezes.

Tudo isso era trabalho feito para derrotar uma limitação do protocolo, e tudo isso deixou os sites
mais difíceis de mudar.

## 2, e uma conexão com muitas faixas

O HTTP/2 manteve todos os significados e trocou a codificação. O texto virou um formato binário — não
mais algo que dá para ler do fio a olho nu, o que é uma perda real — e esse formato leva quadros
numerados, então muitas trocas podem dividir uma conexão ao mesmo tempo.

Requisições deixaram de esperar umas pelas outras. Cem arquivinhos chegam por uma conexão, em
qualquer ordem, e o lento atrasa só a si mesmo.

Cabeçalhos também são comprimidos, e com uma tabela do que já foi enviado: os vinte cabeçalhos que
um navegador repete em cada requisição param de ser enviados vinte vezes.

Duas consequências para carregar. Cada contorno da seção anterior virou contraproducente — um arquivo
concatenado enorme hoje é pior que os pequenos que ele substituiu, e espalhar arquivos por três
hostnames custa três conexões à toa. E uma página montada a partir de muitos hosts perde quase todo
o benefício, porque a multiplexação é por conexão e cada host é uma diferente.

A versão também trouxe um recurso para empurrar arquivos que o cliente não pediu. Os navegadores o
removeram. Acabou que ele mandava coisas que o navegador já tinha, na maior parte das vezes, e a
banda desperdiçada superava a latência economizada — um bom lembrete de que uma otimização plausível
é uma hipótese até alguém medir.

## 3, e a camada de baixo

O HTTP/2 tirou a fila da própria camada, e descobriu uma embaixo dela.

O TCP entrega bytes em ordem. Se um pacote se perde, tudo atrás espera — inclusive bytes pertencentes
a trocas completamente diferentes que chegaram perfeitamente. Os fluxos são independentes para o
HTTP e não são independentes para a camada que os carrega, que é o custo de camadas da aula cinco
aparecendo no lugar onde você menos esperaria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um pacote se perde. No HTTP 2 sobre TCP todos os fluxos esperam por ele porque o transporte entrega em ordem. No HTTP 3 só o fluxo ao qual o pacote pertencia espera, e os outros seguem.\"> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">HTTP/2 sobre TCP — um pacote do fluxo A se perde</text> <rect x=\"20\" y=\"34\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fluxo A — esperando o pedaço que falta</text> <rect x=\"20\" y=\"66\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fluxo B — chegou, e espera assim mesmo</text> <rect x=\"20\" y=\"98\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fluxo C — chegou, e espera assim mesmo</text> <text x=\"480\" y=\"82\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">o TCP entrega em ordem</text> <text x=\"20\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">HTTP/3 — o mesmo pacote se perde</text> <rect x=\"20\" y=\"162\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fluxo A — esperando o pedaço que falta</text> <rect x=\"20\" y=\"194\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"240\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fluxo B — entregue</text> <text x=\"480\" y=\"196\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">cada fluxo ordenado</text> <text x=\"480\" y=\"214\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">por si só</text> </svg>", "caption": "O HTTP/2 tirou a fila da própria camada e descobriu a de baixo. É atrás dela que o HTTP/3 foi."}
```

Consertar isso quer dizer mudar o transporte, e mudar o transporte quer dizer as caixas do meio. O
HTTP/3 é construído sobre um protocolo novo carregado por UDP, no qual cada fluxo tem a própria
ordenação, então um pacote perdido segura só a troca à qual ele pertencia. Ele também dobra o acordo
de criptografia para dentro da abertura da conexão, então uma conexão segura custa uma ida e volta
em vez de duas, e identifica uma conexão por algo que não sejam os quatro números de endereço e
porta — o que quer dizer que sair do Wi-Fi para a rede móvel não a derruba.

E ele teve que ser carregado por UDP por um motivo que você já conhece. Um protocolo genuinamente
novo ao lado do TCP encontraria as caixas do meio da aula cinco — aquelas esticando o braço para
dentro de cabeçalhos cujo formato presumiram — e seria descartado por redes que não fazem ideia de
que são a causa. O UDP já passa. O transporte mais novo da internet está usando um disfarce, e a
violação de camada de duas aulas atrás é o motivo.

## O que você de fato faz a respeito

Muito pouco, que é o ponto.

Você não escolhe uma versão no seu código. Navegador e servidor combinam a melhor que os dois falam,
e o acordo faz parte da abertura de conexão que você viu na seção anterior. Seus manipuladores, seus
métodos e seus códigos de status são idênticos dos dois jeitos.

O que muda é o que vale a pena otimizar. A regra é curta: **no HTTP/1.1, menos requisições; no 2 e no
3, menos conexões.** Em qual deles você está é algo que as ferramentas de desenvolvedor do navegador
dizem numa coluna escondida por padrão, e que este curso liga na última aula.
