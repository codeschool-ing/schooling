---
title: Paginação, e filtrar a lista
version: 1
---

Uma lista que devolve todas as linhas funciona com três eventos e falha com trinta mil: a resposta
cresce, a consulta cresce, e um cliente mobile espera dados que nunca vai mostrar. A configuração pediu
páginas de dois:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/ | python3 -m json.tool
{
    "count": 3,
    "next": "http://127.0.0.1:8000/api/events/?page=2",
    "previous": null,
    "results": [
        {
            "slug": "django-night",
            "title": "Django Night",
            "starts_at": "2026-11-12T19:00:00-03:00",
            "venue": "Community Centre, room 3",
            "capacity": 40,
            "description": "",
            "taken": 1
        },
        {
            "slug": "async-workshop",
            "title": "Async Python workshop",
            "starts_at": "2026-11-19T14:00:00-03:00",
            "venue": "Public Library, lab 2",
            "capacity": 12,
            "description": "",
            "taken": 12
        }
    ]
}
```

A página vem embrulhada num objeto: **`count`**, o total de todas as páginas; **`next`** e
**`previous`**, endereços completos que um cliente segue sem precisar montá-los; e **`results`**, as
linhas desta página. A lista saiu em ordem de data porque o `get_queryset` diz `order_by("starts_at")`,
o que importa aqui mais que em qualquer lugar: **páginas sobre uma consulta sem ordem podem repetir uma
linha em duas páginas ou pular uma**, e o DRF avisa no log do servidor quando pagina uma assim. A
segunda página:

```
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/api/events/?page=2" | python3 -m json.tool
{
    "count": 3,
    "next": null,
    "previous": "http://127.0.0.1:8000/api/events/",
    "results": [
        {
            "slug": "testing-dojo",
            "title": "Testing dojo",
            "starts_at": "2026-11-26T19:00:00-03:00",
            "venue": "Community Centre, room 3",
            "capacity": 20,
            "description": "",
            "taken": 2
        }
    ]
}
```

O `next` é `null`: não há terceira página.

## Filtrar

O `get_queryset` lê `venue` da query string e filtra antes de paginar, então o `count` é a contagem da
lista filtrada:

```
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/api/events/?venue=Public%20Library,%20lab%202" | python3 -m json.tool | head -4
{
    "count": 1,
    "next": null,
    "previous": null,
```

Um evento na biblioteca. O padrão serve para todo filtro de que a API precisar, e o **django-filter**
é a biblioteca que os declara em vez de escrever um `if` por parâmetro, com integração ao DRF pronta.

## Números de página, ou um cursor

| | como um cliente pede | custo |
|---|---|---|
| `PageNumberPagination` | `?page=2` | um `COUNT(*)` por requisição, e `OFFSET`, que lê e joga fora as linhas anteriores |
| `LimitOffsetPagination` | `?limit=20&offset=40` | o mesmo |
| `CursorPagination` | um `?cursor=…` opaco vindo do `next` | sem contagem e sem offset: pede as linhas depois da última vista |

Números de página são o que as pessoas esperam numa tela. Para um feed que só anda para a frente, ou
uma tabela de milhões, o cursor é o que continua rápido, ao preço de não poder pular para a página 50.
