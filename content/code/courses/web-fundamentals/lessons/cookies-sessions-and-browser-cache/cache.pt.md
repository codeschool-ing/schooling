---
title: Cache: não pedir de novo o que não mudou
---

O jeito mais rápido de carregar um arquivo é não carregá-lo. O **cache** guarda a resposta e a reutiliza enquanto ela valer, e quem manda nisso é o servidor, pelo `Cache-Control`.

`max-age=3600` diz "vale por uma hora, nem pergunte". `no-cache` diz "pode guardar, mas confirme antes de usar" — o navegador manda um pedido condicional e recebe `304 Not Modified` se nada mudou, o que economiza o corpo inteiro. `no-store` diz "não guarde", e é o certo para página de extrato bancário.

A tensão prática é entre cachear muito (rápido, mas o usuário vê a versão velha) e pouco (sempre atual, mas lento). A saída padrão é o **nome com impressão digital**: `app.9f2c1a.css` pode ser cacheado por um ano, porque qualquer alteração muda o nome do arquivo e o HTML passa a apontar para outro.
