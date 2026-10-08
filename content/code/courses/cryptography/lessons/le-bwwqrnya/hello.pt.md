---
title: Os hellos: o que cada lado oferece e escolhe
version: 1
---

**Um handshake TLS 1.3 leva uma ida e volta: o cliente manda um voo de mensagens, o servidor
responde com um, e o cliente já pode mandar dados no seguinte.** Tudo o que veio das aulas 1 a 9
acontece dentro dele: uma troca de chaves (aula 7), uma cadeia de certificados (aulas 8 e 9), uma
assinatura (aula 3), a HKDF (aula 7) e o AES-GCM (aula 1). Esta aula o observa no portal da
Vereda.

## Quatro servidores na sua própria máquina

Esta aula precisa de servidores TLS com quem conversar, e o OpenSSL tem um embutido, o `openssl
s_server`. Quatro deles, cada um numa porta de `127.0.0.1` e cada um com um certificado da aula 8,
cobrem tudo o que a aula mostra: o portal, feito direito, na 8443; o mesmo certificado sem a AC
emissora na 8444; o certificado vencido da agenda na 8445; e o autoassinado da intranet na 8446. A
seção 05 trata dos três últimos.

```sh
cd ~/lab
serve() { openssl s_server -accept "127.0.0.1:$1" -www -quiet "${@:2}" </dev/null >/dev/null 2>&1 & }
serve 8443 -cert pki/portal.pem -key pki/portal.key -cert_chain pki/issuing1.pem
serve 8444 -cert pki/portal.pem -key pki/portal.key
serve 8445 -cert pki/agenda.pem -key pki/agenda.key -cert_chain pki/issuing1.pem
serve 8446 -cert pki/intranet.pem -key pki/intranet.key
```

O `serve` é uma função do shell, para que as quatro linhas só difiram no que é diferente. Cada
servidor roda em segundo plano até você pará-lo, o que no fim da aula é
`pkill -f 'openssl s_server'`, ou até a máquina reiniciar; depois de reiniciar, digite as cinco
linhas de novo. Nada fora da máquina os alcança, porque `127.0.0.1` é a máquina falando com ela
mesma.

## O handshake, mensagem por mensagem

O `openssl s_client` se conecta ao portal, confiando na raiz da Vereda, e o `-trace` imprime cada
mensagem. Um trace é longo e cheio de bytes aleatórios que mudam a cada conexão, então ele passa
pelo `vcrypt tls-flow`, que mantém os nomes das mensagens e os campos que esta aula discute. Ele é
um leitor do trace e nada mais, e você não precisa acompanhar o código para usá-lo:

```py
# ~/lab/tools/tls-flow.py
"""vcrypt tls-flow: read the output of `openssl s_client -trace` on standard
input and print the handshake as a list of messages, with the fields lesson
10 talks about and none of the random bytes, which differ on every
connection. The trace itself is the evidence; this is a way of reading it."""
import re
import sys


def flow(lines):
    out, direction, encrypted = [], None, False
    msg = None
    pending_versions, in_versions = [], False
    for raw in lines:
        line = raw.rstrip("\n")
        if line.startswith("Sent Record"):
            direction, msg = "client -> server", None
            continue
        if line.startswith("Received Record"):
            direction, msg = "server -> client", None
            continue
        m = re.match(r"  Content Type = (\w+)", line)
        if m and m.group(1) == "ChangeCipherSpec":
            out.append(f"{direction}  ChangeCipherSpec")
            continue
        if line.startswith("  Inner Content Type") and not encrypted:
            encrypted = True
            out.append("---- everything below is encrypted with the handshake keys ----")
        m = re.match(r"  Inner Content Type = (\w+)", line)
        if m and m.group(1) == "ApplicationData":
            out.append(f"{direction}  application data (encrypted)")
            continue
        m = re.match(r"    ([A-Z][A-Za-z]+), Length=\d+", line)
        if m:
            msg = m.group(1)
            out.append(f"{direction}  {msg}")
            in_versions = False
            continue
        if msg is None:
            m = re.match(r"\s+Level=(\w+)\(\d+\), description=(.+)\(\d+\)", line)
            if m:
                out.append(f"{direction}  Alert: {m.group(1)}, {m.group(2)}")
            continue
        s = line.strip()
        if msg == "ClientHello":
            if "extension_type=server_name" in s:
                out.append("    server_name: (see below)")
            if s.startswith("extension_type=supported_versions"):
                in_versions = True
                continue
            if in_versions:
                m = re.match(r"(TLS \d\.\d)", s)
                if m:
                    pending_versions.append(m.group(1))
                    continue
                out.append("    offers versions: " + ", ".join(pending_versions))
                pending_versions, in_versions = [], False
            m = re.match(r"NamedGroup: (\S+)", s)
            if m:
                out.append(f"    key_share: {m.group(1)}")
            m = re.match(r"cipher_suites \(len=(\d+)\)", s)
            if m:
                out.append(f"    offers {int(m.group(1)) // 2} cipher suites")
        elif msg == "ServerHello":
            m = re.match(r"cipher_suite \{.*\} (\S+)", s)
            if m:
                out.append(f"    chosen cipher suite: {m.group(1)}")
            m = re.match(r"(TLS \d\.\d) \(\d+\)", s)
            if m:
                out.append(f"    chosen version: {m.group(1)}")
            m = re.match(r"NamedGroup: (\S+)", s)
            if m:
                out.append(f"    key_share: {m.group(1)}")
        elif msg == "Certificate":
            m = re.match(r"Subject: (.*)", s)
            if m:
                out.append(f"    certificate: {m.group(1).split('CN = ')[-1]}")
        elif msg == "CertificateVerify":
            m = re.match(r"Signature Algorithm: (\S+)", s)
            if m:
                out.append(f"    signed with: {m.group(1)}")
    # the server name sits in a hex dump; take it from the dump's text column
    text = "".join(lines)
    for i, l in enumerate(out):
        if l.endswith("(see below)"):
            m = re.search(r"server_name\(0\)[^\n]*\n((?:\s+[0-9a-f]{4} - .*\n)+)", text)
            name = ""
            if m and m.group(1):
                name = "".join(row.split("   ")[-1].strip() for row in m.group(1).splitlines())
                name = re.sub(r"^\.+", "", name)
            out[i] = f"    server_name: {name}"
    for l in lines:
        s = l.strip()
        if s.startswith("verify error:"):
            out.append("client: " + s)
        if s.startswith("New, ") or s.startswith("Verify return code") or s.startswith("Verification error"):
            out.append("result: " + s)
    return out


print("\n".join(flow(sys.stdin.readlines())))
```

