---
title: Métodos: o verbo do pedido
---

Todo pedido HTTP começa por um verbo que diz a intenção. Os que aparecem sempre:

- `GET` — me dê. Não deve alterar nada no servidor.
- `POST` — tome isto, e crie ou processe algo.
- `PUT` — substitua o recurso por isto.
- `PATCH` — altere só estes campos.
- `DELETE` — remova.

A promessa de que `GET` não altera nada não é formalidade. Navegadores, proxies e buscadores repetem `GET` à vontade — pré-carregam links, revalidam cache, rastreiam páginas. Uma aplicação que apagasse um registro via `GET` seria esvaziada pelo próprio rastreador do Google, e já aconteceu com gente grande.
