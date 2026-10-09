---
title: Três máquinas para configurar
version: 1
---

O Ansible precisa de máquinas que rodam, e o moto não tem nenhuma: ele emula a API da AWS e não
inicia nada. Então, nesta aula, os servidores da loja são **três contêineres Docker no seu
computador**, `web1`, `web2` e `db1`, cada um um Ubuntu 24.04 com um servidor SSH, Python e um
usuário `deploy` que pode usar `sudo`. É tudo o que o Ansible pede de uma máquina, e é o que um
servidor novo na nuvem também lhe dá. Os pacotes dentro deles vêm do repositório real do Ubuntu, e o
nginx dentro deles serve páginas de verdade.

É aqui que a máquina virtual que a aula 1 recomenda compensa. Dentro de uma VM Linux, ou no próprio
Linux, o endereço de um contêiner é alcançável do seu shell. Com o Docker Desktop no macOS ou no
Windows não é, porque os contêineres vivem numa VM escondida do próprio Docker, e as conexões SSH
desta aula não teriam para onde ir.

## Instalando o Docker e o Ansible

O Docker pelo pacote do próprio Ubuntu, e o Ansible com o `pipx`, que dá a um programa Python um
ambiente só dele, como o `~/iac-venv` faz para o moto:

```sh
sudo apt-get install -y docker.io pipx
sudo usermod -aG docker $USER
pipx ensurepath
pipx install ansible-core==2.21.4
```

Depois **saia da sessão e entre de novo**, ou feche o terminal da VM e abra outro. As duas linhas do
meio mudam algo que a sua sessão atual leu quando começou: o `usermod` põe você no grupo que pode
falar com o Docker, e o `ensurepath` põe `~/.local/bin`, onde o `pipx` instala, no seu `PATH`. Antes
de sair da sessão, é isto que o Docker diz a quem não está no grupo dele:

```
ana@laptop:~$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

## As máquinas

Dois arquivos, num diretório só deles. O primeiro, `~/hosts/Dockerfile`, descreve uma máquina:

```dockerfile
# ~/hosts/Dockerfile: an Ubuntu 24.04 server with sshd, Python 3 and a user
# `deploy` who may use sudo without a password, which is what Ansible needs.
FROM ubuntu:24.04
RUN apt-get update -q && apt-get install -yq openssh-server python3 sudo && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash deploy && echo 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deploy \
 && mkdir -p /run/sshd /home/deploy/.ssh && chown deploy: /home/deploy/.ssh
CMD ["/usr/sbin/sshd", "-D", "-e"]
```

O segundo, `~/hosts/up.sh`, constrói essa imagem e inicia três máquinas a partir dela, cada uma num
endereço fixo de uma rede Docker só delas, com a sua chave SSH autorizada para o `deploy`:

```sh
#!/bin/sh
# ~/hosts/up.sh: web1, web2 and db1 for lesson 18, as Docker containers.
# Run it again at any time: it throws the old machines away and starts new ones.
set -e
cd ~/hosts
mkdir -p ~/.ssh && chmod 700 ~/.ssh
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -q -t ed25519 -N "" -f ~/.ssh/id_ed25519
docker build -q -t iac-host . >/dev/null
docker network inspect iac >/dev/null 2>&1 ||
  docker network create --subnet 172.30.0.0/24 iac >/dev/null
for h in web1:172.30.0.11 web2:172.30.0.12 db1:172.30.0.21; do
  name=${h%%:*} addr=${h#*:}
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run -d --name "$name" --hostname "$name" --network iac --ip "$addr" iac-host >/dev/null
  docker cp ~/.ssh/id_ed25519.pub "$name:/home/deploy/.ssh/authorized_keys"
  docker exec "$name" chown deploy: /home/deploy/.ssh/authorized_keys
  grep -q " $name\$" /etc/hosts || echo "$addr $name" | sudo tee -a /etc/hosts >/dev/null
  echo "$name is $addr"
done
```

Três coisas nele valem uma frase. **A chave** só é criada se você não tiver nenhuma, e não tem frase
secreta, o que é aceitável para máquinas que existem no seu computador por uma tarde e para mais
nada. **Os nomes** vão para o `/etc/hosts`, e é por isso que o script pede `sudo` uma vez: esse
arquivo é como `ssh web1` encontra `172.30.0.11` sem um servidor DNS. E **rodá-lo de novo** lhe dá
três máquinas novas sem nada instalado, que é como esta aula foi gravada: as transcrições dela partem
de máquinas que este script tinha acabado de criar.

```
ana@laptop:~$ sh ~/hosts/up.sh
web1 is 172.30.0.11
web2 is 172.30.0.12
db1 is 172.30.0.21
ana@laptop:~$ docker ps --filter network=iac --format '{{.Names}}  {{.Image}}  {{.Status}}'
db1  iac-host  Up Less than a second
web2  iac-host  Up Less than a second
web1  iac-host  Up 1 second
```

A primeira execução passa a maior parte do tempo construindo a imagem, porque o `apt-get` roda dentro
da construção; as seguintes reaproveitam a imagem. Quando terminar a aula, `docker rm -f web1 web2 db1`
remove as máquinas. O que fica é a imagem `iac-host`, a rede `iac`, a sua chave e as três linhas no
`/etc/hosts`, e a aula 20 usa o Docker de novo.
