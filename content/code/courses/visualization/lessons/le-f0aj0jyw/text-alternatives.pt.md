---
title: Alternativas em texto
version: 1
---

Um gráfico numa página web, num relatório ou num e-mail é uma imagem para um leitor de tela. Uma
pessoa cega, ou que usa um leitor de tela por qualquer motivo, recebe **só o texto que o descreve**. O
critério **1.1.1, Conteúdo Não Textual**, da WCAG pede que toda imagem que carrega informação tenha esse
texto.

## O que a alternativa deve dizer

Não "gráfico". Não "gráfico de barras do crescimento por região". Os dois são verdade e nenhum dá ao
leitor o que o gráfico dá a quem enxerga. Uma boa alternativa em texto diz:

1. **que tipo de gráfico e o que ele mede**, numa oração;
2. **o achado principal**, a frase que o gráfico foi feito para mostrar;
3. **os valores-chave**, os poucos números que um leitor citaria.

Para o gráfico de destaque da aula 13:

> Gráfico de barras do crescimento dos pedidos de 2024 a 2025 por região. O Norte cresceu mais rápido,
> 60,5%, quatro vezes os 14,6% do Sudeste. Nordeste 44,8%, Centro-Oeste 30,0%, Sul 23,5%.

Toda figura deste curso traz uma descrição escrita assim, no código da página, que um leitor de tela
anuncia no lugar do desenho.

## Quando o gráfico é complexo

Uma alternativa curta não cabe um mapa de calor de 105 células ou um mapa de 27 estados. Para esses,
**dê o dado como tabela** ao lado do gráfico ou atrás de um link, e mantenha a alternativa no achado.
Uma tabela também é a melhor alternativa para qualquer leitor que precise de números exatos, então ela
raramente é desperdiçada.

## Onde pôr

- **Na web**, o atributo `alt` da imagem, ou `aria-label` num SVG inline.
- **No Word, no PowerPoint e em PDF**, o campo de texto alternativo da imagem; a maioria dos programas
  de escritório pede por ele.
- **Em ferramentas de BI**, o Power BI e o Tableau deixam você escrever um texto alternativo para cada
  visual, e o Power BI consegue montá-lo a partir do dado com uma fórmula, para os números continuarem
  atualizados.
- **Em e-mail e chat**, uma frase embaixo da imagem, o que também ajuda quem lê num celular com as
  imagens desligadas.
