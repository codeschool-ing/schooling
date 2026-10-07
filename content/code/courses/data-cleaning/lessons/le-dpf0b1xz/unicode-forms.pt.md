---
title: Formas Unicode: uma letra, duas grafias
version: 1
---

**O Unicode permite escrever a maioria das letras acentuadas de dois jeitos**: como um caractere,
`ã`, ou como a letra simples seguida de um acento combinante, `a` mais o til combinante, U+0303. Os
dois aparecem iguais na tela. São textos diferentes, de tamanhos diferentes, e nunca comparam iguais.

```
ana@lab:~/clean$ python -c "import unicodedata; a = 'S\u00e3o'; b = unicodedata.normalize('NFD', a); print(a == b, len(a), len(b), [hex(ord(ch)) for ch in b], unicodedata.normalize('NFC', b) == a)"
False 3 4 ['0x53', '0x61', '0x303', '0x6f'] True
```

`'São'` escrito com o caractere único tem três caracteres. Decomposto, tem quatro: `S`, `a`, o til
combinante `0x303`, `o`. Os dois não são iguais, e normalizar o decomposto de volta dá o original.

As duas formas têm nome. **NFC** é a forma composta, um caractere por letra acentuada, que é o que os
teclados da maioria dos sistemas produzem e o que este curso guarda. **NFD** é a forma decomposta.
Alguns sistemas produzem NFD de propósito — sistemas de arquivos antigos do macOS guardavam nomes de
arquivo assim — e o aplicativo da Quitanda Verde é um deles: todo nome e toda cidade que ele mandou
estão em NFD. A aula 1 achou o sintoma, 213 São Paulos que pareciam com os outros 458.

A correção é uma chamada, sem julgamento nenhum:

- pandas: `.str.normalize("NFC")`
- Python: `unicodedata.normalize("NFC", text)`
- PostgreSQL: `normalize(text, NFC)`

**Normalize toda coluna de texto para NFC na entrada**, tão rotineiramente quanto aparar espaços.
Não muda nada que um leitor veja e torna igual o que deveria ser igual. As outras duas formas, NFKC e
NFKD, também juntam caracteres de "compatibilidade" — um `²` sobrescrito vira `2`, a ligadura `ﬁ` vira
`fi` — o que é certo para uma chave de comparação e errado para texto guardado, porque perde
informação.
