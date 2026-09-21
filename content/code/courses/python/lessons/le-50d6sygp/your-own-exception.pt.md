---
title: Uma classe, e quando ela vale a pena
version: 1
---

```python
class ConfigError(Exception):
    """A configuração não pôde ser usada."""
```

Essa é a definição inteira. Ela herda `Exception`, tem uma docstring dizendo o que significa, e não
precisa de corpo.

## Quando vale definir uma

**Quando quem chama talvez queira capturar exatamente a sua falha e nada mais.** Esse é o teste, e
ele é sobre quem chama e não sobre você.

Uma biblioteca que lê configuração deveria levantar `ConfigError`, porque o programa acima dela quer
dizer "a sua config está errada" e sair com 2 — e ele não consegue fazer isso se o que chega é um
`ValueError` indistinguível de qualquer outro.

Um script que lê o próprio arquivo não precisa de uma. `ValueError` serve, porque ninguém está
capturando.

## Uma classe base por pacote

```python
class RelatorioError(Exception): ...
class ConfigError(RelatorioError): ...
class FonteError(RelatorioError): ...
```

Uma base, e as específicas abaixo dela. Agora quem chama escreve `except RelatorioError` para dizer
"qualquer coisa que esta biblioteca diga que deu errado", ou nomeia a específica quando pode fazer
algo diferente a respeito. **Esta é a hierarquia da primeira seção, construída para o seu código.**

## Carregar dados

```python
class LinhaError(Exception):
    def __init__(self, linha, mensagem):
        super().__init__(f"linha {linha}: {mensagem}")
        self.linha = linha
```

A mensagem é para uma pessoa; o atributo é para um programa. Um tratamento que queira juntar os
números das linhas ruins precisa de `e.linha`, e analisar isso de volta a partir da mensagem é o que
isto evita.

Chame `super().__init__(...)` para a mensagem chegar ao `str(e)` — uma exceção cujo `str` é vazio é
uma que um log vai imprimir como linha em branco.

## O que não fazer

**Não herde de `BaseException`.** Isso põe a sua classe ao lado de `KeyboardInterrupt`, fora de todo
`except Exception` que alguém escreveu.

E não defina quinze delas para um programa. Cada uma é um nome que quem lê precisa aprender, e a
maior parte do código precisa de uma ou duas.
