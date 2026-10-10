---
title: Três falhas que parecem a mesma
version: 1
---

**Para a máquina que perguntou, uma máquina que caiu, uma rede cortada e uma máquina que só está lenta
parecem uma coisa só: nenhuma resposta ainda.** A ferramenta para decidir que uma resposta não vem é
um timeout, e um timeout diz quanto tempo você esperou. Ele não diz o que aconteceu.

As três, como acontecem do outro lado:

- uma queda: o processo ou a máquina inteira parou;
- uma partição de rede: as duas máquinas estão bem e o link entre elas está cortado, então
  nenhuma alcança a outra;
- um nó lento: a máquina está viva e trabalhando, e está sobrecarregada, ou pausada, ou esperando
  um disco que está falhando.

## Três nós de mentira

O programa abaixo faz o papel de dois nós na sua própria máquina. Na porta 8001, um nó que responde
com três segundos de atraso. Na porta 8002, um nó que aceita a conexão e depois nunca diz nada, que é
como fica um processo travado. A porta 8003 não tem nada escutando. Salve como `nodes.py`:

```python
# spread/nodes.py
import socket
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Slow(BaseHTTPRequestHandler):
    def do_GET(self):
        time.sleep(3)                       # alive, and three seconds late
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ST06 has 4 bicycles\n")

    def log_message(self, *args):
        pass


stuck = socket.socket()                     # accepts a connection, never answers
stuck.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
stuck.bind(("127.0.0.1", 8002))
stuck.listen()
ThreadingHTTPServer(("127.0.0.1", 8001), Slow).serve_forever()
```

E um cliente que pergunta a cada um dos três, desistindo depois do número de segundos que receber.
Salve como `probe.py`:

```python
# spread/probe.py
import sys
import urllib.request

timeout = float(sys.argv[1])
for name, port in (("slow", 8001), ("stuck", 8002), ("stopped", 8003)):
    try:
        url = f"http://127.0.0.1:{port}/"
        with urllib.request.urlopen(url, timeout=timeout) as reply:
            print(f"{name:8} answered: {reply.read().decode().strip()}")
    except Exception as error:
        print(f"{name:8} {type(error).__name__}: {error}")
```

Rode `python nodes.py` num segundo terminal, em `~/roda/spread`. Ele não imprime nada e continua
rodando até você apertar Ctrl+C. Depois, no primeiro terminal, sonde com um timeout de um segundo e
com um de cinco:

```
ana@lab:~/roda/spread$ python probe.py 1
slow     TimeoutError: timed out
stuck    TimeoutError: timed out
stopped  URLError: <urlopen error [Errno 111] Connection refused>
ana@lab:~/roda/spread$ python probe.py 5
slow     answered: ST06 has 4 bicycles
stuck    TimeoutError: timed out
stopped  URLError: <urlopen error [Errno 111] Connection refused>
```

Com um segundo, o nó lento e o travado imprimem a mesma linha, `TimeoutError: timed out`. Um deles
teria respondido em mais dois segundos e o outro nunca vai responder, e o cliente não tem como saber
qual é qual. Com cinco segundos o nó lento responde, o travado continua estourando o tempo, e nada
nessa linha diz se ele responderia em dez segundos ou nunca.

A terceira linha é diferente, e a diferença deixa o ponto mais nítido. Uma máquina ligada, sem nada
naquela porta, responde na hora: `Connection refused` é uma resposta. Uma máquina desligada, ou do
outro lado de um link cortado, não devolve nada, e o cliente fica de novo com um timeout.

## Escolher um timeout

Não existe valor certo, só dois jeitos de errar. Curto demais, e um nó que estava só lento é
declarado morto: o trabalho dele vai para os outros, que agora ficam mais ocupados, e se ele era um
líder, um seguidor é promovido enquanto o líder antigo continua trabalhando. Longo demais, e toda
falha de verdade deixa alguém esperando o tempo inteiro antes de qualquer providência. A prática
comum é observar quanto as respostas demoram quando tudo está saudável e pôr o timeout com folga
acima da mais lenta delas, e então deixar uma pessoa decidir o que "com folga" quer dizer para aquele
sistema.

## Heartbeats

Esperar um pedido falhar é um jeito lento de descobrir uma máquina morta, então a maioria dos
sistemas também manda **heartbeats**, batimentos: cada nó manda uma mensagem curta de "ainda estou
aqui" para os outros, ou para um coordenador, a cada segundo ou perto disso. Um nó que perde vários
seguidos é **presumido** morto, e o trabalho dele é entregue aos outros.

Presumido é a palavra honesta. O nó pode estar vivo do outro lado de uma partição, ainda atendendo os
clientes que conseguem alcançá-lo, ainda achando que é o líder. Esse é o split brain da seção 06, e
decidir o que um sistema deve fazer a respeito é onde a aula 10 começa.

Quando terminar, aperte Ctrl+C no segundo terminal para parar o `nodes.py`.
