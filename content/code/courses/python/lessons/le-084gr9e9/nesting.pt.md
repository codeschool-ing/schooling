---
title: Uma lista de dicionários, que é a cara de todo arquivo
version: 1
---

Contêineres guardam qualquer coisa, inclusive outros contêineres. Uma forma aparece mais que todas as
outras somadas:

```python
pessoas = [
    {"nome": "Ada", "cidade": "Londres", "langs": ["python", "c"]},
    {"nome": "Bo",  "cidade": "Porto",   "langs": ["go"]},
]
```

**É isso que um arquivo JSON é** quando a aula 9 lê um, e no que um CSV vira com o `DictReader`, e o
que uma API devolve na aula 21. Ficar à vontade com isso agora paga o resto do curso.

## Alcançando

```python
>>> pessoas[0]["cidade"]
'Londres'
>>> pessoas[0]["langs"][1]
'c'
```

Da esquerda para a direita: a primeira pessoa, a cidade dela. Cada `[...]` é um degrau para baixo.

## As três perguntas que você vai fazer a isso

```python
# todas as cidades
cidades = [p["cidade"] for p in pessoas]

# a que tem um certo nome
ada = next(p for p in pessoas if p["nome"] == "Ada")

# agrupadas por cidade
por_cidade = {}
for p in pessoas:
    por_cidade.setdefault(p["cidade"], []).append(p)
```

A primeira é a compreensão da aula 4. A terceira é o idioma do `setdefault`, e o
`collections.defaultdict` da aula 7 é a mesma coisa com o padrão embutido.

## Onde dá errado

**Uma chave ausente no fundo da estrutura.** `p["endereco"]["cidade"]` levanta `KeyError` na primeira
metade, e o traceback diz `'endereco'` — que é a informação de que você precisa, então leia em vez de
adivinhar.

Para dados que não foram você que produziu, `p.get("endereco", {}).get("cidade")` responde `None` em
vez de levantar. A aula 9 tem a seção sobre JSON que não é seu, e a aula 14 tem `TypedDict`, que
deixa um verificador saber a forma de antemão.

**E não desça mais que uns três níveis.** A partir dali o aninhamento está guardando estrutura que
uma classe ou um `dataclass` deveria guardar, e a aula 6 é onde isso mora.
