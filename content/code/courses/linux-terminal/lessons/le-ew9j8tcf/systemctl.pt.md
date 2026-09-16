---
title: Sete verbos, e `enable` não é `start`
version: 1
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
sudo systemctl start nginx        # rode, neste segundo
sudo systemctl enable nginx       # rode a cada boot daqui em diante
sudo systemctl enable --now nginx # os dois
```

**O `enable` não inicia nada. O `start` não sobrevive a um reboot.** Cada um de nós já configurou um
serviço, conferiu que funcionava, reiniciou, e encontrou ele ausente — e é por isso.

## O que o `enable` de fato faz

Aqui está, rodado contra uma árvore de arquivos em vez de um sistema em execução, que é por que
funciona nesta máquina:

```
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 is-enabled hello.service
disabled
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 enable hello.service
Created symlink /srv/machines/ubuntu24/etc/systemd/system/multi-user.target.wants/hello.service → /etc/systemd/system/hello.service.
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 is-enabled hello.service
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
root@vm:/srv/machines/ubuntu24# ls -l /srv/machines/ubuntu24/etc/systemd/system/multi-user.target.wants/
total 0
lrwxrwxrwx 1 root root 40 Sep 14 23:14 e2scrub_reap.service -> /lib/systemd/system/e2scrub_reap.service
lrwxrwxrwx 1 root root 33 Sep 14 23:23 hello.service -> /etc/systemd/system/hello.service
lrwxrwxrwx 1 root root 40 Sep 14 23:14 remote-fs.target -> /usr/lib/systemd/system/remote-fs.target
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 disable hello.service
Removed "/srv/machines/ubuntu24/etc/systemd/system/multi-user.target.wants/hello.service".
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 is-enabled hello.service
disabled
```

Três entradas naquela listagem, e duas delas não foram postas ali por você — é essa a cara de um
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
systemctl status nginx        # a resposta para humano — seção 79
systemctl is-active nginx     # active / inactive / failed
systemctl is-enabled nginx    # enabled / disabled / static / masked
systemctl is-failed nginx     # para script
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
systemctl list-units --type=service              # o que está carregado e rodando
systemctl list-units --type=service --all        # incluindo os inativos
systemctl --failed                               # a lista curta que importa
systemctl list-unit-files --type=service         # todo arquivo de unit, habilitado ou não
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
sudo systemctl daemon-reload      # depois de editar um arquivo de unit na mão
systemctl cat nginx               # imprime o arquivo de unit, e as sobreposições
```

**O `daemon-reload` é o que as pessoas esquecem.** Edite um arquivo `.service` e o systemd segue com
a versão que leu no boot até você mandar reler. O sintoma é uma mudança sem efeito e um serviço que
reinicia alegremente no comportamento antigo. O `systemctl edit` — seção 11 — faz o reload por você,
que é uma entre várias razões para preferi-lo.
