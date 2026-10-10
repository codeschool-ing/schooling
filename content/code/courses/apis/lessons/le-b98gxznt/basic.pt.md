---
title: Autenticação Basic
version: 1
---

**O Basic envia o nome e a senha em toda requisição, codificados e não escondidos.** É o esquema mais
antigo do HTTP e o mais simples de usar: `curl -u nome:senha` e a porta abre.

```
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/books
[{"id": 1, "title": "Dom Casmurro", "stock": 12}, {"id": 2, "title": "Memórias Póstumas de Brás Cubas", "stock": 7}, {"id": 3, "title": "A Hora da Estrela", "stock": 0}, {"id": 4, "title": "Perto do Coração Selvagem", "stock": 3}, {"id": 5, "title": "Ensaio sobre a Cegueira", "stock": 9}, {"id": 6, "title": "Americanah", "stock": 4}]
```

O `-v` faz o curl imprimir os cabeçalhos que envia, cada linha começando com `>`. Fique só com o que
importa:

```
ana@api:~/shelf$ curl -sv -u ana:river-lamp-42 localhost:8000/v1/books/1 2>&1 | grep -i '^> authorization'
> Authorization: Basic YW5hOnJpdmVyLWxhbXAtNDI=
```

A palavra depois do esquema parece um segredo, e a crença comum é que seja um. É **base64**, um jeito de
escrever quaisquer bytes com 64 caracteres imprimíveis para que sobrevivam num cabeçalho. Não tem chave,
e qualquer um a desfaz:

```
ana@api:~/shelf$ echo YW5hOnJpdmVyLWxhbXAtNDI= | base64 -d; echo
ana:river-lamp-42
```

**Base64 é uma codificação, não criptografia.** Quem vê esse cabeçalho tem a senha, no tempo de digitar
`base64 -d`. Por isso o Basic só é aceitável sobre HTTPS, em que a requisição inteira, cabeçalhos
incluídos, viaja criptografada; a aula 13 trata dessa camada. No `http://127.0.0.1` simples deste
laboratório ele é seguro só porque a requisição nunca sai da máquina.

## O que "toda requisição" custa

A senha não é enviada uma vez. Ela viaja com cada requisição, e isso tem três consequências que
**nenhuma configuração remove**.

- Toda requisição é uma conferência de senha. O `keys.py` roda o scrypt em cada uma, e o scrypt é
  lento de propósito. Um cliente que lê cem livros paga por cem conferências de senha, e o servidor
  também.
- O cliente precisa guardar a senha, num arquivo ou na memória, enquanto quiser fazer requisições.
  Qualquer coisa que consiga ler esse arquivo consegue ser a ana.
- Não existe logout. O servidor não guarda nada por cliente que possa apagar. O único jeito de tirar
  um acesso Basic é mudar a senha, o que tira o acesso também de tudo o mais que a usava.

O Basic ainda é a ferramenta certa em alguns lugares: um script num servidor falando com uma API
interna sobre HTTPS, ou um teste como os desta aula. Onde ele encaixa mal é onde quer que uma pessoa
entre uma vez e faça muitas requisições depois, e é isso que a próxima seção muda.
