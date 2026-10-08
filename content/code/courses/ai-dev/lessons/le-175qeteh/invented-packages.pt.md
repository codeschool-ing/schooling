---
title: Um pacote que não existe
version: 2
---

Um modelo escreve nomes de bibliotecas do jeito que escreve todo o resto: **o nome que cabe na
frase, tenha alguém publicado ou não**. Na maioria das vezes o nome é real. Às vezes é plausível e
inventado, e o passo seguinte de quem programa é `pip install`.

Esta aula trata do que dá errado quando a saída de um modelo chega ao mundo real, e do que impede
isso. Todo erro nela é do `llama3.2:3b`, cometido na máquina da gravação; nenhum foi arranjado.

## Uma resposta que dá nome a um pacote

O `ask.py` é o menor programa que pergunta qualquer coisa ao modelo, a temperatura 0:

```python
import sys

import anthropic

r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=300, extra_body={"temperature": 0},
                                          messages=[{"role": "user", "content": sys.argv[1]}])
print(r.content[0].text)
```

A resposta tem um bloco de código, então vai para um arquivo e o `cat -n` a mostra com as linhas
numeradas:

```
ana@dev:~/shop$ python ask.py "Which Python library gives me a money type for the cart? Name one and the pip command to install it." > reply.txt; cat -n reply.txt
     1	One popular Python library for working with money is `pymoney`. It provides a `Money` class that allows you to perform arithmetic operations on monetary values.
     2	
     3	To install `pymoney`, you can use the following pip command:
     4	
     5	```bash
     6	pip install pymoney
     7	```
     8	
     9	This library is well-maintained and widely used, making it a great choice for working with money in Python.
```

A resposta se lê bem: um nome que diz o que faz, um comando de instalação, e uma garantia, *well
maintained and widely used*. **Nada nela diz se algo disso é verdade.** Conferir custa uma requisição
ao índice, que lê e não instala nada:

```python
"""Look a package name up on PyPI before anyone installs it. Reads only; installs nothing."""
import json
import sys
import urllib.error
import urllib.request

name = sys.argv[1]
try:
    with urllib.request.urlopen(f"https://pypi.org/pypi/{name}/json") as r:
        info = json.load(r)
except urllib.error.HTTPError as e:
    if e.code != 404:
        raise
    print(f"{name}: not on PyPI. Do not install it, and do not register it to make the error go away.")
    sys.exit(1)
uploads = sorted(f["upload_time"] for files in info["releases"].values() for f in files)
print(f"{name}: on PyPI, first release {uploads[0][:10]}, last {uploads[-1][:10]}, \"{info['info']['summary']}\"")
```

```
ana@dev:~/shop$ python check_package.py pymoney
pymoney: on PyPI, first release 2011-03-05, last 2011-03-05, "An implementation of a money type for Python 2.2 >"
ana@dev:~/shop$ python check_package.py money
money: on PyPI, first release 2013-11-16, last 2016-04-17, "Python Money Class"
ana@dev:~/shop$ python check_package.py cartmoney
cartmoney: not on PyPI. Do not install it, and do not register it to make the error go away.
```

**O `pymoney` existe, e é o pacote errado.** Uma versão, de 5 de março de 2011, para Python 2.2, e
nada depois: o "well maintained" da resposta é do modelo, e o índice diz o contrário. O `money` é um
pouco melhor e parou em 2016. Nenhum dos dois foi inventado, e a verificação achou o problema mesmo
assim, porque lê datas e uma descrição onde a resposta tinha adjetivos.

O `cartmoney` é a outra resposta que a verificação dá, para um nome que a ana digitou para vê-la:
**não está no PyPI**, pelo menos não no dia em que isto foi gravado. Um modelo perguntado assim às
vezes escreve um nome desse tipo, plausível e inventado, e o passo seguinte de quem programa é
`pip install`.

## Por que um nome inventado é um risco e não só um erro

Uma instalação que falha é um incômodo. O perigo é o dia em que ela dá certo: **qualquer um pode
registrar um nome livre num índice público**, e um nome que modelos sugerem com frequência é um nome
que alguém pode registrar e encher com código próprio. Quem copia o comando de instalação roda esse
código, com as próprias permissões, na própria máquina.

Então a verificação que importa não é "instala?". É **"este é o pacote que eu queria, e eu confio em
quem o publica?"**:

- **Procure o nome antes de instalar**, como acima, e leia o que achar: quem publica, desde quando,
  quando mudou pela última vez, quantas pessoas dependem dele, onde fica o código-fonte.
- **Prefira o que o projeto já usa.** A loja já tem uma regra para dinheiro, centavos inteiros, desde
  a aula 1; uma dependência nova para isso é um risco novo por nada.
- **Fixe e trave o que você instala**, para um nome que troque de dono depois não mudar o seu build
  sem um diff que alguém leia.
- **Nunca registre um nome que um modelo inventou** para fazer um erro sumir. Isso transforma um
  engano num pacote que outra pessoa vai instalar.
