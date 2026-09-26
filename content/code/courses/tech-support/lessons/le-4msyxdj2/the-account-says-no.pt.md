---
title: A conta diz não
version: 1
---

No pc1, o help desk tem uma conta própria, `tec`, com uma regra que dá a ela exatamente dois comandos como
root:

```
ana@pc1:~$ sudo cat /etc/sudoers.d/helpdesk
tec ALL=(root) NOPASSWD: /usr/bin/systemctl restart cups, /usr/sbin/lpadmin
ana@pc1:~$ sudo visudo -cf /etc/sudoers.d/helpdesk
/etc/sudoers.d/helpdesk: parsed OK
```

A regra fica num arquivo próprio em `/etc/sudoers.d`, e o `visudo -c` confere o arquivo antes de alguém
confiar nele: um arquivo sudoers com um erro pode trancar todo mundo fora do `sudo` naquele computador.
Perguntada o que pode fazer, a conta responde com os mesmos dois comandos, e um deles funciona:

```
ana@pc1:~$ sudo -u tec sudo -l | tail -2
User tec may run the following commands on pc1:
    (root) NOPASSWD: /usr/bin/systemctl restart cups, /usr/sbin/lpadmin
ana@pc1:~$ sudo -u tec sudo systemctl restart cups && echo restarted
restarted
```

Os comandos da tec rodam com `sudo -u tec` a partir da sessão da ana, como diz o cabeçalho do laboratório.
Pedindo para criar um usuário, que não está na lista:

```
ana@pc1:~$ echo lab-only-password | sudo -u tec sudo -S useradd bruno
[sudo] password for tec: Sorry, user tec is not allowed to execute '/usr/sbin/useradd bruno' as root on pc1.
```

O `sudo` pediu primeiro a senha da tec, que o script passou com `-S`, e só então recusou: `is not allowed to
execute`, com o comando exato e o computador. **Essa recusa encerra o assunto para essa
conta**, e o próximo passo certo não é achar outro jeito de rodar o mesmo comando. É passar o pedido para
quem cria contas, aula 7, com o que foi pedido.
