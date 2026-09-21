---
title: Duas cláusulas, e um trabalho cada
version: 1
---

```python
try:
    f = open(caminho)
except FileNotFoundError:
    print(f"não existe este arquivo: {caminho}")
else:
    processar(f)        # só se o open deu certo
finally:
    print("pronto")     # de um jeito ou de outro
```

## O `else`

O `else` roda quando o `try` NÃO levantou erro. O trabalho dele é manter fora do `try` código que
nunca foi para ser protegido:

```python
try:
    valor = int(bruto)
except ValueError:
    ...
else:
    salvar(valor)       # um KeyError dentro do salvar NÃO é capturado acima
```

Escrito dentro do `try`, o `salvar(valor)` fica na rede — e no dia em que ele levantar a mesma
classe, o tratamento responde pela falha errada. **O `else` é como o `try` fica com uma linha.**

## O `finally`

O `finally` roda em todo caminho de saída do bloco: sucesso, exceção tratada, exceção não tratada,
e até um `return`. Ele é para a limpeza que precisa acontecer de qualquer jeito — fechar um
arquivo, soltar uma trava, apagar um temporário.

```python
f = open(caminho)
try:
    processar(f)
finally:
    f.close()           # acontece mesmo se o processar levantar erro
```

**Um `try`/`finally` sem `except` é uma coisa perfeitamente comum de escrever.** Ele diz: eu não
estou tratando isto, e ainda assim estou arrumando.

## E o `with` escreve isso por você

```python
with open(caminho) as f:
    processar(f)
```

Essa é a mesma garantia numa linha — o assunto da aula 9. Qualquer coisa com um `close`, uma trava,
uma conexão ou uma transação tem uma forma `with`, e ela existe precisamente porque todo mundo
esquecia o `finally`.

## A única armadilha

```python
try:
    return calcular()
finally:
    return reserva()         # este return VENCE
```

Um `return` no `finally` substitui o que estava a caminho da saída, exceção inclusive. É válido, é
confuso, e a regra é simples: **nunca dê `return` de dentro de um `finally`.**
