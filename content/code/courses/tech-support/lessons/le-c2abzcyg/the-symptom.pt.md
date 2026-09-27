---
title: Um sistema que parou de responder
version: 1
---

Às 01:09, várias pessoas das vendas relatam a mesma coisa: o sistema de vendas no navegador mostra um erro.
De um dos computadores delas:

```
ana@pc1:~$ date "+%H:%M"; curl -sS -o /dev/null -w "%{http_code}\n" http://srv1/sales/
01:09
502
```

**502** é o jeito de o servidor web dizer *estou aqui, e a coisa atrás de mim não respondeu*, a aula sobre
HTTP do curso de redes. Então o servidor web no `srv1` está no ar; aquilo para onde ele passa `/sales/` não
está. Muitos usuários e um sistema inteiro já são motivo para andar rápido, aula 6.