O handshake do portal, lido por ele:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -trace 2>&1 | vcrypt tls-flow
client -> server  ClientHello
    offers 31 cipher suites
    server_name: portal.vereda.example
    offers versions: TLS 1.3, TLS 1.2
    key_share: ecdh_x25519
server -> client  ServerHello
    chosen cipher suite: TLS_AES_256_GCM_SHA384
    chosen version: TLS 1.3
    key_share: ecdh_x25519
server -> client  ChangeCipherSpec
---- everything below is encrypted with the handshake keys ----
server -> client  EncryptedExtensions
server -> client  Certificate
    certificate: portal.vereda.example
    certificate: Vereda Issuing CA 1
server -> client  CertificateVerify
    signed with: ecdsa_secp256r1_sha256
server -> client  Finished
client -> server  ChangeCipherSpec
client -> server  Finished
client -> server  application data (encrypted)
client -> server  Alert: warning, close notify
result: New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
result: Verify return code: 0 (ok)
```

O resto desta seção lê as duas primeiras mensagens. A próxima lê o resto.

## ClientHello

O cliente abre com tudo o que o servidor precisa para escolher:

- as **suítes de cifras** que ele aceita, 31 aqui. No TLS 1.3 uma suíte nomeia só o AEAD e o hash,
  como `TLS_AES_256_GCM_SHA384`. As outras 28 são suítes antigas do TLS 1.2, oferecidas para o caso
  de o servidor ser antigo;
- as **versões aceitas**, TLS 1.3 e TLS 1.2. O campo de versão no cabeçalho do registro ainda diz
  1.2, ou até 1.0, por compatibilidade com equipamentos intermediários antigos que descartariam
  qualquer coisa desconhecida; a negociação de verdade acontece nesta extensão;
- o **server_name**, o nome de host que o cliente quer, `portal.vereda.example`. Isso é o **SNI**, e
  ele permite que um endereço IP sirva muitos sites, cada um com seu certificado. Ele viaja em texto
  claro no ClientHello, e essa é a principal coisa que um observador do TLS 1.3 ainda descobre. (O
  Encrypted Client Hello, ECH, está sendo implantado para escondê-lo.)
- o **key_share**: a chave pública X25519 efêmera do cliente, 32 bytes. O cliente não espera ser
  perguntado; ele aposta que o servidor aceita X25519, e quase todos aceitam. Essa aposta é o que
  economiza uma ida e volta em relação ao TLS 1.2.

## ServerHello

O servidor escolhe um de cada:

- **versão** TLS 1.3, **suíte de cifras** `TLS_AES_256_GCM_SHA384`;
- **key_share**: a chave pública X25519 efêmera dele.

Neste ponto cada lado tem a própria chave privada efêmera e a chave pública do outro, que é
exatamente a troca da aula 7. Os dois calculam o mesmo segredo compartilhado, rodam a HKDF sobre ele
e derivam as **chaves do handshake**. Tudo depois do ServerHello é cifrado com elas, e é essa a
linha que o `vcrypt tls-flow` desenha. Um observador da rede vê os dois hellos e depois só registros
cifrados: nem o certificado fica visível no TLS 1.3, diferente do TLS 1.2.

As mensagens `ChangeCipherSpec` da lista não carregam nada. O TLS 1.3 só as manda porque alguns
equipamentos intermediários quebram conexões que não se parecem o bastante com o TLS 1.2.
