---
title: Capturando com tcpdump
version: 1
---

Primeiro, algo para baixar: uma lista de preços de 3.000 linhas, feita por um laço do shell, servida pelo mesmo
pequeno servidor web do Python que a aula 13 usou, desta vez a partir de uma pasta própria:

```
root@soc:~# mkdir www; for i in $(seq 1 3000); do echo "item-$i,$((i * 37 % 900)).90"; done > www/price-list.csv
root@soc:~# ls -l www
total 52
-rw-r--r-- 1 root root 49524 Oct  7 21:10 price-list.csv
root@soc:~# ip netns exec outside python3 -m http.server 8080 --directory www >/dev/null 2>&1 &
```

Agora a captura. O `tcpdump` roda no `fw`, na `eth0`, o lado da internet; `-w` escreve os pacotes brutos num
arquivo em vez de imprimi-los; e as últimas palavras são um **filtro de captura**, `host 192.168.20.10`, para só
guardar pacotes de ou para o `files`. Enquanto ele roda, o `files` baixa a lista:

```
root@soc:~# ip netns exec fw tcpdump -i eth0 -w web.pcap host 192.168.20.10 2>tcpdump.err &
root@soc:~# ip netns exec files curl -s -o /dev/null -w "%{http_code} %{size_download}\n" http://203.0.113.200:8080/price-list.csv
200 49524
root@soc:~# pkill -x tcpdump; sleep 1; cat tcpdump.err
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
20 packets captured
20 packets received by filter
0 packets dropped by kernel
root@soc:~# install -o ana -m 600 web.pcap /home/ana/
```

O `curl` informa um `200` e 49.524 bytes, o tamanho do arquivo. O `pkill -x tcpdump` para a captura; `-x` casa com
o nome do processo exatamente, então nada mais com "tcpdump" na linha de comando é afetado. O resumo do próprio
tcpdump diz **20 packets captured** e **0 dropped by kernel**: esse último número vale ser lido toda vez, porque
uma captura que descartou pacotes está sem parte da conversa, e a lacuna fica invisível depois.

O filtro de captura é escrito na sintaxe **BPF** (Berkeley Packet Filter), a mesma usada por toda ferramenta
construída sobre a `libpcap`: `host`, `net 192.168.20.0/24`, `port 443`, `tcp`, combinados com `and`, `or` e
`not`. Ele decide o que é **guardado**. O que ele deixa de fora nunca foi gravado, então num incidente de verdade
o filtro fica amplo.

A última linha copia o arquivo para a ana. Capturar precisa de root, porque lê a placa de rede diretamente; ler um
arquivo de captura não precisa, e a análise é melhor feita sem root, para um erro num comando não conseguir
danificar o sistema.
