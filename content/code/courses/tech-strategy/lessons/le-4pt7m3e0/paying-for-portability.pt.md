---
title: Pagar pela portabilidade, ou não
version: 1
---

Evitar um aprisionamento nunca é de graça, e essa é a metade que o slogan deixa de fora.
**Portabilidade é trabalho que você faz agora para que uma troca custe menos depois**, e tem preço
como qualquer outro trabalho. A decisão é uma comparação entre dois números: quanto custa a
portabilidade, contra o custo esperado do aprisionamento que ela remove.

## Quanto custa a portabilidade na Coreto

**Para o banco de documentos: R$ 63.000 em três anos.** O time de Catálogo poria um adaptador entre o
código e o banco — um módulo da própria Coreto por onde passa toda consulta, para que a interface de
consulta do fornecedor apareça num lugar só, e não em muitos. Construí-lo leva 300 horas. Depois ele
precisa de 40 horas por ano para acompanhar: toda funcionalidade que pede um tipo novo de consulta
precisa dela no adaptador primeiro. Em três anos são 300 + 3 × 40 = 420 horas, a R$ 150.

Ele também tem um custo que nenhuma planilha guarda. Um adaptador escrito para funcionar com
qualquer banco expõe só o que todo banco faz, então os recursos que tornaram este atraente ficam
mais difíceis de usar.

**Para o gateway de pagamento: R$ 24.000.** O time de Pagamentos poria uma interface de pagamento da
própria Coreto entre o checkout e o gateway, e garantiria que o contrato permita exportar os cartões
guardados para outro gateway. Construir a interface leva 160 horas, e ela não precisa de nada por
ano depois disso: as operações de pagamento — cobrar, estornar, cancelar — raramente mudam, então a
interface fica parada depois de pronta.

## A planilha, terminada

Acrescente a coluna E à planilha da seção anterior, e a decisão na coluna F:

| | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| 1 | Aprisionamento | Custo de troca | Probabilidade | Custo esperado | Portabilidade | Decisão |
| 2 | Banco de documentos gerenciado | 210000 | 10% | 21000 | 63000 | |
| 3 | Gateway de pagamento | 135000 | 35% | 47250 | 24000 | |

Em F2 e F3, a comparação escrita como fórmula, para que mude se uma estimativa mudar:

```localised
=SE(E2<D2;"pagar pela portabilidade";"aceitar o aprisionamento")      aceitar o aprisionamento
=SE(E3<D3;"pagar pela portabilidade";"aceitar o aprisionamento")      pagar pela portabilidade
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Dois casos, duas barras cada. Banco de documentos gerenciado: custo esperado da troca R$ 21.000, portabilidade em três anos R$ 63.000, então aceitar o aprisionamento. Gateway de pagamento: custo esperado da troca R$ 47.250, portabilidade R$ 24.000, então pagar pela portabilidade.\"><text x=\"20\" y=\"34\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Banco de documentos gerenciado</text><text x=\"220\" y=\"62\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">custo esperado da troca</text><rect x=\"230\" y=\"46\" width=\"126\" height=\"22\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"364\" y=\"61\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 21.000</text><text x=\"220\" y=\"92\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">portabilidade, três anos</text><rect x=\"230\" y=\"76\" width=\"378\" height=\"22\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"616\" y=\"91\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 63.000</text><text x=\"230\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">→ aceitar o aprisionamento</text><text x=\"20\" y=\"159\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Gateway de pagamento</text><text x=\"220\" y=\"187\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">custo esperado da troca</text><rect x=\"230\" y=\"171\" width=\"283.5\" height=\"22\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"521.5\" y=\"186\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 47.250</text><text x=\"220\" y=\"217\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">portabilidade, três anos</text><rect x=\"230\" y=\"201\" width=\"144\" height=\"22\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"382\" y=\"216\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 24.000</text><text x=\"230\" y=\"247\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">→ pagar pela portabilidade</text></svg>", "caption": "Cada aprisionamento como duas barras: quanto se espera que custe (custo de troca × probabilidade) e quanto custa evitá-lo em três anos. A barra menor decide."}
```

**O aprisionamento ao banco é aceito, e o do gateway é comprado de volta.** No banco, evitar o
aprisionamento custaria R$ 63.000 para remover um custo esperado de R$ 21.000: o triplo. No gateway,
R$ 24.000 removem um custo esperado de R$ 47.250: cerca da metade. A mesma aritmética dá respostas
opostas, e a resposta é decidida pela probabilidade tanto quanto por qualquer um dos custos.

## Quanto a probabilidade teria de se mover?

A probabilidade é o número mais fraco da planilha, então o mais útil a saber de cada decisão é onde
ela se inverte. A portabilidade vale a pena quando o custo esperado passa dela, então a probabilidade
de equilíbrio é a portabilidade dividida pelo custo de troca:

