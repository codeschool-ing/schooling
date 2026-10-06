---
title: Bind mounts
version: 1
---

**Um bind mount faz um diretório do host aparecer dentro do container, o mesmo diretório, e não uma
cópia.** Uma mudança de qualquer lado é a mudança dos dois lados, na hora. É isso que torna o bind
mount a ferramenta do desenvolvimento, em que você edita no host e o container deve enxergar, e é
também o que o torna fácil de usar errado.

## Os mesmos arquivos, dos dois lados

A Ana cria um pequeno diretório de site, inicia um container com ele montado em `/srv` e depois edita
o arquivo no host com o container rodando:

```
ana@vm:~$ mkdir site && echo "<h1>Opening hours</h1>" > site/index.html
ana@vm:~$ docker run -d --name web -v "$PWD/site":/srv alpine:3.22 sleep 3600
a4069892959733ac5270ac9422d2e9d29cb3f33205e62fff2bdd509a0ae1bd6f
ana@vm:~$ docker exec web cat /srv/index.html
<h1>Opening hours</h1>
ana@vm:~$ echo "<p>Mon-Fri 9-18</p>" >> site/index.html
ana@vm:~$ docker exec web cat /srv/index.html
<h1>Opening hours</h1>
<p>Mon-Fri 9-18</p>
```

O segundo `cat` mostra a linha que ela acrescentou do host, sem reiniciar nada e sem copiar nada. O
caminho antes dos dois-pontos é o do host, e precisa ser absoluto, e é por isso que se escreve
`"$PWD/site"` em vez de `site`.

## De quem é o que o container escreve

Um processo num container escreve arquivos como o próprio usuário, e a aula 1 mostrou que o kernel só
conhece o número. O container da Ana roda como root, então:

```
ana@vm:~$ docker exec web sh -c "echo generated > /srv/report.txt"
ana@vm:~$ ls -l site
total 8
-rw-r--r-- 1 ana  ana  43 Oct  6 13:42 index.html
-rw-rw-rw- 1 root root 10 Oct  6 13:42 report.txt
ana@vm:~$ rm site/report.txt
```

**O `report.txt` pertence ao `root` no host**, no próprio diretório da Ana. Ela conseguiu apagá-lo
aqui porque o diretório é dela, mas não consegue editá-lo, e numa máquina de CI o próximo job rodando
como usuário comum não consegue limpar a área de trabalho. O `--user` roda o processo do container
com os números de usuário e grupo da própria Ana:

```
ana@vm:~$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD/site":/srv alpine:3.22 sh -c "echo generated > /srv/report.txt"
ana@vm:~$ ls -l site
total 8
-rw-r--r-- 1 ana ana 43 Oct  6 13:42 index.html
-rw-r--r-- 1 ana ana 10 Oct  6 13:42 report.txt
```

Agora o arquivo é dela. **Quando um container escreve num bind mount, rode-o como o usuário do host
que é dono do diretório**, ou os arquivos acabam pertencendo ao usuário com que a imagem roda, que é o
root a menos que o conselho da aula 14 tenha sido seguido.

## Uma montagem esconde o que havia ali

Um bind mount é posto por cima do diretório onde cai, e o que a imagem tinha ali fica invisível
enquanto a montagem durar. Montar o site em cima de `/etc` mostra isso de forma escandalosa:

```
ana@vm:~$ docker run --rm -v "$PWD/site":/etc alpine:3.22 ls /etc
hostname
hosts
index.html
report.txt
resolv.conf
```

O `/etc` inteiro do Alpine, os usuários, a configuração, sumiu de vista; o que sobra são os dois
arquivos da Ana e os três arquivos que o Docker sempre põe no próprio `/etc`, o nome de máquina e a
configuração de rede da aula 4. Nada na imagem mudou, e um container sem a montagem enxerga tudo de
novo. A lição é a versão silenciosa da mesma coisa: montar um diretório de código-fonte em cima do
lugar onde um Dockerfile instalou dependências esconde essas dependências, e o programa falha de um
jeito que parece imagem quebrada. A aula 24 esbarra nisso e o contorna.

## Somente leitura quando o container só deve ler

```
ana@vm:~$ docker run --rm -v "$PWD/site":/srv:ro alpine:3.22 sh -c "echo x >> /srv/index.html"
sh: can't create /srv/index.html: Read-only file system
```

O `:ro` no fim deixa a montagem somente leitura dentro do container, seja qual for o usuário do
container. **Use-o sempre que o container não tiver nada que escrever**: arquivos de configuração,
certificados, um diretório de dados de entrada.
