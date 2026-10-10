---
title: O seu laboratório
version: 1
---

Nada neste curso roda numa máquina nossa. **Você monta uma máquina Linux com Docker Engine e Compose,
e todo comando de toda aula é digitado nela.** As transcrições das aulas foram gravadas numa assim:
Ubuntu 24.04, Docker Engine 29 dos pacotes do próprio Docker, um usuário chamado `ana` e uma máquina
chamada `vm`. O seu prompt vai trazer os seus nomes. As respostas serão as mesmas, tirando os ids
que o Docker inventa, os horários e os tempos.

Este curso pede mais da máquina do que `docker` pedia. Um broker de mensagens, dois ou três bancos de
dados e um motor de busca aparecem ao mesmo tempo em algumas aulas, e Kafka e OpenSearch rodam na
máquina virtual Java, que ocupa memória antes de fazer qualquer coisa.

Há três jeitos de conseguir essa máquina. Escolha a máquina virtual, a não ser que tenha um motivo
para não escolher.

| | o que é | o que custa |
| --- | --- | --- |
| **uma máquina virtual com Multipass** (recomendado) | a ferramenta da Canonical que cria uma VM Ubuntu 24.04 com um comando, no Windows, no macOS ou no Linux, com o Docker Engine instalado dentro | 4 processadores, 8 GB de memória e 40 GB de disco enquanto roda; um computador com 16 GB de memória roda com folga ao lado de um navegador |
| instalado | Docker Desktop no Windows ou no macOS, ou o Docker Engine direto num computador que já roda Linux | o Desktop roda uma VM Linux própria, dimensionada nas configurações, que precisa dos mesmos 8 GB; o Engine no computador do dia a dia deixa nele cada contêiner que este curso iniciar |
| online | um GitHub Codespace, ou o Play with Docker do próprio Docker, no navegador | nada no seu computador; uma cota mensal de horas grátis, ou uma sessão apagada depois de quatro horas, que a empresa que oferece decide e pode mudar |

**A máquina virtual tem o mesmo formato daquela de onde vieram as transcrições**, então, quando a sua
saída diferir da aula, a diferença vale a leitura. E perder a máquina não custa nada: uma aula que
enche o disco ou deixa vinte contêineres para trás é uma aula que você pode repetir numa máquina nova.

**Instalado funciona em todas as aulas.** Nesse caso a máquina é a VM do Docker Desktop, e você a
dimensiona nas configurações do Desktop, em *Resources*: 4 processadores e 8 GB. Se o seu computador
tem 8 GB no total, dê 6 à VM e feche o navegador enquanto as aulas 6, 10 e 17 rodam; são as que
sobem os brokers na JVM e o motor de busca.

**Online aparece aqui para você saber que existe.** O menor Codespace tem 2 processadores e 8 GB, e a
cota grátis de uma conta pessoal, como o GitHub publica, é de 120 horas-núcleo por mês: 60 horas
dessa máquina. Uma sessão do Play with Docker é apagada depois de quatro horas. Nenhuma aula aqui
depende de uma cota grátis que outra pessoa pode mudar.

## Com o Multipass

Se você seguiu a aula 5 de `docker`, já tem uma VM chamada `vm`. Crie uma segunda, maior, para este
curso, de modo que uma possa ser jogada fora sem a outra. Instale o Multipass pelo site da
Canonical e depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name arch --cpus 4 --memory 8G --disk 40G
multipass shell arch
```

**Esses dois comandos não foram executados para este curso**, porque a máquina onde ele foi gravado é
ela mesma uma máquina virtual e não consegue iniciar outra. O primeiro cria a VM e o segundo abre um
shell dentro dela, como o usuário `ubuntu`. Tudo daqui em diante acontece nesse shell.

## Docker Engine e Compose

Dentro da VM, instale o Docker Engine pelo repositório do próprio Docker. São os comandos das
instruções de instalação do Docker para Ubuntu, os mesmos que a aula 5 de `docker` explicou linha a
linha. Também não foram executados aqui, porque o laboratório já tinha o resultado; confira com a
documentação do Docker antes de rodar, porque os detalhes mudam:

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

A última linha coloca você no grupo `docker`, para que `docker` funcione sem `sudo`. **Ela vale a
partir do próximo login**: saia do shell com `exit` e rode `multipass shell arch` de novo.

## As primeiras verificações

Três comandos dizem se a máquina está pronta. Os dois primeiros dão as versões; o terceiro baixa uma
imagem pequena e roda um programa nela, o que prova de uma vez o engine, a rede até o registro e a
sua permissão no socket:

```
ana@vm:~$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
ana@vm:~$ docker compose version
Docker Compose version v5.6.0
ana@vm:~$ docker run --rm alpine:3.22 echo hello from a container
Unable to find image 'alpine:3.22' locally
3.22: Pulling from library/alpine
53f8f5e03afd: Pulling fs layer
53f8f5e03afd: Download complete
53f8f5e03afd: Pull complete
b2e1ce860133: Download complete
0629b44bdb87: Download complete
Digest: sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8
Status: Downloaded newer image for alpine:3.22
hello from a container
```

As suas versões podem ser mais novas, e tudo bem. O que importa é que `docker compose`, com espaço,
responda: é o plugin Compose que as aulas usam. O antigo `docker-compose`, com hífen, é outro
programa e não é usado aqui.

**Cada aula trabalha num diretório próprio dentro de `~/lab`**, que a aula nomeia. Crie o diretório
pai agora:

```sh
mkdir -p ~/lab
```

Cada aula termina parando o que iniciou, com `docker compose down -v` no seu diretório. O `-v`
remove também os volumes da aula, e é isso que você quer: a aula seguinte começa do zero e constrói
o que precisa.
