---
title: Rodar numa máquina onde nunca rodou
version: 2
---

*Precisa de Python 3.12 ou mais novo e de mais nada* é uma afirmação, e o único jeito de saber se é
verdade é experimentar onde nada mais está instalado. A sua própria máquina é o pior lugar para esse teste:
tem todo pacote que você já instalou, toda variável que já definiu e um banco que sobrou da semana
passada.

Uma máquina montada do zero é um lugar melhor, e a aula 15 já mostrou como fazer uma em minutos. A
transcrição abaixo rodou num srv com Python e git e nada do loanbook além do repositório bare enviado a ele.
O seu tem o deploy da aula 15, então monte uma segunda máquina para este teste: `multipass launch 24.04
--name cold` já vem com Python e git. Faça o clone a partir do endereço real do seu projeto e apague a
máquina depois com `multipass delete --purge cold`. Seguindo a seção *Run it* do README, com o clone
vindo do repositório bare do srv em vez do endereço de exemplo, e o `python3 app.py` subido em segundo
plano:

```
ana@srv:~$ python3 --version
Python 3.12.3
ana@srv:~$ git clone -q loanbook.git && cd loanbook && ls
Containerfile
LICENSE
README.md
app.py
deploy
docs
seed.py
static
test_app.py
ana@srv:~/loanbook$ python3 seed.py
seeded 8 items, 4 of them out
ana@srv:~/loanbook$ curl -s localhost:8000/api/items | python3 -c 'import json,sys; print(len(json.load(sys.stdin)), "items")'
8 items
ana@srv:~/loanbook$ python3 -m unittest 2>&1 | tail -3
Ran 7 tests in 0.003s

OK
```

Python 3.12, um clone, o script de dados, um servidor que responde com oito itens, e os testes passando. A
afirmação se sustenta. Se não se sustentasse, a correção teria ido para o README, ou para o código, antes
que outra pessoa esbarrasse nela, e esse é o ponto de rodar a frio.

Para o seu projeto, a máquina limpa pode ser uma máquina virtual, um container de uma imagem pura, o
notebook de um amigo ou um usuário novo no sistema. O que importa é que **você digite exatamente o que o
README diz, e nada mais**. O passo que você faz por hábito e esqueceu de escrever, uma variável, um pacote,
uma pasta que precisa existir, é aquele em que quem avalia vai travar, e é o de que vai lembrar.
