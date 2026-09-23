---
title: A terceira camada, e por que todo mundo consulta
version: 2
---

```python
@retry(times=3)
def fetch(url):
    ...
```

Escreva o `@` como chamada, como a seção anterior disse:

```python
fetch = retry(times=3)(fetch)
```

**Duas chamadas.** O `retry(times=3)` roda primeiro e precisa devolver um DECORADOR; esse
decorador é então chamado com `fetch`. Então há três camadas em vez de duas.

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def retry(times):",
      "note": "**A primeira camada recebe o argumento.** O `retry(times=3)` roda quando a linha do `@` é lida, antes de existir qualquer função, e tudo o que ele faz é guardar o `times`."
    },
    {
      "code": "    def decorator(func):\n        @functools.wraps(func)",
      "note": "**A segunda recebe a função.** Este é o decorador de fato, o que o `@` aplica ao `fetch`, e o `functools.wraps` mantém o nome e a docstring do `fetch` no que ele devolve."
    },
    {
      "code": "        def wrapper(*args, **kwargs):\n            for attempt in range(times):\n                try:\n                    return func(*args, **kwargs)\n                except OSError:\n                    if attempt == times - 1:\n                        raise",
      "note": "**A terceira recebe a chamada**, e roda toda vez que `fetch(url)` roda: até `times` tentativas, devolvendo a primeira que der certo e levantando o último `OSError` se nenhuma der."
    },
    {
      "code": "        return wrapper",
      "note": "O decorador devolve o wrapper, e é para ele que o nome `fetch` aponta daí em diante."
    },
    {
      "code": "    return decorator",
      "note": "E o `retry` devolve o decorador. Um `return` para cada camada de fora: esqueça qualquer um e fica `None` onde deveria haver uma função."
    }
  ]
}
```

Leia de dentro para fora: o `wrapper` faz o trabalho, o `decorator` faz um wrapper para uma função,
o `retry` faz um decorador para uma configuração.

## Por que não dá para ser duas camadas

Porque o `@` aplica o que vem depois dele à função abaixo. Se o `retry` recebesse a função, ele
não teria onde pôr o `times`. A chamada precisa acontecer antes de o `@` fazer qualquer coisa.

## O que pega as pessoas

```python
@retry            # no parentheses
def fetch(url): ...
```

Agora o `times` é a FUNÇÃO, e o `decorator` é o que o `fetch` vira — então chamar `fetch(url)`
chama `decorator(url)` e devolve um wrapper em vez de um resultado. Nada levanta erro até muito
depois, e a mensagem é sobre outra coisa.

**Um decorador que recebe argumentos precisa sempre ser escrito com parênteses**, mesmo vazios, a
não ser que ele tenha sido construído de propósito para aceitar os dois jeitos.

## E a nota honesta

Esta é a parte da aula que as pessoas consultam toda vez, inclusive quem escreve isso com
frequência. Escrever o `@` como chamada é o que a torna legível, e não há vergonha nenhuma em
fazer isso no papel antes de digitar.
