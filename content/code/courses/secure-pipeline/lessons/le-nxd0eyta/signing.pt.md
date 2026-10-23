---
title: Uma chave para o servidor de CI, e a primeira assinatura
version: 1
---

Uma assinatura aqui é a mesma aritmética de qualquer outro lugar: uma chave privada transforma um
digest numa assinatura, e a chave pública correspondente a confere. **O que a torna útil num
pipeline é quem guarda a chave privada.** Se toda pessoa do time pode assinar, uma assinatura diz
"alguém do time", e quem verifica não tem como agir sobre isso. Se só o servidor de CI pode, a
assinatura diz "isto passou pelo pipeline", e essa é uma afirmação que um deploy pode exigir.

A ferramenta é o `cosign`, do projeto Sigstore, um projeto aberto sob a Linux Foundation. A aula 8
de `gitops` o usou para assinar um chart e uma imagem a partir de um laptop; aqui a chave pertence
ao servidor de CI e a assinatura vira um estágio. Os comandos são os mesmos, e a diferença é onde a
chave mora. Ele se instala como toda ferramenta deste curso, o release e o checksum:

```
ana@vm:~$ curl -fsSLO https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign-linux-amd64
ana@vm:~$ curl -fsSL https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign_checksums.txt | grep " cosign-linux-amd64$" | sha256sum --check
cosign-linux-amd64: OK
ana@vm:~$ install -m 755 cosign-linux-amd64 ~/.local/bin/cosign && rm cosign-linux-amd64
ana@vm:~$ cosign version | grep GitVersion
GitVersion:    v3.1.3
```

O release é um binário único, então não há nada para descompactar.

### As chaves, junto do servidor e longe do código

O servidor de CI deste curso é o diretório `~/ci`, então as chaves vão para `~/ci/keys`, que
nenhum clone do linkbox jamais contém. A chave privada é cifrada com uma senha, a senha é uma
string aleatória num arquivo que só a Ana lê, e o `cosign` a lê da variável `COSIGN_PASSWORD` em
vez de perguntar:

```
ana@vm:~/linkbox$ mkdir -p ~/ci/keys && cd ~/ci/keys
ana@vm:~/ci/keys$ openssl rand -base64 24 > password && chmod 600 password
ana@vm:~/ci/keys$ COSIGN_PASSWORD=$(cat password) cosign generate-key-pair
Private key written to cosign.key
Public key written to cosign.pub
ana@vm:~/ci/keys$ cosign signing-config create --out offline.json
ana@vm:~/ci/keys$ jq . offline.json
{
  "mediaType": "application/vnd.dev.sigstore.signingconfig.v0.2+json",
  "rekorTlogConfig": {},
  "tsaConfig": {}
}
ana@vm:~/ci/keys$ ls -l
total 16
-rw------- 1 ana ana 653 Oct 23 09:33 cosign.key
-rw-r--r-- 1 ana ana 178 Oct 23 09:33 cosign.pub
-rw------- 1 ana ana 104 Oct 23 09:33 offline.json
-rw------- 1 ana ana  33 Oct 23 09:33 password
ana@vm:~/ci/keys$ cd ~/linkbox
```

Quatro arquivos, e não são igualmente secretos. **`cosign.key` e `password` juntos podem assinar
qualquer coisa em nome da CI**; nenhum dos dois sozinho pode. O `cosign.pub` é o contrário: não
serve para assinar e precisa estar em todo lugar onde acontece uma verificação. O `offline.json` é
o quarto, e pede um parágrafo só dele.

### Por que uma configuração de assinatura vazia

Por padrão o `cosign` assina para o mundo público. Ele registra toda assinatura no **Rekor**, o log
de transparência público do Sigstore, e pede um carimbo de tempo a uma autoridade pública, para que
qualquer pessoa possa conferir depois que a assinatura existia num dado momento. É o padrão certo
para um projeto cujas imagens são públicas. Para o linkbox, ele publicaria para sempre o digest de
cada imagem e o nome de um registry que só existe num laptop. E na máquina em que estas aulas foram
gravadas a escolha já estava feita: os serviços públicos do Sigstore não são alcançáveis dela, então
uma assinatura que dependesse deles não poderia ser feita.

