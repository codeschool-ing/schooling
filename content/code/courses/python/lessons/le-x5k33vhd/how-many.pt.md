---
title: Guloso por padrão, e o caractere que conserta
version: 1
---

```
*        zero ou mais
+        um ou mais
?        zero ou um
{3}      exatamente três
{2,4}    de dois a quatro
{2,}     dois ou mais
```

Cada um se aplica à coisa imediatamente antes dele: `ab+` é um `a` e um ou mais `b`; `(ab)+` é um
ou mais `ab`.

## Guloso

**`*` e `+` pegam o máximo que conseguem**, e depois devolvem caracteres um a um até o resto do
padrão caber.

```python
re.search(r"<(.*)>", "<a> and <b>").group(1)      # 'a> and <b'
```

Isso não é um defeito. O `.*` casou tudo até o último `>`, porque tudo até o último `>` é mais que
tudo até o primeiro — e o padrão continuou cabendo.

## Preguiçoso

```python
re.search(r"<(.*?)>", "<a> and <b>").group(1)     # 'a'
```

`*?` e `+?` pegam o MÍNIMO que conseguem, e depois acrescentam um caractere por vez até o resto
caber. Uma interrogação, e o sentido se inverte.

## E a resposta melhor

```python
re.search(r"<([^>]*)>", "<a> and <b>").group(1)   # 'a'
```

"Qualquer coisa que não seja um `>`" diz o que você queria, não tem como passar do fecha-colchete,
e não depende de quem lê saber qual tipo de quantificador é este. **Descrever a forma vence
ajustar a gula**, e é mais rápido também.

## O `?` depois de um grupo

```python
r"colou?r"          # color ou colour
r"(\+\d{1,3} )?"    # um código de país opcional, presente ou não
```

O grupo opcional é como um padrão trata "esta parte pode não estar lá" — e quando ela está
ausente, o grupo dela é `None` e não uma string vazia, que é uma conferência que alguém esquece.

## O que está sempre errado

```python
r".*"
```

Sozinho, ele casa tudo, inclusive nada. Dentro de um padrão ele é a armadilha gulosa acima. **Se o
seu padrão tem um `.*` e você não sabe bem por quê, essa é a linha a olhar primeiro.**
