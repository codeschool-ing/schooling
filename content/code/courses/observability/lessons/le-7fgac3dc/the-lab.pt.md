---
title: O seu laboratório, montado por você
version: 2
---

Todo comando deste curso foi executado, e toda linha de saída é o que ele imprimiu. **Você monta o
mesmo laboratório no seu próprio computador, e todo comando de toda aula é digitado lá.** Nada neste
curso roda numa máquina hospedada por nós.

O laboratório é uma máquina Linux rodando Docker: uma pequena loja online, escrita para o curso, e o
software de código aberto que a vigia, cada um no seu contêiner. As duas próximas seções entregam
todos os arquivos dele. Esta aqui arruma a máquina.

Há três jeitos de ter essa máquina. Escolha a máquina virtual, a não ser que tenha um motivo para não
escolher.

| | o que é | o que custa |
|---|---|---|
| instalado | Docker Engine num computador Linux que você já tem | 4 processadores e 8 GB de memória livres enquanto o laboratório roda, e cerca de 15 GB de disco para as imagens |
| **uma máquina virtual com o Multipass** (recomendado) | a ferramenta da Canonical que cria uma máquina Ubuntu Server 24.04 com um comando, no Windows, no macOS e no Linux | os mesmos 4 processadores e 8 GB, entregues à máquina enquanto ela roda, e um disco de 40 GB que cresce conforme enche |
| online | uma máquina virtual alugada por hora de um provedor de nuvem | dinheiro por cada hora em que ela existe, então ela é apagada no fim de cada sessão |

**O laboratório precisa de quatro processadores e 8 GB de memória**, e é com esse número que se
planeja. Subido e deixado quieto ele usa cerca de 900 MB, mas as aulas rodam clientes simulados
contra ele por muitos minutos seguidos. A aula 9 acrescenta o Elasticsearch e o Graylog, e essa aula
sozinha pede 16 GB; num computador menor as transcrições dela podem ser lidas em vez de
reproduzidas, e a aula diz quais.

**Instalado** é a escolha certa num computador Linux que você possa ceder, ou no que você usa todo
dia se já roda Docker nele: nada aqui instala coisa alguma fora do Docker, e toda porta é publicada
só para o próprio computador. No Windows ou no macOS, o Docker Desktop roda o Linux numa máquina
virtual escondida, só dele. Ele pode muito bem rodar o laboratório inteiro, mas o curso não foi
gravado nele, e quando algo difere você está depurando uma máquina que não consegue ver. O caminho
recomendado evita essa pergunta. **Online** também funciona, e as menores máquinas de toda nuvem são
pequenas demais para este laboratório; uma com quatro processadores e 8 GB custa dinheiro de verdade
por hora, então apague-a quando parar em vez de deixá-la ligada. O curso `cloud`, que este exige, é
onde se ensina a criar uma. Qualquer outro hipervisor também funciona no lugar do Multipass:
VirtualBox, UTM num Mac com Apple silicon, Hyper-V no Windows ou GNOME Boxes no Linux, ao preço de
meia hora de telas de instalação e da imagem do Ubuntu Server 24.04 baixada à mão.

## Com o Multipass

Instale o Multipass pelo site dele e depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name obs --cpus 4 --memory 8G --disk 40G
multipass shell obs
```

**Esses dois comandos não foram executados para este curso**, porque o computador em que ele foi
gravado não consegue rodar um hipervisor; ele é uma máquina Ubuntu 24.04 por si só. O primeiro cria
a máquina virtual e o segundo abre um shell dentro dela, com o usuário `ubuntu`. Tudo daqui em
diante acontece nesse shell.

## O Docker, pelos pacotes do próprio Docker

O repositório do Ubuntu traz um Docker mais antigo com outro nome, então o curso instala o Docker
Engine e o plugin do Compose pelo repositório do Docker, como a documentação do Docker manda, junto
com o `jq`, que as aulas usam para ler JSON:

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl jq
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

A última linha põe você no grupo `docker`, que é o que deixa você falar com o Docker sem `sudo`.
**Ela só vale a partir do seu próximo login**, então saia do shell com `exit` e abra de novo com
`multipass shell obs`. Aí `docker compose version` deve responder com uma versão. Este curso foi
gravado com o Docker Engine 29.8 e o Compose 5.6; um mais novo imprime as mesmas coisas.

## Os nomes nas transcrições

A máquina em que este curso foi gravado se chama `obs`, a usuária dela é `ana`, e o laboratório
fica em `~/shop`, então toda transcrição começa com `ana@obs:~/shop$`. A sua diz `ubuntu@obs` se você
usou o Multipass, ou o seu próprio nome num computador seu. Essa é a única diferença que você deve
ver, fora as partes que mudam a cada execução: datas, durações em milissegundos e os ids aleatórios
que todo trace recebe.
