---
title: Arquivos de unit, e qual cópia vence
version: 1
---

Um arquivo de unit é como um serviço se descreve. É um arquivo ini — seções entre colchetes, linhas
`Chave=Valor` — e ele substituiu o script de shell de que tratou a seção 08.

Aqui está um completo, e ele faz tudo de que um serviço pequeno precisa:

```
root@vm:~# cat /etc/systemd/system/hello.service
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
```

Doze linhas. No SysV isso eram cem linhas de shell, a maior parte cuidando de arquivo de PID, que o
systemd agora faz sozinho.

## `[Unit]` — o que ele é e do que precisa

| | |
|---|---|
| `Description=` | o texto depois do nome no `systemctl status` |
| `Documentation=` | uma URL ou uma página `man:`. O `systemctl status` imprime |
| `After=` | inicie **depois** deste, se este estiver sendo iniciado |
| `Requires=` | e **falhe** se aquele falhar |
| `Wants=` | prefira que ele inicie antes, e siga em frente se não iniciar |

**`After=` é sobre ordem, `Requires=` é sobre dependência, e não são a mesma coisa.** `After=` sem
`Requires=` quer dizer *se você estiver iniciando os dois, comece por aquele* — e nada diz sobre o
outro precisar existir. Quase tudo que você escrever quer `After=` sozinho.

`Requires=` é forte: se a unit exigida parar ou falhar, a sua é parada também. Use quando o serviço
genuinamente não funciona sem o outro, e `Wants=` quando ele apenas preferiria.

## `[Service]` — como rodar

**`Type=` é o campo que dá errado.**

| | quer dizer | quando |
|---|---|---|
| `simple` | o processo que você inicia **é** o serviço | o padrão, e quase sempre certo |
| `exec` | como o simple, mas espera até ele ter de fato iniciado | um pouco mais seguro que o simple |
| `forking` | o programa vira daemon sozinho e o **pai termina** | um daemon à moda antiga |
| `oneshot` | ele roda, termina, e isso é sucesso | uma tarefa de preparação — o `active (exited)` da seção 10 |
| `notify` | o programa avisa ao systemd quando está pronto | serviços escritos para o systemd |

**Um programa moderno não deveria virar daemon**, e se ele não vira, `Type=simple` é o correto.
Dizer `forking` ao systemd sobre um programa que fica em primeiro plano produz um start que trava e
depois expira — uma das falhas mais confusas que existem, porque nada está de fato quebrado.

O resto do que você vai escrever:

| | |
|---|---|
| `ExecStart=` | o comando. **Um caminho absoluto**, e sem shell — sem `&&`, sem `>`, sem expansão de `$VAR` |
| `ExecReload=` | o que o `systemctl reload` roda. Ausente quer dizer reload recusado |
| `Restart=` | `no`, `on-failure`, `always`, `on-abnormal` |
| `RestartSec=` | quanto esperar antes. Sem isso, um laço de quebra é um laço apertado |
| `User=`, `Group=` | a conta com que rodar — a terceira propriedade da seção 07, numa linha |
| `WorkingDirectory=` | o ponto da seção 03 da aula 3: um serviço começa em `/` se não avisarem |
| `Environment=` | uma variável; `EnvironmentFile=` para um arquivo delas |
| `UMask=` | a seção 09 da aula 4 disse que seu dotfile não chega aqui. Este chega |

**`ExecStart=` não é um comando de shell.** É o engano que todo mundo comete uma vez:
`ExecStart=/usr/bin/foo > /var/log/foo.log` não redireciona — ele passa o `>` e o caminho como dois
argumentos para o `foo`. Se você precisa de um shell, diga: `ExecStart=/bin/sh -c 'foo >
/var/log/foo.log'`. Normalmente você não precisa, porque o journal da seção 12 já recolhe a saída.

## `[Install]` — o que o `enable` deve fazer

```
[Install]
WantedBy=multi-user.target
```

Esta seção é lida **apenas** pelo `systemctl enable`, e ela diz em qual diretório `.wants` o link
simbólico vai. A seção 09 mostrou o link sendo criado; esta é a linha que decidiu onde.

