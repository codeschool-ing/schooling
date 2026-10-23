---
title: Scratch, distroless e os arquivos no meio
version: 1
---

Se 3.19 MB de base é bom, base nenhuma deve ser melhor, e contêineres têm um nome para base
nenhuma: `FROM scratch`, uma imagem que começa sem arquivo algum. Para o `hits` funcionaria, porque
o `hits` não abre nada além do log. **Na maioria dos programas, o scratch tira arquivos que o
programa lê sem que o autor jamais os tenha visto como dependências**: a base de usuários, as
regras de fuso horário, as autoridades certificadoras. O `probe` da seção 02 pede exatamente esses
três, o que faz dele o programa certo para pôr nas duas bases.

## Nenhum shell para entrar

Primeiro, o que falta de propósito na imagem distroless:

```
ana@vm:~/ship$ podman run --rm --network=none --entrypoint sh hits:1; echo $?
Error: runc: runc create failed: unable to start container process: error during container init: exec: "sh": executable file not found in $PATH: OCI runtime attempted to invoke a command that was not found
127
```

O `--entrypoint` troca o programa que a imagem inicia, e não há `sh` para iniciar: **127 é o "comando
não encontrado" do shell, da seção de laboratório da lição 1, devolvido aqui pelo Podman.** Sem
shell não há `ls`, nem `cat`, nem `podman exec -it … sh` para olhar um contêiner rodando. Isso
também quer dizer que quem achar uma brecha no programa não tem shell para rodar. Os arquivos
continuam alcançáveis de fora, e a próxima listagem vem deles. Para os dias em que um shell vale o
risco, o distroless publica variantes `:debug` de cada imagem com um shell BusyBox em
`/busybox/sh`; elas são para um terminal, nunca para produção.

## O mesmo programa em duas bases

O `probe/Containerfile` recebe a base como argumento de build e copia um binário compilado na
máquina, que é o outro jeito de encher uma imagem quando o build já aconteceu:

`probe/Containerfile`:

```dockerfile
# One binary built on the host, on top of whatever BASE names.
ARG BASE=scratch
FROM $BASE
COPY probe /probe
ENTRYPOINT ["/probe"]
```

Um `ARG` antes do `FROM` declara um valor que a linha `FROM` pode usar, com `scratch` como padrão e
`--build-arg` para trocar. O `probe` em `~/ship/probe` é o último build da seção 02, com o cgo
desligado. Construído duas vezes, rodado duas vezes:

```
ana@vm:~/ship/probe$ podman build -q --cap-drop=all -t probe:scratch .
554647b21915ba63f0bfed6bdf56d802bddf8f3c591e116825594448482d3e71
ana@vm:~/ship/probe$ podman build -q --cap-drop=all --build-arg BASE=gcr.io/distroless/static-debian12:nonroot -t probe:distroless .
a404e0e86b59064ec1699b0ba238a34b7199c06b25663328e0a33e4786b9ad9d
ana@vm:~/ship/probe$ podman run --rm --network=none probe:scratch
user:  user: Current requires cgo or $USER set in environment
zone:  unknown time zone America/Sao_Paulo
certs: 0 authorities
ana@vm:~/ship/probe$ podman run --rm --network=none probe:distroless
user:  nonroot 65532 /home/nonroot
zone:  09:00 -03
certs: 150 authorities
ana@vm:~/ship/probe$ podman images --format 'table {{.Repository}} {{.Tag}} {{.Size}}' --filter reference=localhost/probe
REPOSITORY       TAG         SIZE
localhost/probe  distroless  7.71 MB
localhost/probe  scratch     4.52 MB
```

**No scratch, as três perguntas falham, e a terceira falha sem erro.** O `user.Current` não achou
`/etc/passwd` e disse do que precisaria em vez dele. O `time.LoadLocation` não achou arquivos de
fuso. O `x509.SystemCertPool` não achou pacote e devolveu um pool vazio com erro `nil`, então o
`probe` mostrou `0 authorities`. Um programa de verdade seguiria em frente, abriria a primeira
conexão HTTPS e falharia ali, com uma mensagem sobre uma autoridade desconhecida que parece culpar
o servidor. **No distroless, as três respondem**, com os arquivos da própria imagem: a conta
`nonroot`, as regras de fuso do Debian e o pacote do Debian com 150 autoridades, que não são as 127
do Ubuntu da Ana. A diferença de tamanho é 3.19 MB, a base, até a casa dos centésimos.

## O que os 3.19 MB guardam

A imagem não tem shell para se listar, então a listagem é feita de fora. O `podman export` escreve
o sistema de arquivos inteiro de um contêiner como um arquivo tar:

```
ana@vm:~/ship$ podman create --name peek hits:1 >/dev/null && podman export peek > peek.tar && podman rm peek >/dev/null
ana@vm:~/ship$ tar -tf peek.tar | wc -l; tar -tf peek.tar | grep -c zoneinfo/
1436
1308
ana@vm:~/ship$ tar -tf peek.tar | grep -E "^(etc/(passwd|group|nsswitch.conf)|etc/ssl/certs/.*|bin/.*|hits)$"
bin/
etc/group
etc/nsswitch.conf
etc/passwd
etc/ssl/certs/
etc/ssl/certs/ca-certificates.crt
hits
ana@vm:~/ship$ tar -xOf peek.tar etc/passwd
root:x:0:0:root:/root:/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/sbin/nologin
nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin
```

**1.436 entradas, e 1.308 delas são o banco de fusos horários.** O resto é o punhado de arquivos que
um programa supõe existir: um `/etc/passwd` de três linhas com o usuário `nonroot` que o `podman
image inspect` mostrou como 65532, o `/etc/group`, o `nsswitch.conf`, um pacote de certificados,
alguns arquivos do Debian, como as licenças, e um `bin/` vazio. Todo shell de login ali é
`/sbin/nologin`, que também não está na imagem.

