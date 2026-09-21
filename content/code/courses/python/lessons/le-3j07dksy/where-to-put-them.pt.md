---
title: A fronteira, e a anotação que não diz nada
version: 1
---

## Em ordem

1. **Funções públicas** — as que outro módulo chama. A assinatura é o contrato, e é aqui que quem
   lê olha primeiro.
2. **Qualquer coisa que receba ou devolva uma coleção** — um `list` sozinho não diz nada sobre o
   que tem dentro, e `list[Linha]` diz tudo.
3. **Qualquer coisa que possa devolver `None`** — o defeito que paga a aula inteira de volta.
4. **Todo o resto, com o tempo**, e só se ajudar.

## As que não precisam de nada

```python
def _slug(titulo: str) -> str:
    return titulo.lower().replace(" ", "-")     # anotada assim mesmo: é uma fronteira de uma linha

def _chave(linha):
    return linha["cidade"]                      # uma chave de `sorted`, três linhas do uso dela
```

Um ajudante privado de duas linhas usado uma vez, ao lado de quem o chama, se entende lendo. Um
verificador deduz quase tudo dele de qualquer jeito.

## A anotação que não diz nada

```python
def analisar(dados: dict) -> dict: ...
def processar(itens: list) -> list: ...
def tratar(carga: Any) -> Any: ...
```

Cada uma dessas é a forma de uma mentira por omissão: parece anotada, então ninguém olha mais
fundo, e ela não afirma nada que um verificador possa usar. **Uma anotação vazia é pior que
nenhuma**, porque a ausência ao menos diz que ninguém passou por ali.

## Variáveis em geral não precisam

```python
linhas = []                 # o verificador não tem como saber o que entra
linhas: list[Linha] = []    # agora tem
total = 0                   # óbvio; deixe
```

Anote o contêiner vazio e aquele cujo tipo não está visível na linha. Todo o resto é ruído.

## Aos poucos, e de fora para dentro

Anote a superfície pública do módulo, rode o verificador, conserte o que ele achar, e desça uma
camada. **Essa ordem acha mais defeitos por hora**, porque a parte de fora é onde as suposições
erradas se encontram.

E um arquivo anotado pela metade não está quebrado pela metade. Esse é o projeto inteiro do
sistema: `Any` onde nada foi afirmado, e conferência onde algo foi.
