---
title: O que um componente quer dizer
version: 1
---

Um componente é uma soma com pesos das colunas escaladas, e os pesos dele, as **cargas**, dizem o que ele
mede. O `pca.py` as imprimiu para os dois primeiros:

| coluna | primeiro | segundo |
|---|---|---|
| orders_month | 0,15 | **−0,45** |
| avg_basket | **0,42** | −0,16 |
| fruit | −0,30 | **0,54** |
| vegetables | −0,35 | **−0,44** |
| greens | −0,20 | **−0,52** |
| eggs_dairy | **0,45** | −0,01 |
| bakery | **0,47** | −0,02 |
| extras | 0,36 | 0,14 |

Leia cada coluna de pesos pelos números maiores, e pelos sinais.

**O primeiro componente é "padaria, laticínios e cestas grandes" contra "produtos frescos".** Padaria,
ovos e laticínios, extras e o tamanho da cesta pesam positivo; fruta, legumes e folhas pesam negativo. Um
cliente no extremo positivo dele compra pão, queijo e extras em pedidos grandes; no extremo oposto, sobretudo
produtos frescos.

**O segundo é "fruta" contra "legumes, folhas e pedidos frequentes".** Ele separa os dois tipos de
comprador de frescos que o primeiro componente juntava: o grupo da fruta da aula 16 e o grupo das folhas.

Então os dois componentes ficam perto de duas perguntas que a equipe de marketing faria de qualquer jeito,
e isso é sorte, não uma propriedade da PCA. Um componente é qualquer direção que tenha mais espalhamento, e
em outros dados pode ser uma mistura a que ninguém consegue dar nome. **O sinal também é arbitrário**:
outra execução, ou outra biblioteca, pode virar um componente de modo que todo peso troque de sinal, e ele
quer dizer exatamente o mesmo.

Essa é a vantagem real da PCA sobre os dois métodos que vêm a seguir: **os eixos dela podem ser lidos.**
Todo ponto num retrato da PCA tem uma posição que pode ser explicada em termos das colunas originais, e um
cliente novo pode ser posto pela mesma conta. Nenhuma das duas coisas vale para o t-SNE.
