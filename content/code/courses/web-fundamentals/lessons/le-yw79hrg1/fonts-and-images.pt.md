---
title: Por que o texto pisca, e por que a página pula
version: 1
---

Dois incômodos, os dois extremamente comuns, e os dois explicados por coisas mais atrás nesta aula.
Nenhum é sobre lentidão — eles são sobre chegar **tarde**, que tem causas diferentes e correções
diferentes.

## A fonte, e o piscar

Uma fonte web é um arquivo, descoberto quando os estilos são lidos, buscado como qualquer outro. Ela
costuma chegar depois do momento em que a primeira pintura teria acontecido, o que deixa o navegador
com uma decisão sobre um texto que ele precisa desenhar agora.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas escolhas enquanto uma fonte web ainda carrega: não desenhar nada e deixar o texto invisível, ou desenhar com uma reserva e trocar quando a fonte chegar, o que mexe um pouco no texto.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">esperar a fonte</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o texto fica invisível até ela chegar</text> <rect x=\"20\" y=\"92\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">correto desde o primeiro instante</text> <rect x=\"20\" y=\"148\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e parece quebrado enquanto espera</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">desenhar uma reserva e trocar</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">legível na hora, numa fonte do sistema</text> <rect x=\"380\" y=\"92\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">quem lê começa antes de ela chegar</text> <rect x=\"380\" y=\"148\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e o texto se mexe na troca</text> <text x=\"360\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma reserva de largura parecida é o que torna a coluna da direita barata</text> </svg>", "caption": "Não há terceira opção enquanto a fonte está a caminho. As duas colunas são uma escolha sobre o que quem lê vê."}
```

**Esperar e não desenhar nada.** O texto fica invisível até a fonte chegar, que é o *lampejo de texto
invisível*. O layout está correto desde o primeiro instante e a página parece quebrada enquanto
espera.

**Desenhar com uma reserva e trocar.** O texto aparece na hora numa fonte do sistema, e troca quando a
de verdade chega — o *lampejo de texto sem estilo*. Quem lê consegue ler imediatamente, e o texto se
mexe na troca, porque as duas fontes não têm a mesma largura.

Navegadores deixam você escolher, com um descritor `font-display`. Toda escolha é uma troca entre
essas duas, e existe um padrão sensato: **mostre a reserva e troque**, a menos que a identidade da
fonte importe mais para você do que ser legível durante a espera.

Três coisas reduzem o problema em vez de trocá-lo. Menos pesos, porque cada um é um arquivo separado.
Uma dica de **preload**, para a fonte ser descoberta junto com a folha de estilo em vez de depois dela.
E uma reserva escolhida por largura parecida, para a troca mexer menos no texto.

## O pulo, e o deslocamento de layout

O segundo é mais danoso e inteiramente evitável.

Uma imagem sem dimensões declaradas não ocupa espaço até chegar. O navegador dispõe a página sem ela,
pinta, e então — quando os bytes aparecem — descobre que uma imagem de 400 pixels de altura precisa ir
ali, e empurra tudo abaixo dela para baixo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma imagem sem tamanho declarado não ocupa espaço até carregar, então tudo abaixo dela desce quando ela chega. Com os atributos width e height o espaço é reservado e nada se mexe.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">sem tamanho declarado</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">um título</text> <rect x=\"20\" y=\"66\" width=\"320\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">um parágrafo, lido primeiro</text> <rect x=\"20\" y=\"100\" width=\"320\" height=\"80\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".26\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a imagem chega e reivindica 400 px</text> <text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">tudo abaixo desce</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">width e height na tag</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">um título</text> <rect x=\"380\" y=\"66\" width=\"320\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">um parágrafo, lido primeiro</text> <rect x=\"380\" y=\"100\" width=\"320\" height=\"80\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o espaço foi reservado antes dos bytes</text> <text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nada se mexe quando ela preenche</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">é por isso que quem lê toca no link errado</text> <text x=\"360\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um hábito antigo, conselho atual, e por um motivo diferente do de antes</text> </svg>", "caption": "Dois atributos, e o navegador reserva exatamente o espaço certo mesmo quando a sua folha de estilo redimensiona a imagem."}
```

Isto é um **deslocamento de layout**, e é o que faz quem lê tocar no link errado, porque a página se
mexeu entre decidir e tocar.

A correção é contar ao navegador o tamanho antes de os bytes chegarem. Ponha os atributos `width` e
`height` em toda imagem — as dimensões reais em pixels do arquivo — e navegadores modernos os usam para
reservar exatamente o espaço certo mesmo quando a sua folha de estilo redimensiona a imagem de forma
responsiva. Parece um retorno a um hábito bem antigo e é o conselho atual, por um motivo novo.

O mesmo vale para qualquer coisa que chega tarde num espaço de que vai precisar: um quadro embutido, um
vídeo, um anúncio, um banner que um script insere no topo da página. Reserve o espaço, ou aceite que
tudo abaixo dele vai se mexer.

## Imagens, e os dois números que importam

Já que estamos aqui, porque é a maior coisa que a maioria das páginas baixa.

**Dimensões.** Mandar uma imagem de 4000 pixels para exibi-la a 400 são quatro megabytes para desenhar
cem mil pixels. Navegadores a redimensionam de bom grado e o download continuou sendo quatro megabytes.

**Formato.** Os formatos modernos da negociação da aula seis frequentemente têm metade do tamanho dos
antigos para a mesma foto, escolhidos automaticamente, sem mudar endereço nenhum.

E um atributo quase de graça: `loading="lazy"` em imagens abaixo da dobra, que adia buscá-las até quem
lê se aproximar. É uma palavra só e numa página longa remove a maior parte do download.

Não ponha na imagem do topo. Aquela é o que quem lê está esperando, e adiá-la é o caso em que este
atributo deixa a página pior.

## As medições em que essas duas têm nome

Os dois problemas são medidos, pelo nome, em toda ferramenta de desempenho, e vale saber antes da
próxima aula.

**A maior coisa desenhada na área visível** — em geral a imagem principal ou o título — tem uma métrica
para quando aparece. Uma imagem de destaque enviada num formato antigo com quatro vezes o tamanho
necessário é a razão mais comum de esse número ser ruim.

**Movimento depois do desenho** também tem uma: uma pontuação que soma quanto da tela se mexeu e o
quanto, ao longo da visita inteira. Imagens sem espaço reservado e banners tardios são o que a empurra
para cima.

A razão para conhecer os nomes é que esses são os números que um cliente, um buscador ou um gestor vai
citar para você, e os dois são produzidos pelos dois mecanismos desta leitura em vez de por qualquer
coisa que um servidor fez.

## Nenhum dos dois é lentidão

Vale terminar nisso, porque muda o que você mediria.

A fonte não estava lenta; foi descoberta tarde e desenhada duas vezes. A imagem não estava lenta; foi
deixada chegar num espaço que não tinha sido reservado.

Os dois são visíveis de um jeito que uma diferença de duzentos milissegundos num tempo de resposta
nunca é, e os dois se resolvem com um atributo em vez de com um servidor mais rápido. Esse é o argumento
para conhecer esta aula: ela separa os problemas que uma rede resolve dos problemas que só a página
resolve.
