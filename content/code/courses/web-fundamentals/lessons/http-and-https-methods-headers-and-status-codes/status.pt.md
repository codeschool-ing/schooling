---
title: Códigos de status: as cinco famílias
---

A resposta começa com um número de três dígitos, e o primeiro dígito já classifica:

- **1xx** — informativo, raro no dia a dia.
- **2xx** — deu certo. `200 OK`, `201 Created`, `204 No Content`.
- **3xx** — está em outro lugar. `301` permanente, `302` temporário, `304` não mudou desde a última vez.
- **4xx** — o pedido está errado. `400` malformado, `401` não autenticado, `403` autenticado mas sem permissão, `404` não existe, `429` pedindo demais.
- **5xx** — o servidor falhou. `500` erro interno, `502` o servidor de trás respondeu mal, `503` fora do ar, `504` o servidor de trás não respondeu a tempo.

A fronteira que mais se erra é 4xx contra 5xx: **4xx é culpa de quem pediu, 5xx é culpa de quem responde**. E `401` contra `403`: o primeiro diz "não sei quem você é", o segundo diz "sei quem você é, e você não pode".
