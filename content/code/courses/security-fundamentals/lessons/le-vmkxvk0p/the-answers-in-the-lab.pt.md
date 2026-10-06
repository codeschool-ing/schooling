---
title: As respostas no laboratório
version: 1
---

As páginas de holerite do portal são um exemplo pequeno e completo das duas verificações. Os pedidos
abaixo são mandados com `curl` do notebook do escritório. `-u nome:senha` manda um usuário e uma senha
com o pedido; `-i` pede ao `curl` que mostre a linha de status e os cabeçalhos da resposta além do
corpo, e `-w "%{http_code}\n"` imprime só o código de status.

### Nenhuma identidade

```
ana@laptop:~$ curl -si http://www.example.com/payslips/ana
HTTP/1.0 401 Unauthorized
WWW-Authenticate: Basic realm="staff"
Content-Type: text/plain
Content-Length: 14

sign in first
```

`401 Unauthorized` é o código do HTTP para "autenticação necessária", apesar do nome ("não
autorizado"). O cabeçalho `WWW-Authenticate` diz ao cliente como se autenticar: aqui, com usuário e
senha, o método chamado Basic. Uma senha errada recebe a mesma resposta:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -u ana:wrong-guess http://www.example.com/payslips/ana
401
```

O portal não diz se o usuário existe ou se a senha estava errada. A aula 9 volta ao porquê de isso
importar.

### Identidade provada, permissão conferida

```
ana@laptop:~$ curl -s -u ana:lab-ana-pass http://www.example.com/payslips/ana
payslip for ana, September 2026
ana@laptop:~$ curl -si -u ana:lab-ana-pass http://www.example.com/payslips/bruno
HTTP/1.0 403 Forbidden
Content-Type: text/plain
Content-Length: 18

not yours to read
```

A mesma ana, com a senha correta, recebe o próprio holerite e é recusada no do bruno. A recusa é
`403 Forbidden` ("proibido"): **o portal sabe exatamente quem pede e decidiu que a resposta é não.**
Essa é toda a diferença entre os dois códigos. O 401 diz "não sei quem você é"; o 403 diz "sei quem
você é, e você não pode".

### Um papel que muda a resposta

O bruno cuida do financeiro e está no grupo `hr`, e a regra do portal deixa `hr` ler qualquer holerite:

```
ana@laptop:~$ curl -s -u bruno:lab-bruno-pass http://www.example.com/payslips/ana
payslip for ana, September 2026
```

Mesma página, outra identidade, outra decisão. A autenticação fez o mesmo trabalho para os dois
usuários; a autorização chegou a respostas diferentes porque as regras tratam os papéis deles de forma
diferente.

### O que uma recusa revela

A loja não tem nenhuma funcionária chamada carla. Duas pessoas pedem o holerite dela:

```
ana@laptop:~$ curl -s -w "%{http_code}\n" -u ana:lab-ana-pass http://www.example.com/payslips/carla
not yours to read
403
ana@laptop:~$ curl -s -w "%{http_code}\n" -u bruno:lab-bruno-pass http://www.example.com/payslips/carla
no such payslip
404
```

A ana é recusada com 403 e o bruno ouve 404, "no such payslip" ("não existe esse holerite"). A
diferença é de propósito. A ana não pode ler o holerite de mais ninguém, então o portal a recusa
**antes** de conferir se o holerite existe. Se conferisse a existência primeiro, um 404 para carla e
um 403 para bruno diriam à ana quais nomes estão na folha, o que já é uma informação a que ela não
tem direito. O bruno pode ler qualquer holerite, então dizer a ele que um não existe não revela nada
que ele não pudesse ver de qualquer jeito.

### O registro

```
root@www:~# cat /var/log/lab/portal.log
192.168.10.20 - "GET /payslips/ana HTTP/1.1" 401 -
192.168.10.20 - "GET /payslips/ana HTTP/1.1" 401 -
192.168.10.20 ana "GET /payslips/ana HTTP/1.1" 200 -
192.168.10.20 ana "GET /payslips/bruno HTTP/1.1" 403 -
192.168.10.20 bruno "GET /payslips/ana HTTP/1.1" 200 -
192.168.10.20 ana "GET /payslips/carla HTTP/1.1" 403 -
192.168.10.20 bruno "GET /payslips/carla HTTP/1.1" 404 -
```

Cada linha do log tem o endereço, o usuário autenticado (ou `-` se não houve), a página e a resposta.
As duas primeiras linhas não têm nome, porque esses pedidos nunca se autenticaram. Toda linha depois
tem um, e é isso que permite a quem revisa o log dizer quem pediu o quê.
