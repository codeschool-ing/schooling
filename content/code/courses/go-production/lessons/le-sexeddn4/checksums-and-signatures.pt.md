---
title: Provar que o arquivo é o que você compilou
version: 1
---

Alguém baixa o `hits-linux-arm64` de uma página de release. Duas perguntas ficam entre essa pessoa
e rodar o arquivo, e são perguntas diferentes. **Um checksum responde se os bytes mudaram no
caminho; uma assinatura responde quem responde pelos bytes.** Um checksum publicado na mesma página
do arquivo prova pouco contra quem consegue mudar a página, porque essa pessoa muda os dois. Uma
assinatura só se faz com uma chave que o atacante não tem. Esta seção constrói as duas coisas, mais
uma terceira propriedade que valoriza ambas: um build que qualquer um repete e obtém os mesmos
bytes.

## Checksums

Um release pequeno, os dois alvos Linux com as flags da seção 02, em `dist/`:

```
ana@vm:~/ship$ for a in amd64 arm64; do CGO_ENABLED=0 GOARCH=$a go build -trimpath -ldflags="-s -w" -o dist/hits-linux-$a .; done
ana@vm:~/ship/dist$ sha256sum hits-* > SHA256SUMS && cat SHA256SUMS
e4d54644658448881c3cbc00d20e6cd02977d97f47b61eded56a54e7d4c781ad  hits-linux-amd64
cf602df1c912c17c376d5251934d89b5d1d050e2967e9aa6dba1fc1545a600a9  hits-linux-arm64
ana@vm:~/ship/dist$ sha256sum -c SHA256SUMS
hits-linux-amd64: OK
hits-linux-arm64: OK
```

**O `SHA256SUMS` é o arquivo convencional: uma linha por artefato, um SHA-256 e um nome.** O
`sha256sum -c` o lê de volta, calcula o hash de cada arquivo que ele nomeia e compara. Um byte
acrescentado ao fim de um binário, do jeito que um download truncado ou adulterado difere, e a
verificação percebe:

```
ana@vm:~/ship/dist$ printf x >> hits-linux-arm64; sha256sum -c SHA256SUMS; echo $?
hits-linux-amd64: OK
hits-linux-arm64: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
1
ana@vm:~/ship$ CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o dist/hits-linux-arm64 . && cd dist && sha256sum -c --quiet SHA256SUMS
hits-linux-arm64: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@vm:~/ship$ rm dist/hits-linux-arm64 && CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o dist/hits-linux-arm64 . && cd dist && sha256sum -c --quiet SHA256SUMS && echo all good
all good
```

O segundo comando é a armadilha. **Recompilar não consertou o arquivo**, porque o `go build -o`
primeiro lê o build ID carimbado dentro de uma saída que já existe e, quando ele bate com o build
que está para fazer, deixa o arquivo como está. Um byte no fim não toca no build ID, então o
arquivo danificado ficou. Apagá-lo forçou uma escrita de verdade, e o `--quiet` mostrou só as
falhas, que não houve.

## Um build que qualquer um repete

Um checksum prova que o arquivo é o que foi publicado. Não prova que o arquivo publicado veio do
código de onde diz ter vindo. **Se o build é reprodutível, qualquer um confere isso sozinho**:
compila o mesmo código com as mesmas ferramentas e compara os hashes. Aqui está o `hits` compilado
em `~/ship` e numa cópia do código em `~/ship-copy`, um diretório criado para isso:

```
ana@vm:~/ship$ cp -r go.mod main.go internal ~/ship-copy/
ana@vm:~/ship$ go build -o /tmp/hits-a . && (cd ~/ship-copy && go build -o /tmp/hits-b .) && sha256sum /tmp/hits-a /tmp/hits-b
eb5351838c881861aaf80577463eb4114217b5e674067a69237a96ce81fa240a  /tmp/hits-a
94a083a238a3b4e4faf148c2ce61dd213dd4255611b721f9b3707cb6b559f8fd  /tmp/hits-b
ana@vm:~/ship$ go build -trimpath -o /tmp/hits-a . && (cd ~/ship-copy && go build -trimpath -o /tmp/hits-b .) && sha256sum /tmp/hits-a /tmp/hits-b
c8b3a17e3f4d06ba9836d6e7f63a36171a97b2fce66a936cab723d148f3358b6  /tmp/hits-a
c8b3a17e3f4d06ba9836d6e7f63a36171a97b2fce66a936cab723d148f3358b6  /tmp/hits-b
```

**Mesmo código, hashes diferentes, e a única diferença era o diretório.** Sem `-trimpath`, o
binário grava `/home/ana/ship` num e `/home/ana/ship-copy` no outro, nos nomes de arquivo que usa
para stack traces e depuração. Com ele, os dois gravam caminhos de módulo e os bytes concordam. O
conjunto de ferramentas do Go faz o resto do build determinístico de propósito: sem datas, sem nome
de máquina, a mesma saída para as mesmas entradas.

A versão mais forte do teste é outra máquina, de todo. A imagem da seção 03 compilou o `hits` num
contêiner Debian 13, como root, em `/src`:

