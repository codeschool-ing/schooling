---
title: Que taxa de erro precisa ser igual
version: 1
---

"Justo" tem vários significados precisos, e eles são medidas diferentes da tabela da auditoria.

| medida | igual entre grupos quer dizer | a coluna na auditoria |
|---|---|---|
| **taxa de marcação** | cada grupo é marcado com a mesma frequência | flagged |
| **taxa de alarmes falsos** | quem fica é marcado por engano com a mesma frequência | false alarms among stayers |
| **revocação** | quem sai é pego com a mesma frequência | recall |
| **precisão** | uma marcação é igualmente confiável em cada grupo | não impressa; pegos ÷ marcados |

**Elas não podem ser todas iguais ao mesmo tempo** sempre que os grupos saem em taxas diferentes, o que
em dado real quase sempre acontece. É um resultado matemático, não uma fraqueza de um modelo em
particular: quando um grupo sai com mais frequência, um modelo com precisão igual nos dois grupos não
consegue ter também alarmes falsos iguais e revocação igual, a menos que não erre nunca. Então a
pergunta nunca é "o modelo é justo?", e sim **"qual destas esta decisão precisa que seja igual?"**

A decisão responde, ao dizer qual erro machuca.

- **O clube de fidelidade** fecha uma porta para quem é marcado. O dano cai sobre clientes fiéis
  marcados por engano, então a **taxa de alarmes falsos entre quem fica** é o que precisa ser igual. O
  Norte falha com 22,0% contra 6,2% a 9,2%.
- **A oferta de retenção da aula 17** dá algo a quem é marcado. O dano cai sobre quem sai sem ser
  marcado e por isso não recebe oferta, então é a **revocação** que importa. Nela o Norte fica em
  58,8%, dez pessoas de 17, e não se distingue das outras regiões.

**Um modelo pode ser aceitável sob uma decisão e inaceitável sob outra**, sem mudança nenhuma nos
números dele. Por isso uma auditoria se faz para uma decisão e não para um modelo, e reusar um modelo
num propósito novo quer dizer refazer a auditoria.

A taxa de marcação é a medida que as pessoas procuram primeiro, e aqui ela engana. O Norte é marcado
27,4% das vezes e sai 14,5%. Forçar toda região a ser marcada na mesma taxa trataria como iguais
situações desiguais, e num grupo que de fato saísse mais esconderia de uma oferta de retenção feita
para eles os clientes que estão saindo.
