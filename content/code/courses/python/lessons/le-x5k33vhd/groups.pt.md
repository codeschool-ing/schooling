---
title: Parênteses, e receber algo de volta
version: 1
---

```python
m = re.search(r"(\d{4})-(\d{2})-(\d{2})", linha)
m.group(0)      # a coincidência inteira
m.group(1)      # '2026'
m.groups()      # ('2026', '09', '21')
```

Parênteses CAPTURAM. O `group(0)` é tudo o que o padrão casou; o resto é numerado da esquerda para
a direita pelo parêntese que abre.

## Grupos com nome

```python
m = re.search(r"(?P<ano>\d{4})-(?P<mes>\d{2})", linha)
m["ano"]               # '2026'
m.group("mes")         # '09'
m.groupdict()          # {'ano': '2026', 'mes': '09'}
```

**Dê nome a eles no momento em que houver mais de dois.** O `m.group(3)` é um número que alguém
precisa contar achando o terceiro parêntese que abre, e inserir um grupo na frente renumera tudo
depois dele — em silêncio.

## Sem captura

```python
r"(?:https?)://(\S+)"
```

`(?:…)` agrupa sem capturar, que é o que você quer quando os parênteses estão ali pelo `?` ou pelo
`|` e não para recolher alguma coisa. Ele mantém estável a numeração dos grupos que você QUER.

## Um grupo que não participou

```python
m = re.match(r"(\+\d+ )?(\d+)", "5551234")
m.group(1)       # None, e não ''
```

Um grupo opcional que não estava lá dá `None`. `m.group(1) or ""` é a resposta de sempre, e
esquecer disso é um `AttributeError` em `None` algumas linhas depois.

## Alternância

```python
r"ERROR|WARN|INFO"
r"(?:ERROR|WARN|INFO)"        # quando é parte de algo maior
```

O `|` tem a MENOR precedência de tudo na linguagem, então `^ERROR|WARN$` quer dizer "começa com
ERROR" ou "termina com WARN" — quase nunca o que se queria. Ponha entre parênteses.
