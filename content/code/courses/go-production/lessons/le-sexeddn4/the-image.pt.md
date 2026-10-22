---
title: Uma imagem com um programa dentro
version: 1
---

É comum imaginar uma imagem de contêiner como uma pequena máquina virtual, com um sistema
operacional dentro, sobre o qual o programa roda. **Uma imagem é uma pilha de arquivos compactados
e algumas linhas de configuração**: desempacotados um sobre o outro, os arquivos formam os únicos
arquivos que um processo enxerga, e a configuração diz que programa iniciar e com que usuário. Não
existe segundo kernel. O processo roda no kernel da máquina como qualquer outro, cercado do resto
dela.

Então a pergunta que uma imagem responde é quais arquivos o programa consegue ver. Para o `hits`
estático da seção 02, a resposta honesta é quase nenhum, e o trabalho desta seção é uma imagem que
guarda o binário e muito pouco além disso. A lição 17 instalou o Podman sem root, então todo
comando aqui roda como a Ana e dispensa `sudo`.

## Duas imagens de partida

Duas imagens base, baixadas uma vez dos seus registros:

```
ana@vm:~/ship$ podman images --format 'table {{.Repository}} {{.Tag}} {{.Size}}' --filter reference=docker.io/library/golang --filter reference=gcr.io/distroless/static-debian12
REPOSITORY                         TAG         SIZE
docker.io/library/golang           1.27.1      912 MB
gcr.io/distroless/static-debian12  nonroot     3.19 MB
```

**`golang:1.27.1` é uma oficina de 912 MB**: Debian 13, `gcc`, `git` e o conjunto de ferramentas
do Go exatamente na versão que este curso usa. **`distroless/static-debian12` tem 3.19 MB** e não
tem shell, gerenciador de pacotes nem ferramentas; a seção 04 a abre e conta o que ela tem.
Compilar na primeira e entregar na segunda é para isso que serve um build de vários estágios.

## O Containerfile

`Containerfile` é o nome que o Podman dá ao que o Docker chama de `Dockerfile`, e o Podman lê os
dois. Ponha este no topo de `~/ship`, ao lado do `go.mod`:

```schooling-example
{
  "language": "dockerfile",
  "file": "Containerfile",
  "parts": [
    {
      "code": "# Build hits in an image that has Go, then ship it in one that has\n# almost nothing.\nFROM docker.io/library/golang:1.27.1 AS build",
      "note": "**O primeiro estágio é uma oficina.** A imagem oficial `golang` exatamente no Go que este curso usa, com o nome `build` para o segundo estágio poder se referir a ela."
    },
    {
      "code": "WORKDIR /src\nCOPY . .",
      "note": "O `WORKDIR` cria o `/src` e o torna o diretório atual. O `COPY . .` copia para ele o contexto de build: o que o `.containerignore` deixa passar, e nada mais."
    },
    {
      "code": "RUN CGO_ENABLED=0 go build -trimpath -ldflags=\"-s -w\" -o hits .",
      "note": "O build de release da seção 02, rodado dentro da oficina. O `hits` não tem dependências, então o passo não precisa de rede: nada é baixado."
    },
    {
      "code": "\nFROM gcr.io/distroless/static-debian12:nonroot",
      "note": "**O segundo estágio é o que se entrega.** A imagem distroless do Google para binários estáticos, com Debian 12 por baixo, na variante cujo usuário padrão não é root."
    },
    {
      "code": "COPY --from=build /src/hits /hits",
      "note": "Um arquivo atravessa da oficina: o binário. As ferramentas, o código e o cache de build ficam para trás e não estão na imagem."
    },
    {
      "code": "ENTRYPOINT [\"/hits\"]",
      "note": "O programa que a imagem roda. O que vem depois do nome da imagem no `podman run` vira argumento dele, então `podman run hits:1 top -n 3` roda `/hits top -n 3`."
    }
  ]
}
```

**Cada estágio começa no seu próprio `FROM`, e só o último vira a imagem.** O primeiro existe para
produzir um arquivo, e nada dele viaja a menos que um `COPY --from` o peça pelo nome. Com
dependências, um Containerfile de Go costuma copiar o `go.mod` e o `go.sum` e rodar `go mod
download` antes de copiar o resto. Os downloads ficam então numa camada só deles e sobrevivem a uma
mudança no código. O `hits` não tem dependências, então esse passo não teria o que fazer.

