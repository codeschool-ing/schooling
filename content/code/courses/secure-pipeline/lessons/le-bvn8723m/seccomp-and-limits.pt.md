---
title: O filtro de chamadas de sistema, e limites de memória e de processos
version: 1
---

Mais dois controles são sobre o kernel, e não sobre os arquivos. **O seccomp filtra quais chamadas de
sistema um processo pode fazer; os limites de recursos põem teto em quanta memória e quantos
processos ele pode usar.** O primeiro vem ligado por padrão e o segundo não, o contrário do que a
maioria imagina.

### O seccomp já está ligado

Todo processo conversa com o kernel por chamadas de sistema, pouco mais de trezentas no Linux, e um
serviço web usa algumas dezenas. O Docker inicia todo contêiner com um filtro, o perfil seccomp
padrão, que recusa uma lista de chamadas de que um contêiner comum não precisa: carregar módulos do
kernel, reiniciar a máquina, mudar o relógio, gerenciar keyrings do kernel e criar alguns tipos de
namespace. O `Seccomp: 2` em todos os status desta aula era esse filtro, em modo de filtragem:

```
ana@vm:~/linkbox$ docker info --format "{{.SecurityOptions}}"
[name=seccomp,profile=builtin]
ana@vm:~/linkbox$ docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "import os; os.unshare(os.CLONE_NEWUSER); print('in a new user namespace')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import os; os.unshare(os.CLONE_NEWUSER); print('in a new user namespace')
               ~~~~~~~~~~^^^^^^^^^^^^^^^^^^
PermissionError: [Errno 1] Operation not permitted
ana@vm:~/linkbox$ docker run --rm --user 0 --security-opt seccomp=unconfined --entrypoint python3 linkbox:dev -c "import os; os.unshare(os.CLONE_NEWUSER); print('in a new user namespace')"
in a new user namespace
```

A primeira linha diz que este daemon aplica o perfil embutido. As duas execuções pedem a mesma coisa,
um user namespace novo, como root e com as capabilities padrão. **Com o perfil padrão o kernel
responde `Operation not permitted`; sem o filtro, a mesma chamada funciona.** Nada mais mudou entre os
dois comandos, então a recusa foi do filtro. User namespaces são um recurso legítimo do kernel, e
também são o ponto de onde boa parte dos bugs de escalada de privilégio do kernel foi alcançável, e
por isso o perfil padrão só deixa criar um a um processo que já tenha `CAP_SYS_ADMIN`.

O `seccomp=unconfined` aparece aqui só para mostrar o que o filtro faz. **Ele não tem lugar em nenhum
script que inicie um contêiner de verdade.** Quando uma aplicação precisa de fato de uma chamada que
o padrão recusa, o remédio é um perfil próprio que libere essa chamada e nada mais; a documentação do
Docker descreve o formato, e o Kubernetes aceita os mesmos arquivos, e por isso o manifesto da aula
10 nomeia o perfil explicitamente em vez de confiar num padrão.

A máquina da gravação roda sem AppArmor, então o daemon não lista perfil de AppArmor. Num Ubuntu com
AppArmor ligado, o Docker aplica um segundo perfil padrão, `docker-default`, que restringe acesso a
arquivos e montagens com o mesmo espírito, e o `docker info` o lista ao lado do seccomp.

### Memória

Um contêiner sem limite de memória pode usar toda a memória da máquina, e quando ela acaba o OOM
killer do kernel escolhe uma vítima que pode muito bem ser outro serviço. Um limite transforma isso
numa falha contida: o contêiner que passa da própria cota é o que morre. Peça 300 MB dentro de um
limite de 128 MB:

```
ana@vm:~/linkbox$ docker run --name hog --memory 128m --memory-swap 128m --entrypoint python3 linkbox:dev -c "b = bytearray(300 * 1024 * 1024)"; echo "exit $?"
exit 137
ana@vm:~/linkbox$ docker inspect --format "{{.State.OOMKilled}}" hog
true
ana@vm:~/linkbox$ docker rm hog
hog
```

**O status 137 é 128 mais 9, o processo morto com `SIGKILL`, e o Docker registra o motivo:
`OOMKilled` é verdadeiro.** `--memory-swap` igual a `--memory` quer dizer sem swap por cima do
limite, então o limite é o limite. Um vazamento no linkbox, ou uma requisição que o faça carregar
muito mais do que deveria, agora custa o linkbox e mais nada no host.

### Processos

Um contêiner sem limite de processos também pode iniciar processos ou threads até encher a tabela do
kernel, e aí nada na máquina consegue iniciar um: nem o shell de quem está investigando, nem o worker
da próxima requisição. O `--pids-limit` põe teto na contagem do contêiner. Para ver funcionar, um
programa pequeno que inicia threads até uma ser recusada. **Rode só com um limite em vigor.** Salve
como `~/threads.py`:

```python
# Start threads that sleep, one after another, until the system refuses one.
# Run it only in a container with --pids-limit: on a machine with no limit it
# stops at whatever the kernel allows, which is a great many.
import threading
import time

started = 0
try:
    while True:
        threading.Thread(target=time.sleep, args=(5,), daemon=True).start()
        started += 1
except RuntimeError as error:
    print(f"{started} threads started, then: {error}")
```

A imagem não tem cópia dele, e não precisa: `python3 -` lê o programa da entrada padrão.

```
ana@vm:~/linkbox$ docker run --rm -i --pids-limit 32 --entrypoint python3 linkbox:dev - < ~/threads.py
31 threads started, then: can't start new thread
```

**31 threads mais a principal dão 32, o limite**, e a 33ª foi recusada com um erro que o Python
conseguiu capturar. O programa relatou e saiu, e a máquina nem percebeu.

### Limites para o linkbox

O que definir vem do que o serviço usa, medido com folga, e não de um palpite. Rode o linkbox com
todos os controles desta aula e os dois limites, e pergunte ao Docker quanto ele usa:

```
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 --cap-drop ALL --security-opt no-new-privileges --memory 256m --pids-limit 64 -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
ecdbc2c547e4389ca0d4894f4b0895f02aaf2d2278c333bb38f7c8bf5d8738ec
ana@vm:~/linkbox$ docker stats --no-stream --format "{{.Name}}  memory {{.MemUsage}}  pids {{.PIDs}}" linkbox
linkbox  memory 39.54MiB / 256MiB  pids 2
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

**39 MiB de 256 e dois processos**, o master do gunicorn e o seu único worker. 256 MiB deixam espaço
para tráfego e para as primeiras horas de um vazamento; 64 processos deixam espaço para mais workers.
Um limite muito acima do uso protege o host e diz pouco sobre o serviço; um limite no uso de hoje
falha na primeira tarde movimentada. A execução de staging do pipeline, na próxima seção, deixa os
dois de fora, porque vive um minuto e roda um scan. A aula 10 os define onde importam, no Deployment
que roda o linkbox de verdade, e ali valem as regras de requests e limits da aula 19 de
`kubernetes`.
