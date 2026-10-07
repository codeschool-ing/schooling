---
title: Sete verbos, e `enable` não é `start`
version: 3
---

O `systemctl` é a fachada de todo o systemd, e você precisa de sete verbos dele. Eles se dividem em
dois grupos, e a divisão é a coisa mais importante desta aula.

| **agora** | | **no próximo boot** |
|---|---|---|
| `start` | | `enable` |
| `stop` | | `disable` |
| `restart` | | |
| `reload` | | |
| `status` | | `is-enabled` |

```
sudo systemctl start nginx        # run it, this second
sudo systemctl enable nginx       # run it every boot from now on
sudo systemctl enable --now nginx # both
```

**O `enable` não inicia nada. O `start` não sobrevive a um reboot.** Cada um de nós já configurou um
serviço, conferiu que funcionava, reiniciou, e encontrou ele ausente — e é por isso.

## O que o `enable` de fato faz

Ele precisa de um serviço para habilitar, e esta aula usa um próprio, o `hello`: um script de três
linhas que diz olá uma vez por minuto, e a unit que o roda, que a seção 11 lê linha a linha. Crie
os dois agora:

```sh
printf '#!/bin/sh\nwhile true; do echo "hello"; sleep 60; done\n' | sudo tee /usr/local/bin/hello.sh > /dev/null
sudo chmod 755 /usr/local/bin/hello.sh
sudo tee /etc/systemd/system/hello.service > /dev/null <<'END'
[Unit]
Description=A tiny service that says hello
Documentation=https://example.com/hello
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hello.sh
Restart=on-failure
RestartSec=5
User=ana

[Install]
WantedBy=multi-user.target
END
```

(`User=ana` o roda como você. Se a sua conta tem outro nome, escreva esse nome ali.)

Agora habilite-o. O `--root=/` faz o `systemctl` trabalhar nos arquivos sob `/` em vez de perguntar
ao systemd em execução, que é como isto funciona na máquina em que estas transcrições foram
capturadas, onde não há systemd rodando. Na sua, `sudo systemctl enable hello.service` faz o mesmo
e depois avisa o systemd em execução:

```
ana@vm:~$ sudo -i
root@vm:~# systemctl --root=/ is-enabled hello.service
disabled
root@vm:~# systemctl --root=/ enable hello.service
Created symlink /etc/systemd/system/multi-user.target.wants/hello.service → /etc/systemd/system/hello.service.
root@vm:~# systemctl --root=/ is-enabled hello.service
enabled
```

**O `enable` criou um link simbólico.** É isso, inteiro.

Leia o caminho que ele criou: `multi-user.target.wants/`. A seção 13 é sobre targets; por ora, o
diretório é uma lista de *coisas que este target quer rodando*, e habilitar um serviço é colocá-lo
naquela lista. No boot, o systemd chega no `multi-user.target`, lê o diretório, e inicia o que está
nele.

Nada em criar um link simbólico inicia um programa. **Isso não é uma esquisitice — é o projeto
correto**, e quando você vê o link a regra deixa de precisar ser decorada.

O `disable` remove de novo:

```
root@vm:~# ls -l /etc/systemd/system/multi-user.target.wants/
total 0
lrwxrwxrwx 1 root root 42 Oct  3 05:42 containerd.service -> /usr/lib/systemd/system/containerd.service
lrwxrwxrwx 1 root root 38 Oct  3 05:42 docker.service -> /usr/lib/systemd/system/docker.service
lrwxrwxrwx 1 root root 40 Sep 17 02:20 e2scrub_reap.service -> /lib/systemd/system/e2scrub_reap.service
lrwxrwxrwx 1 root root 33 Oct  7 11:34 hello.service -> /etc/systemd/system/hello.service
lrwxrwxrwx 1 root root 42 Oct  3 05:36 postgresql.service -> /usr/lib/systemd/system/postgresql.service
lrwxrwxrwx 1 root root 44 Oct  3 05:36 redis-server.service -> /usr/lib/systemd/system/redis-server.service
lrwxrwxrwx 1 root root 40 Oct  3 05:36 remote-fs.target -> /usr/lib/systemd/system/remote-fs.target
lrwxrwxrwx 1 root root 40 Oct  3 05:36 ssl-cert.service -> /usr/lib/systemd/system/ssl-cert.service
lrwxrwxrwx 1 root root 51 Oct  7 10:48 unattended-upgrades.service -> /usr/lib/systemd/system/unattended-upgrades.service
root@vm:~# systemctl --root=/ disable hello.service
Removed "/etc/systemd/system/multi-user.target.wants/hello.service".
root@vm:~# systemctl --root=/ is-enabled hello.service
disabled
```

