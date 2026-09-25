---
title: O agente, que lembra a frase-senha
version: 1
---

Com frase-senha na chave, toda conexão a pede, e isso é seguro e cansativo. O **agente** é um pequeno
programa que guarda a chave destrancada na memória, e o ssh pede a ele em vez de pedir a você:

```
ana@laptop:~$ ssh 192.168.10.10 hostname
Enter passphrase for key '/home/ana/.ssh/id_ed25519': 
server
ana@laptop:~$ eval $(ssh-agent)
Agent pid 37177
ana@laptop:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@laptop:~$ ssh-add -l
256 SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg ana@laptop (ED25519)
ana@laptop:~$ ssh 192.168.10.10 hostname
server
```

O primeiro `ssh` pediu a frase-senha. `eval $(ssh-agent)` iniciou um agente e disse ao shell onde
encontrá-lo; `ssh-add` destrancou a chave uma vez e a entregou; `ssh-add -l` lista o que o agente
guarda, pela impressão digital, o mesmo `SHA256:zfl5ZH…` que o `ssh-keygen` imprimiu. O segundo `ssh`
não pediu nada.

A chave destrancada vive só na memória do agente, e acaba com ele: um logout, uma reinicialização ou um
`ssh-add -D` a esquecem. O arquivo da chave no disco continua cifrado. Num desktop, o agente costuma
começar sozinho com a sessão. O GNOME e o macOS podem guardar a frase-senha no chaveiro do login, e o
agente do Windows lembra as chaves entre reinicializações, e assim a pessoa digita a frase-senha uma vez.

**Não encaminhe o agente para máquinas em que você não confia.** O `ssh -A` deixa o servidor remoto usar
o seu agente enquanto você está conectado; quem for root nesse servidor pode então entrar em qualquer
lugar onde a sua chave funciona. O jump host da seção 08 faz o mesmo serviço sem esse risco.