O `COPY . .` copia o contexto de build, o diretório indicado no fim do `podman build`, e em
`~/ship` esse diretório tem o `access.log`, dois binários e, a partir da seção 05, uma chave
privada de assinatura. **Um arquivo `.containerignore` decide o que entra no build**, e este é uma
lista do que pode entrar, e não do que não pode. Salve como `.containerignore`:

```
# Nothing enters the build that the build does not need.
*
!go.mod
!*.go
!internal/
```

O `*` exclui tudo, e cada linha com `!` deixa um padrão voltar: o `go.mod`, os arquivos `.go` do
topo e o diretório `internal` com tudo o que há dentro. Um arquivo acrescentado ao `~/ship` no mês
que vem fica de fora até alguém nomeá-lo, que é o lado seguro para uma lista dessas errar.

## Construindo

```
ana@vm:~/ship$ podman build --cap-drop=all --network=none -t hits:1 .
[1/2] STEP 1/4: FROM docker.io/library/golang:1.27.1 AS build
[1/2] STEP 2/4: WORKDIR /src
--> c2a45fd9cbae
[1/2] STEP 3/4: COPY . .
--> e7ebcfe093bd
[1/2] STEP 4/4: RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits .
--> c1850bac5989
[2/2] STEP 1/3: FROM gcr.io/distroless/static-debian12:nonroot
[2/2] STEP 2/3: COPY --from=build /src/hits /hits
--> 446d8378012a
[2/2] STEP 3/3: ENTRYPOINT ["/hits"]
[2/2] COMMIT hits:1
--> db40eb60e402
Successfully tagged localhost/hits:1
db40eb60e402aa2db03cf700ef07e6dc8529da79fb1491e15f9721ac096534ce
```

Duas flags trabalham aqui. **`--network=none` dá a cada passo `RUN` rede nenhuma**, e o `hits`
compila mesmo assim porque não há nada para baixar. Este laboratório não poderia oferecer rede de
qualquer forma: o seu Podman sem root não tem `/dev/net/tun` para montar uma, e todo `podman run`
desta lição leva a mesma flag pelo mesmo motivo. Um build que precisa de módulos precisa de rede
nesse passo, ou dos módulos já vendorizados no contexto. **`--cap-drop=all` tira os poderes que o
root normalmente tem dentro do contêiner de build**, que o `go build` nunca usa. Duas coisas
decorreram disso. Sem a flag, o Podman deste laboratório imprime um aviso para cada uma de onze
capacidades que não consegue conceder, o que não diz nada sobre o build. Com ela, o root deixa de
poder escrever no `/`, cujo modo é 555 na imagem `golang`. O primeiro rascunho deste arquivo
compilava para `-o /hits` e parava com `open /hits: permission denied`, e é por isso que o binário
é compilado em `/src` e copiado de lá.

As linhas que começam com `-->` são o id de cada camada no momento em que é gravada, e vão ser
outras na sua máquina. O que sobra é uma tag, `localhost/hits:1`, o nome que o Podman dá a uma
imagem que não veio de registro nenhum:

```
ana@vm:~/ship$ podman images --format 'table {{.Repository}} {{.Tag}} {{.Size}}' --filter reference=localhost/hits
REPOSITORY      TAG         SIZE
localhost/hits  1           5.84 MB
```

**5.84 MB: a base de 3.19 MB e o binário de 2.65 MB**, contra uma oficina de 912 MB que nunca sai
desta máquina.

## Rodando

O programa lá dentro só vê os arquivos da imagem, então o log tem de ser entregue a ele. Dois
jeitos:

```
ana@vm:~/ship$ podman run --rm --network=none -i hits:1 top -n 3 < access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
ana@vm:~/ship$ podman run --rm --network=none -v "$PWD/access.log:/data/access.log:ro" hits:1 count /data/access.log
status  requests
200     7554
201     1256
204     1248
301     1192
304     1229
400     1223
401     1226
404     2549
500     1269
503     1254
```

