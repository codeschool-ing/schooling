---
title: Muitas conexões, um endereço, separadas pela porta
version: 1
---

Reescrever só o endereço deixaria sair uma conversa por destino de cada vez: com todo pacote saindo
de 203.0.113.2, duas respostas do mesmo servidor para a mesma porta seriam indistinguíveis. **O PAT,
tradução de endereço e porta, também reescreve a porta de origem quando precisa, para que cada conexão
continue única vista de fora.** É o que o `masquerade` do r1 faz e o que todo roteador doméstico faz,
e no dia a dia se chama simplesmente NAT; a Cisco chama de NAT overload.

A aula 5 deu a regra que o PAT precisa manter: uma conexão são quatro números, e duas conexões não
podem ter os quatro iguais. Para ver o r1 mantê-la, três PCs conectam ao mesmo tempo em `192.0.2.80`
porta 80, e dois deles insistem na mesma porta de origem: o pc1 e o pc2 pedem a 40000, o pc3 a 51000.
A tabela do r1, esvaziada logo antes, fica assim:

```
root@r1:~# conntrack -L -p tcp
conntrack v1.4.8 (conntrack-tools): 3 flow entries have been shown.
tcp      6 431998 ESTABLISHED src=10.20.10.23 dst=192.0.2.80 sport=51000 dport=80 src=192.0.2.80 dst=203.0.113.2 sport=80 dport=51000 [ASSURED] mark=0 use=1
tcp      6 431998 ESTABLISHED src=10.20.10.21 dst=192.0.2.80 sport=40000 dport=80 src=192.0.2.80 dst=203.0.113.2 sport=80 dport=46745 [ASSURED] mark=0 use=1
tcp      6 431998 ESTABLISHED src=10.20.10.22 dst=192.0.2.80 sport=40000 dport=80 src=192.0.2.80 dst=203.0.113.2 sport=80 dport=40000 [ASSURED] mark=0 use=1
```

Cada linha tem duas metades, como na aula 5: a conexão como o PC a mandou, e depois a resposta que o
r1 espera. Por extenso:

| PC | mandou de | sai como | resposta esperada em |
|---|---|---|---|
| pc3 | 10.20.10.23:51000 | 203.0.113.2:51000 | 203.0.113.2:51000 |
| pc1 | 10.20.10.21:40000 | 203.0.113.2:46745 | 203.0.113.2:46745 |
| pc2 | 10.20.10.22:40000 | 203.0.113.2:40000 | 203.0.113.2:40000 |

O pc3 e o pc2 mantiveram as portas: nada mais usava a 51000 ou a 40000 para aquele servidor, então só
o endereço precisou mudar. O pc1 pediu a 40000 quando o pc2 já a tinha. Mantê-la tornaria as duas
conexões idênticas vistas de fora — 203.0.113.2 porta 40000 para 192.0.2.80 porta 80, duas vezes — então
o r1 deu ao pc1 a porta **46745** e a traduz de volta em cada resposta. **Uma porta só é reescrita
quando mantê-la faria duas conexões ficarem iguais vistas de fora.**

Os outros campos: `6` é o número do protocolo TCP; `431998` são os segundos que faltam para uma entrada
parada ser esquecida, porque uma conexão TCP estabelecida é guardada por cinco dias, 432000 segundos, e
dois já passaram; `[ASSURED]` quer dizer que já passou tráfego nos dois sentidos.

De fora, o efeito é que o escritório inteiro é um endereço com muitas portas. No isp, o roteador do
provedor, uma captura vigiou os pacotes que abrem conexões TCP (SYN) enquanto o pc1, o pc2 e o pc3
buscavam a mesma página:

```
ana@pc1:~$ curl -s http://192.0.2.80/
served by web2
ana@pc2:~$ curl -s http://192.0.2.80/
served by web1
ana@pc3:~$ curl -s http://192.0.2.80/
served by web2
root@isp:~# timeout 8 tcpdump -n -i eth1 -c 3 "tcp[tcpflags] == tcp-syn"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:24:55.380912 IP 203.0.113.2.45602 > 192.0.2.80.80: Flags [S], seq 3108904710, win 64240, options [mss 1460,sackOK,TS val 3435536978 ecr 0,nop,wscale 7], length 0
08:24:56.561483 IP 203.0.113.2.50074 > 192.0.2.80.80: Flags [S], seq 1287844257, win 64240, options [mss 1460,sackOK,TS val 2920209295 ecr 0,nop,wscale 7], length 0
08:24:57.776959 IP 203.0.113.2.40738 > 192.0.2.80.80: Flags [S], seq 659442927, win 64240, options [mss 1460,sackOK,TS val 4149592587 ecr 0,nop,wscale 7], length 0
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

Os três `curl` rodaram primeiro e imprimiram as páginas — `served by web2` e `served by web1` são o
balanceador de carga da aula 1 se revezando — e a captura do isp foi impressa quando terminou. Três
conexões, três portas de origem, `45602`, `50074` e `40738`, e um endereço, `203.0.113.2`. Nada nessas
linhas diz qual PC era qual; só a tabela do r1 sabe.

Quantas conexões cabem atrás de um endereço? O campo da porta tem 16 bits, então dezenas de milhares
para um mesmo endereço e porta de destino, e mais no total, já que uma porta em uso para um servidor
pode ser usada de novo para outro: os quatro números continuam diferentes. Num roteador movimentado, o
limite que aperta primeiro é o tamanho da tabela.
