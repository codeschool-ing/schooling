---
title: Protocolos que mandam a senha como foi digitada
version: 1
---

**FTP, Telnet, HTTP, POP3, IMAP, SMTP e LDAP foram todos projetados para mandar tudo, inclusive
credenciais, como texto legível.** Eles são anteriores às ameaças da internet pública, e cada um
ganhou uma versão cifrada desde então. Os antigos ainda são encontrados rodando, em geral porque
alguma coisa depende deles e ninguém os desligou.

## Três servidores na sua máquina

Esta aula conversa com um servidor FTP, um servidor SSH e um diretório LDAP, e por isso é a primeira
que precisa de mais pacotes e a primeira que precisa de `sudo`. Os pacotes do Ubuntu dão os três
programas; o instalador do `slapd` pede uma senha de administrador para um diretório que esta aula
não usa, e qualquer resposta serve:

```sh
sudo apt-get install -y openssh-server slapd ldap-utils python3-pyftpdlib curl
```

Um script sobe os três, cada um numa porta de `127.0.0.1`, com os certificados da aula 8 e a chave
da Ana da aula 6. Ele roda como root porque sobe o `sshd`, cria um usuário `ana` para o servidor
SSH aceitar, se a sua máquina não tiver um, e acrescenta dois nomes ao `/etc/hosts`. Essas três
mudanças são o motivo de a aula 1 recomendar uma máquina virtual:

```sh
#!/usr/bin/env bash
# ~/lab/bin/protocol-servers
# sudo protocol-servers start | stop: lesson 12's servers, on 127.0.0.1 only.
#
#   2121  FTP (pyftpdlib), account scheduler, serving ~/lab/data/release
#   2222  OpenSSH's sshd, SFTP only, a user ana who signs in with keys/ana_ssh
#   3389  OpenLDAP's slapd, plain LDAP with StartTLS, refusing a password sent
#         before TLS (security simple_bind=128)
#   6636  the same slapd over LDAPS, with lesson 8's pki/ldap-chain.pem
#
# It needs root: it starts sshd, adds the user ana if there is none, and adds
# files.vereda.example and ldap.vereda.example to /etc/hosts.
set -euo pipefail
lab=$(cd "$(dirname "$0")/.." && pwd)
run=/run/vereda-lab   # not in ~/lab: root writes here

stop() {
  for pid in "$run"/*.pid; do
    [ -f "$pid" ] && kill "$(cat "$pid")" 2>/dev/null
    rm -f "$pid"
  done
  return 0
}

start() {
  stop
  mkdir -p "$run/ldap" /run/sshd
  grep -q ldap.vereda.example /etc/hosts ||
    echo '127.0.0.1 files.vereda.example ldap.vereda.example' >> /etc/hosts

  # ana, with no password: the only way in is her key.
  id ana >/dev/null 2>&1 || { useradd -m -s /bin/bash ana; usermod -p '*' ana; }
  install -d -m 700 -o ana /home/ana/.ssh
  touch /home/ana/.ssh/authorized_keys
  grep -qF "$(cat "$lab/keys/ana_ssh.pub")" /home/ana/.ssh/authorized_keys ||
    cat "$lab/keys/ana_ssh.pub" >> /home/ana/.ssh/authorized_keys
  chown ana /home/ana/.ssh/authorized_keys

  cat > "$run/sshd_config" <<EOF
Port 2222
ListenAddress 127.0.0.1
HostKey $lab/keys/sftp_host_ed25519
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
StrictModes no
Subsystem sftp internal-sftp
PidFile $run/sshd.pid
EOF
  /usr/sbin/sshd -f "$run/sshd_config"

  setsid python3 -c "
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer
a = DummyAuthorizer()
a.add_user('scheduler', 'V-db-s3cret-2026', '$lab/data/release', perm='elr')
FTPHandler.authorizer = a
FTPHandler.passive_ports = range(30000, 30001)
FTPServer(('127.0.0.1', 2121), FTPHandler).serve_forever()" </dev/null >/dev/null 2>&1 &
  echo $! > "$run/ftp.pid"

  rm -rf "$run/ldap/db"; mkdir -p "$run/ldap/db"
  cat > "$run/ldap/slapd.conf" <<EOF
include /etc/ldap/schema/core.schema
pidfile $run/slapd.pid
modulepath /usr/lib/ldap
moduleload back_mdb
TLSCertificateFile $lab/pki/ldap-chain.pem
TLSCertificateKeyFile $lab/pki/ldap.key
database mdb
suffix "dc=vereda,dc=example"
rootdn "cn=admin,dc=vereda,dc=example"
rootpw directory-admin-lab
directory $run/ldap/db
security simple_bind=128
EOF
  slapd -f "$run/ldap/slapd.conf" -h "ldap://127.0.0.1:3389/ ldaps://127.0.0.1:6636/"
  sleep 1
  echo "FTP on 2121, SFTP on 2222, LDAP on 3389 and LDAPS on 6636, all on 127.0.0.1"
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  *) echo "usage: sudo protocol-servers start | stop" >&2; exit 2 ;;
esac
```

