---
title: Privilégio no laboratório
version: 1
---

O servidor `www` da loja roda o portal e também guarda a planilha do financeiro. Esta seção olha o que
três contas nessa mesma máquina podem fazer: a conta do próprio portal, a do bruno e a da ana.

### A conta do portal

```
root@www:~# id shop
uid=990(shop) gid=990(shop) groups=990(shop)
root@www:~# ps -o user,args -p $(cat /srv/portal/portal.pid)
USER     COMMAND
shop     python3 /srv/portal/portal.py
root@www:~# getpcaps $(cat /srv/portal/portal.pid) | cut -d' ' -f2
cap_net_bind_service=eip
```

O `id shop` mostra uma conta sem nada a mais: usuário `shop`, grupo `shop`, nenhum outro grupo. O `ps`
confirma que o portal em execução pertence a ela, e não ao `root`, a conta de administrador que pode
tudo na máquina. Um programa web rodando como `root` é um dos erros mais comuns em servidores pequenos,
porque é o jeito mais fácil de fazê-lo subir; isso quer dizer que um defeito no portal é um defeito com
controle total do servidor.

A última linha é mais sutil. Um programa no Linux normalmente precisa ser `root` para escutar numa
porta abaixo de 1024, e a porta web é a 80. Em vez de rodar como `root` por essa única necessidade, o
portal foi iniciado com uma só **capability**, `cap_net_bind_service`: o direito de escutar em portas
baixas, e nada mais do que o `root` tem. O Linux divide o poder do `root` em umas quarenta peças assim
exatamente para que um programa receba uma delas.

### Quem lê os arquivos

```
root@www:~# ls -l /srv/hr/salaries.csv /srv/portal/users
-rw-r----- 1 bruno hr    33 Sep 30 17:00 /srv/hr/salaries.csv
-rw-r----- 1 root  shop 189 Sep 30 17:00 /srv/portal/users
bruno@www:~$ id
uid=1002(bruno) gid=1002(bruno) groups=1002(bruno),1100(hr)
bruno@www:~$ cat /srv/hr/salaries.csv
name,monthly
ana,7800
bruno,8200
ana@www:~$ cat /srv/hr/salaries.csv
cat: /srv/hr/salaries.csv: Permission denied
```

O arquivo de salários pode ser lido pelo dono, o bruno, e pelo grupo `hr`. O arquivo de senhas do
portal pode ser lido pelo `root` e pelo grupo `shop`, porque o portal precisa conferir senhas e mais
ninguém precisa. O `id` do bruno mostra que ele está em `hr`, e ele lê os salários. A ana cuida da TI e
tem conta neste servidor, e é recusada, porque cuidar da TI não é motivo para ler salários.

### O que a administradora pode fazer

A ana administra o portal. Isso não exige `root`; exige reiniciar o portal e ler o log dele. O `sudo` é o
programa que deixa um usuário rodar comandos específicos como outro usuário, em geral o `root`, sob
regras que um administrador escreveu:

```
ana@www:~$ sudo -l
Matching Defaults entries for ana on www:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    use_pty

User ana may run the following commands on www:
    (root) NOPASSWD: /usr/local/sbin/portal-restart, /usr/bin/tail /var/log/lab/portal.log
ana@www:~$ sudo tail /var/log/lab/portal.log
192.168.10.20 - "GET / HTTP/1.1" 200 -
192.168.10.20 - "GET /handbook HTTP/1.1" 200 -
ana@www:~$ sudo -l tail /var/log/lab/portal.log; echo "exit $?"
/usr/bin/tail /var/log/lab/portal.log
exit 0
ana@www:~$ sudo -l cat /srv/hr/salaries.csv; echo "exit $?"
exit 1
```

O `sudo -l` lista o que a ana pode rodar como `root` no `www`, e a resposta são dois comandos: o script
de reinício do portal e o `tail` sobre o log do portal, com aquele arquivo exato nomeado. Ela usa o
segundo, e funciona. O `sudo -l` seguido de um comando pergunta se aquele comando seria permitido, sem
rodá-lo: o `tail` no log é (`exit 0`), e o `cat` nos salários não é (`exit 1`).

Dois detalhes deixam essa regra justa. Os comandos estão escritos com **caminho completo e
argumentos**, então a regra não permite `tail` em nenhum outro arquivo. E ela não permite um shell nem
um editor: uma regra que permitisse `sudo vim` ou `sudo bash` entregaria o `root` inteiro, porque os dois
conseguem rodar qualquer outro comando lá de dentro. A aula 4 de `linux-terminal` trata de `sudo` e
permissões por inteiro.
