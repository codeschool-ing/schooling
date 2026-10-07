---
title: Quando a instalação falha
version: 1
---

Quem desiste de um curso como este costuma desistir aqui, diante de um erro numa máquina que acabou
de montar. Estas são as falhas que acontecem de verdade, mais ou menos na ordem em que você
toparia com elas, com o que cada uma quer dizer. Onde a máquina em que este curso foi gravado
consegue produzir uma, ela aparece como essa máquina a imprimiu.

**A VM não inicia, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte do processador
à virtualização está desligado no firmware do computador. É um ajuste no menu da BIOS ou da UEFI,
em geral em *Advanced* ou *CPU configuration*, e muitos notebooks saem de fábrica com ele desligado.
Nenhum programa liga isso por você. O Docker Desktop no Windows falha no mesmo ajuste, como disse a
seção sobre instalá-lo.

**O `multipass launch` estoura o tempo.** O primeiro lançamento baixa uma imagem do Ubuntu de algumas
centenas de megabytes, e uma conexão lenta leva mais que a espera padrão. O `multipass launch` aceita
`--timeout` em segundos; dê 1800 e deixe terminar.

**O `apt-get` diz que não conseguiu obter uma trava.** O Ubuntu roda as próprias atualizações nos
primeiros minutos depois que a máquina liga, e só um programa por vez pode instalar pacotes. Espere
alguns minutos e rode o comando de novo. Apagar o arquivo de trava é o conselho que você vai achar
na internet, e é assim que um banco de pacotes se corrompe.

**`permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`.**
O motor está rodando e recusou você. Ou o seu usuário não está no grupo `docker`, ou está e você não
entrou de novo desde então; um `id -nG` sem `docker` diz qual dos dois. Saia do shell e abra de novo.
Duas correções que vão lhe oferecer estão ambas erradas: `sudo chmod 666` no socket dá a toda conta
da máquina o que a aula 6 mostra que o grupo vale, e `sudo` antes de todo `docker` deixa arquivos
de root nos seus próprios diretórios.

**`failed to connect to the docker API`.** Não há nada escutando no socket: o motor está parado, ou o
`docker` aponta para outro motor. A seção anterior termina nessa mensagem e no que ela quer dizer;
na VM, `sudo systemctl start docker` inicia o motor.

**`429 Too Many Requests` do Docker Hub.** O Docker Hub limita quantas imagens um endereço pode
baixar sem login, e uma escola, um escritório ou um café dividem um endereço entre todo mundo que
está atrás dele, então o limite chega antes lá do que em casa. O laboratório bateu nele enquanto
esta aula era escrita: o mesmo `docker buildx imagetools inspect` respondeu 429 num minuto e
funcionou no seguinte. Um `docker login` com uma conta grátis do Docker aumenta o limite, esperar
devolve o limite, e um espelho de registry, que a aula 6 mostra na configuração do daemon, manda os
pulls para outro lugar.

**Um programa dentro do container não consegue verificar um certificado.**

```
ana@vm:~$ docker run --rm alpine:3.22 wget -q -O /dev/null https://dl-cdn.alpinelinux.org/alpine/
28DB5418077F0000:error:0A000086:SSL routines:tls_post_process_server_certificate:certificate verify failed:ssl/statem/statem_clnt.c:2124:
ssl_client: SSL_connect
wget: error getting response: Connection reset by peer
```

Esta é a rede do próprio laboratório, e isso é comum no trabalho e na escola: a rede abre as
conexões cifradas, inspeciona e assina de novo com um certificado dela. A máquina foi instruída a
confiar nesse certificado, então o `docker pull` funciona. Um container traz a própria lista de
certificados confiáveis, que não o tem, e recusa, com razão. Tentar o mesmo comando em outra rede,
o roteador do celular por exemplo, resolve se a causa é essa. A saída é o certificado da rede, com
quem a administra, acrescentado à imagem. Desligar a verificação (`wget --no-check-certificate`,
`curl -k`) nunca é a saída: aceita quem quer que responda. É por isso que algumas aulas adiante
dizem que um passo que precisa de rede dentro do container não foi rodado aqui, e por isso que o
`shelf` guarda a dependência dentro do projeto.

**`port is already allocated`.**

```
ana@vm:~$ docker run -d --name one -p 127.0.0.1:8080:8080 alpine:3.22 sleep 600
c255de10585a3fc1fb896a68b1e272ff0ee8b455892a43b2fed4d6eb33d4338a
ana@vm:~$ docker run -d --name two -p 127.0.0.1:8080:8080 alpine:3.22 sleep 600
6a5b8277272753750a73b1f9ac64f08ad2717be39ec408a4b9f1659f0e71cef4
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint two (5d0ab47a76029ff0445b66c2bd7e330c699bf22355a714947e01d1d6b444a4ba): Bind for 127.0.0.1:8080 failed: port is already allocated

Run 'docker run --help' for more information
ana@vm:~$ docker ps -a --format "{{.Names}}  {{.Status}}  {{.Ports}}"
two  Created  
one  Up Less than a second  127.0.0.1:8080->8080/tcp
ana@vm:~$ docker rm -f one two
one
two
```

Só uma coisa pode ocupar um endereço e uma porta, e aqui um container de antes ocupa. O `docker ps`
diz qual. Repare no id impresso antes do erro: **o segundo container foi criado mesmo assim**, e
fica em `Created` com o nome tomado, então rodar o mesmo comando de novo falha no nome. O `docker rm`
libera os dois. Quando o `docker ps` não mostra nada na porta, quem a ocupa é um programa fora do
Docker, e a aula 17 mostra como achá-lo com o `ss`.

**`no space left on device`.** Imagens, containers parados e o cache de build se somam, e o curso
baixa cerca de 4,5 GB de imagens antes de contar o que você constrói. O `docker system df` diz para
onde foi o espaço, a aula 22 mostra como devolvê-lo, e `multipass stop vm` seguido de
`multipass set local.vm.disk=40G` dá à VM um disco maior.

**E quando nada mais funciona**, apague a máquina e monte de novo: `multipass delete --purge vm`,
depois os comandos da primeira seção. Parece desistir. É o que profissionais fazem com uma máquina
cujo estado ninguém mais sabe explicar, e é por isso que esta aula monta tudo com comandos, e não
com ajustes clicados uma vez. Copie antes o que quiser guardar; da aula 11 em diante, isso é o
`~/shelf`.
