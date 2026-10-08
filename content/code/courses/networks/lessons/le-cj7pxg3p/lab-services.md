---
title: "The lab, part 4: SSH, file transfer and mail"
version: 1
---

The last file sets up the services that lessons 7, 8 and 9 log in to. They all need **accounts, and
the passwords are printed here** because the lessons type them: `ana`, you, with `office-2026`;
`example`, the hosting account that owns the website, with `Sunflower-77`; `scans`, the office
scanner, with `scanner-2026`; and `bruno`, a customer at `example.net`, with `Oak-leaf-51`. They are
accounts of the whole Linux machine, which is one more reason to build the lab in a virtual
machine of its own.

- **SSH.** `sshd_conf` gives `server` and `www` an SSH server each, with its own host key. A
  firewall rule on `www` accepts SSH only from the office's public address, and `server` has an
  admin page that listens only on the server itself, which lesson 7 reaches through a tunnel.
- **File transfer.** `build_files` runs an FTP server on `www`, where the `example` account lands in
  the website's own folder, and makes `scans` an account that may use SFTP on `server` and nothing
  else, the arrangement lesson 8 ends with.
- **Mail.** `mail_host` builds one mail server per domain, `mail` for `example.com` and `netmail`
  for `example.net`. Postfix takes mail in on port 25 and from the domain's own people on 587,
  Dovecot hands it to them over IMAP and POP3, OpenDKIM signs what leaves and checks what arrives,
  and OpenDMARC applies the sender's policy. Lesson 9 takes these apart one at a time.

Save it as `~/netlab/services.sh`:

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

All four files are in place. The next section builds the network and walks into it.