**Os números da lição 1, requisição por requisição, de dentro de um contêiner.** A primeira
execução usa o contrato que a lição 1 embutiu: sem arquivo, vale a entrada padrão; o `-i` mantém a
entrada padrão do contêiner aberta, e o shell a alimenta com o log. A segunda monta o único arquivo
em `/data/access.log`, só para leitura por causa do `:ro`, e o nomeia como argumento. Tudo o que
veio depois do nome da imagem virou argumento do `/hits`, porque o ponto de entrada da imagem é o
programa, e não um shell. O `--rm` apaga o contêiner quando ele termina, então nada se acumula.

Com que usuário ele rodou?

```
ana@vm:~/ship$ podman image inspect --format "{{.Config.User}} {{.Config.Entrypoint}}" hits:1
65532 [/hits]
ana@vm:~/ship$ install -m 600 access.log private.log && podman run --rm --network=none -v "$PWD/private.log:/data/access.log:ro" hits:1 count /data/access.log; echo $?
hits: open /data/access.log: permission denied
1
ana@vm:~/ship$ podman run --rm --network=none -i hits:1 top -n 1 < private.log
path    requests
/login  2576
```

**Usuário 65532, o `nonroot` da tag da imagem**, definido pela imagem base e herdado pelo
`hits:1`. Ele também não é ninguém na máquina da Ana: o Podman sem root mapeia os usuários do
contêiner numa faixa de ids reservada para a Ana, e o 65532 cai num desses, que não é a Ana. Então
um log que só a Ana lê, modo 600, não abre pela montagem, e o `hits` diz isso e sai com 1, o status
que a lição 1 deu a uma execução que falhou. Pela entrada padrão funciona, porque o shell que abre
o `private.log` é da Ana. Um programa que é invadido dentro do contêiner em que roda vira um
usuário sem privilégios e sem shell para rodar, que é a razão de ser da variante `nonroot`.

## As camadas

```
ana@vm:~/ship$ podman history --format "{{.Size}}\t{{.CreatedBy}}" hits:1
0B	/bin/sh -c #(nop) ENTRYPOINT ["/hits"]
2.65MB	/bin/sh -c #(nop) COPY file:dc30b927acd5c4...
276kB	bazel build //common:cacerts_debian12_amd6...
3.07kB	bazel build //common:os_release_debian12
2.05kB	bazel build //static:nsswitch
1.54kB	bazel build //common:tmp
2.56kB	bazel build //common:group
2.56kB	bazel build //common:home
2.56kB	bazel build //common:passwd
1.54kB	bazel build //common:rootfs
102kB	bazel build @bookworm//media-types/amd64:d...
2.42MB	bazel build @bookworm//tzdata/amd64:data_s...
41kB	bazel build @bookworm//netbase/amd64:data_...
328kB	bazel build @bookworm//base-files/amd64:da...
```

A mais nova primeiro. A linha do topo é a configuração e não tem arquivos; a seguinte é o binário;
as doze de baixo vieram com a base, construída pelo Google com Bazel a partir de pacotes do Debian
12 ("bookworm"). Em escala:

