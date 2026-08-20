---
title: Cookies: a memória que o HTTP não tem
---

HTTP não lembra de nada: cada pedido chega como se fosse o primeiro. O **cookie** é a gambiarra que virou fundação — o servidor manda um `Set-Cookie` e o navegador devolve aquele valor em todo pedido seguinte para aquele domínio.

Os atributos são o que separa cookie seguro de problema de segurança. `HttpOnly` impede o JavaScript da página de ler o valor, o que limita o estrago de um XSS. `Secure` impede o envio fora do HTTPS. `SameSite` controla se o cookie viaja em pedidos que partem de outro site, que é a defesa contra CSRF.
