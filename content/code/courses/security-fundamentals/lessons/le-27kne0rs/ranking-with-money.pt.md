---
title: Ordenando riscos com dinheiro
version: 1
---

Uma avaliação quantitativa troca as palavras por uma quantia esperada de perda por ano. Ela dá mais
trabalho e exige mais dados, e em troca responde à pergunta que a matriz não responde: **este
controle vale o que custa?**

As grandezas, definidas nesta ordem:

| nome | o que é | como se acha |
|---|---|---|
| **AV**, valor do ativo | quanto o ativo vale para o negócio | a estimativa do dono |
| **EF**, fator de exposição | a fração desse valor que um incidente destrói | de 0 a 1 |
| **SLE**, expectativa de perda única | quanto custa um incidente | **SLE = AV × EF** |
| **ARO**, taxa anualizada de ocorrência | quantas vezes por ano se espera que aconteça | histórico, ou dados do setor |
| **ALE**, expectativa de perda anualizada | quanto este risco custa por ano, em média | **ALE = SLE × ARO** |

As siglas vêm do inglês e é assim que aparecem nas normas e nas provas de certificação, então o
curso as mantém.

### Notebooks

O R3 da seção anterior, calculado. Um notebook mais o dia que leva para preparar o substituto valem
R$ 7.000 para a loja, e um notebook perdido se perde inteiro, então o fator de exposição é 1. A loja
perde um notebook mais ou menos uma vez a cada dois anos, então a ARO é 0,5:

| | |
|---|---|
| SLE | R$ 7.000 × 1 = R$ 7.000 |
| ALE | R$ 7.000 × 0,5 = **R$ 3.500 por ano** |

Isso não quer dizer que a loja perde R$ 3.500 todo ano. Quer dizer que, ao longo de muitos anos, a
média dá isso, e é um teto razoável para o que gastar por ano para diminuir o problema.

### Ransomware

O R2 é mais raro e muito pior. Restaurar os sistemas da loja do zero, mais as vendas perdidas
enquanto isso, põem em jogo R$ 80.000. Com o backup só no mesmo servidor, um ataque destruiria mais
ou menos metade desse valor, então o EF é 0,5. A oficina estimou um evento desses em dez anos, então
a ARO é 0,1:

| | |
|---|---|
| SLE | R$ 80.000 × 0,5 = R$ 40.000 |
| ALE | R$ 40.000 × 0,1 = **R$ 4.000 por ano** |

Agora um controle: um backup offline, guardado onde o servidor não consegue escrever, custa
R$ 1.500 por ano. Com ele, um ataque destrói só o trabalho desde o último backup, e o fator de
exposição cai para 0,05:

| | |
|---|---|
| SLE nova | R$ 80.000 × 0,05 = R$ 4.000 |
| ALE nova | R$ 4.000 × 0,1 = R$ 400 por ano |

O controle vale **a perda que ele elimina menos o que ele custa**:

> R$ 4.000 − R$ 400 − R$ 1.500 = **R$ 2.100 por ano a favor da loja**

Então a loja compra. Se o mesmo backup custasse R$ 5.000 por ano, a conta diria que o controle
custa mais que o risco, e a resposta honesta seria um controle mais barato ou a decisão de aceitar.

### De onde vêm os números

**A precisão do resultado é a precisão da pior entrada.** Uma ARO de 0,1 para ransomware é um
palpite com uma faixa, não uma medida. A análise quantitativa merece o lugar porque obriga esses
palpites a aparecer, onde dá para discuti-los e melhorá-los, e porque deixa explícita a comparação
com o custo do controle. Ela não transforma um palpite em fato.

Na prática, a maioria das organizações usa as duas: a matriz para ordenar tudo depressa, e o
dinheiro para o punhado de riscos em que há uma decisão grande de gasto na mesa. A aula 10 de
`threat-modeling` trata do FAIR, um método quantitativo mais rigoroso que trabalha com faixas em vez
de números únicos.