**Uma unit sem seção `[Install]` não pode ser habilitada**, e o `systemctl is-enabled` a chama de
`static`. Isso é intencional para units que outra coisa puxa.

## Onde eles moram, e qual vence

```
root@vm:~# systemd-analyze unit-paths
/etc/systemd/system.control
/run/systemd/system.control
/run/systemd/transient
/run/systemd/generator.early
/etc/systemd/system
/etc/systemd/system.attached
/run/systemd/system
/run/systemd/system.attached
/run/systemd/generator
/usr/local/lib/systemd/system
/usr/lib/systemd/system
/run/systemd/generator.late
```

**Aquela lista está em ordem de prioridade, da maior para a menor.** Três das entradas importam
para você:

| | |
|---|---|
| `/usr/lib/systemd/system` | **a cópia do pacote.** Uma atualização sobrescreve |
| `/usr/local/lib/systemd/system` | software que você instalou na mão — o `/usr/local` da seção 02 da aula 3 |
| `/etc/systemd/system` | **a sua.** Prioridade maior, e nada sobrescreve |

Então um arquivo que você põe em `/etc/systemd/system/nginx.service` substitui completamente o do
pacote, e sobrevive a atualizações. Esse é o mecanismo, e ele tem uma armadilha: **a sua cópia deixa
de receber as melhorias do pacote**, em silêncio, enquanto existir. Uma correção que o upstream faz
na unit é uma correção que você não recebe.

## O `systemctl edit` é a resposta melhor

```
sudo systemctl edit nginx
```

Ele abre um arquivo vazio e grava o que você digitar em
`/etc/systemd/system/nginx.service.d/override.conf` — um **drop-in**. Esses são mesclados por cima
da unit do pacote em vez de substituí-la, então você muda uma linha e herda todas as outras:

```
[Service]
Restart=always
RestartSec=10
```

Quatro linhas em vez de quarenta, e a unit do pacote continua se atualizando por baixo.

O `systemctl edit --full` te dá o arquivo inteiro para sobrepor, quando um drop-in não serve. E o
`systemctl edit` roda o `daemon-reload` por você depois, que é o passo que a seção 09 disse que as
pessoas esquecem.

O `systemctl cat nginx` imprime a unit e cada drop-in aplicado a ela, em ordem — que é como se
descobre o que outra pessoa fez numa máquina.

## Confira antes de iniciar

Este é o comando da demonstração no fim da aula, e ele roda sobre um **arquivo** e não sobre um
sistema em execução:

```
root@vm:~# systemd-analyze verify /etc/systemd/system/broken.service
/etc/systemd/system/broken.service:2: Unknown key name 'Descriptoin' in section 'Unit', ignoring.
/etc/systemd/system/broken.service:8: Failed to parse service restart specifier, ignoring: maybe
Binding to IPv6 address not available since kernel does not support IPv6.
broken.service: Command /usr/local/bin/does-not-exist.sh is not executable: No such file or directory
root@vm:~# echo $?
1
```

Ignore a linha do IPv6 — é o kernel desta máquina, não a sua unit, e ela aparece verifique você o
que verificar. As outras três são os achados, e **leia a última palavra das duas primeiras:
`ignoring`.**

Um nome de chave escrito errado não é um erro. O systemd descarta a linha e segue, então um serviço
com `Descriptoin=` não tem descrição e não tem reclamação, e um serviço com `Restart=maybe` não
reinicia e nunca avisou. **Esse silêncio é o bug característico do systemd**, e o `verify` é a única
coisa que vai te contar.

O terceiro achado teria falhado alto no start. É o menos perigoso dos três e o único que a maioria
das pessoas chega a perceber.

Num arquivo válido o mesmo comando não tem nada a dizer, que é o silêncio-é-sucesso da aula 1
chegando num lugar novo:

```
root@vm:~# systemd-analyze verify /etc/systemd/system/hello.service
Binding to IPv6 address not available since kernel does not support IPv6.
root@vm:~# echo $?
0
```

A linha solitária é o mesmo ruído da máquina, e o código de saída é `0`. **Essa é a resposta** — e é
por isso que um script confere o `$?` em vez de conferir se algo foi impresso.
