---
title: root, `su`, `sudo`, e por que o segundo venceu
version: 1
---

Tudo nesta aula até aqui tem uma exceção, e ela é total.

**root é o uid 0, e o kernel não confere permissões para o uid 0.** Não é "o root está em todos os
grupos", não é "os bits do root estão sempre ligados" — a checagem é pulada. Um arquivo
`-rw-------` de outra pessoa, o root lê. Um diretório `700`, o root entra. `chmod`, `chown`, um modo
sem bit nenhum: nada disso vale.

```
ana@vm:~$ head -1 /etc/shadow
head: cannot open '/etc/shadow' for reading: Permission denied
ana@vm:~$ sudo head -1 /etc/shadow
root:*:20501:0:99999:7:::
```

Mesmo arquivo, mesmo comando, mesmo segundo. A única coisa que mudou foi quem perguntou.

## Os dois jeitos de virar root, e por que um deles acabou

**`su` — switch user.** Ele pede a **senha do root** e te dá um shell de root pelo tempo que você
deixar aberto.

```
ana@vm:~$ su -
Password:
su: Authentication failure
```

Aquela falha não é um erro na transcrição. **No Ubuntu e na maioria das instalações Debian modernas
a conta root não tem senha nenhuma**, de propósito, então o `su` não tem como funcionar com entrada
alguma. A distribuição decidiu que você vai usar `sudo`.

**`sudo` — faça isto como outra pessoa.** Ele pede a **sua própria senha**, confere um arquivo para
ver se você tem direito, e roda **um comando**:

```
ana@vm:~$ whoami
ana
ana@vm:~$ sudo whoami
[sudo] password for ana:
root
ana@vm:~$ sudo id
uid=0(root) gid=0(root) groups=0(root)
```

Olhe a terceira linha. `sudo whoami` imprimiu `root` e depois você estava de volta em `ana@vm:~$` —
a elevação durou exatamente um comando.

## Por que o `sudo` venceu, em quatro motivos

**Ninguém precisa saber a senha do root.** Dez administradores, dez senhas pessoais, e nenhum
segredo compartilhado que precise ser trocado quando um deles sai.

**É registrado, com um nome junto.** O `/var/log/auth.log` guarda quem rodou o quê, como ele mesmo.
Um login de root compartilhado guarda "root", que é ninguém.

**Dá para estreitar.** Uma pessoa pode ter direito de reiniciar um serviço e mais nada, o que é
impossível com uma senha de root.

**E é um comando por vez.** Essa é a parte subestimada. Um shell de root é uma noite em que todo
erro de digitação é permanente; o `sudo` são cinco caracteres a mais que fazem você decidir, a cada
vez, que este comando específico deve rodar como root.

## Quem tem direito: o grupo, depois o arquivo

```
ana@vm:~$ id -nG
ana sudo team
```

No Debian e no Ubuntu, estar no grupo `sudo` é o que concede. No Red Hat e na família dele o grupo
se chama `wheel`. É esse o mecanismo inteiro na maioria das máquinas, e acrescentar alguém é
`usermod -aG sudo bruno` — com o `-a`, como a seção 08 insistiu.

Quem não está nele recebe isto:

```
carla@vm:~$ id -nG
carla
carla@vm:~$ sudo whoami
[sudo] password for carla:
carla is not in the sudoers file.
```

Ela digitou a senha certa. **O `sudo` autenticou e então recusou**, o que é a ordem correta: ele
confirma que você é quem diz ser antes de te contar o que você não pode fazer.

Versões mais antigas acrescentavam *"This incident will be reported."* — e cumpriam, por e-mail
para o root. É uma linha famosa e a maioria das versões atuais deixou de usá-la.

## As regras moram no `/etc/sudoers`

```
root    ALL=(ALL:ALL) ALL
%sudo   ALL=(ALL:ALL) ALL
```

Leia uma linha como **quem = (como quem) o quê**. O `%` marca um grupo. Então a segunda linha diz
*qualquer um do grupo `sudo`, em qualquer host, pode rodar qualquer comando como qualquer usuário*.

Elas podem ser bem mais estreitas, e é assim que estreitar se parece:

```
bruno  ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx
```

O bruno pode reiniciar o nginx como root, sem senha, e não pode fazer mais nada. Essa é a cara de
uma máquina bem administrada, e é por isso que o `sudo` vale o trabalho.

O `sudo -l` pergunta o que você pode:

```
ana@vm:~$ sudo -l
[sudo] password for ana:
Matching Defaults entries for ana on vm:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    use_pty

User ana may run the following commands on vm:
    (ALL : ALL) ALL
```

**Edite com o `visudo`, nunca com um editor direto.** O `visudo` confere a sintaxe antes de salvar,
e um erro de sintaxe no `/etc/sudoers` tranca todo mundo para fora do `sudo` numa máquina em que o
root não tem senha — o que é uma tarde com disco de resgate. Regras específicas vão num arquivo sob
`/etc/sudoers.d/`, editado com `visudo -f`.

## Rodar como alguém que não é o root

```
ana@vm:~$ sudo -u bruno whoami
bruno
ana@vm:~$ sudo -u bruno id -nG
bruno team
```

O `-u` escolhe a conta de destino, e o root é só o padrão. É assim que se testa o que uma conta de
serviço realmente consegue fazer — rode o comando como `www-data` e veja falhar do mesmo jeito que o
serviço falha, em vez de rodar como root e ver funcionar.

## A senha fica lembrada por alguns minutos

```
ana@vm:~$ sudo id -u
0
ana@vm:~$ sudo id -u
0
```

O segundo não perguntou. O `sudo` guarda uma marca de tempo por terminal e pula a pergunta por uns
quinze minutos. `sudo -k` esquece na hora, o que vale fazer antes de se afastar de uma máquina em
que outra pessoa encosta.

## A regra para levar

**Use `sudo` para o comando que precisa, e nada além.**

`sudo apt install nginx` está certo. Virar root e *depois* decidir o que fazer é como um `rm -rf` no
diretório errado passa de irritante a irrecuperável. A seção 12 é a metade prática — incluindo o
único `sudo` que não faz o que você espera.
