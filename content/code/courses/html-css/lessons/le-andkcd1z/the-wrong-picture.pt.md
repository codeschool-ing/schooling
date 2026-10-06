---
title: HTML não é a aparência da página
version: 1
---

Quase todo mundo chega ao HTML com uma imagem pronta na cabeça: **HTML é o código que faz a página ter a cara que tem**. Um título é grande porque está num `<h1>`; um texto é negrito porque está num `<b>`; uma página tem duas colunas porque alguém escreveu as tags certas. Essa imagem está errada de um jeito que cobra seu preço mais tarde, então vale trocá-la agora.

HTML descreve **o que cada pedaço do conteúdo é**. `<h1>` diz "este é o título principal da página". Que ele saia grande e em negrito é uma decisão que o navegador toma com a própria folha de estilos padrão, e cada uma dessas decisões pode ser desfeita com CSS. Você pode deixar um `<h1>` pequeno e cinza e um `<p>` enorme; a página ficaria estranha, e continuaria com a marcação correta, porque o HTML continuaria dizendo a verdade sobre o que cada parte é.

## Por que a diferença importa

Um navegador desenhando a página numa tela é só um dos leitores do seu HTML. Três outros o leem sem nunca olhar para a imagem:

- **Um leitor de tela**, usado por quem não enxerga a tela, lê os títulos em voz alta, deixa o usuário pular de um para o outro e anuncia uma lista como "lista, cinco itens". Ele só sabe o que é título pelo HTML.
- **Um buscador** lê o título, os cabeçalhos e os links para entender do que a página trata. Um título desenhado com uma `<div>` grande e em negrito é, para ele, mais um parágrafo.
- **O próprio navegador**, no modo de leitura, num relógio inteligente ou quando a folha de estilos da própria pessoa substitui a sua, usa o que os elementos são para decidir o que mostrar.

Então a pergunta a fazer enquanto escreve HTML nunca é "como isto vai aparecer?", e sim **"o que é isto?"**. A aula 2 trata inteiramente dessa pergunta. Como aparece é CSS, aulas 5 a 13.

## A segunda imagem errada: se aparece, está certo

A outra crença que vale nomear é a de que uma página que aparece direito tem HTML correto. **O navegador é o leitor mais tolerante que o seu HTML vai ter.** Ele foi feito para mostrar alguma coisa para qualquer entrada, porque a web do começo era escrita à mão por gente que errava, e um navegador que recusava páginas quebradas perdia para um que as mostrava.

Então ele conserta. Fecha elementos que você deixou abertos, move elementos que não podem ficar onde você os pôs e inventa os que você esqueceu. Esta aula mostra ele fazendo as três coisas, com o documento exato que o navegador montou impresso ao lado do arquivo que ele recebeu. A maioria dos consertos é inofensiva. Alguns mudam o que fica em negrito, o que fica dentro de um link ou o que um formulário envia. E um deles, na seção 07 desta aula, transforma uma página inteira numa janela em branco por causa de uma única tag de fechamento que faltou.

Uma página está correta quando o HTML dela diz o que quer dizer sem que o navegador tenha de adivinhar, e a ferramenta que diz se isso é verdade é um validador, seção 11.
