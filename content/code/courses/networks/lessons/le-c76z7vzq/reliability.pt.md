---
title: Perdendo pacotes e entregando assim mesmo
version: 1
---

As confirmações são o que deixa o TCP prometer a entrega. Quando um segmento não é confirmado a tempo,
quem mandou manda de novo. O kernel conta cada retransmissão, e o `nstat` imprime o contador. Primeiro
a lista de preços da aula 2, 186893 bytes, numa rede saudável:

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
pacotes que o servidor web manda, e o mesmo arquivo é buscado de novo:

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
