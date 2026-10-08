---
title: Quando a montagem falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, antes da primeira aula de
verdade, diante de uma mensagem de erro sobre uma máquina que acabou de montar. Estas são as falhas
que de fato acontecem, na ordem em que você as encontraria, com o que cada uma significa. As três
que têm transcrição foram provocadas na máquina em que este curso foi gravado, então as palavras são
as que você vai ver.

**A máquina virtual não sobe, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte do
processador à virtualização está desligado no firmware do computador. É uma opção no menu da BIOS
ou da UEFI, normalmente em *Advanced* ou *CPU configuration*, e vem desligada em muitos notebooks.
Nenhum software consegue ligá-la por você. No Windows, o Hyper-V e o Subsistema do Windows para
Linux também podem ocupá-la, e aí o VirtualBox roda devagar ou não roda.

**O `multipass launch` estoura o tempo.** A primeira execução baixa uma imagem do Ubuntu de algumas
centenas de megabytes, e uma conexão lenta demora mais do que a espera padrão. O `multipass launch`
aceita um `--timeout` em segundos; dê 1800 e deixe terminar.

**O Docker diz permission denied.**

```
ana@obs:~/shop$ docker compose ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

O seu usuário ainda não está no grupo `docker`, ou está e este shell começou antes disso. O
`usermod` da primeira seção só vale a partir do próximo login: `exit`, abra o shell de novo, e `id`
deve listar `docker` entre os seus grupos. Pôr `sudo` na frente de todo comando também funciona, e
aí todo arquivo que o Docker cria em `~/shop` pertence ao root, o que a próxima falha mostra ser um
problema à parte.

**O download para com `429 Too Many Requests`.** O Docker Hub limita quantas imagens um endereço
pode baixar anonimamente em algumas horas, e o primeiro `docker compose up` pede quinze. Aconteceu
enquanto este laboratório era montado, no `prom/node-exporter`. O limite se renova com o tempo:
espere um quarto de hora e rode o mesmo comando de novo, e o Docker guarda o que já baixou. Entrar
com `docker login` aumenta o limite, se você tiver uma conta no Docker; o curso não precisa de uma.

**O build falha enquanto o `pip install` roda.** A imagem da loja baixa os pacotes Python do Python
Package Index enquanto é construída, então a máquina precisa alcançar `pypi.org`. Dentro da máquina,
`curl -sI https://pypi.org/simple/ | head -1` deve responder `HTTP/2 200`. Se não conseguir, a máquina
não tem rota para fora, o que numa máquina virtual costuma significar que a VPN ou o firewall do
computador hospedeiro está no caminho.

**O Grafana sobe, e ninguém consegue entrar.** Esta não diz nada quando acontece:

```
ana@obs:~/shop$ docker compose up -d grafana
 Container shop-grafana-1 Creating 
 Container shop-grafana-1 Created 
 Container shop-grafana-1 Starting 
 Container shop-grafana-1 Started 
ana@obs:~/shop$ ls -ld .grafana-password
drwxr-xr-x 2 root root 4096 Oct  7 10:48 .grafana-password
ana@obs:~/shop$ cat .grafana-password
cat: .grafana-password: Is a directory
```

O `compose.yaml` monta o `.grafana-password` no contêiner do Grafana, e quando esse arquivo não
existe, **o Docker cria um diretório com esse nome no lugar**, do root, e sobe o Grafana mesmo
assim. O Grafana não encontra senha nenhuma ali, e toda aula que lê o arquivo falha no `cat`. O
conserto é remover o contêiner e o diretório, e desta vez escrever o arquivo:

```sh
docker compose rm -sf grafana
sudo rm -r .grafana-password
openssl rand -hex 12 > .grafana-password
docker compose up -d grafana
```

**Um contêiner não sobe porque a porta dele está ocupada.**

```
ana@obs:~/shop$ docker compose up -d grafana
 Container shop-grafana-1 Starting
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint shop-grafana-1 (b1aae8ecb42cfc33c668b625b9db7e0468d653d1655be5a271df7033f1376120): failed to bind host port 127.0.0.1:3000/tcp: address already in use
ana@obs:~/shop$ ss -ltn 'sport = :3000'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5          127.0.0.1:3000      0.0.0.0:*
```

Outra coisa na máquina já escuta em `127.0.0.1:3000`, e o `ss` mostra a porta. Com `sudo` na
frente, `ss -ltnp` mostra também o programa. Costuma ser um servidor de desenvolvimento seu, no
caminho instalado e não numa máquina virtual nova. Pare-o, ou mude o número da esquerda na linha
`ports` desse serviço no `compose.yaml`, e então use o seu número sempre que uma aula digitar o
original.

**Um contêiner fica reiniciando, ou mostra `Exited (137)`.** 137 quer dizer que o processo foi
morto, e numa máquina de laboratório quem mata é quase sempre o kernel, sem memória. `free -h`
mostra o que sobra. Dê mais memória à máquina virtual, ou pare o que mais estiver rodando nela.

**Quando algo não responde**, pergunte ao Docker antes de perguntar ao programa: `docker compose ps`
diz se o contêiner está rodando, e `docker compose logs <serviço>` diz o que ele imprimiu ao subir.
As últimas linhas dizem o motivo quase sempre.

**E quando nada mais funciona**, comece o laboratório de novo do zero com os três comandos do fim da
seção anterior. Se não bastar, apague a máquina e monte de novo: com o Multipass isso é
`multipass delete --purge obs`, depois os comandos da primeira seção e os arquivos das duas
seguintes, cerca de meia hora. Parece desistir. É o que profissionais fazem com uma máquina cujo
estado ninguém consegue mais explicar, e é o motivo de este curso montar tudo a partir de arquivos
que você pode ler.
