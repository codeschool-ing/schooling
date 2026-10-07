---
title: O handshake, e os dois canais
version: 1
---

O cliente foi iniciado na mão por seis segundos, com o log filtrado para as linhas que dizem o que foi
combinado, enquanto o roteador do provedor capturava a UDP 1194. Comece a captura em `isp` primeiro, e
depois o cliente em `remote`:

```
ana@remote:~$ cd /etc/openvpn && sudo timeout 6 openvpn --config client.conf | grep -E "VERIFY OK|Control Channel:|Data Channel:|Initialization"
2026-09-28 18:07:59 VERIFY OK: depth=1, O=Example Lab, CN=Example Lab Root CA
2026-09-28 18:07:59 VERIFY OK: depth=0, CN=vpn.example.com
2026-09-28 18:07:59 Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, peer certificate: 2048 bits RSA, signature: RSA-SHA256, peer temporary key: 253 bits X25519
2026-09-28 18:07:59 Initialization Sequence Completed
2026-09-28 18:07:59 Data Channel: cipher 'AES-256-GCM', peer-id: 0
```

**`VERIFY OK` aparece duas vezes porque um certificado é conferido como uma cadeia**, da autoridade para
baixo. `depth=1` é a raiz do laboratório, em que o cliente confia porque o `ca.crt` diz. `depth=0` é o
servidor, `CN=vpn.example.com`, assinado por essa raiz, e o nome que `verify-x509-name` pediu. Se
qualquer uma das duas conferências falhasse, o log diria isso aqui e o túnel não subiria.

A linha seguinte é todo o trabalho do TLS: `Control Channel: TLSv1.3`, um certificado RSA de 2048 bits no
servidor e uma troca de chaves X25519. É o Diffie-Hellman de curva elíptica que o `dh none` deixou como
único tipo. A última linha é a outra metade. **`Data Channel: cipher 'AES-256-GCM'` não é TLS**: o
tráfego não viaja como registros TLS, e sim nos pacotes do próprio OpenVPN, cifrados com chaves que o
handshake produziu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"remote em 198.51.100.77 e hq em 203.0.113.2, ligados por uma conversa UDP na porta 1194. Dentro dela correm dois canais. O canal de controle leva pacotes P_CONTROL com TLS 1.3 dentro: certificados nos dois sentidos e a troca de chaves. O canal de dados leva pacotes P_DATA cifrados com AES-256-GCM: os pacotes do tun0, que não são registros TLS. Uma seta rotulada chaves vai do canal de controle para o canal de dados.\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"56\" width=\"120\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remote</text><text x=\"80.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.77</text><rect x=\"580\" y=\"56\" width=\"120\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"640.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"160\" y=\"20\" width=\"400\" height=\"186\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma conversa UDP, porta 1194</text><rect x=\"176\" y=\"50\" width=\"368\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">canal de controle</text><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P_CONTROL + TLSv1.3</text><text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">certificados nos dois sentidos, troca de chaves</text><rect x=\"176\" y=\"128\" width=\"368\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">canal de dados</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P_DATA, AES-256-GCM</text><text x=\"360\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os pacotes do tun0, não registros TLS</text><path d=\"M500 114 L500 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"508\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">chaves</text><path d=\"M140 82 L176 82\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M544 82 L580 82\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M140 160 L176 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M544 160 L580 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "Os dois canais do OpenVPN. O TLS faz o handshake e mais nada; o tráfego viaja nos pacotes do próprio OpenVPN, com chaves que o handshake produziu."}
```

No roteador do provedor, o tshark decodificou os mesmos seis segundos:

```
ana@isp:~$ tshark -n -i eth0 -c 12 -f "udp port 1194"
Capturing on 'eth0'
12 packets captured
    1 0.000000000 198.51.100.77 → 203.0.113.2  OpenVPN 56 MessageType: P_CONTROL_HARD_RESET_CLIENT_V2
    2 0.000164366  203.0.113.2 → 198.51.100.77 OpenVPN 68 MessageType: P_CONTROL_HARD_RESET_SERVER_V2
    3 0.000266724 198.51.100.77 → 203.0.113.2  TLSv1 345 Client Hello
    4 0.001805037  203.0.113.2 → 198.51.100.77 TLSv1.3 1264 Server Hello, Change Cipher Spec, Application Data, Application Data
    5 0.001838623  203.0.113.2 → 198.51.100.77 TLSv1.3 1264 Continuation Data
    6 0.001846940  203.0.113.2 → 198.51.100.77 TLSv1.3 79 Continuation Data
    7 0.002041436 198.51.100.77 → 203.0.113.2  OpenVPN 68 MessageType: P_ACK_V1
    8 0.002694277 198.51.100.77 → 203.0.113.2  OpenVPN 72 MessageType: P_ACK_V1
    9 0.003629784 198.51.100.77 → 203.0.113.2  TLSv1.3 1264 Change Cipher Spec
   10 0.003653049 198.51.100.77 → 203.0.113.2  TLSv1.3 1264 Continuation Data
   11 0.003661477 198.51.100.77 → 203.0.113.2  TLSv1.3 228 Continuation Data
   12 0.003777507  203.0.113.2 → 198.51.100.77 OpenVPN 68 MessageType: P_ACK_V1
