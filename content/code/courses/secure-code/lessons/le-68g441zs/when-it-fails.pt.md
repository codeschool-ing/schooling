---
title: Quando o laboratório não funciona
version: 1
---

Um laboratório que falha na primeira noite é onde um curso é abandonado, por isso as quatro falhas
abaixo foram reproduzidas de propósito na máquina da gravação. Cada uma tem uma mensagem que diz o que
está errado, para quem sabe ler.

### O ambiente não está ativo

Um terminal novo começa sem o ambiente virtual. O Python está lá, o Flask não, porque o Flask foi
instalado em `~/sc/.venv` e em nenhum outro lugar:

```
(.venv) ana@vm:~/sc$ deactivate
ana@vm:~/sc$ python3 -c 'import flask'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import flask
ModuleNotFoundError: No module named 'flask'
```

**O prompt denuncia**: não há `(.venv)` no começo dele. `cd ~/sc` e `. .venv/bin/activate`, e o
mesmo comando funciona. Outras duas falhas são do Debian e do Ubuntu e não foram reproduzidas aqui.
Se o `python3 -m venv` reclamar do `ensurepip`, falta o pacote `python3-venv`: instale, apague a
`.venv` e crie de novo. Se o pip recusar com uma mensagem sobre um **ambiente gerenciado
externamente** (*externally managed environment*), ele rodou fora do ambiente virtual, contra o
Python do próprio sistema. Ative a `.venv` e tente de novo, e nunca apele para `sudo pip`.

### O Flask não acha a aplicação

`flask --app app` quer dizer *importe o módulo `app`* da pasta em que você está. Rodado da pasta
errada, não há `app.py` para importar:

```
(.venv) ana@vm:~/sc$ flask --app app run
Usage: flask run [OPTIONS]
Try 'flask run --help' for help.

Error: Could not import 'app'.
```

A saída é `cd ~/sc/cancel`. A pasta de cada aula tem o seu próprio `app.py`, então a pasta em que
você está decide qual aplicação inicia.

### A porta 5000 está ocupada

Só um programa por vez ouve numa porta. A causa comum é uma aplicação de antes ainda rodando em
outro terminal; com uma já iniciada, uma segunda avisa:

```
(.venv) ana@vm:~/sc/cancel$ flask --app app run
 * Serving Flask app 'app'
 * Debug mode: off
Address already in use
Port 5000 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

No macOS a mesma mensagem continua e aponta uma causa que surpreende: desde o macOS 12 o **AirPlay
Receiver** ouve na porta 5000, então a porta já está ocupada antes de você iniciar qualquer coisa.
Essa linha não foi gravada aqui, porque a máquina da gravação roda Linux. Desligue o receptor nos
ajustes do sistema, ou dê outra porta ao Flask com `--port 5001` e use esse número onde uma aula
escrever 5000.

### Os testes não acham nada, ou acham a coisa errada

O pytest coleta arquivos chamados `test_*.py` ou `*_test.py` e, dentro deles, funções cujo nome
começa com `test`. Um arquivo salvo como `tests_app.py` nunca é aberto, e uma função chamada
`check_cancel` nunca roda. Se o `pytest` relatar menos testes do que a aula mostra, compare os nomes
antes de qualquer outra coisa.

### E se ainda estiver quebrado

Apague a pasta da aula e monte de novo a partir das listagens: elas são curtas, e todo arquivo que as
aulas usam aparece inteiro. Para o ambiente em si, `rm -rf ~/sc/.venv` e repita os passos do
`python3 -m venv` e do `pip install`; as pastas das aulas não são afetadas.
