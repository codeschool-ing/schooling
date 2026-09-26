---
title: Um artigo que quebra coisas
version: 1
---

A aula 1 achou uma linha velha no `/etc/hosts` da Carla, apontando `intranet` para um endereço onde nada
responde. Vale perguntar de onde vem uma linha assim. A base de conhecimento do escritório:

```
ana@host:~$ ls kb; grep -rl intranet kb
intranet-on-a-new-computer.md
printing-from-a-new-computer.md
shared-folder-full.md
kb/intranet-on-a-new-computer.md
ana@host:~$ cat kb/intranet-on-a-new-computer.md
# Intranet on a new computer

Add the intranet to the hosts file:

    echo "10.30.0.200 intranet" | sudo tee -a /etc/hosts

Then open http://intranet/ in the browser.

Last reviewed: 2024-03-11
```

O artigo dá o endereço antigo, `10.30.0.200`, onde a intranet morava quando ele foi escrito. Qualquer
pessoa configurando um computador à mão o seguiria. Seguido no `pc2`:

```
ana@pc2:~$ echo "10.30.0.200 intranet" | sudo tee -a /etc/hosts
10.30.0.200 intranet
ana@pc2:~$ curl -sS -m 10 http://intranet/
curl: (7) Failed to connect to intranet port 80 after 3094 ms: Couldn't connect to server
```

O mesmo defeito da aula 1, **3094 milissegundos e nada**, produzido seguindo a própria documentação da
equipe. É a pior coisa que uma KB pode fazer: ninguém desconfia do artigo, porque o artigo é aquilo em que
disseram para confiar. A aula 1 consertou um computador; o artigo teria quebrado o próximo.