```
ana@vm:~/ship$ podman create --name peek hits:1 >/dev/null && podman cp peek:/hits from-image && podman rm peek >/dev/null
ana@vm:~/ship$ sha256sum hits from-image dist/hits-linux-amd64
e4d54644658448881c3cbc00d20e6cd02977d97f47b61eded56a54e7d4c781ad  hits
e4d54644658448881c3cbc00d20e6cd02977d97f47b61eded56a54e7d4c781ad  from-image
e4d54644658448881c3cbc00d20e6cd02977d97f47b61eded56a54e7d4c781ad  dist/hits-linux-amd64
```

**Três builds, no Ubuntu da Ana e num contêiner Debian, um hash.** O binário que a seção 02
compilou, o que saiu da imagem e o arquivo `amd64` do release são os mesmos 2.650.272 bytes. O que
eles têm em comum é o código, o Go 1.27.1 e as configurações que o `go version -m` registra:
`CGO_ENABLED=0`, `GOARCH=amd64`, `GOAMD64=v1` e `-trimpath`.

Uma imagem é mais difícil, porque o build grava a hora nela. O distroless mostra a solução:

```
ana@vm:~/ship$ podman image inspect --format "{{.Created}}" gcr.io/distroless/static-debian12:nonroot
1970-01-01 00:00:00 +0000 UTC
ana@vm:~/ship$ podman build -q --no-cache --cap-drop=all --network=none --timestamp 0 -t hits:r1 .
46957a7c1dc10917f735d000e2ac6b26903754e5f01d0933b3413cd4ea9498c8
ana@vm:~/ship$ podman build -q --no-cache --cap-drop=all --network=none --timestamp 0 -t hits:r2 .
46957a7c1dc10917f735d000e2ac6b26903754e5f01d0933b3413cd4ea9498c8
ana@vm:~/ship$ podman build -q --no-cache --cap-drop=all --network=none -t hits:r2 .
7bd7cea71b0cff8e9ebe4e5bb5106f1b1a65d8fb821e3bfebc12a80dd5bd97da
```

**O Google constrói o distroless com todas as datas no início de 1970, e o `--timestamp 0` pede o
mesmo ao Podman.** Dois builds sem cache e com essa flag produziram um único id de imagem, e o
build sem ela, outro, a partir dos mesmos arquivos. O `--no-cache` importa aqui: uma camada em
cache guarda a data com que foi feita, então um build com cache pode devolver uma imagem mais
antiga, diga o `--timestamp` o que disser. Com as bases fixadas por digest, como a seção 04 deixou
o `Containerfile`, esse id é uma propriedade da árvore de código e qualquer um com as mesmas duas
bases consegue conferir.

## Assinando com o cosign

O cosign, do projeto Sigstore, assina arquivos e imagens de contêiner. É um programa Go, então se
instala como toda ferramenta deste curso; o build leva uns três minutos e o binário tem cerca de
139 MB:

```
ana@vm:~/ship$ go install github.com/sigstore/cosign/v3/cmd/cosign@v3.1.3
ana@vm:~/ship$ cosign version 2>&1 | grep -e GitVersion -e GoVersion -e Platform
GitVersion:    v3.1.3
GoVersion:     go1.27.1
Platform:      linux/amd64
```

Uma assinatura precisa de um par de chaves. **A chave privada assina e nunca sai da máquina da Ana;
a chave pública verifica e vai junto com cada release.** O cosign cifra a chave privada com uma
senha, que ele pede duas vezes num terminal ou lê de `COSIGN_PASSWORD`. O `read -rs` põe a senha
nessa variável sem ecoá-la e sem gravá-la no histórico do shell:

```
ana@vm:~/ship$ read -rs COSIGN_PASSWORD; export COSIGN_PASSWORD
ana@vm:~/ship$ cosign generate-key-pair
Private key written to cosign.key
Public key written to cosign.pub
ana@vm:~/ship$ stat -c "%a  %n" cosign.key cosign.pub
600  cosign.key
644  cosign.pub
```

Modo 600 na chave privada, e ela fica em `~/ship`, fora de `dist/`. **Ela também não chega a uma
imagem**, porque o `.containerignore` da seção 03 começa com `*`: uma chave no contexto de build é o
jeito clássico de publicar uma.

### Sem log público, de propósito

Por padrão, o cosign v3 tira os serviços que usa da configuração de assinatura do próprio
Sigstore, e entre eles está o Rekor, o log de transparência público do Sigstore. Uma assinatura
gravada ali fica ali: rodado com `--use-signing-config=false`, este cosign parou para perguntar
antes de enviar, e a pergunta dizia que o registro "cannot be removed later". Para uma chave num
notebook e um exercício de curso, é um registro de que ninguém precisa. Uma configuração sua
substitui a do Sigstore, e uma vazia não nomeia serviço nenhum:

```
ana@vm:~/ship$ cosign signing-config create --out no-tlog.json && cat no-tlog.json; echo
{"mediaType":"application/vnd.dev.sigstore.signingconfig.v0.2+json","rekorTlogConfig":{},"tsaConfig":{}}
```

