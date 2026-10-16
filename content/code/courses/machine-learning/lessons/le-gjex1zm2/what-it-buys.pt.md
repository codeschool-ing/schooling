---
title: O que reequilibrar compra, e quando
version: 1
---

Ponha os números da aula num lugar só:

| remédio | AUC | precisão média | no próprio melhor corte |
|---|---|---|---|
| nenhum | 0,804 | 0,322 | R$ 23.832 |
| pesos de classe | 0,797 | 0,321 | R$ 21.304 |
| sobreamostragem | 0,788 | 0,315 | R$ 21.616 |
| subamostragem | 0,788 | 0,285 | R$ 18.440 |

Neste problema **nenhum dos remédios fez o modelo saber mais**, e cada um o deixou um pouco pior. O que
cada um fez foi mover as chances, e com elas o lugar onde um corte é útil. Um modelo que produz chances,
lido com um corte calculado dos custos, já lidou com o desbalanceamento: o corte é onde se lida com ele.

Isso não vale para todo problema, e os casos em que reequilibrar se justifica merecem ser conhecidos pelo
nome:

- **Um modelo que dá rótulos, não chances.** Alguns algoritmos, ou alguns sistemas em produção, só dizem
  sim ou não. Sem chance não há corte para mover, e o peso é o único botão que sobra.
- **Um algoritmo cuja perda ignora a classe rara.** Uma máquina de vetores de suporte ou uma árvore rasa
  numa classe de um em mil pode se acomodar prevendo a maioria em toda parte. Os pesos a obrigam a olhar.
  Confira que olhou, com as curvas da aula 10, em vez de supor.
- **Dados grandes demais para ajustar.** Subamostre a maioria, depois corrija as chances.
- **Uma classe rara com pouquíssimos exemplos.** Aqui nada nesta aula ajuda muito, e a seção sobre
  contagens disse por quê. Colete mais deles.

E três hábitos, seja qual for o remédio:

- **Compare com não fazer nada**, cada modelo no próprio melhor corte, no mesmo teste honesto.
- **Reamostre dentro da parte**, nunca antes da divisão.
- **Devolva as chances ao lugar** antes que um corte calculado dos custos as leia: a fórmula depois da
  subamostragem, calibração depois de qualquer outra coisa.
