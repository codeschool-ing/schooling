---
title: Aprendizado não supervisionado, sem resposta para aprender
version: 1
---

**Aprendizado não supervisionado recebe linhas e nenhuma resposta.** Ele encontra a estrutura que as
linhas têm por conta própria: grupos de membros parecidos entre si, umas poucas direções ao longo das
quais corre a maior parte da variação, as linhas que não se parecem com nada. Ninguém lhe diz o que é
um bom grupo, então ninguém pode lhe dizer que ele errou um.

Essa última frase é a que vale guardar. Um modelo supervisionado tem uma nota, porque as respostas
dele podem ser comparadas com as reais. Um resultado não supervisionado não tem resposta real para
comparar, então **se ele é útil é decidido por alguém que o lê**, e duas rodadas com ajustes
diferentes podem estar ambas "certas".

## Quatro grupos de membros

O método não supervisionado mais comum é o **k-means**: escolha um número de grupos, `k`, e ele move
`k` centros até que cada membro fique com o mais próximo e cada centro fique no meio dos seus
membros. Salve isto como `unsupervised.py`:

```python
"""unsupervised.py: group members by how they buy, with no answer to learn from."""
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

import features

COLUMNS = ["recency_days", "visits_180d", "spend_180d"]

members = features.build("2025-11-30")
scaled = StandardScaler().fit_transform(members[COLUMNS])
members["group"] = KMeans(n_clusters=4, n_init=10, random_state=0).fit_predict(scaled)

summary = members.groupby("group").agg(
    members=("member_id", "count"),
    recency_days=("recency_days", "median"),
    visits_180d=("visits_180d", "median"),
    spend_180d=("spend_180d", "median"),
    lapsed=("lapsed", "mean"),          # never shown to KMeans: read afterwards
)
print(summary.round(2).to_string())
```

**O `StandardScaler` vem primeiro por um motivo que é pura aritmética.** O k-means mede distância, e
`spend_180d` está em centavos, chegando a seis dígitos, enquanto `visits_180d` chega a uns vinte. Sem
escala, uma diferença de uma visita pesaria menos que uma diferença de um centavo, e os grupos seriam
grupos só por gasto. A escala põe cada coluna no mesmo pé: a média vira 0 e uma dispersão típica
vira 1.

```
ana@dev:~/ml$ python unsupervised.py
       members  recency_days  visits_180d  spend_180d  lapsed
group                                                        
0          382           9.0         14.0    133790.0    0.05
1          451         109.0          2.0     19970.0    0.53
2         1064          14.0          8.0     77870.0    0.09
3         1233          22.0          4.0     32940.0    0.15
```

Os grupos têm números e não nomes, porque o k-means não dá nome a nada. Lendo as medianas, uma pessoa
os chamaria de algo como:

| grupo | o que as medianas dizem | um nome que uma pessoa daria |
| --- | --- | --- |
| 0 | veio há 9 dias, 14 visitas, R$ 1.337,90 | os frequentes |
| 1 | veio há 109 dias, 2 visitas | os que estão sumindo |
| 2 | veio há 14 dias, 8 visitas | os constantes |
| 3 | veio há 22 dias, 4 visitas | os ocasionais |

**A última coluna nunca foi mostrada ao k-means.** `lapsed` veio junto na tabela, e o programa só a
lê depois que os grupos existem. Ela diz que 53% do grupo 1 se afastou nos 90 dias seguintes, contra
5% do grupo 0, então os grupos acharam algo real sobre os membros. Essa verificação só foi possível
porque esta loja por acaso tem um rótulo; a maior parte do trabalho não supervisionado não tem
nenhum, e a leitura da tabela acima é tudo o que existe.

## Para que isso serve numa plataforma

Segmentos assim vão para um painel, para uma lista de campanha, ou **para outro modelo como
atributo**: "grupo 1" é uma coluna que resume três. A lição 2 usa agrupamento como uma das quatro
tarefas comuns, e a lição 10 encontra outra ideia não supervisionada, comparar a distribuição das
linhas de hoje com as do mês passado, que também dispensa rótulo.
