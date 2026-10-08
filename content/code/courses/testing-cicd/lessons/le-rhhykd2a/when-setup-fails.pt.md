---
title: Quando a montagem falha
version: 1
---

Montar é onde mais gente desiste de um curso como este, quase sempre por causa de uma linha de saída
que parecia uma catástrofe e era uma coisa pequena. Estas são as falhas que aparecem seguindo as
duas últimas seções, cada uma com o que imprime e o que a resolve. Todas foram produzidas de
propósito, na máquina de onde vêm as transcrições.

## `uv: command not found`

O terminal que rodou `pipx ensurepath` ainda estava aberto:

```
ana@laptop:~$ uv --version
bash: line 1: uv: command not found
```

O `pipx ensurepath` gravou o novo `PATH` no `~/.bashrc`, e um terminal lê esse arquivo uma vez,
quando abre. **Abra um terminal novo**, ou rode `source ~/.bashrc` neste. Se um terminal novo
ainda não o encontra, `ls ~/.local/bin` diz se o `pipx install uv` chegou a terminar.

## `No module named pytest`

Um terminal novo, o diretório do projeto e a suíte:

```
ana@laptop:~/shipquote$ python -m pytest -q
/usr/bin/python: No module named pytest
```

O caminho no começo da linha entrega: esse é o Python do sistema, que não tem pytest e não deve
ter. Num Ubuntu 24.04 de fábrica não existe nem `python` sozinho fora de um ambiente virtual, e o
mesmo engano responde que `python` não foi encontrado. Nos dois casos, o ambiente virtual não está
ativo neste terminal. **Rode `source .venv/bin/activate` em `~/shipquote`**, uma vez por terminal,
e `python` volta a ser o do ambiente. `which python` responde qual você tem:
`/home/ana/shipquote/.venv/bin/python` é o certo.

## Um arquivo que perdeu a indentação

Aqui o `shipquote/quote.py` tem uma linha colada com dois espaços onde deviam ser quatro, e a suíte
nem começa:

```
ana@laptop:~/shipquote$ python -m pytest -q
ImportError while loading conftest '/home/ana/shipquote/tests/conftest.py'.
tests/conftest.py:9: in <module>
    from shipquote.app import Handler
shipquote/app.py:9: in <module>
    from . import money, quote
E     File "/home/ana/shipquote/shipquote/quote.py", line 25
E       zone = zone_of(cep)
E                          ^
E   IndentationError: unindent does not match any outer indentation level
```

Leia de baixo para cima. `IndentationError` é a causa, e a linha acima dela nomeia o arquivo e a
linha, `quote.py`, linha 25. Tudo o que está acima disso é a cadeia de imports que chegou ao
arquivo: o `conftest.py` importa o `app.py`, que importa o `quote.py`, então **um erro num arquivo
para todos os testes**, inclusive os que nunca o usam. Copie o arquivo de novo com o botão do
bloco.

## `Author identity unknown`

O primeiro `git commit` numa máquina em que ninguém disse ao git quem você é:

```
ana@laptop:~/shipquote$ git commit -m "shipquote as the course begins"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'ana@laptop.(none)')
```

O git recusa em vez de adivinhar, e diz exatamente o que rodar. As duas linhas `git config --global`
da seção 03 resolvem, uma vez por máquina. Rode o commit de novo depois.

## `Address already in use`

A seção 10 sobe o servidor à mão na porta 8080. Suba-o uma segunda vez enquanto o primeiro ainda
roda, noutro terminal ou em segundo plano, e o segundo para na hora:

```
ana@laptop:~/shipquote$ SHIPQUOTE_PORT=8080 python -m shipquote.app
Traceback (most recent call last):
  File "<frozen runpy>", line 203, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "/home/ana/shipquote/shipquote/app.py", line 67, in <module>
    main()
    ~~~~^^
  File "/home/ana/shipquote/shipquote/app.py", line 61, in main
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
  File "/usr/lib/python3.13/socketserver.py", line 457, in __init__
    self.server_bind()
    ~~~~~~~~~~~~~~~~^^
  File "/usr/lib/python3.13/http/server.py", line 140, in server_bind
    socketserver.TCPServer.server_bind(self)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^
  File "/usr/lib/python3.13/socketserver.py", line 478, in server_bind
    self.socket.bind(self.server_address)
    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^
OSError: [Errno 98] Address already in use
ana@laptop:~/shipquote$ ss -ltnp | grep 8080
LISTEN 0      5          127.0.0.1:8080       0.0.0.0:*    users:(("python",pid=6178,fd=3))        
```

Só um programa pode escutar numa porta. Ache o primeiro com `ss -ltnp | grep 8080`, que nomeia o
processo, e pare-o, ou aperte Ctrl-C no terminal em que ele roda.

## Quando o uv não consegue baixar um Python

`uv venv -p 3.13` numa máquina sem Python 3.13 baixa um. Numa rede que recusa o download, de uma
escola ou de uma empresa, ele para com um erro que nomeia o endereço que não alcançou. **Toda aula
funciona com qualquer Python a partir do 3.11**, então use o que o Ubuntu traz: `uv venv -p 3.12`.
A primeira linha de cada transcrição do pytest passa a dizer 3.12 onde o curso diz 3.13, e nada
mais muda até a aula 5, cuja CI quer as três versões; essa aula diz o que fazer com menos.

## A contagem não é 31

A suíte rodou e disse outra coisa que não `31 passed`. Um número menor costuma querer dizer que um
arquivo está faltando, ou foi salvo com outro nome: o pytest só coleta arquivos cujo nome começa
com `test_`. `python -m pytest --collect-only -q` lista cada teste que encontrou, um por linha, com
o arquivo, e o que falta na lista é o arquivo para olhar.
