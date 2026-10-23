---
title: Um viewset são cinco views
version: 1
---

O roteador registrou `events` sob dois padrões, e o viewset responde a cada método neles:

| método e endereço | o método do viewset | resposta |
|---|---|---|
| `GET /api/events/` | `list` | 200, uma página de eventos |
| `POST /api/events/` | `create` | 201, o evento novo |
| `GET /api/events/<slug>/` | `retrieve` | 200, um evento |
| `PUT`, `PATCH /api/events/<slug>/` | `update`, `partial_update` | 200, o evento alterado |
| `DELETE /api/events/<slug>/` | `destroy` | 204, nada |

## Escrever precisa de alguém

Ler era aberto. Uma escrita de um cliente anônimo:

```
ana@vm:~/agenda$ curl -si -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 45}" http://127.0.0.1:8000/api/events/django-night/ | sed -n "1p;\$p"; echo
HTTP/1.1 403 Forbidden
{"detail":"Authentication credentials were not provided."}
```

**403, `Authentication credentials were not provided.`** É o `IsAuthenticatedOrReadOnly`: um PATCH é
uma escrita. O DRF aceita **autenticação HTTP Basic** por padrão, um nome de usuário e uma senha num
cabeçalho, que o curl manda com `-u`. É o jeito mais rápido de testar, e a aula 11 a troca por tokens,
já que uma senha mandada em toda requisição só é aceitável por HTTPS, e olhe lá. Como a superusuária
da aula 5:

```
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 45}" http://127.0.0.1:8000/api/events/django-night/ | python3 -m json.tool
{
    "slug": "django-night",
    "title": "Django Night",
    "starts_at": "2026-11-12T19:00:00-03:00",
    "venue": "Community Centre, room 3",
    "capacity": 45,
    "description": "",
    "taken": 1
}
```

Um `PATCH` muda só os campos que manda: o Django Night agora tem 45 lugares. Um evento novo é um POST
na lista, e removê-lo é um DELETE no endereço dele:

```
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X POST -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"PyCon talks, watched together\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"Public Library, lab 2\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/
{"slug":"pycon-watch","title":"PyCon talks, watched together","starts_at":"2026-12-03T19:00:00-03:00","venue":"Public Library, lab 2","capacity":15,"description":""}
201
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X DELETE -w "%{http_code}\n" http://127.0.0.1:8000/api/events/pycon-watch/
204
```

**201 Created** com o evento novo, e **204 No Content** para a exclusão: as respostas da API levam o
significado no código de status, então um cliente pode agir sem ler o corpo. O evento criado não tem
`taken`, pelo motivo que a seção de serializers deu: ele voltou do `save()`, não do queryset anotado.

## Quando não usar um viewset

O endpoint de inscrição é uma função, porque é uma ação que não cabe em cinco verbos padrão sobre um
recurso. Um viewset para algo que não é uma coleção de linhas produz rotas que ninguém deveria chamar;
uma função, ou a classe `APIView` do DRF, diz exatamente o que existe.
