---
title: Quando a montagem falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, diante de uma mensagem de erro
sobre uma máquina que ainda não terminou de montar. Estas são as falhas que de fato acontecem, na ordem
em que você as encontraria, com o que cada uma quer dizer.

**A máquina virtual não inicia, e a mensagem fala em virtualização, VT-x, AMD-V ou SVM.** O suporte do
processador à virtualização está desligado no firmware do computador. É uma opção no menu da BIOS ou
da UEFI, em geral em *Advanced* ou *CPU configuration*, e muitos notebooks vêm com ela desligada.
Nenhum programa consegue ligá-la por você. No Windows, o Hyper-V e o WSL também podem segurá-la, e aí
o VirtualBox fica lento ou nem roda; o Multipass no Windows usa o próprio Hyper-V e evita a briga.

**`multipass launch` estoura o tempo.** O primeiro launch baixa uma imagem do Ubuntu de várias
centenas de megabytes, e uma conexão lenta demora mais do que a espera padrão. O `multipass launch`
aceita `--timeout 1800`; dê esse tempo e deixe terminar.

**`apt-get` diz que não conseguiu obter um lock.** O Ubuntu roda as próprias atualizações nos
primeiros minutos depois que a máquina liga, e só um programa por vez pode instalar pacotes. Espere até
`pgrep -c apt` imprimir `0` e rode o comando de novo. Apagar o arquivo de lock é o conselho que você vai
achar na internet, e é assim que um banco de pacotes se corrompe.

**`apt-get` diz `Unable to locate package`.** Ou o `sudo apt-get update` ficou para trás, ou a máquina
não é Ubuntu 24.04. `grep PRETTY /etc/os-release` resolve a dúvida; os nomes de pacote deste curso são
os do 24.04.

**O servidor diz `Address already in use`.** Outro programa já escuta na porta 8000, e quase sempre é
um `rest.py` anterior esquecido em outro terminal:

```
ana@api:~/shelf$ python3 rest.py
Traceback (most recent call last):
  File "/home/ana/shelf/rest.py", line 196, in <module>
    server = ThreadingHTTPServer(("127.0.0.1", 8000), Shelf)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/socketserver.py", line 457, in __init__
    self.server_bind()
  File "/usr/lib/python3.12/http/server.py", line 136, in server_bind
    socketserver.TCPServer.server_bind(self)
  File "/usr/lib/python3.12/socketserver.py", line 473, in server_bind
    self.socket.bind(self.server_address)
OSError: [Errno 98] Address already in use
```

Ache-o com `ss -ltnp 'sport = :8000'`, que mostra o processo, e pare-o com `Ctrl+C` no terminal dele,
ou com `kill` e o número de processo que o `ss` imprimiu.

**O `curl` não imprime nada.** A opção `-s`, que mantém as barras de progresso fora das transcrições,
também esconde os erros do próprio curl, então um servidor parado parece um servidor que respondeu
vazio. `echo $?` depois do comando mostra o código de saída do curl, e `-sS` mantém o silêncio mas
mostra o erro:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1; echo "exit $?"
exit 7
ana@api:~/shelf$ curl -sS localhost:8000/v1/books/1
curl: (7) Failed to connect to localhost port 8000 after 0 ms: Couldn't connect to server
```

O código de saída 7 quer dizer que nada estava escutando: o servidor está parado, ou está rodando em
outra máquina, o que acontece quando o segundo terminal foi aberto no seu próprio computador em vez de
com `multipass shell api`.

**O Python acusa `IndentationError` ou `SyntaxError` num arquivo colado.** Alguns terminais acrescentam
espaços ou perdem uma linha quando uma colagem longa passa por eles. Abra o arquivo com o `nano`, vá à
linha citada na mensagem com `Ctrl+_` e compare com a aula. Copiar com o botão no canto do bloco, em
vez de selecionar com o mouse, evita quase tudo isso.

**E quando nada mais funciona**, apague a máquina e monte de novo: `multipass delete --purge api` no
terminal do seu computador, depois os comandos das três seções anteriores. Parece desistir, e é o que
profissionais fazem com uma máquina cujo estado ninguém sabe mais explicar.
