---
title: Ao lado do script, e não ao lado do terminal
version: 2
---

```python
open("data/rows.csv")
```

Esse caminho é relativo ao **diretório de trabalho atual** — onde o terminal estava quando você
digitou `python`, e não onde o script está. Rode de outro lugar e ele falha, e a falha é um
`FileNotFoundError` nomeando um caminho que claramente existe.

## O arquivo que mora ao lado do script

```python
from pathlib import Path

HERE = Path(__file__).resolve().parent
rows = HERE / "data" / "rows.csv"
```

`__file__` é o caminho do módulo que está rodando. O `.resolve()` o torna absoluto e remove os
`..`, e o `.parent` é o diretório. Dali em diante o caminho funciona de qualquer diretório.

**Esta é a forma certa para dado que viaja junto com o código** — um modelo, uma fixture, uma
tabelinha de consulta.

## E o arquivo que não

O dado que o USUÁRIO nomeia pertence à linha de comando, relativo a onde ele está:

```python
path = Path(sys.argv[1])
```

Esse é o caso oposto, e o comportamento relativo ao terminal está certo ali.

Configuração, caches e saída em geral pertencem a outro lugar ainda, e o `os.environ` ou um
argumento explícito é como a implantação diz onde.

## `resolve` e `exists`

```python
path.resolve()          # absolute, symlinks followed, `..` removed
path.expanduser()       # ~ becomes the home directory
```

`open("~/data.csv")` NÃO funciona: quem expande o `~` é o shell, e o Python não. `Path("~/
dados.csv").expanduser()` é a versão que funciona.

## Imprimir o caminho no erro

```python
raise FileNotFoundError(f"no rows file at {rows.resolve()}")
```

Um caminho relativo numa mensagem de erro é a string menos útil da programação, porque quem lê não
sabe relativo a quê ele era. **Resolva antes de imprimir**, e a mensagem deixa de ser um enigma.
