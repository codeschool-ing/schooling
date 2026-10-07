---
title: Para onde vão os logs
version: 1
---

**A saída padrão e a saída de erro de um container são o log dele, e o daemon as escreve num arquivo
no host.** O `docker logs` lê esse arquivo de volta. Qual arquivo, e se ele algum dia para de
crescer, quem decide é o **driver de log**:

```
ana@vm:~/shelf$ docker info --format "{{.LoggingDriver}}"
json-file
ana@vm:~/shelf$ docker run -d --name chatty alpine:3.22 yes "one more line of log"
919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963
ana@vm:~/shelf$ docker logs --tail 2 chatty
one more line of log
one more line of log
ana@vm:~/shelf$ docker inspect chatty --format "{{.LogPath}}"
/var/lib/docker/containers/919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963/919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963-json.log
ana@vm:~/shelf$ sudo du -h "$(docker inspect chatty --format "{{.LogPath}}")"
183M	/var/lib/docker/containers/919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963/919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963-json.log
```

O `json-file` é o padrão: um objeto JSON por linha, num arquivo em `/var/lib/docker/containers/`.
**E por padrão ele não tem limite de tamanho.** O container acima é o `yes`, um programa que imprime a
mesma linha o mais rápido que consegue, fazendo o papel de um serviço preso registrando um erro em
laço. Nos três segundos antes de a Ana olhar, ele escreveu **183 MB**. Nesse ritmo, um dia enche
qualquer disco, e com o disco vão todos os outros containers da máquina, e o próprio daemon.

## Rotação, por container

Duas opções de log põem um teto: `max-size` para um arquivo, e `max-file` para quantos são mantidos:

```
ana@vm:~/shelf$ docker run -d --name chatty --log-opt max-size=1m --log-opt max-file=3 alpine:3.22 yes "one more line of log"
5c4dcd7687352387b3bff6cfeabe334c91ba3882b4b638c0110f436586851363
ana@vm:~/shelf$ sudo ls -l "$(dirname "$(docker inspect chatty --format "{{.LogPath}}")")" | grep json.log
-rw-r----- 1 root root  993809 Oct  6 15:05 5c4dcd7687352387b3bff6cfeabe334c91ba3882b4b638c0110f436586851363-json.log
-rw-r----- 1 root root 1000082 Oct  6 15:05 5c4dcd7687352387b3bff6cfeabe334c91ba3882b4b638c0110f436586851363-json.log.1
-rw-r----- 1 root root 1000059 Oct  6 15:05 5c4dcd7687352387b3bff6cfeabe334c91ba3882b4b638c0110f436586851363-json.log.2
```

**Três arquivos de cerca de 1 MB, e nada mais, por mais tempo que ele rode.** As linhas mais antigas
são descartadas, e essa é a troca: a rotação protege a máquina, e o que for mais velho do que os
arquivos guardam se perde, a não ser que algo o tenha mandado para outro lugar antes.

## Rotação, para todos os containers

Escrever `--log-opt` em todo `docker run` é uma promessa que alguém vai esquecer. O daemon aceita um
padrão em `/etc/docker/daemon.json`, o mesmo arquivo que a aula 6 usou para o espelho do registry:

```json
{
  "registry-mirrors": ["https://mirror.gcr.io"],
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

**Este arquivo foi escrito no laboratório e não foi instalado**, porque aplicá-lo exige reiniciar o
daemon, e o daemon do laboratório fica como a aula 6 o deixou. Duas coisas valem para ele segundo a
documentação do Docker: a mudança vale depois de reiniciar o daemon, e **só para containers criados
depois disso**; os que já existem mantêm as opções com que foram criados. O driver `local` que ele
escolhe guarda os logs num formato compacto e os rotaciona por padrão, e o `docker logs` o lê do mesmo
jeito.

## Em outro lugar que não a máquina

O arquivo no host serve para uma máquina e para o `docker logs`. Uma frota manda os logs para um lugar
só, onde dá para procurá-los depois que o container sumiu: outros drivers, como `syslog`, `journald`,
`gcplogs` e `awslogs`, escrevem direto num lugar assim, ou um agente em cada host lê os arquivos e os
encaminha. O programa não muda em nenhum dos casos, **e é por isso que um programa em container
registra na saída padrão e nunca num arquivo próprio**: para onde as linhas vão é decisão da
plataforma, tomada fora da imagem.
