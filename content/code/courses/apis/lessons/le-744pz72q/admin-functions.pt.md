---
title: Funções que só alguns podem chamar
version: 1
---

**Algumas operações não são sobre um objeto, e sim sobre a loja inteira, e a pergunta aí é se quem
chamou pode usar a função.** Listar todas as contas, trocar o papel de alguém, devolver dinheiro: a
OWASP chama a falta dessa checagem de **API5:2023 Broken Function Level Authorization**.

Ela aparece de alguns jeitos conhecidos. Endpoints administrativos ficam fora da documentação e do
menu, e são tidos como seguros porque ninguém sabe o endereço. Ficam embaixo de `/admin` e são
protegidos por uma checagem do prefixo do caminho, sem a qual uma rota foi acrescentada. Ou o mesmo
endereço aceita um GET de qualquer um e um DELETE pensado para funcionários, e só o GET foi checado.

No `orders.py` uma função é uma linha de `ROUTES`, e a linha nomeia a sua permissão. A Carla é
funcionária e a Dora é a administradora:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-carla' localhost:8000/admin/people
{"error": "the role staff lacks people:read"}
403
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-dora' localhost:8000/admin/people
[{"name": "ana", "role": "customer"}, {"name": "bruno", "role": "customer"}, {"name": "carla", "role": "staff"}, {"name": "dora", "role": "admin"}, {"name": "eva", "role": "auditor"}]
200
```

O 403 da Carla diz o que falta, e dizer isso é seguro. A função não é segredo, já que o documento
OpenAPI da aula 6 lista toda rota que uma API tem, e o nome da permissão é o que ela citaria ao
pedir acesso.

Uma função pode estar fora do alcance de quem é dono do objeto. O pedido 3 é do Bruno, e estorná-lo
continua não sendo tarefa dele:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3/refund
{"error": "the role customer lacks orders:refund"}
403
```

**A checagem de dono responde "de quem é?"; a autorização por função responde "isso é algo que o
seu tipo de usuário faz?"** O Bruno passa na primeira e falha na segunda, e nenhuma das duas
perguntas implica a outra.

O método faz parte da função. `ROUTES` não tem DELETE para um pedido, e o `do_DELETE` vai para o
mesmo `dispatch` que o resto. Então um DELETE da própria administradora não encontra porta aberta,
só um 405 e um cabeçalho `Allow` que nomeia o único método que esse endereço aceita:

```
ana@api:~/shelf$ curl -si -X DELETE -H 'Authorization: Bearer demo-dora' localhost:8000/orders/3
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 40
Allow: GET

{"error": "DELETE is not allowed here"}
```

Se o `do_DELETE` não estivesse definido, a biblioteca do Python teria respondido por ele com um 501
e uma página de HTML, como fez com `OPTIONS` na aula 1. Mandar todo método para uma função só é o
que faz da tabela de rotas a lista completa do que esta API faz.
