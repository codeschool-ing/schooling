---
title: Quando a instalação falha
version: 1
---

Quase todo mundo que desiste de um curso como este desiste no primeiro dia, num erro sobre uma
máquina que acabou de montar. Estas são as falhas que acontecem de verdade, mais ou menos na ordem
em que você as encontraria. Onde a máquina do laboratório conseguiu produzir uma, ela aparece como
a máquina imprimiu.

**A VM não inicia, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte do processador
à virtualização está desligado no firmware do computador. É uma opção no menu da BIOS ou da UEFI,
em geral em *Advanced* ou *CPU configuration*, e nenhum programa consegue ligá-la por você. O Docker
Desktop no Windows falha na mesma opção.

**`multipass launch` estoura o tempo.** O primeiro launch baixa uma imagem do Ubuntu de algumas
centenas de megabytes, e uma conexão lenta demora mais do que a espera padrão. Acrescente
`--timeout 1800` e deixe terminar.

**`multipass launch` diz que não há memória suficiente.** Os 8 GB precisam estar livres quando a VM
inicia, não apenas instalados. Feche o que puder, ou peça `--memory 6G`; as aulas que mais pedem
avisam no começo, e parar os contêineres da aula anterior em geral basta.

**`apt-get` diz que não conseguiu obter um lock.** O Ubuntu roda as próprias atualizações nos
primeiros minutos depois do boot, e só um programa por vez pode instalar pacotes. Espere alguns
minutos e rode o comando de novo. Apagar o arquivo de lock é o conselho que você vai achar na
internet, e é assim que um banco de pacotes se corrompe.

**`permission denied while trying to connect to the docker API`.** O engine está rodando e recusou
você: ou você não está no grupo `docker`, ou está e não entrou de novo desde então. `id -nG` sem
`docker` na saída diz qual dos dois. Duas correções que vão te oferecer estão erradas: `sudo chmod
666` no socket dá a toda conta da máquina o que ser do grupo significa, que é root, e `sudo` antes
de todo `docker` deixa arquivos do root nos seus próprios diretórios.

**Uma porta já está em uso.** Toda aula publica os seus serviços no loopback da máquina, e um
contêiner que ficou rodando de uma aula anterior ainda segura a porta dele. É assim que isso
aparece, com a loja desta aula iniciada uma segunda vez com outro nome de projeto:

```
ana@vm:~/lab/monolith$ docker compose -p second up -d --quiet-build
 Volume second_data Creating 
 Network second_default Creating 
 Volume second_data Creating 
 Network second_default Creating 
 Volume second_data Created 
 Volume second_data Created 
 Network second_default Created 
 Network second_default Created 
 Container second-shop-1 Creating 
 Container second-shop-1 Created 
 Container second-shop-1 Starting 
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint second-shop-1 (42ea779442c08ba397371a91ecee4a3555a6132ec901591353bbec83b4dbfbbf): Bind for 127.0.0.1:8000 failed: port is already allocated
```

`docker ps` lista o que está rodando e que portas segura; `docker compose down` no diretório da aula
antiga libera as portas.

**Um contêiner para com código de saída 137.** É 128 mais o sinal 9: o kernel matou o processo, quase
sempre porque o contêiner, ou a VM inteira, ficou sem memória. Aqui está a mesma coisa de propósito,
um programa pedindo 200 MB num contêiner com limite de 64:

```
ana@vm:~/lab/monolith$ docker run --name hog --memory 64m python:3.12-slim python -c "b = bytearray(200 * 1024 * 1024)"; echo "exit code $?"
exit code 137
ana@vm:~/lab/monolith$ docker inspect --format "{{.State.OOMKilled}} {{.State.ExitCode}}" hog
true 137
```

`docker inspect` diz `"OOMKilled": true` quando a causa foi o limite do próprio contêiner. Se diz
`false` e o código ainda é 137, quem ficou sem memória foi a VM: dê mais memória a ela ou rode menos
coisas ao mesmo tempo.

**`no space left on device`.** Imagens, cache de build e volumes se acumulam ao longo de vinte aulas.
`docker system df` diz quanto cada um ocupa, e `docker system prune` remove contêineres parados,
redes sem uso e imagens soltas; acrescente `--volumes` só quando nada neles importar, porque isso
apaga dados de vez.

**`429 Too Many Requests` do Docker Hub.** O Docker Hub limita quantas imagens um endereço pode baixar
sem login, e uma escola, um escritório ou um café dividem um endereço entre todo mundo atrás dele.
Espere e tente de novo, ou crie uma conta gratuita no Docker Hub e rode `docker login`, que aumenta o
limite para você.

**Num Mac com Apple silicon**, o Multipass cria uma máquina `arm64`. Toda imagem que este curso usa é
publicada para `arm64` além de `amd64`, então os comandos funcionam sem mudança; só os digests das
imagens diferem das transcrições.
