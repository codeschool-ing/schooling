---
title: Seis que você vai usar antes de escrever um
version: 1
---

## `open`

O da aula 9, e a razão de a maioria das pessoas encontrar essa sintaxe.

## Uma trava

```python
with trava:
    compartilhado += 1
```

A `threading.Lock` adquire na entrada e solta na saída — inclusive quando o corpo levanta erro, que
é o caso em que um release esquecido trava o programa inteiro sem mensagem de erro em lugar nenhum.

## Uma conexão de banco

```python
with conn:
    conn.execute(...)
```

No `sqlite3`, o `with` é a TRANSAÇÃO: ele confirma no fim e desfaz numa exceção. **Ele não fecha a
conexão**, o que surpreende todo mundo uma vez — o gerenciador faz a transação e o `conn.close()`
continua sendo seu.

Isso vale como ponto geral: o gerenciador de uma biblioteca faz o que a documentação dela diz, e
"é um `with`" não diz qual desfazer ele executa.

## `tempfile`

```python
with tempfile.TemporaryDirectory() as d:
    escrever_coisas(Path(d))
# o diretório e tudo dentro dele sumiram aqui
```

A versão que limpa quando o teste falha, que é a versão que importa.

## `contextlib.suppress`

```python
with suppress(FileNotFoundError):
    caminho.unlink()
```

`try`/`except`/`pass`, com a classe nomeada onde quem lê vê. Duas linhas viram uma, e o nome é o
ponto — um `except: pass` pelado não diz nada sobre o que era esperado.

## `redirect_stdout`

```python
buffer = io.StringIO()
with redirect_stdout(buffer):
    biblioteca_barulhenta()
```

Para a biblioteca que imprime e não tem opção de não imprimir. A aula 15 o usa para testar algo
que foi escrito para imprimir.

## E a forma que eles compartilham

Cada um deles é preparação, corpo, desfazer — com o desfazer garantido. **Quando você encontrar um
`with` no código de alguém, a pergunta é o que ele desfaz**, e a resposta está sempre no
`__exit__`.
