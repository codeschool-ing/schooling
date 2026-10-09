---
title: "O laboratório, parte 4: SSH, transferência de arquivos e e-mail"
version: 1
---

O último arquivo prepara os serviços em que as aulas 7, 8 e 9 fazem login. Todos precisam de **contas,
e as senhas estão impressas aqui** porque as aulas as digitam: `ana`, você, com `office-2026`;
`example`, a conta de hospedagem dona do site, com `Sunflower-77`; `scans`, o scanner do escritório,
com `scanner-2026`; e `bruno`, um cliente na `example.net`, com `Oak-leaf-51`. São contas da máquina
Linux inteira, o que é mais um motivo para montar o laboratório numa máquina virtual só dele.

- **SSH.** `sshd_conf` dá ao `server` e ao `www` um servidor SSH cada, com sua própria chave de host.
  Uma regra de firewall no `www` só aceita SSH vindo do endereço público do escritório, e o `server`
  tem uma página de administração que só escuta no próprio servidor, à qual a aula 7 chega por um
  túnel.
- **Transferência de arquivos.** `build_files` roda um servidor FTP no `www`, onde a conta `example`
  cai na própria pasta do site, e faz de `scans` uma conta que pode usar SFTP no `server` e mais nada,
  o arranjo com que a aula 8 termina.
- **E-mail.** `mail_host` monta um servidor de e-mail por domínio, `mail` para `example.com` e
  `netmail` para `example.net`. O Postfix recebe e-mail na porta 25 e do pessoal do próprio domínio
  na 587, o Dovecot o entrega a eles por IMAP e POP3, o OpenDKIM assina o que sai e confere o que
  chega, e o OpenDMARC aplica a política do remetente. A aula 9 desmonta esses um de cada vez.

Salve-o como `~/netlab/services.sh`:

```sh
nano ~/netlab/services.sh
```

