---
title: Uma sessão TLS que funciona, e três que falham
version: 1
---

A aula 5 de `networks` descreveu o handshake TLS do lado do cliente. Visto do fio, **o TLS 1.3 mostra
muito menos do que mostrava antes, e isso é de propósito.** `web1` serve TLS em quatro portas, cada uma
com um certificado que o `netlab.sh` criou na aula 1. O nome é `www.example.com`, que pertence aos
balanceadores de carga, e eles não estão rodando nesta aula, então cada `--resolve` manda o pedido para
aquele nome e porta ao endereço do próprio `web1`. Aqui ele está funcionando, na porta 443:

```
ana@laptop:~$ curl -sS --resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21 https://www.example.com/
ok
ana@laptop:~$ tshark -n -i eth0 -c 12 -f "host 192.0.2.21 and tcp port 443" -Y tls
Capturing on 'eth0'
6 packets captured
    4 0.001819318 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    6 0.003707199   192.0.2.21 → 192.168.10.20 TLSv1.3 1509 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.026236990 192.168.10.20 → 192.0.2.21   TLSv1.3 146 Change Cipher Spec, Application Data
    9 0.026388693 192.168.10.20 → 192.0.2.21   TLSv1.3 166 Application Data
   10 0.026541364   192.0.2.21 → 192.168.10.20 TLSv1.3 369 Application Data
   11 0.026605534   192.0.2.21 → 192.168.10.20 TLSv1.3 369 Application Data
```

O quadro 4 é o Client Hello, e o nome que o laptop quer, `www.example.com`, vai em texto claro como
SNI. O servidor precisa dele antes de existir qualquer criptografia, para escolher um certificado,
então qualquer um no caminho consegue ler qual site está sendo visitado. O `TLSv1` naquela coluna não
é a versão em uso: o registro externo de um Client Hello diz 1.0 por causa de equipamentos antigos no
meio do caminho, e as versões de verdade são oferecidas lá dentro.

O quadro 6 é a resposta inteira do servidor num pacote só: o Server Hello, depois quatro registros
marcados `Application Data`. **No TLS 1.3 tudo depois do Server Hello é criptografado, inclusive o
certificado.** Esses quatro registros são o resto do handshake do servidor, e uma captura não consegue
dizer qual certificado o servidor mandou. Os registros `Change Cipher Spec` não significam nada no TLS
1.3; eles são mandados para que equipamentos antigos no caminho vejam o que esperam ver. O quadro 8 é o
`Finished` do próprio laptop, também criptografado, e do quadro 9 em diante são a requisição e as
respostas.

## Três certificados que o laptop recusou

`web1` serve mais três certificados em mais três portas: um vencido, um para outro nome e um assinado
por uma autoridade em que o laptop não confia. O primeiro:

```
ana@laptop:~$ curl -sS --resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21 https://www.example.com:8443/
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 8443" -Y tls -d tcp.port==8443,tls
Capturing on 'eth0'
3 packets captured
    4 0.001872089 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    6 0.003155064   192.0.2.21 → 192.168.10.20 TLSv1.3 1509 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.026663340 192.168.10.20 → 192.0.2.21   TLSv1.3 73 Alert (Level: Fatal, Description: Certificate Expired)
```

**O quadro 8 é legível: `Alert (Level: Fatal, Description: Certificate Expired)`, mandado pelo
laptop.** O certificado estava criptografado, mas o veredito do cliente sobre ele não. São 73 bytes, e
um segmento TCP vazio neste enlace tem 66, então ele leva 7 bytes de TLS: um cabeçalho de registro de
5 bytes e um alerta de 2 bytes, nível e descrição, em claro. O laptop rejeitou o certificado antes de
começar a criptografar o próprio lado do handshake, e disse por quê.

O certificado do nome errado:

```
ana@laptop:~$ curl -sS --resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21 https://www.example.com:9443/
curl: (60) SSL: no alternative certificate subject name matches target host name 'www.example.com'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 9443" -Y tls -d tcp.port==9443,tls
Capturing on 'eth0'
3 packets captured
    4 0.001831433 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    6 0.003085279   192.0.2.21 → 192.168.10.20 TLSv1.3 1511 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.026775708 192.168.10.20 → 192.0.2.21   TLSv1.3 146 Change Cipher Spec, Application Data
```

