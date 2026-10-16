---
title: A cadeia de suprimentos por trás da prateleira
version: 1
---

O gancho vazio no corredor de jardim não foi culpa do comprador, nem do depósito. Ele começou três
semanas antes, num fornecedor. **A prateleira é o último elo de uma cadeia**, e os indicadores que
importam para os fornecedores de um varejista são os que preveem uma prateleira vazia antes de ela
acontecer: quanto tempo o fornecedor leva, se manda tudo o que foi pedido e se manda no dia que
prometeu.

## Três indicadores, um fornecedor

O enrolador de mangueira vem de um único fornecedor, e a Varanda faz um pedido de compra a ele a
cada uma ou duas semanas. Lívia tirou do ERP, o sistema em que ficam registradas as compras, o
estoque e as vendas da Varanda, os oito pedidos de agosto a outubro de 2025: as unidades pedidas,
as unidades recebidas e os dias de atraso em relação à data que o fornecedor prometeu. Um 0 quer
dizer no prazo ou antes.

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Pedido | Pedidas | Recebidas | Dias de atraso |
| 2 | PO 1 | 120 | 120 | 0 |
| 3 | PO 2 | 120 | 114 | 0 |
| 4 | PO 3 | 150 | 150 | 2 |
| 5 | PO 4 | 150 | 150 | 0 |
| 6 | PO 5 | 120 | 120 | 9 |
| 7 | PO 6 | 120 | 108 | 0 |
| 8 | PO 7 | 150 | 150 | 0 |
| 9 | PO 8 | 150 | 150 | 4 |

O relatório do próprio fornecedor para a Varanda cita a sua **taxa de atendimento** (*fill rate*):
unidades recebidas sobre unidades pedidas. Na linha 10, os totais de B e C, e depois a taxa:

```localised
=SOMA(B2:B9)      1080
=SOMA(C2:C9)      1062
=ARRED(C10/B10*100;1)      98,3
```

98,3% parece um fornecedor confiável. Agora pergunte sobre cada pedido, e não sobre cada unidade.
Em E1 digite `Completo`, em F1 `No prazo` e em G1 `OTIF`; na linha 2, e copiado para baixo:

```localised
=SE(C2>=B2;1;0)      1
=SE(D2<=0;1;0)      1
=E2*F2      1
```

O **OTIF** (*on time in full*, no prazo e completo) só conta um pedido como bom quando ele chegou
completo e no prazo; multiplicar as duas marcas dá 1 só quando as duas são 1. Some as três colunas
na linha 10 e divida cada uma pelos oito pedidos:

```localised
=ARRED(E10/8*100;1)      75
=ARRED(F10/8*100;1)      62,5
=ARRED(G10/8*100;1)      37,5
```

**Taxa de atendimento de 98,3%, OTIF de 37,5%**, para os mesmos oito pedidos. As duas estão certas.
A primeira conta unidades, então seis enroladores faltando em 120 quase não a mexem, e ela nem olha
para datas. A segunda conta pedidos, e cinco dos oito falharam num teste ou no outro. **O
fornecedor escolhe informar a primeira, e o varejista precisa medir a segunda.**

## De um pedido atrasado a uma prateleira vazia

O PO 5 chegou com nove dias de atraso. Era o pedido que devia chegar antes do pico da temporada de
jardim, e a página de estoque desta aula mostra o que aconteceu no meio: o enrolador ficou na
prateleira 18 dos 28 dias, e a estimativa de vendas perdidas nos outros dez foi de 47 enroladores,
R$ 13.583.

Essa ligação é o achado útil. **O atraso médio do fornecedor ficou abaixo de dois dias**, e ninguém
cobraria isso. O que esvaziou a prateleira foi o único pedido que chegou nove dias atrasado. A aula
9 montou um ponto de pedido a partir da demanda diária e do prazo de entrega do fornecedor. Um
prazo que quase sempre é cumprido e de vez em quando atrasa nove dias pede mais estoque de
segurança do que a média sugere, e a regra de reposição só sabe disso se alguém medir a dispersão
além da média.

## O que esses dados têm de estranho

Os dados de suprimentos vêm de dois registros que não foram feitos um para o outro. O pedido de
compra é digitado quando o comprador faz o pedido, com a data que o fornecedor prometeu. O
recebimento é digitado quando o depósito confere a entrega. **A data do recebimento é o dia em que
alguém a digitou, que nem sempre é o dia em que o caminhão chegou**: uma entrega que chega ao
depósito de Contagem no fim da tarde de sexta pode ser conferida na segunda e contar como três dias
de atraso. Antes de avaliar um fornecedor por OTIF, a Varanda precisa decidir se "no prazo" quer
dizer na porta do depósito ou no sistema, e se quer dizer a data prometida ou a data que a Varanda
pediu. Dois varejistas podem dar notas diferentes ao mesmo fornecedor pelas mesmas entregas, e cada
um está certo pela sua própria regra escrita.

Caio Barreto, o diretor de operações, levou o OTIF à reunião trimestral com o fornecedor. A taxa de
atendimento era o slide do fornecedor; o OTIF era o da Varanda, com o PO 5 e os dez dias de
prateleira vazia ao lado.
