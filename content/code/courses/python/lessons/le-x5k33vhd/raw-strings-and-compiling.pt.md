---
title: `r""`, e o padrão usado num laço
version: 1
---

```python
re.search("\\d+", s)       # o que o Python passa: \d+
re.search(r"\d+", s)       # o mesmo, sem a duplicação
```

Uma barra invertida é um escape para o Python ANTES de o padrão chegar ao `re`. Sem o `r`, toda
barra no padrão precisa ser escrita duas vezes — e no dia em que você esquecer, `"\b"` é um
caractere de backspace e não uma fronteira de palavra, e o padrão casa nada em silêncio.

**Escreva todo padrão como string crua, inclusive os que ainda não têm barra nenhuma.** O que você
acrescenta depois é o que quebra.

O mesmo vale para a SUBSTITUIÇÃO no `sub`, onde o `\1` tem o mesmo problema.

## `re.compile`

```python
LINHA = re.compile(r"(?P<ts>\S+) (?P<nivel>\w+) (?P<msg>.*)")

for linha in f:
    m = LINHA.match(linha)
```

Um padrão compilado é um objeto com os mesmos métodos — `search`, `match`, `findall`, `sub`. Duas
razões para usá-lo:

- **o padrão ganha um nome**, no topo do arquivo, onde quem lê o encontra
- **as flags pertencem a ele**, em vez de serem repetidas em cada chamada

O argumento de velocidade é mais fraco do que as pessoas pensam: o módulo guarda os padrões
compilados, então um laço chamando `re.search` não recompila toda vez. Compile pelo nome.

## `re.VERBOSE`, para um padrão que vale explicar

```python
LINHA = re.compile(r"""
    (?P<ts>\d{4}-\d{2}-\d{2})    # a data
    \s+
    (?P<nivel>\w+)               # ERROR, WARN, INFO
    \s+
    (?P<msg>.*)                  # todo o resto
""", re.VERBOSE)
```

O `re.VERBOSE` ignora espaço em branco e tudo depois de um `#`, então um padrão longo dá para
espalhar e comentar. Um espaço literal então precisa ser escrito `\ ` ou `[ ]` — que é o custo, e
ele vale para qualquer padrão sobre o qual você precisou pensar.
