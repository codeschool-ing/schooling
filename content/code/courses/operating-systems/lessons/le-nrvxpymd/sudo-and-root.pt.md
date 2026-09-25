---
title: root, sudo, e o registro de cada uso
version: 1
---

**O Ubuntu bloqueia o root.** Existe uma conta root com ID 0, e ninguém consegue entrar nela:

```
ana@server:~$ sudo passwd -S root
root L 2026-09-25 0 99999 7 -1
ana@server:~$ sudo passwd -S ana
ana P 2026-09-25 0 99999 7 -1
```

`root L`: nenhuma senha utilizável. A ana tem `P`. A administração no Ubuntu acontece **pelo sudo**, como
uma pessoa, um comando de cada vez, e esse projeto tem três consequências que vale conhecer.

**1. Dá para perguntar o que você pode.**

```
ana@server:~$ sudo -l
Matching Defaults entries for ana on server:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, use_pty, env_keep+=DEBIAN_FRONTEND

User ana may run the following commands on server:
    (ALL : ALL) ALL
    (ALL) NOPASSWD: ALL
```

`(ALL : ALL) ALL` é a regra do grupo sudo: qualquer comando, como qualquer usuário. A linha `NOPASSWD` é
a preparação desta máquina de teste, o motivo de nenhum registro deste curso mostrar o sudo pedindo
senha; uma instalação de verdade não tem isso. As regras moram no **`/etc/sudoers`** e nos arquivos de
`/etc/sudoers.d/`, e só se editam com o `visudo`, que se recusa a salvar um arquivo com erro. Um
sudoers quebrado é como um administrador se tranca do lado de fora.

**2. Todo uso fica registrado, com quem pediu.**

```
ana@server:~$ sudo journalctl _COMM=sudo --no-pager -o cat | grep COMMAND | tail -3
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/passwd -S root
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/passwd -S ana
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/journalctl _COMM=sudo --no-pager -o cat
```

Cada linha diz *quem* (`ana`), *de onde*, *como quem* e *exatamente o quê*. Numa máquina que
várias pessoas administram, essa é a resposta para "quem mudou isto?", que o `root` entrando direto
nunca daria: toda sessão de root parece igual.

**3. Ele pede a sua própria senha.** O `su` pediu a da carla. O `sudo` pede **a sua**, porque a pergunta
não é "você sabe o segredo do root", e sim "você ainda é a pessoa que se sentou aqui", e as regras
decidem o resto.

## `sudo -i` e `sudo -s`

Os dois abrem um shell de root inteiro, o prompt `#` da aula 8. O registro então mostra um comando, o
shell, e nada do que foi digitado dentro dele. **Prefira comandos avulsos**, e quando um shell de root
for necessário, saia dele assim que o trabalho acabar.
