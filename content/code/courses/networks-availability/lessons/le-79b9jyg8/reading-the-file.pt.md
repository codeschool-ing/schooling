---
title: Perguntando ao servidor, e lendo o arquivo de uma falha
version: 1
---

Uma captura mostra o que passou pelo fio, e o certificado não passou numa forma que alguém consiga
ler. **O `openssl s_client` se conecta como um cliente faria e imprime o que lhe foi mostrado**, e
isso faz dele o complemento da captura:

```
ana@laptop:~$ openssl s_client -connect 192.0.2.21:8443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|issuer=|NotAfter|Verify return code"
   v:NotBefore: Jan  1 00:00:00 2025 GMT; NotAfter: Jan  1 00:00:00 2026 GMT
subject=CN = www.example.com
issuer=O = Example Lab, CN = Example Lab Root CA
Verify return code: 10 (certificate has expired)
ana@laptop:~$ openssl s_client -connect 192.0.2.21:9443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|Verify return code"
subject=CN = shop.example.net
Verify return code: 0 (ok)
ana@laptop:~$ openssl s_client -connect 192.0.2.21:10443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|issuer=|Verify return code"
subject=CN = www.example.com
issuer=O = Nobody, CN = Nobody Root CA
Verify return code: 21 (unable to verify the first certificate)
```

O vencido é a leitura fácil: `NotAfter: Jan  1 00:00:00 2026 GMT`, e o código de verificação **10,
certificate has expired**. A autoridade desconhecida aparece com nome e tudo, `Nobody Root CA`, com o
código **21, unable to verify the first certificate**: o `openssl` não conseguiu montar uma cadeia
desse certificado até algo em que confia. Duas ferramentas, duas redações, uma causa.

**O do meio é a armadilha.** A porta 9443 respondeu `Verify return code: 0 (ok)` para um certificado
emitido para `shop.example.net`, quando o laptop pediu `www.example.com`. O código 0 quer dizer que a
cadeia está boa: uma autoridade confiável assinou e ele está dentro da validade. **Ele não diz nada
sobre o nome**, porque o `s_client` só confere o nome quando pedem, com `-verify_hostname`, que não foi
rodado aqui. O `-servername` só manda o SNI. A linha `subject=` é onde a divergência aparece, e lê-la é
trabalho seu.

## O arquivo como dado

O caso do vencido foi capturado mais uma vez, inteiro, num arquivo, e lido linha a linha. Enquanto a
captura de quatro segundos rodava, o laptop fez o pedido à porta 8443 de novo, desta vez com `-s`, para
que o `curl` não imprimisse nada:
`curl -s --resolve www.example.com:8443:192.0.2.21 https://www.example.com:8443/`.

```
ana@laptop:~$ tshark -n -q -i eth0 -a duration:4 -f "host 192.0.2.21" -w failing.pcap
Capturing on 'eth0'
10 packets captured
ana@laptop:~$ tshark -r failing.pcap
    1 0.000000000 192.168.10.20 → 192.0.2.21   TCP 74 41122 → 8443 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3105821767 TSecr=0 WS=1024
    2 0.000076393   192.0.2.21 → 192.168.10.20 TCP 74 8443 → 41122 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM TSval=885483827 TSecr=3105821767 WS=1024
    3 0.000088252 192.168.10.20 → 192.0.2.21   TCP 66 41122 → 8443 [ACK] Seq=1 Ack=1 Win=64512 Len=0 TSval=3105821767 TSecr=885483827
    4 0.001797118 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    5 0.001844791   192.0.2.21 → 192.168.10.20 TCP 66 8443 → 41122 [ACK] Seq=1 Ack=518 Win=65536 Len=0 TSval=885483829 TSecr=3105821769
    6 0.002697896   192.0.2.21 → 192.168.10.20 TLSv1.3 1509 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    7 0.002707083 192.168.10.20 → 192.0.2.21   TCP 66 41122 → 8443 [ACK] Seq=518 Ack=1444 Win=67584 Len=0 TSval=3105821770 TSecr=885483830
    8 0.026241284 192.168.10.20 → 192.0.2.21   TLSv1.3 73 Alert (Level: Fatal, Description: Certificate Expired)
    9 0.026495654   192.0.2.21 → 192.168.10.20 TCP 66 8443 → 41122 [FIN, ACK] Seq=1444 Ack=525 Win=65536 Len=0 TSval=885483854 TSecr=3105821793
   10 0.026835405 192.168.10.20 → 192.0.2.21   TCP 66 41122 → 8443 [RST, ACK] Seq=525 Ack=1445 Win=67584 Len=0 TSval=3105821794 TSecr=885483854
```

Dez pacotes, e dá para explicar cada um deles.

| quadros | o que aconteceu |
|---|---|
| 1 a 3 | o handshake TCP para a porta 8443, como na primeira seção |
| 4 | o Client Hello, 583 bytes, com o SNI |
| 5 | `web1` confirma: `Ack=518`, o próximo byte depois de 517 bytes de TLS contados a partir de 1 |
| 6 | o Server Hello e o certificado criptografado, 1509 bytes |
| 7 | o laptop os confirma, `Ack=1444` |
| 8 | o alerta do laptop: `Certificate Expired`, 7 bytes de TLS |
| 9 | `web1` fecha o lado dele, `FIN` |
| 10 | o laptop responde com `RST`: ele já tinha fechado a conexão |

**O intervalo entre os quadros 7 e 8 é de 23 milissegundos, e não é a rede.** Neste laboratório todo
enlace é um computador falando consigo mesmo, e os quadros 6 e 7 estão a nove microssegundos um do
outro; os 23 ms são o laptop conferindo o certificado antes de responder. O handshake bom teve uma
pausa de tamanho parecido antes do quadro 8 dele.

**Um arquivo assim é dado, e pode ser repassado**, como a aula 12 fez: para um colega, para um
fornecedor, para o chamado. Qualquer um consegue lê-lo e chegar à mesma conclusão sem ter estado lá.
Esse é o motivo de capturar a falha em vez de descrevê-la: "o TLS falha" é uma opinião, e o quadro 8 é
um fato.