```bash
# ~/netlab/services.sh: SSH on the office server and the web server, FTP and
# SFTP, and a mail server for each of the two domains.

# ------------------------------------------------------------------------ SSH
sshd_conf() {  # sshd_conf HOST ADDRESS
  local s="$LAB/$1/etc/ssh"
  mkdir -p "$s"
  cp -a /etc/ssh/. "$s/"
  rm -f "$s"/ssh_host_*
  ssh-keygen -q -t ed25519 -N '' -C "root@$1" -f "$s/ssh_host_ed25519_key"
  cat > "$s/sshd_config" <<C
ListenAddress $2
HostKey /etc/ssh/ssh_host_ed25519_key
PidFile /run/sshd-$1.pid
KbdInteractiveAuthentication no
UsePAM yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp internal-sftp
C
}
build_ssh() {
  sshd_conf server 192.168.10.10
  sshd_conf www 192.0.2.80
  echo 'ana:office-2026' | chpasswd
  # sshd writes its log to a file of each machine's own, because the lab's
  # machines share one journal; and no welcome banner, to keep sessions short.
  mkdir -p /var/log/ssh "$LAB/server/var/log/ssh" "$LAB/www/var/log/ssh"
  sed -i 's/^\(session.*pam_motd.so.*\)$/# \1/' /etc/pam.d/sshd
  # The web server accepts SSH only from the office's public address.
  ip netns exec www nft -f - <<'NFT'
table inet ssh-guard {
  chain input {
    type filter hook input priority 0;
    tcp dport 22 ip saddr != 203.0.113.2 drop
  }
}
NFT
  # An admin page on the office server that listens only on the server itself.
  mkdir -p "$LAB/server/var/www/admin"
  printf '<h1>Office server: backups</h1>\n<p>Last backup: finished.</p>\n' > "$LAB/server/var/www/admin/index.html"
}

# -------------------------------------------------------------- file transfer
build_files() {
  # The hosting account that owns the website: whoever logs in as it by FTP
  # lands in the site's own directory, and what they upload is what is served.
  id example >/dev/null 2>&1 || useradd -M -d /var/www/example -s /bin/bash example
  echo 'example:Sunflower-77' | chpasswd
  chown -R example:example "$LAB/www/var/www/example"
  mkdir -p /var/run/vsftpd/empty
  cat > "$LAB/www/etc/vsftpd.conf" <<'C'
listen=YES
listen_address=192.0.2.80
listen_ipv6=NO
background=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_min_port=40000
pasv_max_port=40009
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
seccomp_sandbox=NO
xferlog_enable=YES
ssl_enable=YES
rsa_cert_file=/etc/ssl/private/example.com.crt
rsa_private_key_file=/etc/ssl/private/example.com.key
allow_anon_ssl=NO
force_local_logins_ssl=NO
force_local_data_ssl=NO
require_ssl_reuse=NO
C
  # The office scanner drops its scans on the server by SFTP, and may do
  # nothing else: no shell, and no view of anything above its own folder.
  id scans >/dev/null 2>&1 || useradd -M -d /srv/scans -s /bin/bash scans
  echo 'scans:scanner-2026' | chpasswd
  mkdir -p /srv/scans/inbox; chown root:root /srv/scans; chmod 755 /srv/scans
  chown scans:scans /srv/scans/inbox
  cat >> "$LAB/server/etc/ssh/sshd_config" <<'C'
Match User scans
    ForceCommand internal-sftp
    ChrootDirectory /srv/scans
    AllowTcpForwarding no
C
}

# ----------------------------------------------------------------------- mail
# One mail server per domain: Postfix takes mail in on 25 and from the
# domain's own people on 587; Dovecot hands it to them over IMAP and POP3;
# OpenDKIM signs what leaves and checks what arrives; OpenDMARC checks SPF
# and applies the sender's DMARC policy.
mail_host() {  # mail_host HOST DOMAIN ADDRESS
  local h=$1 d=$2 a=$3 r="$LAB/$1"
  mkdir -p "$r/etc/postfix" "$r/var/spool/postfix" "$r/var/lib/postfix" "$r/etc/dovecot" \
           "$r/etc/opendkim" "$r/var/log/mail" "$r/etc/ssl/private"
  cp -a /etc/postfix/. "$r/etc/postfix/"
  cp -a /var/spool/postfix/. "$r/var/spool/postfix/"
  chown postfix:postfix "$r/var/lib/postfix"
  cert "mail.$d" 90 "mail.$d"
  cp "$LAB/ca/mail.$d.chain" "$r/etc/ssl/private/mail.crt"; cp "$LAB/ca/mail.$d.key" "$r/etc/ssl/private/mail.key"
  chmod 600 "$r/etc/ssl/private/mail.key"
  cat > "$r/etc/postfix/main.cf" <<C
compatibility_level = 3.6
myhostname = mail.$d
mydomain = $d
myorigin = \$mydomain
mydestination = \$mydomain, localhost
inet_interfaces = $a, 127.0.0.1
inet_protocols = ipv4
mynetworks = 127.0.0.0/8
home_mailbox = Maildir/
alias_maps =
alias_database =
smtpd_banner = \$myhostname ESMTP
biff = no
maillog_file = /var/log/mail/postfix.log
smtpd_tls_cert_file = /etc/ssl/private/mail.crt
smtpd_tls_key_file = /etc/ssl/private/mail.key
smtpd_tls_security_level = may
smtp_tls_security_level = may
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination
milter_default_action = accept
smtpd_milters = inet:127.0.0.1:8891, inet:127.0.0.1:8893
non_smtpd_milters = inet:127.0.0.1:8891
C
  postconf -c "$r/etc/postfix" -F '*/*/chroot = n'
  postconf -c "$r/etc/postfix" -M 'submission/inet=submission inet n - n - - smtpd'
  postconf -c "$r/etc/postfix" -P 'submission/inet/syslog_name=postfix/submission' \
    'submission/inet/smtpd_tls_security_level=encrypt' 'submission/inet/smtpd_sasl_auth_enable=yes' \
    'submission/inet/smtpd_relay_restrictions=permit_sasl_authenticated,reject' \
    'submission/inet/milter_macro_daemon_name=ORIGINATING'
  cat > "$r/etc/dovecot/dovecot.conf" <<C
protocols = imap pop3
listen = $a
instance_name = dovecot-$h
base_dir = /run/dovecot-$h
log_path = /var/log/mail/dovecot.log
ssl = required
ssl_cert = </etc/ssl/private/mail.crt
ssl_key = </etc/ssl/private/mail.key
auth_mechanisms = plain login
mail_location = maildir:~/Maildir
first_valid_uid = 1000
passdb {
  driver = pam
}
userdb {
  driver = passwd
}
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
C
  cp "$LAB/dkim/$d/mail.private" "$r/etc/opendkim/mail.private"
  chown opendkim:opendkim "$r/etc/opendkim/mail.private"; chmod 600 "$r/etc/opendkim/mail.private"
  cat > "$r/etc/opendkim.conf" <<C
Syslog yes
SyslogSuccess yes
LogWhy yes
Mode sv
Domain $d
Selector mail
KeyFile /etc/opendkim/mail.private
Socket inet:8891@127.0.0.1
PidFile /run/opendkim-$h.pid
UserID opendkim
Nameservers 198.51.100.53
C
  cat > "$r/etc/opendmarc.conf" <<C
Syslog false
Socket inet:8893@127.0.0.1
PidFile /run/opendmarc-$h.pid
UserID opendmarc
AuthservID mail.$d
TrustedAuthservIDs mail.$d
RejectFailures true
SPFSelfValidate true
SPFIgnoreResults true
IgnoreAuthenticatedClients true
C
}
build_mail() {
  mkdir -p /etc/opendkim /var/log/mail
  id bruno >/dev/null 2>&1 || useradd -M -s /bin/bash bruno
  echo 'bruno:Oak-leaf-51' | chpasswd
  mkdir -p "$LAB/netmail/home/bruno"; cp -a /etc/skel/. "$LAB/netmail/home/bruno/"
  chown -R bruno:bruno "$LAB/netmail/home/bruno"; chmod 750 "$LAB/netmail/home/bruno"
  mail_host mail example.com 192.0.2.25
  mail_host netmail example.net 192.0.2.26
}

```

Os quatro arquivos estão no lugar. A próxima seção monta a rede e entra nela.
