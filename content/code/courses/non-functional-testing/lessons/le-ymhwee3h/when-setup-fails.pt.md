---
title: Quando a montagem falha
version: 1
---

A maioria das pessoas que desistem de um curso como este desiste aqui, diante de uma mensagem de erro
sobre uma máquina que ainda não terminaram de montar. Estas são as falhas que de fato acontecem, na
ordem em que você as encontraria, com o que cada uma quer dizer.

**A máquina virtual não inicia, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte
à virtualização do processador está desligado no firmware do computador. É uma opção no menu da BIOS
ou da UEFI, em geral em *Advanced* ou *CPU configuration*, e muitos notebooks saem de fábrica com ela
desligada. Nenhum programa liga isso por você. No Windows, o Hyper-V e o WSL também podem segurá-la,
e aí o VirtualBox roda devagar ou não roda; o Multipass no Windows usa o próprio Hyper-V e evita a
briga.

**O `multipass launch` diz que não há memória suficiente, ou o computador se arrasta depois que ela
sobe.** Os quatro gigabytes da VM são somados ao que o seu sistema já usa. Num computador com 8 GB no
total, feche as abas do navegador de que não precisa, ou crie a máquina com `--memory 3G --cpus 2`:
todas as aulas continuam funcionando, mais devagar.

**O `multipass launch` estoura o tempo.** A primeira criação baixa uma imagem do Ubuntu de algumas
centenas de megabytes, e uma conexão lenta demora mais que a espera padrão. O `multipass launch`
aceita `--timeout 1800`; dê esse tempo e deixe terminar.

**O `apt-get` diz que não conseguiu pegar uma trava.** O Ubuntu roda as próprias atualizações nos
primeiros minutos depois que uma máquina liga, e só um programa por vez pode instalar pacotes. Espere
até `pgrep -c apt` imprimir `0` e rode o comando de novo. Apagar o arquivo de trava é o conselho que
você vai achar na internet, e é assim que um banco de pacotes se corrompe.

**O `apt-get` diz `Unable to locate package`.** Ou o `sudo apt-get update` foi pulado, ou a máquina
não é Ubuntu 24.04. `grep PRETTY /etc/os-release` resolve a dúvida; os nomes de pacote deste curso
são os do 24.04.

**O servidor diz `Address already in use`.** Outro programa já escuta na porta 8000, e quase sempre é
um `app.py` anterior que você esqueceu em outro terminal:

```
ana@nft:~/boxoffice$ python3 app.py
Traceback (most recent call last):
  File "/home/ana/boxoffice/app.py", line 106, in <module>
    server = ThreadingHTTPServer((host, 8000), Box)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/socketserver.py", line 457, in __init__
    self.server_bind()
  File "/usr/lib/python3.12/http/server.py", line 136, in server_bind
    socketserver.TCPServer.server_bind(self)
  File "/usr/lib/python3.12/socketserver.py", line 473, in server_bind
    self.socket.bind(self.server_address)
OSError: [Errno 98] Address already in use
```

Ache-o com `ss -ltnp 'sport = :8000'`, que mostra o nome do processo, e pare-o com `Ctrl+C` no
terminal dele, ou com `kill` e o número de processo que o `ss` mostrou.

**O `curl` não imprime nada.** A opção `-s`, que tira as barras de progresso das transcrições, também
esconde os erros do próprio curl, então um servidor que não está rodando parece um servidor que
respondeu com nada. `echo $?` depois dele mostra o código de saída do curl, e `-sS` mantém o silêncio
mas mostra o erro:

```
ana@nft:~/boxoffice$ curl -s localhost:8000/health; echo "exit $?"
exit 7
ana@nft:~/boxoffice$ curl -sS localhost:8000/health
curl: (7) Failed to connect to localhost port 8000 after 0 ms: Couldn't connect to server
```

O código de saída 7 quer dizer que nada estava escutando: o servidor está parado, ou está rodando em
outra máquina, o que acontece quando o segundo terminal foi aberto no seu computador em vez de com
`multipass shell nft`.

**O Python acusa `IndentationError` ou `SyntaxError` num arquivo que você colou.** Alguns terminais
acrescentam espaços ou perdem uma linha quando uma colagem longa passa por eles. Abra o arquivo com
`nano`, vá até o número de linha da mensagem com `Ctrl+_` e compare com a aula. Copiar com o botão no
canto do bloco, em vez de selecionar com o mouse, evita quase tudo isso.

**`sqlite3.OperationalError: unable to open database file`.** O servidor foi iniciado de uma pasta que
não é `~/boxoffice`, então `data/boxoffice.db` não está onde ele procura. Faça `cd ~/boxoffice`
antes; todo comando das aulas de desempenho supõe isso.

**E quando nada mais funciona**, apague a máquina e monte de novo: `multipass delete --purge nft` no
terminal do seu computador, depois os comandos desta aula outra vez. Parece desistir, e é o que
profissionais fazem com uma máquina cujo estado ninguém consegue mais explicar. A sua `~/boxoffice`
vai junto, e é por isso que todo arquivo de que você precisa está impresso numa aula.
