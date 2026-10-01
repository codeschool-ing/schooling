---
title: Uma VPN cujo handshake é TLS
version: 1
---

"VPN SSL" sugere uma página web num navegador, e alguns produtos são exatamente isso. A maior parte do
que se vende com esse nome é outra coisa: **um programa no laptop que abre um túnel, e usa o TLS só para
conferir certificados e combinar chaves.** O nome é histórico. O SSL foi substituído pelo TLS faz tempo,
e o handshake desta aula é TLS 1.3, a versão que a aula 5 de `networks` desmontou para o HTTPS.

O que muda, comparado ao IPsec, é onde a VPN mora. O IPsec faz parte da camada de rede do sistema
operacional, com protocolo IP próprio, o 50, e portas UDP próprias, a 500 e a 4500. **Uma VPN TLS é um
programa comum conversando por uma porta comum**, UDP ou TCP, e os certificados dela são do mesmo tipo que
um servidor web usa. Isso a torna fácil de instalar em qualquer coisa, e fácil de passar por um firewall,
que é o assunto da seção sobre a porta 443.

O OpenVPN é a VPN TLS que este laboratório roda: um servidor em `hq` e um cliente em `remote`, o laptop
de casa atrás do roteador doméstico. Os dois arquivos de configuração foram impressos com `cat`. O do
servidor:

```schooling-example
{"language": "conf", "file": "server.conf", "parts": [{"code": "dev tun\nproto udp\nport 1194\nserver 10.8.0.0 255.255.255.0\ntopology subnet", "note": "Um túnel roteado, `tun`, levando pacotes IP, sobre a porta UDP 1194. `server` distribui endereços de `10.8.0.0/24` e fica com o primeiro, e `topology subnet` dá a cada cliente um endereço nessa rede, como numa LAN."}, {"code": "ca ca.crt\ncert vpn-server.crt\nkey vpn-server.key", "note": "A autoridade que assinou todo certificado desta VPN, e o certificado e a chave do próprio servidor. Um cliente cujo certificado essa autoridade não assinou é recusado durante o handshake."}, {"code": "dh none", "note": "Nenhum arquivo de parâmetros Diffie-Hellman clássicos: a troca de chaves é feita só com curvas elípticas, que é o que o cliente depois informa como X25519."}, {"code": "push \"route 192.168.10.0 255.255.255.0\"", "note": "Uma rota que o servidor empurra a todo cliente, para que a rede da matriz entre no túnel. O cliente não precisou conhecê-la."}, {"code": "keepalive 10 60", "note": "Manda um keepalive a cada 10 segundos, e trata 60 segundos de silêncio como túnel morto."}]}
```

E o do cliente, que é mais curto porque o servidor empurra o que o cliente precisa saber:

```schooling-example
{"language": "conf", "file": "client.conf", "parts": [{"code": "client\ndev tun\nproto udp\nremote vpn.example.com 1194", "note": "Um cliente, com o mesmo tipo de dispositivo e de transporte do servidor, apontado para o nome e a porta do servidor."}, {"code": "ca ca.crt\ncert vpn-ana.crt\nkey vpn-ana.key", "note": "A mesma autoridade, e o certificado e a chave desta pessoa: o servidor confere este certificado como o cliente confere o do servidor."}, {"code": "remote-cert-tls server\nverify-x509-name vpn.example.com name", "note": "As duas linhas que fazem o cliente recusar um impostor. `remote-cert-tls server` exige um certificado emitido para servidor, então o certificado de cliente de outra pessoa não se passa por um; `verify-x509-name` exige o nome `vpn.example.com`."}, {"code": "verb 3", "note": "Quanto registrar. O nível 3 é o que imprime as linhas lidas na próxima seção."}]}
```

**Os dois lados provam quem são com um certificado**, assinado pela autoridade do próprio laboratório, o
`ca.crt`. **Não há segredo compartilhado em nenhum dos dois arquivos**, então tirar uma pessoa quer
dizer revogar um certificado, o problema com que a aula 2 terminou. O certificado do servidor diz
`vpn.example.com`, e o cliente recusa qualquer outro nome, exatamente como um navegador recusa um
servidor web cujo certificado nomeia outra pessoa.

O dispositivo, `dev tun`, é uma interface TUN como a que o `tunnel.py` da aula 1 usava: pacotes IP
entrando e saindo, roteados, uma sub-rede em cada ponta. O OpenVPN também roda com `dev tap`, que leva
quadros Ethernet, e a seção sobre esticar uma LAN diz quando isso vale a pena.