```

Leia como uma conversa. As duas mensagens `HARD_RESET` são a abertura do próprio OpenVPN, cada lado
anunciando uma sessão. Depois o TLS começa dentro dos pacotes de controle do OpenVPN: o `Client Hello`
do laptop, e a resposta do servidor, `Server Hello, Change Cipher Spec, Application Data`. Dali em diante
**o handshake vai cifrado, e o certificado do servidor está dentro do que o tshark só consegue chamar de
`Application Data`.** O TLS 1.3 cifra certificados, e a aula 5 de `networks` viu o mesmo no HTTPS.

`Continuation Data` é o resto de um registro, dividido em pacotes de 1264 bytes. **Os pacotes `P_ACK_V1`
são o OpenVPN confirmando ele mesmo os pacotes de controle, porque o UDP não confirma.** Os pacotes 9 a
11 vão no outro sentido: o certificado e a prova do próprio laptop, cifrados, cerca de 2,7 kilobytes.
São a conferência que o servidor faz do cliente. Doze pacotes, 3,8 milissegundos, num
computador conversando consigo mesmo.

O `tshark` rotula o `Client Hello` como `TLSv1`, e isso não é rebaixamento. Um cliente TLS 1.3 escreve
um número de versão antigo no cabeçalho do registro, para que equipamentos antigos no meio do caminho o
deixem passar, e diz lá dentro a versão que quer de verdade. A resposta do servidor decide, e o tshark
rotula tudo depois dela como `TLSv1.3`.

Iniciado de novo e deixado rodando, em segundo plano como o servidor, o cliente dá um túnel ao laptop. Em
`remote`:

```sh
sudo setsid openvpn --cd /etc/openvpn --config client.conf >/dev/null 2>&1 &
```

Alguns segundos depois:

```
ana@remote:~$ ip -br addr show tun0; ip route | grep tun0
tun0             UNKNOWN        10.8.0.2/24 
10.8.0.0/24 dev tun0 proto kernel scope link src 10.8.0.2 
192.168.10.0/24 via 10.8.0.1 dev tun0 
ana@remote:~$ curl -s http://192.168.10.10/
served by files
```

O `tun0` recebeu `10.8.0.2`, o primeiro endereço que o servidor distribui. **Ninguém configurou no laptop
a rota para `192.168.10.0/24`**: ela é a linha `push` do arquivo do servidor, e chegou pelo canal de
controle. Pare o cliente antes da próxima seção, na máquina virtual: `sudo bash netlab.sh kill remote openvpn`.
