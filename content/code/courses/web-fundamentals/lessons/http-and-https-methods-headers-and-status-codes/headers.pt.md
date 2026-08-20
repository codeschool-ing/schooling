---
title: Cabeçalhos: os metadados da conversa
---

Pedido e resposta carregam **cabeçalhos** — pares de nome e valor que descrevem o conteúdo e as condições, sem fazer parte dele.

No pedido, os que mais aparecem são `Host` (qual site, já que um servidor hospeda vários), `Accept` (que formatos servem), `Authorization` (a credencial) e `Cookie`. Na resposta, `Content-Type` (o que é isto), `Cache-Control` (por quanto tempo guardar) e `Set-Cookie`.

`Content-Type` errado é uma das causas mais comuns de "funciona no meu servidor e não no outro": o mesmo arquivo servido como `text/plain` em vez de `text/css` faz o navegador recusar a folha de estilo, e a página aparece sem estilo nenhum, sem erro visível.
