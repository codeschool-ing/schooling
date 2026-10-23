---
title: Rego, no Dockerfile
version: 1
---

Rego parece estranho no começo: não tem comandos que rodam um depois do outro nem `return`. Uma regra
é uma conclusão, a palavra `if` e as condições sob as quais a conclusão vale. **Toda linha do corpo de
uma regra precisa ser verdadeira para a regra produzir alguma coisa, e uma linha que não pode ser
avaliada conta como não verdadeira.** Essa frase explica quase tudo o que surpreende as pessoas na
linguagem, e as regras abaixo se apoiam nela de propósito.

### O que o conftest enxerga

Antes de escrever uma regra, olhe a entrada que ela vai receber. O `conftest parse` imprime o JSON em
que um arquivo se transforma. Um Dockerfile vira uma lista de instruções; filtrar os comentários com
`jq` deixa uma linha por instrução, com o número do estágio, o comando e os argumentos:

```
ana@vm:~$ cd ~/linkbox
ana@vm:~/linkbox$ conftest parse Dockerfile | jq -c '.[][] | select(.Cmd != "comment") | [.Stage, .Cmd, .Value]'
[0,"from",["python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39","AS","build"]]
[0,"copy",["requirements.txt","/"]]
[0,"copy",["wheels","/wheels"]]
[0,"run",["pip install --no-cache-dir --no-index --find-links /wheels --require-hashes     --target /packages -r /requirements.txt"]]
[0,"run",["mkdir /data"]]
[1,"from",["gcr.io/distroless/python3-debian13:nonroot@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a"]]
[1,"copy",["/packages","/packages"]]
[1,"copy",["/data","/data"]]
[1,"copy",["app.py","settings.py","/app/"]]
[1,"workdir",["/app"]]
[1,"env",["PYTHONPATH","/packages","=","LINKBOX_DB","/data/linkbox.db","="]]
[1,"expose",["8000"]]
[1,"entrypoint",["python3","-m","gunicorn","--bind","0.0.0.0:8000","app:app"]]
```

Dois estágios, numerados 0 e 1. Toda instrução tem um `Cmd` em minúsculas, uma lista `Value` com os
argumentos e o `Stage` a que pertence. Nada na entrada diz com qual usuário a imagem vai rodar, e essa
ausência está prestes a importar.

### Duas regras para o Dockerfile

A aula 15 nomeou as duas imagens base por digest, e as aulas 8 e 9 rodaram o linkbox com um usuário
sem privilégio. A política torna as duas decisões checáveis. Crie no projeto um diretório chamado
`policy`, que é onde o conftest procura por padrão, e salve isto como `policy/docker.rego`:

```
package docker

# Rules for linkbox's Dockerfile. conftest hands each Dockerfile to these
# rules as a list of instructions, in order, each with its Cmd ("from",
# "copy", "user"...), its Value and the number of the Stage it belongs to.

# Every FROM names its image by digest. A tag is a name somebody else can
# move to a different image; a digest is the image itself.
deny contains msg if {
	some instr in input
	instr.Cmd == "from"
	image := instr.Value[0]
	not contains(image, "@sha256:")
	msg := sprintf("FROM %s: name the base image by digest (image@sha256:...)", [image])
}

# The stage that becomes the image sets a USER, by number, that is not 0.
# The base image's default user is invisible here, and Kubernetes can only
# check runAsNonRoot against a number.
deny contains msg if {
	not final_user
	msg := "the final stage sets no USER: name a numeric user that is not root"
}

deny contains msg if {
	user := final_user
	not numeric_non_root(user)
	msg := sprintf("USER %s: use a numeric user other than 0, such as 65532", [user])
}

final_stage := max({instr.Stage | some instr in input})

# The last USER of the final stage, which is the one the container runs as.
final_user := users[count(users) - 1] if {
	users := [instr.Value[0] | some instr in input; instr.Stage == final_stage; instr.Cmd == "user"]
	count(users) > 0
}

numeric_non_root(user) if {
	uid := split(user, ":")[0]
	regex.match(`^[0-9]+$`, uid)
	to_number(uid) != 0
}
```

Leia de cima para baixo.

**`package docker`** dá nome ao namespace das regras. O conftest só avalia o namespace que mandarem,
`main` por padrão, então nomear um por tipo de arquivo mantém as regras do Dockerfile longe das dos
manifestos.

**`deny contains msg if { ... }`** acrescenta `msg` a um conjunto chamado `deny` sempre que todas as
linhas do corpo valem. O conftest reporta cada mensagem de `deny` como uma falha; um conjunto vazio é
aprovação. Há três regras `deny`, e o conjunto junta as mensagens de todas: **regras separadas são
alternativas, e as linhas dentro de uma regra precisam valer todas juntas.**

**`some instr in input`** tenta cada instrução por vez. A primeira regra diz então: para alguma
instrução cujo comando é `from` e cuja imagem não contém `@sha256:`, produza uma mensagem. Cada FROM
que quebra a regra acrescenta a própria mensagem.

**`final_user`** é um auxiliar sem `deny` no nome. Ele junta numa lista as instruções USER do último
estágio e pega a última, porque só o último USER do estágio final decide com quem o contêiner roda.
Quando não há nenhuma, o auxiliar fica *indefinido*, e `not final_user` é verdadeiro. É assim que Rego
diz "está faltando".

