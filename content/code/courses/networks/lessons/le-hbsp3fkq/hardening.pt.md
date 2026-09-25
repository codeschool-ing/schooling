---
title: Fechando a porta para senhas
version: 1
---

Quando toda pessoa que precisa do servidor tiver uma chave instalada, as senhas podem ser desligadas:

```
ana@server:~$ echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
PasswordAuthentication no
ana@server:~$ sudo sshd -t -f /etc/ssh/sshd_config && echo config ok
config ok
ana@server:~$ sudo kill -HUP $(cat /run/sshd-server.pid)
ana@server:~$ sudo sshd -T | grep -E "^(passwordauthentication|permitrootlogin|pubkeyauthentication) "
permitrootlogin without-password
pubkeyauthentication yes
passwordauthentication no
ana@laptop:~$ ssh -o PubkeyAuthentication=no -o BatchMode=yes office true
ana@192.168.10.10: Permission denied (publickey).
```

O `sshd -t` confere a configuração antes de ela ser usada; um erro no `sshd_config` descoberto
reiniciando o servidor pode trancar todo mundo fora de uma máquina até a qual ninguém consegue ir a pé.
O `kill -HUP` faz o sshd do laboratório reler o arquivo, e num Ubuntu de verdade isso é
`sudo systemctl reload ssh`. O laptop, mandado não oferecer a chave, é recusado na hora, e a recusa diz
o que ainda é permitido: `(publickey)`.

O `sshd -T` imprime as opções que o sshd está de fato usando, depois de todo arquivo que ele lê. **Essa
é a conferência que importa, porque o sshd, como o cliente, fica com o primeiro valor que encontra.** O
Ubuntu lê `/etc/ssh/sshd_config.d/*.conf` antes do resto do arquivo principal, e em algumas imagens de
nuvem um desses já diz `PasswordAuthentication yes`; um `no` acrescentado no fim então não muda nada, e o
arquivo parece certo.

`permitrootlogin without-password` é o padrão do Ubuntu: o root pode entrar com chave e nunca com
senha. Muitos servidores o põem em `no`, para que as pessoas entrem como elas mesmas e usem `sudo`, e o
log diga quem fez o quê. **Mantenha uma sessão aberta enquanto muda qualquer coisa disto**, e teste a
partir de uma segunda. Uma sessão aberta sobrevive a um reload, e é o caminho de volta se a opção nova
estiver errada.
