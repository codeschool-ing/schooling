---
title: `bytes` contra `str`, e quando você não precisa de nenhum dos dois
version: 2
---

```python
with open(path, "rb") as f:
    data = f.read()        # bytes, not str
```

`"rb"` e `"wb"` pulam a decodificação inteira. Você recebe um objeto `bytes`: uma sequência de
números de 0 a 255, impressa como `b"..."`.

## As duas conversões

```python
text = data.decode("utf-8")      # bytes → str
data = text.encode("utf-8")      # str   → bytes
```

**Decodifique na entrada, codifique na saída**, e mantenha `str` em todo o meio. Um programa que
carrega `bytes` pelo meio dele é um que vai comparar um `b"name"` com um `"name"` e receber `False`.

## Quando você precisa de binário

Uma imagem, um PDF, um zip, qualquer coisa comprimida, e qualquer coisa em que você está copiando em
vez de lendo. Para copiar, o `shutil.copyfile` é a versão que você deveria escrever.

Também um arquivo cuja codificação você ainda não sabe: leia os primeiros bytes como binário e olhe
para eles antes de decidir.

## Quando você não precisa

Quase sempre. CSV, JSON, logs, código-fonte e configuração são texto, e `open(caminho,
encoding="utf-8")` é a resposta inteira. Se você se pegar decodificando à mão dentro de um laço, o
modo estava errado duas linhas antes.

## O que pega as pessoas

```python
>>> b"91" + 1
TypeError: can't concat int to bytes
>>> b"a" == "a"
False
```

`bytes` e `str` nunca comparam iguais e nunca concatenam. Isso chega mais frequentemente de uma
biblioteca que devolve bytes — `subprocess`, um socket, um hash — e o conserto é um `.decode()`
naquela fronteira em vez de uma conversão mais adiante.

O `hashlib` é o caso comum: ele quer bytes, então `h.update(text.encode("utf-8"))`, e ele devolve
um `hexdigest()` que é `str` de novo.
