---
title: Sessão: o cookie que não carrega o segredo
---

Guardar dados de verdade no cookie é má ideia — o usuário edita o que quiser. O padrão é o cookie carregar só um **identificador de sessão** aleatório, e o servidor guardar os dados associados a ele.

Daí a consequência que aparece no primeiro deploy sério: se a aplicação roda em dois servidores e a sessão está na memória de um deles, metade dos pedidos não encontra a sessão e o usuário "cai" aleatoriamente. Por isso sessão em produção mora em lugar compartilhado — Redis, banco — ou não existe, e o estado vai num token assinado.

Sair de verdade é invalidar a sessão **no servidor**. Apagar o cookie só some com a chave; se alguém tiver copiado o identificador antes, ele continua valendo.
