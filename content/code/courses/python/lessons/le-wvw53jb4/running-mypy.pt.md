---
title: Rodando, e lendo um erro direito
version: 2
---

```sh
pip install mypy
mypy app/report.py        # one file
mypy -p app               # the package, by name
mypy app/                 # the directory
```

```sh
app/report.py:4: error: Argument 1 to "find" has incompatible type "int"; expected "str"  [arg-type]
Found 1 error in 1 file (checked 3 source files)
```

## As quatro partes de uma linha

`app/report.py:4` — onde olhar. `error:` — a sua severidade; linhas `note:` são informação extra
sobre o erro acima delas e não são falhas próprias. Depois a frase. Depois `[arg-type]` entre
colchetes: **o código do erro**, que é a parte que as pessoas pulam e a parte de que você precisa.

O código é o que você busca, o que você põe dentro de um `# type: ignore[...]` e o que você nomeia
em `disable_error_code`. A frase é para você; o código é para a ferramenta.

## A linha de resumo conta duas coisas diferentes

```sh
Found 1 error in 1 file (checked 3 source files)
```

Três arquivos foram verificados porque `report.py` importa `rates.py`, que traz o `__init__.py`
junto. **Erros são relatados nos arquivos sobre os quais você perguntou; as importações são lidas
para entendê-los.**

## O engano que todo mundo comete uma vez

```sh
mypy app/rates.py
```

```sh
Success: no issues found in 1 source file
```

O mesmo projeto, o mesmo defeito, um atestado de saúde — porque o defeito está em `report.py`, que
CHAMA `rates.find` errado. O `rates.py` em si está bem.

**O erro quase nunca está no arquivo que você mudou.** Está no arquivo que o chama. Rode o
verificador sobre o pacote, nunca sobre o arquivo que você por acaso tem aberto.

## `reveal_type`, quando você quer saber o que ele pensa

```python
data = json.load(f)
reveal_type(data)
```

```sh
note: Revealed type is "Any"
```

Não precisa de import e não é uma função — o verificador reconhece o nome e responde. Em tempo de
execução o nome puro levanta `NameError`; `from typing import reveal_type` dá uma de verdade (3.11
em diante) que imprime `Runtime type is 'int'`. Use quando um erro não fizer sentido: em geral é
porque alguma coisa acima é `Any`.

## O cache

A primeira passagem sobre um pacote leva um segundo ou dois; a segunda leva uma fração disso,
porque `.mypy_cache/` guarda o que foi apurado sobre cada módulo. Ponha no `.gitignore` ao lado do
`__pycache__` e nunca comite.
