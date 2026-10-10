---
title: Quando a instalação falha
version: 1
---

Instalar é onde a maioria desiste de um curso assim, quase sempre por uma linha de saída que
parecia uma catástrofe e era uma coisa pequena. Estas são as falhas que aparecem seguindo as duas
últimas seções, cada uma com o que ela imprime e o que a resolve. As do Linux foram produzidas de
propósito na máquina de onde vêm as transcrições; a do Windows não foi executada, e diz isso.

## `can't open file`

O terminal não está no diretório onde o `boxoffice.py` foi salvo:

```
ana@laptop:~$ python3 boxoffice.py
python3: can't open file '/home/ana/boxoffice.py': [Errno 2] No such file or directory
```

O caminho na mensagem é onde o Python procurou, e o prompt diz o mesmo: `~`, o diretório pessoal,
e não `~/boxoffice`. **Rode `cd ~/boxoffice` antes.** Se o erro continua no diretório certo, o
arquivo foi salvo com outro nome; no Windows, o Bloco de Notas gosta de salvar como
`boxoffice.py.txt`, que o Explorador de Arquivos esconde a menos que você ligue as extensões de
nome de arquivo.

## `python3` abre uma loja, ou não é encontrado, no Windows

No Windows, digitar `python3` com o Python instalado pelo python.org pode abrir a Microsoft Store em
vez de rodar alguma coisa, porque o Windows traz um atalho com esse nome. Digite `python
boxoffice.py` ou `py boxoffice.py`. Se nenhum dos dois é encontrado, o instalador rodou sem **Add
python.exe to PATH**; rode de novo, escolha Modify e marque a opção. Isto não foi executado para
este curso.

## `IndentationError`

Uma linha do programa perdeu a indentação no caminho até o editor:

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
  File "/home/ana/boxoffice/boxoffice.py", line 57
    return f"R$ {reais},{cents % 100:02d}"
IndentationError: unexpected indent
```

O Python lê indentação como estrutura, então uma linha com dois espaços ao lado de uma com quatro é
outro programa, ou programa nenhum. A mensagem cita o arquivo e a linha, mas a linha citada muitas
vezes é a que vem *depois* do estrago, aqui a 57, abaixo da linha que perdeu dois espaços. **Copie
o arquivo inteiro de novo pelo botão do bloco** em vez de consertar no olho.

## `Address already in use`

A aplicação já está rodando, em outro terminal ou num que você esqueceu atrás de uma janela, e uma
segunda cópia não consegue pegar a mesma porta:

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
boxoffice 1.0 on http://127.0.0.1:8000  (Ctrl-C stops it)
Traceback (most recent call last):
  File "/home/ana/boxoffice/boxoffice.py", line 260, in <module>
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
    ~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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
```

Leia um traceback de baixo para cima: a última linha é a causa, e tudo acima dela é o caminho até
lá. **Ache a outra cópia e pare com Ctrl-C.** Se não achar, inicie esta em outra porta,
`BOXOFFICE_PORT=8001 python3 boxoffice.py`, e use `8001` onde o curso escreve `8000`. Algo que não é
o boxoffice também pode estar ocupando a porta; a mesma variável contorna.

## `Couldn't connect to server`

Nada está escutando no endereço que o curl ou o navegador pediu:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Couldn't connect to server
```

O servidor não está rodando. Ou nunca foi iniciado, ou o terminal dele foi fechado, o que o para,
ou ele parou com um erro que você ainda não leu. **Olhe o terminal onde você o iniciou.** Um
navegador diz a mesma coisa com as palavras dele, *não é possível conectar* ou *não é possível
acessar esse site*. E confira o endereço: `https` em vez de `http` também falha, porque o boxoffice
não fala esse protocolo.

## A página mostra outra coisa que não o curso

Três espetáculos, os lugares cheios, a conta da Bia Souza e nenhum pedido: essa é a aplicação logo
depois de iniciar. Uma aula cuja transcrição mostra o pedido 1001 quando a sua mostra 1004 é uma
aula que você começou depois de reservar outra coisa. **Pare a aplicação e inicie de novo** antes de
cada aula que reserva, e os números se alinham.