**`numeric_non_root`** separa `65532:65532` nos dois-pontos e confere se a parte do usuário é feita de
dígitos e não é 0. Um nome como `nonroot` reprova, e o comentário acima da regra diz por quê: com
`runAsNonRoot` ligado, o kubelet se recusa a iniciar um contêiner cuja imagem nomeia o usuário por
nome, porque não consegue saber que número o nome representa. Essa recusa não foi reproduzida aqui.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l19-rego\" aria-label=\"Como o conftest chega a um veredito. O Dockerfile é convertido em input, uma lista de instruções. Cada uma das três regras deny é avaliada sobre ele: dentro de uma regra toda linha precisa valer, e quando todas valem a regra acrescenta a sua mensagem ao conjunto deny. As regras são alternativas, então o conjunto junta as mensagens de todas. Um conjunto vazio é aprovação e status de saída 0; qualquer mensagem é falha e status de saída 1.\"><defs><marker id=\"sp-l19-rego-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"95\" width=\"92\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"58.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Dockerfile</text><path d=\"M104 120 L158 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><text x=\"131\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conversão</text><rect x=\"160\" y=\"90\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">input</text><text x=\"220.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">uma lista de instruções</text><rect x=\"300\" y=\"30\" width=\"215\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"407.5\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"500\" fill=\"var(--paper)\">deny: um FROM sem digest</text><path d=\"M280 120 L288 120 L288 53 L298 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><path d=\"M515 53 L535 53 L535 120 L548 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><rect x=\"300\" y=\"98\" width=\"215\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"407.5\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"500\" fill=\"var(--paper)\">deny: sem USER no estágio final</text><path d=\"M280 120 L288 120 L288 121 L298 121\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><path d=\"M515 121 L535 121 L535 120 L548 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><rect x=\"300\" y=\"166\" width=\"215\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"407.5\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"500\" fill=\"var(--paper)\">deny: um USER que não é número acima de 0</text><path d=\"M280 120 L288 120 L288 189 L298 189\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><path d=\"M515 189 L535 189 L535 120 L548 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><text x=\"407\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">toda linha de uma regra precisa valer</text><rect x=\"550\" y=\"92\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o conjunto deny</text><text x=\"630.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">uma mensagem por regra que valeu</text><text x=\"630\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">vazio: passa, saída 0</text><text x=\"630\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">uma mensagem: FAIL, saída 1</text></svg>", "caption": "As linhas dentro de uma regra se juntam por E; regras separadas se juntam por OU, num só conjunto de mensagens. O conjunto decide o status de saída."}
```

### A primeira execução falha

```
ana@vm:~/linkbox$ mkdir policy
ana@vm:~/linkbox$ conftest test --no-color --namespace docker Dockerfile; echo "exit status $?"
FAIL - Dockerfile - docker - the final stage sets no USER: name a numeric user that is not root

3 tests, 2 passed, 0 warnings, 1 failure, 0 exceptions
exit status 1
```

A regra do digest passou para as duas linhas FROM. A regra do usuário falhou, e o status de saída 1 é
o que um estágio do pipeline transforma num build quebrado. `3 tests` são três regras `deny`
avaliadas contra um arquivo.

O resultado surpreende, porque o linkbox não roda como root. A imagem base define o usuário:

```
ana@vm:~/linkbox$ docker image inspect --format '{{.Config.User}}' gcr.io/distroless/python3-debian13:nonroot
65532
```

**A imagem roda como 65532, e o arquivo não diz nada sobre isso.** Esse é o limite de qualquer
checagem que lê o arquivo e não a imagem: o que o arquivo não declara, ela não enxerga. A imagem base
poderia ser trocada por uma cujo usuário padrão é root, com uma única linha alterada, e a revisão
dessa linha mostraria um digest novo e nada sobre o usuário.

Uma segunda ferramenta concorda. O scanner de configuração do Trivy, que a aula 11 rodou, tem uma
checagem embutida exatamente para isso, e a levanta pelo mesmo motivo:

```
ana@vm:~/linkbox$ trivy config --quiet --format json Dockerfile | jq -r '.Results[].Misconfigurations[]? | "\(.ID) \(.Severity) \(.Title)"'
DS-0002 HIGH Image user should not be 'root'
DS-0026 LOW No HEALTHCHECK defined
```

DS-0002 é a versão do Trivy da regra acima. A seção sobre checagens embutidas volta à outra linha.

### A correção

Declare o usuário no arquivo, por número, no estágio final. O resto do Dockerfile é o da aula 15; o
comentário acima do segundo FROM diz por que a linha está ali. Salve como `Dockerfile`:

```dockerfile
# Build: the pinned dependencies, installed from the wheels the pipeline
# downloaded and checked against requirements.txt. The build itself runs
# with no network, so it can read nothing it was not handed.
FROM python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39 AS build
COPY requirements.txt /
COPY wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links /wheels --require-hashes \
    --target /packages -r /requirements.txt
RUN mkdir /data

# Run: the same Python and nothing else. No shell, no package manager, no
# pip, and a user that is not root, written here by number although the base
# image already sets it, so that a check reading this file can see it. Both
# images are named by digest, so a tag that moves upstream changes nothing
# here until somebody changes it.
FROM gcr.io/distroless/python3-debian13:nonroot@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a
COPY --from=build /packages /packages
COPY --from=build --chown=nonroot:nonroot /data /data
COPY app.py settings.py /app/
WORKDIR /app
ENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db
USER 65532:65532
EXPOSE 8000
ENTRYPOINT ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

```
ana@vm:~/linkbox$ conftest test --no-color --namespace docker Dockerfile

3 tests, 3 passed, 0 warnings, 0 failures, 0 exceptions
```

Três regras, três aprovações. A imagem que isso constrói é a mesma de antes, já que 65532 já era o
usuário dela; o que mudou é que agora o arquivo diz isso, e uma mudança que remova a linha ou a ponha
em 0 quebra o build no primeiro estágio que a lê.