O servidor SSH precisa de uma chave própria, que o `vcrypt sshkey` da aula 6 grava a partir de um
rótulo, como todas as outras chaves. Depois os servidores sobem:

```sh
cd ~/lab
vcrypt sshkey keys/sftp-host keys/sftp_host_ed25519
chmod +x bin/protocol-servers
sudo ~/lab/bin/protocol-servers start
```

Eles rodam até a máquina reiniciar ou até você digitar `sudo ~/lab/bin/protocol-servers stop`. O
`start` para o que um `start` anterior deixou rodando antes de começar, então digitá-lo de novo
também é o jeito de reiniciá-los.

## FTP, como o servidor o recebe

O servidor de arquivos da Vereda ainda oferece FTP na porta 2121 para uma ferramenta de agendamento
antiga. O `curl -v` imprime os comandos que manda, que são exatamente os bytes que atravessam a rede:

```
ana@lab:~/lab$ curl -sv --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (USER|PASS|RETR|230)|^Vereda'
> USER scheduler
> PASS V-db-s3cret-2026
< 230 Login successful.
> RETR NOTES.txt
Vereda portal 2.4.1: booking reminders by SMS.
```

`USER` e `PASS` levam o nome da conta e a senha como foram digitados, e o arquivo também vem em texto
claro. Qualquer um no caminho, um switch comprometido, uma rede Wi-Fi compartilhada, uma porta de
espelhamento mal configurada, lê os dois sem quebrar nada. Não há criptografia a derrotar.

## Pedindo uma cifragem que o servidor não consegue dar

Um cliente pode insistir na cifragem. Com `--ssl-reqd`, o curl primeiro pede ao servidor para passar
para TLS, que é como o **FTPS** funciona, e se recusa a continuar quando o servidor não consegue:

```
ana@lab:~/lab$ curl -sv --ssl-reqd --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (AUTH|USER|PASS|5)|^curl:'; echo "exit status ${PIPESTATUS[0]}"
> AUTH SSL
< 500 Command "AUTH" not understood.
> AUTH TLS
< 500 Command "AUTH" not understood.
exit status 64
```

O servidor responde `500` tanto ao `AUTH SSL` quanto ao `AUTH TLS`, então o curl para com código de
saída 64 **antes** de mandar `USER` ou `PASS`. Essa ordem é o sentido todo do `--ssl-reqd`: um
cliente que só *prefere* cifragem teria voltado ao FTP simples e mandado a senha mesmo assim, que é
o problema de rebaixamento da seção 04.

## Os pares a conhecer

| protocolo simples | porta | substituto cifrado | porta |
|---|---|---|---|
| FTP | 21 | **SFTP** (transferência de arquivos sobre SSH), ou FTPS (FTP sobre TLS) | 22, ou 990 / 21 |
| Telnet | 23 | **SSH** | 22 |
| HTTP | 80 | **HTTPS** | 443 |
| LDAP | 389 | **LDAPS**, ou LDAP com StartTLS | 636, ou 389 |
| SMTP de envio | 25, 587 | SMTP com STARTTLS, ou TLS implícito | 587, 465 |
| IMAP, POP3 | 143, 110 | IMAPS, POP3S | 993, 995 |

O inseguro não deveria simplesmente estar **disponível ao lado** do seguro: ele deveria estar
**desligado**, ou se recusar a autenticar, como faz o servidor LDAP no fim desta aula. Um servidor
que oferece os dois deixa todo cliente a uma configuração errada da versão simples.
