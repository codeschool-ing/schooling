---
title: Assinando no pipeline
version: 1
---

Assinar à mão prova o mecanismo e nada mais. **O que quem verifica precisa é que toda imagem que a
CI envia seja assinada pela CI, com a mesma chave, sem nenhuma pessoa no meio.** Então a assinatura
vira um estágio, e vai por último: ela só roda quando todos os estágios anteriores passaram, o que
faz uma assinatura querer dizer "esta imagem passou pela lista inteira", e não apenas "alguém tinha
a chave".

O estágio também anexa duas declarações à imagem, cada uma assinada com a mesma chave. Uma é a
lista de materiais que a aula 13 já escreve ao lado dos logs da execução. A outra é a
**proveniência** da execução: qual repositório, qual commit, qual builder. Uma declaração assinada
sobre um artefato se chama **atestação**, e a próxima seção lê as duas de volta. Salve o estágio
como `ci/sign.sh`:

```schooling-example
{"language": "sh", "file": "ci/sign.sh", "parts": [{"code": "# The pushed image, signed by digest, and two attestations about it, signed\n# with the same key: its bill of materials and the provenance of this run.\n# The key and its password belong to the CI server, in ~/ci/keys, and never\n# to the repository.", "note": "Todo o trabalho do estágio: uma assinatura sobre a imagem e duas declarações assinadas sobre ela. A chave é do servidor de CI e fica fora de qualquer repositório que ele constrói."}, {"code": "set -euo pipefail\nout=${CI_LOGS:-ci-logs}\nkeys=~/ci/keys\nref=$(docker inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' \\\n  \"localhost:5000/linkbox:${CI_COMMIT:-dev}\" | grep '^localhost:5000/')", "note": "O digest da imagem que esta execução enviou. O `docker push` o registrou em `RepoDigests`, e a linha do registry é a que se assina: uma tag poderia mudar entre este passo e o seguinte."}, {"code": "python3 ci/provenance.py >\"$out/provenance.json\"", "note": "A proveniência é escrita ao lado dos logs da execução, onde o `ci/sbom.sh` já pôs a lista de materiais."}, {"code": "export COSIGN_PASSWORD\nCOSIGN_PASSWORD=$(cat \"$keys/password\")", "note": "O cosign lê a senha da chave em `COSIGN_PASSWORD`, então ela sai do arquivo para o ambiente deste script e de mais nenhum lugar."}, {"code": "sign() { cosign \"$@\" --yes --key \"$keys/cosign.key\" --signing-config \"$keys/offline.json\"; }", "note": "Toda chamada leva as mesmas três opções: nenhuma pergunta a responder, a chave da CI e a configuração de assinatura sem nenhum serviço público."}, {"code": "sign sign \"$ref\"\nsign attest --type cyclonedx --predicate \"$out/sbom.cdx.json\" \"$ref\"\nsign attest --type slsaprovenance1 --predicate \"$out/provenance.json\" \"$ref\"\necho \"signed $ref\"", "note": "A assinatura, depois as duas atestações. `--type` diz o que a declaração afirma ser, e quem verifica pede por esse nome."}]}
```

A proveniência vem de um programa curto, porque o servidor de CI é a única parte que sabe o que fez
checkout. Salve-o como `ci/provenance.py`:

