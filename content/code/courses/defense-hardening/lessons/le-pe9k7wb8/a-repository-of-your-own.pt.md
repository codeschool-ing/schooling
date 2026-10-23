---
title: Um repositório próprio
version: 1
---

**Máquinas que instalam atualizações da internet decidem cada uma por si quando e a partir do quê.**
Um escritório que quer decidir no lugar delas aponta as máquinas para um repositório que ele controla:
um espelho do repositório da distribuição, atualizado na agenda dele, mais os pacotes próprios. Aí "que
versão do nginx o portal pode rodar" tem uma resposta só, guardada num lugar só, e uma atualização
quebrada pode ser parada antes de chegar a alguém.

## Duas versões de um pacote

Um pacote Debian é um diretório com um arquivo `DEBIAN/control` que o descreve e os arquivos a
instalar, empacotado pelo `dpkg-deb`. No `admin`, como você mesmo, monte duas versões do
`jatoba-health`:

```
ana@admin:~$ mkdir -p ~/repo && for v in 1.0 1.1; do
  d=~/pkg/jatoba-health_$v
  mkdir -p $d/DEBIAN $d/usr/bin
  printf 'Package: jatoba-health\nVersion: %s\nArchitecture: all\nMaintainer: Jatoba IT <ti@jatoba.example>\nDepends: curl\nDescription: checks that the client portal answers\n' $v > $d/DEBIAN/control
  printf '#!/bin/sh\necho "jatoba-health %s"\ncurl -s -o /dev/null -w "portal %%{http_code}\\n" http://web/healthz\n' $v > $d/usr/bin/jatoba-health
  chmod 755 $d/usr/bin/jatoba-health
  dpkg-deb --root-owner-group --build $d ~/repo/
done
dpkg-deb: building package 'jatoba-health' in '/home/ana/repo//jatoba-health_1.0_all.deb'.
dpkg-deb: building package 'jatoba-health' in '/home/ana/repo//jatoba-health_1.1_all.deb'.
ana@admin:~$ cat ~/pkg/jatoba-health_1.1/usr/bin/jatoba-health
#!/bin/sh
echo "jatoba-health 1.1"
curl -s -o /dev/null -w "portal %{http_code}\n" http://web/healthz
```

O laço escreve o mesmo pacote duas vezes com uma linha `Version:` diferente. Na vida real a segunda
traria uma correção; aqui **a única diferença é a versão**, porque o que esta aula exercita é entregar
uma atualização, e uma mudança no programa só distrairia disso. O programa confere o portal de onde
quer que rode e imprime antes a própria versão, então cada transcrito abaixo diz qual rodou.

## Um índice e um servidor

O apt não navega por diretórios. Ele lê um índice, `Packages`, que lista cada pacote com versão e
checksum, e um arquivo `Release` que descreve o repositório. O `apt-ftparchive` escreve os dois; a
`Origin` e o `Label` que ele recebe importam depois, quando as atualizações automáticas decidem de que
repositórios podem instalar:

```
ana@admin:~$ cd ~/repo && apt-ftparchive packages . > Packages && apt-ftparchive -o APT::FTPArchive::Release::Origin=Jatoba -o APT::FTPArchive::Release::Label=Jatoba release . > Release && ls
Packages
Release
jatoba-health_1.0_all.deb
jatoba-health_1.1_all.deb
root@admin:~# systemd-run --unit=repo --uid=ana --working-directory=/home/ana/repo python3 -m http.server 8000; sleep 1; systemctl is-active repo
Running as unit: repo.service; invocation ID: 0cd8064dde7c4842979c2c1a02f8ab46
active
```

O servidor web embutido do Python, iniciado como serviço temporário com o `systemd-run`, torna o
diretório alcançável em `http://admin:8000/`. Um espelho de verdade é servido por nginx ou Apache,
muitas vezes com uma ferramenta como `aptly` ou `reprepro` mantendo-o, mas o que o apt vê é o mesmo.

## Apontando uma máquina para ele

No `desk`, como root, ponha de lado o repositório da distribuição, que o laboratório nem alcança, e
acrescente o repositório do escritório:

```
root@desk:~# mv /etc/apt/sources.list /root/sources.list.archive; echo "deb [trusted=yes] http://admin:8000 ./" > /etc/apt/sources.list.d/jatoba.list
root@desk:~# apt-get update 2>&1 | tail -2; apt-cache policy jatoba-health
Fetched 1861 B in 0s (84.0 kB/s)
Reading package lists...
jatoba-health:
  Installed: (none)
  Candidate: 1.1
  Version table:
     1.1 500
        500 http://admin:8000 ./ Packages
     1.0 500
        500 http://admin:8000 ./ Packages
```

O `apt-cache policy` lista as duas versões e oferece a `1.1` como candidata, a mais alta disponível. O
`500` ao lado de cada uma é a prioridade dela, igual para as duas, então a versão mais alta vence.

**`[trusted=yes]` é um atalho do laboratório e mais nada.** Ele manda o apt instalar pacotes deste
repositório sem conferir assinatura, o que quer dizer que qualquer um que consiga responder por
`admin:8000` pode colocar qualquer programa na máquina como root. Um repositório de verdade assina o
arquivo `Release` com uma chave, e cada máquina cita a chave em que confia com `signed-by=` na mesma
linha. As imagens do laboratório não têm `gpg` para assinar, e o texto diz isso para que a linha nunca
seja copiada: **assinaturas de pacotes são o controle que torna um repositório seguro de usar**, e
desligá-las é o enfraquecimento contra o qual este curso vive alertando.
