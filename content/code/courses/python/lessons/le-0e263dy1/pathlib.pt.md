---
title: Um caminho é um objeto, não uma string
version: 2
---

```python
from pathlib import Path

data = Path("data")
rows = data / "2026" / "rows.csv"       # data/2026/rows.csv
rows.exists()
rows.read_text(encoding="utf-8")
```

O operador `/` junta. Ele usa o separador certo para a máquina em que está, que é a primeira razão
de isto existir: `"data" + "/" + name` é um defeito no Windows e uma linha esquisita em todo lugar.

## As partes

```python
rows.name          # 'rows.csv'
rows.stem          # 'rows'
rows.suffix        # '.csv'
rows.parent        # Path('data/2026')
rows.parts         # ('data', '2026', 'rows.csv')
```

Cada uma delas é uma função que alguém escreveu à mão com `split(".")` e errou para um arquivo
chamado `arquivo.tar.gz` ou para um sem extensão nenhuma.

## Ler e gravar

```python
text = path.read_text(encoding="utf-8")
path.write_text(text, encoding="utf-8")
```

Para um arquivo pequeno inteiro, essa é a operação toda — sem `open`, sem fechar, sem nada a
esquecer. A aula 9 é a forma `with open(...)`, que é o que você quer para um arquivo grande lido
linha a linha.

**Passe sempre `encoding="utf-8"`.** Sem isso o Python usa o padrão da máquina, que muda de máquina
para máquina — e um arquivo que lê perfeitamente aqui falha no servidor com um `UnicodeDecodeError`
nomeando um byte.

## Encontrar arquivos

```python
for p in Path("data").glob("*.csv"):
for p in Path("data").rglob("*.csv"):       # every level below
```

O `glob` é um nível, o `rglob` são todos. Os dois dão objetos `Path`, então a linha seguinte
pergunta `p.stem` sem analisar nada.

## Criar e testar

```python
path.exists()  path.is_file()  path.is_dir()
path.parent.mkdir(parents=True, exist_ok=True)
```

O `exist_ok=True` é a diferença entre um script idempotente e um que falha na segunda vez. O
`parents=True` cria os diretórios intermediários.

## A coisa a lembrar

**Um caminho não é uma string, e no momento em que você faz `+` num deles você saiu do `pathlib`.**
Se uma biblioteca insistir numa string, `str(path)` nessa fronteira — e em lugar nenhum mais.