```schooling-example
{"language": "python", "file": "ci/provenance.py", "parts": [{"code": "\"\"\"The provenance of this run, as a SLSA v1 predicate: what was built, from\nwhich commit of which repository, by which builder, and when. The image it\ndescribes is the subject of the attestation that carries it.\"\"\"\nimport datetime\nimport json\nimport os\nfrom pathlib import Path\n", "note": "Um predicado é o corpo de uma declaração. Este segue o formato de proveniência da SLSA, versão 1, e o cosign o embrulha num envelope cujo sujeito é o digest da imagem."}, {"code": "# The CI server checks the pushed commit out detached, so HEAD holds its hash.\ncommit = Path(\".git/HEAD\").read_text().strip()", "note": "O commit vem do próprio checkout, nunca de uma variável que alguém pudesse definir. O hook do servidor faz checkout do commit enviado em modo detached, então `.git/HEAD` tem o hash completo e mais nada."}, {"code": "print(json.dumps({\n    \"buildDefinition\": {\n        \"buildType\": \"https://example.org/linkbox/ci/pipeline/v1\",\n        \"externalParameters\": {\n            \"repository\": \"ci/linkbox.git\",\n            \"ref\": \"refs/heads/\" + os.environ.get(\"CI_BRANCH\", \"main\"),\n        },\n        \"resolvedDependencies\": [\n            {\"uri\": \"git+file:ci/linkbox.git\", \"digest\": {\"gitCommit\": commit}},\n        ],\n    },", "note": "`buildDefinition` é o que foi pedido: qual repositório, qual branch e o commit exato que foi resolvido."}, {"code": "    \"runDetails\": {\n        \"builder\": {\"id\": \"https://example.org/linkbox/ci/post-receive\"},\n        \"metadata\": {\n            \"invocationId\": os.environ.get(\"CI_LOGS\", \"local\"),\n            \"finishedOn\": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec=\"seconds\"),\n        },\n    },\n}, indent=2))", "note": "`runDetails` é quem fez e quando. O id do builder é um nome que este curso inventa para o seu hook; uma CI hospedada escreve o dela, e é isso que quem verifica pode exigir."}]}
```

Depois a lista ganha a última entrada. Salve-a como `ci/stages`:

```
secrets
test
sast
sca
build
image
push
sbom
sign
```

### Onde está a chave, e o que isso significa

O `ci/sign.sh` lê a chave em `~/ci/keys`, que é a casa do servidor de CI e fica fora de todo clone
que o hook faz. **Nada no repositório guarda a chave ou a senha dela**, então um fork, um clone ou
um backup vazado do histórico do linkbox não leva nada disso. É o arranjo que a aula 9 de
`testing-cicd` pede para todo segredo que um pipeline usa, e é o mínimo de que esta chave precisa.

Não é o máximo. **O script que assina vem do commit que está sendo construído**, como todo estágio
deste curso: o hook roda o `ci/sign.sh` que o commit enviado contiver. Quem pode enviar uma branch
pode, portanto, mudar o que o estágio faz com a chave, naquela execução. Neste laptop a pessoa que
envia e a dona da chave são ambas a Ana, então nada se perde. Num time não são as mesmas pessoas, e
a aula 16 trata exatamente dessa lacuna: o que um pipeline deixa o autor de uma mudança fazer com
credenciais que nunca foram dadas a ele.

### A execução

Faça commit dos três arquivos e envie:

```
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git commit -q -m "every pushed image signed, with its bill of materials and its provenance attested"
9:33AM INF 0 commits scanned.
9:33AM INF scanned ~1968 bytes (1.97 KB) in 184ms
9:33AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 0764386        
remote: secrets: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 4s        
remote: sca: passed in 8s        
remote: build: passed in 0s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 4s        
remote: sign: passed in 3s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   de3591e..0764386  main -> main
```

O hook de pre-commit da aula 6 varreu os arquivos preparados no caminho, que são as três linhas que
começam com um horário. Depois, a execução: `sign` é o nono estágio, e passou. O log dele traz o
mesmo `WARNING` sobre a raiz de confiança do Sigstore três vezes, uma por chamada, e fora isso diz:

```
ana@vm:~/linkbox$ grep -v ^WARNING ~/ci/runs/1/logs/sign.log
Signing artifact...
Pushing signature to: localhost:5000/linkbox
Using payload from: /home/ana/ci/runs/1/logs/sbom.cdx.json
Signing artifact...
Using payload from: /home/ana/ci/runs/1/logs/provenance.json
Signing artifact...
signed localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b
```

**Uma assinatura e duas atestações, todas sobre um mesmo digest.** `Using payload from` nomeia o
arquivo de que cada atestação foi feita, e a última linha é a referência que um deploy pode usar.
Todo push para `main` daqui em diante termina do mesmo jeito, e toda branch também, porque o hook
roda a mesma lista para toda branch que recebe.
