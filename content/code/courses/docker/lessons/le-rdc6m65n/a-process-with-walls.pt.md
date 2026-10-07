---
title: Um processo com paredes
version: 1
---

**Um container costuma ser imaginado como uma pequena máquina virtual**: um computadorzinho com
sistema operacional próprio, iniciado dentro do grande. Essa imagem está errada, e ela prevê coisas
que não acontecem. Não há boot, nem segundo kernel, nem máquina escondida. **Um container é um
processo comum do host, iniciado de um jeito que limita o que ele enxerga e quanto ele pode usar.**

O jeito mais rápido de acreditar nisso é olhar. A Ana inicia o PostgreSQL num container, em segundo
plano, que é o que o `-d` (de *detached*, desacoplado) significa:

```
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17
6e19ca7ee468df3d42d4217746fb90dac8d4bb6928bd3235fb1cb674076a453c
```

A sequência hexadecimal longa é o id do container. O `docker ps` lista os containers em execução e
encurta o id para os doze primeiros caracteres:

```
ana@vm:~$ docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED         STATUS         PORTS      NAMES
6e19ca7ee468   postgres:17   "docker-entrypoint.s…"   4 seconds ago   Up 4 seconds   5432/tcp   db
```

Agora a Ana pergunta ao **host**, e não ao Docker, quais são os processos chamados `postgres`:

```
ana@vm:~$ ps -o pid,ppid,uid,cmd -C postgres
  PID  PPID   UID CMD
10912 10887   999 postgres
10981 10912   999 postgres: checkpointer 
10982 10912   999 postgres: background writer 
10984 10912   999 postgres: walwriter 
10985 10912   999 postgres: autovacuum launcher 
10986 10912   999 postgres: logical replication launcher 
```

O banco está ali, na lista comum de processos do host. Ele tem um número de processo comum, 10912,
e as cinco linhas abaixo dele são os processos auxiliares que o próprio PostgreSQL inicia, todos com
10912 como pai. Nada neles diz "container". O `docker top` faz ao Docker a mesma pergunta sobre o
container `db`, e recebe os mesmos processos com os mesmos números:

```
ana@vm:~$ docker top db -o pid,ppid,uid,args
PID                 PPID                UID                 COMMAND
10912               10887               999                 postgres
10981               10912               999                 postgres: checkpointer
10982               10912               999                 postgres: background writer
10984               10912               999                 postgres: walwriter
10985               10912               999                 postgres: autovacuum launcher
10986               10912               999                 postgres: logical replication launcher
ana@vm:~$ docker exec db id postgres
uid=999(postgres) gid=999(postgres) groups=999(postgres),101(ssl-cert)
```

**O `999` merece um segundo olhar.** Dentro da imagem, 999 é o usuário chamado `postgres`, que a
imagem criou quando foi construída, como o `id` mostra. No host, 999 é só um número; o nome que o
`/etc/passwd` do próprio host der a ele, se der algum, não tem nada a ver com o banco. Para o
kernel, um usuário é um número, e cada lado da parede o lê pela sua própria lista de nomes. A aula
14 volta a isso, porque é o que decide o que um processo dentro de um container pode fazer com
arquivos fora dele.

## O mesmo processo, visto de dentro

De dentro do container, o mesmo `postgres` vê um mundo bem diferente:

```
ana@vm:~$ docker exec db cat /proc/1/status | grep -E "^(Name|Pid|PPid):"
Name:	postgres
Pid:	1
PPid:	0
```

Dentro, ele é o processo **1**, o primeiro do seu pequeno mundo, e o pai dele é 0, que quer dizer
"ninguém que eu consiga ver". Fora, ele é o 10912 e tem pai. **As duas coisas são verdade ao mesmo
tempo**: o kernel mantém um processo só e o mostra com dois números, porque o container recebeu o
próprio **namespace de processos**. Essa é uma das paredes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um kernel Linux embaixo. Acima dele, a lista de processos do host, com dockerd, bash e o postgres de número 10912. Parte dessa lista está dentro de uma caixa chamada container db: lá dentro, o mesmo postgres é o processo 1 e não enxerga o dockerd nem o bash.\"><defs><marker id=\"l1walls-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"250\" width=\"680\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">um kernel Linux, compartilhado por tudo acima dele</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a visão do host: todos os processos</text><rect x=\"40\" y=\"60\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">dockerd</text><rect x=\"190\" y=\"60\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">bash</text><rect x=\"350\" y=\"40\" width=\"340\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"6 4\"></rect><text x=\"366\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">container db</text><text x=\"366\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a visão dele: só o que está dentro</text><rect x=\"380\" y=\"100\" width=\"280\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">postgres</text><text x=\"520\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PID 1 dentro  ·  PID 10912 no host</text><text x=\"520\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">+ cinco processos auxiliares, filhos do PID 1</text><path d=\"M105 112 L105 248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1walls-ah-wire)\"></path><path d=\"M255 112 L255 248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1walls-ah-wire)\"></path><path d=\"M520 166 L520 180\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M520 232 L520 248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1walls-ah-wire)\"></path><text x=\"180\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chamadas de sistema</text></svg>", "caption": "Um processo, dois números. O host vê o postgres como 10912, entre os outros processos dele; dentro do container ele é o processo 1, sozinho. O kernel embaixo é o mesmo.", "same": ["container db"]}
```

As paredes são de dois tipos, e a aula 4 desmonta cada uma:

- **O que o processo enxerga** é limitado pelos namespaces. A própria lista de processos, como
  acima, o próprio nome de máquina, as próprias interfaces de rede, a própria visão do sistema de
  arquivos.
- **Quanto o processo pode usar** é limitado pelos cgroups: memória, tempo de CPU, o número de
  processos que ele pode iniciar.

Uma terceira peça fornece os arquivos. O processo enxerga um sistema de arquivos feito a partir da
imagem, e a aula 4 mostra como camadas de arquivos são empilhadas para montá-lo.

## O que decorre de "é um processo"

Três consequências aparecem em todas as aulas depois desta, então vale dizê-las uma vez aqui:

- **Ele inicia tão rápido quanto um processo inicia.** Não há sistema operacional para dar boot,
  então um container está pronto quando o programa dele está pronto. A aula 2 mede isso.
- **Ele vive enquanto o processo principal vive.** Quando esse processo termina, o container para.
  Um container cujo programa terminou o trabalho um segundo depois de começar não está quebrado;
  ele acabou.
- **Ele compartilha o kernel do host.** Todos os containers da máquina fazem as chamadas de sistema
  ao mesmo kernel. É daí que vem a velocidade, e é também por isso que as paredes importam: um
  processo que passa por elas está no host. A aula 21 trata de mantê-lo dentro.