Nove entradas naquela listagem, e só uma delas foi posta ali por você — é essa a cara de um
serviço habilitado em qualquer máquina. A seção 11 da aula 3 te ensinou a ler o `->`; esta é aquela
leitura, sendo cobrada.

## `restart` e `reload` não são a mesma coisa

| | faz |
|---|---|
| `restart` | para e inicia. **Conexões caem, estado se perde** |
| `reload` | manda reler a configuração **continuando rodando** |
| `reload-or-restart` | recarrega se ele suportar, reinicia se não |

**Prefira `reload` em qualquer coisa servindo tráfego.** Nginx, Apache, Postgres e sshd suportam, e
um reload é invisível para quem está conectado.

Nem todo serviço implementa — o arquivo de unit precisa dizer `ExecReload=`, e a seção 11 mostra
onde. Um `systemctl reload` num serviço sem isso falha e te avisa, o que é melhor do que reiniciar
em silêncio.

**E o que vale saber sobre o sshd**: recarregar não te desconecta, e reiniciar também não — a sessão
em curso já está estabelecida. O que uma configuração quebrada *mata* é o seu próximo login, e é por
isso que se testa com um segundo terminal que você não fechou.

## `status` e a família `is-*`

```
systemctl status nginx        # the human answer — section 79
systemctl is-active nginx     # active / inactive / failed
systemctl is-enabled nginx    # enabled / disabled / static / masked
systemctl is-failed nginx     # for a script
```

A família `is-*` imprime uma palavra e define um código de saída, o que faz dela a escolha para
script. O `status` é para ler, e a seção 10 o desmonta.

O `systemctl is-enabled` tem quatro respostas e duas precisam de explicação:

| | |
|---|---|
| `static` | ele não tem seção `[Install]`, então não pode ser habilitado — outra coisa o puxa |
| `masked` | desabilitado *com força*: ligado a `/dev/null` para não ser iniciado nem por acidente |

O `mask` é a marreta, e existe para um caso real: um pacote que você não pode remover insiste em
iniciar algo que você não quer. O `unmask` desfaz. Um serviço que não inicia sem motivo aparente é
frequentemente um serviço mascarado, e o `is-enabled` é como se descobre isso numa palavra.

## Ver o que existe

```
systemctl list-units --type=service              # what is loaded and running
systemctl list-units --type=service --all        # including the inactive
systemctl --failed                               # the short list that matters
systemctl list-unit-files --type=service         # every unit file, enabled or not
```

**`systemctl --failed` é o primeiro comando a rodar numa máquina que alguém diz estar quebrada.**
Ele imprime os serviços que tentaram e não conseguiram, e normalmente é uma linha e normalmente é a
resposta.

A diferença entre o primeiro e o último vale guardar: o `list-units` é sobre o que está **carregado
agora**; o `list-unit-files` é sobre o que **existe em disco**. Um serviço instalado e nunca
iniciado aparece num e não no outro.

## O nome, e o sufixo que você quase sempre pode omitir

`nginx.service` é o nome completo. `systemctl start nginx` funciona porque o `.service` é presumido
quando você omite o sufixo. Outros tipos precisam dele:

| sufixo | é |
|---|---|
| `.service` | um programa a rodar — o padrão |
| `.timer` | um agendamento — aula 13 |
| `.socket` | uma porta ou socket que inicia o serviço na primeira conexão |
| `.mount` | um sistema de arquivos — seção 12 da aula 3, gerado do `/etc/fstab` |
| `.target` | um grupo dos acima — seção 13 |

Então `systemctl start backup.timer` precisa do sufixo, e `systemctl start nginx` não.

## Mais dois que você vai querer

```
sudo systemctl daemon-reload      # after editing a unit file by hand
systemctl cat nginx               # print the unit file, and any overrides
```

**O `daemon-reload` é o que as pessoas esquecem.** Edite um arquivo `.service` e o systemd segue com
a versão que leu no boot até você mandar reler. O sintoma é uma mudança sem efeito e um serviço que
reinicia alegremente no comportamento antigo. O `systemctl edit` — seção 11 — faz o reload por você,
que é uma entre várias razões para preferi-lo.
