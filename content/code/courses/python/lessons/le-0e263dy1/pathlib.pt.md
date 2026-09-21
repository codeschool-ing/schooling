---
title: Um caminho é um objeto, não uma string
version: 1
---

```python
from pathlib import Path

dados = Path("dados")
linhas = dados / "2026" / "linhas.csv"       # dados/2026/linhas.csv
linhas.exists()
linhas.read_text(encoding="utf-8")
```

O operador `/` junta. Ele usa o separador certo para a máquina em que está, que é a primeira razão
de isto existir: `"dados" + "/" + nome` é um defeito no Windows e uma linha esquisita em todo lugar.

## As partes

```python
linhas.name          # 'linhas.csv'
linhas.stem          # 'linhas'
linhas.suffix        # '.csv'
linhas.parent        # Path('dados/2026')
linhas.parts         # ('dados', '2026', 'linhas.csv')
```

Cada uma delas é uma função que alguém escreveu à mão com `split(".")` e errou para um arquivo
chamado `arquivo.tar.gz` ou para um sem extensão nenhuma.

## Ler e gravar

```python
texto = caminho.read_text(encoding="utf-8")
caminho.write_text(texto, encoding="utf-8")
```

Para um arquivo pequeno inteiro, essa é a operação toda — sem `open`, sem fechar, sem nada a
esquecer. A aula 9 é a forma `with open(...)`, que é o que você quer para um arquivo grande lido
linha a linha.

**Passe sempre `encoding="utf-8"`.** Sem isso o Python usa o padrão da máquina, que muda de máquina
para máquina — e um arquivo que lê perfeitamente aqui falha no servidor com um `UnicodeDecodeError`
nomeando um byte.

## Encontrar arquivos

```python
for p in Path("dados").glob("*.csv"):
for p in Path("dados").rglob("*.csv"):       # todo nível abaixo
```

O `glob` é um nível, o `rglob` são todos. Os dois dão objetos `Path`, então a linha seguinte
pergunta `p.stem` sem analisar nada.

## Criar e testar

```python
caminho.exists()  caminho.is_file()  caminho.is_dir()
caminho.parent.mkdir(parents=True, exist_ok=True)
```

O `exist_ok=True` é a diferença entre um script idempotente e um que falha na segunda vez. O
`parents=True` cria os diretórios intermediários.

## A coisa a lembrar

**Um caminho não é uma string, e no momento em que você faz `+` num deles você saiu do `pathlib`.**
Se uma biblioteca insistir numa string, `str(caminho)` nessa fronteira — e em lugar nenhum mais.
