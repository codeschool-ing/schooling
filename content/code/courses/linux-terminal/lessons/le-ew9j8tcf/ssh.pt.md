---
title: `ssh`, porque toda máquina está em outro lugar
version: 1
---

Esta é uma seção numa aula cujo título não menciona ela, e está aqui porque **toda máquina Linux
que você vai administrar é uma que você alcança por ssh.** O curso não tem lugar melhor, e ficar
sem isso até lá seria desonesto sobre como o trabalho é.

Chaves, o prompt de impressão digital, e onde as coisas moram. Túneis, arquivos de configuração e
endurecimento são aula de outra pessoa.

```
ssh usuario@host
ssh -p 2222 ana@localhost       # uma porta que não é a 22
```

É isso. Um shell noutra máquina, e tudo das aulas 1 a 4 funciona lá exatamente como funciona aqui.

## A pergunta que ele faz na primeira vez

```
ana@vm:~$ ssh -p 2222 ana@localhost
The authenticity of host '[localhost]:2222 ([127.0.0.1]:2222)' can't be established.
ED25519 key fingerprint is SHA256:iokzK3UORZNPSUcTadj2ARlnsRdwOFmIQ2oOVirnSy8.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[localhost]:2222' (ED25519) to the list of known hosts.
ana@localhost's password:
```

Todo mundo digita `yes` sem ler. Eis o que ele está de fato perguntando.

**O servidor tem uma chave própria**, criada quando o ssh foi instalado. Aquela impressão digital é
um hash da metade pública dela. O seu ssh nunca viu esta máquina antes, então ele não tem como
saber se está falando com a máquina que você quis ou com alguém no meio se passando por ela.

Digitar `yes` quer dizer *aceito esta chave como a identidade desta máquina*, e ela é gravada no
`~/.ssh/known_hosts`. **Dali em diante o ssh confere toda vez**, em silêncio, e reclama alto se ela
mudar:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

Esse aviso quer dizer uma de três coisas, em ordem decrescente de probabilidade: a máquina foi
reconstruída e tem chave nova; você está alcançando outra máquina atrás do mesmo nome; ou alguém
está te interceptando. **Não é coisa de limpar sem saber qual.** O conserto, quando é inocente, é
`ssh-keygen -R nomedohost`, que remove a chave guardada para a pergunta ser feita de novo.

O jeito honesto de responder ao primeiro prompt é comparar a impressão digital com uma que te
deram por outro canal — impressa por `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` no servidor,
por alguém que já estava lá. Quase ninguém faz isso. Ainda assim é para isso que o prompt serve.

## Chaves em vez de senhas

Uma senha viaja pelo fio a cada conexão e pode ser adivinhada. Uma chave não faz nem uma coisa nem
outra. Crie uma:

```
ana@vm:~$ ssh-keygen -t ed25519 -C "ana@vm" -f ~/.ssh/id_ed25519 -N ""
Generating public/private ed25519 key pair.
Created directory '/home/ana/.ssh'.
Your identification has been saved in /home/ana/.ssh/id_ed25519
Your public key has been saved in /home/ana/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:754NYP2waKcTxYlX8j8/HBVtWL19iPG45a/enwVhrJY ana@vm
```

**Dois arquivos, e a diferença entre eles é a ideia inteira:**

```
ana@vm:~$ ls -l ~/.ssh
total 8
-rw------- 1 ana ana 399 Sep 14 23:23 id_ed25519
-rw-r--r-- 1 ana ana  88 Sep 14 23:23 id_ed25519.pub
```

O `id_ed25519` é a chave **privada**, modo `600`, e ela nunca sai desta máquina. O
`id_ed25519.pub` é a metade **pública**, modo `644`, e é feita para ser copiada a qualquer lugar:

```
ana@vm:~$ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKHhDDaH171LJb/mce2OhMnKDYo5PArO8BPrVDTHdhd ana@vm
```

Publicar aquela linha não te custa nada. Publicar o outro arquivo te custa tudo. A seção 66 da aula
4 disse que o `.ssh` é o diretório mais sensível que você tem, e é por isso — **o ssh confere as
permissões e recusa uma chave que outra pessoa poderia ler.**