Uma **configuração de assinatura** (signing config) é um arquivo que lista os serviços que o
`cosign` deve usar. A criada acima não lista nenhum: um `rekorTlogConfig` vazio e um `tsaConfig`
vazio. **O que sobra é a chave, e mais nada.** Na sua máquina, com acesso à internet, assinar sem
`--signing-config` gravaria no Rekor; se isso é aceitável é uma decisão sobre o que os seus digests
revelam, e para um serviço privado a resposta costuma ser não.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l14-flow\" aria-label=\"Assinar e verificar. O servidor de CI guarda cosign.key e a senha em ~/ci/keys e assina o digest que enviou; a assinatura vai para o registry ao lado da imagem, numa tag com o nome do digest. Quem verifica tem cosign.pub, busca os dois, confere a assinatura sobre o digest e só então implanta esse digest.\"><defs><marker id=\"sp-l14-flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l14-flow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l14-flow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o servidor de CI</text><rect x=\"20\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/keys</text><text x=\"110.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cosign.key + password</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o registry</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a imagem</text><text x=\"360.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox@sha256:…</text><rect x=\"270\" y=\"100\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a assinatura</text><text x=\"360.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tag sha256-…</text><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem verifica</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cosign verify</text><text x=\"610.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--key cosign.pub</text><path d=\"M200 65 L230 65 L230 122 L268 122\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-phosphor)\"></path><text x=\"215\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">assina o digest</text><path d=\"M518 65 L452 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-paper-dim)\"></path><path d=\"M518 80 L490 80 L490 122 L452 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-paper-dim)\"></path><text x=\"485\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">busca os dois</text><rect x=\"520\" y=\"120\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passa: implanta o digest</text><rect x=\"520\" y=\"172\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">falha: recusa</text><path d=\"M610 90 L610 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-phosphor)\"></path><path d=\"M700 70 L712 70 L712 190 L702 190\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-amber)\"></path></svg>", "caption": "A chave privada nunca sai do servidor de CI; a pública vai para onde houver uma verificação."}
```

### Assine o digest

O digest vem da imagem que o servidor de CI enviou para o último commit. O `docker inspect` lista
todas as referências pelas quais a imagem é conhecida, e a linha deste registry é a que se assina:

```
ana@vm:~/linkbox$ REF=$(docker inspect --format "{{range .RepoDigests}}{{println .}}{{end}}" localhost:5000/linkbox:$(git rev-parse --short HEAD) | grep ^localhost:5000/); echo $REF
localhost:5000/linkbox@sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179
ana@vm:~/linkbox$ export COSIGN_PASSWORD=$(cat ~/ci/keys/password)
ana@vm:~/linkbox$ cosign sign --yes --key ~/ci/keys/cosign.key --signing-config ~/ci/keys/offline.json $REF
WARNING: Could not fetch trusted_root.json from the TUF repository. Continuing with individual targets. Error from TUF: error getting live trusted root: failed to create TUF client failed to load metadata: tuf refresh failed: Get "https://tuf-repo-cdn.sigstore.dev/15.root.json": Forbidden
Signing artifact...
Pushing signature to: localhost:5000/linkbox
ana@vm:~/linkbox$ unset COSIGN_PASSWORD
ana@vm:~/linkbox$ curl -s localhost:5000/v2/linkbox/tags/list | jq -c .tags
["de3591e","main","sha256-a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179"]
```

O `WARNING` é o `cosign` falhando em alcançar a raiz de confiança do Sigstore, o que ele tenta a
cada execução; com acesso à internet ele não aparece, e uma assinatura feita com chave não precisa
dela. `--yes` responde à pergunta que o `cosign` faz antes de assinar, que é sobre o log público e
não se aplica aqui. **A assinatura está no registry agora, numa tag com o nome do digest que ela
assina**, então qualquer um que leia a imagem encontra a assinatura, e o registry não precisou de
nenhum recurso novo para guardá-la.

### Verifique

Verificar precisa da imagem, da chave pública e de uma decisão sobre o log.
`--insecure-ignore-tlog=true` diz que nenhuma entrada de log é esperada, o que vale para toda
assinatura deste curso, e a opção tem esse nome porque pular o log remove o registro público de
quando a assinatura foi feita:

```
ana@vm:~/linkbox$ cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true $REF | jq .
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5000/linkbox@sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
[
  {
    "critical": {
      "identity": {
        "docker-reference": "localhost:5000/linkbox@sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179"
      },
      "image": {
        "docker-manifest-digest": "sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179"
      },
      "type": "https://sigstore.dev/cosign/sign/v1"
    },
    "optional": {}
  }
]
```

O `WARNING` diz exatamente isso, e para estas assinaturas é o desenho. A lista de checagens é a que
o `cosign` imprime toda vez, com ou sem log envolvido. **O JSON é o que foi de fato assinado**: um
pequeno documento que nomeia o digest da imagem em `docker-manifest-digest`. É por isso que uma
assinatura não pode ser movida para outros bytes, e é por isso que a próxima seção pode mostrá-la
recusando.
