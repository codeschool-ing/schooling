---
title: Deixe na forma canônica, depois verifique
version: 1
---

Uma lista de permissão verifica caracteres, e **a mesma coisa pode ser escrita com mais de uma
sequência de caracteres**. O Unicode tem um dígito um, `1`, e um dígito um de largura total, `１`,
que teclados do leste asiático produzem e que na tela parece quase igual. Tem um dois sobrescrito,
`²`. Uma verificação que não conhece esses caracteres diz sim a um valor que o resto do programa lê
de outro jeito.

As definições do próprio Python para "dígito" são o exemplo que vale ver, porque o padrão óbvio é o
errado. Salve isto como `~/sc/booking/digits.py`, na pasta que a aplicação desta aula vai usar:

```python
# digits.py
import re
import unicodedata

phone = "".join(chr(0xFF10 + int(d)) for d in "11987654321")  # full-width
print(re.fullmatch(r"\d{11}", phone) is not None)
print(re.fullmatch(r"[0-9]{11}", phone) is not None)
print(phone.isdigit(), int(phone))
print("²".isdigit())
print(unicodedata.normalize("NFKC", phone))
```

```
(.venv) ana@vm:~/sc/booking$ python3 digits.py
True
False
True 11987654321
True
11987654321
```

Linha a linha, são cinco fatos sobre o Python 3:

1. **`\d` casa com qualquer dígito decimal Unicode**, inclusive os de largura total, então `\d{11}`
   aceita o telefone de largura total.
2. **`[0-9]` casa com os dez dígitos ASCII e mais nada**, então recusa.
3. `str.isdigit()` concorda com `\d`, e **`int()` lê dígitos de largura total como os números que
   parecem ser**. Um programa pode validar uma string e guardar outra, de aparência diferente, que
   significa o mesmo número.
4. `isdigit()` também diz sim a `²`, que `int()` recusa; uma verificação, três comportamentos.
5. **A normalização NFKC** reescreve caracteres de compatibilidade nos equivalentes simples, e o
   telefone de largura total vira `11987654321`.

### Decida, e verifique a forma decidida

Há duas respostas honestas para um telefone de largura total, e qualquer uma serve desde que seja
escolhida de propósito:

- **recusar**: o formato é de dígitos ASCII, o padrão é `[0-9]{10,11}`, e o erro diz ao paciente o
  que digitar. É o que o formulário da Vereda faz, porque um número de telefone não tem motivo para
  chegar de outro jeito de um formulário web.
- **normalizar, e validar o valor normalizado**: `unicodedata.normalize("NFKC", value)` primeiro, e
  a lista de permissão sobre o resultado. Serve para nomes e texto livre, que as pessoas digitam em
  todo tipo de teclado.

O que nunca serve é o terceiro arranjo: **validar uma forma e guardar outra**. Verifique `value`,
guarde `value.strip().lower()`, e o valor guardado é um que ninguém verificou. A regra é curta: deixe
na forma canônica primeiro, verifique a forma canônica e guarde exatamente o que foi verificado.

### A mesma regra, para caminhos

A ideia é mais velha que o Unicode. Um nome de arquivo que chega como entrada pode nomear o mesmo
arquivo de muitos jeitos: `exams/lucia.pdf`, `exams/./lucia.pdf`, `exams/../exams/lucia.pdf`. Procurar
`..` no texto é lista de bloqueio de novo. A forma canônica de um caminho é a que o sistema
operacional resolve, e **a verificação que se sustenta é sobre o caminho resolvido**: resolva, e
confirme que ele ainda está dentro do diretório em que deveria estar. A aula 14 faz exatamente isso
com os exames enviados, com `Path.resolve()` e `is_relative_to()`.
