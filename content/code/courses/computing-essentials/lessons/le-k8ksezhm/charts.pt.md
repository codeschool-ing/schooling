---
title: Gráficos, em que a imagem não pode dizer mais que os números
version: 1
---

Um gráfico é um argumento. Ele pega uma tabela que ninguém leria e a transforma em algo que uma
pessoa absorve de relance — que é exatamente por que um gráfico consegue estar errado de um jeito
que uma tabela não consegue.

## Comece pela pergunta

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 288\" role=\"img\" aria-label=\"Cinco linhas emparelhando uma pergunta com o gráfico que a responde. Como mudou ao longo do tempo vai com uma linha. Como categorias se comparam vai com uma barra, ordenada. Como dois números se relacionam vai com uma dispersão. Como os valores se espalham vai com um histograma. Quanto de um total cada parte é vai com uma barra de novo, e uma pizza só para duas ou três partes.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Comece pela pergunta, nunca pelo menu de gráficos</text><text x=\"44\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a pergunta que você está fazendo</text><text x=\"676\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o gráfico que a responde</text><rect x=\"24\" y=\"62\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"77\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">como mudou ao longo do tempo</text><text x=\"676\" y=\"77\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma linha</text><rect x=\"24\" y=\"100\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"115\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">como estas categorias se comparam</text><text x=\"676\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma barra, ordenada</text><rect x=\"24\" y=\"138\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"153\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">como estes dois números se relacionam</text><text x=\"676\" y=\"153\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma dispersão</text><rect x=\"24\" y=\"176\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">como os valores estão espalhados</text><text x=\"676\" y=\"191\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um histograma</text><rect x=\"24\" y=\"214\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quanto do total é cada parte</text><text x=\"676\" y=\"229\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma barra, e pizza só para duas ou três</text><text x=\"24\" y=\"270\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Um gráfico escolhido no menu responde a qualquer pergunta que aquele gráfico por acaso responda.</text></svg>", "caption": "A última linha é a que vale discutir: uma pizza é lida comparando ângulos, coisa que as pessoas fazem mal acima de umas três fatias."}
```

Escolher no menu de gráficos e ver qual fica melhor é escolher um argumento e depois descobrir o
que ele diz. Decidir a pergunta antes leva dez segundos e elimina a maior parte dos gráficos ruins
que alguém já fez.

## A regra do eixo, que não é questão de gosto

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 298\" role=\"img\" aria-label=\"Dois gráficos de barras dos mesmos três valores, noventa e oito, cem e cento e dois. No gráfico da esquerda o eixo começa em zero e as três barras têm quase a mesma altura. No da direita o eixo começa em noventa e seis e a última barra tem o triplo da altura da primeira.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Os mesmos três números, desenhados duas vezes</text><text x=\"24\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">com o eixo no zero</text><path d=\"M50 68 L50 218 L320 218\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><text x=\"44\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"74\" y=\"74\" width=\"56\" height=\"144\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"102\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">98</text><rect x=\"154\" y=\"71\" width=\"56\" height=\"147\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"182\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">100</text><rect x=\"234\" y=\"68\" width=\"56\" height=\"150\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"262\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">102</text><text x=\"374\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">com o eixo em noventa e seis</text><path d=\"M400 68 L400 218 L670 218\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><text x=\"394\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">96</text><rect x=\"424\" y=\"168\" width=\"56\" height=\"50\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"452\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">98</text><rect x=\"504\" y=\"118\" width=\"56\" height=\"100\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"532\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">100</text><rect x=\"584\" y=\"68\" width=\"56\" height=\"150\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"612\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">102</text><text x=\"24\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma diferença de quatro por cento, que é o que ela é</text><text x=\"374\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">os mesmos quatro por cento, parecendo um triplo</text><text x=\"24\" y=\"280\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nenhum dos dois gráficos mente sobre os números. Só um deles mente sobre o tamanho da diferença.</text></svg>", "caption": "A regra não é que um eixo cortado seja proibido. É que o comprimento de uma barra é lido como o valor dela, então um gráfico de barras tem de começar no zero."}
```

**Uma barra é lida pelo comprimento**, então o comprimento tem de ser o valor, então o eixo tem de
começar no zero. Um eixo cortado num gráfico de barras não é ênfase; é uma barra três vezes mais
longa que outra descrevendo uma diferença de quatro por cento.

**Uma linha é lida pela inclinação**, então um gráfico de linha pode começar onde o dado é
interessante. Essa é a exceção e é a exceção inteira.

## Mais quatro que fazem o grosso do serviço

- **Ordene as barras.** Um gráfico de barras de categorias deve estar em ordem de valor, não
  alfabética, a menos que as categorias tenham ordem própria — meses, tamanhos, notas. Ordenar é o
  que torna a comparação legível.
- **Rotule a coisa em vez da legenda.** Uma legenda faz o olho viajar; um rótulo na linha ou na
  ponta da barra não faz. Duas séries raramente precisam de legenda.
- **Diga as unidades.** `Vendas` não é um título de eixo. `Vendas, R$ mil` é, e é a diferença
  entre um gráfico sobre o qual alguém consegue agir e um sobre o qual a pessoa tem de perguntar.
- **Titule com o achado.** *As vendas caíram no segundo trimestre* é um título. *Vendas por
  trimestre* é uma etiqueta de pasta, e quem lê tem de descobrir sozinho o que deveria estar
  vendo.

## Gráficos de pizza, honestamente

Uma pizza é lida comparando ângulos, coisa que as pessoas fazem mal. Acima de umas três fatias
ninguém consegue ordená-las de olho, e no instante em que duas fatias ficam próximas o gráfico
parou de responder à pergunta para a qual foi desenhado.

**Duas ou três partes de um todo: uma pizza serve e é imediatamente legível.** Mais que isso: um
gráfico de barras ordenado diz a mesma coisa e dá para ler.

E nunca uma pizza em 3D. A perspectiva deixa as fatias da frente maiores, o que significa que a
imagem está errada num tanto que depende de onde uma fatia por acaso está.

## A que não é sobre desenho

**Um gráfico construído sobre um intervalo não cresce.** Acrescente cem linhas embaixo dos dados
de um gráfico e o gráfico mostra as primeiras novecentas, em silêncio, pelo tempo que ninguém
conferir.

Construa gráficos sobre **tabelas** — o recurso do `Ctrl+T` da aula nove — e o intervalo cresce
com os dados. É o mesmo conserto de tudo o mais nesta aula: defina a coisa uma vez, e deixe tudo
apontar para a definição.
