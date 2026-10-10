---
title: Lendo uma árvore em voz alta
version: 1
---

Uma árvore é um conjunto de regras, uma por folha, e cada regra é o caminho da raiz até aquela folha.
A árvore do `first_tree.py` se lê, folha por folha, como quatro frases que qualquer pessoa da Feira em
Casa poderia conferir:

| caminho | quem saiu na folha | a regra, em voz alta |
|---|---|---|
| avaliação ≤ 3,6, reclamações = 0 | 525 de 2.386, 22% | um assinante insatisfeito que não reclamou sai mais ou menos em um de cada cinco |
| avaliação ≤ 3,6, reclamações ≥ 1 | 353 de 896, 39% | um assinante insatisfeito que reclamou sai mais ou menos em dois de cada cinco |
| avaliação > 3,6, pulos ≤ 2 | 1.091 de 33.424, 3% | um assinante satisfeito que mantém as caixas quase nunca sai |
| avaliação > 3,6, pulos ≥ 3 | 232 de 1.922, 12% | um assinante satisfeito que pula muito sai mais ou menos em um de cada oito |

**Essa tabela é o modelo.** Não há mais nada nele. Ela pode ser impressa, discutida e pregada na
parede, e a equipe de retenção pode aplicá-la sem computador. Numa árvore pequena essa legibilidade é
o principal motivo para escolhê-la, e é por isso que árvores são usadas onde cada decisão precisa ser
justificada, como quais sinistros uma seguradora manda para revisão.

A legibilidade some com a profundidade. A melhor árvore da seção anterior, de profundidade 7, tem 110
folhas e caminhos de até sete condições; ainda dá para imprimi-la, mas ela não cabe mais na cabeça de
ninguém, e na profundidade 10 é tão opaca quanto qualquer outro modelo. **Uma árvore é legível quando
é pequena, e precisa quando não é**, e na maioria dos dados essas duas coisas puxam para lados
opostos.

## Três jeitos de a leitura dar errado

**Ler um caminho como causa.** *Reclamar sobe a chance de sair de 22% para 39%* é o que a tabela
parece dizer. Ela diz que, entre os assinantes insatisfeitos, os que reclamaram saíram mais; se
reclamar teve algo a ver com isso é outra pergunta, e o aviso da aula 5 vale também para árvores.

**Ler a ordem das perguntas como importância.** A coluna na raiz é o melhor corte isolado, não
necessariamente a coluna mais útil no conjunto. Uma coluna que nunca aparece perto do topo ainda pode
ser usada em dezenas de cortes mais abaixo.

**Ler uma coluna ausente como irrelevante.** Uma coluna pode faltar na árvore porque outra,
correlacionada, foi escolhida primeiro a cada passo. `orders_90d` nunca aparece na saída do
`first_tree.py` porque `skips_90d` carrega a mesma informação e ganhou o corte.
