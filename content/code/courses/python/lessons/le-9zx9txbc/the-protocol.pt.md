---
title: Dois métodos, e o valor de retorno que engole
version: 2
---

```python
class Timer:
    def __enter__(self):
        self.start = time.perf_counter()
        return self                      # this is what `as` binds

    def __exit__(self, exc_type, exc, tb):
        self.elapsed = time.perf_counter() - self.start
```

```python
with Timer() as t:
    work()
print(t.elapsed)
```

## O `__enter__`

Roda antes do corpo. **O que ele devolver é o que o `as` liga** — e isso é em geral o `self`, e às
vezes outra coisa completamente: o `open` devolve um objeto de arquivo, e uma trava devolve `True`.

Se não houver `as`, o valor devolvido é descartado, o que está bem para um gerenciador cujo
trabalho inteiro é o desfazer.

## O `__exit__` e os três argumentos dele

```python
def __exit__(self, exc_type, exc, tb):
```

Na saída sem exceção, os três são `None`. Com uma, eles são a classe, a instância e o traceback —
os mesmos três que o `sys.exc_info()` dá.

**É assim que um gerenciador se comporta de outro jeito na falha**: uma transação confirma quando
`exc_type is None` e desfaz caso contrário.

## O valor de retorno

```python
    def __exit__(self, exc_type, exc, tb):
        return True          # the exception is GONE
```

Um retorno verdadeiro quer dizer "eu tratei". A exceção para ali: não registrada, não relevantada,
e o código depois do `with` roda como se o corpo tivesse terminado.

**Não devolva nada a menos que suprimir seja o ponto inteiro do gerenciador.** Um `return` que
você não quis — o fim de um `if` que por acaso dá `True` — come em silêncio toda falha dentro de
todo bloco que o usa.

O `contextlib.suppress(FileNotFoundError)` é a versão escrita para quando você quer isso, e ela
nomeia qual exceção, o que um `True` pelado não faz.

## Nenhum dos dois métodos dá para pular

Uma classe com `__enter__` e sem `__exit__` levanta `TypeError` no `with`, dizendo qual método
falta. Essa é a falha boa: ela acontece no primeiro uso e não na primeira exceção.
