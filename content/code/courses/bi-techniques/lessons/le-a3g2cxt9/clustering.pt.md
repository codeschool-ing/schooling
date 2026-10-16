---
title: Deixar um algoritmo achar os grupos
version: 1
---

O **agrupamento por k-médias** (*k-means*) põe cada cliente num de k grupos de modo que os clientes de
um grupo fiquem o mais perto possível do centro do grupo. Ele recebe os números e o número de grupos,
e nada mais: nenhuma regra sobre o que é um bom cliente. Esse é o aprendizado não supervisionado a que
a aula 16 dá nome, e é o membro mais simples da família.

```schooling-example
{"language": "python", "file": "clusters.py", "parts": [{"code": "import numpy as np\nimport pandas as pd\nfrom sklearn.cluster import KMeans\nfrom sklearn.metrics import silhouette_score\nfrom sklearn.preprocessing import StandardScaler\n\nrfm = pd.read_csv(\"rfm.csv\", index_col=\"customer\")\nfeatures = np.log1p(rfm[[\"recency\", \"frequency\", \"monetary\"]])\nscaled = StandardScaler().fit_transform(features)", "note": "Os mesmos três números crus. O logaritmo deles doma as caudas longas, e a padronização dá a cada um a mesma dispersão, para o gasto em reais não pesar mais que a recência em dias só por ser maior."}, {"code": "print(\" k   inertia   silhouette\")\nfor k in range(2, 7):\n    model = KMeans(n_clusters=k, n_init=10, random_state=0).fit(scaled)\n    print(f\"{k:2} {model.inertia_:9.0f} {silhouette_score(scaled, model.labels_):12.3f}\")", "note": "k-médias para dois a seis grupos. A inércia é quão longe os clientes ficam do centro do seu grupo, e sempre cai conforme k cresce; a silhueta compara isso com quão longe eles ficam do grupo seguinte. O `random_state` fixa os pontos de partida, para o resultado se repetir."}, {"code": "model = KMeans(n_clusters=4, n_init=10, random_state=0).fit(scaled)\nrfm[\"cluster\"] = model.labels_\nprofile = rfm.groupby(\"cluster\").agg(customers=(\"recency\", \"size\"), recency=(\"recency\", \"median\"),\n                                     orders=(\"frequency\", \"median\"), spent=(\"monetary\", \"median\"))\nprint(\"\\nfour clusters, medians\")\nprint(profile.sort_values(\"spent\", ascending=False).round(0).to_string())", "note": "Quatro grupos, descritos pelas medianas dos números originais. O algoritmo numera os grupos ao acaso; a descrição é o que lhes dá nome."}], "output": " k   inertia   silhouette\n 2      6793        0.435\n 3      4660        0.395\n 4      3364        0.427\n 5      2679        0.395\n 6      2084        0.401\n\nfour clusters, medians\n         customers  recency  orders   spent\ncluster                                    \n0             1581      6.0    24.0  5066.0\n1             1413    155.0    12.0  2319.0\n3              718      5.0     6.0  1231.0\n2              967    275.0     3.0   480.0"}
```

## Escolher k

**Não há um número certo de grupos no dado**; há um número útil. Duas medidas ajudam.

- **A inércia** cai a cada grupo a mais, de 6.793 com dois a 2.084 com seis, porque mais centros ficam
  sempre mais perto. O sinal útil é um cotovelo, onde a queda desacelera; aqui ela é gradual.
- **A silhueta** fica entre −1 e 1, mais alta quando cada cliente está claramente mais perto do seu
  grupo que do seguinte. Ela tem o pico de 0,435 com dois grupos e o segundo melhor valor, 0,427, com
  quatro.

Dois grupos, "recentes" e "afastados", são a divisão estatisticamente mais limpa e grossa demais para
planejar quatro campanhas diferentes. Quatro são quase tão limpos e batem com o número de ações que a
Panela consegue tomar. **A pergunta do negócio escolhe o k dentro da faixa que o dado permite.**

## Ler os grupos

Os quatro grupos, pelas medianas, são reconhecíveis:

| grupo, por gasto | clientes | recência mediana | pedidos medianos | lê-se como |
|---|---|---|---|---|
| primeiro | 1.581 | 6 dias | 24 | regular, recente, o melhor |
| segundo | 1.413 | 155 dias | 12 | pedia com frequência, agora afastado |
| terceiro | 718 | 5 dias | 6 | recente, ainda ocasional |
| quarto | 967 | 275 dias | 3 | pediu poucas vezes, há muito tempo |

Eles ficam perto dos segmentos RFM: campeões, em risco, novos ou ocasionais, perdidos, com o "entre um
e outro" do RFM espalhado entre eles. **Essa concordância é o resultado que tranquiliza**: uma regra
escrita por uma pessoa e um algoritmo que não conhecia regra nenhuma acharam quase a mesma estrutura.
Quando os dois discordam muito, vale descobrir por quê antes de confiar em qualquer um.

## RFM ou agrupamento

| | regras RFM | k-médias |
|---|---|---|
| explicável | uma frase por segmento | uma tabela de medianas, nomeada depois |
| estável no tempo | as mesmas regras todo mês | os centros se mexem quando o dado se mexe |
| acha o inesperado | só o que as regras perguntam | estrutura para a qual ninguém escreveu regra |
| precisa de | uma pessoa para escrever as regras | padronização, uma escolha de k, uma pessoa para nomear os grupos |

A maioria dos times começa pelo RFM porque ele se explica numa reunião, e usa o agrupamento para
conferi-lo ou para explorar mais que três números, onde escrever regras à mão deixa de ser prático.