`-t ed25519` é o algoritmo a usar; ele é curto, rápido e atual. `-N ""` quer dizer sem frase
secreta, o que está certo para esta demonstração e errado para um laptop — a frase secreta é o que
protege a chave privada se a máquina for roubada, e o `ssh-agent` é o que impede você de digitá-la
quarenta vezes por dia.

## Pôr a metade pública na outra máquina

```
ana@vm:~$ ssh-copy-id -p 2222 bruno@localhost
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ana/.ssh/id_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
bruno@localhost's password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -p 2222 'bruno@localhost'"
and check to make sure that only the key(s) you wanted were added.
```

Aquela foi a última vez que uma senha foi digitada. Veja:

```
ana@vm:~$ ssh -p 2222 bruno@localhost
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.18.44-fc-v33 x86_64)
...
bruno@vm:~$ whoami
bruno
bruno@vm:~$ ls -l ~/.ssh
total 8
-rw------- 1 bruno bruno 88 Sep 14 23:23 authorized_keys
-rw------- 1 bruno bruno 42 Sep 14 22:27 config
bruno@vm:~$ cat ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKHhDDaH171LJb/mce2OhMnKDYo5PArO8BPrVDTHdhd ana@vm
```

Nenhum prompt. **O `ssh-copy-id` acrescentou uma linha ao `~/.ssh/authorized_keys` do outro lado** —
a metade pública, sem alteração, a mesma string impressa acima. Aquele arquivo é a lista de chaves
com permissão de entrar como `bruno`, uma por linha, e dá para editar na mão; o `ssh-copy-id` é uma
comodidade que acerta as permissões.

Repare no que isso significa para o aviso da seção 72. **`passwd -l bruno` não teria impedido aquele
login.** Chaves nunca consultam o `/etc/shadow`. Quando alguém sai, a conta é travada *e* o
`authorized_keys` é esvaziado, e esquecer o segundo é um jeito real de as pessoas manterem acesso
por anos.

## Os quatro arquivos do `~/.ssh`

| | |
|---|---|
| `id_ed25519` | sua chave privada. `600`, nunca copiada |
| `id_ed25519.pub` | sua chave pública. Segura de colar em qualquer lugar |
| `authorized_keys` | chaves públicas com permissão de entrar **como você, nesta máquina** |
| `known_hosts` | chaves de servidores que **você** aceitou |

As duas metades da confusão valem ser ditas com todas as letras: o `authorized_keys` é sobre gente
entrando; o `known_hosts` é sobre máquinas em que você saiu. Eles moram no mesmo diretório e
respondem perguntas opostas.

## Rodar um comando sem um shell

```
ssh ana@host 'uptime'
ssh ana@host 'systemctl is-active nginx'
```

O ssh roda um comando e te entrega a saída. É assim que se pergunta a mesma coisa a cinquenta
máquinas num laço, e é a coisa mais útil que o ssh faz depois de te dar um shell.

**Aquele comando roda num shell não interativo e não de login**, que é a terceira linha da seção 74
— então seus aliases estão ausentes e seu `PATH` pode não ser o que você espera. Dê caminhos
completos, e a surpresa nunca acontece.

## Três coisas que valem agora

**`scp` e `rsync` vão pela mesma conexão.** `scp arquivo host:/caminho` copia uma coisa;
`rsync -av dir/ host:/caminho/` copia uma árvore e só as partes que mudaram. Os dois usam ssh por
baixo, então uma chave que serve para um shell serve para eles.

**Autenticação por senha costuma ficar desligada em servidor.** Quando as chaves funcionam, um
`PasswordAuthentication no` na configuração do servidor remove uma categoria inteira de ataque.
Faça isso *depois* de confirmar que sua chave funciona, de uma sessão que você não fechou.

**E o host que você não alcança é quase sempre um firewall.** `ssh: connect to host … port 22:
Connection refused` quer dizer que algo respondeu e disse não; `Connection timed out` quer dizer
que nada respondeu. Os dois apontam em direções diferentes, e a aula 11 volta a essa diferença.
