---
title: Descobrindo qual regra venceu
version: 1
---

Toda captura desta aula usou `probe rules`, e ele existe porque **o DevTools mostra a mesma lista**. Quando um estilo não faz o que você espera, este é o procedimento que descobre o porquê em um minuto, em vez de uma tarde acrescentando `!important`:

1. **Clique com o botão direito no elemento e escolha Inspecionar.** O painel Elements abre com o elemento selecionado.
2. **Olhe o painel Styles.** Ele lista toda regra que casou com o elemento, a mais importante primeiro: `element.style` no topo, depois as suas regras da maior especificidade para baixo, depois as do navegador, marcadas como *user agent stylesheet*. Cada regra diz o arquivo e a linha.
3. **Encontre a propriedade.** Uma declaração que perdeu aparece **riscada**. A que se aplica é a que não está, e a regra dela é a vencedora.
4. **Leia por que venceu.** Mais acima na lista quer dizer que venceu por especificidade ou por ordem; o arquivo e a linha dizem qual. Se a sua declaração está riscada, a regra acima dela com a mesma propriedade é o que a venceu.
5. **Se a sua regra nem aparece, o seletor não casa.** É outro problema: leia o seletor pela direita, como a seção 04 disse, contra as classes e os pais reais do elemento na árvore.
6. **O painel Computed** mostra o valor final de cada propriedade, e expandir uma mostra toda declaração que disputou por ela, que é o mesmo que a linha `computed` no fim de cada `probe rules`.

## Três coisas que ele mostra e você não adivinharia

**Uma declaração com sinal de aviso não foi entendida**: uma propriedade com erro de digitação ou um valor inválido, pulados como a seção 02 disse. **Um valor herdado aparece em *Inherited from main*** mais abaixo, não entre as regras do próprio elemento, como a cor da nota apareceria. **Uma regra pode casar e não definir nada que você veja**: um fundo num elemento cujos filhos o cobrem inteiro está aplicado e invisível, e o painel Computed é como você prova que o valor está lá.

O painel também deixa você editar qualquer valor e ver o resultado na hora, desmarcar uma declaração para desligá-la e acrescentar uma nova. Nada do que você muda ali é salvo: é um lugar para experimentar, e quando você acha a correção, escreve-a no arquivo.
