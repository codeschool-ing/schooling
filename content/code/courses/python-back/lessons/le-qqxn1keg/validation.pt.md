---
title: Validação que conhece outras linhas
version: 1
---

As conferências de um campo veem um valor. O `validate_capacity` do serializer vê o evento também, e
recusa uma capacidade abaixo do número de pessoas já inscritas. O Testing dojo tem duas:

```
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 1}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/
{"capacity":["2 people are already registered."]}
400
```

**400, com a mensagem do `validate_capacity`**, sob o nome do campo, para um cliente poder pô-la ao
lado do input. E um valor do tipo errado nem chega a esse método:

```
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": \"forty\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/
{"capacity":["A valid integer is required."]}
400
```

## Onde cada conferência pertence

| conferência | onde | exemplo |
|---|---|---|
| um valor, o tipo e a faixa dele | o campo do modelo, que o serializer copia | `capacity` é um inteiro não negativo |
| um valor contra outras linhas | `validate_<campo>` | capacidade não abaixo das inscrições |
| vários campos juntos | `validate(self, attrs)` | uma data de fim depois de uma de começo |
| uma regra que precisa valer com escritas simultâneas | o banco, ou um serviço com trava | uma inscrição por endereço; a capacidade de um evento |

A última linha é a que vale lembrar. A conferência de um serializer roda numa requisição e pode ser
atropelada por outra, exatamente como a contagem da aula 3; **o endpoint de inscrição por isso chama o
serviço da aula 4** em vez de contar no serializer, e essa é a próxima seção.
