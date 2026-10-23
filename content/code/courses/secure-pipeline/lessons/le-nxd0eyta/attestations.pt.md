---
title: Atestações, e como fazer perguntas a elas
version: 1
---

Uma assinatura responde a uma pergunta: quem tem esta chave respondeu por estes bytes? **Uma
atestação responde a uma pergunta sobre os bytes**: o que há dentro deles, ou como foram feitos.
Ela é um pequeno documento JSON chamado **declaração in-toto** (in-toto statement), com três campos
que importam. O `subject` nomeia o artefato pelo digest. O `predicateType` diz que tipo de
afirmação é o resto. O `predicate` é a afirmação em si. O `cosign` assina a declaração inteira e a
guarda no registry ao lado da imagem, do mesmo jeito que guarda uma assinatura.

### O que está anexado à imagem

A execução da seção anterior anexou três coisas à imagem para a qual `main` aponta agora. O
`cosign tree` as lista; ele enfeita a saída com símbolos que esta página não desenha, então o
`grep` fica só com o tipo de cada uma:

```
ana@vm:~/linkbox$ REF=$(docker inspect --format "{{range .RepoDigests}}{{println .}}{{end}}" localhost:5000/linkbox:main | grep ^localhost:5000/); echo $REF
localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b
ana@vm:~/linkbox$ cosign tree $REF 2>/dev/null | grep -o "https://[^ ]*"
https://slsa.dev/provenance/v1
https://cyclonedx.org/bom
https://sigstore.dev/cosign/sign/v1
```

A assinatura, a lista de materiais em CycloneDX e a proveniência no formato da SLSA, versão 1.
**Qualquer um que consiga puxar a imagem encontra as três**, e ninguém precisa de um segundo
sistema para guardá-las.

### A lista de materiais, verificada

O `cosign verify-attestation` confere a assinatura de uma declaração exatamente como o `cosign
verify` confere a de uma imagem, e depois imprime a declaração, codificada em base64 dentro de um
envelope JSON:

```
ana@vm:~/linkbox$ cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type cyclonedx $REF > ~/sbom.att.json
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the attestation.

Verification for localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
ana@vm:~/linkbox$ jq -r .payload ~/sbom.att.json | base64 -d | jq -c "{_type, predicateType, subject}"
{"_type":"https://in-toto.io/Statement/v0.1","predicateType":"https://cyclonedx.org/bom","subject":[{"name":"localhost:5000/linkbox","digest":{"sha256":"a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b"}}]}
ana@vm:~/linkbox$ jq -r .payload ~/sbom.att.json | base64 -d | jq ".predicate.components | length"
2190
ana@vm:~/linkbox$ jq ".components | length" ~/ci/runs/1/logs/sbom.cdx.json
2190
```

O sujeito é o digest da imagem, então a declaração não pode ser movida para outros bytes. **A
contagem de componentes bate com o arquivo que a execução escreveu**, e é para isso que serve
anexá-la: a aula 13 guardou a lista de materiais ao lado dos logs da execução, onde ela vive enquanto
alguém mantiver `~/ci/runs`. Agora ela viaja com a imagem para todo registry para onde a imagem for
copiada, e a assinatura diz que quem a escreveu foi a CI que enviou a imagem, e não alguém que a
editou depois.

### A proveniência, verificada

A proveniência é lida do mesmo jeito, e a parte interessante é o predicado:

```
ana@vm:~/linkbox$ cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 $REF 2>/dev/null | jq -r .payload | base64 -d | jq .predicate
{
  "buildDefinition": {
    "buildType": "https://example.org/linkbox/ci/pipeline/v1",
    "externalParameters": {
      "ref": "refs/heads/main",
      "repository": "ci/linkbox.git"
    },
    "resolvedDependencies": [
      {
        "digest": {
          "gitCommit": "076438617306c7ef0715a479cdbd40d2c26b558c"
        },
        "uri": "git+file:ci/linkbox.git"
      }
    ]
  },
  "runDetails": {
    "builder": {
      "id": "https://example.org/linkbox/ci/post-receive"
    },
    "metadata": {
      "finishedOn": "2026-10-23T12:33:49Z",
      "invocationId": "/home/ana/ci/runs/1/logs"
    }
  }
}
ana@vm:~/linkbox$ git rev-parse HEAD
076438617306c7ef0715a479cdbd40d2c26b558c
```

O commit em `resolvedDependencies` é o commit que o `git rev-parse` nomeia, caractere por
caractere. **A imagem agora diz de qual commit foi construída, e a chave da CI responde por isso.**
O `docker build` também escreve uma proveniência própria, o `attestation-manifest` que a primeira
seção achou no índice da imagem, e a aula 8 de `gitops` lê uma delas. Essa é escrita pelo builder e
assinada por ninguém, que é a diferença que esta seção acrescenta.

### Uma pergunta com sim ou não

Ler um predicado a olho não escala para um deploy. O `cosign` consegue conferir o conteúdo de uma
declaração contra uma **política**, escrita em CUE ou em Rego, e recusar quando ela não vale. Uma
política é uma forma em que o predicado tem de caber. Salve esta como `~/deploy.cue`:

```
// What a deployment of linkbox accepts: an image whose provenance says it
// was built by the CI server's hook, from the main branch of its repository.
predicate: {
	buildDefinition: externalParameters: {
		repository: "ci/linkbox.git"
		ref:        "refs/heads/main"
	}
	runDetails: builder: id: "https://example.org/linkbox/ci/post-receive"
}
```

E, para ver uma recusa, uma política que espera outro builder, como `~/hosted.cue`:

```
// The same question, asked by a deployment that accepts only images built by
// a hosted builder, which this laptop is not.
predicate: runDetails: builder: id: "https://ci.example.org/hosted-builder"
```

As duas, contra a imagem para a qual `main` aponta:

```
ana@vm:~/linkbox$ cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 --policy ~/deploy.cue $REF > /dev/null
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the attestation.
will be validating against CUE policies: [/home/ana/deploy.cue]

Verification for localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
ana@vm:~/linkbox$ cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 --policy ~/hosted.cue $REF > /dev/null; echo "exit status $?"
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the attestation.
will be validating against CUE policies: [/home/ana/hosted.cue]
There are 1 number of errors occurred during the validation:

- predicate.runDetails.builder.id: conflicting values "https://example.org/linkbox/ci/post-receive" and "https://ci.example.org/hosted-builder"
Error: 1 validation errors occurred
error during command execution: 1 validation errors occurred
exit status 1
```

A primeira passa. A segunda nomeia o campo e os dois valores que discordam, e sai com erro, então
um script de deploy para ali. **Esta é a checagem que um deploy faz, em vez de uma pessoa lendo
JSON**: a imagem está assinada pela chave em que confiamos, e a declaração assinada com essa chave
diz main, este repositório, este builder.

### Implante o digest que você verificou

A última regra é sobre ordem. Uma verificação responde pelo digest que conferiu, então **o que se
implanta é esse digest, nunca a tag que apontava para ele um momento antes**. A forma mais curta da
regra, nesta máquina:

```
ana@vm:~/linkbox$ cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true $REF > /dev/null 2>&1 && docker pull -q $REF
localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b
```

O `docker pull` imprime a referência que puxou, o digest e nada mais. O mesmo padrão vale para o
cluster da aula 10: verifique a referência e entregue essa mesma referência ao `kubectl set image`,
para que a tag não possa mudar entre a checagem e o pull. Esse último passo não foi executado nesta
aula; o cluster é da aula 10, e a próxima seção trata de fazer a checagem dentro dele.
