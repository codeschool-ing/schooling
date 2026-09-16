---
title: Um timer são dois arquivos, e um deles você já conhece
version: 1
---

Um timer do systemd é um **serviço que já existe**, mais um arquivo que diz
quando iniciá-lo. Essa divisão é o projeto inteiro: o que rodar e quando rodar
são unidades separadas, e a primeira é o `.service` da aula 5.

## O serviço

```ini
[Unit]
Description=Nightly report

[Service]
Type=oneshot
ExecStart=/home/ana/bin/report.sh
User=ana
```

**O `Type=oneshot`** é a diferença para os serviços da aula 5: ele roda, termina,
e o systemd não considera isso uma falha. Um `.service` para um timer é um job,
não um daemon.

Não há agenda nele. Você pode rodá-lo à mão com `systemctl start report.service`,
o que vale fazer antes de confiar no timer — **o timer não é o que está quebrado,
nove vezes em dez.**

## O timer

```ini
[Unit]
Description=Run the nightly report at 03:00

[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=15m
Persistent=true

[Install]
WantedBy=timers.target
```

Mesmo nome base, extensão diferente. **O `report.timer` inicia o
`report.service`**, só por essa convenção — e o `Unit=` sobrepõe isso quando os
nomes diferem.

| | |
|---|---|
| `OnCalendar=` | uma agenda de relógio — seção 11 |
| `RandomizedDelaySec=15m` | espalha a manada: um atraso aleatório de até quinze minutos |
| `Persistent=true` | se a máquina estava desligada, roda no próximo boot — seção 12 |
| `WantedBy=timers.target` | habilite e ele inicia com o sistema |

## Instalando um

```sh
sudo cp report.service report.timer /etc/systemd/system/
sudo systemctl daemon-reload            # systemd re-reads the unit files
sudo systemctl enable --now report.timer
```

**O `daemon-reload` é o passo que as pessoas esquecem.** Sem ele o systemd
continua rodando a versão que leu no boot, e a sua edição não tem efeito nenhum.

**Habilite o `.timer`, não o `.service`.** Habilitar o serviço iniciaria o job no
boot, que não é o que você pediu.

Para um job que é seu em vez de ser da máquina, os mesmos arquivos vão em
`~/.config/systemd/user/` e todo comando leva `--user` — e isso precisa de
`loginctl enable-linger ana` para os timers rodarem enquanto você não está
logado.

## Confira antes de instalar

```
ana@vm:~/work/cron/units$ systemd-analyze verify ./report.timer ./report.service && echo "both ok"
Binding to IPv6 address not available since kernel does not support IPv6.
both ok
```

A linha do IPv6 é este contêiner falando, não as suas unidades.

Agora o mesmo timer com uma letra errada — `OnCalender` em vez de `OnCalendar`:

```
ana@vm:~/work/cron/units$ systemd-analyze verify ./report-typo.timer ./report-typo.service
/home/ana/work/cron/units/report-typo.timer:5: Unknown key name 'OnCalender' in section 'Timer', ignoring.
report-typo.timer: Timer unit lacks value setting. Refusing.
Binding to IPv6 address not available since kernel does not support IPv6.
Unit report-typo.timer has a bad unit file setting.
```

**Duas mensagens, e a segunda é a que importa.** O `Unknown key name` é um aviso
— o systemd ignora chaves que não reconhece, que é como um `OnCalendar` mal
escrito vira *um timer sem agenda* em vez de um erro. E um timer sem agenda é
recusado: `Timer unit lacks value setting.`

Esse é o modo de falha para lembrar. **Um erro de digitação num arquivo de
unidade normalmente é ignorado, não relatado**, e o `systemd-analyze verify` antes
do `daemon-reload` é como você descobre qual dos dois casos você tem. Ele lê
arquivos por caminho e não precisa de root.

## O que os dois arquivos te dão a mais que uma linha de crontab

| | |
|---|---|
| o journal | `journalctl -u report.service` — toda execução, com saída, com hora |
| o ambiente | `Environment=`, `EnvironmentFile=`, e um `PATH` que você controla |
| a identidade | `User=`, `Group=`, e o sandbox da aula 5 |
| dependências | `After=network-online.target` — uma coisa que o cron não sabe expressar |
| uma execução por vez | um `.service` que já está rodando não é iniciado de novo |
| pôr o atraso em dia | `Persistent=`, para o que o cron não tem resposta |

Esse último par é a razão honesta para preferir um timer para qualquer coisa que
importa: **sobreposição e execuções perdidas são resolvidas no arquivo em vez de
no seu script** — que são as seções 14 e 12, e cerca de metade do que a seção 16 trata.

## O que custa

Dois arquivos em vez de uma linha. Um `daemon-reload` que você vai esquecer uma
vez. E uma sintaxe de arquivo de unidade com umas quarenta configurações, onde o
cron tem cinco campos.

**Numa máquina em que o job é uma linha, o cron continua sendo a resposta certa.**
Numa máquina em que o job pertence a um serviço para o qual você já escreveu uma
unidade, o timer são quinze linhas e tudo acima.