**Uma assinatura sobre o `SHA256SUMS` cobre cada arquivo que ele lista**, então é esse o arquivo a
assinar:

```
ana@vm:~/ship$ cosign sign-blob --key cosign.key --signing-config no-tlog.json --bundle dist/SHA256SUMS.sigstore.json dist/SHA256SUMS
WARNING: Could not fetch trusted_root.json from the TUF repository. Continuing with individual targets. Error from TUF: error getting live trusted root: failed to create TUF client failed to load metadata: tuf refresh failed: Get "https://tuf-repo-cdn.sigstore.dev/15.root.json": Forbidden
Using payload from: dist/SHA256SUMS
Signing artifact...
Wrote bundle to file dist/SHA256SUMS.sigstore.json
```

O aviso é deste laboratório: o cosign tenta buscar a raiz de confiança do Sigstore antes de tudo, e
esta máquina não tem permissão para chegar a esse endereço. Uma assinatura com uma chave da própria
Ana não precisa dela, e o bundle foi escrito. **O bundle é um pequeno arquivo JSON com a assinatura
e o hash que ela cobre**, e vai para a página de release ao lado do `SHA256SUMS` e da `cosign.pub`.

Verificar é o que faz quem baixa:

```
ana@vm:~/ship$ cosign verify-blob --key cosign.pub --bundle dist/SHA256SUMS.sigstore.json --insecure-ignore-tlog dist/SHA256SUMS
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the blob.
Verified OK
ana@vm:~/ship$ sed "2s/^......../00000000/" dist/SHA256SUMS > forged; cosign verify-blob --key cosign.pub --bundle dist/SHA256SUMS.sigstore.json --insecure-ignore-tlog forged; echo $?
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the blob.
Error: failed to verify signature: could not verify message: invalid signature when validating ASN.1 encoded signature
error during command execution: failed to verify signature: could not verify message: invalid signature when validating ASN.1 encoded signature
1
```

**`Verified OK` para o arquivo verdadeiro; status de saída 1 para uma cópia com o checksum do arm64
reescrito**, que é o que um atacante que trocou o binário teria de fazer com a lista. Sem
`--insecure-ignore-tlog`, o cosign exige a entrada no log que esta assinatura, de propósito, não
tem, e o aviso é justo: sem log público, ninguém além da Ana vê quando a chave dela assinou alguma
coisa. A corrente vai da assinatura para a lista e da lista para os binários, e o elo do meio
aparece no bundle:

```
ana@vm:~/ship$ jq -r .messageSignature.messageDigest.digest dist/SHA256SUMS.sigstore.json | base64 -d | od -An -tx1 -v | tr -d " \n"; echo
6fd31c4913f2aa88e729d3d55ccd34e9a3046219c0b486edb80b7a6d95ac96e3
ana@vm:~/ship$ sha256sum dist/SHA256SUMS
6fd31c4913f2aa88e729d3d55ccd34e9a3046219c0b486edb80b7a6d95ac96e3  dist/SHA256SUMS
```

O bundle guarda o SHA-256 do `SHA256SUMS` em base64; decodificado, é o hash que o `sha256sum`
mostra. **O que o cosign assinou é esse hash**, e o `SHA256SUMS`, por sua vez, guarda o hash de
cada binário. A sua chave e a sua assinatura vão ser diferentes destas, porque um par de chaves novo
é aleatório, e cada assinatura ECDSA também. O hash não, se o seu build bateu com o da Ana.

## O que não rodou aqui

Três coisas que um release de verdade acrescenta, descritas e não rodadas neste laboratório, que
não tem registro, nem conta num provedor de identidade, nem caminho até os serviços do Sigstore.

**A assinatura sem chave troca o par de chaves por uma identidade.** O `cosign sign-blob` sem
`--key` leva você a um login num provedor de identidade, como GitHub ou Google, ou usa a identidade
de um job de CI. A autoridade certificadora do Sigstore, o Fulcio, emite para essa identidade um
certificado que vive minutos, a assinatura vai para o Rekor, e quem verifica confere a identidade
com `--certificate-identity` e `--certificate-oidc-issuer` em vez de uma chave pública. Não há chave
privada para perder, e o log é o que torna isso seguro.

**Proveniência e SBOM dizem como o arquivo foi feito.** Proveniência é uma declaração assinada de
como um artefato foi construído: que código, que commit, que máquina de build. Um SBOM, a lista de
materiais de software, enumera o que entrou nele. O `cosign attest-blob` assina os dois tipos de
declaração. Para um binário Go, o `go version -m` já mostra um SBOM pequeno, os módulos e as
configurações que o build registrou.

**Uma imagem é assinada separadamente do binário.** O `cosign sign` assina uma imagem num registro
e guarda a assinatura ao lado dela no mesmo registro, endereçada pelo digest da imagem. Assine
sempre um digest, nunca uma tag, pelo motivo que a seção 04 deu: uma tag pode ser movida depois da
assinatura. Um release que entrega binário e imagem assina os dois.
