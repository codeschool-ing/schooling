---
title: O Word, em que o programa inteiro é uma distinção
version: 1
---

O Word tem uma ideia dentro dele e todo o resto é consequência. **Um documento tem estrutura, e a
formatação é a aparência dessa estrutura.**

Um título é um título porque ele é *marcado* como um. Deixar uma linha em dezoito pontos e negrito
produz uma linha que parece um título e não é um, e a diferença é invisível na página e decide o
que o programa consegue fazer por você.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"Dois painéis mostrando a mesma página de um documento. Os dois desenham uma linha grande e em negrito idêntica seguida de três linhas de texto. O painel da esquerda, marcado como estilo de título, registra a linha como Título 1 seguida de parágrafos Normais, e consegue montar um sumário. O painel da direita, marcado como formatação direta, registra só um parágrafo Normal posto em dezoito pontos e negrito, e não tem do que montar um sumário.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">A mesma página, duas vezes, e o que o programa anotou</text><rect x=\"24\" y=\"36\" width=\"322\" height=\"230\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">marcada com um estilo de título</text><text x=\"44\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Uma nota sobre o método</text><path d=\"M44 104 L326 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M44 115 L286 115\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M44 126 L246 126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M44 140 L326 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"374\" y=\"36\" width=\"322\" height=\"230\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">aumentada e negritada à mão</text><text x=\"394\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Uma nota sobre o método</text><path d=\"M394 104 L676 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M394 115 L636 115\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M394 126 L596 126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"3\"></path><path d=\"M394 140 L676 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"44\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o Word registrou</text><text x=\"44\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Título 1</text><text x=\"44\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Normal</text><text x=\"44\" y=\"218\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Normal</text><text x=\"44\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um sumário sai dali sozinho</text><text x=\"394\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o Word registrou</text><text x=\"394\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Normal, 18 pt, negrito</text><text x=\"394\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Normal</text><text x=\"394\" y=\"218\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Normal</text><text x=\"394\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">não há do que montar um</text><text x=\"24\" y=\"288\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">As duas páginas imprimem igual. Só uma delas dá para navegar, renumerar ou reformatar num movimento.</text></svg>", "caption": "Nada na página diz qual das duas você está vendo. A diferença aparece no dia em que você precisa de um sumário."}
```

## O que sai disso

Tudo nesta lista é de graça se o documento estiver marcado e impossível se não estiver:

- **Um sumário**, montado e remontado num clique, com os números de página certos.
- **O painel de navegação**, que transforma um documento de sessenta páginas numa lista que dá
  para clicar e reordenar arrastando.
- **Reformatar o documento inteiro de uma vez.** Mude a aparência do *Título 1* e todo título
  muda. Com formatação direta, isso são cem edições à mão e uma que você vai esquecer.
- **Numeração que se renumera** — figuras, tabelas, títulos, e as referências cruzadas que
  apontam para eles.
- **Um leitor de tela que consegue navegar**, que é a razão de isto ser uma questão de
  acessibilidade e não só de arrumação.

## Os três estilos que cobrem quase tudo

Você não precisa aprender o sistema de estilos. Você precisa de três:

| | para |
|---|---|
| **Normal** | o corpo do texto. Tudo que não for um dos outros |
| **Título 1, 2, 3** | a estrutura. Três níveis bastam para quase qualquer documento |
| **Título** | o do topo, que não é um título de seção e não deve entrar no sumário |

**Ajuste uma vez, nos estilos do próprio documento, em vez de formatar cada uso.** Botão direito
num estilo, *Modificar*, muda a fonte — e tudo que o usa acompanha.

## A coisa para parar de fazer

**Não aperte Enter para fazer espaço.** Um parágrafo em branco é um parágrafo, e ele se mexe
quando o texto acima reflui, e é por isso que documentos chegam com um título sozinho no pé de uma
página e a seção dele na seguinte.

Espaço acima e abaixo de um parágrafo é uma **propriedade do estilo**. Ajuste uma vez e todo
parágrafo daquele tipo fica espaçado certo para sempre, inclusive os que você ainda não escreveu.

O mesmo vale para apertar Enter até alguma coisa chegar à próxima página. É para isso que existe
uma **quebra de página**, e a diferença aparece no instante em que uma frase é acrescentada acima.

## Controlar alterações e comentários, que é para o que ele de fato serve no trabalho

**Comentários** são perguntas na margem; eles não mudam nada. **Controlar alterações** registra
cada edição como uma proposta que outra pessoa aceita ou recusa.

Duas coisas que valem saber antes de mandar um documento para alguém:

- **As alterações controladas viajam dentro do arquivo.** Um documento enviado com as alterações
  ainda registradas carrega cada frase recusada, cada preço anterior, cada parágrafo apagado —
  legíveis por quem abrir.
- **O histórico nos metadados também viaja**: nomes de autores, a hora em que foi editado, e às
  vezes o caminho de onde foi salvo. O *Inspecionar Documento* remove tudo isso, e vale rodar uma
  vez em qualquer coisa que saia da empresa.
