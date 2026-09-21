---
title: Um arquivo, uma função e um `assert` pelado
version: 1
---

```python
# test_slug.py
from app.slug import slugify

def test_espacos_viram_hifens():
    assert slugify("Hello World") == "hello-world"
```

```sh
pytest
```

```sh
test_slug.py .                                                           [100%]
============================== 1 passed in 0.02s ===============================
```

**É essa a interface inteira.** Nenhuma classe de que herdar, nenhum `assertEqual`, nenhum
registro em lugar nenhum. Um arquivo cujo nome começa com `test_`, uma função cujo nome começa com
`test_`, e um `assert` comum do Python dentro dela.

## O que o `pytest` procura

Rodado sem argumento, ele desce a partir de onde você está e coleta todo `test_*.py`, e dentro de
cada um toda função chamada `test_*`. Qualquer outra coisa no arquivo é código comum — auxiliares,
imports, constantes — e fica em paz.

## O ponto

```sh
test_slug.py .F                                                          [100%]
```

Um caractere por teste, na ordem em que rodaram: `.` passou, `F` falhou, `E` levantou antes de o
corpo começar, `s` foi pulado. Numa suíte de quatrocentos é uma barra de progresso que dá para ler.

## Rodar menos que tudo

```sh
pytest tests/test_slug.py              # um arquivo
pytest tests/test_slug.py::test_espacos_viram_hifens   # um teste
pytest -k slug                         # todo teste cujo nome contém "slug"
pytest -x                              # para na primeira falha
pytest --lf                            # só os que falharam da última vez
```

`-x` e `--lf` juntos são como uma suíte quebrada é consertada: rode as falhas, pare na primeira,
conserte, repita. `-q` encurta o relatório e `-v` dá uma linha por teste com o nome completo.

## O código de saída

O `pytest` sai com 0 quando tudo passou e diferente de zero caso contrário, que é tudo o que a CI
precisa dele. Todo o resto da saída é para você.
