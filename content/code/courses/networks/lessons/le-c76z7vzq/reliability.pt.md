---
title: Perdendo pacotes e entregando assim mesmo
version: 2
---

As confirmações são o que deixa o TCP prometer a entrega. Quando um segmento não é confirmado a tempo,
quem mandou manda de novo. O kernel conta cada retransmissão, e o `nstat` imprime o contador. Primeiro
a lista de preços da aula 2, 186893 bytes, numa rede saudável. Se o seu laboratório foi reiniciado
depois da aula 2, ponha a lista de preços de volta antes, da sua máquina virtual:

```sh
sudo bash ~/netlab/netlab exec www root 'for i in $(seq 1 2000); do echo "line $i of the price list, padded to a hundred characters so the file is large enough ....."; done > /var/www/example/prices.txt'
```

```
ana@www:~$ nstat -az TcpRetransSegs
#kernel
TcpRetransSegs                  0                  0.0
ana@laptop:~$ curl -sS -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' https://www.example.com/prices.txt
200 186893 bytes in 0.023639 s
ana@www:~$ nstat -az TcpRetransSegs
#kernel
TcpRetransSegs                  0                  0.0
```

Nenhuma retransmissão, e 0,024 segundo. Depois o roteador do escritório passa a perder um em cada cinco
pacotes que o servidor web manda, e o mesmo arquivo é buscado de novo. A regra, da sua máquina
virtual, e a que a tira depois; a perda é aleatória, então a sua contagem não vai ser 46:

```sh
sudo bash ~/netlab/netlab exec router root 'nft add table inet lossy; nft add chain inet lossy forward "{ type filter hook forward priority 0; }"; nft add rule inet lossy forward tcp sport 443 numgen random mod 100 lt 20 drop'
sudo bash ~/netlab/netlab exec router root 'nft delete table inet lossy'
```

```
ana@laptop:~$ curl -sS -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' https://www.example.com/prices.txt
200 186893 bytes in 1.048856 s
ana@www:~$ nstat -az TcpRetransSegs
#kernel
TcpRetransSegs                  46                 0.0
```

**Os 186893 bytes chegaram, e o programa nunca soube que algo deu errado.** O servidor teve de mandar
46 segmentos de novo, e o download levou 1,05 segundo em vez de 0,024, mais de quarenta vezes mais. Essa é
a troca que o TCP faz: ele transforma perda em demora.

Essa troca é a lição de diagnóstico. **Uma rede que perde pacotes parece lenta, não quebrada**: páginas
que carregam, uma hora; uma chamada de vídeo que engasga; uma cópia de arquivo muito abaixo da
velocidade da linha. Quando algo está lento e nada está fora do ar, vale ler os contadores de perda. O
`nstat` no Linux, e em qualquer sistema, `ping -c 100` até a outra ponta: poucos por cento de pings
perdidos bastam para fazer toda conexão TCP por aquele caminho se arrastar.
