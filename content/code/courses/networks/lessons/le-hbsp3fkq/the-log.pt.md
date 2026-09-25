---
title: Lendo o log do servidor
version: 1
---

Todo login, e todo login que falhou, fica anotado pelo sshd. Primeiro três senhas erradas a partir do
laptop, depois o log:

```
ana@laptop:~$ ssh -o PubkeyAuthentication=no office true
ana@192.168.10.10's password: 
Permission denied, please try again.
ana@192.168.10.10's password: 
Permission denied, please try again.
ana@192.168.10.10's password: 
ana@192.168.10.10: Permission denied (publickey,password).
ana@server:~$ sudo grep -E "Accepted|Failed" /var/log/ssh/sshd.log
Accepted password for ana from 192.168.10.20 port 34472 ssh2
Accepted password for ana from 192.168.10.20 port 40738 ssh2
Accepted publickey for ana from 192.168.10.20 port 40746 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 192.168.10.20 port 58742 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 192.168.10.20 port 35328 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 198.51.100.77 port 50958 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 198.51.100.77 port 52030 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Accepted publickey for ana from 192.168.10.20 port 38096 ssh2: ED25519 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg
Failed password for ana from 192.168.10.20 port 44420 ssh2
Failed password for ana from 192.168.10.20 port 44420 ssh2
Failed password for ana from 192.168.10.20 port 44420 ssh2
```

**Cada linha é uma tentativa, e diz o método que ela usou.** Dois `Accepted password`, a primeira conexão e o
`ssh-copy-id`. Seis `Accepted publickey`, cada um com a impressão digital da chave usada, e é assim que
se descobre de quem era a chave quando um servidor confia em várias. Dois deles vieram de
`198.51.100.77`, o home: o login da seção 07 e o primeiro salto da seção 08. Três `Failed password`
dividem uma porta de origem, porque foram as três tentativas que uma conexão tem antes de o ssh
desistir.

O laboratório grava este log num arquivo próprio. **Num Ubuntu de verdade, as mesmas linhas ficam em
`/var/log/auth.log`**, e o `journalctl -u ssh` também as mostra. Um servidor na internet mostra
`Failed password` para `root`, `admin` e `test` o dia inteiro, de endereços que ninguém conhece; com as
senhas desligadas, esse barulho é inofensivo, e uma ferramenta como o `fail2ban` pode bloquear endereços
que insistem.
