---
title: Três coisas que um bloco `with` não faz
version: 1
---

## Ele não é um escopo

```python
with open(caminho) as f:
    linhas = f.readlines()
print(linhas)        # tudo bem — e o `f` também está aqui
print(f.closed)      # True: o objeto está aqui, e está fechado
```

O Python não tem escopo de bloco, como a aula 5 disse. Um nome ligado dentro de um `with` continua
ligado depois dele, inclusive o que o `as` criou — **e usá-lo depois do bloco é o engano**: o
objeto de arquivo existe e está fechado, então ler dele levanta `ValueError: I/O operation on
closed file`.

## Ele não é uma transação por si

Um `with` garante que o `__exit__` roda. Se isso confirma, desfaz, apaga ou não faz nada é
inteiramente do gerenciador.

`with conn:` no `sqlite3` é uma transação e NÃO fecha a conexão. `with open(...)` fecha e não tem
transação nenhuma. **"É um `with`" diz que há um desfazer e não diz qual** — a documentação, ou o
`__exit__`, é onde isso está escrito.

## Ele não trata a exceção

```python
with cronometrado("carga"):
    carregar()      # levanta erro
# nada aqui roda; a exceção continua subindo
```

O gerenciador é avisado da exceção para poder arrumar, e então a exceção continua. A não ser que o
`__exit__` devolva algo verdadeiro — e aí ela sumiu, que é a ponta afiada da seção do protocolo e
quase nunca é o que você quer.

**Um `with` não é um `try`/`except`.** Se você precisa tratar a falha, o `try` continua sendo seu
para escrever, e ele vai em volta do `with`.

## E uma quarta, rapidamente

Ele não torna o corpo atômico, nem seguro para threads, nem repetível. Ele roda duas coisas em
volta do seu código. Todo o resto é o que o gerenciador foi escrito para fazer.
