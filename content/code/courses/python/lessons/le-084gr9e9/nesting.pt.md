---
title: Uma lista de dicionários, que é a cara de todo arquivo
version: 2
---

Contêineres guardam qualquer coisa, inclusive outros contêineres. Uma forma aparece mais que todas as
outras somadas:

```python
people = [
    {"name": "Ada", "city": "London", "langs": ["python", "c"]},
    {"name": "Bo",  "city": "Porto",  "langs": ["go"]},
]
```

**É isso que um arquivo JSON é** quando a aula 9 lê um, e no que um CSV vira com o `DictReader`, e o
que uma API devolve na aula 21. Ficar à vontade com isso agora paga o resto do curso.

## Alcançando

```python
>>> people[0]["city"]
'London'
>>> people[0]["langs"][1]
'c'
```

Da esquerda para a direita: a primeira pessoa, a cidade dela. Cada `[...]` é um degrau para baixo.

## As três perguntas que você vai fazer a isso

```python
# every city
cities = [p["city"] for p in people]

# the one with a given name
ada = next(p for p in people if p["name"] == "Ada")

# grouped by city
by_city = {}
for p in people:
    by_city.setdefault(p["city"], []).append(p)
```

A primeira é a compreensão da aula 4. A terceira é o idioma do `setdefault`, e o
`collections.defaultdict` da aula 7 é a mesma coisa com o padrão embutido.

## Onde dá errado

**Uma chave ausente no fundo da estrutura.** `p["address"]["city"]` levanta `KeyError` na primeira
metade, e o traceback diz `'endereco'` — que é a informação de que você precisa, então leia em vez de
adivinhar.

Para dados que não foram você que produziu, `p.get("address", {}).get("city")` responde `None` em
vez de levantar. A aula 9 tem a seção sobre JSON que não é seu, e a aula 14 tem `TypedDict`, que
deixa um verificador saber a forma de antemão.

**E não desça mais que uns três níveis.** A partir dali o aninhamento está guardando estrutura que
uma classe ou um `dataclass` deveria guardar, e a aula 6 é onde isso mora.
