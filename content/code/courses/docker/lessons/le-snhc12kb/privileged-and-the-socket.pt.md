---
title: Duas flags que desfazem tudo
version: 1
---

**Tudo o que este curso disse sobre as paredes de um container deixa de valer com duas coisas: o
`--privileged`, e o socket do Docker montado lá dentro.** As duas aparecem em tutoriais, as duas
funcionam, e vale reconhecê-las de olhada no comando ou no arquivo do Compose de outra pessoa.

## `--privileged`

```
ana@vm:~$ docker run --rm alpine:3.22 sh -c "ls /dev | wc -l; grep CapEff /proc/self/status"
14
CapEff:	00000000a80425fb
ana@vm:~$ docker run --rm --privileged alpine:3.22 sh -c "ls /dev | wc -l; grep CapEff /proc/self/status"
111
CapEff:	000001fffeffffff
```

**De 14 capabilities para 40, todas as que o próprio daemon tem, e de 14 entradas no `/dev` para
111**: os discos do host, os terminais e todos os outros dispositivos. O AppArmor e o seccomp, as outras
duas restrições que o Docker aplica por padrão, também são desligados. O que sobra do container é uma
visão separada de processos e de rede; um processo nele alcança o hardware do host diretamente.

Algumas ferramentas precisam disso de verdade, como uma que roda Docker dentro do Docker. A maioria das
que pedem precisa de uma capability ou de um dispositivo, que o `--cap-add` e o `--device` concedem sem
o resto.

## O socket do Docker

A aula 6 mostrou que quem fala com o `/var/run/docker.sock` controla o daemon, que roda como root, e
que estar no grupo `docker` é, portanto, ser root na máquina. **Montar o socket num container dá esse
mesmo poder ao que rodar nele:**

```
ana@vm:~$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock docker:29.8.2-cli docker ps --format "{{.Names}} {{.Image}}"
sharp_herschel docker:29.8.2-cli
```

**O container listou a si mesmo, porque perguntava ao daemon do host.** A mesma conexão consegue
iniciar containers, com quaisquer flags e quaisquer montagens que o daemon aceite, e o daemon aceita
todas. Um container com o socket é um container que consegue iniciar um privilegiado. Nunca o monte num
serviço exposto à rede, e trate qualquer imagem que o peça com a desconfiança que você teria com um
pedido da senha de root.

## Achando-os num host

Os dois deixam rastros na configuração do container, então um script curto os acha:

```sh
#!/bin/sh
# Lists every running container that holds more than a container should.
docker ps -q | xargs docker inspect --format \
  '{{.Name}} privileged={{.HostConfig.Privileged}} caps={{.HostConfig.CapAdd}}{{range .Mounts}}{{if eq .Source "/var/run/docker.sock"}} DOCKER-SOCKET{{end}}{{end}}'
```

```
ana@vm:~$ docker run -d --name ok shelf:1.0.0 >/dev/null; docker run -d --name risky --privileged -v /var/run/docker.sock:/var/run/docker.sock alpine:3.22 sleep 300 >/dev/null
ana@vm:~$ sh audit.sh
/risky privileged=true caps=[] DOCKER-SOCKET
/ok privileged=false caps=[]
```

**O `risky` é as duas coisas, e o script diz isso numa linha.** Rodado em todo host, por um job agendado
ou por um agente de monitoramento, ele pega o container que alguém iniciou com pressa. Num cluster, a
mesma regra fica na política de admissão (aula 25 do curso `kubernetes`), onde um container assim é
recusado antes de iniciar.
