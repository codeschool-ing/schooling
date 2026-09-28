---
title: Os padrões e os nomes na caixa
version: 1
---

Duas crenças chegam com quase todo mundo. Uma é que **o Wi-Fi 6 leva esse nome por causa da faixa de 6
GHz**, e a outra é que cada padrão novo substitui o anterior. Nenhuma das duas é verdade, e as duas
custam dinheiro: a primeira compra um roteador que não usa 6 GHz de jeito nenhum, e a segunda deixa uma
impressora velha atrasando uma rede que todo mundo acha que é nova.

Wi-Fi é um padrão só, o **IEEE 802.11**, publicado em 1997 com taxa máxima de 2 Mbit/s, e uma série de
emendas a ele, cada uma batizada com letras depois do número. O IEEE escreve as emendas. A Wi-Fi
Alliance, um grupo da indústria, testa os produtos contra elas e é dona do nome Wi-Fi. Em 2018 ela deu
números simples às emendas, e só voltou até o 802.11n: **Wi-Fi 4 é o 802.11n, Wi-Fi 5 é o 802.11ac,
Wi-Fi 6 é o 802.11ax**, e o Wi-Fi 7 veio depois, para o 802.11be. Chamar o 802.11b de "Wi-Fi 1" é
comum, e não é um nome oficial.

| emenda | nome | ano | faixas | canal mais largo | fluxos | taxa máxima no padrão |
|---|---|---|---|---|---|---|
| 802.11b | nenhum | 1999 | 2,4 GHz | 22 MHz | 1 | 11 Mbit/s |
| 802.11a | nenhum | 1999 | 5 GHz | 20 MHz | 1 | 54 Mbit/s |
| 802.11g | nenhum | 2003 | 2,4 GHz | 20 MHz | 1 | 54 Mbit/s |
| 802.11n | Wi-Fi 4 | 2009 | 2,4 e 5 GHz | 40 MHz | 4 | 600 Mbit/s |
| 802.11ac | Wi-Fi 5 | 2013 | 5 GHz | 160 MHz | 8 | 6,9 Gbit/s |
| 802.11ax | Wi-Fi 6 | 2021 | 2,4 e 5 GHz | 160 MHz | 8 | 9,6 Gbit/s |
| 802.11ax | Wi-Fi 6E | 2021 | acrescenta 6 GHz | 160 MHz | 8 | 9,6 Gbit/s |
| 802.11be | Wi-Fi 7 | 2024 | 2,4, 5 e 6 GHz | 320 MHz | 16 | 46 Gbit/s |

Duas colunas dessa tabela pedem uma palavra. O ano é o ano em que o IEEE publicou a emenda, e os
produtos vieram antes: a certificação Wi-Fi 6 abriu em 2019, bem antes de o 802.11ax ficar pronto.
E a taxa máxima é **um teto que o padrão escreve, nunca uma velocidade que alguém mede**. Ela supõe o
canal mais largo, o maior número de fluxos e um sinal limpo o bastante para a modulação mais densa, tudo
ao mesmo tempo. A seção sobre largura de canal calcula todas elas, do 802.11a em diante, a partir dos números
do próprio padrão, e a última seção desta aula diz quanto disso chega a um celular.

**O Wi-Fi 6E é o mesmo 802.11ax, autorizado numa terceira faixa**, e certificado desde 2021. Um
roteador Wi-Fi 6 sem 6E na caixa não transmite em 6 GHz, apesar do que o número sugere.

**Os padrões são compatíveis com os anteriores dentro de uma faixa.** Um ponto de acesso 802.11ax em 2,4
GHz ainda conversa com um cliente 802.11b de 1999, e em 5 GHz com um 802.11a. Só que na velocidade do
cliente antigo, usando o tempo de ar do cliente antigo, e é por isso que a última seção desta aula tem
uma impressora. A faixa de 6 GHz é a única exceção, e a próxima seção diz por que isso importa: nenhum
aparelho anterior ao Wi-Fi 6E entra nela, então não há nada antigo lá para esperar.
