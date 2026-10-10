---
title: Um arquivo por assunto, no git
version: 1
---

A cura para o desvio é um hábito com duas metades. **Todo valor de que um servidor precisa fica
escrito num arquivo guardado em outro lugar que não o servidor**, e o servidor é feito a partir
desse arquivo, em vez de editado à mão. O resto desta lição monta as duas metades para o servidor
do `shop`: aqui, o arquivo e o repositório onde ele mora; na próxima seção, o script que o coloca
no lugar.

## Qual arquivo no servidor

A escolha tentadora é o próprio `postgresql.conf`, já que todo parâmetro está nele, comentado com o
valor padrão. **Deixe-o como o Ubuntu o escreveu.** Ele passa de oitocentas linhas, e o
`pg_createcluster` o gera para uma versão maior. Um valor mudado no meio dele é uma linha perdida
entre oitocentas, num arquivo que ninguém consegue comparar com o que a próxima versão gera. Perto
do fim está a saída, que a lição 5 apontou:

```
ana@db:~$ wc -l /etc/postgresql/16/main/postgresql.conf
828 /etc/postgresql/16/main/postgresql.conf
ana@db:~$ grep -n '^include_dir' /etc/postgresql/16/main/postgresql.conf
818:include_dir = 'conf.d'			# include files ending in '.conf' from
```

Todo arquivo em `/etc/postgresql/16/main/conf.d/` cujo nome termina em `.conf` é lido depois do
arquivo principal, **na ordem dos nomes dos arquivos**, e quando dois arquivos definem o mesmo
parâmetro vence o que vem depois. O `postgresql.auto.conf` é lido depois de todos eles. Assim, uma
equipe que divide o trabalho dá nomes aos arquivos para dizer quem vem primeiro: `10-memory.conf`,
`20-logging.conf`, `90-local.conf` para o único valor que muda numa máquina só. O número é a ordem,
o que faz de sobrescrever um valor um ato deliberado, e não um acaso do `ls`.

Este servidor é pequeno o bastante para um arquivo só, e ele diz o que o servidor do `shop` muda e
por quê:

```conf
# 50-shop.conf: what the shop's server sets differently from Ubuntu's
# defaults. provision.sh copies it into /etc/postgresql/16/main/conf.d/.
listen_addresses = '*'               # the application connects from 10.0.0.0/24
shared_buffers = 1GB                 # a quarter of a 4 GB machine (lesson 6)
work_mem = 16MB
maintenance_work_mem = 256MB
log_min_duration_statement = 500ms   # lesson 19
log_lock_waits = on
```

**Os comentários dizem o porquê, nunca o quê.** `shared_buffers = 1GB` já diz o quê; o motivo é a
aritmética da lição 6, e daqui a um ano o motivo é a parte de que alguém precisa antes de mudar o
número. Dois desses valores só passam a valer quando o servidor sobe de novo, e o script da próxima
seção tem de lidar com isso.

O `pg_hba.conf` não ganha arquivo próprio. O PostgreSQL 16 consegue incluir arquivos a partir dele,
mas o do Ubuntu não faz isso, e nesse arquivo **a ordem das linhas é o significado** — a primeira
linha que casa com uma conexão decide, como a lição 5 mostrou. Por isso o script vai acrescentar
uma linha exata, no fim, onde nada acima dela casa com as mesmas conexões.

## O original mora no git

A cópia que vale está num repositório. Numa equipe ele mora num servidor Git, e o servidor de banco
nunca guarda a única cópia; nesta lição ele mora no seu diretório pessoal, num diretório chamado
`shop-db`, com o arquivo em `shop-db/conf.d/50-shop.conf`. Diga ao git quem você é uma vez, e chame
o primeiro branch de `main`:

```sh
git config --global user.name "Ana"
git config --global user.email ana@example.com
git config --global init.defaultBranch main
```

Depois crie o diretório, salve o arquivo nele com o seu editor e faça o commit:

```
ana@db:~$ mkdir -p shop-db/conf.d
ana@db:~$ git -C shop-db init
Initialized empty Git repository in /home/ana/shop-db/.git/
ana@db:~$ git -C shop-db add conf.d/50-shop.conf
ana@db:~$ git -C shop-db commit -m "The shop server's settings, one file"
[main (root-commit) cca080c] The shop server's settings, one file
 1 file changed, 8 insertions(+)
 create mode 100644 conf.d/50-shop.conf
```

O `git -C shop-db` roda o git como se você tivesse entrado em `shop-db` antes. O hash depois de
`root-commit` vai ser outro na sua máquina. A partir de agora, **a resposta para "como este servidor
está configurado, desde quando e por quê" é o `git log`**, e o servidor é só uma cópia dele.

## A porta que isto fecha

O `ALTER SYSTEM` continua funcionando, e numa emergência é o jeito mais rápido de mudar um valor sem
um shell na máquina. Uma regra impede que ele vire desvio: **o valor entra no repositório no mesmo
dia, e o `ALTER SYSTEM RESET` o tira do `postgresql.auto.conf`.** Esse arquivo é lido por último,
então um valor esquecido nele passa por cima de todo arquivo em `conf.d`, inclusive o que você
acabou de commitar. E continua passando muito depois de todo mundo ter esquecido dele, exatamente
como o `work_mem = 64MB` fez na seção anterior.
