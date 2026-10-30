---
title: JSON entra, JSON sai, e as requisições recusadas
version: 1
---

O `@Serializable` em `Session` é tudo de que o plugin de serialização precisa: **ele gera, na compilação,
o código que transforma um `Session` em JSON e de volta**, sem reflexão em tempo de execução. O
`ContentNegotiation` é o plugin do Ktor que o usa, lendo o `Content-Type` da requisição e escolhendo o
formato.

Um POST leva uma sessão no corpo. O `-i` mostra a linha de status e os cabeçalhos da resposta:

```
ana@vm:~/kt/server$ curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{"course":"android-apps","minutes":30}'
HTTP/1.1 201 Created
Content-Length: 38
Content-Type: application/json

{"course":"android-apps","minutes":30}
ana@vm:~/kt/server$ curl -s -w '\n' localhost:8080/sessions
[{"course":"kotlin","minutes":45},{"course":"android-apps","minutes":30}]
```

`201 Created` é o status que o tratador escolheu, e o corpo é a sessão que ele recebeu, devolvida como
JSON. A lista agora tem duas entradas. Duas requisições com algo errado:

```
ana@vm:~/kt/server$ curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{"course":"kotlin","minutes":0}'
HTTP/1.1 400 Bad Request
Content-Length: 24
Content-Type: text/plain; charset=UTF-8

minutes must be positive
ana@vm:~/kt/server$ curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{"course":"kotlin"}'
HTTP/1.1 400 Bad Request
Content-Length: 64
Content-Type: text/plain; charset=UTF-8

Failed to convert request body to class studyplan.server.Session
```

A primeira chegou ao tratador: o JSON era um `Session` válido, e o `if` recusou zero minutos, como o
`WeekTotal` fez na lição 17. **A segunda nem chegou ao tratador.** Um corpo sem `minutes` não vira um
`Session`, que não tem valor padrão para ele, então o `receive` lançou exceção, e o Ktor respondeu `400`
por ela. Nada no `Server.kt` trata esse caso, e nada precisa: um `Int` não nulo sem valor padrão é um
campo que a requisição tem de trazer, e o tipo diz isso.

O `sessions` é um `MutableStateFlow`, mudado com `update`, pelo motivo que a lição 17 deu. O Ktor
responde requisições em várias threads ao mesmo tempo, e dois POSTs chegando juntos precisam ser os dois
contados. Um servidor de verdade guardaria a lista num banco de dados, não na memória, onde ela se perde
toda vez que o servidor para.

Pare o servidor com **Ctrl+C** no terminal dele.
