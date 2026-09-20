---
title: O PowerPoint, em que o slide não é onde o design mora
version: 1
---

O modelo do PowerPoint tem o mesmo formato do Word e as pessoas o perdem pelo mesmo motivo. **Um
slide é um layout preenchido**, e o layout mora no *slide mestre* — um lugar só, valendo para todo
slide que o usa.

Um **espaço reservado** é uma caixa que o layout pôs ali. Uma **caixa de texto** é uma que você
desenhou. Elas parecem idênticas e não são o mesmo objeto.

| | um espaço reservado | uma caixa que você desenhou |
|---|---|---|
| de onde vem a fonte dela | do layout | de onde você ajustou |
| muda quando o mestre muda | sim | não |
| aparece no modo de tópicos | sim | não |
| lida por um leitor de tela em ordem | sim | por último, ou nunca |
| sobrevive a uma troca de modelo | sim | ela se desloca ou se sobrepõe |

**O jeito mais comum de uma apresentação se tornar impossível de manter** é alguém apagar um
espaço reservado e desenhar uma caixa de texto no lugar porque era mais fácil de mover. Tudo
acima deixa de valer para aquele slide, e nada avisa.

## O que o mestre te compra

Mude a fonte no mestre e a apresentação inteira muda. Mude a posição do logotipo uma vez. Aplique
o modelo da empresa e todo slide se adapta, porque todo slide é um layout e o modelo é um conjunto
de layouts.

Trabalhando do outro jeito — uma apresentação de caixas desenhadas à mão — aplicar um modelo muda
o fundo e mais nada, e você reposiciona noventa slides à mão.

## A parte honesta sobre design de slide

O conselho é antigo e é em geral verdadeiro:

- **Um slide não é um documento.** Se dá para ler, ele está sendo lido no seu lugar. As notas
  existem para as frases.
- **Uma ideia por slide**, e o título diz a ideia em vez de nomear o assunto. *As vendas caíram no
  segundo trimestre* é um título; *Vendas* é uma etiqueta de pasta.
- **Tipo grande.** Vinte e quatro pontos é um piso, e o teste real é se dá para ler do fundo da
  sala em que você realmente vai estar.
- **Contraste ganha de enfeite**, e é a mesma aritmética da WCAG de qualquer tela: texto claro
  sobre fotografia precisa de uma faixa escurecida atrás, não de esperança.

E a que não é sobre design: **a apresentação é o material de apoio com a mesma frequência com que
é a fala.** Se ela vai ser lida sozinha depois, as frases têm de estar em algum lugar — que é para
o que o painel de notas serve, e o que exportar as páginas de anotações produz.

## Apresentar, em quatro fatos

- **O modo de apresentador** mostra as suas notas, o próximo slide e um relógio na sua tela
  enquanto a plateia vê só o slide. É a razão inteira de ligar em vez de espelhar.
- **`F5` começa do início, `Shift+F5` do slide atual.** O segundo é o que você quer enquanto
  monta.
- **Aperte `B` para apagar a tela.** Para o momento em que alguém faz uma pergunta e o slide
  atrapalha.
- **Exporte para PDF para enviar.** Isso elimina o problema de fonte, o de animação e o de versão
  num passo só, e ninguém precisava editar.

## E a coisa para conferir antes que importe

**Fontes não viajam dentro de um `.pptx` a menos que você as embuta.** Uma apresentação montada
numa fonte que a outra máquina não tem é rediagramada naquela máquina, o que move cada linha e
quebra cada caixa cuidadosamente posicionada — na sala, na frente das pessoas.

*Salvar, Opções, Incorporar fontes no arquivo* resolve, e um PDF resolve de modo mais completo.
Para qualquer coisa apresentada de uma máquina que não é sua, mande o PDF também.