Cada um desses dá para acrescentar à mão numa imagem scratch. **O `-tags timetzdata` embute as
regras de fuso no binário**, por meio do pacote `time/tzdata` da biblioteca padrão:

```
ana@vm:~/ship/probe$ CGO_ENABLED=0 go build -tags timetzdata -o probe-tz . && stat -c "%s bytes  %n" probe probe-tz
4518294 bytes  probe
4928878 bytes  probe-tz
```

São 410.584 bytes a mais, que a documentação do pacote arredonda para "about 450 KB". O pacote de
certificados dá para copiar do estágio de build `golang` com um `COPY --from`, e um arquivo passwd
se escreve à mão. Os três passam então a ser arquivos que você mantém: autoridades entram no pacote
e outras perdem a confiança, e as regras de fuso mudam sempre que um governo mexe no relógio. **O
distroless é esses mesmos arquivos, mantidos em dia por outra pessoa**, por 3.19 MB, e esse é o
argumento a favor dele contra o scratch numa frase.

## Um binário dinâmico numa base estática

A seção 02 prometeu uma mensagem enganosa. Aqui está o `probe` compilado com o cgo ligado, ligado
dinamicamente à biblioteca C, posto na mesma base distroless:

```
ana@vm:~/ship/probe$ CGO_ENABLED=1 go build -o probe . && podman build -q --cap-drop=all --build-arg BASE=gcr.io/distroless/static-debian12:nonroot -t probe:dynamic .
9daf041528438993051de6f33e873c58a1472cef0681d45d1c5e5218e74d0159
ana@vm:~/ship/probe$ podman run --rm --network=none probe:dynamic; echo $?
exec /probe: no such file or directory
255
```

**O `/probe` está lá; o arquivo que falta é o `/lib64/ld-linux-x86-64.so.2`**, o carregador que o
`ldd` nomeou na seção 02, de que o kernel precisa antes de poder iniciar um programa ligado
dinamicamente. O kernel relata isso como "no such file" e não diz qual arquivo. A cura é
`CGO_ENABLED=0` ou, para um programa que precisa mesmo da biblioteca C,
`gcr.io/distroless/base-debian12`, que acrescenta a glibc. O `static` no nome da imagem quer dizer
"para binários estáticos", que é exatamente a condição que este quebrou.

## Qual imagem, exatamente

`:nonroot` é uma tag, e uma tag é um nome que o dono pode apontar para outra imagem amanhã, quando
o Debian publicar uma correção ou o pacote de certificados mudar. **Um digest é o SHA-256 do que o
registro serviu**, e só consegue nomear aqueles bytes:

```
ana@vm:~/ship$ podman image inspect --format "{{.Digest}}" gcr.io/distroless/static-debian12:nonroot
sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
ana@vm:~/ship$ podman manifest inspect gcr.io/distroless/static-debian12@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab | jq -r ".manifests[] | .platform.architecture + \" \" + .digest"
amd64 sha256:52dcfbabb7457ea47c82f6e13af8c8a4a1d9f7b0145142b3ecab20f2b888411d
arm64 sha256:06c3c14b7fa252d9f4285242d2d665ce3b51f74b02d3c529464f220f2912aecb
arm sha256:ed55430d277931fc5a82b9994d26933d21dca79b95f4e4290168c4d894da7b3a
s390x sha256:f8f7116c7de2f0c41b95a8dd068b9a0afb099c0663c9b75192e935d1b8ac4f15
ppc64le sha256:9154fe977c987d184361dcf0943da6a06505723bf9e9e25289407d434decd6d4
```

O digest que a Ana baixou nomeia um índice, e o índice nomeia uma imagem por processador, cinco
delas, cada uma com o seu digest. O Podman escolheu `amd64` para esta máquina, e num servidor ARM a
mesma linha `FROM` escolheria a `arm64`: o build cruzado da lição 16, na escala de uma imagem
inteira. **Fixar o digest do índice prende todas as plataformas de uma vez.** Escrito ao lado da
tag, a tag fica para as pessoas e o digest decide; troque o `Containerfile` por este:

`Containerfile`:

```dockerfile
# Build hits in an image that has Go, then ship it in one that has
# almost nothing. Each base is named by digest; the tag is for people.
FROM docker.io/library/golang:1.27.1@sha256:162be5298a40ed317005c8339c6de4d10d3eef336d66dc8e9259b03ab9d3a6d2 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits .

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /src/hits /hits
ENTRYPOINT ["/hits"]
```

```
ana@vm:~/ship$ podman build --cap-drop=all --network=none -t hits:1 . | grep -e STEP -e COMMIT
[1/2] STEP 1/4: FROM docker.io/library/golang:1.27.1@sha256:162be5298a40ed317005c8339c6de4d10d3eef336d66dc8e9259b03ab9d3a6d2 AS build
[1/2] STEP 2/4: WORKDIR /src
[1/2] STEP 3/4: COPY . .
[1/2] STEP 4/4: RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits .
[2/2] STEP 1/3: FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
[2/2] STEP 2/3: COPY --from=build /src/hits /hits
[2/2] STEP 3/3: ENTRYPOINT ["/hits"]
[2/2] COMMIT hits:1
```

O build usou as imagens que já estavam nesta máquina, porque são elas que esses digests nomeiam.
Daqui a um ano o mesmo arquivo compila sobre as mesmas bases, e passar para um distroless mais novo
é uma edição que alguém faz, revisa e pode desfazer, e não algo que aconteceu durante a noite. O
preço é que as correções também não chegam sozinhas, então uma base fixada precisa de alguém, ou
de um robô, que a atualize de propósito.
