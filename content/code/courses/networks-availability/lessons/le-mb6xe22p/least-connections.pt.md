---
title: Least connections, para requisições que não são iguais
version: 1
---

Os servidores do laboratório também têm o `slow.txt`, 3000 bytes que o `nginx` foi configurado para enviar
a 1000 bytes por segundo, então uma requisição dele ocupa um servidor por uns três segundos. O laptop começa
a baixá-lo em segundo plano, espera 0,3 segundo e envia quatro requisições comuns. Os pesos da seção
anterior continuam valendo:

```
ana@laptop:~$ curl -s -o /dev/null http://www.example.com/slow.txt & sleep 0.3; for i in 1 2 3 4; do curl -s http://www.example.com/; done; wait
served by web2
served by web1
served by web3
served by web1
```

A resposta do download foi para `/dev/null`, então a transcrição não diz qual servidor ficou com ele. Nem
precisa. **O round robin distribuiu as quatro requisições na ordem fixa dele, `web1` duas vezes, fizesse o
que fizesse cada servidor**, e um dos três estava naquele momento ocupado enviando o arquivo. Com um
download lento isso custa pouco. Com algumas centenas, um servidor que pegou vários continua recebendo a
parte inteira dele de trabalho novo por cima.

**O least connections faz outra pergunta: qual servidor tem menos conexões abertas agora?** O mesmo teste,
com `balance leastconn`:

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance leastconn
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
ana@laptop:~$ curl -s -o /dev/null http://www.example.com/slow.txt & sleep 0.3; for i in 1 2 3 4; do curl -s http://www.example.com/; done; wait
served by web2
served by web3
served by web2
served by web3
```

`web2`, `web3`, `web2`, `web3`. **`web1` não recebeu nenhuma das quatro**, que é exatamente o que a regra
diz que deve acontecer com o único servidor que ainda tinha uma conexão aberta, o download lento. Os
outros dois ficavam ociosos entre uma requisição e outra, então se alternaram.

O HAProxy mostra as próprias contas. O laptop começa mais um download lento, e meio segundo depois as
estatísticas de `lb1` são lidas pelo socket de controle dele:

```
ana@lb1:~$ echo "show stat" | sudo socat stdio /run/haproxy.sock | cut -d, -f1,2,5 | grep -E "^web,web"
web,web1,0
web,web2,1
web,web3,0
```

O `show stat` imprime uma linha longa de campos separados por vírgula para cada servidor, e o `cut` guarda
três: o backend, o servidor e o quinto campo, **`scur`, as conexões abertas naquele momento**. A linha de
cabeçalho que dá nome aos campos foi filtrada pelo `grep`. `web2` tem uma, o download; os outros dois não
têm nenhuma, então a próxima requisição vai para um deles.

| | round robin | least connections |
|---|---|---|
| decide pelo | próximo nome da lista | menor número de conexões abertas agora |
| sabe dos servidores | nada | as conexões abertas deles |
| serve para | muitas requisições curtas de custo parecido | requisições longas ou desiguais: downloads, WebSockets, sessões de banco de dados |
| pesos | vezes por rodada | as conexões são comparadas na proporção do peso |

Num site de páginas pequenas os dois se comportam quase igual, porque cada conexão fecha antes de a próxima
chegar e todas as contas ficam em zero. **A diferença só aparece quando algumas requisições duram muito
mais que outras**, e aí é o least connections que percebe.