| | portabilidade | custo de troca | probabilidade de equilíbrio | estimativa da Coreto |
|---|---|---|---|---|
| banco de documentos | R$ 63.000 | R$ 210.000 | 63.000 ÷ 210.000 = 30% | 10% |
| gateway de pagamento | R$ 24.000 | R$ 135.000 | 24.000 ÷ 135.000 = 17,8% | 35% |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois gráficos pequenos. Cada um tem a probabilidade de troca de 0% a 50% na horizontal e dinheiro na vertical. Uma linha que sobe é o custo esperado; uma linha reta é o custo da portabilidade. No banco de documentos elas se cruzam em 30% e a estimativa da Coreto é 10%, à esquerda do cruzamento. No gateway de pagamento se cruzam em cerca de 18% e a estimativa é 35%, à direita do cruzamento.\"><text x=\"70\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">banco de documentos</text><path d=\"M70 230 L330 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M70 230 L70 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"70\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0%</text><text x=\"200\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25%</text><text x=\"330\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50%</text><text x=\"200\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">probabilidade de troca</text><path d=\"M70 230 L330 62\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"326\" y=\"54\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">custo esperado</text><path d=\"M70 129.2 L330 129.2\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"326\" y=\"145.2\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">portabilidade</text><path d=\"M226 129.2 L226 230\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><text x=\"230\" y=\"224\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">equilíbrio 30%</text><circle cx=\"122\" cy=\"196.4\" r=\"4.5\" fill=\"var(--paper)\"></circle><text x=\"130\" y=\"212.4\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estimativa 10%</text><text x=\"420\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">gateway de pagamento</text><path d=\"M420 230 L680 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M420 230 L420 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"420\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0%</text><text x=\"550\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25%</text><text x=\"680\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50%</text><text x=\"550\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">probabilidade de troca</text><path d=\"M420 230 L680 122\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"676\" y=\"114\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">custo esperado</text><path d=\"M420 191.6 L680 191.6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"676\" y=\"207.6\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">portabilidade</text><path d=\"M512.56 191.6 L512.56 230\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><text x=\"516.56\" y=\"224\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">equilíbrio 17,8%</text><circle cx=\"602\" cy=\"154.4\" r=\"4.5\" fill=\"var(--paper)\"></circle><text x=\"594\" y=\"145.4\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estimativa 35%</text></svg>", "caption": "O custo esperado sobe com a probabilidade de troca; a portabilidade custa o mesmo aconteça o que acontecer. Pagar pela portabilidade compensa à direita do cruzamento: 30% no banco, cerca de 18% no gateway. O ponto é a estimativa da Coreto."}
```

**As duas estimativas estão longe do ponto de equilíbrio.** A chance de troca do banco teria de
triplicar, de 10% para 30%, antes de o adaptador se pagar. A do gateway poderia cair de 35% para
18%, e a interface ainda seria a escolha certa. Quando uma estimativa está tão longe da linha,
ninguém precisa discutir se ela está exatamente certa — e quando uma está perto da linha, o ponto de
equilíbrio avisa, e diz qual número ir conferir.

## Aceitar um aprisionamento de propósito

Aceitar o aprisionamento ao banco é uma decisão, e uma decisão não escrita parece, um ano depois,
exatamente um acidente. O Davi escreveu as duas, com o que as reabriria:

> **Banco de documentos gerenciado: aprisionamento aceito.** Trocar custaria R$ 210.000; pomos a
> chance em 10% em três anos, um custo esperado de R$ 21.000. Um adaptador custaria R$ 63.000.
> Revisitar se o provedor anunciar aumento de preço ou descontinuar o produto, ou se a chance de sair
> parecer maior que 30%.
>
> **Gateway de pagamento: pagar pela portabilidade.** Trocar custaria R$ 135.000; pomos a chance em
> 35%, um custo esperado de R$ 47.250. Uma interface de pagamento nossa e a exportação de cartões no
> contrato custam R$ 24.000. Vale a pena acima de 17,8% de chance de troca.

A aula 17 transforma notas como estas em registros de decisão de arquitetura (ADRs), que é onde um
aprisionamento aceito de propósito deve ficar.

## O que a planilha simplifica

A planilha trata a portabilidade como se ela eliminasse o custo de troca por inteiro. Não elimina:
com a interface de pagamento no lugar, sair do gateway ainda custa alguma coisa, só que bem menos.
Essa simplificação favorece a portabilidade. No gateway a margem é larga — R$ 24.000 contra um custo
esperado de R$ 47.250 —, então ela sobrevive; num caso perto do ponto de equilíbrio, estime quanto a
troca ainda custaria com a portabilidade no lugar, e compare com isso.
