---
title: Onde tudo vai, e de que cor é
version: 1
---

A árvore de renderização diz o que será desenhado. Ela não diz onde. Nada na marcação nem nos estilos
deu uma coordenada para coisa alguma, e no entanto a página pronta tem uma para cada caixa, cada linha
de texto e cada letra.

Produzi-las é o **layout**, e costuma ser a coisa mais cara desta lista.

## Layout

O navegador percorre a árvore e calcula, para cada caixa, uma posição e um tamanho, em pixels, para
esta janela nesta largura.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A mesma marcação disposta em duas larguras de janela, produzindo posições diferentes, quebras de linha diferentes e uma altura diferente. Nada na marcação deu uma coordenada.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">com 1200 pixels de largura</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <rect x=\"36\" y=\"52\" width=\"140\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"106\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">título</text> <rect x=\"184\" y=\"52\" width=\"140\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"254\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">uma imagem</text> <rect x=\"36\" y=\"90\" width=\"288\" height=\"50\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">duas linhas de texto</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">com 400 pixels de largura</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <rect x=\"396\" y=\"52\" width=\"288\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">título</text> <rect x=\"396\" y=\"86\" width=\"288\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">uma imagem, agora abaixo</text> <rect x=\"396\" y=\"120\" width=\"288\" height=\"70\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">quatro linhas de texto</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um cálculo e não uma consulta — e é por isso que virar o celular é um completo</text> </svg>", "caption": "Cada posição da página pronta foi calculada, para esta janela, nesta largura, há um instante."}
```

Essa última parte é a importante. Quase nada numa página tem tamanho fixo: uma largura é uma
porcentagem de um pai cuja largura é consequência da janela, uma altura é o que o conteúdo acabou
precisando, uma linha de texto quebra onde por acaso chega à borda.

Então layout é um cálculo e não uma consulta, e depende de coisas que mudam. Virar um celular de lado
é um layout completo. Mudar uma fonte é um layout. Acrescentar uma frase a um parágrafo é um layout de
tudo que vem depois dele.

A palavra que você vai ver em ferramentas e em textos mais antigos é **reflow**, que quer dizer a
mesma coisa.

## Pintura, e composição

Quando cada caixa tem um retângulo, a **pintura** preenche o que há dentro dele: cores, bordas, texto,
sombras, imagens. Isso produz pixels, em geral em várias superfícies separadas em vez de uma.

Depois a **composição** junta essas superfícies na ordem certa e entrega o resultado à tela. Coisas
sobrepostas, transparência, e qualquer coisa que o hardware desenhe rápido são resolvidas aqui.

A divisão importa por causa do que ela torna barato.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três tipos de mudança e quanto cada uma custa: mudar tamanho ou posição custa layout, pintura e composição; mudar cor custa pintura e composição; mudar transform ou opacity custa só composição.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"44\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"160\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">largura, altura, top, left, fonte</text> <text x=\"440\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">layout, depois pintura, depois composição</text> <rect x=\"20\" y=\"88\" width=\"680\" height=\"44\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"160\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cor, fundo, sombra</text> <text x=\"440\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pintura, depois composição</text> <rect x=\"20\" y=\"142\" width=\"680\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"160\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">transform, opacity</text> <text x=\"440\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">só composição</text> <text x=\"360\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">anime a linha de baixo, e o orçamento de um quadro é 16 ms</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um layout de uma página grande num celular modesto já gastou isso</text> </svg>", "caption": "O fato mais acionável da aula, e é consequência do pipeline em vez de moda."}
```

Uma mudança que afeta apenas a composição — mover algo com um transform, mudar a opacidade dele — pode
ser feita sem dispor nada e sem repintar nada. É por isso que uma animação feita com essas duas
propriedades é suave e uma animação feita com `top` e `left` não é: uma delas é uma composição por
quadro e a outra é um layout e uma pintura por quadro.

Este é o fato mais acionável da aula. **Anime transform e opacity.** Não porque estão na moda, mas por
causa de onde ficam neste pipeline.

## O que dispara o quê

Uma tabela curta, e vale saber em vez de consultar.

| uma mudança em | custa |
|---|---|
| largura, altura, posição, tamanho de fonte, texto | layout, depois pintura, depois composição |
| cor, fundo, sombra, cor de borda | pintura, depois composição |
| transform, opacity | só composição |

Qualquer coisa mais acima nessa tabela inclui tudo que está abaixo. Não há como dispor algo sem
pintá-lo em seguida.

## A armadilha que tem nome

Um padrão vale reconhecer porque transforma uma página rápida numa lenta sem que nenhuma linha isolada
pareça errada.

Um script muda um estilo e então lê um valor que depende do layout — uma largura, uma posição, a altura
de algo. O navegador não consegue responder sem dispor, então ele dispõe, na hora. O script muda outro
estilo e lê outro valor, e ele dispõe de novo. Num laço sobre quarenta elementos, isso são quarenta
layouts onde um teria bastado.

Isso é **layout thrashing**, e a correção é fazer todas as leituras primeiro e todas as escritas
depois, para que um layout sirva ao lote inteiro.

Você não precisa escrever scripts para se beneficiar de saber disso. É uma das duas ou três coisas que
fazem uma página engasgar enquanto a rede está parada, e reconhecer o formato é quase todo o
diagnóstico.

## Camadas, e a tentação de criar mais delas

A composição trabalha com superfícies, e um navegador decide quais partes de uma página ganham uma
própria. Algo sendo animado, algo fixo na viewport, um vídeo — cada um pode ser promovido a uma camada
própria para que movê-lo custe só recompor.

Existe uma propriedade que pede isso deliberadamente, e vale conhecer nas duas direções. Usada nas uma
ou duas coisas que você de fato está animando, ela remove um engasgo. Usada em tudo, é um jeito bem
documentado de deixar uma página mais lenta: cada camada custa memória, e uma página com centenas
delas gasta mais tempo administrando superfícies do que economizou por tê-las.

O instinto é o mesmo do resto desta aula. **Promova o que se move, não a página sobre a qual ele se
move.**

## Onde estão os números

Tudo acima é visível. As ferramentas de desempenho de um navegador registram esses passos com a
duração de cada um, na aula que vem depois desta.

Dois números para levar. Um layout de uma página grande num celular modesto é medido em dezenas de
milissegundos, e dezesseis milissegundos é o orçamento de um quadro de animação suave — o que quer
dizer que um único layout dentro de um quadro já o gastou.
