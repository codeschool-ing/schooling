---
title: Um pacote que não existe
version: 1
---

Um modelo escreve nomes de bibliotecas do jeito que escreve todo o resto: **o nome que cabe na
frase, tenha alguém publicado ou não**. Na maioria das vezes o nome é real. Às vezes é plausível e
inventado, e o passo seguinte de quem programa é `pip install`.

Esta aula trata do que dá errado quando a saída de um modelo chega ao mundo real, e do que impede
isso. Todo erro que o modelo comete aqui foi escrito pelo curso, como regras do `scripted-1`, para
mostrar o que as defesas precisam aguentar. As defesas são reais.

## Uma resposta que dá nome a um pacote

```
ana@dev:~/shop$ python ask.py "Which library gives me a money type for the cart?"
Use the cartmoney package, which handles cents and rounding for you:

    pip install cartmoney

Then `from cartmoney import Money` and write `Money("39.90")` wherever the cart holds a price.
```

A resposta se lê bem: um nome que diz o que faz, um comando de instalação, um import, um exemplo.
**Nada nela diz se o `cartmoney` existe.** Conferir custa uma requisição ao índice, que lê e não
instala nada:

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
uploads = [f["upload_time"] for files in info["releases"].values() for f in files]
print(f"{name}: on PyPI since {min(uploads)[:10]}, \"{info['info']['summary']}\"")
```

```
ana@dev:~/shop$ python check_package.py cartmoney
cartmoney: not on PyPI. Do not install it, and do not register it to make the error go away.
ana@dev:~/shop$ python check_package.py requests
requests: on PyPI since 2011-02-14, "Python HTTP for Humans."
```

**O `cartmoney` não está no PyPI**, pelo menos não no dia em que isto foi gravado. O `requests` está,
e desde 2011, que é a segunda coisa que vale saber de um pacote antes de confiar nele.

## Por que um nome inventado é um risco e não só um erro

Uma instalação que falha é um incômodo. O perigo é o dia em que ela dá certo: **qualquer um pode
registrar um nome livre num índice público**, e um nome que modelos sugerem com frequência é um nome
que alguém pode registrar e encher com código próprio. Quem copia o comando de instalação roda esse
código, com as próprias permissões, na própria máquina.

Então a verificação que importa não é "instala?". É **"este é o pacote que eu queria, e eu confio em
quem o publica?"**:

- **Procure o nome antes de instalar**, como acima, e leia o que achar: quem publica, desde quando,
  quantas pessoas dependem dele, onde fica o código-fonte.
- **Prefira o que o projeto já usa.** A loja já tem uma regra para dinheiro, centavos inteiros, desde
  a aula 1; uma dependência nova para isso é um risco novo por nada.
- **Fixe e trave o que você instala**, para um nome que troque de dono depois não mudar o seu build
  sem um diff que alguém leia.
- **Nunca registre um nome que um modelo inventou** para fazer um erro sumir. Isso transforma um
  engano num pacote que outra pessoa vai instalar.