```schooling-figure
{
  "svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" aria-label=\"A imagem hits:1 é uma pilha de 13 camadas que somam 5.84 MB. A camada do topo, acrescentada pelo segundo estágio, é o binário hits, com 2.65 MB. Abaixo dela ficam as 12 camadas da base distroless, 3.19 MB, das quais os dados de fuso horário, com 2.42 MB, são quase tudo; as autoridades certificadoras ocupam 276 kB, base-files 328 kB, media-types 102 kB, netbase 41 kB, e sete camadas pequenas como passwd e group ficam com 2 a 3 kB cada. Ao lado da pilha, o estágio de build, a imagem golang de 912 MB, nunca é entregue; só um arquivo atravessa dela.\"><defs><marker id=\"l18a\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"115\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o estágio de build</text><text x=\"115\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">docker.io/library/golang:1.27.1</text><text x=\"115\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--amber)\">912 MB</text><text x=\"115\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nunca é entregue</text><text x=\"250\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">a imagem hits:1: 13 camadas, 5.84 MB</text><rect x=\"242\" y=\"104\" width=\"468\" height=\"342\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"250\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a base, distroless static-debian12:nonroot: 12 camadas, 3.19 MB</text><text x=\"250\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">acrescentada por COPY --from=build</text><text x=\"350\" y=\"81.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/hits</text><rect x=\"360\" y=\"73\" width=\"250.0\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"618.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.65MB</text><text x=\"350\" y=\"141.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cacerts</text><rect x=\"360\" y=\"133\" width=\"26.0\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"394.0377358490566\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">276kB</text><text x=\"350\" y=\"167.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">os_release</text><rect x=\"360\" y=\"159\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3.07kB</text><text x=\"350\" y=\"193.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nsswitch</text><rect x=\"360\" y=\"185\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.05kB</text><text x=\"350\" y=\"219.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tmp</text><rect x=\"360\" y=\"211\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.54kB</text><text x=\"350\" y=\"245.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">group</text><rect x=\"360\" y=\"237\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"245.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.56kB</text><text x=\"350\" y=\"271.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">home</text><rect x=\"360\" y=\"263\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.56kB</text><text x=\"350\" y=\"297.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">passwd</text><rect x=\"360\" y=\"289\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"297.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.56kB</text><text x=\"350\" y=\"323.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rootfs</text><rect x=\"360\" y=\"315\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"323.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.54kB</text><text x=\"350\" y=\"349.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">media-types</text><rect x=\"360\" y=\"341\" width=\"9.6\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"377.62264150943395\" y=\"349.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">102kB</text><text x=\"350\" y=\"375.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tzdata</text><rect x=\"360\" y=\"367\" width=\"228.3\" height=\"16\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"596.3018867924528\" y=\"375.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.42MB</text><text x=\"350\" y=\"401.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">netbase</text><rect x=\"360\" y=\"393\" width=\"3.9\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"371.8679245283019\" y=\"401.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41kB</text><text x=\"350\" y=\"427.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">base-files</text><rect x=\"360\" y=\"419\" width=\"30.9\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"398.9433962264151\" y=\"427.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">328kB</text><path d=\"M150,100 L150,91.0 Q150,81.0 160,81.0 L252,81.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l18a)\"></path><text x=\"200\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um arquivo atravessa</text><text x=\"360.0\" y=\"456\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ENTRYPOINT e USER são configuração, não camadas</text></svg>",
  "caption": "As camadas de hits:1, como o podman history as mediu, desenhadas em escala. Duas camadas são quase a imagem inteira: o programa e o banco de fusos horários.",
  "same": [
    "912 MB"
  ]
}
```

**Uma camada é o programa e uma é o banco de fusos horários; as outras onze juntas pesam menos de
um megabyte.** Camadas também são a unidade de reaproveitamento. Duas imagens sobre a mesma base
compartilham esses doze arquivos, em disco e num registro. Um segundo build reaproveita toda camada
cuja instrução e cujas entradas não mudaram:

```
ana@vm:~/ship$ podman build --cap-drop=all --network=none -t hits:1 .
[1/2] STEP 1/4: FROM docker.io/library/golang:1.27.1 AS build
[1/2] STEP 2/4: WORKDIR /src
--> Using cache c2a45fd9cbae79191467b4f14c1201b4793135d395b5fb7e7445fcdf9da550af
--> c2a45fd9cbae
[1/2] STEP 3/4: COPY . .
--> Using cache e7ebcfe093bde879c89298633a2feec17339b9dda4eb313f9f0103b40c08e867
--> e7ebcfe093bd
[1/2] STEP 4/4: RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits .
--> Using cache c1850bac59892487e995b8e74275cd0a089be54d1a252b3932e111cf53d3e8e6
--> c1850bac5989
[2/2] STEP 1/3: FROM gcr.io/distroless/static-debian12:nonroot
[2/2] STEP 2/3: COPY --from=build /src/hits /hits
--> Using cache 446d8378012ab338929bd0ab7e685f5d84843a3574155b987c0b1a57df327e38
--> 446d8378012a
[2/2] STEP 3/3: ENTRYPOINT ["/hits"]
--> Using cache db40eb60e402aa2db03cf700ef07e6dc8529da79fb1491e15f9721ac096534ce
[2/2] COMMIT hits:1
--> db40eb60e402
Successfully tagged localhost/hits:1
db40eb60e402aa2db03cf700ef07e6dc8529da79fb1491e15f9721ac096534ce
```

**Todos os passos vieram do cache e nada foi compilado.** Edite qualquer arquivo `.go` e o
`COPY . .` vê entradas diferentes, então ele e todos os passos depois dele rodam de novo; as duas linhas
acima dele continuam em cache.
