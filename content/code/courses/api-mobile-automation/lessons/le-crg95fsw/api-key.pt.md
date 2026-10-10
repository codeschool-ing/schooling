---
title: Uma chave de API, e as três requisições que a testam
version: 1
---

**Uma chave de API é um segredo fixo que um programa manda em toda requisição para dizer qual
programa ele é.** É a credencial mais simples que existe: sem login, sem expiração, uma string
combinada com antecedência. O boxoffice protege um endereço com uma chave, o relatório de vendas do
teatro em `/v1/reports/sales`, e a espera num cabeçalho chamado `X-Api-Key`.

A crença que vale abandonar é a de que uma chave diz *quem* está pedindo. Ela diz *qual programa*,
ou qual cópia de um arquivo de configuração. Toda pessoa e todo script que tem a string é o mesmo
chamador para o servidor, então uma chave não distingue o gerente da bilheteria de um script em que
alguém a copiou no ano passado. Por isso chaves servem para um relatório que poucos programas
internos leem, e por isso o boxoffice não usa uma para pedidos, onde importa qual cliente fez qual
pedido.

## Três requisições

Uma chave se testa com pelo menos três requisições: nenhuma, uma errada, a certa. Primeiro sem
chave, com `-i` para ver os cabeçalhos:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/reports/sales
HTTP/1.1 401 Unauthorized
content-type: application/problem+json
Date: Sat, 10 Oct 2026 19:43:07 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"type":"about:blank","title":"Unauthorized","status":401,"detail":"send the staff key in X-Api-Key"}
```

Um `401` e um corpo de problema que diz o que mandar, o que está certo. Falta um cabeçalho, porém.
**Um `401` deve trazer um cabeçalho `www-authenticate` dizendo como se autenticar** (RFC 9110, §15.5.2), e este não traz nenhum. Os pedidos mandam esse cabeçalho, como a seção 05 mostra,
então o relatório é o ponto fora da curva. É um defeito pequeno e real: uma biblioteca cliente que lê
o cabeçalho para decidir que credencial mandar não tem o que ler. Registre.

Depois uma chave errada e a certa:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/reports/sales -H 'X-Api-Key: guess'
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"send the staff key in X-Api-Key"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/reports/sales -H 'X-Api-Key: lab-only-staff-key'
{"orders":0,"seats":0,"revenue_cents":0}
```

A chave errada recebe a mesma resposta que nenhuma chave, palavra por palavra. **Essa igualdade está
certa**: um servidor que dissesse *"chave não reconhecida"* para uma e *"chave ausente"* para a
outra contaria a um estranho quais palpites chegaram perto de ser uma chave. A chave certa recebe o
relatório, ainda sem nada vendido.

## Por que num cabeçalho, e não no endereço

Algumas APIs aceitam a chave na query string, `?key=…`, porque é fácil de colar num navegador. O
boxoffice não aceita, e pedir assim é recusado:

```
ana@laptop:~/boxoffice$ curl -s 'localhost:8080/v1/reports/sales?key=lab-only-staff-key'
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"send the staff key in X-Api-Key"}
```

A recusa não é a parte interessante. Olhe o segundo terminal, onde o boxoffice registra toda
requisição que responde:

```
GET /v1/reports/sales?key=lab-only-staff-key 401
```

**A chave está no log, em texto puro.** O log do boxoffice escreve o método, o endereço e o status,
que é o que quase todo servidor web, proxy e balanceador de carga registra por padrão; um endereço
também vai para o histórico do navegador e para o cabeçalho `Referer` mandado a outros sites. Um
cabeçalho não é registrado a menos que alguém escolha registrá-lo. Então o teste que quem testa
acrescenta não é só "a chave funciona no cabeçalho", mas **"a chave não funciona no endereço"**,
porque uma API que a aceitasse ali convidaria todo cliente a vazá-la.