**No fio, isto é o handshake bom de novo.** O quadro 8 é `Change Cipher Spec, Application Data`, 146
bytes, igual ao `Finished` do laptop quando tudo funcionou. O certificado era válido e assinado por uma
autoridade em que o laptop confia, então o handshake terminou, e só então o `curl` comparou o nome nele
com o nome que tinha pedido. Qualquer coisa que o laptop tenha dito depois, um alerta inclusive, foi
dentro da criptografia e apareceria como `Application Data`, impossível de separar de uma requisição.
Esta captura parou no quadro 8, então o que veio depois não aparece.

E a autoridade desconhecida:

```
ana@laptop:~$ curl -sS --resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21 https://www.example.com:10443/
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 10443" -Y tls -d tcp.port==10443,tls
Capturing on 'eth0'
3 packets captured
    4 0.001872793 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    6 0.003189474   192.0.2.21 → 192.168.10.20 TLSv1.3 1499 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.026791460 192.168.10.20 → 192.0.2.21   TLSv1.3 73 Alert (Level: Fatal, Description: Unknown CA)
```

**`Unknown CA`, legível, 73 bytes, como o vencido.** O `curl` diz isso como `unable to get local issuer
certificate`: quem emitiu o certificado não está em nenhum repositório de confiança do laptop.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 770 254\" role=\"img\" aria-label=\"Uma grade de quatro sessões TLS com web1, nas portas 443, 8443, 9443 e 10443: uma que funciona, um certificado vencido, um certificado para o nome errado e um de uma autoridade desconhecida. O quadro 4 do laptop é igual nos quatro, um Client Hello com SNI www.example.com, e o quadro 6 de web1 é igual, um Server Hello e quatro registros Application Data com o certificado criptografado dentro. O quadro 8 muda: Change Cipher Spec e Application Data de 146 bytes quando funciona e com o nome errado, que por isso parece ter funcionado; um alerta legível de 73 bytes, Certificate Expired ou Unknown CA, nos outros dois, que dizem o motivo às claras.\"><text x=\"232.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">funciona</text><text x=\"232.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">443</text><text x=\"384.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">vencido</text><text x=\"384.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8443</text><text x=\"536.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nome errado</text><text x=\"536.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9443</text><text x=\"688.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CA desconhecida</text><text x=\"688.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10443</text><text x=\"10\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quadro 4, laptop</text><rect x=\"160\" y=\"48\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"232.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Client Hello</text><text x=\"232.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SNI=www.example.com</text><rect x=\"312\" y=\"48\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"384.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Client Hello</text><text x=\"384.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SNI=www.example.com</text><rect x=\"464\" y=\"48\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"536.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Client Hello</text><text x=\"536.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SNI=www.example.com</text><rect x=\"616\" y=\"48\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"688.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Client Hello</text><text x=\"688.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SNI=www.example.com</text><text x=\"10\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quadro 6, web1</text><rect x=\"160\" y=\"100\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"232.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Server Hello</text><text x=\"232.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 × Application Data</text><rect x=\"312\" y=\"100\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"384.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Server Hello</text><text x=\"384.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 × Application Data</text><rect x=\"464\" y=\"100\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"536.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Server Hello</text><text x=\"536.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 × Application Data</text><rect x=\"616\" y=\"100\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"688.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Server Hello</text><text x=\"688.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 × Application Data</text><text x=\"10\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quadro 8, laptop</text><rect x=\"160\" y=\"152\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"232.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Change Cipher Spec,</text><text x=\"232.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Application Data 146</text><rect x=\"312\" y=\"152\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"384.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Alert: Certificate</text><text x=\"384.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Expired, 73 bytes</text><rect x=\"464\" y=\"152\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"536.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Change Cipher Spec,</text><text x=\"536.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Application Data 146</text><rect x=\"616\" y=\"152\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"688.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Alert: Unknown CA,</text><text x=\"688.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">73 bytes</text><text x=\"10\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a captura diz</text><text x=\"232.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">funcionou</text><text x=\"384.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o motivo, às claras</text><text x=\"536.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">parece que funcionou</text><text x=\"688.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o motivo, às claras</text><text x=\"160\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">O certificado está dentro do quadro 6 nos quatro casos, criptografado.</text></svg>", "caption": "As três capturas desta seção e a que funcionou, quadro a quadro. Duas falhas se anunciam; o nome errado termina exatamente como um sucesso, até onde a captura chegou."}
```

Então a captura de uma sessão TLS que falha responde a duas perguntas e não a uma terceira. **Onde ela
parou sempre aparece**, porque os quadros param. **O motivo aparece quando o cliente o diz em claro**,
e este cliente disse para um certificado vencido e para uma autoridade desconhecida. Um nome errado é
invisível, e para esse a próxima seção pergunta direto ao servidor.
