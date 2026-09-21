---
title: `@contextmanager`, e o `try` que não é opcional
version: 1
---

```python
from contextlib import contextmanager

@contextmanager
def cronometro():
    inicio = time.perf_counter()
    try:
        yield                       # o corpo roda aqui
    finally:
        print(f"{time.perf_counter() - inicio:.3f}s")
```

Um `yield`. Tudo antes dele é o `__enter__`, tudo depois dele é o `__exit__`, e o que ele produzir
é o que o `as` liga.

## O `try`/`finally` é a lição inteira desta seção

```python
@contextmanager
def cronometro():
    inicio = time.perf_counter()
    yield
    print(...)              # NÃO roda quando o corpo levanta erro
```

Sem o `try`, uma exceção no corpo sobe através do `yield` e as linhas depois dele nunca rodam. **O
gerenciador então arruma só no caso que não precisava de arrumação**, que é pior que gerenciador
nenhum, porque o código parece tratar isso.

## Produzir um valor

```python
@contextmanager
def diretorio(caminho):
    anterior = Path.cwd()
    os.chdir(caminho)
    try:
        yield caminho           # o `as` liga isto
    finally:
        os.chdir(anterior)
```

## Exatamente um `yield`

Dois deles é um `RuntimeError` — "generator didn't stop" — no fim do bloco, que é um lugar confuso
de ouvir isso. Zero deles é "generator didn't yield", no `with`.

## Capturar dentro do gerenciador

```python
    try:
        yield
    except ValueError:
        log.warning("ignorado")     # isto ENGOLE, como devolver True
    finally:
        limpar()
```

Um `except` em volta do `yield` é o equivalente, no gerador, a um `__exit__` verdadeiro — e um
`raise` pelado no fim dele é como se olha e ainda assim se deixa passar.

## Classe ou gerador?

O gerador é mais curto e se lê em ordem. A classe é melhor quando o gerenciador tem estado que
alguém consulta depois, quando ele é reaproveitável em vários blocos `with`, ou quando a
preparação e o desfazer são longos o bastante para quererem nomes.

**Comece com o `@contextmanager`.** Vá para uma classe quando se pegar querendo um método.
