---
title: Nunca cobrado por nada
version: 1
---

Planejar as falhas desta aula revelou um defeito que toda aula desde a 8 carregava. A venda cobrava o
comprador primeiro e depois rodava o `UPDATE ... WHERE sold < capacity` que acha um lugar. Num show
esgotado, o `UPDATE` não achava nenhum e a venda respondia `409 Sold out`, **depois de o comprador ter
sido cobrado**. Isso nunca apareceu numa captura porque nenhum show do laboratório tinha esgotado.

A bilheteria agora pergunta ao primário quantos lugares sobram antes de cobrar, e recusa um show
esgotado sem cobrar nada. Esgote o show 7 à mão, e tente:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'UPDATE events SET sold = capacity WHERE id = 7'
UPDATE 1
ana@lab:~/tickets$ curl -s localhost:8001/charges; echo
{"charged": 0}
ana@lab:~/tickets$ curl -s -X POST -H 'X-Buyer: fan-20' localhost:8080/events/7/tickets; echo
{"error": "sold out"}
ana@lab:~/tickets$ curl -s localhost:8001/charges; echo
{"charged": 0}
```

`409`, e a contagem do payments não se mexeu.

A verificação estreita a janela sem fechá-la. Entre a verificação e o `UPDATE`, outra pessoa pode
levar o último lugar: dois compradores veem um lugar sobrando, os dois são cobrados, e um fica com o
lugar. A bilheteria agora registra esse caso como erro, *charged but sold out*, porque alguém precisa
reembolsar aquele comprador. Fechar a janela de vez quer dizer mudar a ordem: **reservar o lugar
primeiro**, com prazo, **depois cobrar**, depois confirmar a reserva, e liberá-la se a cobrança falhar.
Cada passo é desfeito por um passo de compensação se um passo seguinte falhar, que é o padrão chamado
**saga**. É assim que funcionam de fato a venda de ingressos, as viagens e todo negócio que vende algo
escasso por meio de um pagamento que não controla.

A lição geral é sobre caminhos degradados. **Um caminho de falha que ninguém rodou é um caminho de
falha que não foi testado**, e o caminho do esgotado não tinha sido rodado nenhuma vez em oito aulas.
